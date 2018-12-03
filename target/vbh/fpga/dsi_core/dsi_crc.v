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
      genvar i;
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