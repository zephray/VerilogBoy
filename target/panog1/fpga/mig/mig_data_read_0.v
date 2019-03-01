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
//  /   /        Filename           : mig_data_read_0.v
// /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $
// \   \  /  \   Date Created       : Mon May 2 2005
//  \___\/\___\
// Device       : Spartan-3/3E/3A/3A-DSP
// Design Name  : DDR SDRAM
// Purpose      : ram8d modules are instantiated for Read data FIFOs.
//                ram8d is each 8 bits or 4 bits depending on number data bits
//                per strobe. Each strobe  will have two instances, one for
//                rising edge data and one for falling edge data.
//*****************************************************************************

`timescale 1ns/100ps
`include "mig_parameters_0.v"

module mig_data_read_0
  (
   input wire                              clk90,
   input wire                              reset90,
   input wire [(`DATA_WIDTH-1):0]          ddr_dq_in,
   input wire [(`DATA_STROBE_WIDTH-1):0]   fifo_0_wr_en,
   input wire [(`DATA_STROBE_WIDTH-1):0]   fifo_1_wr_en,
   input wire [(4*`DATA_STROBE_WIDTH)-1:0] fifo_0_wr_addr ,
   input wire [(4*`DATA_STROBE_WIDTH)-1:0] fifo_1_wr_addr ,
   input wire [(`DATA_STROBE_WIDTH-1):0]   dqs_delayed_col0,
   input wire [(`DATA_STROBE_WIDTH-1):0]   dqs_delayed_col1,    
   input wire                              read_fifo_rden, 
   output wire [((`DATA_WIDTH*2)-1):0]     user_output_data,
   output wire                             u_data_val
   );

   reg 				      reset90_r;

   reg [(4*`DATA_STROBE_WIDTH)-1:0] fifo0_rd_addr_r
                                    /* synthesis syn_preserve=1 */;
   reg [(4*`DATA_STROBE_WIDTH)-1:0] fifo1_rd_addr_r
                                    /* synthesis syn_preserve=1 */;
   reg [`DATA_WIDTH-1:0]            fifo_0_data_out_r
                                    /* synthesis syn_preserve=1 */;
   reg [`DATA_WIDTH-1:0]            fifo_1_data_out_r
                                    /* synthesis syn_preserve=1 */;
   reg [((`DATA_WIDTH*2)-1):0]      first_sdr_data;
   reg                               read_fifo_rden_90r1; 
   reg                               read_fifo_rden_90r2; 
   reg                               read_fifo_rden_90r3; 
   reg                               read_fifo_rden_90r4; 
   reg                               read_fifo_rden_90r5; 
   reg                               read_fifo_rden_90r6; 

   wire [3:0]                       fifo0_rd_addr;
   wire [3:0]                       fifo1_rd_addr;
   wire [`DATA_WIDTH-1:0]           fifo_0_data_out;
   wire [`DATA_WIDTH-1:0]           fifo_1_data_out;
   wire [(`DATA_STROBE_WIDTH-1):0]  dqs_delayed_col0_n;
   wire [(`DATA_STROBE_WIDTH-1):0]  dqs_delayed_col1_n;

   assign dqs_delayed_col0_n  = ~ dqs_delayed_col0;
   assign dqs_delayed_col1_n  = ~ dqs_delayed_col1;
   assign user_output_data    = first_sdr_data;
   assign u_data_val          = read_fifo_rden_90r6; 
   always @( posedge clk90 )
     reset90_r <= reset90;

  // Read fifo read enable signal phase is changed from 180 to 90 clock domain 
   always@(posedge clk90) begin
      if(reset90_r)begin
         read_fifo_rden_90r1 <= 1'b0;
         read_fifo_rden_90r2 <= 1'b0;
         read_fifo_rden_90r3 <= 1'b0;
         read_fifo_rden_90r4 <= 1'b0;
         read_fifo_rden_90r5 <= 1'b0;
         read_fifo_rden_90r6 <= 1'b0;

      end
      else begin
         read_fifo_rden_90r1 <= read_fifo_rden;
         read_fifo_rden_90r2 <= read_fifo_rden_90r1;
         read_fifo_rden_90r3 <= read_fifo_rden_90r2;
         read_fifo_rden_90r4 <= read_fifo_rden_90r3;
         read_fifo_rden_90r5 <= read_fifo_rden_90r4;
         read_fifo_rden_90r6 <= read_fifo_rden_90r5;
      end
   end

   always@(posedge clk90) begin
     fifo_0_data_out_r <= fifo_0_data_out;
     fifo_1_data_out_r <= fifo_1_data_out;
   end

   genvar addr_i;
   generate for(addr_i = 0; addr_i < `DATA_STROBE_WIDTH;
                addr_i = addr_i + 1) begin: gen_addr
      always@(posedge clk90) begin
         fifo0_rd_addr_r[addr_i*4+:4] <= fifo0_rd_addr;
         fifo1_rd_addr_r[addr_i*4+:4] <= fifo1_rd_addr;
      end
   end
   endgenerate
   always@(posedge clk90)begin
      if(reset90_r)
        first_sdr_data       <= {(`DATA_WIDTH*2){1'b0}};
      else if(read_fifo_rden_90r5)
         first_sdr_data  <= {fifo_0_data_out_r, fifo_1_data_out_r};
   end

// rd address gray counters
   mig_rd_gray_cntr fifo0_rd_addr_inst
     (
      .clk90    (clk90),
      .reset90  (reset90),
      .cnt_en   (read_fifo_rden_90r3),
      .rgc_gcnt (fifo0_rd_addr)
      );

   mig_rd_gray_cntr fifo1_rd_addr_inst
     (
      .clk90    (clk90),
      .reset90  (reset90),
      .cnt_en   (read_fifo_rden_90r3),
      .rgc_gcnt (fifo1_rd_addr)
      );

   genvar strobe_i;
   generate for(strobe_i = 0; strobe_i < `DATA_STROBE_WIDTH;
                strobe_i = strobe_i + 1) begin: gen_strobe
      mig_ram8d_0 strobe
        (
         .dout  (fifo_0_data_out[strobe_i*`DATABITSPERREADCLOCK+:
                                 `DATABITSPERREADCLOCK]),
         .waddr (fifo_0_wr_addr[strobe_i*4+:4]),
         .din   (ddr_dq_in[strobe_i*`DATABITSPERREADCLOCK+:
                           `DATABITSPERREADCLOCK]),
         .raddr (fifo0_rd_addr_r[strobe_i*4+:4]),
         .wclk0 (dqs_delayed_col0[strobe_i]),
         .wclk1 (  dqs_delayed_col1[strobe_i]),
         .we    (fifo_0_wr_en[strobe_i])
         );
      mig_ram8d_0 strobe_n
        (
         .dout  (fifo_1_data_out[strobe_i*`DATABITSPERREADCLOCK+:
                                 `DATABITSPERREADCLOCK]),
         .waddr (fifo_1_wr_addr[strobe_i*4+:4]),
         .din   (ddr_dq_in[strobe_i*`DATABITSPERREADCLOCK+:
                           `DATABITSPERREADCLOCK]),
         .raddr (fifo1_rd_addr_r[strobe_i*4+:4]),
         .wclk0 (dqs_delayed_col0_n[strobe_i]),
         .wclk1 (  dqs_delayed_col1_n[strobe_i]),
         .we    (fifo_1_wr_en[strobe_i])
         );
   end
   endgenerate

endmodule
