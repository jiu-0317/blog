// Verilog Behavioral Model
// Converted from Liberty: /mnt/user-data/uploads/mychips_scl_0_0_1_tt_5_50v.lib
// Library: tt_5.50v | Cells: 31
// specify values = typical corner. SDF will override.
`timescale 1ns/1ps

`celldefine
module AND2X1 (Y, A, B);
    input  A;
    input  B;
    output Y;

    and  (strong0, strong1) (Y, A, B);

    specify
        (A => Y) = (0.3362, 0.4524);
        (B => Y) = (0.3178, 0.5135);
    endspecify

endmodule
`endcelldefine

`celldefine
module AND2X2 (Y, A, B);
    input  A;
    input  B;
    output Y;

    and  (strong0, strong1) (Y, A, B);

    specify
        (A => Y) = (0.3114, 0.4269);
        (B => Y) = (0.2869, 0.4834);
    endspecify

endmodule
`endcelldefine

`celldefine
module AOI21X1 (Y, A, B, C);
    input  A;
    input  B;
    input  C;
    output Y;

    assign Y = (~A & ~C) | (~B & ~C);

    specify
        (A => Y) = (0.4281, 0.2484);
        (B => Y) = (0.3759, 0.293);
        (C => Y) = (0.3476, 0.3039);
    endspecify

endmodule
`endcelldefine

`celldefine
module AOI22X1 (Y, A, B, C, D);
    input  A;
    input  B;
    input  C;
    input  D;
    output Y;

    assign Y = (~A & ~C) | (~A & ~D) | (~B & ~C) | (~B & ~D);

    specify
        (A => Y) = (0.5309, 0.3011);
        (B => Y) = (0.4792, 0.3463);
        (C => Y) = (0.3917, 0.2606);
        (D => Y) = (0.4431, 0.2208);
    endspecify

endmodule
`endcelldefine

`celldefine
module BUFX2 (Y, A);
    input  A;
    output Y;

    buf  (strong0, strong1) (Y, A);

    specify
        (A => Y) = (0.3474, 0.3954);
    endspecify

endmodule
`endcelldefine

`celldefine
module BUFX4 (Y, A);
    input  A;
    output Y;

    buf  (strong0, strong1) (Y, A);

    specify
        (A => Y) = (0.3346, 0.3768);
    endspecify

endmodule
`endcelldefine

`celldefine
module CLKBUFX1 (Y, A);
    input  A;
    output Y;

    buf  (strong0, strong1) (Y, A);

    specify
        (A => Y) = (0.5469, 0.5944);
    endspecify

endmodule
`endcelldefine

`celldefine
module CLKBUFX2 (Y, A);
    input  A;
    output Y;

    buf  (strong0, strong1) (Y, A);

    specify
        (A => Y) = (0.7438, 0.7916);
    endspecify

endmodule
`endcelldefine

`celldefine
module CLKBUFX4 (Y, A);
    input  A;
    output Y;

    buf  (strong0, strong1) (Y, A);

    specify
        (A => Y) = (0.9413, 0.9891);
    endspecify

endmodule
`endcelldefine

`celldefine
module DFFNEGX1 (Q, CLK, D);
    input  CLK;
    input  D;
    output Q;

    reg IQ;
    buf (strong0, strong1) (Q, IQ);
    always @(negedge CLK) IQ <= D;

    specify
        (negedge CLK => (Q : CLK)) = (0.6315, 0.5284);
        $setup(D, negedge CLK, 0.319);
        $hold (negedge CLK, D, 0.2868);
    endspecify

endmodule
`endcelldefine

`celldefine
module DFFPOSX1 (Q, CLK, D);
    input  CLK;
    input  D;
    output Q;

    reg IQ;
    buf (strong0, strong1) (Q, IQ);
    always @(posedge CLK) IQ <= D;

    specify
        (posedge CLK => (Q : CLK)) = (0.3878, 0.693);
        $setup(D, posedge CLK, 0.423);
        $hold (posedge CLK, D, 0.0347);
    endspecify

endmodule
`endcelldefine

`celldefine
module DFFSRX1 (Q, CLK, D, R, S);
    input  CLK;
    input  D;
    input  R;
    input  S;
    output Q;

    reg IQ;
    buf (strong0, strong1) (Q, IQ);
    always @(posedge CLK or posedge R or posedge S)
        if      (R) IQ <= 1'b0;
        else if (S) IQ <= 1'b1;
        else          IQ <= D;

    specify
        (posedge CLK => (Q : CLK)) = (0.8108, 1.0035);
        (posedge R => (Q : R)) = (0.3767, 0.0);
        (posedge S => (Q : S)) = (0.7725, 0.0);
        $setup(D, posedge CLK, 0.1926);
        $hold (posedge CLK, D, 0.0965);
    endspecify

endmodule
`endcelldefine

`celldefine
module FAX1 (CO, S, A, B, CI);
    input  A;
    input  B;
    input  CI;
    output CO;
    output S;

    assign CO = (A & B) | (A & CI) | (B & CI);
    assign S = (A & B & CI) | (A & ~B & ~CI) | (~A & B & ~CI) | (~A & ~B & CI);

    specify
        (A => CO) = (0.4927, 0.6916);
        (B => CO) = (0.5642, 0.6505);
        (CI => CO) = (0.5207, 0.6722);
        (A => S) = (0.5576, 0.6799);
        (B => S) = (0.577, 0.6259);
        (CI => S) = (0.6259, 0.5902);
    endspecify

endmodule
`endcelldefine

`celldefine
module HAX1 (CO, S, A, B);
    input  A;
    input  B;
    output CO;
    output S;

    and  (strong0, strong1) (CO, A, B);
    assign S = (A & ~B) | (~A & B);

    specify
        (A => CO) = (0.3959, 0.5156);
        (B => CO) = (0.3691, 0.5701);
        (A => S) = (0.4454, 0.5179);
        (B => S) = (0.3797, 0.529);
    endspecify

endmodule
`endcelldefine

`celldefine
module INVX1 (Y, A);
    input  A;
    output Y;

    not  (strong0, strong1) (Y, A);

    specify
        (A => Y) = (0.2997, 0.2733);
    endspecify

endmodule
`endcelldefine

`celldefine
module INVX2 (Y, A);
    input  A;
    output Y;

    not  (strong0, strong1) (Y, A);

    specify
        (A => Y) = (0.2302, 0.1994);
    endspecify

endmodule
`endcelldefine

`celldefine
module INVX4 (Y, A);
    input  A;
    output Y;

    not  (strong0, strong1) (Y, A);

    specify
        (A => Y) = (0.1883, 0.1541);
    endspecify

endmodule
`endcelldefine

`celldefine
module INVX8 (Y, A);
    input  A;
    output Y;

    not  (strong0, strong1) (Y, A);

    specify
        (A => Y) = (0.1612, 0.1253);
    endspecify

endmodule
`endcelldefine

`celldefine
module LATCHX1 (Q, CLK, D);
    input  CLK;
    input  D;
    output Q;

    reg IQ;
    buf (strong0, strong1) (Q, IQ);
    always @(*) if (CLK) IQ <= D;

    specify
        (posedge CLK => (Q : CLK)) = (0.4035, 0.6429);
        $setup(D, negedge CLK, 0.3717);
        $hold (negedge CLK, D, 0.2532);
    endspecify

endmodule
`endcelldefine

`celldefine
module MUX2X1 (Y, A, B, S);
    input  A;
    input  B;
    input  S;
    output Y;

    assign Y = (~A & S) | (~B & ~S);

    specify
        (A => Y) = (0.4444, 0.2586);
        (B => Y) = (0.4407, 0.2618);
        (S => Y) = (0.5144, 0.4471);
    endspecify

endmodule
`endcelldefine

`celldefine
module NAND2X1 (Y, A, B);
    input  A;
    input  B;
    output Y;

    assign Y = (~A) | (~B);

    specify
        (A => Y) = (0.3385, 0.2299);
        (B => Y) = (0.3815, 0.192);
    endspecify

endmodule
`endcelldefine

`celldefine
module NAND3X1 (Y, A, B, C);
    input  A;
    input  B;
    input  C;
    output Y;

    assign Y = (~A) | (~B) | (~C);

    specify
        (A => Y) = (0.3447, 0.302);
        (B => Y) = (0.3863, 0.2882);
        (C => Y) = (0.419, 0.2689);
    endspecify

endmodule
`endcelldefine

`celldefine
module NOR2X1 (Y, A, B);
    input  A;
    input  B;
    output Y;

    assign Y = (~A & ~B);

    specify
        (A => Y) = (0.3438, 0.2967);
        (B => Y) = (0.331, 0.3505);
    endspecify

endmodule
`endcelldefine

`celldefine
module NOR3X1 (Y, A, B, C);
    input  A;
    input  B;
    input  C;
    output Y;

    assign Y = (~A & ~B & ~C);

    specify
        (A => Y) = (0.4326, 0.2969);
        (B => Y) = (0.4707, 0.3524);
        (C => Y) = (0.486, 0.3815);
    endspecify

endmodule
`endcelldefine

`celldefine
module OAI21X1 (Y, A, B, C);
    input  A;
    input  B;
    input  C;
    output Y;

    assign Y = (~A & ~B) | (~C);

    specify
        (A => Y) = (0.4374, 0.2542);
        (B => Y) = (0.4493, 0.2145);
        (C => Y) = (0.3421, 0.1927);
    endspecify

endmodule
`endcelldefine

`celldefine
module OAI22X1 (Y, A, B, C, D);
    input  A;
    input  B;
    input  C;
    input  D;
    output Y;

    assign Y = (~A & ~B) | (~C & ~D);

    specify
        (A => Y) = (0.5056, 0.2555);
        (B => Y) = (0.5187, 0.223);
        (C => Y) = (0.4062, 0.2187);
        (D => Y) = (0.392, 0.2555);
    endspecify

endmodule
`endcelldefine

`celldefine
module OR2X1 (Y, A, B);
    input  A;
    input  B;
    output Y;

    assign Y = (A) | (B);

    specify
        (A => Y) = (0.387, 0.4563);
        (B => Y) = (0.4684, 0.4523);
    endspecify

endmodule
`endcelldefine

`celldefine
module OR2X2 (Y, A, B);
    input  A;
    input  B;
    output Y;

    assign Y = (A) | (B);

    specify
        (A => Y) = (0.3703, 0.4353);
        (B => Y) = (0.4456, 0.4258);
    endspecify

endmodule
`endcelldefine

`celldefine
module TBUFX1 (Y, A, EN);
    input  A;
    input  EN;
    output Y;

    assign Y = EN ? (~A) : 1'bz;

    specify
        (A => Y) = (0.4039, 0.2287);
    endspecify

endmodule
`endcelldefine

`celldefine
module XNOR2X1 (Y, A, B);
    input  A;
    input  B;
    output Y;

    xnor (strong0, strong1) (Y, A, B);

    specify
        (A => Y) = (0.5129, 0.446);
        (B => Y) = (0.5724, 0.4638);
    endspecify

endmodule
`endcelldefine

`celldefine
module XOR2X1 (Y, A, B);
    input  A;
    input  B;
    output Y;

    assign Y = (A & ~B) | (~A & B);

    specify
        (A => Y) = (0.5135, 0.4463);
        (B => Y) = (0.5655, 0.4695);
    endspecify

endmodule
`endcelldefine