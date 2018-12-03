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
