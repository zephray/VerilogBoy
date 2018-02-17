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
    //output int_req,
    input int_ack,
    output cpl, // Pixel Clock, = ~clk
    output [1:0] pixel, // Pixel Output
    output reg valid, // Pixel Valid
    output reg hs, // Horizontal Sync, High Valid
    output reg vs // Vertical Sync, High Valid
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
    
    localparam PPU_MODE_H_BLANK    = 2'b00;
    localparam PPU_MODE_V_BLANK    = 2'b01;
    localparam PPU_MODE_OAM_SEARCH = 2'b10;
    localparam PPU_MODE_PIX_TRANS  = 2'b11;
    
    localparam PPU_PAL_BG  = 2'b00;
    localparam PPU_PAL_OB0 = 2'b01;
    localparam PPU_PAL_OB1 = 2'b10;
    
    reg [12:0] vram_addr_int;
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
    
    wire [12:0] window_map_addr = (reg_win_disp_sel) ? (13'h1C00) : (13'h1800);
    wire [12:0] bg_map_addr = (reg_bg_disp_sel) ? (13'h1C00) : (13'h1800);
    wire [12:0] bg_window_tile_addr = (reg_bg_win_data_sel) ? (13'h0000) : (13'h0800);
    
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
    assign vram_data_in = d_wr;
    assign vram_we = (addr_in_vram)&(wr);
    
    // Pixel Pipeline
    
    
    
    // The pixel FIFO: 16 pixels, 4 bits each (2 bits color index, 2 bits palette index)
    // Since in and out are 8 pixels aligned, it can be modeled as a ping-pong buffer
    // of two 32 bits (8 pixels * 4 bits) group
    reg [63:0] pf_data; // Pixel FIFO Data
    wire [1:0] pf_output_pixel;
    wire [7:0] pf_output_palette;
    wire [1:0] pf_output_pixel_id;
    wire [1:0] pf_output_palette_id;
    assign {pf_output_pixel_id, pf_output_palette_id} = pf_data[63:60];
    assign pf_output_palette = (pf_output_palette_id == PPU_PAL_BG)  ? (reg_bgp)  :
                               (pf_output_palette_id == PPU_PAL_OB0) ? (reg_obp0) :
                               (pf_output_palette_id == PPU_PAL_OB1) ? (reg_obp1) : (8'hFF);
    assign pf_output_pixel = (pf_output_pixel_id == 2'b11) ? (pf_output_palette[7:6]) :
                             (pf_output_pixel_id == 2'b10) ? (pf_output_palette[5:4]) :
                             (pf_output_pixel_id == 2'b01) ? (pf_output_palette[3:2]) :
                             (pf_output_pixel_id == 2'b00) ? (pf_output_palette[1:0]) : (8'h00);
    
    assign cpl = ~clk;
    assign pixel = pf_output_pixel;
    
    // HV Timing
    localparam PPU_H_FRONT  = 9'd76;
    localparam PPU_H_SYNC   = 9'd4;    // So front porch + sync = OAM search
    localparam PPU_H_TOTAL  = 9'd456;
    localparam PPU_H_PIXEL  = 8'd160;
    localparam PPU_V_ACTIVE = 8'd144;
    localparam PPU_V_FRONT  = 8'd6;
    localparam PPU_V_SYNC   = 8'd4;  
    localparam PPU_V_BLANK  = 8'd10;
    localparam PPU_V_TOTAL  = 8'd154;
   
    reg [8:0] h_count;
    reg [7:0] v_count;
    
    // H counter
    always @(posedge clk)
    begin
        if (rst) begin
            h_count <= 0;
            hs <= 0;
        end
        else begin
            if(h_count < PPU_H_TOTAL)
                h_count <= h_count + 1'b1;
            else
                h_count <= 0;
            if(h_count == PPU_H_FRONT - 1)
                hs <= 1;
            if(h_count == PPU_H_FRONT + PPU_H_SYNC - 1)
                hs <= 0;
        end 
    end
    
    // V counter
    wire hclk = (h_count == 9'b0);
    always@(posedge hclk)
    begin
        if(rst) begin
            v_count <= 0;
            vs <= 0;
        end
        else begin
            if(v_count < PPU_V_TOTAL)
                v_count <= v_count + 1'b1;
            else
                v_count <= 0;
            if(v_count == PPU_V_FRONT - 1)
                vs <= 1;
            if(v_count == PPU_V_FRONT + PPU_V_SYNC - 1)
                vs <= 0;
        end
    end
    
    // Render FSM
    localparam S_IDLE     = 4'd0; 
    localparam S_BLANK    = 4'd1;  // H Blank and V Blank
    localparam S_OAMX     = 4'd2;  // OAM Search X check
    localparam S_OAMY     = 4'd3;  // OAM Search Y check
    localparam S_FTIDA    = 4'd4;  // Fetch Read Tile ID Stage A (Address Setup)
    localparam S_FTIDB    = 4'd5;  // Fetch Read Tile ID Stage B (Data Read)
    localparam S_FRD0A    = 4'd6;  // Fetch Read Data 0 Stage A
    localparam S_FRD0B    = 4'd7;  // Fetch Read Data 0 Stage B
    localparam S_FRD1A    = 4'd8;  // Fetch Read Data 1 Stage A
    localparam S_FRD1B    = 4'd9;  // Fetch Read Data 1 Stage B
    localparam S_FWAITA   = 4'd10; // Fetch Wait Stage A (Idle)
    localparam S_FWAITB   = 4'd11; // Fetch Wait Stage B (Load to FIFO?)
    localparam S_SWW      = 4'd12; // Fetch Switch to Window
    
    localparam PPU_OAM_SEARCH_LENGTH = 6'd40;

    reg [7:0] h_pix = 0;
    wire [7:0] v_pix = v_count - PPU_V_BLANK;
    wire [7:0] v_pix_in_map = v_pix + reg_scy;
    reg [3:0] r_state = 0;
    reg [3:0] r_next_state;
    wire is_in_v_blank = ((v_count >= 0) && (v_count < PPU_V_BLANK));
    
    wire render_window_or_bg = ((h_pix - reg_scx) >= reg_wx) ? 1 : 0;
    wire [12:0] current_map_address = ((render_window_or_bg) ? (window_map_addr) : (bg_map_addr)) + (v_pix + reg_scy) * 32 + h_pix;
    reg [7:0] current_tile_id;
    wire [2:0] line_to_tile_v_offset = v_pix_in_map[2:0];
    wire [12:0] current_tile_address_0 = (bg_window_tile_addr) + current_tile_id * 16 + line_to_tile_v_offset * 2;
    wire [12:0] current_tile_address_1 = (current_tile_address_0) | 13'h0001;
    reg [7:0] current_tile_data_0;
    reg [7:0] current_tile_data_1;
    // Data that will be pushed into pixel FIFO
    // Organized in pixels
    wire [31:0] current_fetch_result = { 
        current_tile_data_0[7], current_tile_data_1[7], PPU_PAL_BG,
        current_tile_data_0[6], current_tile_data_1[6], PPU_PAL_BG,
        current_tile_data_0[5], current_tile_data_1[5], PPU_PAL_BG,
        current_tile_data_0[4], current_tile_data_1[4], PPU_PAL_BG,
        current_tile_data_0[3], current_tile_data_1[3], PPU_PAL_BG,
        current_tile_data_0[2], current_tile_data_1[2], PPU_PAL_BG,
        current_tile_data_0[1], current_tile_data_1[1], PPU_PAL_BG,
        current_tile_data_0[0], current_tile_data_1[0], PPU_PAL_BG
        };

    reg [5:0] oam_search_count;

    // Modify all state related synchonize registers
    always @(negedge clk)
    begin
        // OAM counter
        if (r_state == S_OAMY) begin
            oam_search_count <= oam_search_count + 1'b1;
        end
        else
        if (r_state == S_BLANK) begin
            oam_search_count <= 6'b0;
        end
        
        // FSM Logic
        case (r_state)
            S_IDLE: 
            begin
                reg_stat[1:0] <= PPU_MODE_V_BLANK;
                //?
            end
            S_BLANK: 
            begin
                if (is_in_v_blank)
                    reg_stat[1:0] <= PPU_MODE_V_BLANK;
                else
                    reg_stat[1:0] <= PPU_MODE_H_BLANK;
                h_pix <= 8'b0;
            end
            S_OAMX: 
            begin
                reg_stat[1:0] <= PPU_MODE_OAM_SEARCH;
                //
            end
            S_OAMY: 
            begin
                reg_stat[1:0] <= PPU_MODE_OAM_SEARCH;
                //
            end
            S_FTIDA: 
            begin
                reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
                vram_addr_int <= current_map_address;
                h_pix <= h_pix + 1'b1;
                pf_data <= {pf_data[59:0], 4'b0000};
            end
            S_FTIDB: 
            begin
                reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
                current_tile_id <= vram_data_out;
                h_pix <= h_pix + 1'b1;
                pf_data <= {pf_data[59:0], 4'b0000};
            end
            S_FRD0A: 
            begin
                reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
                vram_addr_int <= current_tile_address_0;
                h_pix <= h_pix + 1'b1;
                pf_data <= {pf_data[59:0], 4'b0000};
            end
            S_FRD0B: 
            begin
                reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
                current_tile_data_0 <= vram_data_out;
                h_pix <= h_pix + 1'b1;
                pf_data <= {pf_data[59:0], 4'b0000};
            end
            S_FRD1A: 
            begin
                reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
                vram_addr_int <= current_tile_address_1;
                h_pix <= h_pix + 1'b1;
                pf_data <= {pf_data[59:0], 4'b0000};
            end
            S_FRD1B: 
            begin
                reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
                current_tile_data_1 <= vram_data_out;
                h_pix <= h_pix + 1'b1;
                pf_data <= {pf_data[59:0], 4'b0000};
            end
            S_FWAITA: 
            begin
                reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
                h_pix <= h_pix + 1'b1;
                pf_data <= {pf_data[59:0], 4'b0000};
            end
            S_FWAITB: 
            begin
                reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
                h_pix <= h_pix + 1'b1;
                pf_data <= {pf_data[59:28], current_fetch_result};
            end
        endcase
    end
    
    // Enter Next State
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
    
    // Next State Logic
    always @(*)
    begin
        case (r_state)
            S_IDLE: r_next_state = ((reg_lcd_en)&(is_in_v_blank)) ? (S_BLANK) : (S_IDLE);
            S_BLANK: r_next_state = (is_in_v_blank) ? 
                ((v_count == (PPU_V_TOTAL - 1)) ? (S_OAMX) : (S_BLANK)) :
                ((h_count == (PPU_H_TOTAL - 1)) ? ((v_count == (PPU_V_TOTAL - 1)) ? (S_BLANK) : (S_OAMX)) : (S_BLANK));
            S_OAMX: r_next_state = S_OAMY;
            S_OAMY: r_next_state = (oam_search_count == (PPU_OAM_SEARCH_LENGTH - 1)) ? (S_FTIDA) : (S_OAMX);
            S_FTIDA: r_next_state = S_FTIDB;
            S_FTIDB: r_next_state = S_FRD0A;
            S_FRD0A: r_next_state = S_FRD0B;
            S_FRD0B: r_next_state = S_FRD1A;
            S_FRD1A: r_next_state = S_FRD1B;
            S_FRD1B: r_next_state = S_FWAITA;
            S_FWAITA: r_next_state = S_FWAITB;
            S_FWAITB: r_next_state = (h_pix == (PPU_H_PIXEL - 1)) ? (S_BLANK) : S_FTIDB;
            default: r_next_state = S_IDLE;
        endcase
    end
    
    // Interrupt
    //assign int_req = 0;
    
    // Bus RW
    always @(posedge clk)
    begin
        if (rst) begin
            reg_lcdc <= 8'h00;
            reg_stat[7:2] <= 6'h00;
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
                        16'hFF41: reg_stat[7:2] <= d_wr[7:2];
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
