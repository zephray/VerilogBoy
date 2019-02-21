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
//  /   /        Filename           : mig_dqs_delay_0.v
// /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $
// \   \  /  \   Date Created       : Mon May 2 2005
//  \___\/\___\
// Device       : Spartan-3/3E/3A/3A-DSP
// Design Name  : DDR SDRAM
// Purpose      : This module generate the delay in the dqs signal.
//*****************************************************************************


`timescale 1ns/100ps
module mig_dqs_delay_0
  (
   input       clk_in,
   input [4:0] sel_in,
   output      clk_out
   );

   wire delay1;
   wire delay2;
   wire delay3;
   wire delay4;
   wire delay5;

   localparam   HIGH = 1'b1;
   
   LUT4 #
     (
      .INIT (16'hf3c0)
      )
      one 
	(
	 .I0 (HIGH),
	 .I1 (sel_in[4]), 
	 .I2 (delay5), 
	 .I3 (clk_in), 
	 .O  (clk_out)
	 );
 
   LUT4 #
     (
      .INIT (16'hee22)
      ) 
     two 
       (
	.I0 (clk_in), 
	.I1 (sel_in[2]), 
	.I2 (HIGH), 
	.I3 (delay3), 
	.O  (delay4)
	);
   
   LUT4 #
     (
      .INIT (16'he2e2)
      ) 
     three 
       (
	.I0 (clk_in), 
	.I1 (sel_in[0]), 
	.I2 (delay1), 
	.I3 (HIGH), 
	.O  (delay2)
	);
     
   LUT4 #
     (
      .INIT (16'hff00)
      )  
     four 
       (
	.I0 (HIGH), 
	.I1 (HIGH), 
	.I2 (HIGH), 
	.I3 (clk_in), 
	.O (delay1)
	);
   
   LUT4 #
     (
      .INIT (16'hf3c0)
      ) 
     five 
       (
	.I0 (HIGH), 
	.I1 (sel_in[3]), 
	.I2 (delay4), 
	.I3 (clk_in), 
	.O (delay5)
	);
   
   LUT4 #
     (
      .INIT (16'he2e2)
      ) 
     six 
       (
	.I0 (clk_in), 
	.I1 (sel_in[1]), 
	.I2 (delay2), 
	.I3 (HIGH), 
	.O  (delay3)
	);

endmodule
