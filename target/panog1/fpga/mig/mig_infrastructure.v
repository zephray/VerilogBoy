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
//  /   /        Filename           : mig_infrastructure.v
// /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $
// \   \  /  \   Date Created       : Mon May 2 2005
//  \___\/\___\
// Device       : Spartan-3/3E/3A/3A-DSP
// Design Name  : DDR SDRAM
// Purpose      :
//*****************************************************************************


  `timescale 1ns/100ps
module mig_infrastructure
  (
   input wire        clk_int,
   input wire        rst_calib1,
   input wire [4:0]  delay_sel_val,
   output wire [4:0] delay_sel_val1_val,
   // debug_signals
   output wire [4:0] dbg_delay_sel, 
   output wire       dbg_rst_calib
   );

   reg [4:0] delay_sel_val1;
   reg 	     rst_calib1_r1;
   reg 	     rst_calib1_r2;

   assign dbg_delay_sel      = delay_sel_val1;
   assign dbg_rst_calib      = rst_calib1_r2;
   assign delay_sel_val1_val = delay_sel_val1;

   always@(negedge clk_int) begin
      rst_calib1_r1 <= rst_calib1;
   end

   always@(posedge clk_int) begin
      rst_calib1_r2 <= rst_calib1_r1;
   end

   always@(posedge clk_int) begin
     if(rst_calib1_r2 == 1'b0)
       delay_sel_val1 <= delay_sel_val;
     else
       delay_sel_val1 <= delay_sel_val1;
   end
   
endmodule
