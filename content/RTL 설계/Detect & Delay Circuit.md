
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
parameter s0=0, s1=1, s2=2, s3=3, s4=4, s5=5, s6=6, s7=7,
s8=8, s9=9;

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
parameter   s0=0, s1=1, s2=2, s3=3, s4=4, s5=5, s6=6,
s7=7;
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

# 코드 해석

먼저 delay_det를 보자. 
