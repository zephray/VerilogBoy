`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:48:36 02/14/2018 
// Design Name: 
// Module Name:    ppu 
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
module ppu(
    input clk,
    input rst,
    input [15:0] a,
    output reg [7:0] d_rd,
    input [7:0] d_wr,
    input rd,
    input wr,
    output int_req,
    input int_ack,
    output cpl,
    output [1:0] pixel,
    output hs,
    output vs
    );
    
    // Global Wires ?
    
    // PPU registers
    reg [7:0] reg_lcdc; //$FF40 LCD Control (R/W)
    reg [7:0] reg_stat; //$FF41 LCDC Status (R/W)
    reg [7:0] reg_scy;  //$FF42 Scroll Y (R/W)
    reg [7:0] reg_scx;  //$FF43 Scroll X (R/W)
    reg [7:0] reg_ly;   //$FF44 LCDC Y-Coordinate (R) Write will reset the counter
    reg [7:0] reg_dma;  //$FF46 DMA, actually handled outside of PPU for now
    reg [7:0] reg_lyc;  //$FF45 LY Compare (R/W)
    reg [7:0] reg_bgp;  //$FF47 BG Palette Data (R/W) Non-CGB mode only
    reg [7:0] reg_obp0; //$FF48 Object Palette 0 Data (R/W) Non-CGB mode only
    reg [7:0] reg_obp1; //$FF49 Object Palette 1 Data (R/W) Non-CGB mode only
    reg [7:0] reg_wy;   //$FF4A Window Y Position (R/W)
    reg [7:0] reg_wx;   //$FF4B Window X Position (R/W)
    
    wire reg_lcd_en = reg_lcdc[7];
    wire reg_win_disp_sel = reg_lcdc[6];
    wire reg_win_en = reg_lcdc[5];
    wire reg_bg_win_data_sel = reg_lcdc[4];
    wire reg_bg_disp_sel = reg_lcdc[3];
    wire reg_obj_size = reg_lcdc[2];
    wire reg_obj_en = reg_lcdc[1];
    wire reg_bg_disp = reg_lcdc[0];
    wire reg_lyc_int = reg_stat[6];
    wire reg_oam_int = reg_stat[5];
    wire reg_vblank_int = reg_stat[4];
    wire reg_hblank_int = reg_stat[3];
    wire reg_coin_flag = reg_stat[2];
    wire [1:0] reg_mode_flag = reg_stat[1:0];
    
    `define PPU_MODE_H_BLANK 2'b00
    `define PPU_MODE_V_BLANK 2'b01
    `define PPU_MODE_OAM_SEARCH 2'b10
    `define PPU_MODE_PIX_TRANS 2'b11
    
    wire addr_in_ppu    = (a >= 16'hFF40 && a <= 16'hFF4B);
    wire addr_in_vram   = (a >= 16'h8000 && a <= 16'h9FFF);
    wire addr_in_oamram = (a >= 16'hFE00 && a <= 16'hFE9F);
    
    
    // Pixel Pipeline
    
    // The pixel FIFO: 16 pixels, 4 bits each (2 bits color index, 2 bits palette index)
    // Since in and out are 8 pixels aligned, it can be modeled as a ping-pong buffer
    // of two 32 bits (8 pixels * 4 bits) group
    reg [31:0] pf_group1; // pf = Pixel FIFO
    reg [31:0] pf_group2;
    reg pf_group_select; // 0: {pf_group2 : pf_group1} 1: (pf_group2, pf_group1)
    wire [63:0] pf_group;
    wire [31:0] pf_group_first;
    wire [31:0] pf_group_last;
    reg pf_empty = 1; 
    // If LastGrp if full, means that we have at least 8 pixels in the pipeline,
    //   shift out is enabled.
    // When all pixels in FirstGrp is shifted out, swap and mark full to 0, means
    //   it can no longer shift out data.
    
    assign pf_group = (pf_group_select) ? {pf_group2, pf_group1} : {pf_group1, pf_group2};
    assign pf_group_first = pf_group[63:32];
    assign pf_group_last = pf_group[31:0];
    
    always @(posedge clk)
    begin
        if (rst) begin
            reg_lcdc <= 8'h00;
            reg_stat <= 8'h00;
            reg_scy  <= 8'h00;
            reg_scx  <= 8'h00;
            reg_ly   <= 8'h00;
            reg_lyc  <= 8'h00;
            reg_dma  <= 8'h00;
            reg_bgp  <= 8'hFC;
            reg_obp0 <= 8'h00;
            reg_obp1 <= 8'h00;
            reg_wy   <= 8'h00;
            reg_wx   <= 8'h00;
        end
        else
        begin
            if (rd) begin
                if (addr_in_ppu) begin
                    case (a)
                        16'hFF40: d_rd <= reg_lcdc;
                        16'hFF41: d_rd <= reg_stat;
                        16'hFF42: d_rd <= reg_scy;
                        16'hFF43: d_rd <= reg_scx;
                        16'hFF44: d_rd <= reg_ly;
                        16'hFF45: d_rd <= reg_lyc;
                        16'hFF46: d_rd <= reg_dma;
                        16'hFF47: d_rd <= reg_bgp;
                        16'hFF48: d_rd <= reg_obp0;
                        16'hFF49: d_rd <= reg_obp1;
                        16'hFF4A: d_rd <= reg_wy;
                        16'hFF4B: d_rd <= reg_wx;
                    endcase
                end
                else
                if (addr_in_vram) begin
                    if ((reg_mode == PPU_MODE_H_BLANK)||
                        (reg_mode == PPU_MODE_V_BLANK)||
                        (reg_mode == PPU_MODE_OAM_SEARCH))
                    begin
                        //Access good
                    end
                    else
                    begin
                        d_rd <= 8'hFF;
                    end
                end
                else
                if (addr_in_oamram) begin
                    if ((reg_mode == PPU_MODE_H_BLANK)||
                        (reg_mode == PPU_MODE_V_BLANK))
                    begin
                        //Access good
                    end
                    else
                    begin
                        d_rd <= 8'hFF;
                    end
                end
            end
            else
            if (wr) begin
                if (addr_in_ppu) begin
                    case (a)
                        16'hFF40: reg_lcdc <= d_wr;
                        16'hFF41: reg_stat <= d_wr;
                        16'hFF42: reg_scy <= d_wr;
                        16'hFF43: reg_scx <= d_wr;
                        16'hFF44: reg_ly <= d_wr;
                        16'hFF45: reg_lyc <= d_wr;
                        16'hFF46: reg_dma <= d_wr;
                        16'hFF47: reg_bgp <= d_wr;
                        16'hFF48: reg_obp0 <= d_wr;
                        16'hFF49: reg_obp1 <= d_wr;
                        16'hFF4A: reg_wy <= d_wr;
                        16'hFF4B: reg_wx <= d_wr;
                    endcase
                end
                else
                if (addr_in_vram) begin
                    if ((reg_mode == PPU_MODE_H_BLANK)||
                        (reg_mode == PPU_MODE_V_BLANK)||
                        (reg_mode == PPU_MODE_OAM_SEARCH))
                    begin
                        // Access good
                    end
                    else
                    begin
                        // Do nothing
                    end
                end
                else
                if (addr_in_oamram) begin
                    if ((reg_mode == PPU_MODE_H_BLANK)||
                        (reg_mode == PPU_MODE_V_BLANK))
                    begin
                        // Access good
                    end
                    else
                    begin
                        // Do nothing
                    end
                end
            end
        end
    end

endmodule
