`timescale 1ns / 1ps

module SPI_slave(
    input i_rstn,
    input i_clk,
    input i_SSn,
    input i_MOSI,
    input i_SCLK,
    output o_MISO,
    input [31:0] i_dat,
    output reg [31:0] o_dat
    );

  reg [31:0] RBUF, TBUF;
  reg [31:0] r_dat;
  reg d_SSn;
  wire w_rstn;

  assign o_MISO = TBUF[31];

  always @ (posedge i_SCLK or negedge i_rstn) begin
    if (i_rstn == 1'b0) begin
      RBUF <= 32'h00;
    end
    else begin
      RBUF <= {RBUF[30:00], i_MOSI};
    end
  end

  always @ (posedge i_clk or negedge i_rstn) begin
    if (i_rstn == 1'b0) begin
      d_SSn <= 1'b1;
    end
    else begin
      d_SSn <= i_SSn;
    end
  end

  assign w_rstn = ((i_SSn == 1'b0) && (d_SSn == 1'b1)) ? 1'b0 : 1'b1;

  always @ (negedge i_SCLK or negedge w_rstn) begin
    if (w_rstn == 1'b0) begin
      TBUF <= r_dat;
    end
    else begin
      TBUF <= {TBUF[30:00], 1'b0};
    end
  end

  always @ (posedge i_clk or negedge i_rstn) begin
    if (i_rstn == 1'b0) begin
      r_dat <= 32'h00;
      o_dat <= 32'h00;
    end
    else begin
      if (i_SSn == 1'b1) begin
        r_dat <= i_dat;
        o_dat <= RBUF;
      end
    end
  end

endmodule
