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
    output RAM_ZZ_N
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
    inout DAC_SDA,
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
    output LCD_C_HS_N,
    // Keyboard Matrix
    input [3:0] KEY_IN,
    output [1:0] KEY_OUT*/
    );
    
    wire clk = CLK_16M;
    wire [7:0] ram_din;
    wire [7:0] ram_dout;
    assign ram_din = RAM_DQ[7:0];
    assign RAM_DQ[7:0] = (RAM_WE_N) ? (8'hzz) : (ram_dout);
    wire bm_wr;
    wire bm_rd;
    
    mcu_if mcu_if(
        .clk(clk),
        .rst(1'b0),
        .mcu_cs(MCU_CS),
        .mcu_sck(MCU_SCK),
        .mcu_miso(MCU_MISO),
        .mcu_mosi(MCU_MOSI),
        .mcu_irq(MCU_IRQ),
        .bm_a(RAM_A[7:0]),
        .bm_din(ram_din),
        .bm_dout(ram_dout),
        .bm_wr(bm_wr),
        .bm_rd(bm_rd)
    );
    
    assign RAM_WE_N = !bm_wr;
    assign RAM_OE_N = !bm_rd;
    assign RAM_CE_N = !(bm_wr || bm_rd);
    
    assign RAM_A[21:8] = 0;
    assign RAM_LB_N = 1'b0;
    assign RAM_UB_N = 1'b1;
    assign RAM_ZZ_N = 1'b1;


endmodule
