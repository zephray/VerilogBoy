`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:47:02 04/01/2019 
// Design Name: 
// Module Name:    rv_vbc_ddr_arbiter 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module rv_vbc_ddr_arbitrator(
    input wire rst,
    input wire clkrv,
    input wire clkgb,
    input wire [23:0] rv_addr,
    input wire [31:0] rv_wdata,
    output wire [31:0] rv_rdata,
    input wire [3:0] rv_wstrb,
    input wire rv_valid,
    output wire rv_ready,
    output wire [23:0] ddr_addr,
    output wire [31:0] ddr_wdata,
    input wire [31:0] ddr_rdata,
    output wire [3:0] ddr_wstrb,
    output wire ddr_valid,
    input wire ddr_ready,
    input wire [22:0] vb_a, // 8 MiB maximum
    output reg [7:0] vb_din,
    input wire [7:0] vb_dout,
    input wire vb_rd,
    input wire vb_wr
    );

    `define VB_INPUT_SYNC

    //reg [8:0] vb_din_buffer;
    `ifdef VB_INPUT_SYNC
    reg vb_rd_sync;
    reg vb_wr_sync;

    reg vb_rd_sync_pre;
    reg vb_wr_sync_pre;
    always @(posedge clkrv) begin
        vb_rd_sync_pre <= vb_rd;
        vb_wr_sync_pre <= vb_wr;
        vb_rd_sync <= vb_rd_sync_pre;
        vb_wr_sync <= vb_wr_sync_pre;
    end
    `else
    wire vb_rd_sync = vb_rd;
    wire vb_wr_sync = vb_wr;
    `endif
    
    reg [3:0] vb_master_wstrb;
    reg [23:0] vb_master_addr;
    reg [7:0] vb_master_wdata_byte;
    wire [31:0] vb_master_rdata;
    reg vb_master_valid;
    wire vb_master_ready;
    
    reg bus_master; // 1'b0: RV; 1'b1: VB
    
    // These are "wires"
    reg [7:0] vb_master_rdata_byte;
    reg [31:0] vb_master_wdata;
    reg [3:0] vb_master_wstrb_pre;
    always @(*) begin
         case (vb_a[1:0]) 
         2'b00: begin
            vb_master_rdata_byte = vb_master_rdata[7:0];
            vb_master_wdata = {24'b0, vb_master_wdata_byte};
            vb_master_wstrb_pre = 4'b0001;
         end
         2'b01: begin
            vb_master_rdata_byte = vb_master_rdata[15:8];
            vb_master_wdata = {16'b0, vb_master_wdata_byte, 8'b0};
            vb_master_wstrb_pre = 4'b0010;
         end
         2'b10: begin
            vb_master_rdata_byte = vb_master_rdata[23:16];
            vb_master_wdata = {8'b0, vb_master_wdata_byte, 16'b0};
            vb_master_wstrb_pre = 4'b0100;
         end
         2'b11: begin
            vb_master_rdata_byte = vb_master_rdata[31:24];
            vb_master_wdata = {vb_master_wdata_byte, 24'b0};
            vb_master_wstrb_pre = 4'b1000;
         end
         endcase
    end
    
    reg [2:0] state;
    
    localparam STATE_IDLE = 3'd0;
    localparam STATE_VB_RD_REQ_START = 3'd1;
    localparam STATE_VB_WR_REQ_START = 3'd2;
    localparam STATE_VB_RD_WAIT_REQ = 3'd3;
    localparam STATE_VB_WR_WAIT_REQ = 3'd4;
    localparam STATE_VB_FINISH_REQ = 3'd5;
    
    always @(posedge clkrv, posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            vb_master_valid <= 1'b0;
            bus_master <= 1'b0;
        end
        else begin
            case (state)
            STATE_IDLE: begin
                vb_master_valid <= 1'b0;
                if (vb_rd_sync && !rv_valid && !rv_ready) begin
                    state <= STATE_VB_RD_REQ_START;
                    bus_master <= 1'b1;
                end
                else if (vb_wr_sync && !rv_valid && !rv_ready) begin
                    state <= STATE_VB_WR_REQ_START;
                    bus_master <= 1'b1;
                end
                else begin
                    bus_master <= 1'b0;
                end
            end
            STATE_VB_RD_REQ_START: begin
                vb_master_addr <= {1'b1, vb_a[22:2], 2'd0}; // VerilogBoy occupies 8MB-16MB
                vb_master_wstrb <= 4'b0;
                vb_master_valid <= 1'b1;
                state <= STATE_VB_RD_WAIT_REQ;
            end
            STATE_VB_RD_WAIT_REQ: begin
                if (vb_master_ready) begin
                    vb_master_valid <= 1'b0;
                    vb_din <= vb_master_rdata_byte;
                    state <= STATE_VB_FINISH_REQ;
                end
            end
            STATE_VB_WR_REQ_START: begin
                vb_master_addr <= {1'b1, vb_a[22:2], 2'd0};
                vb_master_wstrb <= vb_master_wstrb_pre;
                vb_master_wdata_byte <= vb_dout; 
                vb_master_valid <= 1'b1;
                state <= STATE_VB_WR_WAIT_REQ;
            end
            STATE_VB_WR_WAIT_REQ: begin
                if (vb_master_ready) begin
                    vb_master_valid <= 1'b0;
                    state <= STATE_VB_FINISH_REQ;
                end
            end
            STATE_VB_FINISH_REQ: begin
                if (!ddr_ready)
                    bus_master <= 1'b0;
                if (!vb_rd_sync && !vb_wr_sync)
                    state <= STATE_IDLE;
            end
            endcase
        end
    end
    
    assign ddr_addr = (bus_master) ? (vb_master_addr) : (rv_addr);
    assign ddr_wdata = (bus_master) ? (vb_master_wdata) : (rv_wdata);
    assign ddr_wstrb = (bus_master) ? (vb_master_wstrb) : (rv_wstrb);
    assign ddr_valid = (bus_master) ? (vb_master_valid) : (rv_valid);
    assign rv_rdata = (bus_master) ? (32'bx) : (ddr_rdata);
    assign rv_ready = (bus_master) ? (1'b0) : (ddr_ready);
    assign vb_master_rdata = (bus_master) ? (ddr_rdata) : (32'bx);
    assign vb_master_ready = (bus_master) ? (ddr_ready) : (1'b0);

endmodule
