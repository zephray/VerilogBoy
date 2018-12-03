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
