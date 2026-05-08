
![[Pasted image 20260414170911.png]]

![[Pasted image 20260414170927.png]]

![[Pasted image 20260414170944.png]]

![[Pasted image 20260414171000.png]]

# delay_det (Serial Sequence Analyzer)

```verilog
`define Width 8
`define Duration 8'b00001111 //15

module delay_det
(
    input reset, clk,
    input sr_in,
    output reg sig_start);

reg [3:0] state;
parameter s0=0, s1=1, s2=2, s3=3, s4=4, s5=5, s6=6, s7=7, s8=8, s9=9;

reg [`Width-1:0] cnt;

always @ (posedge clk)
begin
    if (!reset)
        state <= s0;
    else
        case (state)
            s0 :
                if (sr_in==1'b0) state <= s1;
                else             state <= s0;
            s1 :
                if (sr_in==1'b1) state <= s2;
                else             state <= s1;
            s2 :
                if (sr_in==1'b0) state <= s3;
                else             state <= s2;
            s3 :
                state <= s1;
        endcase
end

always @ (posedge clk)
begin
    if (!reset)
        cnt <= {`Width{1'b0}};
    else
        if (state==s2)
            cnt <= cnt + 8'b0000_0001;
        else if (state==s0 || state==s1)
            cnt <= {`Width{1'b0}};
end

always @ (posedge clk)
begin
    if (!reset)
        sig_start <= 1'b0;
    else
        if (state==s3 && cnt==`Duration)
            sig_start <= 1'b1;
        else
            sig_start <= 1'b0;
end

endmodule
```


# sig_gen (Signal Generator)

```verilog
`define Width 8
`define Delay    8'b00001010 //10
`define Duration 8'b00001111 //15

module sig_gen (
            input       reset, clk,
            input       sig_start,
            output      reg sig_out);

reg         [2:0] state;
parameter   s0=0, s1=1, s2=2, s3=3, s4=4, s5=5, s6=6, s7=7;
reg         [`Width-1:0] cnt;
reg         cout;
reg         [`Width-1:0] cnt2;
reg         cout2;

always @ (posedge clk)
begin
    if (!reset)
        state <= s0;
    else
        case (state)
            s0 :
                if (sig_start==1'b1) state <= s1;
                else                 state <= s0;
            s1 :
                if (cout==1'b1)      state <= s2;
                else                 state <= s1;
            s2 :
                if (cout2==1'b1)     state <= s0;
                else                 state <= s2;
        endcase
end

always @ (posedge clk)
begin
    if (!reset)         cnt <= {`Width{1'b0}};
    else
        if (state==s1)  cnt <= cnt + 8'b0000_0001;
        else            cnt <= {`Width{1'b0}};
end

always @ (cnt)
begin
    if (cnt==`Delay) cout <= 1'b1;
    else             cout <= 1'b0;
end

always @ (posedge clk)
begin
    if (!reset)         cnt2 <= {`Width{1'b0}};
    else
        if (state==s2)  cnt2 <= cnt2 + 8'b0000_0001;
        else            cnt2 <= {`Width{1'b0}};
end

always @ (cnt2)
begin
    if (cnt2==`Duration) cout2 <= 1'b1;
    else                 cout2 <= 1'b0;
end

always @ (posedge clk)
begin
    if (!reset)         sig_out <= 1'b0;
    else
        if (state==s2)  sig_out <= 1'b1;
        else            sig_out <= 1'b0;
end
endmodule
```

# delay_det_top (Top Module)

```verilog
module delay_det_top(reset, clk, sr_in, sr_out);

input wire    reset;
input wire    clk;
input wire    sr_in;
output wire   sr_out;
wire          SYNTHESIZED_WIRE_0;

delay_det     b2v_inst(
                .reset(reset),
                .clk(clk),
                .sr_in(sr_in),
                .sig_start(SYNTHESIZED_WIRE_0));

sig_gen       b2v_inst1(
                .reset(reset),
                .clk(clk),
                .sig_start(SYNTHESIZED_WIRE_0),
                .sig_out(sr_out));

endmodule
```

# delay_circuit_tb (Testbench)

```verilog
`timescale 1ns / 10ps

module delay_circuit_tb;

parameter   clk_period = 10;

reg         reset, clk, sr_in;
wire sr_out;

delay_det_top
UUT(.reset(reset), .clk(clk), .sr_in(sr_in), .sr_out(sr_out));

initial
begin
    clk=1'b0;
    forever #(clk_period/2) clk=~clk;
end

initial
begin
    reset=1'b0;
    #(clk_period*2) reset=1'b1;
end

initial
begin
    sr_in = 1'b0;
    #(clk_period*10) sr_in = 1'b1;
    #(clk_period*10) sr_in = 1'b0;
    #(clk_period*10) sr_in = 1'b0;
    #(clk_period*20) sr_in = 1'b1;
    #(clk_period*40) sr_in = 1'b0;
    #(clk_period*10) sr_in = 1'b0;
    #(clk_period*10) sr_in = 1'b1;
    #(clk_period*15) sr_in = 1'b0;
    #(clk_period*3)  sr_in = 1'b1;
    #(clk_period*15) sr_in = 1'b0;
    #(clk_period*10) sr_in = 1'b1;
    #(clk_period*15) sr_in = 1'b0;
end

endmodule
```

# 문제 정의

본 문제는 정해진 길이의 signal을 감지하고 delay 한 뒤 정해진 duration만큼의 signal을 출력하는 코드의 문제를 수정하는 것이다.

발생하는 문제는 duration을 카운팅하는 도중에 sig_start가 들어오면, delay카운팅이 시작되지 않는 것이다.

![[Pasted image 20260502212140.png]]

Sig_gen 에서 각 state가 하는 일은 다음과 같다.

S0: sig_start 감지

S1: delay counting

S2: duration counting (sr_out 출력)

해당 문제는 duration counting을 할 때 state가 S2로 유지되는 중간에 sig_start가 들어오면 state가 S1으로 전이되어 delay counting을 시작하는 것이 아닌 S2로 유지되어 발생하는 문제이다.

그러나 단순히 sig_start가 들어왔다고 S1으로 전이해버리면 duration counting이 멈춰버리니 다른 접근 방법이 필요하다.

# 해결 방안

주어진 문제를 해결하는 방법은 2가지가 있다.

1.     주어진 state machine을 그대로 활용하되, 전이 조건을 수정

2.     counting하는 동안 sig_start가 들어왔을 때를 처리하는 state 추가

본 보고서에서는 1번과 2번을 모두 설명한다.

## 1. 주어진 state machine을 그대로 활용하되, 전이 조건을 수정

문제를 해결하기 위해서는 duration counting 동안 sig_start가 들어오면 duration counting은 그대로 진행하고 delay counting을 새로 시작해야한다.

기존의 설계에서는 각 state마다 하나의 카운팅(delay or duration)을 하기 때문에 문제가 발생하는 것이다.

그러면 S2에서(duration counting을 하는 도중에) sig_start가 들어오면 일단 S1으로 전이해서 delay counting을 시작하고, S2에서 하던 duration counting을 S1에서도 하게 하면 된다.

이때 주의할 부분은 S1에서는 항상 duration count를 하는 것이 아닌 duration count를 하던 도중 S1으로 넘어갔을 때만 duration count를 해야 한다는 것이다.

이는 state가 S1일 때 duration count를 하는 조건을 cnt2가 0이 아닐 때만 하게 조건을 주면 구현할 수 있다.

위 내용을 적용하기 위해서는 기존의 코드를 3줄만 수정하면 된다.

Sig_gen에서 수정된 코드는 다음과 같다:

```verilog
//state machine
always @ (posedge clk)
begin
    if (!reset)
        state <= s0;
    else
        case (state)
            s0 :
                if (sig_start==1'b1) state <= s1;
                else                 state <= s0;
            s1 :
                if (cout==1'b1)      state <= s2;
                else                 state <= s1;
            s2 :
                if (cout2==1'b1)     state <= s0;
                //------------------------------
                else if (sig_start==1'b1) state <= s1;           
                //------------------------------
                else                 state <= s2;
        endcase
end

//duration counter
always @ (posedge clk)
begin                                                     
    if (!reset)         cnt2 <= {`Width{1'b0}};
    else
        if (state==s2 || (state==s1 && cnt!=8'b0))  cnt2 <= cnt2 + 8'b0000_0001;
        //if (state==s2)  cnt2 <= cnt2 + 8'b0000_0001;
        else            cnt2 <= {`Width{1'b0}};
end


//output generation
always @ (posedge clk)
begin
    if (!reset)         sig_out <= 1'b0;
    else
        //if (state==s2)  sig_out <= 1'b1;
        if (state==s2 || (state==s1 && cnt2!=8'b0))  sig_out <= 1'b1;
        else            sig_out <= 1'b0;
end

```

waveform은 다음과 같다:
![[Pasted image 20260502212312.png]]

이렇게 duration counting 도중에 sig_start가 들어와도 output이 잘 출력되는 것을 확인할 수 있다.

## 2. counting하는 동안 sig_start가 들어왔을 때를 처리하는 state 추가

1번에서 설명한 방법도 잘 동작하기는 하지만, 조건에 state가 아닌 것이 추가되었으므로 완전한 state machine이라고 보기에는 어렵다.

따라서 문제가 되는 상황을 처리하는 state를 추가로 만들어주는 방법이 바람직하다.

이를 위해서 발생할 수 있는 각 상황을 정의하면 다음과 같다:

① delay counting(S1) 중 sig_start 발생

② duration counting(S2) 중 sig_start 발생

해당 상황을 state로 구현하기 위해 S1_1와 S2_2를 정의하고 각각 ①, ② 상황에서 전이되는 state로 만들면 된다.

주어진 tb에서는 ②에 해당하는 상황만 발생하므로 ②상황에 맞는 state만 적용한다.

정리하면 S1_1은 S1에서 sig_start발생 시 전이된 결과이고, S2_2는 S2에서 sig_start발생 시 전이된 결과이다.

이때 주의할 부분은 duration이 끝나고 cout2가 발생하는 순간에 delay가 counting중 이라면, state는 이미 S0로 넘어간 이후라 delay counting이 되지 않는다.

이를 방지하기 위해서, duration이 끝나고 cout2가 들어왔어도 delay counting을 지속하는 state인 S0_0를 정의한다.

![[Pasted image 20260502212404.png]]

2번 방법으로 구현한 코드 또한 state machine부분을 제외하면 단 3줄만 수정하면 된다.

수정된 부분은 다음과 같다(state machine코드는 위 그림으로 대신한다):

```verilog
always @ (posedge clk)
begin
    if (!reset)         cnt <= {`Width{1'b0}};
    else
        if (state==s1 || state==s2_2 || state==s0_0 )  cnt <= cnt + 8'b0000_0001;
        else            cnt <= {`Width{1'b0}};
end


always @ (posedge clk)
begin
    if (!reset)         cnt2 <= {`Width{1'b0}};
    else
        if (state==s2 || state==s2_2)  cnt2 <= cnt2 + 8'b0000_0001;
        else            cnt2 <= {`Width{1'b0}};
end


always @ (posedge clk)
begin
    if (!reset)         sig_out <= 1'b0;
    else
        if (state==s2 || state==s2_2)  sig_out <= 1'b1;
        else            sig_out <= 1'b0;
end

```

수정된 코드의 파형은 다음과 같다:
![[Pasted image 20260502212448.png]]

