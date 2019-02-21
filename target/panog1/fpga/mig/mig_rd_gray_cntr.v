//*****************************************************************************
// DISCLAIMER OF LIABILITY
//
// This file contains proprietary and confidential information of
// Xilinx, Inc. ("Xilinx"), that is distributed under a license
// from Xilinx, and may be used, copied and/or disclosed only
// pursuant to the terms of a valid license agreement with Xilinx.
//
// XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
// ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
// EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
// LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
// MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
// does not warrant that functions included in the Materials will
// meet the requirements of Licensee, or that the operation of the
// Materials will be uninterrupted or error-free, or that defects
// in the Materials will be corrected. Furthermore, Xilinx does
// not warrant or make any representations regarding use, or the
// results of the use, of the Materials in terms of correctness,
// accuracy, reliability or otherwise.
//
// Xilinx products are not designed or intended to be fail-safe,
// or for use in any application requiring fail-safe performance,
// such as life-support or safety devices or systems, Class III
// medical devices, nuclear facilities, applications related to
// the deployment of airbags, or any other applications that could
// lead to death, personal injury or severe property or
// environmental damage (individually and collectively, "critical
// applications"). Customer assumes the sole risk and liability
// of any use of Xilinx products in critical applications,
// subject only to applicable laws and regulations governing
// limitations on product liability.
//
// Copyright 2005, 2006, 2007 Xilinx, Inc.
// All rights reserved.
//
// This disclaimer and copyright notice must be retained as part
// of this file at all times.
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor             : Xilinx
// \   \   \/    Version            : 3.6.1
//  \   \        Application	    : MIG
//  /   /        Filename           : mig_rd_gray_cntr.v
// /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $
// \   \  /  \   Date Created       : Mon May 2 2005
//  \___\/\___\
// Device       : Spartan-3/3E/3A/3A-DSP
// Design Name  : DDR SDRAM
// Purpose      :
//*****************************************************************************

`timescale 1ns/100ps

module mig_rd_gray_cntr
  (
   input        clk90,
   input        reset90,
   input        cnt_en,
   output [3:0] rgc_gcnt
   );
   
   wire [3:0] gc_int;
   
   reg [3:0]  d_in;
   reg 	      reset90_r;

   always @( posedge clk90 )
     reset90_r <= reset90;

   assign rgc_gcnt = gc_int;

   always @(gc_int) begin
      case (gc_int)
        4'b0000:  d_in <= 4'b0001;  //1
        4'b0001:  d_in <= 4'b0011;  //3
        4'b0010:  d_in <= 4'b0110;  //6
        4'b0011:  d_in <= 4'b0010;  //2
        4'b0100:  d_in <= 4'b1100;  //c
        4'b0101:  d_in <= 4'b0100;  //4
        4'b0110:  d_in <= 4'b0111;  //7
        4'b0111:  d_in <= 4'b0101;  //5
        4'b1000:  d_in <= 4'b0000;  //0
        4'b1001:  d_in <= 4'b1000;  //8
        4'b1010:  d_in <= 4'b1011;  //b
        4'b1011:  d_in <= 4'b1001;  //9
        4'b1100:  d_in <= 4'b1101;  //d
        4'b1101:  d_in <= 4'b1111;  //f
        4'b1110:  d_in <= 4'b1010;  //a
        4'b1111:  d_in <= 4'b1110;  //e
        default : d_in <= 4'b0001;  //1
      endcase
   end

   FDRE bit0
     (
      .Q  (gc_int[0]),
      .C  (clk90),
      .CE (cnt_en),
      .D  (d_in[0]),
      .R  (reset90_r)
      );

   FDRE bit1
     (
      .Q  (gc_int[1]),
      .C  (clk90),
      .CE (cnt_en),
      .D  (d_in[1]),
      .R  (reset90_r)
      );

   FDRE bit2
     (
      .Q  (gc_int[2]),
      .C  (clk90),
      .CE (cnt_en),
      .D  (d_in[2]),
      .R  (reset90_r)
      );

   FDRE bit3
     (
      .Q  (gc_int[3]),
      .C  (clk90),
      .CE (cnt_en),
      .D  (d_in[3]),
      .R  (reset90_r)
      );

endmodule
