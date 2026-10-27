# KV260 + Pcam 5C (OV5640) → DisplayPort 베어메탈 프로젝트 — 세션 인수인계 문서

작성일: 2026-07-28
상태: **캡처 파이프라인 하드웨어 완성, 비트스트림 생성 완료.**
**방향 변경: DP 출력을 non-live가 아닌 LIVE 모드로 구현하기로 결정 → 표시 경로 하드웨어 추가 필요 (§3) → 재합성 → 소프트웨어 브링업 (§4)**

---

## 1. 프로젝트 개요

- 목표: Digilent Pcam 5C(OV5640)를 KV260 J9(RPi 커넥터)에 연결, MIPI CSI-2로 캡처하여 PS DisplayPort로 모니터 출력 (베어메탈)
- 환경: Vivado 2025.2, Vitis 베어메탈, KV260 보드 파일 rev 1.4, JTAG/xsdb 배포 워크플로우
- 프로젝트명: `pcam_1`

## 2. 완성된 하드웨어 구성 (블록 디자인)

### 데이터 경로
```
mipi_csi2_rx_subsyst_0 (video_out, RAW10 16-bit)
  → v_demosaic_0 (10bpc, 출력 RGB 30-bit → 32-bit 패딩)
  → axis_subset_converter_0 (32-bit → 24-bit RGB888)
  → v_frmbuf_wr_0 (RGB8)
  → m_axi_mm_video → PS S_AXI (DDR 기록)
```
※ frmbuf는 HPC0에 연결됨 (validate 시 `HPC0_LPS_OCM excluded` 경고는 정보성, 무시). HP0로 바꿔도 되지만 현재 상태로 동작 문제 없음.

### IP 설정 요약

| IP | 핵심 설정 |
|---|---|
| MIPI CSI-2 RX Subsystem | RAW10, **2 lanes**, Line Rate **420 Mbps**, VFB 포함, 1 ppc, CSI2 Controller Register Interface 활성, Shared Logic **in core**, HP IO Bank **66** |
| Sensor Demosaic | Samples/Clock 1, Max Data Width **10**, 1920×1080, High Resolution Interpolation, Zipper Removal 체크 |
| AXI4-Stream Subset Converter | Slave 4 bytes / Master 3 bytes, TLAST Yes, USER 1비트 양쪽 모두. TDATA Remap: `tdata[29:22],tdata[19:12],tdata[9:2]` (콤마 구분 필수), TUSER Remap: `tuser[0]`, TLAST Remap: `tlast` |
| Video Frame Buffer Write | Samples/Clock **1**, 1920×1080, Max Data Width 8, **RGB8만** 체크, Address Width 64 권장(32면 하위 2GB 제한) |
| Clocking Wizard | 100 MHz(pl_clk0) 입력 → **200 MHz** 출력 → `dphy_clk_200M`. `locked` → proc_sys_reset `dcm_locked` 연결 권장 |
| xlconstant_0 | 1-bit, value 1 → 카메라 인에이블 (external) |

### 클럭 구조
- **pl_clk0 (100 MHz)**: lite_aclk, video_aclk, demosaic/frmbuf ap_clk, subset converter aclk, maxihpm0_lpd_aclk, saxi*_fpd_aclk, IIC 등 전부
- **Clocking Wizard 200 MHz**: `dphy_clk_200M` 전용 (PS PL1 클럭은 187.5 MHz밖에 안 나와서 사용 불가 — PLL 분주 제약)

### PS 설정 (중요 이력 포함)
- **DDR**: 보드 프리셋의 `PSU__DDRC__CWL=14`가 Vivado 2025.2 검증에서 거부됨(DDR4-2400은 {12,16}만 허용). **CWL=12로 수정한 프리셋 전체(261 파라미터)를 Tcl로 적용**하여 해결. 스크립트: `kv260_preset_cwl12.tcl` (보관 중). SD 부팅 등에서 DDR 이상 시 CWL 12↔16 변경이 1순위 의심 대상.
- **I2C0**: EMIO로 활성화 → `IIC_0` external (카메라 mux/센서 제어용)
- **I2C1**: MIO 24..25 (프리셋 기본, 시스템 버스 — 건드리지 말 것)
- **DPAUX**: MIO 27..30 (MIO 34..37은 UART1과 충돌하므로 금지)
- **DP Lane**: Dual Lower, 참조클럭 27 MHz (프리셋 값)
- **S_AXI (HPC0 또는 HP0)**: frmbuf DDR 쓰기용 활성화
- UART1 = 시리얼 콘솔 (115200)

### 외부 핀 / XDC
```tcl
# MIPI (J9 RPi 커넥터, Bank 66)
set_property PACKAGE_PIN D7 [get_ports {mipi_phy_if_clk_p}]
set_property PACKAGE_PIN D6 [get_ports {mipi_phy_if_clk_n}]
set_property PACKAGE_PIN E5 [get_ports {mipi_phy_if_data_p[0]}]
set_property PACKAGE_PIN D5 [get_ports {mipi_phy_if_data_n[0]}]
set_property PACKAGE_PIN G6 [get_ports {mipi_phy_if_data_p[1]}]
set_property PACKAGE_PIN F6 [get_ports {mipi_phy_if_data_n[1]}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {mipi_phy_if_clk_*}]
set_property DIFF_TERM_ADV TERM_100 [get_ports {mipi_phy_if_data_*}]

# I2C (PS I2C0 EMIO → 캐리어 카메라 I2C 버스)
set_property PACKAGE_PIN G11 [get_ports <IIC포트명>_scl_io]   ;# 실제 래퍼 포트명 확인 필수
set_property PACKAGE_PIN F10 [get_ports <IIC포트명>_sda_io]
set_property IOSTANDARD LVCMOS33 [get_ports <IIC포트명>_*]

# 카메라 인에이블 (xlconstant=1)
set_property PACKAGE_PIN F11 [get_ports {cam_en[0]}]          ;# 벡터라 [0] 필요
set_property IOSTANDARD LVCMOS33 [get_ports {cam_en[0]}]
```
※ 포트 이름은 래퍼 생성 후 합성 I/O Ports 창 또는 `report_ports`로 확인한 실제 이름 사용 (틀리면 critical warning).

## 3. 【미완료】 LIVE 모드 표시 경로 하드웨어 추가

**결정 사항: DP 출력을 live 모드로 구현.** 단, live 모드여도 DDR 버퍼링은 필수 (OV5640 타이밍 ≠ DP 타이밍, 직결 동기화 불가). 캡처 절반은 §2 그대로, 표시 절반만 PL에 추가:

```
[비-live]  DDR → DPDMA(PS 내부) → DP          ← 기존 계획 (폴백 옵션)
[live]     DDR → v_frmbuf_rd → v_axi4s_vid_out(+VTC) → dp_live_video_in → DP
```

### 3-1. PS 설정
- PS-PL Configuration → General → Others → **Live Video 활성화**
- → PS 블록에 `dp_video_in_clk`, `dp_live_video_in`(36-bit + hsync/vsync/de) 포트 노출됨 (UG1449: live 입력은 36-bit 네이티브 비디오 인터페이스)

### 3-2. 추가 IP

| IP | 설정 |
|---|---|
| Video Frame Buffer Read (v_frmbuf_rd) | frmbuf_wr 미러: RGB8, 1 SPC, 1920×1080. `m_axi_mm_video` → PS HP 포트 (HPC0 공유 또는 HP1) |
| Video Timing Controller (VTC, PG016) | Generation만, 1080p60, AXI4-Lite 활성 |
| AXI4-Stream to Video Out (v_axi4s_vid_out) | 24-bit, 1 ppc, **Independent clocks**(내장 비동기 FIFO로 100M↔픽셀클럭 CDC), Timing 모드 **Master** |
| Clocking Wizard 출력 추가 | 기존 위저드에 `clk_out2` = **148.5 MHz** (1080p60 픽셀 클럭) |

### 3-3. 연결
```
frmbuf_rd/m_axis (100 MHz)      → v_axi4s_vid_out/video_in
VTC/vtiming_out                 → v_axi4s_vid_out/vtiming_in
clk_wiz/clk_out2 (148.5 MHz)    → v_axi4s_vid_out/vid_io_out_clk, VTC/clk, PS/dp_video_in_clk
v_axi4s_vid_out/vid_io_out      → PS/dp_live_video_in (+ hsync/vsync/de)
frmbuf_rd/s_axi_CTRL, VTC/ctrl  → SmartConnect (마스터 포트 추가)
```

### 3-4. 24-bit → 36-bit 매핑 (핵심 주의점)
- DP live 입력은 컴포넌트당 12-bit. 8-bit 데이터를 각 12-bit 슬롯의 **상위 8비트 `[11:4]`** 에 배치, 하위 4비트 = 0
- 구현: `vid_data[23:0]`를 Slice ×3 + Constant(4'b0) ×3 + Concat으로 36-bit 조립
- 컴포넌트 순서는 소프트웨어의 live 포맷 레지스터 설정과 일치해야 함 — gtaylormb `ultra96v2_imx219_to_displayport`가 동일 구조이므로 배선 순서 참고
- 색 스왑 증상 시 이 Concat 순서 vs xavbuf 포맷 설정 불일치 1순위 의심

### 3-5. 레이트 설계
- DP 출력 **1080p60**(148.5 MHz) — 1080p30은 모니터 호환성 낮음
- 카메라 30fps 기록, frmbuf_rd 60fps 읽기 → DDR이 레이트 차이 흡수 (티어링은 브링업 단계에서 무시)

완료 후: Validate → 비트스트림 재생성 → XSA 재익스포트.

## 4. 소프트웨어 브링업

### 준비
1. File → Export → Export Hardware (**Include bitstream**) → XSA
2. Vitis에서 새 플랫폼 + 베어메탈 앱 생성, stdout = **UART1** 확인
3. (참고) 이전 MAC 프로젝트에서 FSBL 자동 PS 초기화 실패 이력 있음 → 이번 XSA는 프리셋 기반이라 해소 가능성 높지만, 실패 시 기존 워크어라운드(xsdb에서 `psu_init.tcl` 수동 소싱 → isolation 제거 → reset config → `fpga -f`) 재사용. Tcl 경로는 반드시 forward slash.

### 초기화 순서 (검증 포인트 포함)
```
① XIicPs 초기화 (XPAR_XIICPS_0_DEVICE_ID, 100 kHz)
② TCA9546A(addr 0x74)에 1바이트 0x04 쓰기 → 채널 2(RPi 카메라) 오픈
③ OV5640(addr 0x3C) chip ID 읽기: reg 0x300A=0x56, 0x300B=0x40
   ★ 마일스톤 1: 여기 통과 = I2C 경로(EMIO 핀, mux, F11 전원) 전부 정상
④ OV5640 레지스터 시퀀스 (Digilent OV5640.h, 1080p30 RAW10 2-lane 420 Mbps 모드)
   - 레지스터 주소 16-bit big-endian + 데이터 1바이트
⑤ CSI-2 RX 활성화 (XCsiSs 드라이버)
   ★ 마일스톤 2: 코어 상태 레지스터에서 packet count 증가 확인 (ILA 불필요)
⑥ Demosaic: 해상도 1920×1080, bayer phase 설정 + start
   - OV5640 기본 BGGR (플립/미러 설정에 따라 변동 — 색 이상 시 1순위 의심)
⑦ Frmbuf Wr: 1920×1080, stride 5760(=1920×3, 8바이트 정렬 충족), RGB8,
   DDR 버퍼 주소 설정 + start
   ★ 마일스톤 3: xsdb 메모리 뷰로 DDR 버퍼에 픽셀 데이터 확인
⑧ [LIVE] 표시 경로 초기화:
   a. VTC 1080p60 타이밍 설정 + enable
   b. Frmbuf Rd: 같은 버퍼 주소/stride/RGB8 설정 + start
   c. v_axi4s_vid_out locked 상태 확인 (underflow 카운터도)
   d. xavbuf: XAVBuf_InputVideoSelect()로 소스 = LIVE(PL), live 포맷 RGB 8bpc
   e. xdppsu: MSA를 VTC 타이밍과 정확히 일치하게 수동 설정 (live에선 자동 아님),
      DPDMA는 사용 안 함
   ★ 마일스톤 4: 모니터 출력
```

### 권장 분리 전략 (staged bring-up)
- **1단계 (표시 경로 단독)**: 카메라 무시. DDR에 소프트웨어로 테스트 패턴 작성 → frmbuf_rd → live DP 출력. 여기서 36-bit 매핑·MSA·타이밍 전부 검증
- **2단계 (통합)**: 캡처(①~⑦) 붙여서 같은 버퍼로 연결
- 이렇게 하면 화면 문제 발생 시 캡처/표시 어느 쪽인지 즉시 구분됨
- 인터럽트는 쓰지 않고 폴링으로 시작 (BD에서 IRQ 미연결 상태)
- live 경로는 전부 PL에 있으므로 ILA로 vid_out/vtiming 신호 직접 관찰 가능 (비-live 대비 장점)

### 디버깅 참고
| 증상 | 1순위 의심 |
|---|---|
| chip ID 안 읽힘 | mux 채널(0x04), F11 인에이블, XDC 핀 이름 오타, I2C 속도 |
| packet count 0 | OV5640 MIPI 미출력(레지스터 시퀀스), lane 수/line rate 불일치 |
| SoT/CRC 에러 | D-PHY HS_SETTLE (Xilinx 기본 145ns ↔ Digilent 85ns — `C_HS_SETTLE_NS` 조정) |
| DDR에 데이터 없음 | frmbuf 주소/stride, demosaic start 누락, TUSER/TLAST remap |
| 색 이상 (녹색/보라) | bayer phase (BGGR↔RGGB), R↔B 스왑이면 frmbuf RGB8↔BGR8 |
| DDR 이상 전반 | CWL=12 재검토 (12↔16) |
| [LIVE] 화면 전체 무신호 | MSA↔VTC 타이밍 불일치, dp_video_in_clk 미연결, xavbuf 소스 선택 |
| [LIVE] 화면 밀림/찢어짐 | vid_out underflow (frmbuf_rd 대역폭), timing Master 모드 확인 |
| [LIVE] 색 채널 뒤바뀜 | 36-bit Concat 순서 ↔ xavbuf live 포맷 설정 불일치 |

### 핵심 상수 모음
| 항목 | 값 |
|---|---|
| TCA9546A 주소 / RPi 채널 | 0x74 / ch2 (쓰기값 0x04) |
| OV5640 주소 / chip ID | 0x3C / 0x300A-B = 0x5640 |
| I2C 속도 | 100 kHz (mux·센서 공통) |
| MIPI | 2-lane, RAW10, 420 Mbps/lane |
| 해상도 / stride | 1920×1080 / 5760 bytes |
| dphy 클럭 | 정확히 200 MHz (Clocking Wizard) |
| 픽셀 클럭 (live) | 148.5 MHz (1080p60, Clocking Wizard clk_out2) |
| 캡처/표시 fps | 30 (카메라) / 60 (DP 출력, 같은 버퍼 2회 읽기) |

## 5. 참고 자료
- 프로젝트 지식: PG232(CSI-2 RX), PG286(Demosaic), PG278(Frmbuf), PG231(VPSS), PG285(Gamma), UG1449(Multimedia), UG1089(KV260)
- Digilent Zybo Z7 Pcam 5C 데모 → OV5640.h 레지스터 시퀀스 출처
- **gtaylormb `ultra96v2_imx219_to_displayport` (GitHub) → live 모드 표시 경로(frmbuf_rd + vid_out + VTC + 36-bit 매핑) 참조 설계 — 이번 구현의 핵심 레퍼런스**
- Xilinx `xdpdma_video_example.c` → DP non-live 출력 예제 (live 실패 시 폴백용)
- 공식 KV260 RPi 파이프라인: Xilinx/kria-vitis-platforms `kv260_ispMipiRx_rpiMipiRx_DP` (핀/IP 설정 검증 출처)
- UG1085 Ch.33 (DP 컨트롤러), VTC = PG016

## 6. 향후 확장 (이번 단계 이후)
- Gamma LUT / VPSS CSC 추가 (색감 보정 필요 시 demosaic 뒤에)
- MAC 가속기(SPI, 검증 완료: RESULT=0x51)와 카메라 파이프라인 통합 PL 디자인
- 100케이스 MAC 자동 테스트 (골든 모델 비교) 재개
