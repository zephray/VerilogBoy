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
//  /   /        Filename           : mig_controller_0.v
// /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $
// \   \  /  \   Date Created       : Mon May 2 2005
//  \___\/\___\
// Device       : Spartan-3/3E/3A/3A-DSP
// Design Name  : DDR SDRAM
// Description  : This is the main controller block. This includes the following
//                features:
//                - The controller state machine that controls the
//                initialization process upon power up, as well as the
//                read, write and refresh commands.
//                - Accepts and decodes the user commands.
//                - Generates the address and Bank address and control signals
//                   to the memory    
//                - Generates control signals for other modules.
//*****************************************************************************

`timescale 1ns/100ps
`include "mig_parameters_0.v"

module mig_controller_0
  (
   input wire                           clk,
   input wire                           rst0,
   input wire                           rst180,
   input wire [((`ROW_ADDRESS
	    + `COLUMN_ADDRESS)-1):0] address,
   input wire [`BANK_ADDRESS-1:0]       bank_address,
   input wire [2:0]                     command_register,
   input wire                           burst_done,
   output wire                          ddr_rasb_cntrl,
   output wire                          ddr_casb_cntrl,
   output wire                          ddr_web_cntrl,
   output wire [`BANK_ADDRESS-1:0]      ddr_ba_cntrl,
   output wire [`ROW_ADDRESS-1:0]       ddr_address_cntrl,
   output wire                          ddr_cke_cntrl,
   output wire                          ddr_csb_cntrl,
   output wire                          dqs_enable,
   output wire                          dqs_reset,
   output wire                          write_enable,
   output reg                      rst_calib,
   output wire                          rst_dqs_div_int,
   output wire                          cmd_ack,
   output wire                          init,
   output reg                      ar_done,
   input wire                           wait_200us,
   output wire                          auto_ref_req,
   output reg                      read_fifo_rden // Read Enable signal for read fifo(to data_read module)
   );


   localparam IDLE                    = 4'b0000;
   localparam PRECHARGE               = 4'b0001;
   localparam AUTO_REFRESH            = 4'b0010;
   localparam ACTIVE                  = 4'b0011;
   localparam FIRST_WRITE             = 4'b0100;
   localparam WRITE_WAIT              = 4'b0101;
   localparam BURST_WRITE             = 4'b0110;
   localparam PRECHARGE_AFTER_WRITE   = 4'b0111;
   localparam PRECHARGE_AFTER_WRITE_2 = 4'b1000;
   localparam READ_WAIT               = 4'b1001;
   localparam BURST_READ              = 4'b1010;
   localparam ACTIVE_WAIT             = 4'b1011;
   localparam PRECHARGE_WAIT          = 4'b1100;
   localparam AUTO_REFRESH_WAIT       = 4'b1101;

   localparam INIT_IDLE             = 2'b00;
   localparam INIT_PRECHARGE        = 2'b01;
   localparam INIT_LOAD_MODE_REG    = 2'b10;
   localparam INIT_AUTO_REFRESH     = 2'b11;
   
   localparam INIT_DONE_COUNT       = 4'b0101;
   
   localparam LMR_VAL               = `LOAD_MODE_REGISTER;   
   localparam CAS_LAT_VAL           = LMR_VAL[6:4];   
   localparam BURST_LEN_VAL         = LMR_VAL[2:0];   

   parameter COL_WIDTH          = `COLUMN_ADDRESS;
   parameter ROW_WIDTH          = `ROW_ADDRESS;

   reg [3:0]                       current_state;
   reg [3:0] 			   next_state;
   reg [1:0] 			   init_current_state;
   reg [1:0] 			   init_next_state;
   reg [`ROW_ADDRESS -1 :0]        address_reg;
   reg 				   auto_ref;
   reg 				   auto_ref_detect1;
   reg [10:0] 			   autoref_count;
   reg 				   auto_ref_issued;
   reg [5:0] 			   rfc_counter_value;
   reg [`BANK_ADDRESS-1:0] 	   ba_address_reg1;
   reg [`BANK_ADDRESS-1:0] 	   ba_address_reg2;
   reg [2:0] 			   burst_length;
   reg [2:0] 			   cas_count;
   reg [2:0] 			   cas_latency;
   reg [`ROW_ADDRESS -1:0] 	   column_address_reg;
   reg 				   ddr_rasb2;
   reg 				   ddr_casb2;
   reg 				   ddr_web2;
   reg 				   ddr_rst_dqs_rasb4;
   reg 				   ddr_rst_dqs_casb4;
   reg 				   ddr_rst_dqs_web4;
   reg [`BANK_ADDRESS-1:0] 	   ddr_ba1;
   reg [`ROW_ADDRESS-1:0] 	   ddr_address1;
   reg [3:0] 			   init_count;
   reg 				   init_done;
   reg 				   init_done_r1;
   reg 				   init_memory;
   reg 				   init_mem;
   reg [10:0] 			   max_ref_cnt_value;
   reg 				   read_cmd1;
   reg [1:0] 			   rcd_count;
   reg 				   rfc_count_reg;
   reg 				   ar_done_reg;
   reg 				   rdburst_end_1;
   reg [2:0] 			   rp_count;
   reg [5:0] 			   rfc_count;
   reg [3:0]                       ras_count;
   reg [`ROW_ADDRESS-1:0] 	   row_address_reg;
   reg 				   rst_dqs_div_r;
   reg 				   dly_dqs_div_r;
   reg 				   auto_ref1;
   reg 				   autoref_value;
   reg [2:0] 			   wrburst_end_cnt;
   reg 				   wrburst_end_1;
   reg 				   wrburst_end_2;
   reg [1:0] 			   wr_count;
   reg 				   write_cmd1;
   reg [2:0] 			   dqs_div_cascount;
   reg [2:0] 			   dqs_div_rdburstcount;
   reg 				   dqs_enable1;
   reg 				   dqs_enable2;
   reg 				   dqs_enable3;
   reg 				   dqs_reset1_clk0;
   reg 				   dqs_reset2_clk0;
   reg 				   dqs_reset3_clk0;
   reg 				   rst180_r;
   reg 				   rst0_r;
   reg 				   go_to_active;
   reg 				   rpcnt0;
   reg 				   accept_cmd_in;
   reg 				   auto_ref_wait;
   reg 				   auto_ref_wait1;
   reg 				   auto_ref_wait2;
   reg [4:0] 			   count5;
   reg 				   write_enable_r;
   reg 				   write_enable_r1;
   reg 				   rst_dqs_div_r1;
   reg 				   rst_dqs_div_r2;
   wire  			   rst_dqs_div_d;

   
   
   wire 			   ack_reg;
   wire 			   ack_o;   
   wire 			   auto_ref_issued_p;
   wire 			   ar_done_p;
   wire [2:0] 			   burst_cnt_max;
   wire [`ROW_ADDRESS -1:0] 	   column_address;
   wire 			   ddr_rasb1;
   wire 			   ddr_casb1;
   wire 			   ddr_web1;
   wire 			   init_done_value;
   wire 			   initialize_memory;
   wire 			   read_cmd;
   wire 			   rdburst_end;
   wire [`ROW_ADDRESS-1:0] 	   row_address;
   wire 		           wrburst_end;
   wire                            write_cmd_in;
   wire 			   dqs_enable_int;
   wire 			   dqs_reset_int;
   wire 			   go_to_active_value;
   wire [`ROW_ADDRESS-1:0] 	   lmr;
   wire [`ROW_ADDRESS-1:0] 	   emr;
   wire                            clk180 /* synthesis syn_keep = 1 */;

   // Input : COMMAND REGISTER FORMAT
   //          000  - NOP
   //          010  - Initialize memory
   //          100  - Write Request
   //          110  - Read request


   // Input : Address format
   //   row address  = address[(`ROW_ADDRESS+ `COLUMN_ADDRESS) -1 : `COLUMN_ADDRESS]
   //   column address = address[`COLUMN_ADDRESS-1 : 0]

   assign ddr_csb_cntrl  = 1'b0;
   assign lmr            = `LOAD_MODE_REGISTER;
   assign emr            = `EXT_LOAD_MODE_REGISTER;
   assign ddr_cke_cntrl  = ~wait_200us;
   assign row_address    = address[((`ROW_ADDRESS + `COLUMN_ADDRESS  )-1)
                                  :`COLUMN_ADDRESS];
   assign init           = init_done;
   assign ddr_rasb_cntrl = ddr_rasb2;
   assign ddr_casb_cntrl = ddr_casb2;
   assign ddr_web_cntrl  = ddr_web2;
   assign auto_ref_req   = auto_ref_wait;

  // turn off auto-precharge when issuing read/write commands (A10 = 0)
  // mapping the column  address for linear addressing.
  generate
    if (COL_WIDTH == ROW_WIDTH-1) begin: gen_ddr_addr_col_0
      assign column_address = {address_reg[COL_WIDTH-1:10], 1'b0,
                             address_reg[9:0]};
    end else begin
      if (COL_WIDTH > 10) begin: gen_ddr_addr_col_1
        assign column_address = {{(ROW_WIDTH-COL_WIDTH-1){1'b0}},
                               address_reg[COL_WIDTH-1:10], 1'b0,
                               address_reg[9:0]};
      end else begin: gen_ddr_addr_col_2
        assign column_address = {{(ROW_WIDTH-COL_WIDTH-1){1'b0}}, 1'b0,
                               address_reg[COL_WIDTH-1:0]};
      end
    end
  endgenerate

   always @ (negedge clk) begin
      rst180_r <= rst180;
   end
   
   always @ (posedge clk) begin
      rst0_r <= rst0;
   end

   always @(negedge clk) begin
      if(rst180_r)
        count5 <= 5'd0;
      else if(init_current_state == INIT_AUTO_REFRESH ||
              init_current_state == INIT_PRECHARGE
              || init_current_state == INIT_LOAD_MODE_REG)
        count5 <= `RFC_COUNT_VALUE;
      else if(count5 != 5'd0)
        count5 <= count5 - 1'b1;
      else
        count5 <= 5'd0;
   end

//******************************************************************************
// Register user address
//******************************************************************************

   always @ (negedge clk) begin
      row_address_reg    <= row_address;
      column_address_reg <= column_address;
      ba_address_reg1    <= bank_address;
      address_reg        <= address[`ROW_ADDRESS-1 :0];
      ba_address_reg2    <= ba_address_reg1 ;
   end

   always @ (negedge clk) begin
      if (rst180_r == 1'b1) begin
         burst_length <= 3'b000;
         cas_latency  <= 3'b000;
      end
      else begin
         burst_length <= lmr[2:0];
         cas_latency  <= lmr[6:4];
      end
   end
   
   always @( negedge clk ) begin
      if ( rst180_r )
        accept_cmd_in <= 1'b0;
      else if ( current_state == IDLE && (rpcnt0 && rfc_count_reg &&
                                          !auto_ref_wait && !auto_ref_issued) )
        accept_cmd_in <= 1'b1;
      else
        accept_cmd_in <= 1'b0;
   end
   
//******************************************************************************
// Commands from user.
//******************************************************************************
   assign initialize_memory = (command_register == 3'b010);
   assign write_cmd_in      = (command_register == 3'b100 &&
                               accept_cmd_in == 1'b1);
   assign read_cmd          = (command_register == 3'b110 &&
                               accept_cmd_in == 1'b1);

//******************************************************************************
// write_cmd1 is asserted when user issued write command and the controller s/m
// is in idle state and AUTO_REF is not asserted.
//******************************************************************************

   always @ (negedge clk) begin
      if (rst180_r == 1'b1) begin
	 write_cmd1  <= 1'b0;
      end
      else begin
	 if (accept_cmd_in)
	   write_cmd1 <= write_cmd_in;
      end
   end
   
//******************************************************************************
// read_cmd1 is asserted when user issued read command and the controller s/m
// is in idle state and AUTO_REF is not asserted.
//******************************************************************************

     always @ (negedge clk) begin
        if (rst180_r == 1'b1) begin
           read_cmd1      <= 1'b0;
        end
        else begin
           if (accept_cmd_in)
             read_cmd1       <= read_cmd;
        end
     end

//******************************************************************************
// rfc_count
// An executable command can be issued only after Trfc period after a 
// AUTOREFRESH command is issued. rfc_count_value is set in the parameter file 
// depending on the memory device speed grade and the selected frequency.For 
// example for 75 speed grade, at 133Mhz, rfc_counter_value = 6'b001010.
// ( Trfc/clk_period= 75/7.5= 10)
//******************************************************************************

   always @( negedge clk ) begin
      if ( rst180_r )
        rfc_count <= 6'd0;
      else if ( current_state == AUTO_REFRESH )
        rfc_count <= rfc_counter_value;
      else if ( rfc_count != 6'b000000 )
        rfc_count <= rfc_count - 1'b1;
   end

//******************************************************************************
// rp_count
// An executable command can be issued only after Trp period after a PRECHARGE
// command is issued. 
//******************************************************************************

   always @( negedge clk ) begin
      if ( rst180_r )
        rp_count <= 3'b000;
      else if ( current_state == PRECHARGE )
        rp_count <= `RP_COUNT_VALUE;
      else if ( rp_count != 3'b000 )
        rp_count <= rp_count - 1'b1;
   end
   
   always @( negedge clk ) begin
      if ( rst180_r )
        rpcnt0 <= 1'b1;
      else if ( rp_count > 3'b001  )
        rpcnt0 <= 1'b0;
      else
        rpcnt0 <= 1'b1;
   end

//******************************************************************************
// ACTIVE to READ/WRITE counter
//
// rcd_count
// ACTIVE to READ/WRITE delay - Minimum interval between ACTIVE and READ/WRITE command.
// rcd_count value is fixed to support all memory speed grades.
//
//******************************************************************************

   always @( negedge clk ) begin
      if ( rst180_r )
        rcd_count <= 2'b00;
      else if ( current_state == ACTIVE )
        rcd_count <= 2'b10;
      else if ( rcd_count != 2'b00 )
        rcd_count <= rcd_count - 1'b1;
   end
//******************************************************************************
// ras_count- Active to Precharge time
//******************************************************************************
   always @( negedge clk ) begin
      if ( rst180_r )
	ras_count <= 4'd0;
      else if ( current_state == ACTIVE )
	ras_count <= `RAS_COUNT_VALUE-1;
      else if ( ras_count != 4'd0 )
	ras_count <= ras_count - 1'b1;
   end
//******************************************************************************

//******************************************************************************
// wr_count
// The memory device require Twr period after data written to the memory before
// issuing a PRECHARGE command. wr_count value is fixed to support all memory s
// speed grades.
//******************************************************************************
   always @( negedge clk ) begin
      if ( rst180_r )
        wr_count <= 2'b00;
      else if (dqs_enable_int)
        wr_count <= 2'b11;
      else if ( wr_count != 2'b00 )
        wr_count <= wr_count - 1'b1;
   end

//******************************************************************************
// autoref_count
// The DDR SDRAM requires AUTO REFRESH cycles at an average interval of 7.8125us.
// Auto Refresh Request is raised for every 7.7 us to allow for termination 
// of any ongoing bus transfer. For example 166MHz frequency,
// The autoref_count = refresh_time_period/clock_period = 7.7us/6.02ns = 1279
//******************************************************************************

   always @ (negedge clk) begin
      if (rst180_r == 1'b1) begin
         rfc_counter_value <= `RFC_COUNT_VALUE;
         max_ref_cnt_value <=  `MAX_REF_CNT;
         autoref_value     <= 1'b0;
      end
      else begin
         rfc_counter_value  <= `RFC_COUNT_VALUE;
         max_ref_cnt_value  <= `MAX_REF_CNT;
         autoref_value      <= (autoref_count == max_ref_cnt_value);
      end
   end
   
   always @(negedge clk) begin
      if(rst180_r)
        autoref_count <= `MAX_REF_WIDTH'b0;
      else if(autoref_value)
        autoref_count <= `MAX_REF_WIDTH'b0;
      else
        autoref_count <= autoref_count + 1'b1;
   end

   always @ (negedge clk) begin
      if (rst180_r == 1'b1) begin
         auto_ref_detect1   <= 1'b0;
         auto_ref1          <= 1'b0;
      end
      else begin
         auto_ref_detect1   <= autoref_value && init_done;
         auto_ref1          <= auto_ref_detect1;
      end
   end

   assign ar_done_p = (ar_done_reg == 1'b1);

   always @ (negedge clk) begin
      if (rst180_r == 1'b1) begin
         auto_ref_wait <= 1'b0;
         ar_done  <= 1'b0;
         auto_ref_issued <= 1'b0;
      end
      else begin
         if (auto_ref1 && !auto_ref_wait)
           auto_ref_wait <= 1'b1;
         else if (auto_ref_issued_p)
           auto_ref_wait <= 1'b0;
         else
           auto_ref_wait <= auto_ref_wait;
         ar_done         <= ar_done_p;
         auto_ref_issued <= auto_ref_issued_p;
      end
   end

   always @ (negedge clk) begin
      if (rst180_r == 1'b1) begin
         auto_ref_wait1 <= 1'b0;
         auto_ref_wait2 <= 1'b0;
         auto_ref       <= 1'b0;
      end
      else begin
         if (auto_ref_issued_p) begin
            auto_ref_wait1 <= 1'b0;
            auto_ref_wait2 <= 1'b0;
            auto_ref       <= 1'b0;
         end
         else begin
            auto_ref_wait1  <= auto_ref_wait;
            auto_ref_wait2  <= auto_ref_wait1;
            auto_ref        <= auto_ref_wait2;
         end
      end
   end

   assign auto_ref_issued_p = (current_state == AUTO_REFRESH );

//******************************************************************************
// While doing consecutive READs or WRITEs, the burst_cnt_max value determines
// when the next READ or WRITE command should be issued. burst_cnt_max shows the
// number of clock cycles for each burst.
// e.g burst_cnt_max = 1 for a burst length of 2
//                   = 2 for a burst length of 4
//                   = 4 for a burst length of 8
//******************************************************************************
   assign burst_cnt_max = ((burst_length == 3'b001) ? 3'b001 :
                           (burst_length == 3'b010) ? 3'b010 :
                           (burst_length == 3'b011) ? 3'b100 :
                           3'b000);


   always @( negedge clk ) begin
      if ( rst180_r )
	cas_count <= 3'b000;
      else if ( current_state == BURST_READ )
	cas_count <= burst_cnt_max - 1'b1;
      else if ( cas_count != 3'b000 )
	cas_count <= cas_count - 1'b1;
   end
   

   always @(negedge clk) begin
      if (rst180_r == 1'b1)
        wrburst_end_1 <= 1'b0;
      else begin
         wrburst_end_1 <= burst_done;
         wrburst_end_2 <= wrburst_end_1;
      end
   end

   always @(negedge clk) begin
      if (rst180_r == 1'b1)
        rdburst_end_1 <= 1'b0;
      else begin
         rdburst_end_1 <= burst_done;
      end
   end

  assign wrburst_end = (burst_length == 3'b011) ? wrburst_end_2 : wrburst_end_1;
  assign rdburst_end = rdburst_end_1;

   always @( negedge clk ) begin
      if(rst180_r)
        wrburst_end_cnt <= 3'b000;
      else if((current_state == FIRST_WRITE) || (current_state == BURST_WRITE))
        wrburst_end_cnt <= burst_cnt_max;
      else if(wrburst_end_cnt != 3'b000)
        wrburst_end_cnt <= wrburst_end_cnt - 1'b1;
   end

//******************************************************************************
// dqs_enable and dqs_reset signals are used to generate DQS signal during write
// data.
//******************************************************************************

   assign dqs_enable = dqs_enable2;
   assign dqs_reset  = dqs_reset2_clk0; 


   assign dqs_enable_int = ((current_state == FIRST_WRITE) ||
                            (current_state == BURST_WRITE)||
                            (wrburst_end_cnt != 3'b000));
   assign dqs_reset_int  = (current_state == FIRST_WRITE);
   
   always @ (posedge clk) begin
      if (rst0_r == 1'b1) begin
         dqs_enable1     <= 1'b0;
         dqs_enable2     <= 1'b0;
         dqs_enable3     <= 1'b0;
         dqs_reset1_clk0 <= 1'b0;
         dqs_reset2_clk0 <= 1'b0;
         dqs_reset3_clk0 <= 1'b0;
      end
      else begin
         dqs_enable1     <= dqs_enable_int;
         dqs_enable2     <= dqs_enable1;
         dqs_enable3     <= dqs_enable2;
         dqs_reset1_clk0 <= dqs_reset_int;
         dqs_reset2_clk0 <= dqs_reset1_clk0;
         dqs_reset3_clk0 <= dqs_reset2_clk0;
      end
   end

//******************************************************************************
//Write Enable signal to the datapath
//******************************************************************************

   always @(negedge clk) begin
      if (rst180_r == 1'b1)
	write_enable_r <= 1'b0;
      else if((current_state == FIRST_WRITE) || (current_state == BURST_WRITE)||
              (wrburst_end_cnt > 3'b001))
	write_enable_r <= 1'b1;
      else
	write_enable_r <= 1'b0;
   end

   always @(negedge clk) begin
      if (rst180_r == 1'b1)
        write_enable_r1 <= 1'b0;
      else
        write_enable_r1 <= write_enable_r;
   end


   assign write_enable = write_enable_r;

   assign cmd_ack = ack_reg;

   FD ACK_REG_INST1
     (
      .Q (ack_reg),
      .D (ack_o),
      .C (~clk)
      );

   assign ack_o = ((write_cmd_in == 1'b1) || (write_cmd1 == 1'b1) ||
                   (read_cmd == 1'b1) || (read_cmd1 == 1'b1));

//******************************************************************************
//  init_done will be asserted when initialization sequence is complete
//******************************************************************************
   always @ (negedge clk) begin
      if (rst180_r == 1'b1) begin
         init_memory  <= 1'b0;
         init_done    <= 1'b0;
         init_done_r1 <= 1'b0;
      end
      else begin
         init_memory  <= init_mem;
         init_done    <= init_done_value && ~init_done || init_done;
         init_done_r1 <= init_done;
      end
   end

   //synthesis translate_off
   always @ (negedge clk) begin
      if (rst180_r == 1'b0)
        if (init_done == 1'b1 && init_done_r1 == 1'b0)
          $display ("INITIALIZATION_DONE");
   end
   //synthesis translate_on
   
   always @( negedge clk ) begin
      if ( rst180_r )
        init_mem <= 1'b0;
      else if ( initialize_memory )
        init_mem <= 1'b1;
      else if ( (init_count == INIT_DONE_COUNT) && (count5 == 5'd1) )
        init_mem <= 1'b0;
      else
        init_mem <= init_mem;
   end

   always @( negedge clk ) begin
      if ( rst180_r )
        init_count  <= 4'b0;
      else if (((init_current_state == INIT_PRECHARGE) || 
		(init_current_state == INIT_LOAD_MODE_REG)
                || (init_current_state == INIT_AUTO_REFRESH))
	       && init_memory == 1'b1)
        init_count    <= init_count + 1'b1;
      else
        init_count    <= init_count;
   end

   assign init_done_value =  (init_count == INIT_DONE_COUNT) ? 1'b1 : 1'b0;

   assign go_to_active_value =(((write_cmd_in == 1'b1) && 
				(accept_cmd_in == 1'b1)) ||
			       ((read_cmd == 1'b1) && 
				(accept_cmd_in == 1'b1)) ) ? 1'b1 : 1'b0;

   always @ (negedge clk) begin
      if (rst180_r == 1'b1)
        go_to_active <= 1'b0;
      else
        go_to_active <= go_to_active_value;
   end

   always @ (negedge clk) begin
      if (rst180_r == 1'b1) begin
         rfc_count_reg   <= 1'b0;
         ar_done_reg     <= 1'b0;
      end
      else begin
         if(rfc_count == 6'b000010 )
           ar_done_reg <= 1'b1;
         else
           ar_done_reg <= 1'b0;
         if(ar_done_reg == 1'b1)
           rfc_count_reg <= 1'b1;
         else if(init_done == 1'b1 && init_mem == 1'b0 && rfc_count == 6'b000000)
           rfc_count_reg <= 1'b1;
         else if (auto_ref_issued == 1'b1)
           rfc_count_reg <= 1'b0;
         else
           rfc_count_reg <= rfc_count_reg;
      end
   end

//******************************************************************************
// Initialization state machine
//******************************************************************************
   always @ (negedge clk) begin
      if (rst180_r == 1'b1)
        init_current_state <= INIT_IDLE;
      else
        init_current_state <= init_next_state;
   end
   
   always @ (*) begin
      if (rst180_r == 1'b1)
        init_next_state = INIT_IDLE;
      else begin
         case (init_current_state)
           INIT_IDLE : begin
              if (init_memory == 1'b1) begin
                 case (init_count)
                   4'b0000 :
                     init_next_state = INIT_PRECHARGE;
                   4'b0001 : begin
                      if (count5 == 5'd1)
                        init_next_state = INIT_AUTO_REFRESH;
                      else
                        init_next_state = INIT_IDLE;
                   end
                   4'b0010 : begin
                      if (count5 == 5'd1)
                        init_next_state = INIT_AUTO_REFRESH;
                      else
                        init_next_state = INIT_IDLE;
                   end
                   4'b0011 : begin
                      if (count5 == 5'd1)
                        init_next_state = INIT_LOAD_MODE_REG;
                      else
                        init_next_state = INIT_IDLE;
                   end		   
                   4'b0100 : begin
                      if (count5 == 5'd1)
                        init_next_state = INIT_LOAD_MODE_REG;
                      else
                        init_next_state = INIT_IDLE;
                   end
                   4'b0101 : begin
                      init_next_state = INIT_IDLE;
                   end
                   default :
                     init_next_state = INIT_IDLE;
                 endcase
              end
              else
                init_next_state = INIT_IDLE;
           end
           INIT_PRECHARGE :
             init_next_state = INIT_IDLE;	   
           INIT_LOAD_MODE_REG :
             init_next_state = INIT_IDLE;
           INIT_AUTO_REFRESH :
             init_next_state = INIT_IDLE;
           default :
             init_next_state = INIT_IDLE;
         endcase
      end
   end

//*****************************************************************************
// Main state machine
//******************************************************************************

   always @ (negedge clk) begin
      if (rst180_r == 1'b1)
        current_state    <= IDLE;
      else
        current_state    <= next_state;
   end

   always @( * ) begin
      if ( rst180_r )
        next_state = IDLE;
      else begin
         case ( current_state )
           IDLE:
             if(~init_mem) begin
                if ( auto_ref == 1'b1 && rfc_count_reg == 1'b1 && 
		     rp_count == 3'b000)
                  next_state = AUTO_REFRESH;
                else if (go_to_active == 1'b1)
                  next_state = ACTIVE;
                else
                  next_state = IDLE;
             end
             else
               next_state = IDLE;	 
  
           PRECHARGE :
             next_state = PRECHARGE_WAIT;
	   
           PRECHARGE_WAIT : begin
              if (rp_count == 3'b000) begin
                 if (auto_ref) begin
                    next_state = AUTO_REFRESH;
                 end else if (go_to_active == 1'b1) begin
                    next_state = ACTIVE;
                 end else  begin
                    next_state = IDLE;
                 end
              end else begin
                 next_state = PRECHARGE_WAIT;
              end
           end

           AUTO_REFRESH :
             next_state = AUTO_REFRESH_WAIT;

           AUTO_REFRESH_WAIT : begin
              if ( rfc_count == 6'b000000 )
                next_state = IDLE;
              else
                next_state = AUTO_REFRESH_WAIT;
           end

           ACTIVE :
             next_state = ACTIVE_WAIT;

           ACTIVE_WAIT : begin
              if(rcd_count == 2'b01  && write_cmd1)
                next_state = FIRST_WRITE;
              else if (rcd_count == 2'b01 && read_cmd1)
                next_state = BURST_READ;
              else
                next_state = ACTIVE_WAIT;
           end

           FIRST_WRITE : begin
              if ((burst_length == 3'b001) && (wrburst_end == 1'b0))
                next_state = BURST_WRITE;
              else if ((burst_length == 3'b001) && (wrburst_end == 1'b1))
                next_state = PRECHARGE_AFTER_WRITE;
              else
                next_state = WRITE_WAIT;
           end

           WRITE_WAIT : begin
              case(wrburst_end)
                1'b1 :
                  next_state = PRECHARGE_AFTER_WRITE;
                1'b0 : begin
                   if   (wrburst_end_cnt == 3'b010)
                     next_state = BURST_WRITE;
                   else
                     next_state = WRITE_WAIT;
                end
                default :
                  next_state = WRITE_WAIT;
              endcase
           end 
	   
           BURST_WRITE : begin
              if ((burst_length == 3'b001) && (wrburst_end == 1'b0))
                next_state = BURST_WRITE;
              else if ((burst_length == 3'b001) && (wrburst_end == 1'b1))
                next_state = PRECHARGE_AFTER_WRITE;
              else
                next_state = WRITE_WAIT;
           end

           PRECHARGE_AFTER_WRITE :
             next_state = PRECHARGE_AFTER_WRITE_2;

           PRECHARGE_AFTER_WRITE_2 : begin
              if(wr_count == 2'd0 && ras_count == 4'd0)
                next_state = PRECHARGE;
              else
                next_state = PRECHARGE_AFTER_WRITE_2;
           end
	   
           READ_WAIT : begin
              case(rdburst_end)
                1'b1 :
                  next_state = PRECHARGE_AFTER_WRITE;
                1'b0 : begin
                   if (cas_count <= 3'b001)
                     next_state = BURST_READ;
                   else
                     next_state = READ_WAIT;
                end
                default :
                  next_state = READ_WAIT;
              endcase
           end 
	   
           BURST_READ : begin
              if ((burst_length == 3'b001) && (rdburst_end == 1'b0))
                next_state = BURST_READ;
              else if ((burst_length == 3'b001) && (rdburst_end == 1'b1))
                next_state = PRECHARGE_AFTER_WRITE;
              else
                next_state = READ_WAIT;
           end

           default :
             next_state = IDLE;

         endcase
      end
   end

//******************************************************************************
// address generation logic
//******************************************************************************
   always @( negedge clk ) begin
      if(rst180_r)
        ddr_address1 <= {`ROW_ADDRESS{1'b0}};
      else if(init_mem)
        case ( init_count )
          4'b0000 : ddr_address1 <= {`ROW_ADDRESS{1'b0}}
                                             | 12'h400; //Precharge All
          4'b0011 : ddr_address1 <= lmr; //LMR
          4'b0100 : ddr_address1 <= emr; //EMR
          default : ddr_address1 <= {`ROW_ADDRESS{1'b0}};
        endcase
      else if ( current_state == PRECHARGE )
        ddr_address1 <= {`ROW_ADDRESS{1'b0}} | 12'h400;
      else if ( current_state == ACTIVE )
        ddr_address1 <= row_address_reg;
      else if ( current_state == BURST_WRITE || current_state == FIRST_WRITE
                || current_state == BURST_READ )
        ddr_address1 <= column_address_reg;
      else
        ddr_address1 <= `ROW_ADDRESS'b0;
   end
   
   always @( negedge clk ) begin
      if ( rst180_r )
        ddr_ba1 <= {`BANK_ADDRESS{1'b0}};
      else if ( init_count == 4'b0100 ) // EMR
        ddr_ba1 <= {2'b10};
      else if ( current_state == ACTIVE || current_state == FIRST_WRITE ||
                current_state == BURST_WRITE || current_state == BURST_READ )
        ddr_ba1 <= ba_address_reg2;
      else
        ddr_ba1 <= {`BANK_ADDRESS{1'b0}};
   end

   assign ddr_address_cntrl   = ddr_address1;
   assign ddr_ba_cntrl        = ddr_ba1;


//******************************************************************************
// Control signals to the Memory
//******************************************************************************
   assign ddr_rasb1 = ((current_state == ACTIVE) || (current_state == PRECHARGE)
		       || (current_state == AUTO_REFRESH) ||
		       (init_current_state == INIT_PRECHARGE) ||
		       (init_current_state == INIT_AUTO_REFRESH) ||
		       (init_current_state == INIT_LOAD_MODE_REG))? 1'b0 : 1'b1;   
   assign ddr_casb1 = ((current_state == BURST_READ) || 
                       (current_state == BURST_WRITE) || 
		       (current_state == FIRST_WRITE) || 
		       (current_state == AUTO_REFRESH) ||
		       (init_current_state == INIT_AUTO_REFRESH) ||
		       (init_current_state == INIT_LOAD_MODE_REG))? 1'b0 : 1'b1;
   assign ddr_web1  = ((current_state == BURST_WRITE) || 
                       (current_state == FIRST_WRITE) ||
                       (current_state == PRECHARGE)   ||
                       (init_current_state == INIT_PRECHARGE)||
                       (init_current_state == INIT_LOAD_MODE_REG)) ? 1'b0 : 1'b1;

//******************************************************************************
// register CONTROL SIGNALS outputs
//******************************************************************************
	  
   always @ (negedge clk) begin
      if (rst180_r == 1'b1) begin
         ddr_rasb2 <= 1'b1;
         ddr_casb2 <= 1'b1;
         ddr_web2  <= 1'b1;
      end
      else begin
         ddr_rasb2    <= ddr_rasb1;
         ddr_casb2    <= ddr_casb1;
         ddr_web2     <= ddr_web1;
      end
   end
   
   always @ (negedge clk) begin
      if (rst180_r == 1'b1) begin
         ddr_rst_dqs_rasb4  <= 1'b1;
         ddr_rst_dqs_casb4  <= 1'b1;
         ddr_rst_dqs_web4   <= 1'b1;
      end
      else begin
         if(cas_latency == 3'b011) begin
            ddr_rst_dqs_rasb4  <= ddr_rasb1;
            ddr_rst_dqs_casb4  <= ddr_casb1;
            ddr_rst_dqs_web4   <= ddr_web1;
         end
         else begin
            ddr_rst_dqs_rasb4  <= ddr_rst_dqs_rasb4;
            ddr_rst_dqs_casb4  <= ddr_rst_dqs_casb4;
            ddr_rst_dqs_web4   <= ddr_rst_dqs_web4;
         end
      end
   end 
   
   always @ (negedge clk) begin
      if (rst180_r == 1'b1)
        dqs_div_cascount <= 3'b000;
      else begin
         if( (ddr_rasb1 == 1'b1) && (ddr_casb1 == 1'b0) && (ddr_web1 == 1'b1)
             && ((cas_latency == 3'b010)||(cas_latency == 3'b110)) )
           dqs_div_cascount <= burst_cnt_max ;

         else if((ddr_rst_dqs_rasb4 == 1'b1) && (ddr_rst_dqs_casb4 == 1'b0)
                 && (ddr_rst_dqs_web4 == 1'b1))
           dqs_div_cascount <= burst_cnt_max ;
         else begin
            if (dqs_div_cascount != 3'b000)
              dqs_div_cascount <= dqs_div_cascount - 1'b1;
            else
              dqs_div_cascount <= dqs_div_cascount;
         end
      end
   end

   always @ (negedge clk) begin
      if (rst180_r == 1'b1)
        dqs_div_rdburstcount <= 3'b000;
      else begin
         if (dqs_div_cascount == 3'b001  && burst_length == 3'b010)
           dqs_div_rdburstcount <= 3'b010;
         else if (dqs_div_cascount == 3'b011  && burst_length == 3'b011)
           dqs_div_rdburstcount <= 3'b100;
         else if (dqs_div_cascount == 3'b001  && burst_length == 3'b001)
           dqs_div_rdburstcount <= 3'b001;
         else begin
            if (dqs_div_rdburstcount != 3'b000)
              dqs_div_rdburstcount <= dqs_div_rdburstcount - 1'b1;
            else
              dqs_div_rdburstcount <= dqs_div_rdburstcount;
         end
      end
   end

   always @ (negedge clk) begin
      if (rst180_r == 1'b1)
        rst_dqs_div_r <= 1'b0;
      else begin
         if (dqs_div_cascount == 3'b001  && burst_length == 3'b010)
           rst_dqs_div_r <= 1'b1;
         else if (dqs_div_cascount == 3'b011  && burst_length == 3'b011)
           rst_dqs_div_r <= 1'b1;
         else if (dqs_div_cascount == 3'b001  && burst_length == 3'b001)
           rst_dqs_div_r <= 1'b1;
         else if (dqs_div_rdburstcount == 3'b001 && dqs_div_cascount == 3'b000)
           rst_dqs_div_r <= 1'b0;
         else
           rst_dqs_div_r <= rst_dqs_div_r;
      end
   end

   //For BL=2,4,8 n Comp or Unbuffered Dimms
    generate
      if(BURST_LEN_VAL == 3'b001) begin : ass_rst_dqs
        assign rst_dqs_div_d = rst_dqs_div_r1;
      end else begin
        assign rst_dqs_div_d = rst_dqs_div_r;
      end
    endgenerate

   always @(negedge clk)      begin
     rst_dqs_div_r1 <= rst_dqs_div_r;
     rst_dqs_div_r2 <= rst_dqs_div_d;
   end

//Read fifo read enable logic, this signal is one clock delayed wrt to 
// rst_dqs_div_int signal. 

   always @(negedge clk)  
     read_fifo_rden <= rst_dqs_div_r2;


   always @( negedge clk )   begin
     if (dqs_div_cascount != 3'd0 || dqs_div_rdburstcount !=3'd0)
       rst_calib <= 1'b1;
     else
       rst_calib <= 1'b0;
   end

   assign clk180 = ~clk;

   generate
      if(CAS_LAT_VAL == 3'b110) begin : FD_INST
        FD rst_iob_out
        (
        .Q(rst_dqs_div_int),
        .D(rst_dqs_div_d),
        .C(clk180)
        )/* synthesis syn_useioff = 1 */;
      end else begin
        FD rst_iob_out
        (
        .Q(rst_dqs_div_int),
        .D(rst_dqs_div_d),
        .C(clk)
        )/* synthesis syn_useioff = 1 */;
     end
     endgenerate


endmodule
