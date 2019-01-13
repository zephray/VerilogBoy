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
    // MCU Interface
    /*input MCU_CS,
    input MCU_SCK,
    output MCU_MISO,
    input MCU_MOSI,
    output MCU_IRQ,*/
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
    // LCD Interface
    output BL_EN,
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
    
    wire clk_in = CLK_IN;
    wire [7:0] wb_a;
    wire [7:0] wb_d_to_master;
    wire [7:0] wb_d_to_slave;
    wire       wb_we;
    wire       wb_cyc;
    wire       wb_stb;
    wire       wb_ack;
    wire       wb_stall;
    wire clk_in;     // Input clock
    wire clk_gb;     // Clock for Gameboy
    wire clk_dsi;    // Clock for DSI (Logic)
    wire clk_phy;    // Clock for DSI (PHY, 8xLogic)
    wire clk_phy_s;  // Clock for DSI (Data lane, Same or shift from PHY)
    wire rst_pll;
    wire rst;
    wire pll_locked;
    
    // ----------------------------------------------------------------------
    // Clocking
	 
    pll pll
    (   
        // Clock in ports
        .CLK_IN1(clk_in),
        // Clock out ports
        .CLK_OUT1(clk_gb),
        .CLK_OUT2(clk_dsi),
        .CLK_OUT3(clk_phy),
        .CLK_OUT4(clk_phy_s),
        // Status and control signals
        .RESET(rst_pll),
        .LOCKED(pll_locked)
    );
    
    debounce_rst debounce_rst(
        .clk(clk_in),
        .noisyRst(1'b0),
        .PLLLocked(pll_locked),
        .cleanPLLRst(rst_pll),
        .cleanAsyncRst(rst)
    );
	 
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
    wire [3:0]  vb_pixel;
    wire        vb_valid;
    wire [15:0] vb_left;
    wire [15:0] vb_right;

    verilogboy verilogboy(
        .rst(rst),
        .clk(clk_gb),
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
        .right(vb_right)
    );
	 
	 
    // ----------------------------------------------------------------------
    // Memory Controller
    
    // The memory controller receives address from the VerilogBoy Core and 
    // map it either into RAM bank, BootROM, or peripheral register address.
    
    // VB Core Memory Map: (16-bit address, 64KiB)
    // 0000 - 3EFF Cartridge Bank 0 (PSRAM) / BootROM (BRAM)
    // 3F00 - 3FFF Cartridge Bank 0 (PSRAM) / Peripherals (Wishbone)
    // 4000 - 7FFF Cartridge Bank X (PSRAM)
    // 8000 - 9FFF Blank (Mapped inside the VB Core)
    // A000 - BFFF CRAM (PSRAM)
    // C000 - DFFF WRAM (PSRAM)
    // E000 - EFFF Echo WRAM (PSRAM)
    // F000 - FDFF Echo WRAM (PSRAM)
    // FE00 - FFFF Blank (Mapped inside the VB core)
    
    // Physical RAM Memory Map: (23-bit address, 8MiB)
    // 000000 - 3FFFFF Cartridge ROM (4MB)
    // 400000 - 41FFFF Cartridge RAM (128KB)
    // 420000 - 427FFF Work RAM (32KB)
    // 428000 - 43FFFF Extended Work RAM (96KB)
    // 440000 - 7FFFFF Unused
    
    wire bootrom_enable = 1'b1; // Fixed enable for now
    wire [7:0]  wb_a;
    wire [7:0]  wb_din; // Master to Slave
    wire [7:0]  wb_dout;// Slave to Master
    wire        wb_cyc;
    wire        wb_stb;
    wire        wb_we;
    wire        wb_ack;
    wire        wb_stall;
    wire [21:0] rom_a; // Up to 4MB
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
    
    
    
    // Map addresses into PSRAM
    wire psram_rd = ram_rd || rom_rd;
    wire psram_wr = ram_wr;
    wire [21:0] psram_a = (ram_rd || ram_wr) ? ({5'b10000, ram_a[17:1]}) : {1'b1, rom_a[21:1]};
    wire psram_ub = psram_a[0];
    wire psram_lb = !psram_ub;
    wire [7:0] psram_din = ram_din;
    wire [7:0] psram_dout;
    assign rom_d = psram_dout;
    assign ram_dout = psram_dout;
    
    assign RAM_WE_N = !psram_wr;
    assign RAM_OE_N = !psram_rd;
    assign RAM_CE_N = !(psram_wr || psram_rd);
    assign RAM_A[21:0] = psram_a;
    assign RAM_LB_N = !psram_lb;
    assign RAM_UB_N = !psram_ub;
    assign RAM_ZZ_N = 1'b1;
    assign RAM_DQ[15:0] = (psram_wr) ? (psram_din) : (8'hzz);
    assign psram_dout[15:0] = RAM_DQ[15:0];

    // ----------------------------------------------------------------------
    // MIPI DSI controller
    
    wire        pix_next_frame;
    wire        pix_vsync;
    wire        pix_almost_full;
    wire [23:0] pix;
    wire        pix_wr;
    wire        dsi_dat_lp_p;
    wire        dsi_dat_lp_n;
    wire        dsi_dat_lp_oe;
    wire        dsi_clk_lp_p;
    wire        dsi_clk_lp_n;
    wire        dsi_clk_lp_oe;
    
    assign pix = 24'hFF0000;
    assign pix_wr = 1'b1;
    assign pix_vsync = 1'b1;
    
    dsi_core dsi_core(
        .clk_sys_i(clk_gb),
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
        .wb_dat_i(wb_d_to_slave[7:0]),
        .wb_dat_o(wb_d_to_master[7:0]),
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
    
    assign BL_EN = 1'b0;

    // ----------------------------------------------------------------------
    // I2C Master Controller
    
    // ----------------------------------------------------------------------
    // I2S Master Controller
    
    // ----------------------------------------------------------------------
    // PWM Controller

endmodule
