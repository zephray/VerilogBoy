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
//  /   /        Filename           : mig_data_write_0.v
// /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $
// \   \  /  \   Date Created       : Mon May 2 2005
//  \___\/\___\
// Device       : Spartan-3/3E/3A/3A-DSP
// Design Name  : DDR SDRAM
// Purpose      : Data write operation performed through the pipelines in this
//                module.
//*****************************************************************************

`timescale 1ns/100ps
`include "mig_parameters_0.v"

module mig_data_write_0
  (
   input [((`DATA_WIDTH*2)-1):0]      user_input_data,
   input [((`DATA_MASK_WIDTH*2)-1):0] user_data_mask,
   input                              clk90,
   input                              write_enable,
   output reg                         write_en_val,
   output [((`DATA_WIDTH)-1):0]       write_data_falling,
   output [((`DATA_WIDTH)-1):0]       write_data_rising,
   output [((`DATA_MASK_WIDTH)-1):0]  data_mask_f,
   output [((`DATA_MASK_WIDTH)-1):0]  data_mask_r
    );

   reg                               write_en_P1;
   reg [((`DATA_WIDTH*2)-1):0] 	     write_data1;
   reg [((`DATA_WIDTH*2)-1):0] 	     write_data2;
   reg [((`DATA_WIDTH*2)-1):0] 	     write_data3;
   reg [((`DATA_WIDTH*2)-1):0] 	     write_data4;
   reg [((`DATA_MASK_WIDTH*2)-1):0]  write_data_m1;
   reg [((`DATA_MASK_WIDTH*2)-1):0]  write_data_m2;
   reg [((`DATA_MASK_WIDTH*2)-1):0]  write_data_m3;
   reg [((`DATA_MASK_WIDTH*2)-1):0]  write_data_m4;

   reg [(`DATA_WIDTH-1):0] 	     write_data90;
   reg [(`DATA_WIDTH-1):0] 	     write_data90_1;
   reg [(`DATA_MASK_WIDTH-1):0]      write_data_m90;
   reg [(`DATA_MASK_WIDTH-1):0]      write_data_m90_1;

   reg [((`DATA_WIDTH)-1):0] 	     write_data270;
   reg [((`DATA_WIDTH)-1):0] 	     write_data270_1;
   reg [((`DATA_MASK_WIDTH)-1):0]    write_data_m270;
   reg [((`DATA_MASK_WIDTH)-1):0]    write_data_m270_1;


   wire [((`DATA_WIDTH*2)-1):0]      write_data0;
   wire [((`DATA_MASK_WIDTH*2)-1):0] write_data_m0;

   assign write_data0   = user_input_data;
   assign write_data_m0 = user_data_mask;

   always@(posedge clk90) begin
      write_data1 <= write_data0;
      write_data2 <= write_data1;
      write_data3 <= write_data2;
      write_data4 <= write_data3;
   end

   always@(posedge clk90) begin
      write_data_m1 <= write_data_m0;
      write_data_m2 <= write_data_m1;
      write_data_m3 <= write_data_m2;
      write_data_m4 <= write_data_m3;
   end


   always@(posedge clk90) begin
     write_data90         <= write_data4[(`DATA_WIDTH-1) : 0];
      write_data_m90       <= write_data_m4[(`DATA_MASK_WIDTH-1):0];
      write_data90_1      <= write_data90;
      write_data_m90_1    <= write_data_m90;

   end

   always@(negedge clk90) begin
     write_data270       <= write_data4 [(`DATA_WIDTH*2)-1 : `DATA_WIDTH];
      write_data_m270     <= write_data_m4 [(`DATA_MASK_WIDTH*2)-1:`DATA_MASK_WIDTH];
      write_data270_1    <= write_data270;
      write_data_m270_1  <= write_data_m270;

   end

   assign write_data_rising  = write_data270_1;
   assign write_data_falling = write_data90_1;
   assign data_mask_r = write_data_m270_1;
   assign data_mask_f = write_data_m90_1;

//write enable for data path
   always@(posedge clk90) begin
      write_en_P1 <= write_enable;
   end

   always@(negedge clk90) begin
      write_en_val   <= write_en_P1;
   end

endmodule
