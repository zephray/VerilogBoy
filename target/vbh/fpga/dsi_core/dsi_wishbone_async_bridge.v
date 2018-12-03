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

module dsi_wishbone_async_bridge
   (
    input               clk_wb_i,
    input               clk_csr_i,
    input               rst_n_i,
   
    input [3:0]         wb_adr_i,
    input [7:0]         wb_dat_i,
    input               wb_cyc_i,
    input               wb_stb_i,
    input               wb_we_i,
    output reg          wb_ack_o,
    output              wb_stall_o,
    output reg [7:0]    wb_dat_o,

    output reg [3:0]    csr_adr_o,
    output reg [7:0]    csr_dat_o,
    output              csr_wr_o,
    input [7:0]         csr_dat_i
    );

`define ST_IDLE 0
`define ST_WAIT_ACK 1
`define ST_ACK 2

    reg [1:0]            state;
    reg                  req_wb, req_write;
    wire                 req_csr;

    reg                  wb_stb_d0 = 0;
    reg                  wb_stall;
    reg                  ack_csr;
   
    wire                 ack_wb;
   
    dsi_sync_chain sc_req_to_csr (clk_csr_i, rst_n_i, req_wb, req_csr);
    dsi_sync_chain sc_ack_to_wb (clk_wb_i, rst_n_i, ack_csr, ack_wb);
   
    reg                  req_csr_d0;
    reg                  ack_wb_d0;

    always@(posedge clk_csr_i) req_csr_d0 <= req_csr;
    always@(posedge clk_wb_i) ack_wb_d0 <= ack_wb;
   
    always@(posedge clk_wb_i)
        if(!rst_n_i)
        begin
            wb_stb_d0 <= 0;
            wb_stall <= 1;
        end
        else begin
            wb_stb_d0 <= wb_stb_i & wb_cyc_i;
            wb_stall <= ~ (wb_stb_i & wb_cyc_i & !wb_stb_d0);
        end

    always@(posedge clk_wb_i)
        if(!rst_n_i)
        begin
            state <= `ST_IDLE;
            req_wb <= 0;
            wb_ack_o <= 0;
        end
        else begin
            case (state)
            `ST_IDLE: if(wb_cyc_i && wb_stb_i) begin
                req_wb <= 1;
                wb_ack_o <= 0;
                req_write <= wb_we_i;
                csr_dat_o <= wb_dat_i;
                csr_adr_o <= wb_adr_i;
                state <= `ST_WAIT_ACK;
            end

            `ST_WAIT_ACK: 
                if(ack_wb) begin
                    req_wb <= 0;
                end
                else if (ack_wb_d0) begin
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