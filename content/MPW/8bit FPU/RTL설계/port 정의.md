
![[Pasted image 20260517175340.png]]

먼저 말로 동작을 설명하며 필요한 부분을 정리해보겠다.

Decoder는 SPI로 받아온(command는 load weight 또는 input) data, command, mode(output이 E5M2인지 E4M3인지), address를 분리한다.
Decoder 다음에 있는 DFF는 formatter에 들어갈 valid한 E4M3 또는 E5M2 값이 들어간다.
formatter는 DFF에서 값을 가져와 E5M2또는 E4M3를 E5M3로 확장. 
formatter다음 Router는 address에 맞는 weight/input DFF에 확장된 값을 넣어준다.
그러면 weight 와 input DFF에 각각 값이 저장된다. 
weight와 input DFF에 값이 다 로드되었으면 SPI로 compute command를 보낸다.
그러면 FPU가 연산을 시작하고, output DFF에 valid한 결과값이 저장된다. 
그리고 accumulate command를 보내면 이게 순차적으로 ACC에 들어가서 누적합이 된다.
그러면 ACC다음에 있는 DFF에 누적 합의 결과가 저장되고, 이게 필터 연산 1번 한 결과가 된다.
이걸 다시 SPI로 내보내는 것이다. 

SPI로 받아오는 각 필드는 command(3bit), data(8bit), addr(4bit), mode(1bit) 로 이루어져있다. 

이제 필요한 각 module과 in/out port를 정의해보겠다. 

# spi_slave
기존의 코드를 데이터 비트만 수정해서 사용할 예정이다. 
![[SPI_slave.v]]

| Port    | Dir | Width | Description         |
| ------- | --- | ----- | ------------------- |
| i_rstn  | in  | 1     | active low rst      |
| i_clk   | in  | 1     | clock               |
| i_SSn   | in  | 1     | slave select        |
| i_MOSI  | in  | 1     | master in slave out |
| i_SCLK  | in  | 1     | slave clock         |
| i_dat   | in  | 16    | master로 보낼 data     |
| o_MISO  | out | 1     | master in slave out |
| o_dat   | out | 16    | master에서 수신된 data   |
| o_valid | out | 1     | SSn rising edge 검출  |

# Decoder
Decoder는 SPI로부터 받아온 16bit를 각 필드로 나눈다.

| Port          | Dir | Width | Description  |
| ------------- | --- | ----- | ------------ |
| i_clk, i_rstn | in  | 1     |              |
| i_rx_data     | in  | 16    | SPI 수신 데이터   |
| i_rx_valid    | in  | 1     | 수신 완료        |
| o_cmd         | out | 3     | 명령 코드        |
| o_data        | out | 8     | 8-bit 원본 데이터 |
| o_addr        | out | 4     | 대상 DFF 주소    |
| o_mode        | out | 1     | E4M3/E5M2 선택 |
| o_valid       | out | 1     | 디코딩 완료       |


# dec_DFF_formatter
디코더의 output, formatter의 input DFF.

| Port          | Dir | Width | Description          |
| ------------- | --- | ----- | -------------------- |
| i_clk, i_rstn | in  | 1     |                      |
| i_data        | in  | 8     | decoder에서 들어온 data   |
| i_valid       | in  | 1     | decoder에서 들어온 valid  |
| o_dff         | out | 8     | dff에 저장된 data        |
| o_valid       | out | 1     | valid한 data 저장한 뒤 생성 |

# formatter
E4M3/E5M2를 E5M3로 확장한다. 
이때 E4M3는 확장할 때 bias보정을 진행한다.

| Port    | Dir | Width | Description |
| ------- | --- | ----- | ----------- |
| i_mode  | in  | 1     | 입력 포맷 선택    |
| i_data  | in  | 8     | 원본 FP8 값    |
| i_valid | in  | 1     |             |
| o_data  | out | 9     | E5M3 확장 값   |
| o_valid | out | 1     |             |

# router
SPI에서 받아온 addr로 data를 보낸다. 

| Port          | Dir | Width | Description                 |
| ------------- | --- | ----- | --------------------------- |
| i_clk, i_rstn | in  | 1     |                             |
| i_cmd         | in  | 2     | LOAD_WEIGHT / LOAD_INPUT 구분 |
| i_addr        | in  | 4     | 대상 DFF 인덱스 (0~8)            |
| i_data        | in  | 9     | E5M3 데이터                    |
| i_valid       | in  | 1     |                             |
| o_data        | out | 9     | weight/input DFF로 가는 데이터    |
| o_addr        | out | 4     | weight/input DFF 주소         |
| o_w_wen       | out | 1     | weight write enable         |
| o_i_wen       | out | 1     | input write enable          |

# weight_dff

| Port          | Dir | Width | Description            |
| ------------- | --- | ----- | ---------------------- |
| i_clk         | in  | 1     |                        |
| i_data        | in  | 9     | 쓸 데이터 (E5M3)           |
| i_addr        | in  | 4     | DFF 인덱스                |
| i_wen         | in  | 1     | write enable           |
| o_data[0]~[8] | out | 9×9   | 9개 DFF 출력 (FPU로 상시 연결) |

# input_dff

| Port          | Dir | Width | Description            |
| ------------- | --- | ----- | ---------------------- |
| i_clk         | in  | 1     |                        |
| i_data        | in  | 9     | 쓸 데이터 (E5M3)           |
| i_addr        | in  | 4     | DFF 인덱스                |
| i_wen         | in  | 1     | write enable           |
| o_data[0]~[8] | out | 9×9   | 9개 DFF 출력 (FPU로 상시 연결) |

# fpu

| Port     | Dir | Width | Description     |
| -------- | --- | ----- | --------------- |
| i_cmd    | in  | 3     | COMPUTE인지 확인    |
| i_weight | in  | 9     |                 |
| i_input  | in  | 9     |                 |
| o_result | out | 9     |                 |
| o_valid  | out | 1     | 다 연산하면 valid 생성 |

