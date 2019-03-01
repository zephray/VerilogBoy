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
// Copyright 2005, 2006, 2007, 2008 Xilinx, Inc.
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
//  /   /        Filename           : mig_top_0.v
// /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $
// \   \  /  \   Date Created       : Mon May 2 2005
//  \___\/\___\
// Device       : Spartan-3/3E/3A/3A-DSP
// Design Name  : DDR SDRAM
// Purpose      : This modules has the instantiations infrastructure, Iobs,
//                controller and data_paths modules.
//*****************************************************************************

`include "mig_parameters_0.v"
  `timescale 1ns/100ps
module    mig_top_0
  (
   input wire                              rst_dqs_div_in,
   output wire                             rst_dqs_div_out,
   input wire                              clk_int,
   input wire                              clk90_int,
   input wire [4:0]                        delay_sel_val,
   input wire                              sys_rst_val,
   input wire                              sys_rst90_val,
   input wire                              sys_rst180_val,
   input wire [((`DATA_WIDTH*2)-1):0]      user_input_data,
   output wire [((`DATA_WIDTH*2)-1):0]     user_output_data,

   output wire                             user_data_valid,
   input wire [(`TOTAL_ADDRESS-1):0]       user_input_address,
   input wire [2:0]                        user_command_register,
   output wire                             user_cmd_ack,
   input wire                              burst_done,
   output wire                             init_val,
   output wire                             ar_done,
   inout wire [((`DATA_STROBE_WIDTH)-1):0] ddr_dqs,
   inout wire [(`DATA_WIDTH-1):0]          ddr_dq,
   output wire                             ddr_cke,
   output wire                             ddr_cs_n,
   output wire                             auto_ref_req,
   input wire                              wait_200us,
   output wire                             ddr_ras_n,
   output wire                             ddr_cas_n,
   output wire                             ddr_we_n,
   output wire [((`DATA_MASK_WIDTH)-1):0]  ddr_dm,
   input wire [((`DATA_MASK_WIDTH*2)-1):0] user_data_mask,

   output wire [`BANK_ADDRESS-1:0]         ddr_ba,
   output wire [`ROW_ADDRESS-1:0]          ddr_a,
/*   output wire [`CLK_WIDTH-1:0]            ddr_ck,
   output wire [`CLK_WIDTH-1:0]            ddr_ck_n,*/
   //debug_signals
   output wire [4:0]                       dbg_delay_sel, 
   output wire                                        dbg_rst_calib,
   input wire [4:0]				         vio_out_dqs,
   input wire 				         vio_out_dqs_en,
   input wire [4:0]                                   vio_out_rst_dqs_div,
   input wire                                         vio_out_rst_dqs_div_en
        );


   wire                            rst_calib;
   wire [4:0]                      delay_sel;
   wire                            write_enable;
   wire                            dqs_div_rst;
   wire                            dqs_enable;
   wire                            dqs_reset;
   wire [(`DATA_STROBE_WIDTH-1):0] dqs_int_delay_in;
   wire [(`DATA_WIDTH-1):0]        dq;
   wire                            write_en_val;
   wire [((`DATA_MASK_WIDTH)-1):0] data_mask_f;
   wire [((`DATA_MASK_WIDTH)-1):0] data_mask_r;
   wire [(`DATA_WIDTH-1):0]        write_data_falling;
   wire [(`DATA_WIDTH-1):0]        write_data_rising;
   wire                            ddr_rasb_cntrl;
   wire                            ddr_casb_cntrl;
   wire                            ddr_web_cntrl;
   wire [`BANK_ADDRESS-1:0]        ddr_ba_cntrl;
   wire [`ROW_ADDRESS-1:0]         ddr_address_cntrl;
   wire                            ddr_cke_cntrl;
   wire                            ddr_csb_cntrl;
   wire                            rst_dqs_div_int;
   wire                            read_fifo_rden;



   mig_controller_0 controller0
     (
      .auto_ref_req      (auto_ref_req),
      .wait_200us        (wait_200us),
      .clk               (clk_int),
      .rst0              (sys_rst_val),
      .rst180            (sys_rst180_val),
      .address           (
            {user_input_address[`TOTAL_ADDRESS-1: `BANK_ADDRESS + `COLUMN_ADDRESS],
             user_input_address[`COLUMN_ADDRESS - 1: 0]}),
      .bank_address      (
            user_input_address[`BANK_ADDRESS + `COLUMN_ADDRESS - 1: `COLUMN_ADDRESS]),
      .command_register  (user_command_register),
      .burst_done        (burst_done),
      .ddr_rasb_cntrl    (ddr_rasb_cntrl),
      .ddr_casb_cntrl    (ddr_casb_cntrl),
      .ddr_web_cntrl     (ddr_web_cntrl),
      .ddr_ba_cntrl      (ddr_ba_cntrl),
      .ddr_address_cntrl (ddr_address_cntrl),
      .ddr_cke_cntrl     (ddr_cke_cntrl),
      .ddr_csb_cntrl     (ddr_csb_cntrl),
      .dqs_enable        (dqs_enable),
      .dqs_reset         (dqs_reset),
      .write_enable      (write_enable),
      .rst_calib         (rst_calib),
      .rst_dqs_div_int   (rst_dqs_div_int),
      .cmd_ack           (user_cmd_ack),
      .init              (init_val),
      .ar_done           (ar_done),
      .read_fifo_rden    (read_fifo_rden) // Added new signal
      );

   mig_data_path_0  data_path0
     (
      .user_input_data    (user_input_data),
      .user_data_mask     (user_data_mask),
      .clk                (clk_int),
      .clk90              (clk90_int),
      .reset              (sys_rst_val),
      .reset90            (sys_rst90_val),
      .write_enable       (write_enable),
      .rst_dqs_div_in     (dqs_div_rst),
      .delay_sel          (delay_sel),
      .dqs_int_delay_in   (dqs_int_delay_in),
      .dq                 (dq),
      .u_data_val         (user_data_valid),
      .user_output_data   (user_output_data),
      .write_en_val       (write_en_val),
      .data_mask_f        (data_mask_f),
      .data_mask_r        (data_mask_r),
      .write_data_falling (write_data_falling),
      .write_data_rising  (write_data_rising),
      .read_fifo_rden        (read_fifo_rden),    // Added new signal
//debug signals
      .vio_out_dqs           (vio_out_dqs),   
      .vio_out_dqs_en        (vio_out_dqs_en),   
      .vio_out_rst_dqs_div   (vio_out_rst_dqs_div),
      .vio_out_rst_dqs_div_en(vio_out_rst_dqs_div_en)
      );

   mig_infrastructure infrastructure0
     (
      .clk_int            (clk_int),
      .rst_calib1         (rst_calib),
      .delay_sel_val      (delay_sel_val),
      .delay_sel_val1_val (delay_sel),
      .dbg_delay_sel      (dbg_delay_sel),
      .dbg_rst_calib      (dbg_rst_calib)
      );
   mig_iobs_0 iobs0
     (
      .clk                (clk_int),
      .clk90              (clk90_int),
      .ddr_rasb_cntrl     (ddr_rasb_cntrl),
      .ddr_casb_cntrl     (ddr_casb_cntrl),
      .ddr_web_cntrl      (ddr_web_cntrl),
      .ddr_cke_cntrl      (ddr_cke_cntrl),
      .ddr_csb_cntrl      (ddr_csb_cntrl),
      .ddr_address_cntrl  (ddr_address_cntrl),
      .ddr_ba_cntrl       (ddr_ba_cntrl),
      .rst_dqs_div_int    (rst_dqs_div_int),
      .dqs_reset          (dqs_reset),
      .dqs_enable         (dqs_enable),
      .ddr_dqs            (ddr_dqs),
      .ddr_dq             (ddr_dq),
      .write_data_falling (write_data_falling),
      .write_data_rising  (write_data_rising),
      .write_en_val       (write_en_val),
      .data_mask_f        (data_mask_f),
      .data_mask_r        (data_mask_r),
/*      .ddr_ck             (ddr_ck),
      .ddr_ck_n           (ddr_ck_n),*/
      .ddr_rasb           (ddr_ras_n),
      .ddr_casb           (ddr_cas_n),
      .ddr_web            (ddr_we_n),
      .ddr_ba             (ddr_ba),
      .ddr_address        (ddr_a),
      .ddr_cke            (ddr_cke),
      .ddr_csb            (ddr_cs_n),
      .rst_dqs_div        (dqs_div_rst),
      .rst_dqs_div_in     (rst_dqs_div_in),
      .rst_dqs_div_out    (rst_dqs_div_out),
      .dqs_int_delay_in   (dqs_int_delay_in),
      .ddr_dm             (ddr_dm),
      .dq                 (dq)
      );

endmodule
