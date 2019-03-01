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
//  /   /        Filename           : mig_data_path_0.v
// /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $
// \   \  /  \   Date Created       : Mon May 2 2005
//  \___\/\___\
// Device       : Spartan-3/3E/3A/3A-DSP
// Design Name  : DDR SDRAM
// Purpose      : This module has the write and read data paths for the
//                DDR1 memory interface. The write data along with write enable
//                signals are forwarded to the DDR IOB FFs. The read data is
//                captured in CLB FFs and finally input to FIFOs.
//*****************************************************************************

`timescale 1ns/100ps
`include "mig_parameters_0.v"

module mig_data_path_0
  (
   input wire [((`DATA_WIDTH*2)-1):0]       user_input_data,
   input wire [((`DATA_MASK_WIDTH*2) -1):0] user_data_mask,
   input wire                               clk,
   input wire                               clk90,
   input wire                               reset,
   input wire                               reset90,
   input wire                               write_enable,
   input wire                               rst_dqs_div_in,
   input wire [4:0]                         delay_sel,
   input wire [(`DATA_WIDTH-1):0]           dq,
   input wire [(`DATA_STROBE_WIDTH-1):0]    dqs_int_delay_in,
   input wire                               read_fifo_rden, // Added new signal
   output wire                              u_data_val,
   output wire [((`DATA_WIDTH*2)-1):0]      user_output_data,
   output wire                              write_en_val,
   output wire [((`DATA_MASK_WIDTH)-1):0]   data_mask_f,
   output wire [((`DATA_MASK_WIDTH)-1):0]   data_mask_r,
   output wire [(`DATA_WIDTH-1):0]          write_data_falling,
   output wire [(`DATA_WIDTH-1):0]          write_data_rising,
   //debug_signals
   input wire [4:0]				vio_out_dqs,
   input wire 				vio_out_dqs_en,
   input wire [4:0]                          vio_out_rst_dqs_div,
   input wire                                vio_out_rst_dqs_div_en
   );

   wire [(4*`DATA_STROBE_WIDTH)-1:0] fifo_0_wr_addr;
   wire [(4*`DATA_STROBE_WIDTH)-1:0] fifo_1_wr_addr;
   wire [(`DATA_STROBE_WIDTH-1):0]   dqs_delayed_col0;
   wire [(`DATA_STROBE_WIDTH-1):0]   dqs_delayed_col1;
   wire [(`DATA_STROBE_WIDTH-1):0]   fifo_0_wr_en/* synthesis syn_keep=1 */;
   wire [(`DATA_STROBE_WIDTH-1):0]   fifo_1_wr_en/* synthesis syn_keep=1 */;

   mig_data_read_0 data_read0
     (
      .clk90             (clk90),
      .reset90           (reset90),
      .ddr_dq_in         (dq),
      .fifo_0_wr_en      (fifo_0_wr_en),
      .fifo_1_wr_en      (fifo_1_wr_en),
      .fifo_0_wr_addr    (fifo_0_wr_addr),
      .fifo_1_wr_addr    (fifo_1_wr_addr),
      .dqs_delayed_col0  (dqs_delayed_col0),
      .dqs_delayed_col1  (dqs_delayed_col1),
      .read_fifo_rden    (read_fifo_rden), 
      .user_output_data  (user_output_data),
      .u_data_val        (u_data_val)
      );

   mig_data_read_controller_0  data_read_controller0
     (
      .clk                   (clk),
      .reset                 (reset),
      .rst_dqs_div_in        (rst_dqs_div_in),
      .delay_sel             (delay_sel),
      .dqs_int_delay_in      (dqs_int_delay_in),
      .fifo_0_wr_en_val      (fifo_0_wr_en),
      .fifo_1_wr_en_val      (fifo_1_wr_en),
      .fifo_0_wr_addr_val    (fifo_0_wr_addr),
      .fifo_1_wr_addr_val    (fifo_1_wr_addr),
      .dqs_delayed_col0_val  (dqs_delayed_col0),
      .dqs_delayed_col1_val  (dqs_delayed_col1),
   //debug_signals
      .vio_out_dqs           (vio_out_dqs),   
      .vio_out_dqs_en        (vio_out_dqs_en),   
      .vio_out_rst_dqs_div   (vio_out_rst_dqs_div),
      .vio_out_rst_dqs_div_en(vio_out_rst_dqs_div_en)
      );

   mig_data_write_0 data_write0
     (
      .user_input_data    (user_input_data),
      .user_data_mask     (user_data_mask),
      .clk90              (clk90),
      .write_enable       (write_enable),
      .write_en_val       (write_en_val),
      .write_data_falling (write_data_falling),
      .write_data_rising  (write_data_rising),
      .data_mask_f        (data_mask_f),
      .data_mask_r        (data_mask_r)
      );


endmodule
