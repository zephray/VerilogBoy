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
//  /   /        Filename           : mig_data_path_iobs_0.v
// /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $
// \   \  /  \   Date Created       : Mon May 2 2005
//  \___\/\___\
// Device       : Spartan-3/3E/3A/3A-DSP
// Design Name  : DDR SDRAM
// Purpose      : This module has the instantiations s3_dq_iob, s3_dqs_iob
//                and ddr_dm modules.
//*****************************************************************************

`timescale 1ns/100ps
`include "mig_parameters_0.v"

module mig_data_path_iobs_0
  (
   input wire                             clk,
   input wire                             clk90,
   input wire                             dqs_reset,
   input wire                             dqs_enable,
   inout wire  [(`DATA_STROBE_WIDTH-1):0] ddr_dqs,
   inout wire  [(`DATA_WIDTH-1):0]        ddr_dq,
   input wire  [(`DATA_WIDTH-1):0]        write_data_falling,
   input wire  [(`DATA_WIDTH-1):0]        write_data_rising,
   input wire                             write_en_val,
   output wire [(`DATA_STROBE_WIDTH-1):0] dqs_int_delay_in,
   output wire [((`DATA_MASK_WIDTH)-1):0] ddr_dm,
   input wire  [(`DATA_MASK_WIDTH-1):0]   data_mask_f,
   input wire  [(`DATA_MASK_WIDTH-1):0]   data_mask_r,
   output wire [(`DATA_WIDTH-1):0]        ddr_dq_val
   );

   wire [(`DATA_WIDTH-1):0] ddr_dq_in;

   localparam MASK_CHK = `MASK_ENABLE;

   assign ddr_dq_val = ddr_dq_in;


//***********************************************************************
// DM IOB instantiations
//***********************************************************************
  genvar mask_i;
   generate
     if(MASK_CHK == 1'd1) begin : MASK_INST
       for(mask_i = 0; mask_i < `DATA_MASK_WIDTH; mask_i = mask_i+1) begin: gen_dm
	 mig_s3_dm_iob s3_dm_iob_inst
	   (
	    .ddr_dm       (ddr_dm[mask_i]),
	    .mask_falling (data_mask_f[mask_i]),
	    .mask_rising  (data_mask_r[mask_i]),
	    .clk90        (clk90)
	    );
       end
     end
   endgenerate

//***********************************************************************
//    Read Data Capture Module Instantiations
//***********************************************************************
// DQS IOB instantiations
//***********************************************************************

  genvar dqs_i;
  generate
    for(dqs_i = 0; dqs_i < `DATA_STROBE_WIDTH; dqs_i = dqs_i+1) begin: gen_dqs
       mig_s3_dqs_iob  s3_dqs_iob_inst
	 (
	  .clk            (clk),
	  .ddr_dqs_reset  (dqs_reset),
	  .ddr_dqs_enable (dqs_enable),
	  .ddr_dqs        (ddr_dqs[dqs_i]),
	  .dqs            (dqs_int_delay_in[dqs_i])
          );
    end
  endgenerate

//******************************************************************************
// DDR Data bit instantiations
//******************************************************************************

  genvar dq_i;
   generate
      for(dq_i = 0; dq_i < `DATA_WIDTH; dq_i = dq_i+1) begin: gen_dq
	 mig_s3_dq_iob  s3_dq_iob_inst
	   (
	    .ddr_dq_inout       (ddr_dq[dq_i]),
	    .write_data_falling (write_data_falling[dq_i]),
	    .write_data_rising  (write_data_rising[dq_i]),
	    .read_data_in       (ddr_dq_in[dq_i]),
	    .clk90              (clk90),
	    .write_en_val       (write_en_val)
	    );

      end
   endgenerate
   
   // Instead of generating all the iob instances, instantiate them manually.
   // Then the delay of each bit can be controlled independently.

endmodule
