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
 * dsi_packer.v
 *
 * A module that tightly packs bytes or byte sequences in to an output word of certain
 * size.
 */

module dsi_byte_swapper
  (
   d_i,
   size_i,
   q_o);
   
   parameter g_num_bytes = 4;

   input [g_num_bytes * 8 - 1 : 0] d_i;
   output [g_num_bytes * 8 - 1 : 0] q_o;
   input [2:0]                      size_i;


   wire [g_num_bytes * 8 - 1 : 0]   swapped[1:g_num_bytes];

   generate 
      genvar                        i, j, nbytes;
      for(nbytes = 1; nbytes <= g_num_bytes; nbytes = nbytes + 1)
        for(i=0;i<8;i=i+1)
          begin
             for(j=0;j<nbytes;j=j+1)
               assign swapped[nbytes] [8 * (nbytes-1-j) + i] = d_i[8 * j + i];
             for(j=nbytes;j<g_num_bytes;j=j+1)
               assign swapped[nbytes] [j * 8 + i ] = 1'b0;
          end
      
   endgenerate

   
   assign q_o = (size_i) <= g_num_bytes ? swapped[size_i] : 'hx;
endmodule

module dsi_byte_shifter 
  (
   d_i,
   shifted_o,
   shift_i
   );

   parameter g_data_bytes = 3;
   parameter g_max_shift = 3;

   localparam c_output_width = 8 * (g_data_bytes + g_max_shift);

   input [3:0] shift_i;
   input [g_data_bytes * 8 - 1: 0] d_i;
   output [c_output_width - 1: 0]  shifted_o;
   
   wire [c_output_width - 1 : 0]   gen_array[0:g_max_shift];

   genvar                          i;

   generate
      for (i=0;i<g_max_shift;i=i+1)
        assign gen_array[i] = d_i << (i * 8);
   endgenerate

   assign shifted_o = gen_array[shift_i];
endmodule // dsi_byte_shifter

module dsi_packer
  (
   clk_i,
   rst_n_i,

   
  
   d_i,
   d_size_i,
   d_req_o,
   d_valid_i,
   d_empty_o,

   q_size_i,
   q_o,
   q_req_i,
   q_flush_i,
   q_valid_o  
   );

   
   parameter g_input_bytes = 3;
   parameter g_output_bytes = 3;

   
   localparam c_shiftreg_bytes = 2 * (g_input_bytes > g_output_bytes ? g_input_bytes : g_output_bytes) + 2;
   
   
   input clk_i, rst_n_i;
   input [g_input_bytes * 8 - 1 : 0] d_i;
   input [3 : 0]                     d_size_i;
   output                            d_req_o;
   input                             d_valid_i, q_flush_i;

   output reg [g_output_bytes * 8 -1 :0] q_o;
   output reg [g_output_bytes-1:0]   q_valid_o;
   output                            d_empty_o;
   
   input                             q_req_i;

   input [2:0]                       q_size_i; // 1 to 4
   
   wire [g_input_bytes * 8 - 1 : 0]  d_in;
   reg [g_output_bytes * 8 - 1 : 0]  q_out;
   
   reg [4:0]                         count, avail, avail_next;
   reg [c_shiftreg_bytes * 8 -1 :0]  shreg, shreg_shifted;
   wire [c_shiftreg_bytes * 8 -1 :0] in_shifted;
   wire                              shift_out;
   wire [4:0]                        in_shift;

   wire                              d_req_int;
   
   
   assign shift_out = (count >= q_size_i && q_req_i);
   assign in_shift = (shift_out ? count - q_size_i : count);
   

   dsi_byte_swapper #(g_input_bytes) U_RevIn ( d_i, d_size_i, d_in );


   wire [8*g_output_bytes-1:0]         q_out_reversed[0:7];
   
   
   
   always@* 
     q_o <= q_out;
  
   dsi_byte_shifter
     #(
       .g_data_bytes(g_input_bytes),
       .g_max_shift(c_shiftreg_bytes - 1)
       ) 
   U_Shifter 
     (
      .d_i(d_in),
      .shift_i(in_shift),
      .shifted_o(in_shifted)
      );
   
   
   always@(posedge clk_i)
     if(!rst_n_i) begin
        q_valid_o <= 0;
        q_out <= 0;
     end else if(shift_out || q_flush_i)
       begin : drive_output
          integer i;
          
          q_out <= shreg[g_output_bytes * 8 - 1 : 0];

          for(i=0;i<g_output_bytes;i=i+1)
            q_valid_o[i] <= count > i;
       end else
         q_valid_o <= 0;
   

   always@*
     begin
        case (q_size_i)
          3: shreg_shifted <= shreg >> 24;
          default: shreg_shifted <= shreg >> 32;
        endcase // case (q_size_i)
     end
   
   always@(posedge clk_i)
     if (!rst_n_i)
       begin
          count <= 0;
          avail <= c_shiftreg_bytes;
          shreg <= 0;
          
       end else begin
          if(d_valid_i && shift_out) begin
             shreg <= shreg_shifted | in_shifted;
             count <= count - q_size_i + d_size_i;
          end else if(d_valid_i) begin
             shreg <= shreg | in_shifted;
             count <= count + d_size_i;
          end else if(shift_out) begin
             shreg <= shreg_shifted;
             count <= count - q_size_i;
          end else if (q_flush_i) begin
             count <= 0;
             shreg <= 0;
          end
          avail <= avail_next;
       end // else: !if(!rst_n_i)

   
   always@*
     if(d_valid_i && shift_out) 
       avail_next <= avail + q_size_i - d_size_i;
     else if(d_valid_i) 
       avail_next <= avail - d_size_i;
     else if(shift_out) 
       avail_next <= avail + q_size_i;
     else if(q_flush_i)
       avail_next <= c_shiftreg_bytes;
     else
       avail_next <= avail;
   
   
   assign d_req_int = (avail_next >= g_input_bytes) || (shift_out && avail_next >= (g_input_bytes - q_size_i));
   assign d_req_o = d_req_int;
   assign d_empty_o = !count;
   
   
endmodule // dsi_packer



