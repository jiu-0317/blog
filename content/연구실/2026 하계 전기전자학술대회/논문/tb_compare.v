`timescale 1ns / 1ps

// ============================================================
// 3개 설계 (TOP / TOP_LUT / TOP_LUT_full) 결과 일치 검증 TB
//  - 512 x 512 = 262144 개 입력 조합 전수 검사
//  - 세 모듈 모두 동일한 2-stage 파이프라인 구조이므로
//    같은 클럭에 인가한 입력은 같은 클럭에 출력으로 나온다.
// ============================================================
module tb_compare;

    reg         clk;
    reg         rst_n;
    reg  [8:0]  i_weight;
    reg  [8:0]  i_input;

    wire [8:0]  o_ref;    // TOP          (원본)
    wire [8:0]  o_lut;    // TOP_LUT      (LUT 축소)
    wire [8:0]  o_full;   // TOP_LUT_full (LUT 전체)

    // ---- DUT 인스턴스 ----
    TOP u_ref (
        .clk(clk), .rst_n(rst_n),
        .i_weight(i_weight), .i_input(i_input),
        .o_result(o_ref)
    );

    TOP_LUT u_lut (
        .clk(clk), .rst_n(rst_n),
        .i_weight(i_weight), .i_input(i_input),
        .o_result(o_lut)
    );

    TOP_LUT_full u_full (
        .clk(clk), .rst_n(rst_n),
        .i_weight(i_weight), .i_input(i_input),
        .o_result(o_full)
    );

    // ---- clock ----
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ---- 검증용 변수 ----
    integer w, in;
    integer total_checks;
    integer mismatch_lut;   // ref vs lut
    integer mismatch_full;  // ref vs full
    integer mismatch_lf;    // lut vs full

    // 파이프라인 추적: 2-stage 이므로 인가 후 2클럭 뒤 출력.
    // 비교 시점의 입력값을 보관하는 shift register.
    reg [8:0] w_d1, w_d2;
    reg [8:0] in_d1, in_d2;
    reg       valid_d1, valid_d2;

    // 입력 인가 단계에서 파이프라인 따라 입력값/valid 전달
    always @(posedge clk) begin
        w_d1  <= i_weight;  w_d2  <= w_d1;
        in_d1 <= i_input;   in_d2 <= in_d1;
        valid_d1 <= run_phase;  valid_d2 <= valid_d1;
    end

    reg run_phase;  // 입력을 실제로 인가하는 구간 표시

    // 출력 비교 (출력 레지스터 시점 = d2 입력에 대응)
    always @(posedge clk) begin
        if (valid_d2) begin
            total_checks = total_checks + 1;
            if (o_ref !== o_lut) begin
                mismatch_lut = mismatch_lut + 1;
                $display("[MISMATCH ref vs LUT] w=%h in=%h | ref=%h lut=%h  (t=%0t)",
                          w_d2, in_d2, o_ref, o_lut, $time);
            end
            if (o_ref !== o_full) begin
                mismatch_full = mismatch_full + 1;
                $display("[MISMATCH ref vs FULL] w=%h in=%h | ref=%h full=%h  (t=%0t)",
                          w_d2, in_d2, o_ref, o_full, $time);
            end
            if (o_lut !== o_full) begin
                mismatch_lf = mismatch_lf + 1;
                $display("[MISMATCH LUT vs FULL] w=%h in=%h | lut=%h full=%h  (t=%0t)",
                          w_d2, in_d2, o_lut, o_full, $time);
            end
        end
    end

    // ---- 메인 시퀀스 ----
    initial begin
        // 초기화
        rst_n    = 1'b0;
        i_weight = 9'b0;
        i_input  = 9'b0;
        run_phase= 1'b0;
        total_checks  = 0;
        mismatch_lut  = 0;
        mismatch_full = 0;
        mismatch_lf   = 0;

        // reset 해제
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        // 전수 입력 인가
        run_phase = 1'b1;
        for (w = 0; w < 512; w = w + 1) begin
            for (in = 0; in < 512; in = in + 1) begin
                i_weight = w[8:0];
                i_input  = in[8:0];
                @(posedge clk);
            end
        end
        run_phase = 1'b0;

        // 파이프라인 비우기
        repeat (4) @(posedge clk);

        // ---- 결과 요약 ----
        $display("==================================================");
        $display(" Total checks       : %0d", total_checks);
        $display(" Mismatch ref vs LUT: %0d", mismatch_lut);
        $display(" Mismatch ref vsFULL: %0d", mismatch_full);
        $display(" Mismatch LUT vsFULL: %0d", mismatch_lf);
        if (mismatch_lut==0 && mismatch_full==0 && mismatch_lf==0)
            $display(" RESULT: *** PASS - 3개 설계 결과 모두 일치 ***");
        else
            $display(" RESULT: *** FAIL - 불일치 발생 ***");
        $display("==================================================");
        $finish;
    end

endmodule
