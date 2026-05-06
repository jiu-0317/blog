// =============================================================================
// FP8 Multiplier - 기능별 모듈 분리 버전
// mode = 0: E5M2,  mode = 1: E4M3
// =============================================================================


// -----------------------------------------------------------------------------
// 1. 입력 언팩: 부호/지수/가수 분리
// -----------------------------------------------------------------------------
module fp8_unpack (
    input        mode,
    input  [7:0] a,
    input  [7:0] b,
    output       sign_a,
    output       sign_b,
    output       sign_out,
    output [4:0] exp_a,
    output [4:0] exp_b,
    output [2:0] mant_a,
    output [2:0] mant_b
);
    assign sign_a   = a[7];
    assign sign_b   = b[7];
    assign sign_out = sign_a ^ sign_b;

    // E5M2: exp=a[6:2](5b), mant=a[1:0](2b)
    // E4M3: exp=a[6:3](4b), mant=a[2:0](3b)
    assign exp_a  = mode ? {1'b0, a[6:3]} : a[6:2];
    assign exp_b  = mode ? {1'b0, b[6:3]} : b[6:2];
    assign mant_a = mode ? a[2:0] : {a[1:0], 1'b0};
    assign mant_b = mode ? b[2:0] : {b[1:0], 1'b0};
endmodule


// -----------------------------------------------------------------------------
// 2. 특수값 감지: zero / inf / nan
// -----------------------------------------------------------------------------
module fp8_special_detect (
    input        mode,
    input  [4:0] exp_a,
    input  [4:0] exp_b,
    input  [2:0] mant_a,
    input  [2:0] mant_b,
    output       a_is_zero,
    output       b_is_zero,
    output       a_is_inf,
    output       b_is_inf,
    output       a_is_nan,
    output       b_is_nan
);
    assign a_is_zero = (exp_a == 5'b0);
    assign b_is_zero = (exp_b == 5'b0);

    // Inf: E5M2만 존재
    assign a_is_inf = ~mode & (exp_a == 5'b11111) & (mant_a == 3'b000);
    assign b_is_inf = ~mode & (exp_b == 5'b11111) & (mant_b == 3'b000);

    // NaN
    assign a_is_nan = mode ? ((exp_a == 5'b01111) & (mant_a == 3'b111))
                           : ((exp_a == 5'b11111) & (mant_a != 3'b000));
    assign b_is_nan = mode ? ((exp_b == 5'b01111) & (mant_b == 3'b111))
                           : ((exp_b == 5'b11111) & (mant_b != 3'b000));
endmodule


// -----------------------------------------------------------------------------
// 3. 지수 덧셈
// -----------------------------------------------------------------------------
module fp8_exp_add (
    input               mode,
    input        [4:0]  exp_a,
    input        [4:0]  exp_b,
    output signed [6:0] exp_raw
);
    wire signed [6:0] bias = mode ? 7'sd7 : 7'sd15;
    assign exp_raw = $signed({2'b0, exp_a}) + $signed({2'b0, exp_b}) - bias;
endmodule


// -----------------------------------------------------------------------------
// 4. 가수 곱셈
// -----------------------------------------------------------------------------
module fp8_mant_mult (
    input  [2:0] mant_a,
    input  [2:0] mant_b,
    output [7:0] mant_product
);
    wire [3:0] full_mant_a = {1'b1, mant_a};
    wire [3:0] full_mant_b = {1'b1, mant_b};
    assign mant_product = full_mant_a * full_mant_b;
endmodule


// -----------------------------------------------------------------------------
// 5. 정규화
// -----------------------------------------------------------------------------
module fp8_normalize (
    input        [7:0]  mant_product,
    input  signed [6:0] exp_raw,
    output       [7:0]  mant_normalized,
    output signed [6:0] exp_normalized
);
    wire mant_msb = mant_product[7];
    assign mant_normalized = mant_msb ? mant_product : (mant_product << 1);
    assign exp_normalized  = mant_msb ? (exp_raw + 7'sd1) : exp_raw;
endmodule


// -----------------------------------------------------------------------------
// 6. 반올림
// -----------------------------------------------------------------------------
module fp8_round (
    input               mode,
    input        [7:0]  mant_normalized,
    input  signed [6:0] exp_normalized,
    output       [2:0]  mant_final,
    output signed [6:0] exp_final
);
    // E5M2: mant=[6:5], guard=[4], round=[3], sticky=[2:0]
    // E4M3: mant=[6:4], guard=[3], round=[2], sticky=[1:0]
    wire [2:0] mant_round_candidate = mode ? mant_normalized[6:4] : {1'b0, mant_normalized[6:5]};
    wire       guard  = mode ? mant_normalized[3] : mant_normalized[4];
    wire       round_ = mode ? mant_normalized[2] : mant_normalized[3];
    wire       sticky = mode ? (|mant_normalized[1:0]) : (|mant_normalized[2:0]);

    wire round_up = guard & (round_ | sticky | mant_round_candidate[0]);
    wire [3:0] mant_rounded = {1'b0, mant_round_candidate} + {3'b0, round_up};

    wire round_overflow = mode ? mant_rounded[3] : mant_rounded[2];
    assign mant_final = round_overflow ? 3'b000 : mant_rounded[2:0];
    assign exp_final  = round_overflow ? (exp_normalized + 7'sd1) : exp_normalized;
endmodule


// -----------------------------------------------------------------------------
// 7. 오버플로 / 언더플로 검사
// -----------------------------------------------------------------------------
module fp8_overflow_check (
    input               mode,
    input  signed [6:0] exp_final,
    input        [2:0]  mant_final,
    output              overflow,
    output              underflow,
    output              e4m3_nan_collision
);
    wire signed [6:0] exp_max_normal = mode ? 7'sd15 : 7'sd30;
    assign overflow           = (exp_final > exp_max_normal);
    assign underflow          = (exp_final <= 7'sd0);
    assign e4m3_nan_collision = mode & (exp_final == 7'sd15) & (mant_final == 3'b111);
endmodule


// -----------------------------------------------------------------------------
// 8. 출력 선택 (특수값 조합 처리 포함)
// -----------------------------------------------------------------------------
module fp8_output_select (
    input               mode,
    input               sign_out,
    input  signed [6:0] exp_final,
    input        [2:0]  mant_final,
    input               a_is_zero,
    input               b_is_zero,
    input               a_is_inf,
    input               b_is_inf,
    input               a_is_nan,
    input               b_is_nan,
    input               overflow,
    input               underflow,
    input               e4m3_nan_collision,
    output       [7:0]  result
);
    wire [7:0] nan_val      = mode ? {sign_out, 4'b1111, 3'b111} : {sign_out, 5'b11111, 2'b01};
    wire [7:0] inf_val      = {sign_out, 5'b11111, 2'b00};
    wire [7:0] zero_val     = {sign_out, 7'b0};
    wire [7:0] max_e4m3     = {sign_out, 4'b1111, 3'b110};
    wire [7:0] overflow_val = mode ? max_e4m3 : inf_val;
    wire [7:0] normal_val   = mode ? {sign_out, exp_final[3:0], mant_final[2:0]}
                                   : {sign_out, exp_final[4:0], mant_final[1:0]};

    reg [7:0] result_reg;
    always @(*) begin
        if (a_is_nan || b_is_nan) begin
            result_reg = nan_val;
        end else if (~mode & ((a_is_zero & b_is_inf) | (a_is_inf & b_is_zero))) begin
            result_reg = nan_val;
        end else if (a_is_inf || b_is_inf) begin
            result_reg = inf_val;
        end else if (a_is_zero || b_is_zero) begin
            result_reg = zero_val;
        end else if (overflow || e4m3_nan_collision) begin
            result_reg = overflow_val;
        end else if (underflow) begin
            result_reg = zero_val;
        end else begin
            result_reg = normal_val;
        end
    end

    assign result = result_reg;
endmodule


// -----------------------------------------------------------------------------
// TOP: fp8_multiplier
// -----------------------------------------------------------------------------
module fp8_multiplier (
    input        mode,   // 0: E5M2, 1: E4M3
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] result
);

    // 1. 언팩
    wire        sign_a, sign_b, sign_out;
    wire [4:0]  exp_a, exp_b;
    wire [2:0]  mant_a, mant_b;

    fp8_unpack u_unpack (
        .mode(mode), .a(a), .b(b),
        .sign_a(sign_a), .sign_b(sign_b), .sign_out(sign_out),
        .exp_a(exp_a), .exp_b(exp_b),
        .mant_a(mant_a), .mant_b(mant_b)
    );

    // 2. 특수값 감지
    wire a_is_zero, b_is_zero, a_is_inf, b_is_inf, a_is_nan, b_is_nan;

    fp8_special_detect u_special (
        .mode(mode),
        .exp_a(exp_a), .exp_b(exp_b),
        .mant_a(mant_a), .mant_b(mant_b),
        .a_is_zero(a_is_zero), .b_is_zero(b_is_zero),
        .a_is_inf(a_is_inf),   .b_is_inf(b_is_inf),
        .a_is_nan(a_is_nan),   .b_is_nan(b_is_nan)
    );

    // 3. 지수 덧셈
    wire signed [6:0] exp_raw;
    fp8_exp_add u_exp_add (
        .mode(mode), .exp_a(exp_a), .exp_b(exp_b), .exp_raw(exp_raw)
    );

    // 4. 가수 곱셈
    wire [7:0] mant_product;
    fp8_mant_mult u_mant_mult (
        .mant_a(mant_a), .mant_b(mant_b), .mant_product(mant_product)
    );

    // 5. 정규화
    wire [7:0] mant_normalized;
    wire signed [6:0] exp_normalized;
    fp8_normalize u_normalize (
        .mant_product(mant_product), .exp_raw(exp_raw),
        .mant_normalized(mant_normalized), .exp_normalized(exp_normalized)
    );

    // 6. 반올림
    wire [2:0] mant_final;
    wire signed [6:0] exp_final;
    fp8_round u_round (
        .mode(mode),
        .mant_normalized(mant_normalized), .exp_normalized(exp_normalized),
        .mant_final(mant_final), .exp_final(exp_final)
    );

    // 7. 오버플로/언더플로 검사
    wire overflow, underflow, e4m3_nan_collision;
    fp8_overflow_check u_ovf (
        .mode(mode),
        .exp_final(exp_final), .mant_final(mant_final),
        .overflow(overflow), .underflow(underflow),
        .e4m3_nan_collision(e4m3_nan_collision)
    );

    // 8. 출력 선택
    fp8_output_select u_out (
        .mode(mode), .sign_out(sign_out),
        .exp_final(exp_final), .mant_final(mant_final),
        .a_is_zero(a_is_zero), .b_is_zero(b_is_zero),
        .a_is_inf(a_is_inf),   .b_is_inf(b_is_inf),
        .a_is_nan(a_is_nan),   .b_is_nan(b_is_nan),
        .overflow(overflow), .underflow(underflow),
        .e4m3_nan_collision(e4m3_nan_collision),
        .result(result)
    );

endmodule
