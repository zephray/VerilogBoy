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
  output [30:0]  SRAM_FLASH_A,
  inout  [15:0]  SRAM_FLASH_D,
  //inout  [31:16] SRAM_D,
  //inout  [3:0]   SRAM_DQP,
  //output [3:0]   SRAM_BW,
  output         SRAM_FLASH_WE_B,
  //output         SRAM_CLK,
  //output         SRAM_CS_B,
  //output         SRAM_OE_B,
  //output         SRAM_MODE,
  //output         SRAM_ADV_LD_B,
  output         FLASH_CE_B,
  output         FLASH_OE_B,
  output         FLASH_CLK,
  output         FLASH_ADV_B,
  //output         FLASH_WAIT,
  
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
  input          GPIO_SW_C,
  input          GPIO_SW_W,
  input          GPIO_SW_E,
  input          GPIO_SW_S,
  input          GPIO_SW_N,
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
    wire clk_16;

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
        .CLKOUT1_OUT(clk_16), 
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

    // GAME BOY
    wire gb_hs;
    wire gb_vs;
    wire gb_cpl;
    wire [1:0] gb_pixel;
    wire gb_valid;
    wire halt;
    wire debug_halt;
    wire [7:0] reg_a;
    wire [7:0] reg_f;
    wire [7:0] high_mem_data;
    wire [15:0] high_mem_addr;
    wire [7:0] instr;
    wire [15:0] reg_bc;
    wire [15:0] reg_de;
    wire [15:0] reg_hl;
    wire [15:0] reg_sp;
    wire [15:0] reg_pc;
    wire [4:0] reg_ie;
    wire [4:0] reg_if;
    reg [15:0] bp_addr;
    wire bp_step;
    wire bp_continue;
    wire [7:0] reg_scx;
    wire [7:0] reg_scy;
    
    wire bp_change;
    reg bp_write;
    
    wire [15:0] gb_a;
    wire [7:0] gb_dout;
    wire [7:0] gb_din;
    wire gb_wr;
    wire gb_rd;
    
    gameboy gameboy(
        .rst(reset), // Async Reset Input
        .clk(clk_gb), // 4.19MHz Clock Input
        .clk_mem(clk_16), // High Speed Memory Clock
        //Cartridge interface
        .a(gb_a), // Address Bus
        .dout(gb_dout),  // Data Bus
        .din(gb_din),
        .wr(gb_wr), // Write Enable
        .rd(gb_rd), // Read Enable
        .cs(), // External RAM Chip Select
        //Keyboard input
        .key(8'b0),
        //LCD output
        .hs(gb_hs), // Horizontal Sync Output
        .vs(gb_vs), // Vertical Sync Output
        .cpl(gb_cpl), // Pixel Data Latch
        .pixel(gb_pixel), // Pixel Data
        .valid(gb_valid), // Pixel Valid
        //Debug
        .halt(halt), // not quite implemented
        .debug_halt(debug_halt), // Debug mode status output
        .A_data(reg_a), // Accumulator debug output
        .F_data(reg_f), // Flags debug output
        .IE_data(reg_ie),
        .IF_data(reg_if),
        .high_mem_data(high_mem_data), // Debug high mem data output
        .high_mem_addr(high_mem_addr), // Debug high mem addr output
        .instruction(instr), // Debug current instruction output
        .regs_data({reg_bc, reg_de, reg_hl, reg_sp, reg_pc}), // Debug all reg data output
        .bp_addr(bp_addr), // Debug breakpoint PC
        .bp_step(bp_step), // Debug single step
        .bp_continue(bp_continue), // Debug continue
        .scx(reg_scx),
        .scy(reg_scy)
    );
    
    // Cartridge
    wire [9:0] rom_bank; //debug output
    
    mbc5 mbc5(
        .gb_clk(clk_gb),
        .gb_a(gb_a[15:12]),
        .gb_d(gb_dout[7:0]),
        .gb_cs(),
        .gb_wr(gb_wr),
        .gb_rd(gb_rd),
        .gb_rst(reset),
        .rom_a(SRAM_FLASH_A[21:13]),//Flash in 16bit mode
        .ram_a(),
        .rom_cs(),
        .ram_cs(),
        .ddir(),
        .rom_bank(rom_bank)
    );
    
    assign SRAM_FLASH_A[12:0] = gb_a[13:1];
    assign SRAM_FLASH_A[30:22] = 18'b0;
    assign gb_din[7:0] = gb_a[0] ? (SRAM_FLASH_D[15:8]) : (SRAM_FLASH_D[7:0]);
    assign SRAM_FLASH_WE_B = 1;
    assign FLASH_CE_B = 0;
    assign FLASH_OE_B = 0;
    assign FLASH_CLK = 1;
    assign FLASH_ADV_B = ~gb_rd;
   
    // Debugger
    wire [6:0] dbg_x; // Col address, 0-79
    wire [4:0] dbg_y; // Row address, 0-29
    wire [6:0] dbg_char; // Char display output
    wire dbg_clk;

    debugger debugger(
        .rst(reset),
        .clk(dbg_clk), // Do we need clock?
        .x(dbg_x), // Current Screen Cursor X
        .y(dbg_y), // Current Screen Cursor Y
        .chr(dbg_char), // Current Char Output
        .instr(instr),
        .reg_a(reg_a),
        .reg_f(reg_f),
        .reg_bc(reg_bc),
        .reg_de(reg_de),
        .reg_hl(reg_hl),
        .reg_sp(reg_sp),
        .reg_pc(reg_pc),
        .reg_ie(reg_ie),
        .reg_if(reg_if),
        .reg_scx(reg_scx),
        .reg_scy(reg_scy),
        .bp_addr(bp_addr),
        .rom_bank(rom_bank[7:0])
    );

    // DVI output
    wire dvi_hs;
    wire dvi_vs;
    wire dvi_blank;
    wire [7:0] dvi_r; 
    wire [7:0] dvi_g; 
    wire [7:0] dvi_b; 

    dvi_mixer dvi_mixer(
        .clk(clk_dvi),
        .rst(reset),
        // GameBoy Image Input
        .gb_hs(gb_hs),
        .gb_vs(gb_vs),
        .gb_pclk(gb_cpl),
        .gb_pdat(gb_pixel),
        .gb_valid(gb_valid),
        // Debugger Char Input
        .dbg_x(dbg_x),
        .dbg_y(dbg_y),
        .dbg_char(dbg_char),
        .dbg_sync(dbg_clk),
        // DVI signal Output
        .dvi_hs(dvi_hs),
        .dvi_vs(dvi_vs),
        .dvi_blank(dvi_blank),
        .dvi_r(dvi_r),
        .dvi_g(dvi_g),
        .dvi_b(dvi_b));

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
    //assign GPIO_LED_C = locked_pll;
    //assign GPIO_LED_S = reset;
    //assign GPIO_LED_W = iic_done;
    assign GPIO_LED_N = locked_pll;
    //assign GPIO_LED_E = 0;

    assign GPIO_LED[7] = gb_hs;
    assign GPIO_LED[6] = gb_vs;
    assign GPIO_LED[5] = gb_valid;
    assign GPIO_LED[4:3] = gb_pixel;
    assign GPIO_LED[2:0] = 3'b0;
    //
    
    //Keys
    button button_c(
        .pressed(bp_step), 
        .pressed_disp(GPIO_LED_C),
        .button_input(GPIO_SW_C),
        .clock(clk_gb),
        .reset(reset)
    );
    
    button button_w(
        .pressed(bp_change), 
        .pressed_disp(GPIO_LED_W),
        .button_input(GPIO_SW_W),
        .clock(clk_gb),
        .reset(reset)
    );
    
    button button_e(
        .pressed(bp_continue), 
        .pressed_disp(GPIO_LED_E),
        .button_input(GPIO_SW_E),
        .clock(clk_gb),
        .reset(reset)
    );
    
    button button_s(
        .pressed(), 
        .pressed_disp(GPIO_LED_S),
        .button_input(GPIO_SW_S),
        .clock(clk_gb),
        .reset(reset)
    );
    
    wire [7:0] dip_sw = {GPIO_DIP_SW[0], GPIO_DIP_SW[1], GPIO_DIP_SW[2], GPIO_DIP_SW[3], GPIO_DIP_SW[4], GPIO_DIP_SW[5], GPIO_DIP_SW[6], GPIO_DIP_SW[7]};
    
    always@(posedge bp_change, posedge reset)
    begin
        if (reset) begin
            bp_write <= 0;
        end
        else begin
            if (bp_write)
                bp_addr[15:8] <= dip_sw[7:0];
            else
                bp_addr[7:0] <= dip_sw[7:0];
            bp_write <= ~bp_write;
        end
    end

endmodule
