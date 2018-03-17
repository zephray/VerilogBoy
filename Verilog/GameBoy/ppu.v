`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
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
`default_nettype wire
module ppu(
    input clk,
    input clk_mem,
    input rst,
    input [15:0] a,
    output reg [7:0] dout,
    input [7:0] din,
    input rd,
    input wr,
    output reg int_vblank_req,
    output reg int_lcdc_req,
    input int_vblank_ack,
    input int_lcdc_ack,
    output cpl, // Pixel Clock, = ~clk
    output reg [1:0] pixel, // Pixel Output
    output reg valid, // Pixel Valid
    output reg hs, // Horizontal Sync, High Valid
    output reg vs, // Vertical Sync, High Valid
    //Debug output
    output [7:0] scx,
    output [7:0] scy,
    output [4:0] state
    );
    
    // There are three hardware layers in the GameBoy PPU: Background, Window, and Object (or sprites).
    // Window will render above the background and the object can render above the background or under the background.
    // Each object have a priority bit to identify where it should be rendered.
    // Background, Window, and Object can be individually turned on or off.
    // When nothing is turned on, it displays white.
    
    // The whole render logic does NOT require a scanline buffer to work, and it runs at 4MHz (VRAM runs at 2MHz)
    // There are two main parts of the logic, implemented in a big FSM. The first one is the fetch unit, and the other
    // is the pixel FIFO.
    // The pixel FIFO shifts out one pixel when it contains more than 8 pixels, the fetch unit would generally render
    // 8 pixels in 6 cycles (so 2 wait cycles are inserted so they are in sync generally). When there is no enough pixels,
    // The FIFO would stop and wait for the fetch unit.
    
    // Windows Trigger is handled in the next state logic, their is a distinct state for the PPU to switch from
    // background rendering to window rendering (flush the fifo and add wait cycles.)
    
    // Object Trigger is handled in the state change block, in order to backup the previous state
    // Current RAM address is also backed up during the handling of object rendering
    // So, once all the objects at this position has been rendered, the state machine could be restored
    
    // The output pixel clock is the inverted main clock, which is the same as the real Game Boy
    // Pixel data would be put on the pixel bus on the negedge of clock, so the LCD would latch the data on the posedge
    // The original Game Boy used a gated clock to control if output is valid. Since gated clock is not recommend,
    // I used a valid signal to indicate is output should be considered valid.
    
    // Global Wires ?
    integer i;
    
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
    
    // Some next state register, gets updated into reg during posedge
    reg [7:0] reg_ly_next;
    reg [1:0] reg_mode_next; // Next mode based on next state
    
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
    
    wire addr_in_ppu  = (a >= 16'hFF40 && a <= 16'hFF4B);
    wire addr_in_vram = (a >= 16'h8000 && a <= 16'h9FFF);
    wire addr_in_oam  = (a >= 16'hFE00 && a <= 16'hFE9F);
    
    wire vram_access_ext = ((reg_mode_next == PPU_MODE_H_BLANK)||
                            (reg_mode_next == PPU_MODE_V_BLANK)||
                            (reg_mode_next == PPU_MODE_OAM_SEARCH));
    wire vram_access_int = ~vram_access_ext;
    wire oam_access_ext = ((reg_mode_next == PPU_MODE_H_BLANK)||
                           (reg_mode_next == PPU_MODE_V_BLANK));
    wire oam_access_int = ~oam_access_int;
    
    wire [12:0] window_map_addr = (reg_win_disp_sel) ? (13'h1C00) : (13'h1800);
    wire [12:0] bg_map_addr = (reg_bg_disp_sel) ? (13'h1C00) : (13'h1800);
    wire [12:0] bg_window_tile_addr = (reg_bg_win_data_sel) ? (13'h0000) : (13'h0800);
    
    // PPU Memories
    
    // 8 bit WR, 16 bit RD, 160Bytes OAM
    reg [7:0] oam_u [0: 79];
    reg [7:0] oam_l [0: 79];
    reg [7:0] oam_rd_addr_int;
    wire [7:0] oam_rd_addr;
    wire [7:0] oam_wr_addr;
    reg [15:0] oam_data_out;
    wire [8:0] oam_data_in;
    wire oam_we;
    
    always @ (posedge clk)
    begin
        if (oam_we) begin
            if (oam_wr_addr[0])
                oam_u[oam_wr_addr[7:1]] <= oam_data_in;
            else
                oam_l[oam_wr_addr[7:1]] <= oam_data_in;
        end
        else begin
            oam_data_out <= {oam_u[oam_rd_addr[7:1]], oam_l[oam_rd_addr[7:1]]};
        end
    end
    
    assign oam_wr_addr = a[7:0];
    assign oam_rd_addr = (oam_access_ext) ? (a[7:0]) : (oam_rd_addr_int); 
    assign oam_data_in = din;
    assign oam_we = (addr_in_oam)&(wr)&(oam_access_ext);
    
    // 8 bit WR, 8 bit RD, 8KB VRAM
    wire        vram_we;
    wire [12:0] vram_addr;
    wire [7:0]  vram_data_in;
    wire [7:0]  vram_data_out;
    
    blockram8192 br_vram(
        .clka(clk_mem),
        .wea(vram_we),
        .addra(vram_addr),
        .dina(vram_data_in),
        .douta(vram_data_out));
        
    assign vram_addr_ext = a[12:0];
    assign vram_addr = (vram_access_ext) ? (vram_addr_ext) : (vram_addr_int);
    assign vram_data_in = din;
    assign vram_we = (addr_in_vram)&(wr)&(vram_access_ext);
    
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
    reg [4:0] pf_empty;
    
    assign cpl = clk;
    //assign pixel = pf_output_pixel;
    
    // HV Timing
    localparam PPU_H_FRONT  = 9'd76;
    localparam PPU_H_SYNC   = 9'd4;    // So front porch + sync = OAM search
    localparam PPU_H_TOTAL  = 9'd456;
    localparam PPU_H_PIXEL  = 8'd160;
    localparam PPU_H_FIFO   = 8'd176;  // 8 pixel empty for first fetch, 8 pixels in the front for objects which have x < 8
    localparam PPU_V_ACTIVE = 8'd144;
    localparam PPU_V_BACK   = 8'd9;
    localparam PPU_V_SYNC   = 8'd1;  
    localparam PPU_V_BLANK  = 8'd10;
    localparam PPU_V_TOTAL  = 8'd154;
   
    reg [8:0] h_count;
    reg [7:0] v_count;
    
    // HV counter
    always @(posedge clk)
    begin
        if (rst) begin
            h_count <= 0;
            hs <= 0;
            v_count <= 0;
            vs <= 0;
        end
        else begin
            if(h_count < PPU_H_TOTAL - 1)
                h_count <= h_count + 1'b1;
            else begin
                h_count <= 0;
                if(v_count < PPU_V_TOTAL - 1)
                    v_count <= v_count + 1'b1;
                else
                    v_count <= 0;
                if(v_count == PPU_V_ACTIVE + PPU_V_BACK - 1)
                    vs <= 1;
                if(v_count == PPU_V_ACTIVE + PPU_V_BACK + PPU_V_SYNC - 1)
                    vs <= 0;
            end
            if(h_count == PPU_H_FRONT - 1)
                hs <= 1;
            if(h_count == PPU_H_FRONT + PPU_H_SYNC - 1)
                hs <= 0;
        end 
    end
    
    // Render FSM
    localparam S_IDLE     = 5'd0; 
    localparam S_BLANK    = 5'd1;  // H Blank and V Blank
    localparam S_OAMX     = 5'd2;  // OAM Search X check
    localparam S_OAMY     = 5'd3;  // OAM Search Y check
    localparam S_FTIDA    = 5'd4;  // Fetch Read Tile ID Stage A (Address Setup)
    localparam S_FTIDB    = 5'd5;  // Fetch Read Tile ID Stage B (Data Read)
    localparam S_FRD0A    = 5'd6;  // Fetch Read Data 0 Stage A
    localparam S_FRD0B    = 5'd7;  // Fetch Read Data 0 Stage B
    localparam S_FRD1A    = 5'd8;  // Fetch Read Data 1 Stage A
    localparam S_FRD1B    = 5'd9;  // Fetch Read Data 1 Stage B
    localparam S_FWAITA   = 5'd10; // Fetch Wait Stage A (Idle)
    localparam S_FWAITB   = 5'd11; // Fetch Wait Stage B (Load to FIFO?)
    localparam S_SWW      = 5'd12; // Fetch Switch to Window
    localparam S_OFRD0A   = 5'd13; // Object Fetch Read Data 0 Stage A
    localparam S_OFRD0B   = 5'd14; // Object Fetch Read Data 0 Stage B
    localparam S_OFRD1A   = 5'd15; // Object Fetch Read Data 1 Stage A
    localparam S_OFRD1B   = 5'd16; // Object Fetch Read Data 1 Stage B
    localparam S_OWB      = 5'd17; // Object Write Back
    localparam S_OAMRDA   = 5'd18; // OAM Read Stage A
    localparam S_OAMRDB   = 5'd19; // OAM Read Stage B
    
    localparam PPU_OAM_SEARCH_LENGTH = 6'd40;

    reg [2:0] h_drop; //Drop pixels when SCX % 8 != 0
    wire [2:0] h_extra = reg_scx % 8; //Extra line length when SCX % 8 != 0
    reg [7:0] h_pix_render; // Horizontal Render Pixel pointer
    reg [7:0] h_pix_output; // Horizontal Output Pixel counter
    wire [7:0] h_pix_obj = h_pix_output + 8'd8; // Counter used to trigger the object rendering
    wire [7:0] v_pix = v_count;
    wire [7:0] v_pix_in_map = v_pix + reg_scy;
    wire [7:0] v_pix_in_win = v_pix - reg_wy;

    reg [4:0] r_state = 0;
    reg [4:0] r_next_backup;
    reg [4:0] r_next_state;
    wire is_in_v_blank = ((v_count >= PPU_V_ACTIVE) && (v_count < PPU_V_ACTIVE + PPU_V_BLANK));
    
    reg window_triggered; // Identify whether window has been triggered
    wire render_window_or_bg = window_triggered;
    wire window_trigger = (((h_pix_output + 8'd7) == (reg_wx))&&(v_pix >= reg_wy)&&(reg_win_en)&&(~window_triggered)) ? 1 : 0;
    
    wire [2:0] line_to_tile_v_offset_bg = v_pix_in_map[2:0]; // Current line in a tile being rendered
    wire [4:0] line_in_tile_v_bg = v_pix_in_map[7:3]; // Current tile Y coordinate being rendered
    wire [2:0] line_to_tile_v_offset_win = v_pix_in_win[2:0];
    wire [4:0] line_in_tile_v_win = v_pix_in_win[7:3];
    wire [2:0] line_to_tile_v_offset = (render_window_or_bg) ? (line_to_tile_v_offset_win) : (line_to_tile_v_offset_bg);
    wire [4:0] line_in_tile_v = (render_window_or_bg) ? (line_in_tile_v_win) : (line_in_tile_v_bg);
    
    wire [4:0] h_tile_bg = h_pix_render[7:3] + reg_scx[7:3]; // Current tile X coordinate being rendered
    wire [4:0] h_tile_win = h_pix_render[7:3];
    wire [4:0] h_tile = (render_window_or_bg) ? (h_tile_win) : (h_tile_bg);  
    
    wire [12:0] current_map_address = (((render_window_or_bg) ? (window_map_addr) : (bg_map_addr)) + (line_in_tile_v) * 32 + h_tile); //Background address
    reg [7:0] current_tile_id;
    wire [7:0] current_tile_id_adj = {~((reg_bg_win_data_sel)^(current_tile_id[7])), current_tile_id[6:0]}; // Adjust for 8800 Adressing mode
    wire [12:0] current_tile_address_0 = (bg_window_tile_addr) + current_tile_id_adj * 16 + (line_to_tile_v_offset * 2);
    wire [12:0] current_tile_address_1 = (current_tile_address_0) | 13'h0001;
    reg [7:0] current_tile_data_0;
    reg [7:0] current_tile_data_1;
    reg [12:0] current_address_backup;
   
    // Data that will be pushed into pixel FIFO
    // Organized in pixels
    wire [31:0] current_fetch_result = { 
        current_tile_data_1[7], current_tile_data_0[7], PPU_PAL_BG,
        current_tile_data_1[6], current_tile_data_0[6], PPU_PAL_BG,
        current_tile_data_1[5], current_tile_data_0[5], PPU_PAL_BG,
        current_tile_data_1[4], current_tile_data_0[4], PPU_PAL_BG,
        current_tile_data_1[3], current_tile_data_0[3], PPU_PAL_BG,
        current_tile_data_1[2], current_tile_data_0[2], PPU_PAL_BG,
        current_tile_data_1[1], current_tile_data_0[1], PPU_PAL_BG,
        current_tile_data_1[0], current_tile_data_0[0], PPU_PAL_BG
        };

    reg [5:0] oam_search_count;
    reg [5:0] obj_visible_list [0:9];
    reg [7:0] obj_trigger_list [0:9];
    reg [7:0] obj_y_list [0:9];
    reg obj_valid_list [0:9];
    reg [3:0] oam_visible_count;
    
    reg [7:0] oam_search_x;
    reg [7:0] oam_search_y;
    wire [7:0] obj_size_h = (reg_obj_size == 1'b1) ? (8'd16) : (8'd8);
    wire [7:0] obj_h_upper_boundary = (v_pix + 8'd16);
    wire [7:0] obj_h_lower_boundary = obj_h_upper_boundary - obj_size_h;

    reg [3:0] obj_trigger_id; // The object currently being/ or have been rendered, in the visible list
        
    localparam obj_trigger_not_found = 4'd15; 
    wire [3:0] obj_trigger_id_start_from_8 = ((h_pix_obj == obj_trigger_list[9])&&(obj_valid_list[9])) ? (4'd9) : (obj_trigger_not_found);
    wire [3:0] obj_trigger_id_start_from_7 = ((h_pix_obj == obj_trigger_list[8])&&(obj_valid_list[8])) ? (4'd8) : (obj_trigger_id_start_from_8);
    wire [3:0] obj_trigger_id_start_from_6 = ((h_pix_obj == obj_trigger_list[7])&&(obj_valid_list[7])) ? (4'd7) : (obj_trigger_id_start_from_7);
    wire [3:0] obj_trigger_id_start_from_5 = ((h_pix_obj == obj_trigger_list[6])&&(obj_valid_list[6])) ? (4'd6) : (obj_trigger_id_start_from_6);
    wire [3:0] obj_trigger_id_start_from_4 = ((h_pix_obj == obj_trigger_list[5])&&(obj_valid_list[5])) ? (4'd5) : (obj_trigger_id_start_from_5);
    wire [3:0] obj_trigger_id_start_from_3 = ((h_pix_obj == obj_trigger_list[4])&&(obj_valid_list[4])) ? (4'd4) : (obj_trigger_id_start_from_4);
    wire [3:0] obj_trigger_id_start_from_2 = ((h_pix_obj == obj_trigger_list[3])&&(obj_valid_list[3])) ? (4'd3) : (obj_trigger_id_start_from_3);
    wire [3:0] obj_trigger_id_start_from_1 = ((h_pix_obj == obj_trigger_list[2])&&(obj_valid_list[2])) ? (4'd2) : (obj_trigger_id_start_from_2);
    wire [3:0] obj_trigger_id_start_from_0 = ((h_pix_obj == obj_trigger_list[1])&&(obj_valid_list[1])) ? (4'd1) : (obj_trigger_id_start_from_1);
    wire [3:0] obj_trigger_id_all          = ((h_pix_obj == obj_trigger_list[0])&&(obj_valid_list[0])) ? (4'd0) : (obj_trigger_id_start_from_0);
    wire [3:0] obj_trigger_id_next =
        (obj_trigger_id == 4'd15) ? (obj_trigger_id_all) : (
        (obj_trigger_id == 4'd0) ? (obj_trigger_id_start_from_0) : (
        (obj_trigger_id == 4'd1) ? (obj_trigger_id_start_from_1) : (
        (obj_trigger_id == 4'd2) ? (obj_trigger_id_start_from_2) : (
        (obj_trigger_id == 4'd3) ? (obj_trigger_id_start_from_3) : (
        (obj_trigger_id == 4'd4) ? (obj_trigger_id_start_from_4) : (
        (obj_trigger_id == 4'd5) ? (obj_trigger_id_start_from_5) : (
        (obj_trigger_id == 4'd6) ? (obj_trigger_id_start_from_6) : (
        (obj_trigger_id == 4'd7) ? (obj_trigger_id_start_from_7) : (obj_trigger_id_start_from_8)))))))));
    wire obj_trigger = ((reg_obj_en)&&(obj_trigger_id_next != obj_trigger_not_found)) ? 1 : 0;
    
    wire [5:0] obj_triggered = obj_visible_list[obj_trigger_id]; // The global id of object being rendered
    wire [7:0] current_obj_y = obj_y_list[obj_trigger_id];
    wire [7:0] current_obj_x = obj_trigger_list[obj_trigger_id]; //h_pix gets incremented before render
    reg [7:0] current_obj_tile_id_raw ; // Tile ID without considering the object size
    reg [7:0] current_obj_flags; // Flags
    wire current_obj_to_bg_priority = current_obj_flags[7];
    wire current_obj_y_flip = current_obj_flags[6];
    wire current_obj_x_flip = current_obj_flags[5];
    wire current_obj_pal_number = current_obj_flags[4];
    wire [1:0] current_obj_pal= (current_obj_pal_number) ? (PPU_PAL_OB1) : (PPU_PAL_OB0);
    wire [7:0] line_to_obj_v_offset_raw = (v_pix + 8'd16 - current_obj_y); // Compensate 16 pixel offset and truncate to 3 bits
    wire [7:0] current_obj_tile_id = (reg_obj_size == 1'b1) ? 
        ({current_obj_tile_id_raw[7:1], (((line_to_obj_v_offset_raw[3])^(current_obj_y_flip)) ? 1'b1 : 1'b0)}) : // Select Hi or Lo tile
        (current_obj_tile_id_raw); // Use tile ID directly
    wire [2:0] line_to_obj_v_offset = (current_obj_y_flip) ? (~line_to_obj_v_offset_raw[2:0]) : (line_to_obj_v_offset_raw[2:0]);
    
    wire [12:0] current_obj_address_0 = current_obj_tile_id * 16 + line_to_obj_v_offset * 2;
    wire [12:0] current_obj_address_1 = current_obj_address_0 | 13'h0001;
    reg [7:0] current_obj_tile_data_0;
    reg [7:0] current_obj_tile_data_1;
    // Data that will be merged into pixel FIFO
    // Organized in pixels
    wire [15:0] current_obj_fetch_result = { 
        current_obj_tile_data_1[7], current_obj_tile_data_0[7],
        current_obj_tile_data_1[6], current_obj_tile_data_0[6],
        current_obj_tile_data_1[5], current_obj_tile_data_0[5],
        current_obj_tile_data_1[4], current_obj_tile_data_0[4],
        current_obj_tile_data_1[3], current_obj_tile_data_0[3],
        current_obj_tile_data_1[2], current_obj_tile_data_0[2],
        current_obj_tile_data_1[1], current_obj_tile_data_0[1],
        current_obj_tile_data_1[0], current_obj_tile_data_0[0]
        };
    
    wire [31:0] merge_result = 
        (current_obj_to_bg_priority) ?
        ({ // BG have higher priority
        (pf_data[63:62] == 2'b00) ? ({current_obj_fetch_result[15:14], current_obj_pal}) : ({pf_data[63:62], PPU_PAL_BG}),
        (pf_data[59:58] == 2'b00) ? ({current_obj_fetch_result[13:12], current_obj_pal}) : ({pf_data[59:58], PPU_PAL_BG}),
        (pf_data[55:54] == 2'b00) ? ({current_obj_fetch_result[11:10], current_obj_pal}) : ({pf_data[55:54], PPU_PAL_BG}),
        (pf_data[51:50] == 2'b00) ? ({current_obj_fetch_result[ 9: 8], current_obj_pal}) : ({pf_data[51:50], PPU_PAL_BG}),
        (pf_data[47:46] == 2'b00) ? ({current_obj_fetch_result[ 7: 6], current_obj_pal}) : ({pf_data[47:46], PPU_PAL_BG}),
        (pf_data[43:42] == 2'b00) ? ({current_obj_fetch_result[ 5: 4], current_obj_pal}) : ({pf_data[43:42], PPU_PAL_BG}),
        (pf_data[39:38] == 2'b00) ? ({current_obj_fetch_result[ 3: 2], current_obj_pal}) : ({pf_data[39:38], PPU_PAL_BG}),
        (pf_data[35:34] == 2'b00) ? ({current_obj_fetch_result[ 1: 0], current_obj_pal}) : ({pf_data[35:34], PPU_PAL_BG})
        }):
        { // OBJ have higher prioritiy
        (current_obj_fetch_result[15:14] == 2'b00) ? ({pf_data[63:62], PPU_PAL_BG}) : ({current_obj_fetch_result[15:14], current_obj_pal}),
        (current_obj_fetch_result[13:12] == 2'b00) ? ({pf_data[59:58], PPU_PAL_BG}) : ({current_obj_fetch_result[13:12], current_obj_pal}),
        (current_obj_fetch_result[11:10] == 2'b00) ? ({pf_data[55:54], PPU_PAL_BG}) : ({current_obj_fetch_result[11:10], current_obj_pal}),
        (current_obj_fetch_result[ 9: 8] == 2'b00) ? ({pf_data[51:50], PPU_PAL_BG}) : ({current_obj_fetch_result[ 9: 8], current_obj_pal}),
        (current_obj_fetch_result[ 7: 6] == 2'b00) ? ({pf_data[47:46], PPU_PAL_BG}) : ({current_obj_fetch_result[ 7: 6], current_obj_pal}),
        (current_obj_fetch_result[ 5: 4] == 2'b00) ? ({pf_data[43:42], PPU_PAL_BG}) : ({current_obj_fetch_result[ 5: 4], current_obj_pal}),
        (current_obj_fetch_result[ 3: 2] == 2'b00) ? ({pf_data[39:38], PPU_PAL_BG}) : ({current_obj_fetch_result[ 3: 2], current_obj_pal}),
        (current_obj_fetch_result[ 1: 0] == 2'b00) ? ({pf_data[35:34], PPU_PAL_BG}) : ({current_obj_fetch_result[ 1: 0], current_obj_pal})
        };
    
    // Next Mode Logic, based on next state
    always @ (*)
    begin
        case (r_next_state)
            S_IDLE: reg_mode_next = PPU_MODE_V_BLANK;
            S_BLANK: reg_mode_next = (is_in_v_blank) ? (PPU_MODE_V_BLANK) : (PPU_MODE_H_BLANK);
            S_OAMX: reg_mode_next = PPU_MODE_OAM_SEARCH;
            S_OAMY: reg_mode_next = PPU_MODE_OAM_SEARCH;
            S_FTIDA: reg_mode_next = PPU_MODE_PIX_TRANS;
            S_FTIDB: reg_mode_next = PPU_MODE_PIX_TRANS;
            S_FRD0A: reg_mode_next = PPU_MODE_PIX_TRANS;
            S_FRD0B: reg_mode_next = PPU_MODE_PIX_TRANS;
            S_FRD1A: reg_mode_next = PPU_MODE_PIX_TRANS;
            S_FRD1B: reg_mode_next = PPU_MODE_PIX_TRANS;
            S_FWAITA: reg_mode_next = PPU_MODE_PIX_TRANS;
            S_FWAITB: reg_mode_next = PPU_MODE_PIX_TRANS;
            S_SWW: reg_mode_next = PPU_MODE_PIX_TRANS;
            S_OAMRDA: reg_mode_next = PPU_MODE_PIX_TRANS;
            S_OAMRDB: reg_mode_next = PPU_MODE_PIX_TRANS;
            S_OFRD0A: reg_mode_next = PPU_MODE_PIX_TRANS;
            S_OFRD0B: reg_mode_next = PPU_MODE_PIX_TRANS;
            S_OFRD1A: reg_mode_next = PPU_MODE_PIX_TRANS;
            S_OFRD1B: reg_mode_next = PPU_MODE_PIX_TRANS;
            S_OWB: reg_mode_next = PPU_MODE_PIX_TRANS;
            default: reg_mode_next = PPU_MODE_V_BLANK;
        endcase
    end
    
    // Modify all state related synchonize registers
    always @(negedge clk)
    begin
        // Update Registers
        reg_ly_next[7:0] <= v_pix[7:0];
        
        // FSM Logic
        case (r_state)
            S_IDLE: 
            begin
                //?
            end
            S_BLANK: 
            begin
                h_pix_render <= 8'b0;
                h_pix_output <= 8'b0;
                valid <= 0;
                oam_search_count <= 6'b0;
                oam_visible_count <= 4'b0;
                pf_empty <= 5'd3;
                for (i = 0; i < 10; i=i+1) begin
                    //obj_visible_list[i] <= 6'b0;
                    //obj_trigger_list[i] <= 8'b0;
                    obj_valid_list[i] <= 1'b0;
                    //obj_y_list[i] <= 8'b0;
                end
                h_drop <= reg_scx[2:0];
                oam_rd_addr_int <= 8'b0;
                window_triggered <= 0;
            end
            S_OAMX: 
            begin
                valid <= 0;
                oam_search_y <= oam_data_out[7:0];
                oam_search_x <= oam_data_out[15:8];
            end
            S_OAMY: 
            begin
                valid <= 0;
                if ((((oam_search_y)<=(obj_h_upper_boundary))&&((oam_search_y)>(obj_h_lower_boundary)))&&
                    (oam_search_x != 8'b0)) begin
                    if (oam_visible_count < 4'd10) begin
                        obj_visible_list[oam_visible_count] <= oam_search_count;
                        obj_trigger_list[oam_visible_count] <= oam_search_x;
                        obj_y_list[oam_visible_count] <= oam_search_y;
                        obj_valid_list[oam_visible_count] <= 1;
                        oam_visible_count <= oam_visible_count + 1'b1;
                    end
                end    
                oam_search_count <= oam_search_count + 1'b1;
                oam_rd_addr_int <= (oam_search_count + 1'b1) * 4;
            end
            S_FTIDA: 
            begin
                vram_addr_int <= current_map_address;
                if (pf_empty == 5'd2) begin
                    valid <= 0;
                    pf_data[63:32] <= current_fetch_result[31:0];
                end
                else if (pf_empty == 5'd1) begin
                    if (h_drop != 3'd0) begin
                        h_drop <= h_drop - 1'd1;
                        valid <= 0;
                    end else
                    begin
                        valid <= 1;
                        h_pix_output <= h_pix_output + 1'b1;
                    end
                    pf_data <= {pf_data[59:32], current_fetch_result, 4'b0};
                    pixel <= pf_output_pixel;
                    pf_empty <= 0;
                end
                else if (pf_empty == 5'd0) begin
                    if (h_drop != 3'd0) begin
                        h_drop <= h_drop - 1'd1;
                        valid <= 0;
                    end else
                    begin
                        valid <= 1;
                        h_pix_output <= h_pix_output + 1'b1;
                    end
                    pf_data <= {pf_data[59:0], 4'b0000};
                    pixel <= pf_output_pixel;
                end
                else begin
                    valid <= 0;
                end
            end
            S_FTIDB: 
            begin
                current_tile_id <= vram_data_out;
                if (pf_empty == 5'd0) begin
                    pf_data <= {pf_data[59:0], 4'b0000};
                    pixel <= pf_output_pixel;
                    if (h_drop != 3'd0) begin
                        h_drop <= h_drop - 1'd1;
                        valid <= 0;
                    end else
                    begin
                        valid <= 1;
                        h_pix_output <= h_pix_output + 1'b1;
                    end
                end
                else begin
                    valid <= 0;
                end
            end
            S_FRD0A: 
            begin
                vram_addr_int <= current_tile_address_0;
                if (pf_empty == 5'd0) begin
                    pf_data <= {pf_data[59:0], 4'b0000};
                    pixel <= pf_output_pixel;
                    if (h_drop != 3'd0) begin
                        h_drop <= h_drop - 1'd1;
                        valid <= 0;
                    end else
                    begin
                        valid <= 1;
                        h_pix_output <= h_pix_output + 1'b1;
                    end
                end
                else begin
                    valid <= 0;
                end
            end
            S_FRD0B: 
            begin
                current_tile_data_0 <= vram_data_out;
                if (pf_empty == 5'd0) begin
                    pf_data <= {pf_data[59:0], 4'b0000};
                    pixel <= pf_output_pixel;
                    if (h_drop != 3'd0) begin
                        h_drop <= h_drop - 1'd1;
                        valid <= 0;
                    end else
                    begin
                        valid <= 1;
                        h_pix_output <= h_pix_output + 1'b1;
                    end
                end
                else begin
                    valid <= 0;
                end
            end
            S_FRD1A: 
            begin
                vram_addr_int <= current_tile_address_1;
                if (pf_empty == 5'd0) begin
                    pf_data <= {pf_data[59:0], 4'b0000};
                    pixel <= pf_output_pixel;
                    if (h_drop != 3'd0) begin
                        h_drop <= h_drop - 1'd1;
                        valid <= 0;
                    end else
                    begin
                        valid <= 1;
                        h_pix_output <= h_pix_output + 1'b1;
                    end
                end
                else begin
                    valid <= 0;
                end
            end
            S_FRD1B: 
            begin
                current_tile_data_1 <= vram_data_out;
                if (pf_empty == 5'd3) begin
                    valid <= 0;
                    pf_empty <= 5'd2; 
                    h_pix_render <= h_pix_render + 8'd8;
                    //Fetch result is not ready now, merge in the first stage.
                    //But h_pix add need to be handled here in order to have address ready
                end
                else if (pf_empty == 5'd2) begin
                    valid <= 0;
                    pf_empty <= 5'd1;
                    h_pix_render <= h_pix_render + 8'd8;
                end
                else if (pf_empty == 5'd0) begin
                    if (h_drop != 3'd0) begin
                        h_drop <= h_drop - 1'd1;
                        valid <= 0;
                    end else
                    begin
                        valid <= 1;
                        h_pix_output <= h_pix_output + 1'b1;
                    end
                    pf_data <= {pf_data[59:0], 4'b0000};
                    pixel <= pf_output_pixel;
                end
            end
            S_FWAITA: 
            begin
                pf_data <= {pf_data[59:0], 4'b0000};
                pixel <= pf_output_pixel;
                if (h_drop != 3'd0) begin
                        h_drop <= h_drop - 1'd1;
                        valid <= 0;
                    end else
                    begin
                        valid <= 1;
                        h_pix_output <= h_pix_output + 1'b1;
                    end
            end
            S_FWAITB: 
            begin
                h_pix_render <= h_pix_render + 8'd8;
                pf_data <= {pf_data[59:28], current_fetch_result};
                pixel <= pf_output_pixel;
                if (h_drop != 3'd0) begin
                        h_drop <= h_drop - 1'd1;
                        valid <= 0;
                    end else
                    begin
                        valid <= 1;
                        h_pix_output <= h_pix_output + 1'b1;
                    end
            end
            S_SWW:
            begin
                valid <= 0;
                pf_empty <= 5'd3;
                window_triggered <= 1;
                h_pix_render <= 0;
            end
            S_OAMRDA:
            begin
                valid <= 0;
                oam_rd_addr_int <= obj_triggered * 4 + 2'd2;
            end
            S_OAMRDB:
            begin
                valid <= 0;
                current_obj_tile_id_raw <= oam_data_out[7:0];
                current_obj_flags <= oam_data_out[15:8];
            end
            S_OFRD0A:
            begin
                valid <= 0;
                vram_addr_int <= current_obj_address_0;
            end
            S_OFRD0B:
            begin
                valid <= 0;
                current_obj_tile_data_0 <= vram_data_out;
            end
            S_OFRD1A:
            begin
                valid <= 0;
                vram_addr_int <= current_obj_address_1;
            end
            S_OFRD1B:
            begin
                valid <= 0;
                current_obj_tile_data_1 <= vram_data_out;
            end
            S_OWB:
            begin
                valid <= 0;
                vram_addr_int <= current_address_backup;
                pf_data <= {merge_result[31:0], pf_data[31:0]};
            end
        endcase
    end
    
    // Enter Next State
    // and handle object interrupt
    // (sorry but I need to backup next state so I could not handle these in the next state logic)
    always @(posedge clk)
    begin
        if (rst) begin
            r_state <= 0;
            r_next_backup <= 0;
            obj_trigger_id <= obj_trigger_not_found;//not triggered
        end
        else
        begin
            if (obj_trigger) begin
                // If already in object rendering stages
                if ((r_state == S_OFRD0A)||(r_state == S_OFRD0B)||
                    (r_state == S_OFRD1A)||(r_state == S_OFRD1B)||
                    (r_state == S_OAMRDA)||(r_state == S_OAMRDB)) begin
                    r_state <= r_next_state;
                end 
                // Finished one object, but there is more to go!
                else if (r_state == S_OWB) begin
                    r_state <= S_OAMRDA;
                    obj_trigger_id <= obj_trigger_id_next;
                end
                // Not rendering object before, start now
                else begin
                    r_next_backup <= r_next_state;
                    r_state <= S_OAMRDA;
                    obj_trigger_id <= obj_trigger_id_next;
                end
            end
            else begin
                r_state <= r_next_state;
                // Finished one object, should be no more!
                if (r_state == S_OWB) begin
                    obj_trigger_id <= obj_trigger_not_found;
                end
            end
        end
    end
    
    // Next State Logic
    // Since new state get updated during posedge
    always @(*)
    begin
        case (r_state)
            S_IDLE: r_next_state = ((reg_lcd_en)&(is_in_v_blank)) ? (S_BLANK) : (S_IDLE);
            S_BLANK: r_next_state = 
                (reg_lcd_en) ? (
                    (is_in_v_blank) ? 
                        (((v_count == (PPU_V_TOTAL - 1))&&(h_count == (PPU_H_TOTAL - 1))) ?
                            (S_OAMX) : (S_BLANK)
                        ) :
                        ((h_count == (PPU_H_TOTAL - 1)) ? 
                            ((v_count == (PPU_V_ACTIVE - 1)) ? 
                                (S_BLANK) : (S_OAMX)):
                            (S_BLANK)
                        )
                ) : (S_IDLE);
            S_OAMX: r_next_state = (reg_lcd_en) ? (S_OAMY) : (S_IDLE);
            S_OAMY: r_next_state = (reg_lcd_en) ? ((oam_search_count == (PPU_OAM_SEARCH_LENGTH)) ? (S_FTIDA) : (S_OAMX)) : (S_IDLE);
            S_FTIDA: r_next_state = (reg_lcd_en) ? ((h_pix_output == (PPU_H_FIFO)) ? (S_BLANK) : ((window_trigger) ? (S_SWW) : (S_FTIDB))) : (S_IDLE);
            S_FTIDB: r_next_state = (reg_lcd_en) ? ((h_pix_output == (PPU_H_FIFO)) ? (S_BLANK) : ((window_trigger) ? (S_SWW) : (S_FRD0A))) : (S_IDLE);
            S_FRD0A: r_next_state = (reg_lcd_en) ? ((h_pix_output == (PPU_H_FIFO)) ? (S_BLANK) : ((window_trigger) ? (S_SWW) : (S_FRD0B))) : (S_IDLE);
            S_FRD0B: r_next_state = (reg_lcd_en) ? ((h_pix_output == (PPU_H_FIFO)) ? (S_BLANK) : ((window_trigger) ? (S_SWW) : (S_FRD1A))) : (S_IDLE);
            S_FRD1A: r_next_state = (reg_lcd_en) ? ((h_pix_output == (PPU_H_FIFO)) ? (S_BLANK) : ((window_trigger) ? (S_SWW) : (S_FRD1B))) : (S_IDLE);
            S_FRD1B: r_next_state = (reg_lcd_en) ? ((h_pix_output == (PPU_H_FIFO)) ? (S_BLANK) : ((window_trigger) ? (S_SWW) : ((pf_empty != 5'd0) ? (S_FTIDA) : (S_FWAITA)))) : (S_IDLE); // If fifo is empty, no wait state is needed
            S_FWAITA: r_next_state = (reg_lcd_en) ? ((h_pix_output == (PPU_H_FIFO)) ? (S_BLANK) : ((window_trigger) ? (S_SWW) : (S_FWAITB))) : (S_IDLE);
            S_FWAITB: r_next_state = (reg_lcd_en) ? ((h_pix_output == (PPU_H_FIFO)) ? (S_BLANK) : ((window_trigger) ? (S_SWW) : (S_FTIDA))) : (S_IDLE);
            S_SWW: r_next_state = (reg_lcd_en) ? ((h_pix_output == (PPU_H_FIFO)) ? (S_BLANK) : (S_FTIDA)) : (S_IDLE);
            //S_OFTID: r_next_state = (reg_lcd_en) ? (S_OFRD0A) : (S_IDLE);
            S_OAMRDA: r_next_state = (reg_lcd_en) ? (S_OAMRDB) : (S_IDLE);
            S_OAMRDB: r_next_state = (reg_lcd_en) ? (S_OFRD0A) : (S_IDLE);
            S_OFRD0A: r_next_state = (reg_lcd_en) ? (S_OFRD0B) : (S_IDLE);
            S_OFRD0B: r_next_state = (reg_lcd_en) ? (S_OFRD1A) : (S_IDLE);
            S_OFRD1A: r_next_state = (reg_lcd_en) ? (S_OFRD1B) : (S_IDLE);
            S_OFRD1B: r_next_state = (reg_lcd_en) ? (S_OWB) : (S_IDLE);
            S_OWB: r_next_state = (reg_lcd_en) ? (r_next_backup) : (S_IDLE);
            default: r_next_state = S_IDLE;
        endcase
    end
    
    // Interrupt
    always @(posedge clk)
    begin
        if (rst) begin
            int_vblank_req <= 0;
            int_lcdc_req <= 0;
            reg_ly[7:0] <= 0;
            reg_stat[2] <= 0;
            reg_stat[1:0] <= PPU_MODE_V_BLANK;
        end
        else
        begin
            if ((reg_mode_next == PPU_MODE_V_BLANK)&&(reg_mode_flag != PPU_MODE_V_BLANK))
                int_vblank_req <= 1;
            if (((reg_lyc_int == 1'b1)&&(reg_ly_next == reg_lyc)&&(reg_ly != reg_lyc))||
                ((reg_oam_int == 1'b1)&&(reg_mode_next == PPU_MODE_OAM_SEARCH)&&(reg_mode_flag != PPU_MODE_OAM_SEARCH))||
                ((reg_vblank_int == 1'b1)&&(reg_mode_next == PPU_MODE_V_BLANK)&&(reg_mode_flag != PPU_MODE_V_BLANK))||
                ((reg_hblank_int == 1'b1)&&(reg_mode_next == PPU_MODE_H_BLANK)&&(reg_mode_flag != PPU_MODE_H_BLANK)))
                int_lcdc_req <= 1;
            if (int_vblank_ack)
                int_vblank_req <= 0;
            if (int_lcdc_ack)
                int_lcdc_req <= 0;
            reg_stat[2] <= (reg_ly_next == reg_lyc) ? 1 : 0;
            reg_ly <= reg_ly_next;
            reg_stat[1:0] <= reg_mode_next;
        end
    end
    
    // Bus RW
    // Bus RW - Combinational Read
    always @(*)
    begin
        dout = 8'hFF;
        if (addr_in_ppu) begin
            case (a)
                16'hFF40: dout = reg_lcdc;
                16'hFF41: dout = reg_stat;
                16'hFF42: dout = reg_scy;
                16'hFF43: dout = reg_scx;
                16'hFF44: dout = reg_ly;
                16'hFF45: dout = reg_lyc;
                16'hFF46: dout = reg_dma;
                16'hFF47: dout = reg_bgp;
                16'hFF48: dout = reg_obp0;
                16'hFF49: dout = reg_obp1;
                16'hFF4A: dout = reg_wy;
                16'hFF4B: dout = reg_wx;
            endcase
        end
        else
        if (addr_in_vram) begin
            if (vram_access_ext)
            begin
                dout = vram_data_out;
            end
        end
        else
        if (addr_in_oam) begin
            if (oam_access_ext)
            begin
                dout = oam_data_out;
            end
        end
    end
    
    // Bus RW - Sequential Write
    always @(posedge clk)
    begin
        if (rst) begin
            reg_lcdc <= 8'h00;
            reg_stat[7:3] <= 5'h00;
            reg_scy  <= 8'h00;
            reg_scx  <= 8'h00;
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
            if (wr) begin
                if (addr_in_ppu) begin
                    case (a)
                        16'hFF40: reg_lcdc <= din;
                        16'hFF41: reg_stat[7:3] <= din[7:3];
                        16'hFF42: reg_scy <= din;
                        16'hFF43: reg_scx <= din;
                        //16'hFF44: reg_ly <= din;
                        16'hFF45: reg_lyc <= din;
                        16'hFF46: reg_dma <= din;
                        16'hFF47: reg_bgp <= din;
                        16'hFF48: reg_obp0 <= din;
                        16'hFF49: reg_obp1 <= din;
                        16'hFF4A: reg_wy <= din;
                        16'hFF4B: reg_wx <= din;
                    endcase
                end
                // VRAM and OAM access should be completed automatically 
            end
        end
    end
    
    // Debug Outputs
    assign scx = reg_scx;
    assign scy = reg_scy;
    assign state = r_state;

endmodule
