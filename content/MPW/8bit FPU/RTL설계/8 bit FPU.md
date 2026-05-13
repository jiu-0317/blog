
```verilog
module fp8_multiplier (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] result
);

    // 입력 필드 분리
    wire        sign_a = a[7];
    wire [4:0]  exp_a  = a[6:2];
    wire [1:0]  mant_a = a[1:0];

    wire        sign_b = b[7];
    wire [4:0]  exp_b  = b[6:2];
    wire [1:0]  mant_b = b[1:0];

    // 1. 특수값 사전 감지
    wire a_is_zero = (exp_a == 5'b0);
    wire b_is_zero = (exp_b == 5'b0);
    wire a_is_inf  = (exp_a == 5'b11111) && (mant_a == 2'b00);
    wire b_is_inf  = (exp_b == 5'b11111) && (mant_b == 2'b00);
    wire a_is_nan  = (exp_a == 5'b11111) && (mant_a != 2'b00);
    wire b_is_nan  = (exp_b == 5'b11111) && (mant_b != 2'b00);

    // 2. 부호 계산
    wire sign_out = sign_a ^ sign_b;

    // 3. 지수 덧셈
    wire signed [6:0] exp_raw = $signed({2'b0, exp_a}) + $signed({2'b0, exp_b}) - 7'sd15;

    // 4. 가수 곱셈
    wire [2:0] full_mant_a = {1'b1, mant_a};
    wire [2:0] full_mant_b = {1'b1, mant_b};
    wire [5:0] mant_product = full_mant_a * full_mant_b;

    // 5. 정규화
    wire mant_msb = mant_product[5];
    wire [5:0] mant_normalized = mant_msb ? mant_product : (mant_product << 1);
    wire signed [6:0] exp_normalized = mant_msb ? (exp_raw + 7'sd1) : exp_raw;

    // 6. 반올림
    wire [1:0] mant_round_candidate = mant_normalized[4:3];
    wire       guard  = mant_normalized[2];
    wire       round_ = mant_normalized[1];
    wire       sticky = mant_normalized[0];

    wire round_up = guard & (round_ | sticky | mant_round_candidate[0]);

    wire [2:0] mant_rounded = {1'b0, mant_round_candidate} + {2'b0, round_up};

    //    반올림 오버플로
    wire round_overflow = mant_rounded[2];
    wire [1:0] mant_final = round_overflow ? 2'b00 : mant_rounded[1:0];
    wire signed [6:0] exp_final = round_overflow ? (exp_normalized + 7'sd1) : exp_normalized;

    // 7. 오버플로 / 언더플로 처리
    wire overflow  = (exp_final > 7'sd30);
    wire underflow = (exp_final <= 7'sd0);

    // 8. 특수값 조합에 따른 최종 출력 결정
    reg [7:0] result_reg;

    always @(*) begin
        if (a_is_nan || b_is_nan) begin
            result_reg = {sign_out, 5'b11111, 2'b01};
        end else if ((a_is_zero && b_is_inf) || (a_is_inf && b_is_zero)) begin
            result_reg = {sign_out, 5'b11111, 2'b01};
        end else if (a_is_inf || b_is_inf) begin
            result_reg = {sign_out, 5'b11111, 2'b00};
        end else if (a_is_zero || b_is_zero) begin
            result_reg = {sign_out, 5'b00000, 2'b00};
        end else if (overflow) begin
            result_reg = {sign_out, 5'b11111, 2'b00};
        end else if (underflow) begin
            result_reg = {sign_out, 5'b00000, 2'b00};
        end else begin
            result_reg = {sign_out, exp_final[4:0], mant_final};
        end
    end

    assign result = result_reg;

endmodule

```

