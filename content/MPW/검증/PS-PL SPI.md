
EMIO를 통해 PS와 PL통신을 해서 SPI 로직을 검증해봐야겠다. 

![[Pasted image 20260612172554.png|603]]

# Block Design

![[Pasted image 20260617133327.png]]


# Vitis

```c
/*
 * main.c  -  PS(SPI0 마스터) <-> PL(SPI_slave) SPI 통신 테스트
 *
 *  - XSpiPs : PS SPI0를 마스터, 수동 CS(FORCE_SSELECT), 폴링 전송, 모드 0
 *  - XGpio  : AXI GPIO 2개로 슬레이브 백엔드 제어
 *      GPIO_OUT (PS->PL) : ch1 = i_dat[15:0], ch2 = i_tx_load
 *      GPIO_IN  (PL->PS) : ch1 = o_dat[15:0], ch2 = o_rx_done
 *
 *  동작: PS가 GPIO로 슬레이브의 응답값(i_dat)을 세팅 -> SPI로 16비트 전송
 *        -> MISO로 받은 값(=슬레이브 i_dat)과 GPIO로 읽은 o_dat(=슬레이브가 받은 값)을 검증
 */

#include "xparameters.h"
#include "xspips.h"
#include "xgpio.h"
#include "xil_printf.h"

/* ---- 이 xparameters.h 는 SDT 플로우(_DEVICE_ID 없음) -> 베이스 주소 사용 ---- */
#define SPI_BASEADDR        XPAR_XSPIPS_0_BASEADDR   /* 0xe0006000 */
#define GPIO_OUT_BASEADDR   XPAR_XGPIO_0_BASEADDR    /* 0x41200000 : i_dat / i_tx_load  (배선으로 확인) */
#define GPIO_IN_BASEADDR    XPAR_XGPIO_1_BASEADDR    /* 0x41210000 : o_dat / o_rx_done  (배선으로 확인) */

/* AXI GPIO 채널 번호 (Dual Channel 사용) */
#define CH_DATA   1   /* ch1 : 16-bit  */
#define CH_FLAG   2   /* ch2 : 1-bit   */

static XSpiPs Spi;
static XGpio  GpioOut;   /* i_dat, i_tx_load */
static XGpio  GpioIn;    /* o_dat, o_rx_done */

/* 전체 테스트 통과/실패 집계 */
static int g_pass = 0;
static int g_fail = 0;

static int init_spi(void)
{
    XSpiPs_Config *cfg = XSpiPs_LookupConfig(SPI_BASEADDR);
    if (cfg == NULL) {
        return XST_FAILURE;
    }
    if (XSpiPs_CfgInitialize(&Spi, cfg, cfg->BaseAddress) != XST_SUCCESS) {
        return XST_FAILURE;
    }
    if (XSpiPs_SelfTest(&Spi) != XST_SUCCESS) {
        return XST_FAILURE;
    }

    /*
     * 모드 0(CPOL=0, CPHA=0) : CLK_PHASE / CLK_ACTIVE_LOW 옵션을 켜지 않는다.
     * FORCE_SSELECT : 수동 CS. PolledTransfer 한 번이 CS low 유지 -> 16비트(2바이트)
     *                 동안 CS가 떨어지지 않게 해 프레임을 보존한다.
     */
    XSpiPs_SetOptions(&Spi, XSPIPS_MASTER_OPTION | XSPIPS_FORCE_SSELECT_OPTION);

    /* SCLK = SPI_Ref_Clk / 32 (~5 MHz). EMIO 25MHz 한계 이하이며 PL CDC 오버샘플링에 충분. */
    XSpiPs_SetClkPrescaler(&Spi, XSPIPS_CLK_PRESCALE_32);

    /* SS0 선택 (EMIOSPI0SSON0 -> 슬레이브 i_ssn) */
    XSpiPs_SetSlaveSelect(&Spi, 0x00);

    XSpiPs_Enable(&Spi);
    return XST_SUCCESS;
}

static int init_gpio(void)
{
    if (XGpio_Initialize(&GpioOut, GPIO_OUT_BASEADDR) != XST_SUCCESS) {
        return XST_FAILURE;
    }
    if (XGpio_Initialize(&GpioIn, GPIO_IN_BASEADDR) != XST_SUCCESS) {
        return XST_FAILURE;
    }

    /* GPIO_OUT : 두 채널 모두 출력 (0 = 출력) */
    XGpio_SetDataDirection(&GpioOut, CH_DATA, 0x0000);
    XGpio_SetDataDirection(&GpioOut, CH_FLAG, 0x0000);

    /* GPIO_IN : 두 채널 모두 입력 (1 = 입력) */
    XGpio_SetDataDirection(&GpioIn, CH_DATA, 0xFFFF);
    XGpio_SetDataDirection(&GpioIn, CH_FLAG, 0x0001);

    /* i_tx_load = 1 로 유지 -> r_dat가 i_dat를 계속 추종, ssn_falling에 TBUF로 래치됨 */
    XGpio_DiscreteWrite(&GpioOut, CH_FLAG, 1);
    return XST_SUCCESS;
}

/* i_tx_load 제어 (1: r_dat가 i_dat 추종 / 0: r_dat 고정) */
static void set_tx_load(u32 v)
{
    XGpio_DiscreteWrite(&GpioOut, CH_FLAG, v & 0x1);
}

/*
 * 참고: o_rx_done 는 ssn_rising 에서 i_clk 1사이클짜리 펄스라,
 *       PS가 GPIO로 폴링하는 시점엔 이미 지나간 경우가 대부분이다.
 *       따라서 검증 신호로는 쓰지 않고 o_dat(확정 수신값)만으로 판정한다.
 */

/*
 * 16비트 1회 트랜잭션.
 *   tx16 : PS가 MOSI로 슬레이브에 보낼 값  (-> 슬레이브 o_dat 로 들어감)
 *   slave_resp : 슬레이브가 MISO로 되돌려줄 값 (i_dat 로 미리 세팅)
 *   rx16 : PS가 MISO로 받은 값 (= slave_resp 와 같아야 함)
 *   slave_got : 슬레이브가 받은 값 o_dat (= tx16 과 같아야 함)
 */
static void spi_xfer16(u16 tx16, u16 slave_resp, u16 *rx16, u16 *slave_got)
{
    u8 tx[2], rx[2] = {0, 0};

    /* 슬레이브가 되돌려줄 응답값을 GPIO로 세팅 (MSB first) */
    XGpio_DiscreteWrite(&GpioOut, CH_DATA, slave_resp);

    tx[0] = (u8)(tx16 >> 8);   /* high byte 먼저 (MSB first) */
    tx[1] = (u8)(tx16 & 0xFF);

    /* CS low -> 16 SCLK -> CS high. 끝나는 순간 슬레이브 ssn_rising 으로 o_dat 확정 */
    XSpiPs_PolledTransfer(&Spi, tx, rx, 2);

    *rx16 = ((u16)rx[0] << 8) | rx[1];

    /* 슬레이브가 수신한 값을 GPIO로 읽어옴 */
    *slave_got = (u16)XGpio_DiscreteRead(&GpioIn, CH_DATA);
}

/*
 * 1개 테스트 케이스 실행 + 검증 + 결과 출력.
 *   MOSI(tx16)  -> 슬레이브 o_dat 와 일치해야 함
 *   MISO(rx16)  -> slave_resp 와 일치해야 함
 * 반환: 두 검증 모두 통과하면 1.
 */
static int run_case(const char *name, u16 tx16, u16 slave_resp)
{
    u16 rx16, slave_got;
    int ok_slv, ok_rx, ok;

    spi_xfer16(tx16, slave_resp, &rx16, &slave_got);

    ok_slv = (slave_got == tx16);
    ok_rx  = (rx16 == slave_resp);
    ok     = ok_slv && ok_rx;

    if (ok) g_pass++; else g_fail++;

    xil_printf("[%-12s] MOSI=0x%04X o_dat=0x%04X(%s)  resp=0x%04X MISO=0x%04X(%s) -> %s\r\n",
               name,
               tx16, slave_got, ok_slv ? "OK" : "NG",
               slave_resp, rx16, ok_rx ? "OK" : "NG",
               ok ? "PASS" : "FAIL");
    return ok;
}

/* ---------------- 테스트 그룹들 ---------------- */

/* 1) 기본/엣지 패턴 */
static void test_patterns(void)
{
    xil_printf("\r\n== [1] 기본/엣지 패턴 ==\r\n");
    run_case("basic",   0x1234, 0xA55A);
    run_case("zeros",   0x0000, 0x0000);
    run_case("ones",    0xFFFF, 0xFFFF);
    run_case("aa55",    0xAAAA, 0x5555);
    run_case("55aa",    0x5555, 0xAAAA);
    run_case("msb_only",0x8000, 0x0001);   /* 첫 비트만 1 / 마지막 비트만 1 */
    run_case("lsb_only",0x0001, 0x8000);
    run_case("byte_hi", 0xFF00, 0x00FF);   /* 바이트 경계 확인 */
    run_case("byte_lo", 0x00FF, 0xFF00);
}

/* 2) 워킹 1 : 비트 위치별로 1을 한 칸씩 이동시키며 16비트 정렬/순서 검증 */
static void test_walking_one(void)
{
    int i;
    char nm[12];
    xil_printf("\r\n== [2] walking-1 (MOSI & MISO 동시) ==\r\n");
    for (i = 0; i < 16; i++) {
        u16 m = (u16)(1u << i);
        /* MISO 응답은 반대편 비트로 둬서 둘이 섞이지 않는지도 같이 본다 */
        u16 r = (u16)(1u << (15 - i));
        nm[0] = 'w'; nm[1] = '1'; nm[2] = ':';
        nm[3] = (i >= 10) ? ('1') : ('0' + i);
        nm[4] = (i >= 10) ? ('0' + (i - 10)) : '\0';
        nm[5] = '\0';
        run_case(nm, m, r);
    }
}

/* 3) 워킹 0 : 한 비트만 0이고 나머지는 1 */
static void test_walking_zero(void)
{
    int i;
    char nm[12];
    xil_printf("\r\n== [3] walking-0 ==\r\n");
    for (i = 0; i < 16; i++) {
        u16 m = (u16)(~(1u << i));
        nm[0] = 'w'; nm[1] = '0'; nm[2] = ':';
        nm[3] = (i >= 10) ? ('1') : ('0' + i);
        nm[4] = (i >= 10) ? ('0' + (i - 10)) : '\0';
        nm[5] = '\0';
        run_case(nm, m, (u16)~m);
    }
}

/* 4) 연속 전송 : 매 트랜잭션마다 다른 값을 보내며 이전 값이 새지 않는지(TBUF/RBUF 재적재) 확인 */
static void test_back_to_back(void)
{
    static const u16 seq[] = {
        0x0001, 0x0002, 0x0004, 0x1000, 0xDEAD, 0xBEEF, 0xCAFE, 0x0F0F, 0xF0F0, 0x1357
    };
    int i, n = sizeof(seq) / sizeof(seq[0]);
    xil_printf("\r\n== [4] back-to-back 연속 전송 ==\r\n");
    for (i = 0; i < n; i++) {
        /* MOSI 와 MISO 응답을 서로 다르게(보수로) 줘서 교차 오염을 잡는다 */
        run_case("b2b", seq[i], (u16)~seq[i]);
    }
}

/* 5) i_tx_load 게이팅 검증
 *    load=0 으로 두고 i_dat 를 바꿔도 슬레이브 응답(r_dat)이 고정값 그대로여야 한다.
 *    (load=1 일 때만 i_dat 가 r_dat 로 반영됨) */
static void test_tx_load_gate(void)
{
    u16 rx16, slave_got;
    int ok;
    const u16 latched = 0x1234;   /* load=1 동안 r_dat 에 들어갈 값 */
    const u16 changed = 0xABCD;   /* load=0 후에 바꿔치기 시도하는 값 */

    xil_printf("\r\n== [5] i_tx_load 게이팅 ==\r\n");

    /* load=1 상태에서 latched 값으로 한 번 정상 전송 -> r_dat = latched */
    set_tx_load(1);
    run_case("load1", 0x0000, latched);

    /* load=0 으로 고정 후 i_dat 를 changed 로 바꿔도 r_dat 는 latched 유지되어야 함 */
    set_tx_load(0);
    XGpio_DiscreteWrite(&GpioOut, CH_DATA, changed);  /* i_dat 변경 시도 */

    {
        u8 tx[2] = {0x00, 0x00}, rx[2] = {0, 0};
        XSpiPs_PolledTransfer(&Spi, tx, rx, 2);
        rx16 = ((u16)rx[0] << 8) | rx[1];
        slave_got = (u16)XGpio_DiscreteRead(&GpioIn, CH_DATA);
    }

    ok = (rx16 == latched);   /* 변경이 무시되고 이전 래치값이 와야 정상 */
    if (ok) g_pass++; else g_fail++;
    xil_printf("[%-12s] i_dat changed=0x%04X but MISO=0x%04X (expect latched 0x%04X) -> %s\r\n",
               "load0_hold", changed, rx16, latched, ok ? "PASS" : "FAIL");
    (void)slave_got;

    /* 원복 : load=1 로 되돌려 이후 테스트가 정상 동작하게 함 */
    set_tx_load(1);
}

int main(void)
{
    xil_printf("\r\n========= PS-PL SPI test =========\r\n");

    if (init_spi() != XST_SUCCESS) {
        xil_printf("SPI init failed\r\n");
        return XST_FAILURE;
    }
    if (init_gpio() != XST_SUCCESS) {
        xil_printf("GPIO init failed\r\n");
        return XST_FAILURE;
    }

    test_patterns();
    test_walking_one();
    test_walking_zero();
    test_back_to_back();
    test_tx_load_gate();

    xil_printf("\r\n========= 결과 =========\r\n");
    xil_printf("PASS=%d  FAIL=%d  -> %s\r\n",
               g_pass, g_fail, (g_fail == 0) ? "ALL OK" : "SOME FAILED");
    xil_printf("========= done =========\r\n");

    return (g_fail == 0) ? XST_SUCCESS : XST_FAILURE;
}

```


# 결과

![[Pasted image 20260617133542.png]]

그런데 실칩 검증을 진행할 때는 axi를 사용하면 안되고 PS가 바로 SPI 마스터 역할을 해야해서 PS가 spi 마스터역할을 하게 해야한다고 한다. 

