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
    input clk_mem,
    input rst,
    input [15:0] a,
    output reg [7:0] d_rd,
    input [7:0] d_wr,
    input rd,
    input wr,
    output int_req,
    input int_ack,
    output cpl, // Pixel Clock, = ~clk
    output reg [1:0] pixel, // Pixel Output
    output reg valid, // Pixel Vaild
    output hs, // Horizontal Sync, High Vaild
    output vs // Vertical Sync, High Vaild
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
    
    wire reg_lcd_en = reg_lcdc[7];          //0=Off, 1=On
    wire reg_win_disp_sel = reg_lcdc[6];    //0=9800-9BFF, 1=9C00-9FFF
    wire reg_win_en = reg_lcdc[5];          //0=Off, 1=On
    wire reg_bg_win_data_sel = reg_lcdc[4]; //0=8800-97FF, 1=8000-8FFF
    wire reg_bg_disp_sel = reg_lcdc[3];     //0=9800-9BFF, 1=9C00-9FFF
    wire reg_obj_size = reg_lcdc[2];        //0=8x8, 1=8x16
    wire reg_obj_en = reg_lcdc[1];          //0=Off, 1=On
    wire reg_bg_disp = reg_lcdc[0];         //0=Off, 1=On
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
    
    `define PPU_PAL_BG  2'b00
    `define PPU_PAL_OB0 2'b01
    `define PPU_PAL_OB1 2'b10
    
    wire [12:0] vram_addr_int;
    wire [12:0] vram_addr_ext;
    
    wire addr_in_ppu    = (a >= 16'hFF40 && a <= 16'hFF4B);
    wire addr_in_vram   = (a >= 16'h8000 && a <= 16'h9FFF);
    wire addr_in_oamram = (a >= 16'hFE00 && a <= 16'hFE9F);
    
    wire vram_access_ext = ((reg_mode_flag == PPU_MODE_H_BLANK)||
                            (reg_mode_flag == PPU_MODE_V_BLANK)||
                            (reg_mode_flag == PPU_MODE_OAM_SEARCH));
    wire vram_access_int = ~vram_access_ext;
    wire oamram_access_ext = ((reg_mode_flag == PPU_MODE_H_BLANK)||
                              (reg_mode_flag == PPU_MODE_V_BLANK));
    wire oamram_access_int = ~oamram_access_int;
    
    // PPU Memories
    wire        vram_we;
    wire [12:0] vram_addr;
    wire [7:0]  vram_data_in;
    wire [7:0]  vram_data_out;
    
    reg [7:0] oamram [0: 159];
    
    blockram8192 br_vram(
        .clka(clk_mem),
        .wea(vram_we),
        .addra(vram_addr),
        .dina(vram_data_in),
        .douta(vram_data_out));
        
    assign vram_addr_ext = a[12:0];
    assign vram_addr = (vram_access_ext) ? (vram_addr_ext) : (vram_addr_int);
    
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
    reg pf_full = 0; 
    assign pf_group = (pf_group_select) ? {pf_group2, pf_group1} : {pf_group1, pf_group2};
    assign pf_group_first = pf_group[63:32];
    assign pf_group_last = pf_group[31:0];
    // If LastGrp if full, means that we have at least 8 pixels in the pipeline,
    //   shift out is enabled.
    // When all pixels in FirstGrp is shifted out, swap and mark full to 0, means
    //   it can no longer shift out data.
    wire [1:0] pf_output_pixel;
    wire [7:0] pf_output_palette;
    wire [1:0] pf_output_pixel_id;
    wire [1:0] pf_output_palette_id;
    assign {pf_output_pixel_id, pf_output_palette_id} = pf_group_first[31:28];
    assign pf_output_palette = (pf_palette_id == `PPU_PAL_BG)  ? (reg_bgp)  :
                               (pf_palette_id == `PPU_PAL_OB0) ? (reg_obp0) :
                               (pf_palette_id == `PPU_PAL_OB1) ? (reg_obp1) : (8'hFF);
    assign pf_output_pixel = (pf_output_pixel_id == 2'b11) ? (pf_output_palette[7:6]) :
                             (pf_output_pixel_id == 2'b10) ? (pf_output_palette[5:4]) :
                             (pf_output_pixel_id == 2'b01) ? (pf_output_palette[3:2]) :
                             (pf_output_pixel_id == 2'b00) ? (pf_output_palette[1:0]) : (8'h00);
    
    assign cpl = ~clk;
    assign pixel = pf_output_pixel;
    assign valid = pf_full;
    
    // Pixel Shift
    always @(posedge clk)
    begin
        if (pf_full)
        begin
            pf_group <= {pf_group[59:0], 4'b0000};
        end
    end
    
    // HV Timing
    `define PPU_H_FRONT  9'd76
    `define PPU_H_SYNC   9'd4    // So front porch + sync = OAM search
    `define PPU_H_TOTAL  9'd456
    `define PPU_V_ACTIVE 8'd144
    `define PPU_V_BACK   8'd6
    `define PPU_V_SYNC   8'd4    // Make sync back instead of front so v_count is line count
    `define PPU_V_TOTAL  8'd154
    reg [8:0] h_count;
    reg [7:0] v_count;
    
    // H counter
    always @(posedge clk)
    begin
        if (rst) begin
            h_count <= 0;
            hs <= 0;
        end
        else
        begin
            if(h_count < H_TOTAL)
                h_count <= h_count + 1'b1;
            else
                h_count <= 0;
            if(h_count == H_FRONT - 1)
                hs <= 1;
            if(h_count == H_FRONT + H_SYNC - 1)
                hs <= 0;
        end 
    end
    
    // V counter
    wire hclk = (h_count == 9'b0);
    always@(posedge hclk)
    begin
        if(rst)
        begin
            v_count <= 0;
            vs <= 0;
        end
        else
        begin
            if(v_count < V_TOTAL)
                v_count <= v_count + 1'b1;
            else
                v_count <= 0;
            if(v_count == V_ACTIVE + V_BACK - 1)
                vs <= 1;
            if(v_count == V_ACTIVE + V_BACK + V_SYNC - 1)
                vs <= 0;
        end
    end
    
    // Render FSM
    `define S_VBLANK    4'd0
    `define S_HBLANK    4'd1
    `define S_OAMX      4'd2  // OAM Search X check
    `define S_OAMY      4'd3  // OAM Search Y check
    `define S_FTIDA     4'd4  // Fetch Read Tile ID Stage A (Address Setup)
    `define S_FTIDB     4'd5  // Fetch Read Tile ID Stage B (Data Read)
    `define S_FRD0A     4'd6  // Fetch Read Data 0 Stage A
    `define S_FRD0B     4'd7  // Fetch Read Data 0 Stage B
    `define S_FRD1A     4'd8  // Fetch Read Data 1 Stage A
    `define S_FRD1B     4'd9  // Fetch Read Data 1 Stage B
    `define S_FWAITA    4'd10 // Fetch Wait Stage A (Idle)
    `define S_FWAITB    4'd11 // Fetch Wait Stage B (Load to FIFO?)
    
    reg [7:0] h_pix = 0;
    reg [3:0] r_state = 0;
    reg [3:0] r_next_state;
    
    always @(posedge clk)
    begin
        if (rst) begin
            r_state <= 0;
        end
        else
        begin
            r_state <= r_next_state;
        end
    end
    
    always @(*)
    begin
        // next state logic
    end
    
    always @(posedge clk)
    begin
        if (!rst) begin
            case (r_state)
                `S_VBLANK: 
                begin
                
                end
                `S_HBLANK: 
                begin
                
                end
                `S_OAMX: 
                begin
                
                end
                `S_OAMY: 
                begin
                
                end
                `S_FTIDA: 
                begin
                
                end
                `S_FTIDB: 
                begin
                
                end
                `S_FRD0A: 
                begin
                
                end
                `S_FRD0B: 
                begin
                
                end
                `S_FRD1A: 
                begin
                
                end
                `S_FRD1B: 
                begin
                
                end
                `S_FWAITA: 
                begin
                
                end
                `S_FWAITB: 
                begin
                
                end
            endcase
        end
    end
    
    // Bus RW
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
                    if (vram_access_ext)
                    begin
                        d_rd <= vram_data_out;
                    end
                    else
                    begin
                        d_rd <= 8'hFF;
                    end
                end
                else
                if (addr_in_oamram) begin
                    if (oamram_access_ext)
                    begin
                        // Access Good
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
                // VRAM access should be completed automatically 
                if (addr_in_oamram) begin
                    if (oamram_access_ext)
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
