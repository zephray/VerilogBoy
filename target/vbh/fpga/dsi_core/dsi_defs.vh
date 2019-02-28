/* 
 * DSI Core
 * Copyright (C) 2013 twl <twlostow@printf.cc>
 * Copyright (C) 2018 Wenting Zhang <zephray@outlook.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

`define PTYPE_VSYNC_START 6'h01
`define PTYPE_VSYNC_END   6'h11
`define PTYPE_HSYNC_START 6'h21
`define PTYPE_HSYNC_END   6'h31

//`define PTYPE_BLANKING    6'h09
`define PTYPE_BLANKING    6'h19
`define PTYPE_RGB24       6'h3e
`define PTYPE_RGB16       6'h0e
`define PTYPE_RGB         6'h0e

`define PTYPE_EOT         6'h08

`define DSI_SYNC_SEQ      8'b10111000

`define REG_DSI_CTL       0
`define REG_TICK_DIV      1
`define REG_LP_TX         2

`define REG_H1            3
`define REG_H2            4
`define REG_H3_L          5
`define REG_H3_H          6
`define REG_H4            7

`define REG_V1            8
`define REG_V2            9
`define REG_V3_L          10
`define REG_V3_H          11
`define REG_V4_L          12
`define REG_V4_H          13

`define DBG_CTL_SEND 1
`define DBG_CTL_NEXT 2
