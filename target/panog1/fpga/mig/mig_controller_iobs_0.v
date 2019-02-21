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
//  /   /        Filename           : mig_controller_iobs_0.v
// /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $
// \   \  /  \   Date Created       : Mon May 2 2005
//  \___\/\___\
// Device       : Spartan-3/3E/3A/3A-DSP
// Design Name  : DDR SDRAM
// Purpose      : This module has the IOB instantiations for the controller
//                module.
//*****************************************************************************

`timescale 1ns/100ps
`include "mig_parameters_0.v"

module mig_controller_iobs_0
  (
   input                      clk0,
   input                      ddr_rasb_cntrl,
   input                      ddr_casb_cntrl,
   input                      ddr_web_cntrl,
   input                      ddr_cke_cntrl,
   input                      ddr_csb_cntrl,
   input [`ROW_ADDRESS-1:0]   ddr_address_cntrl,
   input [`BANK_ADDRESS-1:0]  ddr_ba_cntrl,
   input                      rst_dqs_div_int,
   output                     ddr_rasb,
   output                     ddr_casb,
   output                     ddr_web,
   output [`BANK_ADDRESS-1:0] ddr_ba,
   output [`ROW_ADDRESS-1:0]  ddr_address,
   output                     ddr_cke,
   output                     ddr_csb,
   output                     rst_dqs_div,
   input                      rst_dqs_div_in,
   output                     rst_dqs_div_out
   );


   wire [`ROW_ADDRESS-1:0]  ddr_address_iob_reg;
   wire [`BANK_ADDRESS-1:0] ddr_ba_reg;
   wire 		    ddr_web_q;
   wire 		    ddr_rasb_q;
   wire 		    ddr_casb_q;
   wire 		    ddr_cke_q;
   wire 		    ddr_cke_int;   

// ******************************************* //
//  Includes the instantiation of FD for cntrl //
//            signals                          //
// ******************************************* //

   (* IOB = "FORCE" *) FD iob_web
     (
      .Q ( ddr_web_q),
      .D ( ddr_web_cntrl),
      .C (~clk0)
      )/* synthesis syn_useioff = 1 */;
   
   (* IOB = "FORCE" *) FD iob_rasb
     (
      .Q ( ddr_rasb_q),
      .D ( ddr_rasb_cntrl),
      .C (~clk0)
      )/* synthesis syn_useioff = 1 */;

   (* IOB = "FORCE" *) FD iob_casb
     (
      .Q ( ddr_casb_q),
      .D ( ddr_casb_cntrl),
      .C (~clk0)
      )/* synthesis syn_useioff = 1 */;

//---- ************************************* ----
//----  Output buffers for control signals   ----
//---- ************************************* ----

   OBUF r16
     (
      .I ( ddr_web_q),
      .O ( ddr_web)
      );

   OBUF r17
     (
      .I ( ddr_rasb_q),
      .O ( ddr_rasb)
      );

   OBUF r18
     (
      .I ( ddr_casb_q),
      .O ( ddr_casb)
      );

   OBUF r19
     (
      .I (ddr_csb_cntrl),
      .O ( ddr_csb)
      );

   FD iob_cke0
     (
      .Q (ddr_cke_int),
      .D (ddr_cke_cntrl),
      .C (clk0)
      );

   (* IOB = "FORCE" *) FD iob_cke
     (
      .Q (ddr_cke_q),
      .D (ddr_cke_int),
      .C (~clk0)
      )/* synthesis syn_useioff = 1 */;

   OBUF r20
     (
      .I (ddr_cke_q),
      .O (ddr_cke)
      );

//---- *******************************************  ----
//----  Includes the instantiation of FD  and OBUF  ----
//----  for addr signals                            ----
//---- *******************************************  ----
   
   genvar addr_i;
   generate
      for(addr_i = 0; addr_i < `ROW_ADDRESS; addr_i = addr_i + 1) begin : gen_addr
	 (* IOB = "FORCE" *) FD FD_inst
	   (
            .Q (ddr_address_iob_reg[addr_i]),
            .D (ddr_address_cntrl[addr_i]),
            .C (~clk0)
            )/* synthesis syn_useioff = 1 */;
	 
         OBUF OBUF_inst
           (
            .I (ddr_address_iob_reg[addr_i]),
            .O (ddr_address[addr_i])
            );
      end
   endgenerate

   genvar ba_i;
   generate
      for(ba_i = 0; ba_i < `BANK_ADDRESS; ba_i = ba_i + 1) begin : gen_ba
	 (* IOB = "FORCE" *) FD FD_inst
           (
            .Q(ddr_ba_reg[ba_i]),
            .D(ddr_ba_cntrl[ba_i]),
            .C(~clk0)
            )/* synthesis syn_useioff = 1 */;
	 
	 OBUF OBUF_inst
           (
            .I (ddr_ba_reg[ba_i]),
            .O (ddr_ba[ba_i])
	    );
      end
   endgenerate

   /*IBUF rst_iob_inbuf
     (
      .I (rst_dqs_div_in),
      .O (rst_dqs_div)
      );

   OBUF rst_iob_outbuf
     (
      .I (rst_dqs_div_int),
      .O (rst_dqs_div_out)
      );*/
   assign rst_dqs_div_out = rst_dqs_div_int;
   assign rst_dqs_div = rst_dqs_div_in;

endmodule
