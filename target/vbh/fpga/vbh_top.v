`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    21:43:15 11/21/2018 
// Design Name: 
// Module Name:    vbh_top 
// Project Name:   VerilogBoy
// Description: 
//   Top level file for VerilogBoy Handheld target
// Dependencies: 
// 
// Additional Comments: 
//   See doc/vbh_ref_man.md for descriptions
////////////////////////////////////////////////////////////////////////////////
module vbh_top(
    // Global Clock Input
    input CLK_IN,
    // PSRAM Interface
    inout [15:0] RAM_DQ,
    output [21:0] RAM_A,
    output RAM_LB_N,
    output RAM_UB_N,
    output RAM_OE_N,
    output RAM_CE_N,
    output RAM_WE_N,
    output RAM_ZZ_N,
    // SD Card Interface
    /*output SD_CLK,
    output SD_CMD,
    output [3:0] SD_DAT,
    // DAC Interface
    output DAC_BCLK,
    output DAC_MCLK,
    output DAC_DOUT,
    output DAC_LRCK,
    output DAC_SCK,
    inout DAC_SDA,*/
    // PMU Interface
    /*input PMU_IRQ,
    output PMU_SCK,
    inout PMU_SDA,*/
    // LCD Interface
    output BL_EN,
    output BL_PWM,
    input LCD_TE,
    output LCD_RESET,
    output LCD_D_LP_P,
    output LCD_D_LP_N,
    output LCD_D_HS_P,
    output LCD_D_HS_N,
    output LCD_C_LP_P,
    output LCD_C_LP_N,
    output LCD_C_HS_P,
    output LCD_C_HS_N
    // Keyboard Matrix
    /*input [3:0] KEY_IN,
    output [1:0] KEY_OUT*/
    );
    
    // ----------------------------------------------------------------------
    // Clocking
	wire clk_in = CLK_IN;
    wire clk_in_bufg;
    wire clk_core;   // Clock for VerilogBoy Core
    wire clk_dsi;    // Clock for DSI (Logic)
    wire clk_phy;    // Clock for DSI (PHY, 8xLogic)
    wire clk_phy_s;  // Clock for DSI (Data lane, Same or shift from PHY)
    wire rst_pll;
    wire rst;
    wire pll_locked;
    
    pll pll
    (   
        // Clock in ports
        .CLK_IN1(clk_in),
        // Clock out ports
        .CLK_IN1_BUFFERED(clk_in_bufg),
        .CLK_OUT1(clk_core),
        .CLK_OUT2(clk_dsi),
        .CLK_OUT3(clk_phy),
        .CLK_OUT4(clk_phy_s),
        // Status and control signals
        .RESET(rst_pll),
        .LOCKED(pll_locked)
    );
    
    assign rst_pll = 1'b0;
    assign rst = !pll_locked;
    
    /*debounce_rst debounce_rst(
        .clk(clk_in_bufg),
        .noisyRst(1'b0),
        .PLLLocked(pll_locked),
        .cleanPLLRst(rst_pll),
        .cleanAsyncRst(rst)
    );*/
	 
    // ----------------------------------------------------------------------
    // VerilogBoy core
    
    wire        vb_phi;
    wire [15:0] vb_a;
    wire [7:0]  vb_dout;
    wire [7:0]  vb_din;
    wire        vb_wr;
    wire        vb_rd;
    wire        vb_cs;
    wire [7:0]  vb_key;
    wire        vb_hs;
    wire        vb_vs;
    wire        vb_cpl;
    wire [1:0]  vb_pixel;
    wire        vb_valid;
    wire [15:0] vb_left;
    wire [15:0] vb_right;

    boy boy(
        .rst(rst),
        .clk(clk_core),
        .phi(),
        .a(vb_a),
        .dout(vb_dout),
        .din(vb_din),
        .wr(vb_wr),
        .rd(vb_rd),
        .cs(vb_cs),
        .key(vb_key),
        .hs(vb_hs),
        .vs(vb_vs),
        .cpl(vb_cpl),
        .pixel(vb_pixel),
        .valid(vb_valid),
        .left(vb_left),
        .right(vb_right),
        .done(done)
    );
	 
    // ----------------------------------------------------------------------
    // Memory Controller
    
    // The memory controller receives address from the VerilogBoy Core and 
    // map it either into RAM bank, BootROM, or peripheral register address.
    
    // VB Core Memory Map: (16-bit address, 64KiB)
    // 0000 - 3EFF Cartridge Bank 0 (PSRAM) / BootROM (BRAM)
    // 4000 - 7FFF Cartridge Bank X (PSRAM)
    // 8000 - 9FFF Blank (Mapped inside the VB Core)
    // A000 - BFFF CRAM (PSRAM)
    // C000 - DFFF WRAM (PSRAM)
    // E000 - EFFF Echo WRAM (PSRAM)
    // F000 - FDFF Echo WRAM (PSRAM)
    // FE00 - FF00 Blank
	 // FF00 - FF7F Blank / Peripherals (Wishbone)
    // FF80 - FFFF Blank
	 
    // Physical RAM Memory Map: (23-bit address, 8MiB)
    // 000000 - 3FFFFF Cartridge ROM (4MB)
    // 400000 - 41FFFF Cartridge RAM (128KB)
    // 420000 - 427FFF Work RAM (32KB)
    // 428000 - 43FFFF Extended Work RAM (96KB)
    // 440000 - 7FFFFF Unused
    
    wire        vb_brom_en = 1'b1; // Fixed to enable for now
    wire [4:0]  vb_wram_bank = 5'd0; // Fixed to bank 0 for now
    wire [7:0]  wb_a;
    wire [7:0]  wb_din; // Master to Slave
    wire [7:0]  wb_dout;// Slave to Master
    wire        wb_cyc;
    wire        wb_stb;
    wire        wb_we;
    wire        wb_ack;
    wire        wb_stall;
    wire [22:0] rom_a; // Up to 8MB (hardware limit to 4MB)
    wire [7:0]  rom_d;
    wire        rom_rd;
    wire [17:0] ram_a; // Up to 256KB
    wire [7:0]  ram_din;
    wire [7:0]  ram_dout;
    wire        ram_wr;
    wire        ram_rd;
    wire [13:0] brom_a; // Up to 16KB
    wire [7:0]  brom_d;
    wire        brom_rd;
    
    mc mc(
        .vb_clk(clk_core),
        .vb_rst(rst),
        .vb_din(vb_din),
        .vb_dout(vb_dout),
        .vb_a(vb_a),
        .vb_wr(vb_wr),
        .vb_rd(vb_rd),
        .vb_brom_en(vb_brom_en),
        .vb_wram_bank(vb_wram_bank),
        .wb_a(wb_a),
        .wb_din(wb_din),
        .wb_dout(wb_dout),
        .wb_cyc(wb_cyc),
        .wb_stb(wb_stb),
        .wb_we(wb_we),
        .wb_ack(wb_ack),
        .wb_stall(wb_stall),
        .rom_a(rom_a),
        .rom_d(rom_d),
        .rom_rd(rom_rd),
        .ram_a(ram_a),
        .ram_din(ram_din),
        .ram_dout(ram_dout),
        .ram_wr(ram_wr),
        .ram_rd(ram_rd),
        .brom_a(brom_a),
        .brom_d(brom_d),
        .brom_rd(brom_rd)
    );
    
    // Map addresses into PSRAM
    wire psram_rd = ram_rd || rom_rd;
    wire psram_wr = ram_wr;
    wire [21:0] psram_a = (ram_rd || ram_wr) ? ({5'b10000, ram_a[17:1]}) : {1'b1, rom_a[21:1]};
    wire psram_ub = (ram_rd || ram_wr) ? (ram_a[0]) : (rom_a[0]);
    wire psram_lb = !psram_ub;
    wire [15:0] psram_din = (psram_ub) ? ({ram_din[7:0], 8'b0}) : ({8'b0, ram_din[7:0]});
    wire [15:0] psram_dout;
    assign rom_d = (psram_ub) ? (psram_dout[15:8]) : (psram_dout[7:0]);
    assign ram_dout = (psram_ub) ? (psram_dout[15:8]) : (psram_dout[7:0]);
    
    assign RAM_WE_N = !psram_wr;
    assign RAM_OE_N = !psram_rd;
    assign RAM_CE_N = !(psram_wr || psram_rd);
    assign RAM_A[21:0] = psram_a;
    assign RAM_LB_N = !psram_lb;
    assign RAM_UB_N = !psram_ub;
    assign RAM_ZZ_N = 1'b1;
    assign RAM_DQ[15:0] = (psram_wr) ? (psram_din) : (16'hzz);
    assign psram_dout[15:0] = RAM_DQ[15:0];
	 
    // Boot ROM (8KB for now)
    brom brom(
        .clk(clk_core),
        .a(brom_a[12:0]),
        .d(brom_d)
    );

    // ----------------------------------------------------------------------
    // MIPI DSI controller
    
    wire        pix_next_frame;
    wire        pix_vsync;
    wire        pix_almost_full;
    wire [23:0] pix;
    reg         pix_wr;
    wire        dsi_dat_lp_p;
    wire        dsi_dat_lp_n;
    wire        dsi_dat_lp_oe;
    wire        dsi_clk_lp_p;
    wire        dsi_clk_lp_n;
    wire        dsi_clk_lp_oe;
    
    reg [16:0] pix_counter;
    reg last_vsync;
    reg [6:0] frame_counter;
    reg [1:0] color_sel;
    
    always@(posedge clk_dsi) begin
        if (rst) begin
            pix_counter <= 0;
            pix_wr <= 1'b0;
            frame_counter <= 0;
            color_sel <= 0;
        end
        else begin
            if (pix_counter < 17'd102400) begin
                pix_counter <= pix_counter + 1;
                pix_wr <= 1'b1;
            end
            else begin
                pix_wr <= 1'b0;
                last_vsync <= pix_next_frame;
                if (!last_vsync && pix_next_frame) begin
                    pix_counter <= 0;
                    if (frame_counter == 59) begin
                        if (color_sel == 2)
                            color_sel <= 0;
                        else
                            color_sel <= color_sel + 1;
                        frame_counter <= 0;
                    end
                    else begin
                        frame_counter <= frame_counter + 1;
                    end
                end
            end
        end
    end
    
    assign pix = (color_sel == 0) ? (24'hFF0000) : ((color_sel == 1) ? (24'h00FF00) : (24'h0000FF));
    
//    assign pix_wr = 1'b1;
    assign pix_vsync = 1'b1;
    
    dsi_core dsi_core(
        .clk_sys_i(clk_core),
        .clk_dsi_i(clk_dsi),
        .clk_phy_i(clk_phy),
        .clk_phy_shifted_i(clk_phy_s),
        .rst_n_i(!rst),
        .pll_locked_i(pll_locked),
        .pix_next_frame_o(pix_next_frame),
        .pix_vsync_i(pix_vsync),
        .pix_almost_full_o(pix_almost_full),
        .pix_i(pix),
        .pix_wr_i(pix_wr),
        .dsi_hs_p_o(LCD_D_HS_P),
        .dsi_hs_n_o(LCD_D_HS_N),
        .dsi_lp_p_o(dsi_dat_lp_p),
        .dsi_lp_n_o(dsi_dat_lp_n),
        .dsi_lp_oe_o(dsi_dat_lp_oe),
        .dsi_clk_p_o(LCD_C_HS_P),
        .dsi_clk_n_o(LCD_C_HS_N),
        .dsi_clk_lp_p_o(dsi_clk_lp_p),
        .dsi_clk_lp_n_o(dsi_clk_lp_n),
        .dsi_clk_lp_oe_o(dsi_clk_lp_oe),
        .dsi_reset_n_o(LCD_RESET),
        .wb_adr_i(wb_a[3:0]),
        .wb_dat_i(wb_din),
        .wb_dat_o(wb_dout),
        .wb_cyc_i(wb_cyc),
        .wb_stb_i(wb_stb),
        .wb_we_i(wb_we),
        .wb_ack_o(wb_ack),
        .wb_stall_o(wb_stall)
    );
    
    assign LCD_D_LP_P = ((dsi_dat_lp_p == 1'b1) && (dsi_dat_lp_oe == 1'b1)) ? 1'b1 : 1'bZ;
    assign LCD_D_LP_N = ((dsi_dat_lp_n == 1'b1) && (dsi_dat_lp_oe == 1'b1)) ? 1'b1 : 1'bZ;
    assign LCD_C_LP_P = ((dsi_clk_lp_p == 1'b1) && (dsi_clk_lp_oe == 1'b1)) ? 1'b1 : 1'bZ;
    assign LCD_C_LP_N = ((dsi_clk_lp_n == 1'b1) && (dsi_clk_lp_oe == 1'b1)) ? 1'b1 : 1'bZ;
    
    assign BL_EN = 1'b1;
    assign BL_PWM = 1'b0;
    
    

    // ----------------------------------------------------------------------
    // I2C Master Controller #1
    
    // ----------------------------------------------------------------------
    // I2C Master Controller #2
    
    // ----------------------------------------------------------------------
    // I2S Master Controller
    
    // ----------------------------------------------------------------------
    // PWM Controller

    // ----------------------------------------------------------------------
    // SDIO Controller
    
endmodule
