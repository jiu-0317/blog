
# spi_slave

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

# IR
기존의 decoder, dec_dff_formatter, input_formatter 를 통합했다.

| Port          | Dir | Width | Description            |
| ------------- | --- | ----- | ---------------------- |
| i_clk, i_rstn | in  | 1     |                        |
| i_rx_data     | in  | 16    | SPI 수신 데이터             |
| o_cmd         | out | 3     | control이 받는 command    |
| o_mode        | out | 1     | control이 받는 mode       |
| o_data        | out | 9     | datapath가 받는 E5M3 data |
| o_addr        | out | 4     | datapath가 받는 addr      |

# W_I_RF

| Port          | Dir | Width | Description                   |
| ------------- | --- | ----- | ----------------------------- |
| i_clk, i_rstn | in  | 1     |                               |
| i_w_wen       | in  | 1     | weight write enable (w RF 지정) |
| i_i_wen       | in  | 1     | input write enable (i RF 지정)  |
| i_addr        | in  | 4     | 몇번 register에 쓸지 지정            |
| i_data        | in  | 9     | 쓸 data                        |
| i_clear       | in  | 1     | input valid 초기화               |
| o_w_all_valid | out | 1     | 모든 weight register가 다 찼으면 1   |
| o_i_all_valid | out | 1     | 모든 input register가 다 찼으면 1    |
| o_w_data      | out | 9x9   | weight 저장                     |
| o_i_data      | out | 9x9   | input 저장                      |

# fpu

| Port       | Dir | Width | Description       |
| ---------- | --- | ----- | ----------------- |
| i_start    | in  | 1     | control이 보낸 start |
| i_weight   | in  | 9     |                   |
| i_input    | in  | 9     |                   |
| o_result   | out | 9     |                   |
| ~~o_done~~ | out | 1     | 다 연산하면 done 생성    |

--> FPU_top에서 start 신호 1클락만 지연시켜서 all_done 만들면 됨.  
조합논리니까 9개 done 모아서 all_done 만들 필요 없음.

# FPU_RF

| Port          | Dir | Width | Description               |
| ------------- | --- | ----- | ------------------------- |
| i_clk, i_rstn | in  | 1     |                           |
| i_wen         | in  | 1     | control에서 보낸 write enable |
| i_clear       | in  | 1     | control에서                 |
| i_data        | in  | 9     |                           |
| o_data        | out | 9     |                           |
| o_all_valid   | out | 1     | control로 보내는 valid        |

# FP_adder

| Port     | Dir | Width | Description |
| -------- | --- | ----- | ----------- |
| i_a      | in  | 9     | 연산 대상       |
| i_b      | in  | 9     | 연산 대상       |
| o_result | out | 9     | 연산 결과       |

# ACC
(FP_adder를 instanciation하여 사용.)

| Port          | Dir | Width | Description           |
| ------------- | --- | ----- | --------------------- |
| i_clk, i_rstn | in  | 1     |                       |
| i_start       | in  | 1     | control에서 받는 연산 시작 신호 |
| i_data        | in  | 9     | FPU_RF에서 읽어온 data     |
| o_all_done    | out | 1     | 9개 값의 연산이 끝나면 발생      |
| o_data        | out | 9     | 누적 합이 완료된 값           |

# ACC_R
ACC의 결과를 저장한다. 

| Port          | Dir | Width | Description        |
| ------------- | --- | ----- | ------------------ |
| i_clk, i_rstn | in  | 1     |                    |
| i_wen         | in  | 1     | control에서 보낸 wen   |
| i_mode        | in  | 1     | 0: E4M3 \| 1: E5M2 |
| i_data        | in  | 9     | ACC 결과             |
| o_data        | out | 8     | 축소된 포맷             |
| o_valid       | out | 1     |                    |


