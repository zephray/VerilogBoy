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

/* dsi_core.v - top level of the DSI core */

`include "dsi_defs.vh"

`timescale 1ns/1ps

module dsi_core(
    // system/FIFO clock 
    clk_sys_i,

    // DSI interface byte clock (=PHY clock/8)
    clk_dsi_i,

    // DSI HS clock
    clk_phy_i,

    // Shifted version of PHY clocks (for clock-data lane alignment)
    clk_phy_shifted_i,

    rst_n_i,

    pll_locked_i,

    // Pixel FIFO interface

    // 1 indicates the core is in LP mode, waiting for the start of the next frame
    pix_next_frame_o,
    // when pix_next_frame is asserted, 1 on pix_vsync_i starts outputting next frame
    pix_vsync_i,
    // FIFO almost full
    pix_almost_full_o,
    // FIFO pixel(s) input
    pix_i,
    // FIFO write
    pix_wr_i,

    // DSI high speed output
    dsi_hs_p_o,
    dsi_hs_n_o,

    // DSI low power output
    dsi_lp_p_o,
    dsi_lp_n_o,

    // Low power output enable
    dsi_lp_oe_o,

    // DSI clock lane output
    dsi_clk_p_o,
    dsi_clk_n_o,

    // DSI clock lane LP signals + output enable
    dsi_clk_lp_p_o,
    dsi_clk_lp_n_o,
    dsi_clk_lp_oe_o,

    // Displat Reset pin
    dsi_reset_n_o,

    // Host control registers (WBv4 pipelined, clk_sys_i clock domain)
    wb_adr_i,
    wb_dat_i,
    wb_dat_o,
    wb_cyc_i,
    wb_stb_i,
    wb_we_i,
    wb_ack_o,
    wb_stall_o
);
   
    // number of pixels processed in each clk_dsi_i cycle
    parameter g_pixels_per_clock = 1;
    // max number of DSI lanes
    parameter g_lanes = 1;
    // image FIFO size (holds g_pixels_per_clock * g_fifo_size pixels)
    parameter g_fifo_size = 1024;
    // ineverted lane polarity mask (0 = lane 0, 0x4 = lane 2, etc)
    parameter g_invert_lanes = 0;
    // invert DSI clock when true
    parameter g_invert_clock = 0;

    parameter g_use_external_dsi_clock = 0;

    // PHY clock period, in picoseconds. Used to set clock-to-data shift.
    parameter g_clock_period_ps = 3700;
    // picoseconds per ODELAY2 tap.  Used to set clock-to-data shift.
    parameter g_ps_per_delay_tap = 50;

    localparam g_data_delay = (g_clock_period_ps / 2) / g_ps_per_delay_tap;
    localparam g_pixel_width = 24 * g_pixels_per_clock;

    input  [3:0] wb_adr_i;
    input  [7:0] wb_dat_i;
    output [7:0] wb_dat_o;
    input         wb_cyc_i, wb_stb_i, wb_we_i;
    output        wb_ack_o, wb_stall_o;

    input                          clk_sys_i, clk_phy_i, clk_dsi_i, rst_n_i;
    input                          clk_phy_shifted_i;
    input                          pll_locked_i;

    output                         pix_next_frame_o;
    input                          pix_vsync_i;
    output                         pix_almost_full_o;
    input [g_pixel_width - 1 : 0 ] pix_i;
    input                          pix_wr_i;

    output                         dsi_clk_p_o, dsi_clk_n_o;
    output [g_lanes-1:0]           dsi_hs_p_o, dsi_hs_n_o;
    output [g_lanes-1:0]           dsi_lp_p_o, dsi_lp_n_o;
    output [g_lanes-1:0]           dsi_lp_oe_o;

    output                         dsi_clk_lp_p_o, dsi_clk_lp_n_o;
    output                         dsi_clk_lp_oe_o;

    output reg                     dsi_reset_n_o;

    wire [3:0]                     host_a;
    wire [7:0]                     host_d_in;
    wire [7:0]                     host_d_out;
    wire                           host_wr;

    //reg [7:0]                      r_lane_mux;
    // In one lane mode, there is no meaning of mux
    wire [7:0]                     r_lane_mux = 8'b0;
    reg                            r_lane_invert;
    reg                            r_clock_invert;
    reg                            r_tim_en = 0;
    reg                            r_force_lp = 0;

    dsi_wishbone_async_bridge U_CsrBridge (
        .clk_wb_i (clk_sys_i),
        .clk_csr_i (clk_dsi_i),
        .rst_n_i(rst_n_i),
        .wb_adr_i(wb_adr_i),
        .wb_dat_i(wb_dat_i),
        .wb_cyc_i(wb_cyc_i),
        .wb_stb_i(wb_stb_i),
        .wb_we_i(wb_we_i),
        .wb_ack_o(wb_ack_o),
        .wb_stall_o(wb_stall_o),
        .wb_dat_o(wb_dat_o),

        .csr_adr_o(host_a),
        .csr_dat_o(host_d_in),
        .csr_wr_o(host_wr),
        .csr_dat_i(host_d_out)
    );
   
    ///////////////////
    // PHY/Serdes layer
    ///////////////////

    reg                             tick = 0;

    wire [g_lanes-1:0]              phy_hs_ready_lane,  lp_ready_lane, lp_readback_lane;
    wire [g_lanes:0]                serdes_oe_lane;


    wire [g_lanes-1:0]              lp_txp, lp_txn, lp_oe;

    wire                            lp_ready;
    wire                            phy_hs_ready;

    assign lp_ready = lp_ready_lane[0];
    assign phy_hs_ready = phy_hs_ready_lane[0];

    wire                            phy_hs_request;
    wire [g_lanes * 8 -1 :0]        phy_hs_data;
    wire [g_lanes-1:0]              phy_hs_valid;
    wire [(g_lanes + 1) * 8 - 1: 0] serdes_data;
    reg                             r_dsi_clk_en = 0;
    reg                             lp_request = 0;
    reg                             lp_valid = 0;
    reg [7:0]                       lp_data = 0;
    wire [2:0]                      num_lanes = 3'd1;
    //reg [2:0]                       num_lanes;
   
    dsi_sync_chain #(2) Sync3 (clk_dsi_i, 1'b0, rst_n_i, rst_n_dsi);
   
    generate
        genvar i;
        for(i=0;i<g_lanes;i=i+1) begin
            dphy_lane U_LaneX (
                .clk_i(clk_dsi_i),
                .rst_n_i(rst_n_dsi),

                .tick_i(tick),

                .hs_request_i (phy_hs_request),
                .hs_data_i    (phy_hs_data),
                .hs_ready_o   (phy_hs_ready_lane[i]),
                .hs_valid_i   (phy_hs_valid),

                .lp_request_i (lp_request),
                .lp_data_i    (lp_data),
                .lp_valid_i   (r_lane_mux[ i*2 +: 2] == 0 ? lp_valid : 1'b0),
                .lp_ready_o   (lp_ready_lane[i]),

                .serdes_data_o(serdes_data[ i*8 +: 8]),

                .lane_sel_i   (r_lane_mux[ i*2 +: 2]),
                .lane_invert_i(r_lane_invert),

                .lp_txp_o(lp_txp[i]),
                .lp_txn_o(lp_txn[i]),
                .lp_oe_o(lp_oe[i])
            );

            assign dsi_lp_p_o[i] = lp_txp[i];
            assign dsi_lp_n_o[i] = lp_txn[i];
            assign dsi_lp_oe_o[i] = lp_oe[0];
            assign serdes_oe_lane[i] = lp_oe[0];
        end
    endgenerate
   
    wire clk_lane_ready;
    wire dsi_clk_lp_oe;
   
    dphy_lane U_ClockLane  (
        .clk_i(clk_dsi_i),
        .rst_n_i(rst_n_dsi),

        .tick_i(tick),

        .hs_request_i (r_dsi_clk_en),
        .hs_data_i    ({24'h000000, clk_lane_ready ? 8'haa : 8'h00}),
        .hs_ready_o   (clk_lane_ready),
        .hs_valid_i(1'b1),

        .lp_request_i (1'b0),
        .lp_data_i(8'h00),
        .lp_valid_i(1'b0),
        .lp_ready_o(),

        .serdes_data_o(serdes_data[g_lanes*8 +: 8]),

        .lane_sel_i(2'b00),
        .lane_invert_i( r_clock_invert ), //g_invert_clock ? 1'b1: 1'b0),

        .lp_txp_o(dsi_clk_lp_p_o),
        .lp_txn_o(dsi_clk_lp_n_o),
        .lp_oe_o(dsi_clk_lp_oe)
    );

    assign serdes_oe_lane [g_lanes] = dsi_clk_lp_oe;
    assign dsi_clk_lp_oe_o = dsi_clk_lp_oe;

    wire clk_serdes, serdes_strobe;
    wire clk_serdes_shifted, serdes_strobe_shifted;

    dphy_serdes_plla U_BufPLL (
        .clk_phy_i(clk_phy_i),
        .clk_dsi_i(clk_dsi_i),
        .rst_n_a_i(rst_n_i),
        .locked_i (pll_locked_i),
        .clk_serdes_o(clk_serdes),
        .serdes_strobe_o(serdes_strobe)
    );
    
    //assign clk_serdes_shifted = clk_serdes;
    //assign serdes_strobe_shifted = serdes_strobe;

    dphy_serdes_pllb U_BufPLL_Clk (
        .clk_phy_i(clk_phy_shifted_i),
        .clk_dsi_i(clk_dsi_i),
        .rst_n_a_i(rst_n_i),
        .locked_i (pll_locked_i),
        .clk_serdes_o(clk_serdes_shifted),
        .serdes_strobe_o(serdes_strobe_shifted)
    );
   
    wire [g_lanes:0] tx_p, tx_n;

    generate
        for(i=0;i<g_lanes;i=i+1) begin
            dphy_serdes
                #( .g_delay ( g_data_delay ) )
            U_Serdes_LaneX (
                .clk_serdes_i(clk_serdes),
                .clk_word_i(clk_dsi_i),
                .rst_n_a_i(rst_n_i),
                .strobe_i(serdes_strobe),
                .oe_i(serdes_oe_lane[i]),
                .d_i(serdes_data[i*8 +: 8]),
                .q_p_o(tx_p[i]),
                .q_n_o(tx_n[i])
            );

            if( i < g_lanes ) begin
                assign dsi_hs_p_o[i] = tx_p[i];
                assign dsi_hs_n_o[i] = tx_n[i];
            end
        end // for (i=0;i<=g_lanes;i+=1)
    endgenerate

    dphy_serdes
        #( .g_delay ( 0 ) )
    U_Serdes_ClkLane (
        .clk_serdes_i(clk_serdes_shifted),
        .clk_word_i(clk_dsi_i),
        .rst_n_a_i(rst_n_i),
        .strobe_i(serdes_strobe_shifted),
        .oe_i(serdes_oe_lane[g_lanes]),
        .d_i(serdes_data[g_lanes*8 +: 8]),
        .q_p_o(tx_p[g_lanes]),
        .q_n_o(tx_n[g_lanes])
    );

    assign dsi_clk_p_o = tx_p[g_lanes];
    assign dsi_clk_n_o = tx_n[g_lanes];
   
    ////////////////   
    // Packet layer
    ///////////////

    wire                     p_req, p_islong, p_dreq, p_last;
    wire [5:0]               p_type;
    wire [15:0]              p_command, p_wcount;
    wire [g_pixel_width-1:0] p_payload;

   
    dsi_packet_assembler 
        #(
        .g_num_lanes(g_lanes),
        .g_pixels_per_clock(g_pixels_per_clock)
    ) U_PktAsm (
        .clk_i(clk_dsi_i),
        .rst_n_i(rst_n_dsi),

        .p_req_i(p_req),
        .p_islong_i(p_islong),
        .p_type_i(p_type),
        .p_wcount_i(p_wcount),
        .p_command_i(p_command),
        .p_dreq_o(p_dreq),
        .p_dlast_o(p_dlast),
        .p_payload_i(p_payload),
        .p_last_i(p_last),

        .phy_d_o(phy_hs_data),
        .phy_hs_request_o(phy_hs_request),
        .phy_hs_dreq_i(phy_hs_ready_lane[0]),
        .phy_dvalid_o(phy_hs_valid),
        .num_lanes_i(num_lanes)
    );

    ////////////////
    // Test Screen generator
    ///////////////

    wire                           fifo_empty, fifo_rd;
    wire [g_pixel_width-1:0]       fifo_dout;

   
    ///////////////
    // Image timing
    ///////////////

    wire                           pix_vsync_dsi, pix_next_frame_dsi;

    dsi_sync_chain #(2) Sync1 (clk_dsi_i, rst_n_dsi, pix_vsync_i, pix_vsync_dsi);
    dsi_sync_chain #(2) Sync2 (clk_sys_i, rst_n_i, pix_next_frame_dsi, pix_next_frame_o);

    dsi_timing_gen 
        #( .g_pixels_per_clock(g_pixels_per_clock) )
    U_TimingGen (
        .clk_i(clk_dsi_i),
        .rst_n_i(rst_n_dsi),

        .fifo_empty_i(fifo_empty),
        .fifo_rd_o(fifo_rd),
        .fifo_pixels_i(fifo_dout),
        .pix_vsync_i(pix_vsync_dsi),
        .pix_next_frame_o(pix_next_frame_dsi),
        .p_req_o(p_req),
        .p_islong_o(p_islong),
        .p_type_o(p_type),
        .p_wcount_o(p_wcount),
        .p_command_o(p_command),
        .p_payload_o(p_payload),
        .p_dreq_i(p_dreq),
        .p_last_o(p_last),

        .enable_i(r_tim_en),
        .force_lp_i(r_force_lp),

        .host_a_i(host_a),
        .host_d_i(host_d_in),
        //        .host_d_o(host_d_o),
        .host_wr_i(host_wr)
    );


    ////////////////
    /// Pixel Buffer
    ////////////////

    generic_async_fifo #(
        .g_data_width(g_pixel_width),
        .g_size(g_fifo_size),
        .g_almost_full_threshold(g_fifo_size-20),
        .g_almost_empty_threshold(10),
        .g_with_wr_almost_full(1)  
    ) U_PixFifo (
        .rst_n_i(rst_n_i),
        .clk_wr_i(clk_sys_i),
        .d_i(pix_i),
        .wr_almost_full_o(pix_almost_full_o),
        .we_i(pix_wr_i),

        .clk_rd_i(clk_dsi_i),
        .rd_i(fifo_rd),
        .rd_empty_o(fifo_empty),
        .q_o(fifo_dout)
    );

    ////////////////
    // Host regs
    ////////////////

    reg [7:0]               r_tick_div, tick_count;

    always@(posedge clk_dsi_i) begin
        if (!rst_n_dsi)
            tick_count <= 0;
        else begin
            if(tick_count == r_tick_div) begin
                tick <= 1;
                tick_count <= 0;
            end
            else begin
                tick <= 0;
                tick_count <= tick_count + 1;
            end
        end // else: !if(!rst_n_i)
    end // always@ (posedge clk_sys_i)

    reg [7:0] host_d_self;

    always@(posedge clk_dsi_i)
        /*if(!rst_n_dsi)
        begin
            r_tick_div <= 0;
            r_dsi_clk_en <= 0;
            lp_request <= 0;
            host_d_self <= 0;
            dsi_reset_n_o <= 0;
            r_lane_invert <= 0;
            r_clock_invert <= 0;
        end 
        else */if(host_wr) begin
            case(host_a)
            `REG_DSI_CTL: begin
                r_dsi_clk_en  <= host_d_in[0];
                lp_request <= host_d_in[1];
                r_clock_invert <= host_d_in[2];
                r_lane_invert <= host_d_in[3];
                r_tim_en <= host_d_in[4];
                r_force_lp <= host_d_in[5];
                dsi_reset_n_o <= host_d_in[6];
            end
            
            `REG_TICK_DIV: r_tick_div <= host_d_in;
            
            `REG_LP_TX: 
                if(lp_ready) begin
                    lp_valid <= 1'b1;
                    lp_data <= host_d_in[7:0];
                end        
            
            endcase // case (host_a_i)
        end else begin
            lp_valid <= 0;
          
            case(host_a)
            `REG_DSI_CTL: begin
                host_d_self[7] <= 0;
                host_d_self[6] <= dsi_reset_n_o;
                host_d_self[5] <= r_force_lp;
                host_d_self[4] <= r_tim_en;
                host_d_self[3] <= r_lane_invert;
                host_d_self[2] <= r_clock_invert;
                host_d_self[1] <= lp_ready;
                host_d_self[0] <= r_dsi_clk_en;
            end

            `REG_TICK_DIV: begin
                host_d_self <= r_tick_div;
            end

            `REG_LP_TX: begin
                host_d_self <= 8'hef;
            end
            
            default:
                host_d_self <= 0;
            endcase // case (host_a)
        end // else: !if(host_wr_i)

    assign host_d_out = host_d_self;
   
endmodule // dsi_core



