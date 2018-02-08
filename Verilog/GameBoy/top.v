`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:28:19 01/27/2018 
// Design Name: 
// Module Name:    top 
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
module top(
  //Audio
  /*output         AUDIO_SDATA_OUT,
  output         AUDIO_BIT_CLK,
  input          AUDIO_SDATA_IN,
  output         AUDIO_SYNC,
  output         FLASH_AUDIO_RESET_B,*/

  //SRAM & Flash
  /*output [30:0]  SRAM_FLASH_A,
  inout  [15:0]  SRAM_FLASH_D,
  inout  [31:16] SRAM_D,
  inout  [3:0]   SRAM_DQP,
  output [3:0]   SRAM_BW,
  output         SRAM_FLASH_WE_B,
  output         SRAM_CLK,
  output         SRAM_CS_B,
  output         SRAM_OE_B,
  output         SRAM_MODE,
  output         SRAM_ADV_LD_B,
  output         FLASH_CE_B,
  output         FLASH_OE_B,
  output         FLASH_CLK,
  output         FLASH_ADV_B,
  output         FLASH_WAIT,*/
  
  //UART
  /*output         FPGA_SERIAL1_TX,
  input          FPGA_SERIAL1_RX,
  output         FPGA_SERIAL2_TX,
  input          FPGA_SERIAL2_RX,*/
  
  //IIC
  /*output         IIC_SCL_MAIN,
  inout          IIC_SDA_MAIN,*/
  inout          IIC_SCL_VIDEO,
  inout          IIC_SDA_VIDEO,
  /*output         IIC_SCL_SFP,
  inout          IIC_SDA_SFP,*/
  
  //PS2
  /*output         MOUSE_CLK,
  input          MOUSE_DATA,
  output         KEYBOARD_CLK,
  inout          KEYBOARD_DATA,*/
  
  //VGA IN
  /*input          VGA_IN_DATA_CLK,
  input  [7:0]   VGA_IN_BLUE,
  input  [7:0]   VGA_IN_GREEN,
  input  [7:0]   VGA_IN_RED,
  input          VGA_IN_HSOUT,
  input          VGA_IN_ODD_EVEN_B,
  input          VGA_IN_VSOUT,
  input          VGA_IN_SOGOUT,*/
  
  //SW
  input  [4:0]   GPIO_COMPSW,
  input  [7:0]   GPIO_DIP_SW,

  //LED
  output [7:0]   GPIO_LED,
  output         GPIO_LED_C,
  output         GPIO_LED_W,
  output         GPIO_LED_E,
  output         GPIO_LED_S,
  output         GPIO_LED_N,

  //DDR2
  /*inout  [63:0]  DDR2_D,
  output [12:0]  DDR2_A,
  output [1:0]   DDR2_CLK_P,
  output [1:0]   DDR2_CLK_N,
  output [1:0]   DDR2_CE,
  output [1:0]   DDR2_CS_B,
  output [1:0]   DDR2_ODT,
  output         DDR2_RAS_B,
  output         DDR2_CAS_B,
  output         DDR2_WE_B,
  output [1:0]   DDR2_BA,
  output [7:0]   DDR2_DQS_P,
  output [7:0]   DDR2_DQS_N,
  output         DDR2_SCL,
  inout          DDR2_SDA,*/
  
  //Speaker
  //output         PIEZO_SPEAKER,
  
  //DVI
  output [11:0]  DVI_D,
  output         DVI_DE,
  output         DVI_H,
  output         DVI_RESET_B,
  output         DVI_V,
  output         DVI_XCLK_N,
  output         DVI_XCLK_P,
  input          DVI_GPIO1,
  
  //System
  input          FPGA_CPU_RESET_B,
  input          CLK_33MHZ_FPGA,
  input          CLK_27MHZ_FPGA
    );

//Clock and Reset control   
wire clk_33;
wire clk_27;
wire clk_27_90;
wire clk_4;
wire clk_100;

wire clk_gb;
wire clk_dvi;
wire clk_dvi_90;

wire reset_in;
wire reset_pll;
wire reset;
wire locked_pll;

assign clk_33 = CLK_33MHZ_FPGA;
assign reset_in = ~FPGA_CPU_RESET_B;

assign clk_gb = clk_4;
assign clk_dvi = clk_27;
assign clk_dvi_90 = clk_27_90;

pll pll (
  .CLKIN1_IN(clk_33), 
  .RST_IN(reset_pll), 
  .CLKOUT0_OUT(clk_4), 
  .CLKOUT1_OUT(clk_100), 
  .CLKOUT2_OUT(clk_27),
  .CLKOUT3_OUT(clk_27_90),
  .LOCKED_OUT(locked_pll)
);

debounce_rst debounce_rst(
  .clk(clk_33),
  .noisy_rst(reset_in),
  .pll_locked(locked_pll),
  .clean_pll_rst(reset_pll),
  .clean_async_rst(reset)
);
//

//Delay Control
/*localparam IODELAY_GRP = "IODELAY_MIG";
localparam RST_SYNC_NUM = 25;
ddr2_idelay_ctrl_mod #(
  .IODELAY_GRP(IODELAY_GRP),
  .RST_SYNC_NUM(RST_SYNC_NUM)
) ddr2_idelay_ctrl_mod (
  .clk_100MHz(clk_100),
  .rst(reset)
);*/

//DVI output
wire dvi_hs;
wire dvi_vs;
wire dvi_blank;
wire [7:0] dvi_r; 
wire [7:0] dvi_g; 
wire [7:0] dvi_b; 

dvi_mixer dvi_mixer(
  .clk(clk_dvi),
  .rst(reset),
  .gb_hs(),
  .gb_vs(),
  .gb_pclk(),
  .gb_pdat(),
  .dvi_hs(dvi_hs),
  .dvi_vs(dvi_vs),
  .dvi_blank(dvi_blank),
  .dvi_r(dvi_r),
  .dvi_g(dvi_g),
  .dvi_b(dvi_b)
    );

wire iic_done;

dvi_module dvi_module(  
  //Outputs
  .dvi_vs(DVI_V),        
  .dvi_hs(DVI_H), 
  .dvi_d(DVI_D), 
  .dvi_xclk_p(DVI_XCLK_P), 
  .dvi_xclk_n(DVI_XCLK_N),
  .dvi_de(DVI_DE), 
  .dvi_reset_b(DVI_RESET_B),  
  .iic_done(iic_done), 
  
  //Inouts
  .dvi_sda(IIC_SDA_VIDEO),
  .dvi_scl(IIC_SCL_VIDEO),
  
  //Inputs
  .pixel_clk(clk_dvi), 
  .shift_clk(clk_dvi_90),
  .gpuclk_rst(reset), 
  .hsync(dvi_hs),
  .vsync(dvi_vs),
  .blank_b(dvi_blank),
  .pixel_r(dvi_r),
  .pixel_b(dvi_b),
  .pixel_g(dvi_g)
);
//

//Debug output
assign GPIO_LED_C = locked_pll;
assign GPIO_LED_S = reset;
assign GPIO_LED_W = iic_done;
assign GPIO_LED_N = 0;
assign GPIO_LED_E = 0;

assign GPIO_LED[7:0] = 8'h0;
//

endmodule
