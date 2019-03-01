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
//  /   /        Filename           : mig_s3_dqs_iob.v
// /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $
// \   \  /  \   Date Created       : Mon May 2 2005
//  \___\/\___\
// Device       : Spartan-3/3E/3A/3A-DSP
// Design Name  : DDR SDRAM
// Purpose      : This module instantiates DDR IOB output flip-flops, an
//               output buffer with registered tri-state, and an input buffer
//               for a single strobe/dqs bit. The DDR IOB output flip-flops
//               are used to forward strobe to memory during a write. During
//               a read, the output of the IBUF is routed to the internal
//               delay module, dqs_delay.
//*****************************************************************************

`timescale 1ns/100ps

module mig_s3_dqs_iob
  (
   input wire  clk,
   input wire  ddr_dqs_reset,
   input wire  ddr_dqs_enable,
   inout wire  ddr_dqs,
   output wire dqs
   );

   localparam VCC = 1'b1;
   localparam GND = 1'b0;

   wire dqs_q;
   wire ddr_dqs_enable1;
   wire ddr_dqs_enable_b;
   wire data1;


   assign ddr_dqs_enable_b = ~ddr_dqs_enable;
   assign data1            = (ddr_dqs_reset == 1'b1) ? 1'b0 : 1'b1;

   (* IOB = "FORCE" *) FD  U1
     (
      .D (ddr_dqs_enable_b),
      .Q (ddr_dqs_enable1),
      .C (clk)
      )/* synthesis syn_useioff = 1 */;

   FDDRRSE U2
     (
      .Q  (dqs_q),
      .C0 (clk),
      .C1 (~clk),
      .CE (VCC),
      .D0 (data1),
      .D1 (GND),
      .R  (GND),
      .S  (GND)
      );
//***********************************************************************
//    IO buffer for dqs signal. Allows for distribution of dqs
//     to the data (DQ) loads.
//***********************************************************************

   OBUFT  U3
     (
      .I (dqs_q),
      .T (ddr_dqs_enable1),
      .O (ddr_dqs)
      );
   
   IBUF  U4
     (
      .I (ddr_dqs),
      .O (dqs)
      );
   
endmodule
