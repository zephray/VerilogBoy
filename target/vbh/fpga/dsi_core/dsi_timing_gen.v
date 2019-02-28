/* 
 * DSI Core
 * Copyright (C) 2013-2014 twl <twlostow@printf.cc>
 * Copyright (C) 2018 Wenting Zhang <zephray@outlook.com>
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

`include "dsi_defs.vh"

/* 
 * dsi_timing_gen.v
 *
 * Image timing generator - produces the display refresh timing (hsync, vsync, blanking, etc.)
 * The image is delivered by a simple FIFO interface, pixel-by-pixel. The output requests
 * particular packets from the Packet Assembler.
 */

module dsi_timing_gen (
    clk_i,
    rst_n_i,

    fifo_empty_i,
    fifo_rd_o,
    fifo_pixels_i,

    pix_vsync_i,
    pix_next_frame_o,

    p_req_o,
    p_islong_o,
    p_type_o,
    p_wcount_o,
    p_command_o,
    p_payload_o,
    p_dreq_i,
    p_last_o,

    enable_i,
    force_lp_i,

    host_a_i,
    host_d_i,
    host_d_o,
    host_wr_i
    );

    parameter g_bytes_per_pixel = 2;

    localparam g_pixel_width =  g_bytes_per_pixel * 8;

    input clk_i;
    input rst_n_i;

    input fifo_empty_i;
    output fifo_rd_o;
    input [g_pixel_width - 1: 0] fifo_pixels_i;

    input                        pix_vsync_i;
    output reg                   pix_next_frame_o;

    output reg                   p_req_o, p_islong_o;
    output reg [5:0]             p_type_o;
    output reg [15:0]            p_wcount_o, p_command_o;
    output [g_pixel_width-1:0]   p_payload_o;

    input                        p_dreq_i;

    output reg                   p_last_o;
    
    input                        enable_i;
    input                        force_lp_i;

    input [3:0]                  host_a_i;
    input [7:0]                 host_d_i;
    output reg [7:0]            host_d_o;
    input                        host_wr_i;
   
   
`define ST_BPORCH 0
`define ST_FPORCH 1
`define ST_HSYNC_START 2
`define ST_HSYNC_END 3
`define ST_HSYNC_ACTIVE 4
`define ST_LINE 6
`define ST_VSYNC_PACKET 7
`define ST_STOP 8
`define ST_LONG_PACKET 9
`define ST_LP 10
`define ST_PACKET_HEADER 11

    reg [3:0]   state, next_state;

    reg [11:0]  h_count, v_count;

    reg [7:0]   h_1, h_2, h_4;
    reg [11:0]  h_3;
    reg [7:0]   v_1, v_2;
    reg [11:0]  v_3, v_4;

    reg         disp_en_mask;

    reg [11:0]  pixel_counter, pixel_counter_d0;
    reg [2:0]   byte_counter;
    reg         is_long;
   
   
    // host registers
    always@(posedge clk_i)
        if(host_wr_i) begin
            case (host_a_i)       
            `REG_H1     : h_1 <= host_d_i;
            `REG_H2     : h_2 <= host_d_i;
            `REG_H3_L   : h_3[7:0] <= host_d_i;
            `REG_H3_H   : h_3[11:8] <= host_d_i[3:0];
            `REG_H4     : h_4 <= host_d_i;
            `REG_V1     : v_1 <= host_d_i;
            `REG_V2     : v_2 <= host_d_i;
            `REG_V3_L   : v_3[7:0] <= host_d_i;
            `REG_V3_H   : v_3[11:8] <= host_d_i[3:0];
            `REG_V4_L   : v_4[7:0] <= host_d_i;
            `REG_V4_H   : v_4[11:8] <= host_d_i[3:0];
            endcase // case (host_a_i)
        end

    task send(input long, input [5:0] ptype, input [15:0] count, input[3:0] _next_state, input is_last);
        begin
            if(p_dreq_i) begin
                p_islong_o <= long;
                p_type_o <= ptype;
                p_wcount_o <= count;
                p_command_o <= 0;
                p_last_o <= is_last;

                pixel_counter <= count;
                byte_counter <= 4 - 1; // Short packet is always 4 bytes
                is_long <= long;
                state <= `ST_PACKET_HEADER;
            
                next_state <= _next_state;
            end // if (p_dreq_i)
        end
    endtask // send
   
    reg push_pixels, push_pixels_d0;
    reg waiting_frame = 0;

    always@(posedge clk_i)
        if(!rst_n_i || !enable_i) begin
            v_count  <= 0;
            state <= `ST_LP;
            pixel_counter <= h_3;
            p_req_o <= 0;
            p_last_o <= 0;

            disp_en_mask <= 0;
            push_pixels <= 0;
            push_pixels_d0 <= 0;
            pix_next_frame_o <= 0;
        end
        else begin
            push_pixels_d0 <= push_pixels;
            case (state)
            `ST_FPORCH:
            begin
                push_pixels<=0;
                push_pixels_d0<=0;
               
                if(v_count == v_2) begin
                    disp_en_mask <= 1;
                end else if(v_count == v_3) begin
                    disp_en_mask <= 0;
                end 

                if(force_lp_i) begin
                    p_req_o <= 0;
                    state <= `ST_LP;
                    pixel_counter <= 0;
                end
                else
                    send(1, `PTYPE_BLANKING, h_4, `ST_HSYNC_START, 0);
            end // case: `ST_FPORCH
          
            // Full Sync
            /*`ST_HSYNC_START: begin
                p_req_o <= 1;

                if(v_count == 0)
                    send(0, `PTYPE_VSYNC_START, 0, `ST_HSYNC_ACTIVE, 0);
                else if (v_count == v_1)
                    send(0, `PTYPE_VSYNC_END, 0, `ST_HSYNC_ACTIVE, 0);
                else if (v_count == v_4)
                    send(0, `PTYPE_EOT, h_3, `ST_LP, 1); // h_3 used as the frame gap
                else
                    send(0, `PTYPE_HSYNC_START, 0, `ST_HSYNC_ACTIVE, 0);
            end*/
            
            // Pulse Sync
            `ST_HSYNC_START: begin
                p_req_o <= 1;

                if(v_count == 0)
                    send(0, `PTYPE_VSYNC_START, 0, `ST_BPORCH, 0);
                else if (v_count == v_4)
                    send(0, `PTYPE_EOT, h_3, `ST_LP, 1); // h_3 used as the frame gap
                else
                    send(0, `PTYPE_HSYNC_START, 0, `ST_BPORCH, 0);
            end
            
            // No Sync
            /*`ST_HSYNC_START: begin
                p_req_o <= 1;

                if (v_count == v_4)
                    send(0, `PTYPE_EOT, h_3, `ST_LP, 1); // h_3 used as the frame gap
                else
                    send(1, `PTYPE_BLANKING, h_2, `ST_LINE, 0);
            end*/
            
            `ST_HSYNC_ACTIVE:
                send(1, `PTYPE_BLANKING, h_1, `ST_HSYNC_END, 0);
                
            `ST_HSYNC_END:
                send(0, `PTYPE_HSYNC_END, 0, `ST_BPORCH, 0);

            `ST_BPORCH:
                send(1, `PTYPE_BLANKING, h_2, `ST_LINE, 0);

            `ST_LINE:
            begin
                send(1, disp_en_mask ? `PTYPE_RGB: `PTYPE_BLANKING, h_3, `ST_FPORCH, 0);
                if(p_dreq_i) begin
                    if(v_count == v_4)
                        v_count <= 0;
                    else
                        v_count <= v_count + 1;
                    push_pixels <= disp_en_mask;
                end
            end

            `ST_LP: begin
                p_req_o <= 0;
         
                if(pixel_counter == 0) begin
                    if(pix_vsync_i && !force_lp_i) begin
                        state <= `ST_HSYNC_START;
                        pix_next_frame_o <= 0;
                    end
                    v_count <= 0;
                end
                else begin
                    pix_next_frame_o <= 1;
                    pixel_counter <= pixel_counter - 1;
                end // else: !if(pixel_counter == 0)
            end
          
            `ST_LONG_PACKET:
            begin
                if(p_dreq_i)  begin
                    pixel_counter <= pixel_counter - g_bytes_per_pixel;
                    pixel_counter_d0 <= pixel_counter;
                end

                if(pixel_counter == 0)
                begin
                    push_pixels <=0;
                    state <= next_state;
                end
            end
            
            `ST_PACKET_HEADER:
            begin
                byte_counter <= byte_counter - 1;
                if (byte_counter == 1) begin
                    state <= (is_long) ? (`ST_LONG_PACKET) : next_state;
                end
            end
        endcase // case (state)
    end // else: !if(!rst_n_i || !enable)

    assign fifo_rd_o = (push_pixels && p_dreq_i);
    assign p_payload_o = (push_pixels || push_pixels_d0 ? fifo_pixels_i : 0); 

endmodule // dsi_timing_gen

