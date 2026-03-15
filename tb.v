`timescale 1ns / 1ps
module dut( );
 reg  rst, clk_wr, clk_rd, wr_en, rd_en;
 reg [7:0] din;
 wire [7:0] dout;
 wire empty, full;
 asy_fifo z(.rst(rst), .clk_rd(clk_rd), .clk_wr(clk_wr), .din(din), .dout(dout), .empty(empty), .full(full), .wr_en(wr_en), .rd_en(rd_en));
 
 initial begin
 clk_wr = 1'b0;
 forever #5clk_wr = ~ clk_wr;
 end
 
 initial begin
 clk_rd = 1'b0;
  forever #10clk_rd = ~ clk_rd;
 end
 
 initial begin
 rst = 0;
 din = 0;
 wr_en = 0;
 rd_en = 0;
 $monitor("%0b  clk_wr=%0b  clk_rd=%0b  wr_en = %0b  rd_en = %0b  din = %0b  dout = %0b  empty = %0b  full = %0b", $time, 
 clk_wr, clk_rd, wr_en, rd_en, din, dout, empty, full);
 #50;
 rst = 1'b1;
 #5;
 wr_en = 1'd1;
 rd_en = 1'd1;
 din = 8'h3d;
 #50000;
 $finish;
 end
 endmodule
