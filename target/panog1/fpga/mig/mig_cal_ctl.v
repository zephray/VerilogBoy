//*****************************************************************************
// (c) Copyright 2005 - 2009 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and 
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor             : Xilinx
// \   \   \/    Version            : 3.6.1
//  \   \        Application	    : MIG
//  /   /        Filename           : mig_cal_ctl_0.v
// /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $
// \   \  /  \   Date Created       : Mon May 2 2005
//  \___\/\___\
// Device       : Spartan-3/3E/3A/3A-DSP
// Design Name  : DDR SDRAM
// Purpose      : This module generates the select lines for the LUT delay
//                circuit that generate the required delay for the DQS with
//                respect to the DQ. It calculates the dealy of a LUT
//		  dynamically by finding the number of LUTs in a clock phase. 
//*****************************************************************************

`timescale 1ns/100ps

module mig_cal_ctl
  (
   input           clk,
   input           reset,
   input [31:0]    flop2,
   output reg[4:0] tapfordqs,
   // debug signals
   output [4:0]    dbg_phase_cnt,
   output [5:0]    dbg_cnt,
   output          dbg_trans_onedtct,
   output          dbg_trans_twodtct,
   output          dbg_enb_trans_two_dtct
   );

   localparam tap1        = 5'b01111;
   localparam tap2        = 5'b10111;
   localparam tap3        = 5'b11011;
   localparam tap4        = 5'b11101;
   localparam tap5        = 5'b11110;
   localparam tap6        = 5'b11111;
   localparam default_tap = 5'b11101;
   reg [5:0]  cnt/* synthesis syn_preserve=1 */;
   reg [5:0]  cnt1/* synthesis syn_preserve=1 */;
   reg [4:0]  phase_cnt/* synthesis syn_preserve=1 */;
   reg [31:0] tap_dly_reg/* synthesis syn_preserve=1 */;
   reg [4:0]  tapfordqs1/* synthesis syn_preserve=1 */;
   reg        reset_r/* synthesis syn_preserve=1 */;
   reg        trans_onedtct;
   reg        trans_twodtct;
   reg        enb_trans_two_dtct;

   assign dbg_phase_cnt          = phase_cnt;
   assign dbg_cnt                = cnt1;
   assign dbg_trans_onedtct      = trans_onedtct;
   assign dbg_trans_twodtct      = trans_twodtct;
   assign dbg_enb_trans_two_dtct = enb_trans_two_dtct;


   always @( posedge clk )
     reset_r <= reset;


   always @(posedge clk) begin
      if(reset_r)
        enb_trans_two_dtct <= 1'b0;
      else if(phase_cnt >= 5'd1)
        enb_trans_two_dtct <= 1'b1;
      else
        enb_trans_two_dtct <= 1'b0;
   end

   always @(posedge clk) begin
      if(reset_r)
        tap_dly_reg <= 32'd0;
      else if(cnt[5] == 1'b1)
        tap_dly_reg <= flop2;
      else
        tap_dly_reg <= tap_dly_reg;
   end

   /*********** Free Running Counter For Counting 32 States *******************/
   /*********** Two parallel counters are used to fix the timing **************/

   always @(posedge clk) begin
      if(reset_r || (cnt[5] == 1'b1))
        cnt[5:0] <= 6'b0;
      else
        cnt[5:0] <= cnt[5:0] + 1'b1;
   end


   always @(posedge clk) begin
      if(reset_r || (cnt1[5] == 1'b1))
        cnt1[5:0] <= 6'b0;
      else
        cnt1[5:0] <= cnt1[5:0] + 1'b1;
   end

   always @(posedge clk) begin
      if(reset_r || (cnt[5] == 1'b1)) 
         phase_cnt <= 5'd0;
      else if (trans_onedtct && (!trans_twodtct))
        phase_cnt <= phase_cnt + 1;
      else
        phase_cnt <= phase_cnt;
   end

   /***************** Checking For The First Transition ***********************/

   always @(posedge clk) begin
      if(reset_r || (cnt[5] == 1'b1)) begin
         trans_onedtct <= 1'b0;
         trans_twodtct <= 1'b0;
      end
      else if (cnt[4:0] == 5'd0 && tap_dly_reg[0]) begin
         trans_onedtct <= 1'b1;
         trans_twodtct <= 1'b0;
      end
      else if ((tap_dly_reg[cnt[4:0]]) && (trans_twodtct == 1'b0)) begin
         if((trans_onedtct == 1'b1) && (enb_trans_two_dtct) ) 
            trans_twodtct <= 1'b1;
         else
            trans_onedtct <= 1'b1;
      end
   end

  // Tap values for Left/Right banks 
   always @(posedge clk)begin
     if(reset_r)
       tapfordqs1 <= default_tap;
     else if(cnt1[4] && cnt1[3] && cnt1[2] && cnt1[1]
             && cnt1[0]) begin
       if((trans_onedtct == 1'b0) || (trans_twodtct == 1'b0) ||
          (phase_cnt > 5'd12))
         tapfordqs1 <= tap6;
       else if((phase_cnt > 5'd10))
         tapfordqs1 <= tap5;
       else if((phase_cnt > 5'd8))
         tapfordqs1 <= tap4;
       else if((phase_cnt > 5'd5))
         tapfordqs1 <= tap3;
       else
         tapfordqs1 <= tap2;
     end
     else
       tapfordqs1 <= tapfordqs1;
   end

   always @( posedge clk )
     tapfordqs <= tapfordqs1;

endmodule
