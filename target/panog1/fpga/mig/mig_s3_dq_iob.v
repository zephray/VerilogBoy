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
//  /   /        Filename           : mig_s3_dq_iob.v
// /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $
// \   \  /  \   Date Created       : Mon May 2 2005
//  \___\/\___\
// Device       : Spartan-3/3E/3A/3A-DSP
// Design Name  : DDR SDRAM
// Purpose      : This module instantiate DDR IOB output flip-flops, an
//               output buffer with registered tri-state, and an input buffer
//               for a single data/dq bit. The DDR IOB output flip-flops
//               are used to forward data to memory during a write.
//*****************************************************************************

`timescale 1ns/100ps

module mig_s3_dq_iob
  (
   inout  ddr_dq_inout,
   input  write_data_falling,
   input  write_data_rising,
   input  clk90,
   input  write_en_val,
   output read_data_in
   );


   localparam GND = 1'b0;
   localparam CLOCK_EN = 1'b1;

   wire ddr_en;   
   wire ddr_dq_q; 
   wire enable_b;
   wire write_data_rising1;
   wire write_data_falling1;

   assign enable_b = ~ write_en_val;

// # delays are used for simulation purpose(delta delay).

   assign #1 write_data_rising1  = write_data_rising;
   assign #1 write_data_falling1 = write_data_falling;

//Transmission data path

   FDDRRSE DDR_OUT
     (
      .Q  (ddr_dq_q),
      .C0 (~clk90),
      .C1 (clk90),
      .CE (CLOCK_EN),
      .D0 (write_data_rising1),
      .D1 (write_data_falling1),
      .R  (GND),
      .S  (GND)
      );

   (* IOB = "FORCE" *) FD DQ_T
     (
      .D (enable_b),
      .C (~clk90),
      .Q (ddr_en)
      )/* synthesis syn_useioff = 1 */;

   OBUFT DQ_OBUFT
     (
      .I (ddr_dq_q),
      .T (ddr_en),
      .O (ddr_dq_inout)
      );

   //Receive data path

   IBUF DQ_IBUF
     (
      .I (ddr_dq_inout),
      .O (read_data_in)
      );

endmodule
