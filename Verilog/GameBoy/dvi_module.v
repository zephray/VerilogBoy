`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: The Fighting Meerkat
// 
// Create Date:    11:41:00 11/11/2013 
// Design Name: 
// Module Name:    dvi_module 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module dvi_module(//Outputs
            dvi_vs, dvi_hs, dvi_d, dvi_xclk_p, dvi_xclk_n, 
            dvi_de, dvi_reset_b,    
            iic_done, //TEST
            //Inouts
            dvi_sda, dvi_scl,            
            //Inputs
            pixel_clk, 
            shift_clk,
            gpuclk_rst,
            hsync, vsync, blank_b,
            pixel_r, pixel_b, pixel_g);
   
  //Outputs
  output wire dvi_vs, dvi_hs;
  output wire [11:0] dvi_d;
  output wire dvi_xclk_p, dvi_xclk_n;
  output wire dvi_de;
  output wire dvi_reset_b;
  output wire iic_done; //TEST
  
  //Inouts
  inout wire dvi_sda;
  inout wire dvi_scl;
  
  //Inputs
  input pixel_clk, 
        shift_clk,
        gpuclk_rst, 
        hsync, vsync, blank_b;
  input [7:0] pixel_r, pixel_b, pixel_g;
  
  assign dvi_reset_b = 1;
  assign dvi_vs = vsync;
  assign dvi_hs = hsync;
  assign dvi_de = blank_b;
  
//  wire dvi_xclk_p_nodly, dvi_xclk_n_nodly;
  
  `define MAKE_DDR(n,q,d1,d2) ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) n (.C(pixel_clk), .Q(q), .D1(d1), .D2(d2), .R(0), .S(0), .CE(1))
  
  wire [7:0] blue_p, green_p, red_p;
  
  assign blue_p = pixel_b;
  assign green_p = pixel_g;
  assign red_p = pixel_r;
  
//  `MAKE_DDR(ODDR_dvi_xclk_p, dvi_xclk_p_nodly, 1'b1, 1'b0);
//  `MAKE_DDR(ODDR_dvi_xclk_n, dvi_xclk_n_nodly, 1'b0, 1'b1);
  ODDR ODDR_dvi_xclk_p (.C(shift_clk), .Q(dvi_xclk_p), .D1(1'b1), .D2(1'b0), .R(0), .S(0), .CE(1));
  ODDR ODDR_dvi_xclk_n (.C(shift_clk), .Q(dvi_xclk_n), .D1(1'b0), .D2(1'b1), .R(0), .S(0), .CE(1));
//  `MAKE_DDR(ODDR_dvi_de, dvi_de, ~border, ~border);
//  `MAKE_DDR(ODDR_dvi_vs, dvi_vs, vs, vs);
//  `MAKE_DDR(ODDR_dvi_hs, dvi_hs, hs, hs);
  `MAKE_DDR(ODDR_dvi_d_0, dvi_d[0], blue_p[0], green_p[4]);
  `MAKE_DDR(ODDR_dvi_d_1, dvi_d[1], blue_p[1], green_p[5]);
  `MAKE_DDR(ODDR_dvi_d_2, dvi_d[2], blue_p[2], green_p[6]);
  `MAKE_DDR(ODDR_dvi_d_3, dvi_d[3], blue_p[3], green_p[7]);
  `MAKE_DDR(ODDR_dvi_d_4, dvi_d[4], blue_p[4], red_p[0]);
  `MAKE_DDR(ODDR_dvi_d_5, dvi_d[5], blue_p[5], red_p[1]);
  `MAKE_DDR(ODDR_dvi_d_6, dvi_d[6], blue_p[6], red_p[2]);
  `MAKE_DDR(ODDR_dvi_d_7, dvi_d[7], blue_p[7], red_p[3]);
  `MAKE_DDR(ODDR_dvi_d_8, dvi_d[8], green_p[0], red_p[4]);
  `MAKE_DDR(ODDR_dvi_d_9, dvi_d[9], green_p[1], red_p[5]);
  `MAKE_DDR(ODDR_dvi_d_10, dvi_d[10], green_p[2], red_p[6]);
  `MAKE_DDR(ODDR_dvi_d_11, dvi_d[11], green_p[3], red_p[7]);

  iic_init #(.CLK_RATE_MHZ(27)) init (
        // Outputs
      .Done  (iic_done),  
        // Inouts
      .SDA  (dvi_sda),
      .SCL  (dvi_scl),
        // Inputs
      .Clk  (pixel_clk),
      .Reset  (gpuclk_rst),
      .Pixel_clk_greater_than_65Mhz(1'b0)
      );

  /*(* IODELAY_GROUP = "IODELAY_MIG" *)IODELAY delay_p (
    .ODATAIN(dvi_xclk_p_nodly),
    .DATAOUT(dvi_xclk_p),
    .RST(1'b1),
    .T(1'b0),
    .C(1'b0));
    defparam delay_p.IDELAY_TYPE = "FIXED";
    defparam delay_p.IDELAY_VALUE = 0;
    defparam delay_p.ODELAY_VALUE = 24;
    defparam delay_p.DELAY_SRC = "O";

  (* IODELAY_GROUP = "IODELAY_MIG" *)IODELAY delay_n (
    .ODATAIN(dvi_xclk_n_nodly),
    .DATAOUT(dvi_xclk_n),
    .T(1'b0),
    .RST(1'b1),
    .C(1'b0));
    defparam delay_n.IDELAY_TYPE = "FIXED";
    defparam delay_n.IDELAY_VALUE = 0;
    defparam delay_n.ODELAY_VALUE = 24;
    defparam delay_n.DELAY_SRC = "O";*/

endmodule
