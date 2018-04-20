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
//   GameBoy PPU
// Additional Comments: 
//   There are three hardware layers in the GameBoy PPU: Background, Window, and 
//   Object (or sprites).
//
//   Window will render above the background and the object can render above the
//   background or under the background. Each object have a priority bit to
//   indicate where it should be rendered.
//
//   Background, Window, and Object can be individually turned on or off. When 
//   nothing is turned on, it displays white.
//
//   The whole render logic does NOT require a scanline buffer to work, and it
//   runs at 4MHz (VRAM runs at 2MHz)
//
//   There are two main parts of the logic, implemented in a big FSM. The first
//   one is the fetch unit, and the other is the pixel FIFO.
//
//   The pixel FIFO shifts out one pixel when it contains more than 8 pixels, the 
//   fetch unit would generally render 8 pixels in 6 cycles (so 2 wait cycles are
//   inserted so they are in sync generally). When there is no enough pixels,
//   the FIFO would stop and wait for the fetch unit.
//
//   Windows Trigger is handled in the next state logic, there is a distinct state
//   for the PPU to switch from background rendering to window rendering (flush 
//   the fifo and add wait cycles.)
//
//   Object Trigger is handled in the state change block, in order to backup the 
//   previous state. Current RAM address is also backed up during the handling of
//   object rendering. Once all the objects at this position has been rendered,
//   the render state machine could be restored to its previous state.
//
//   The output pixel clock is the inverted main clock, which is the same as the
//   real Game Boy Pixel data would be put on the pixel bus on the negedge of 
//   clock, so the LCD would latch the data on the posedge. The original Game Boy
//   used a gated clock to control if output is valid. Since gated clock is not
//   recommend, I used a valid signal to indicate is output should be considered
//   valid.
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
    
    // Some interrupt related register
    reg [7:0] reg_ly_last;
    reg [1:0] reg_mode_last; // Next mode based on next state
    
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
    wire [1:0] reg_mode = reg_stat[1:0];
    
    localparam PPU_MODE_H_BLANK    = 2'b00;
    localparam PPU_MODE_V_BLANK    = 2'b01;
    localparam PPU_MODE_OAM_SEARCH = 2'b10;
    localparam PPU_MODE_PIX_TRANS  = 2'b11;
    
    localparam PPU_PAL_BG  = 2'b00;
    localparam PPU_PAL_OB0 = 2'b01;
    localparam PPU_PAL_OB1 = 2'b10;
    
    reg [12:0] vram_addr_bg;
    reg [12:0] vram_addr_obj;
    wire [12:0] vram_addr_int;
    wire [12:0] vram_addr_ext;
    wire vram_addr_int_sel; // 0 - BG, 1 - OBJ
    
    assign vram_addr_int = (vram_addr_int_sel == 1'b1) ? (vram_addr_obj) : (vram_addr_bg);
    
    wire addr_in_ppu  = (a >= 16'hFF40 && a <= 16'hFF4B);
    wire addr_in_vram = (a >= 16'h8000 && a <= 16'h9FFF);
    wire addr_in_oam  = (a >= 16'hFE00 && a <= 16'hFE9F);
    
    wire vram_access_ext = ((reg_mode == PPU_MODE_H_BLANK)||
                            (reg_mode == PPU_MODE_V_BLANK)||
                            (reg_mode == PPU_MODE_OAM_SEARCH));
    wire vram_access_int = ~vram_access_ext;
    wire oam_access_ext = ((reg_mode == PPU_MODE_H_BLANK)||
                           (reg_mode == PPU_MODE_V_BLANK));
    wire oam_access_int = ~oam_access_ext;
    
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
    wire [7:0] oam_data_in;
    wire oam_we;
    
    always @ (negedge clk)
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
    reg [2:0] pf_empty; // Indicate if the Pixel FIFO is empty. 
    localparam PF_INITA = 3'd5; // When a line start...
    localparam PF_INITB = 3'd4; // Line start, 2 pixels out, 8 rendered
    localparam PF_EMPTY = 3'd3; // When the pipeline get flushed
    localparam PF_HALF  = 3'd2; // After flushed, 8 pixels in
    localparam PF_FIN   = 3'd1; // 16 pixels in, but still no wait cycles
    localparam PF_FULL  = 3'd0; // Normal

    assign cpl = ~clk;
    //assign pixel = pf_output_pixel;
    
    // HV Timing
    localparam PPU_H_FRONT  = 9'd76;
    localparam PPU_H_SYNC   = 9'd4;    // So front porch + sync = OAM search
    localparam PPU_H_TOTAL  = 9'd456;
    localparam PPU_H_PIXEL  = 9'd160;
    localparam PPU_H_OUTPUT = 9'd168; // 8 null pixels in the front for objects which have x < 8
    localparam PPU_V_ACTIVE = 8'd144;
    localparam PPU_V_BACK   = 8'd9;
    localparam PPU_V_SYNC   = 8'd1;  
    localparam PPU_V_BLANK  = 8'd10;
    localparam PPU_V_TOTAL  = 8'd154;
   
    // Raw timing counter
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
    localparam S_OAMRDA   = 5'd13; // OAM Read Stage A
    localparam S_OAMRDB   = 5'd14; // OAM Read Stage B
    localparam S_OFRD0A   = 5'd15; // Object Fetch Read Data 0 Stage A
    localparam S_OFRD0B   = 5'd16; // Object Fetch Read Data 0 Stage B
    localparam S_OFRD1A   = 5'd17; // Object Fetch Read Data 1 Stage A
    localparam S_OFRD1B   = 5'd18; // Object Fetch Read Data 1 Stage B
    localparam S_OWB      = 5'd19; // Object Write Back
    
    localparam PPU_OAM_SEARCH_LENGTH = 6'd40;

    reg [2:0] h_drop; //Drop pixels when SCX % 8 != 0
    wire [2:0] h_extra = reg_scx % 8; //Extra line length when SCX % 8 != 0
    reg [7:0] h_pix_render; // Horizontal Render Pixel pointer
    reg [7:0] h_pix_output; // Horizontal Output Pixel counter
    wire [7:0] h_pix_obj = h_pix_output + 1'b1; // Coordinate used to trigger the object rendering
    wire [7:0] v_pix = v_count;
    wire [7:0] v_pix_in_map = v_pix + reg_scy;
    wire [7:0] v_pix_in_win = v_pix - reg_wy;

    reg [4:0] r_state = 0;
    reg [4:0] r_next_backup;
    reg [4:0] r_next_state;
    wire is_in_v_blank = ((v_count >= PPU_V_ACTIVE) && (v_count < PPU_V_ACTIVE + PPU_V_BLANK));
    
    reg window_triggered; // Indicate whether window has been triggered, should be replaced by a edge detector
    wire render_window_or_bg = window_triggered;
    wire window_trigger = (((h_pix_output - 8'd1) == (reg_wx))&&(v_pix >= reg_wy)&&(reg_win_en)&&(~window_triggered)) ? 1 : 0;
    
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
   
    // Data that will be pushed into pixel FIFO
    // Organized in pixels
    reg [31:0] current_fetch_result;
    always@(current_tile_data_1, current_tile_data_0) begin
        for (i = 0; i < 8; i = i + 1) begin
            current_fetch_result[i*4+3] = current_tile_data_1[i];
            current_fetch_result[i*4+2] = current_tile_data_0[i];
            current_fetch_result[i*4+1] = PPU_PAL_BG[1]; // Fetch could only fetch BG
            current_fetch_result[i*4+0] = PPU_PAL_BG[0];
        end
    end
    
    reg [5:0] oam_search_count; // Counter during OAM search stage
    reg [5:0] obj_visible_list [0:9]; // Total visible list
    reg [7:0] obj_trigger_list [0:9]; // Where the obj should be triggered
    reg [7:0] obj_y_list [0:9]; // Where the obj is
    reg obj_valid_list [0:9]; // Is obj visible entry valid
    reg [3:0] oam_visible_count; // ???
    
    wire [7:0] oam_search_x;
    wire [7:0] oam_search_y;
    wire [7:0] obj_size_h = (reg_obj_size == 1'b1) ? (8'd16) : (8'd8);
    wire [7:0] obj_h_upper_boundary = (v_pix + 8'd16);
    wire [7:0] obj_h_lower_boundary = obj_h_upper_boundary - obj_size_h;

    reg [3:0] obj_trigger_id; // The object currently being/ or have been rendered, in the visible list
        
    localparam OBJ_TRIGGER_NOT_FOUND = 4'd15; 
    
    // Cascade mux used to implement the searching of next id would be triggered
    reg [3:0] obj_trigger_id_from[0:10];
    reg [3:0] obj_trigger_id_next;
    always@(h_pix_obj, obj_trigger_id) begin
        obj_trigger_id_from[10] = OBJ_TRIGGER_NOT_FOUND; // There is no more after the 10th
        for (i = 9; i >= 0; i = i - 1) begin
            obj_trigger_id_from[i] = 
                ((h_pix_obj == obj_trigger_list[i])&&(obj_valid_list[i])) ? (i) : (obj_trigger_id_from[i+1]);
                // See if this one match, if not, cascade down.
        end
        if (obj_trigger_id == OBJ_TRIGGER_NOT_FOUND) // currently not triggered yet
            obj_trigger_id_next = obj_trigger_id_from[0]; // Search from start
        else
            obj_trigger_id_next = obj_trigger_id_from[obj_trigger_id + 1]; // Search start from next one
    end
    
    //!-- DEBUG --
    //wire [3:0] obj_trigger_id_next = ((h_pix_obj == obj_trigger_list[4'd0])&&(obj_valid_list[4'd0])) ? (4'd0) : (4'd15);
    
    wire obj_trigger = ((reg_obj_en)&&(obj_trigger_id_next != OBJ_TRIGGER_NOT_FOUND)) ? 1 : 0;
    //wire obj_trigger = 0;
    
    wire [5:0] obj_triggered = obj_visible_list[obj_trigger_id]; // The global id of object being rendered
    wire [7:0] current_obj_y = obj_y_list[obj_trigger_id];
    wire [7:0] current_obj_x = obj_trigger_list[obj_trigger_id]; //h_pix gets incremented before render
    reg [7:0] current_obj_tile_id_raw; // Tile ID without considering the object size
    reg [7:0] current_obj_flags; // Flags
    wire current_obj_to_bg_priority = current_obj_flags[7];
    wire current_obj_y_flip = current_obj_flags[6];
    wire current_obj_x_flip = current_obj_flags[5];
    wire current_obj_pal_id = current_obj_flags[4];
    wire [1:0] current_obj_pal= (current_obj_pal_id) ? (PPU_PAL_OB1) : (PPU_PAL_OB0);
    wire [3:0] line_to_obj_v_offset_raw = (v_pix + 8'd16 - current_obj_y); // Compensate 16 pixel offset and truncate to 4 bits
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
    reg [31:0] merge_result;
    always@(*) begin
        for (i = 0; i < 8; i = i + 1) begin
            if (
                    ((current_obj_tile_data_1[i] != 1'b0)||(current_obj_tile_data_0[i] != 1'b0))&&
                    ((pf_data[32+i*4+1] == PPU_PAL_BG[1])&&(pf_data[32+i*4+0] == PPU_PAL_BG[0]))&&
                    (
                        ((current_obj_to_bg_priority)&&(pf_data[32+i*4+3] == 1'b0)&&(pf_data[32+i*4+2] == 1'b0))|| 
                        (~current_obj_to_bg_priority)
                    )
                ) //(OBJ is not transparent) and ((BG priority and BG is transparent) or (OBJ priority))
            begin 
                merge_result[i*4+3] = current_obj_tile_data_1[i];
                merge_result[i*4+2] = current_obj_tile_data_0[i];
                merge_result[i*4+1] = current_obj_pal[1];
                merge_result[i*4+0] = current_obj_pal[0];
            end
            else begin
                merge_result[i*4+3] = pf_data[32+i*4+3];
                merge_result[i*4+2] = pf_data[32+i*4+2];
                merge_result[i*4+1] = pf_data[32+i*4+1];
                merge_result[i*4+0] = pf_data[32+i*4+0];
            end
        end
    end
    
    assign vram_addr_int_sel = 
        ((r_state == S_OAMRDB) || (r_state == S_OFRD0A) || (r_state == S_OFRD0B)
            || (r_state == S_OFRD1A) || (r_state == S_OFRD1B)) ? 1'b1 : 1'b0;
        
    
    // Current mode logic, based on current state
    always @ (posedge clk)
    begin
        case (r_state)
            S_IDLE: reg_stat[1:0] <= PPU_MODE_V_BLANK;
            S_BLANK: reg_stat[1:0] <= (is_in_v_blank) ? (PPU_MODE_V_BLANK) : (PPU_MODE_H_BLANK);
            S_OAMX: reg_stat[1:0] <= PPU_MODE_OAM_SEARCH;
            S_OAMY: reg_stat[1:0] <= PPU_MODE_OAM_SEARCH;
            S_FTIDA: reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
            S_FTIDB: reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
            S_FRD0A: reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
            S_FRD0B: reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
            S_FRD1A: reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
            S_FRD1B: reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
            S_FWAITA: reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
            S_FWAITB: reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
            S_SWW: reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
            S_OAMRDA: reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
            S_OAMRDB: reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
            S_OFRD0A: reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
            S_OFRD0B: reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
            S_OFRD1A: reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
            S_OFRD1B: reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
            S_OWB: reg_stat[1:0] <= PPU_MODE_PIX_TRANS;
            default: reg_stat[1:0] <= PPU_MODE_V_BLANK;
        endcase
    end

    assign oam_search_y = oam_data_out[7:0];
    assign oam_search_x = oam_data_out[15:8];

    // Render logic
    always @(posedge clk)
    begin
        reg_ly <= v_pix[7:0];
        
        case (r_state)
            // nothing to do for S_IDLE
            S_BLANK: begin
                h_pix_render <= 8'd0; // Render pointer
                oam_search_count <= 6'd0;
                oam_visible_count <= 4'd0;
                for (i = 0; i < 10; i = i + 1) begin
                    obj_valid_list[i] <= 1'b0;
                end
                oam_rd_addr_int <= 8'b0;
                window_triggered <= 1'b0;
                // Line start, need to render 16 pixels in 12 clocks
                // and output 8 null pixels starting from the 4th clock
            end
            S_OAMX: begin
                oam_rd_addr_int <= oam_search_count * 4;
            end
            S_OAMY: begin
                if ((oam_search_y <= obj_h_upper_boundary)&&
                    (oam_search_y >  obj_h_lower_boundary)&&
                    (oam_search_x != 8'd0)&&
                    (oam_visible_count < 4'd10)) begin
                    obj_visible_list[oam_visible_count] <= oam_search_count;
                    obj_trigger_list[oam_visible_count] <= oam_search_x;
                    obj_y_list[oam_visible_count] <= oam_search_y;
                    obj_valid_list[oam_visible_count] <= 1'b1;
                    oam_visible_count <= oam_visible_count + 1'b1;
                end
                oam_search_count <= oam_search_count + 1'b1;
            end
            S_FTIDA: vram_addr_bg <= current_map_address;
            S_FTIDB: current_tile_id <= vram_data_out;
            S_FRD0A: vram_addr_bg <= current_tile_address_0;
            S_FRD0B: current_tile_data_0 <= vram_data_out;
            S_FRD1A: vram_addr_bg <= current_tile_address_1;
            S_FRD1B: begin
                current_tile_data_1 <= vram_data_out;
                h_pix_render <= h_pix_render + 8'd8;
            end
            // nothing to do for S_WAITA, S_WAITB
            S_SWW: begin
                h_pix_render <= 8'd0;
                window_triggered <= 1'b1;
            end
            S_OAMRDA: oam_rd_addr_int <= obj_triggered * 4 + 2'd2;
            S_OAMRDB: begin
                current_obj_tile_id_raw <= oam_data_out[7:0];
                current_obj_flags <= oam_data_out[15:8];
            end
            S_OFRD0A: vram_addr_obj <= current_obj_address_0;
            S_OFRD0B:
                if (current_obj_x_flip == 1'b1)
                    current_obj_tile_data_0[7:0] <= {
                        vram_data_out[0], vram_data_out[1], vram_data_out[2], vram_data_out[3], 
                        vram_data_out[4], vram_data_out[5], vram_data_out[6], vram_data_out[7]
                    };
                else
                    current_obj_tile_data_0 <= vram_data_out;
            S_OFRD1A: vram_addr_obj <= current_obj_address_1;
            S_OFRD1B:
                if (current_obj_x_flip == 1'b1)
                    current_obj_tile_data_1[7:0] <= {
                        vram_data_out[0], vram_data_out[1], vram_data_out[2], vram_data_out[3], 
                        vram_data_out[4], vram_data_out[5], vram_data_out[6], vram_data_out[7]
                    };
                else
                    current_obj_tile_data_1 <= vram_data_out;
            // nothing to do for S_OWB
        endcase
    end
    
    // Output logic
    always @(posedge clk)
    begin
        if (r_state == S_BLANK) begin
            valid <= 1'b0;
            h_pix_output <= 8'd0; // Output pointer
            h_drop <= reg_scx[2:0];
            pf_empty <= PF_INITA; 
        end
        else if ((r_state == S_FTIDA) || (r_state == S_FTIDB) || (r_state == S_FRD0A) || (r_state == S_FRD0B) ||
            (r_state == S_FRD1A) || (r_state == S_FRD1B) || (r_state == S_FWAITA) || (r_state == S_FWAITB))
        begin
        
            if (r_state == S_FRD1B) begin
                if (pf_empty == PF_INITA) pf_empty <= PF_INITB;
                if (pf_empty == PF_INITB) pf_empty <= PF_FIN;
                if (pf_empty == PF_EMPTY) pf_empty <= PF_HALF;
                if (pf_empty == PF_HALF) pf_empty <= PF_FIN;
            end else
                if (pf_empty == PF_FIN) pf_empty <= PF_FULL; // should NOT wait through end
            
            // If it is in one of the output stages
            if (pf_empty == PF_EMPTY) begin
                // Just started, no data available
                valid <= 1'b0;
            end
            else if (pf_empty == PF_HALF) begin
                valid <= 1'b0;
                if (r_state == S_FTIDA) begin
                // One batch done, and they can be push into pipeline, but could not be output yet
                    pf_data[63:32] <= current_fetch_result[31:0];
                end
            end
            else if (((pf_empty == PF_INITA)&&((r_state == S_FRD1A)||(r_state == S_FRD1B)))
                    ||(pf_empty == PF_INITB)||(pf_empty == PF_FULL)||(pf_empty == PF_FIN)) begin 
                if (r_state == S_FTIDA) begin // reload and shift
                    if (pf_empty == PF_INITB) begin
                        pf_data[63:0] <= {20'b0, current_fetch_result[31:0], 12'b0};
                    end
                    else begin // PF_FULL or PF_FIN
                        pf_data[63:0] <= {pf_data[59:32], current_fetch_result[31:0], 4'b0};
                    end
                end
                else begin // just shift
                    pf_data <= {pf_data[59:0], 4'b0};
                end
                
                if (h_drop != 3'd0) begin
                    h_drop <= h_drop - 1'd1;
                    valid <= 0;
                end
                else begin
                    if (h_pix_output >= 8)
                        valid <= 1;
                    else
                        valid <= 0;
                    pixel <= pf_output_pixel;
                    h_pix_output <= h_pix_output + 1'b1;
                end
            end
        end
        else if (r_state == S_OAMRDA) begin
            h_pix_output <= h_pix_output - 1'b1; //revert adding
            valid <= 1'b0;
        end
        else if (r_state == S_OWB) begin
            h_pix_output <= h_pix_output + 1'b1; //restore adding
            pf_data <= {merge_result[31:0], pf_data[31:0]};
            valid <= 1'b0;
        end
        else if (r_state == S_SWW) begin
            pf_empty <= PF_EMPTY;  // Flush the pipeline 
            valid <= 1'b0;
        end
        else begin
            // Not even in output stages
            valid <= 1'b0;
        end
    end

    // Enter Next State
    // and handle object interrupt
    // (sorry but I need to backup next state so I could not handle these in the next state logic)
    always @(posedge clk)
    begin
        if (rst) begin
            //h_pix_obj <= 8'b0;
            r_state <= 0;
            r_next_backup <= 0;
            obj_trigger_id <= OBJ_TRIGGER_NOT_FOUND;//not triggered
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
                // Finished one object, but there is more
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
                //h_pix_obj <= h_pix_output + 8'd2;
                r_state <= r_next_state;
                // Finished one object, and there is no more currently
                if (r_state == S_OWB) begin
                    obj_trigger_id <= OBJ_TRIGGER_NOT_FOUND;
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
            S_OAMY: r_next_state = (reg_lcd_en) ? ((oam_search_count == (PPU_OAM_SEARCH_LENGTH - 1'b1)) ? (S_FTIDA) : (S_OAMX)) : (S_IDLE);
            S_FTIDA: r_next_state = (reg_lcd_en) ? ((h_pix_output == (PPU_H_OUTPUT - 1'b1)) ? (S_BLANK) : ((window_trigger) ? (S_SWW) : (S_FTIDB))) : (S_IDLE);
            S_FTIDB: r_next_state = (reg_lcd_en) ? ((h_pix_output == (PPU_H_OUTPUT - 1'b1)) ? (S_BLANK) : ((window_trigger) ? (S_SWW) : (S_FRD0A))) : (S_IDLE);
            S_FRD0A: r_next_state = (reg_lcd_en) ? ((h_pix_output == (PPU_H_OUTPUT - 1'b1)) ? (S_BLANK) : ((window_trigger) ? (S_SWW) : (S_FRD0B))) : (S_IDLE);
            S_FRD0B: r_next_state = (reg_lcd_en) ? ((h_pix_output == (PPU_H_OUTPUT - 1'b1)) ? (S_BLANK) : ((window_trigger) ? (S_SWW) : (S_FRD1A))) : (S_IDLE);
            S_FRD1A: r_next_state = (reg_lcd_en) ? ((h_pix_output == (PPU_H_OUTPUT - 1'b1)) ? (S_BLANK) : ((window_trigger) ? (S_SWW) : (S_FRD1B))) : (S_IDLE);
            S_FRD1B: r_next_state = (reg_lcd_en) ? ((h_pix_output == (PPU_H_OUTPUT - 1'b1)) ? (S_BLANK) : ((window_trigger) ? (S_SWW) : ((pf_empty != PF_FULL) ? (S_FTIDA) : (S_FWAITA)))) : (S_IDLE); // If fifo not full, no wait state is needed
            S_FWAITA: r_next_state = (reg_lcd_en) ? ((h_pix_output == (PPU_H_OUTPUT - 1'b1)) ? (S_BLANK) : ((window_trigger) ? (S_SWW) : (S_FWAITB))) : (S_IDLE);
            S_FWAITB: r_next_state = (reg_lcd_en) ? ((h_pix_output == (PPU_H_OUTPUT - 1'b1)) ? (S_BLANK) : ((window_trigger) ? (S_SWW) : (S_FTIDA))) : (S_IDLE);
            S_SWW: r_next_state = (reg_lcd_en) ? ((h_pix_output == (PPU_H_OUTPUT - 1'b1)) ? (S_BLANK) : (S_FTIDA)) : (S_IDLE);
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
    always @(*) reg_stat[2] = (reg_ly == reg_lyc) ? 1 : 0;
    always @(posedge clk)
    begin
        if (rst) begin
            int_vblank_req <= 0;
            int_lcdc_req <= 0;
            reg_ly_last[7:0] <= 0;
            //reg_stat[1:0] <= PPU_MODE_V_BLANK;
        end
        else
        begin
            if ((reg_mode == PPU_MODE_V_BLANK)&&(reg_mode_last != PPU_MODE_V_BLANK))
                int_vblank_req <= 1;
            if (((reg_lyc_int == 1'b1)&&(reg_ly == reg_lyc)&&(reg_ly_last != reg_lyc))||
                ((reg_oam_int == 1'b1)&&(reg_mode == PPU_MODE_OAM_SEARCH)&&(reg_mode_last != PPU_MODE_OAM_SEARCH))||
                ((reg_vblank_int == 1'b1)&&(reg_mode == PPU_MODE_V_BLANK)&&(reg_mode_last != PPU_MODE_V_BLANK))||
                ((reg_hblank_int == 1'b1)&&(reg_mode == PPU_MODE_H_BLANK)&&(reg_mode_last != PPU_MODE_H_BLANK)))
                int_lcdc_req <= 1;
            if (int_vblank_ack)
                int_vblank_req <= 0;
            if (int_lcdc_ack)
                int_lcdc_req <= 0;
            reg_ly_last <= reg_ly;
            reg_mode_last <= reg_mode;
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
