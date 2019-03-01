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
//  /   /        Filename           : mig_data_read_controller_0.v
// /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $
// \   \  /  \   Date Created       : Mon May 2 2005
//  \___\/\___\
// Device       : Spartan-3/3E/3A/3A-DSP
// Design Name  : DDR SDRAM
// Purpose      : This module has instantiation for fifo_0_wr_en, fifo_1_wr_en,
//                dqs_delay and wr_gray_cntr.
//*****************************************************************************
`timescale 1ns/100ps
`include "mig_parameters_0.v"

module mig_data_read_controller_0
  (
   input wire                               clk,
   input wire                               reset,
   input wire                               rst_dqs_div_in,
   input wire [4:0]                         delay_sel,
   input wire  [(`DATA_STROBE_WIDTH-1):0]   dqs_int_delay_in,
   output wire [(`DATA_STROBE_WIDTH-1):0]   fifo_0_wr_en_val,
   output wire [(`DATA_STROBE_WIDTH-1):0]   fifo_1_wr_en_val,
   output wire [(4*`DATA_STROBE_WIDTH)-1:0] fifo_0_wr_addr_val,
   output wire [(4*`DATA_STROBE_WIDTH)-1:0] fifo_1_wr_addr_val,
   output wire [(`DATA_STROBE_WIDTH-1):0]   dqs_delayed_col0_val,
   output wire [(`DATA_STROBE_WIDTH-1):0]   dqs_delayed_col1_val,
   //debug_signals
   input wire [4:0]				vio_out_dqs,
   input wire 				vio_out_dqs_en,
   input wire [4:0]                          vio_out_rst_dqs_div,
   input wire                                vio_out_rst_dqs_div_en
  );

   reg 	                             reset_r;

   wire 			     rst_dqs_div;
   wire [(4*`DATA_STROBE_WIDTH)-1:0] fifo_0_wr_addr;
   wire [(4*`DATA_STROBE_WIDTH)-1:0] fifo_1_wr_addr;
   wire [(`DATA_STROBE_WIDTH-1):0]   rst_dqs_delay_n;
   wire [(`DATA_STROBE_WIDTH-1):0]   dqs_delayed_col0_n;
   wire [(`DATA_STROBE_WIDTH-1):0]   dqs_delayed_col1_n;   
   wire  [(`DATA_STROBE_WIDTH-1):0]  fifo_0_wr_en/* synthesis syn_keep=1 */;
   wire [(`DATA_STROBE_WIDTH-1):0]   fifo_1_wr_en/* synthesis syn_keep=1 */;
   wire [4:0]                        delay_sel_rst_dqs_div;
   wire [4:0]			     delay_sel_dqs;
   (* BUFFER_TYPE = "none" *) wire [(`DATA_STROBE_WIDTH-1):0]   dqs_delayed_col0;
   (* BUFFER_TYPE = "none" *) wire [(`DATA_STROBE_WIDTH-1):0]   dqs_delayed_col1;

   
   assign fifo_0_wr_addr_val    = fifo_0_wr_addr;
   assign fifo_1_wr_addr_val    = fifo_1_wr_addr;
   assign fifo_0_wr_en_val      = fifo_0_wr_en;
   assign fifo_1_wr_en_val      = fifo_1_wr_en;
   assign dqs_delayed_col0_val  = dqs_delayed_col0;
   assign dqs_delayed_col1_val  = dqs_delayed_col1;
   assign dqs_delayed_col0_n    = ~ dqs_delayed_col0;
   assign dqs_delayed_col1_n    = ~ dqs_delayed_col1;


   always @(posedge clk)
     reset_r <= reset;


   generate
      if(`DEBUG_EN) 
	assign delay_sel_rst_dqs_div = (vio_out_rst_dqs_div_en) ? 
                                       vio_out_rst_dqs_div[4:0] : 
                                       delay_sel;
      else
	assign delay_sel_rst_dqs_div = delay_sel;
   endgenerate

// rst_dqs_div instantation. 
   mig_dqs_delay_0 rst_dqs_div_delayed
     (
      .clk_in  (rst_dqs_div_in),
      .sel_in(delay_sel_rst_dqs_div),
      .clk_out (rst_dqs_div)
      );

   generate 
      if(`DEBUG_EN) 
         assign delay_sel_dqs = vio_out_dqs_en ? vio_out_dqs[4:0] : delay_sel;
      else 
        assign delay_sel_dqs = delay_sel;
   endgenerate
//DQS Internal Delay Circuit implemented in LUTs

   genvar dly_i;
   generate
      for(dly_i = 0; dly_i < `DATA_STROBE_WIDTH;
	  dly_i = dly_i + 1) begin: gen_delay
	 mig_dqs_delay_0 dqs_delay_col0
	   (
            .clk_in  (dqs_int_delay_in[dly_i]),
	      .sel_in	(delay_sel_dqs),
            .clk_out (dqs_delayed_col0[dly_i])
            )/* synthesis syn_preserve=1 */;
	 
	 mig_dqs_delay_0 dqs_delay_col1
	   (
            .clk_in  (dqs_int_delay_in[dly_i]),
	      .sel_in	(delay_sel_dqs),
            .clk_out (dqs_delayed_col1[dly_i])
            )/* synthesis syn_preserve=1 */;
      end
   endgenerate


// FIFO write enables instances
   genvar wren_i;
   generate
      for(wren_i = 0; wren_i < `DATA_STROBE_WIDTH; 
	  wren_i = wren_i + 1) begin: gen_wr_en
	 mig_fifo_0_wr_en_0 fifo_0_wr_en_inst
           (
            .clk             ( dqs_delayed_col1_n [wren_i]),
            .reset           (reset_r),
            .din             (rst_dqs_div),
            .rst_dqs_delay_n (rst_dqs_delay_n[wren_i]),
            .dout            (fifo_0_wr_en[wren_i])
            );
	 
	 mig_fifo_1_wr_en_0 fifo_1_wr_en_inst
	   (
            .clk             (dqs_delayed_col0[wren_i]),
            .rst_dqs_delay_n (rst_dqs_delay_n[wren_i]),
            .reset           (reset_r),
            .din             (rst_dqs_div),
            .dout            (fifo_1_wr_en[wren_i])
            );
      end
   endgenerate

//FIFO write pointer instances
   
   genvar wr_addr_i;
   generate
      for(wr_addr_i = 0; wr_addr_i < `DATA_STROBE_WIDTH;
	  wr_addr_i = wr_addr_i + 1) begin: gen_wr_addr
        mig_wr_gray_cntr fifo_0_wr_addr_inst
          (
           .clk      (dqs_delayed_col1[wr_addr_i]),
           .reset    (reset_r),
           .cnt_en   (fifo_0_wr_en[wr_addr_i]),
           .wgc_gcnt (fifo_0_wr_addr[wr_addr_i*4+:4])
          );
	 
        mig_wr_gray_cntr fifo_1_wr_addr_inst
          (
           .clk      (dqs_delayed_col0_n[wr_addr_i]),
           .reset    (reset_r),
           .cnt_en   (fifo_1_wr_en[wr_addr_i]),
           .wgc_gcnt (fifo_1_wr_addr[wr_addr_i*4+:4])
           );
      end
    endgenerate

endmodule
