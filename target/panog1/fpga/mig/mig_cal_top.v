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
//  /   /        Filename           : mig_cal_top.v
// /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $
// \   \  /  \   Date Created       : Mon May 2 2005
//  \___\/\___\
// Device       : Spartan-3/3E/3A/3A-DSP
// Design Name  : DDR SDRAM
// Purpose      : This module has the instantiations cal_ctl and tap_dly.
//*****************************************************************************

`timescale 1ns/100ps

(* X_CORE_INFO = "mig_v3_61_ddr_sp3, Coregen 12.4" , 
   CORE_GENERATION_INFO = "ddr_sp3,mig_v3_61,{component_name=ddr_sp3, data_width=16, memory_width=8, clk_width=1, bank_address=2, row_address=12, column_address=9, no_of_cs=1, cke_width=1, registered=0, data_mask=1, mask_enable=1, load_mode_register=12'b000000100001, ext_load_mode_register=12'b000000000000, language=Verilog, synthesis_tool=ISE, interface_type=DDR_SDRAM, no_of_controllers=1}" *)
module mig_cal_top
  (
   input         clk0,
   input         clk0dcmlock,
   input         reset,
   output [4:0]  tapfordqs,
   // debug signals
    output [4:0] dbg_phase_cnt,
    output [5:0] dbg_cnt,
    output       dbg_trans_onedtct,
    output       dbg_trans_twodtct,
    output       dbg_enb_trans_two_dtct
   );

   wire        fpga_rst;
   wire [31:0] flop2_val;

   assign 	 fpga_rst = (~reset || ~clk0dcmlock);

   mig_cal_ctl cal_ctl0
     (
      .clk                    (clk0), 
      .reset                  (fpga_rst), 
      .flop2                  (flop2_val), 
      .tapfordqs              (tapfordqs),
      .dbg_phase_cnt          (dbg_phase_cnt),
      .dbg_cnt                (dbg_cnt),
      .dbg_trans_onedtct      (dbg_trans_onedtct),
      .dbg_trans_twodtct      (dbg_trans_twodtct),
      .dbg_enb_trans_two_dtct (dbg_enb_trans_two_dtct)
      );

   mig_tap_dly tap_dly0
     (
      .clk   (clk0),
      .reset (fpga_rst),
      .tapin (clk0),
      .flop2 (flop2_val)
      );

endmodule
