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
//  /   /        Filename           : mig_tap_dly_%controllerNo.v
// /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $
// \   \  /  \   Date Created       : Mon May 2 2005
//  \___\/\___\
// Device       : Spartan-3/3E/3A/3A-DSP
// Design Name  : DDR SDRAM
// Purpose      : This module generates a 32 bit tap delay register used by the
//                cal_ctl module to find out the phase transitions.
//*****************************************************************************

`timescale 1ns/100ps

module mig_tap_dly
  (
   input         clk,
   input         reset,
   input         tapin,
   output [31:0] flop2
  );

   reg         reset_r;
   wire [31:0] tap/* synthesis syn_keep=1 */;
   wire [31:0] flop1/* synthesis syn_keep=1 */;
   wire        high;

   assign high = 1'b1;

   always @( posedge clk )
     reset_r <= reset;
   
   LUT4 #
     (
      .INIT (16'h0080)
      )
     l0  
       ( 
	 .I0(high), 
	 .I1(high), 
	 .I2(high), 
	 .I3(tapin), 
	 .O(tap[0])
	 );

   LUT4 #
     (
      .INIT (16'h4000)
      )
     l1  
       ( 
	 .I0(tap[0]), 
	 .I1(high), 
	 .I2(high), 
	 .I3(high), 
	 .O(tap[1])
	 );

   LUT4 #
     (
      .INIT (16'h0080)
      )
     l2  
       ( 
	 .I0(high), 
	 .I1(high), 
	 .I2(high), 
	 .I3(tap[1]), 
	 .O(tap[2])
	 );

   LUT4 #
     (
      .INIT (16'h0800)
      )
     l3 
       (
	.I0(high), 
	.I1(high), 
	.I2(tap[2]), 
	.I3(high), 
	.O(tap[3])
	);

   LUT4 #
     (
      .INIT (16'h0080)
      )
     l4  
       ( .I0(high), 
	 .I1(high), 
	 .I2(high), 
	 .I3(tap[3]), 
	 .O(tap[4])
	 );

   LUT4 #
     (
      .INIT (16'h0800)
      )
     l5 
       ( 
	 .I0(high), 
	 .I1(high), 
	 .I2(tap[4]), 
	 .I3(high), 
	 .O(tap[5])
	 );

   LUT4 #
     (
      .INIT (16'h0080)
      )
     l6 
       ( 
	 .I0(high), 
	 .I1(high), 
	 .I2(high), 
	 .I3(tap[5]), 
	 .O(tap[6])
	 );

   LUT4 #
     (
      .INIT (16'h4000)
      )
     l7 
       (
	.I0(tap[6]), 
	.I1(high), 
	.I2(high), 
	.I3(high), 
	.O(tap[7])
	);

   LUT4 #
     (
      .INIT (16'h0080)
      )
     l8 
       ( 
	 .I0(high), 
	 .I1(high), 
	 .I2(high), 
	 .I3(tap[7]), 
	 .O(tap[8])
	 );

   LUT4 #
     (
      .INIT (16'h4000)
      )
     l9 
       ( 
	 .I0(tap[8]), 
	 .I1(high), 
	 .I2(high), 
	 .I3(high), 
	 .O(tap[9])
	 );

   LUT4 #
     (
      .INIT (16'h0080)
      )
     l10 
       ( 
	 .I0(high), 
	 .I1(high), 
	 .I2(high), 
	 .I3(tap[9]), 
	 .O(tap[10])
	 );

   LUT4 #
     (
      .INIT (16'h0800)
      )
     l11
       ( 
	 .I0(high), 
	 .I1(high), 
	 .I2(tap[10]), 
	 .I3(high), 
	 .O(tap[11])
	 );

   LUT4 #
     (
      .INIT (16'h0080)
      )
     l12  
       ( 
	 .I0(high), 
	 .I1(high), 
	 .I2(high), 
	 .I3(tap[11]), 
	 .O(tap[12])
	 );

   LUT4 #
     (
      .INIT (16'h0800)
      )
     l13  
       ( 
	 .I0(high), 
	 .I1(high), 
	 .I2(tap[12]), 
	 .I3(high), 
	 .O(tap[13])
	 );

   LUT4 #
     (
      .INIT (16'h0080)
      )
     l14
       (
	.I0(high), 
	.I1(high), 
	.I2(high), 
	.I3(tap[13]), 
	.O(tap[14])
	);

   LUT4 #
     (
      .INIT (16'h4000)
      )
     l15  
       ( 
	 .I0(tap[14]), 
	 .I1(high), 
	 .I2(high), 
	 .I3(high), 
	 .O(tap[15])
	 );

   LUT4 #
     (
      .INIT (16'h0080)
      )
     l16  
       ( 
	 .I0(high), 
	 .I1(high), 
	 .I2(high), 
	 .I3(tap[15]), 
	 .O(tap[16])
	 );

   LUT4 #
     (
      .INIT (16'h0800)
      )
     l17  
       ( 
	 .I0(high), 
	 .I1(high), 
	 .I2(tap[16]), 
	 .I3(high), 
	 .O(tap[17])
	 );

   LUT4 #
     (
      .INIT (16'h0080)
      )
     l18  
       ( 
	 .I0(high), 
	 .I1(high), 
	 .I2(high), 
	 .I3(tap[17]), 
	 .O(tap[18])
	 );

   LUT4 #
     (
      .INIT (16'h0800)
      )
     l19
       (
	.I0(high), 
	.I1(high), 
	.I2(tap[18]), 
	.I3(high), 
	.O(tap[19])
	);

   LUT4 #
     (
      .INIT (16'h0080)
      )
     l20  
       (
	.I0(high), 
	.I1(high), 
	.I2(high), 
	.I3(tap[19]), 
	.O(tap[20])
	);

   LUT4 #
     (
      .INIT (16'h0080)
      )
     l21  
       (
	.I0(high), 
	.I1(high), 
	.I2(high), 
	.I3(tap[20]), 
	.O(tap[21])
	);

   LUT4 #
     (
      .INIT (16'h4000)
      )
     l22  
       ( 
	 .I0(tap[21]), 
	 .I1(high), 
	 .I2(high), 
	 .I3(high), 
	 .O(tap[22])
	 );

   LUT4 #
     (
      .INIT (16'h0080)
      )
     l23  
       (
	.I0(high), 
	.I1(high), 
	.I2(high), 
	.I3(tap[22]), 
	.O(tap[23])
	);
   
   LUT4 #
     (
      .INIT (16'h0800)
      )
     l24  
       ( 
	 .I0(high), 
	 .I1(high), 
	 .I2(tap[23]), 
	 .I3(high), 
	 .O(tap[24])
	 );

   LUT4 #
     (
      .INIT (16'h0080)
      )
     l25  
       ( 
	 .I0(high), 
	 .I1(high), 
	 .I2(high), 
	 .I3(tap[24]), 
	 .O(tap[25])
	 );

   LUT4 #
     (
      .INIT (16'h0800)
      )
     l26  
       (
	.I0(high), 
	.I1(high), 
	.I2(tap[25]), 
	.I3(high), 
	.O(tap[26])
	);

   LUT4 #
     (
      .INIT (16'h0080)
      )
     l27  
       (
	.I0(high), 
	.I1(high), 
	.I2(high), 
	.I3(tap[26]), 
	.O(tap[27])
	);

   LUT4 #
     (
      .INIT (16'h4000)
      )
     l28  
       (
	.I0(tap[27]), 
	.I1(high), 
	.I2(high), 
	.I3(high), 
	.O(tap[28])
	);

   LUT4 #
     (
      .INIT (16'h0080)
      )
     l29  
       ( 
	 .I0(high), 
	 .I1(high), 
	 .I2(high), 
	 .I3(tap[28]), 
	 .O(tap[29])
	 );

   LUT4 #
     (
      .INIT (16'h4000)
      )
     l30  
       (
	.I0(tap[29]), 
	.I1(high), 
	.I2(high), 
	.I3(high), 
	.O(tap[30])
	);

   LUT4 #
     (
      .INIT (16'h0080)
      )
     l31  
       ( 
	 .I0(high), 
	 .I1(high), 
	 .I2(high), 
	 .I3(tap[30]), 
	 .O(tap[31])
	 );

   genvar tap_i;
   generate for(tap_i = 0; tap_i < 32;  tap_i = tap_i + 1) begin: gen_tap1
      FDR r
        (
          .Q (flop1[tap_i]),
          .C (clk),
          .D (tap[tap_i]),
          .R (reset_r)
          );
   end
   endgenerate

   genvar tap1_i;
   generate for(tap1_i = 0; tap1_i < 31;  tap1_i = tap1_i + 1) begin: gen_tap2
      FDR u
        (
          .Q (flop2[tap1_i]),
          .C (clk),
          .D (flop1[tap1_i] ~^ flop1[tap1_i + 1]),
          .R (reset_r)
          );
   end
   endgenerate

   FDR u31
     (
       .Q (flop2[31]),
       .C (clk),
       .D (flop1[31]),
       .R (reset_r)
       );

endmodule
