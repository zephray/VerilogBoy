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
//  /   /        Filename           : mig_iobs_0.v
// /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $
// \   \  /  \   Date Created       : Mon May 2 2005
//  \___\/\___\
// Device       : Spartan-3/3E/3A/3A-DSP
// Design Name  : DDR SDRAM
// Purpose      : This module has the instantiations infrastructure_iobs,
//                data_path_iobs and controller_iobs modules.
//*****************************************************************************

`timescale 1ns/100ps
`include "mig_parameters_0.v"

(* X_CORE_INFO = "mig_v3_61_ddr_sp3, Coregen 12.4" , 
   CORE_GENERATION_INFO = "ddr_sp3,mig_v3_61,{component_name=ddr_sp3, data_width=16, memory_width=8, clk_width=1, bank_address=2, row_address=12, column_address=9, no_of_cs=1, cke_width=1, registered=0, data_mask=1, mask_enable=1, load_mode_register=12'b000000100001, ext_load_mode_register=12'b000000000000, language=Verilog, synthesis_tool=ISE, interface_type=DDR_SDRAM, no_of_controllers=1}" *)
  module mig_iobs_0
    (
     input                              clk,
     input                              clk90,
     input                              ddr_rasb_cntrl,
     input                              ddr_casb_cntrl,
     input                              ddr_web_cntrl,
     input                              ddr_cke_cntrl,
     input                              ddr_csb_cntrl,
     input [`ROW_ADDRESS-1:0]           ddr_address_cntrl,
     input [`BANK_ADDRESS-1:0]          ddr_ba_cntrl,
     input                              rst_dqs_div_int,
     input                              dqs_reset,
     input                              dqs_enable,
     inout [((`DATA_STROBE_WIDTH)-1):0] ddr_dqs,
     inout [(`DATA_WIDTH-1):0]          ddr_dq,
     input [(`DATA_WIDTH-1):0]          write_data_falling,
     input [(`DATA_WIDTH-1):0]          write_data_rising,
     input                              write_en_val,
     input [((`DATA_MASK_WIDTH)-1):0]   data_mask_f,
     input [((`DATA_MASK_WIDTH)-1):0]   data_mask_r,
/*     output [`CLK_WIDTH-1:0]            ddr_ck,
     output [`CLK_WIDTH-1:0]            ddr_ck_n,*/
     output                             ddr_rasb,
     output                             ddr_casb,
     output                             ddr_web,
     output [`BANK_ADDRESS-1:0]         ddr_ba,
     output [`ROW_ADDRESS-1:0]          ddr_address,
     output                             ddr_cke,
     output                             ddr_csb,
     output                             rst_dqs_div,
     input                              rst_dqs_div_in,
     output [((`DATA_MASK_WIDTH)-1):0]  ddr_dm,
     output [(`DATA_STROBE_WIDTH-1):0]  dqs_int_delay_in,
     output                             rst_dqs_div_out,
     output [((`DATA_WIDTH)-1):0]       dq
     );

   /*mig_infrastructure_iobs_0 infrastructure_iobs0
     (
      .ddr_ck   (ddr_ck),
      .ddr_ck_n (ddr_ck_n),
      .clk0     (clk)
      );*/

   mig_controller_iobs_0 controller_iobs0
     (
      .clk0              (clk),
      .ddr_rasb_cntrl    (ddr_rasb_cntrl),
      .ddr_casb_cntrl    (ddr_casb_cntrl),
      .ddr_web_cntrl     (ddr_web_cntrl),
      .ddr_cke_cntrl     (ddr_cke_cntrl),
      .ddr_csb_cntrl     (ddr_csb_cntrl),
      .ddr_address_cntrl (ddr_address_cntrl),
      .ddr_ba_cntrl      (ddr_ba_cntrl),
      .rst_dqs_div_int   (rst_dqs_div_int),
      .ddr_rasb          (ddr_rasb),
      .ddr_casb          (ddr_casb),
      .ddr_web           (ddr_web),
      .ddr_ba            (ddr_ba),
      .ddr_address       (ddr_address),
      .ddr_cke           (ddr_cke),
      .ddr_csb           (ddr_csb),
      .rst_dqs_div       (rst_dqs_div),
      .rst_dqs_div_in    (rst_dqs_div_in),
      .rst_dqs_div_out   (rst_dqs_div_out)
      );

   mig_data_path_iobs_0 datapath_iobs0
     (
      .clk                (clk),
      .clk90              (clk90),
      .dqs_reset          (dqs_reset),
      .dqs_enable         (dqs_enable),
      .ddr_dqs            (ddr_dqs),
      .ddr_dq             (ddr_dq),
      .write_data_falling (write_data_falling),
      .write_data_rising  (write_data_rising),
      .write_en_val       (write_en_val),
      .data_mask_f        (data_mask_f),
      .data_mask_r        (data_mask_r),
      .dqs_int_delay_in   (dqs_int_delay_in),
      .ddr_dm             (ddr_dm),
      .ddr_dq_val         (dq)
      );

endmodule
