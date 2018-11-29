/* 
 * DSI Core
 * Copyright (C) 2013-2014 twl <twlostow@printf.cc>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

`timescale 1ns/1ps

/*
 * dsi_utils.v
 * 
 * Some utility stuff (parity/CRC generators)
 */

module dsi_parity 
  (
   input [23:0] d_i,
   output [7:0] p_o
   );

   assign p_o[0]=^{d_i[2:0], d_i[5:4], d_i[7], d_i[11:10], d_i[13], d_i[16], d_i[23:20]};
   assign p_o[1]=^{d_i[1:0], d_i[4:3], d_i[6], d_i[8], d_i[10], d_i[12], d_i[14], d_i[17], d_i[23:20]}; 
   assign p_o[2]=^{d_i[0], d_i[3:2], d_i[6:5], d_i[9], d_i[12:11], d_i[15], d_i[18], d_i[22:20] };
   assign p_o[3]=^{d_i[3:1], d_i[9:7], d_i[15:13], d_i[21:19], d_i[23]};
   assign p_o[4]=^{d_i[9:4], d_i[20:16], d_i[23:22]}; 
   assign p_o[5]=^{d_i[19:10], d_i[23:21]};
   assign p_o[7:6]=2'b0;
   
endmodule // dsi_parity


module dsi_crc_comb (input[15:0] crc, input[7:0] x, output [15:0] crc_new);
   assign  crc_new[0] = crc[8] ^ crc[12] ^ x[7-0] ^ x[7-4];
   assign	 crc_new[1] = crc[9] ^ crc[13] ^ x[7-1] ^ x[7-5];
   assign	 crc_new[2] = crc[10] ^ crc[14] ^ x[7-2] ^ x[7-6];
   assign	 crc_new[3] = crc[11] ^ crc[15] ^ x[7-3] ^ x[7-7];
   assign	 crc_new[4] = crc[12] ^ x[7-4];
   assign	 crc_new[5] = crc[8] ^ crc[12] ^ crc[13] ^ x[7-0] ^ x[7-4] ^ x[7-5];
   assign	 crc_new[6] = crc[9] ^ crc[13] ^ crc[14] ^ x[7-1] ^ x[7-5] ^ x[7-6];
   assign	 crc_new[7] = crc[10] ^ crc[14] ^ crc[15] ^ x[7-2] ^ x[7-6] ^ x[7-7];
   assign	 crc_new[8] = crc[0] ^ crc[11] ^ crc[15] ^ x[7-3] ^ x[7-7];
   assign	 crc_new[9] = crc[1] ^ crc[12] ^ x[7-4];
   assign	 crc_new[10] = crc[2] ^ crc[13] ^ x[7-5];
   assign	 crc_new[11] = crc[3] ^ crc[14] ^ x[7-6];
   assign	 crc_new[12] = crc[4] ^ crc[8] ^ crc[12] ^ crc[15] ^ x[7-0] ^ x[7-4] ^ x[7-7];
   assign	 crc_new[13] = crc[5] ^ crc[9] ^ crc[13] ^ x[7-1] ^ x[7-5];
   assign	 crc_new[14] = crc[6] ^ crc[10] ^ crc[14] ^ x[7-2] ^ x[7-6];
   assign	 crc_new[15] = crc[7] ^ crc[11] ^ crc[15] ^ x[7-3] ^ x[7-7];
endmodule // dsi_crc_comb


module dsi_crc
  (
   clk_i,
   rst_i,
   valid_i,
   nbytes_i,
   d_i,
   crc_o);

   parameter g_max_data_bytes = 3;

   input [g_max_data_bytes*8-1:0] d_i;
   input                          valid_i;
   input [2:0] 			  nbytes_i;
   input                          clk_i;
   input                          rst_i;
   output [15:0] 		  crc_o;
   
   reg [15:0] 			  crc_cur;

   wire [15:0] 			  stages_in [0:g_max_data_bytes-1];
   wire [15:0] 			  stages_out [0:g_max_data_bytes-1];

   generate
      genvar                      i        ;
      for(i=0;i<g_max_data_bytes;i=i+1)
        begin
           if(i != g_max_data_bytes-1)
             assign stages_in[i] = (nbytes_i == (i+1) ? crc_cur : stages_out[i+1]);
           dsi_crc_comb stageX(stages_in[i], d_i[8*i+7:8*i], stages_out[i]);
        end

      assign stages_in[g_max_data_bytes-1] = crc_cur;
   endgenerate

   always@(posedge clk_i)
     if(rst_i)
       crc_cur <= 16'hffff;
     else if(valid_i)
       crc_cur <= stages_out[0];

   assign crc_o = {crc_cur[0], crc_cur[1],crc_cur[2], crc_cur[3],
                   crc_cur[4], crc_cur[5],crc_cur[6], crc_cur[7],
                   crc_cur[8], crc_cur[9],crc_cur[10], crc_cur[11],
                   crc_cur[12], crc_cur[13],crc_cur[14], crc_cur[15]};
   
   
endmodule // dsi_crc

module dsi_wishbone_async_bridge
  #(
    parameter g_csr_addr_bits = 10
    ) 
   (
    input 			     clk_wb_i,
    input 			     clk_csr_i,
    input 			     rst_n_i,
   
    input [31:0] 		     wb_adr_i,
    input [31:0] 		     wb_dat_i,
    input [3:0] 		     wb_sel_i,
    input 			     wb_cyc_i,
    input 			     wb_stb_i,
    input 			     wb_we_i,
    output reg 			     wb_ack_o,
    output 			     wb_stall_o,
    output reg [31:0] 		     wb_dat_o,

    output reg [g_csr_addr_bits-1:0] csr_adr_o,
    output reg [31:0] 		     csr_dat_o,
    output 			     csr_wr_o,
    input [31:0] 		     csr_dat_i
    );

`define ST_IDLE 0
`define ST_WAIT_ACK 1
`define ST_ACK 2

   reg [1:0] 			     state;
   reg 				     req_wb, req_write;
   wire 			     req_csr;

   reg 				     wb_stb_d0 = 0;
   reg 				     wb_stall;
   reg 				     ack_csr;
   
   wire 			     ack_wb;
   
   dsi_sync_chain sc_req_to_csr (clk_csr_i, rst_n_i, req_wb, req_csr);
   dsi_sync_chain sc_ack_to_wb (clk_wb_i, rst_n_i, ack_csr, ack_wb);
   
   reg 				     req_csr_d0;
   reg 				     ack_wb_d0;

   always@(posedge clk_csr_i) req_csr_d0 <= req_csr;
   always@(posedge clk_wb_i) ack_wb_d0 <= ack_wb;
   
   always@(posedge clk_wb_i or negedge rst_n_i)
     if(!rst_n_i)
       begin
          wb_stb_d0 <= 0;
          wb_stall <= 1;
       end else begin
          wb_stb_d0 <= wb_stb_i & wb_cyc_i;
          wb_stall <= ~ (wb_stb_i & wb_cyc_i & !wb_stb_d0);
       end

   always@(posedge clk_wb_i or negedge rst_n_i)
     if(!rst_n_i)
       begin
          state <= `ST_IDLE;
          req_wb <= 0;
          wb_ack_o <= 0;
       end else begin
	  case (state)
            `ST_IDLE: if(wb_cyc_i && wb_stb_i) begin
               req_wb <= 1;
               wb_ack_o <= 0;
               req_write <= wb_we_i;
               csr_dat_o <= wb_dat_i;
               csr_adr_o <= wb_adr_i[g_csr_addr_bits+1:2];
               state <= `ST_WAIT_ACK;
            end

            `ST_WAIT_ACK: 
              if(ack_wb) begin
		 req_wb <= 0;
              end else if (ack_wb_d0) begin
		 wb_dat_o <= csr_dat_i;
		 wb_ack_o <= 1;
		 state <= `ST_ACK;
              end 
            `ST_ACK: begin
               wb_ack_o <=0;
               state <= `ST_IDLE;
            end
            
	  endcase // case (state)
       end // if (!rst_n_i)

   
   assign csr_wr_o = req_wb & req_write & !req_csr_d0 & req_csr;
   always@(posedge clk_csr_i)
     ack_csr <= req_csr;
   
   assign wb_stall_o = wb_stall;

endmodule // dsi_wishbone_async_bridge

module dsi_sync_chain
  #( parameter length = 2)
   (
    input  clk_i,
    input  rst_n_i,
    input  d_i,
    output q_o );

   reg [length-1:0] sync;

   
   always@(posedge clk_i)
     begin
        sync[0] <= d_i;
        sync[length-1:1] <= sync[length-2:0];
     end
   assign q_o = sync[length-1];
   
endmodule // dsi_sync_chain
