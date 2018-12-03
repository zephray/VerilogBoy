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
    input CLK_16M,
    // MCU Interface
    input MCU_CS,
    input MCU_SCK,
    output MCU_MISO,
    input MCU_MOSI,
    output MCU_IRQ,
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
    
    wire clk_raw = CLK_16M;
    wire [7:0] wb_a;
    wire [7:0] wb_d_to_master;
    wire [7:0] wb_d_to_slave;
    wire       wb_we;
    wire       wb_cyc;
    wire       wb_stb;
    wire       wb_ack;
    wire       wb_stall;
    wire clk_16;     // 1X  16M from DCM
    wire clk_33_dcm; // 2X  16M from DCM
    wire clk_33;     // 2X  16M from PLL
    wire clk_268;    // 16X 16M
    wire clk_268_s;  // 16X 16M shifted
    wire rst_pll;
    wire rst_dcm;
    wire rst;
    wire dcm_locked;
    wire pll_locked;
    
    dcm dcm
    (
        // Clock in ports
        .CLK_IN1(clk_raw),
        // Clock out ports
        .CLK_OUT1(clk_16),
        .CLK_OUT2(clk_33_dcm),
        // Status and control signals
        .RESET(rst_dcm),
        .LOCKED(dcm_locked)
    );
    
    assign rst_dcm = 1'b0;
    
    pll pll
    (   
        // Clock in ports
        .CLK_IN1(clk_33_dcm),
        // Clock out ports
        .CLK_OUT1(clk_268),
        .CLK_OUT2(clk_268_s),
        .CLK_OUT3(clk_33),
        // Status and control signals
        .RESET(rst_pll),
        .LOCKED(pll_locked)
    );
    
    debounce_rst debounce_rst(
        .clk(clk_16),
        .noisyRst(~dcm_locked),
        .PLLLocked(pll_locked),
        .cleanPLLRst(rst_pll),
        .cleanAsyncRst(rst)
    );
    
    mcu_if mcu_if(
        .clk(clk_16),
        .rst(rst),
        .mcu_cs(MCU_CS),
        .mcu_sck(MCU_SCK),
        .mcu_miso(MCU_MISO),
        .mcu_mosi(MCU_MOSI),
        .mcu_irq(MCU_IRQ),
        .wb_a(wb_a),
        .wb_din(wb_d_to_master),
        .wb_dout(wb_d_to_slave),
        .wb_we(wb_we),
        .wb_cyc(wb_cyc),
        .wb_stb(wb_stb),
        .wb_ack(wb_ack),
        .wb_stall(wb_stall)
    );
    
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
        .clk_sys_i(clk_16),
        .clk_dsi_i(clk_33),
        .clk_phy_i(clk_268),
        .clk_phy_shifted_i(clk_268_s),
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
    
    // Disable RAM for now
    assign RAM_WE_N = 1'b1;
    assign RAM_OE_N = 1'b1;
    assign RAM_CE_N = 1'b1;
    assign RAM_A[21:0] = 0;
    assign RAM_LB_N = 1'b0;
    assign RAM_UB_N = 1'b1;
    assign RAM_ZZ_N = 1'b1;
    assign RAM_DQ[15:0] = 16'bZ;


endmodule
