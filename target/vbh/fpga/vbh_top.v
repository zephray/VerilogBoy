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
    input wire CLK_IN,
    // PSRAM Interface
    inout  wire [15:0] RAM_DQ,
    output wire [21:0] RAM_A,
    output wire RAM_LB_N,
    output wire RAM_UB_N,
    output wire RAM_OE_N,
    output wire RAM_CE_N,
    output wire RAM_WE_N,
    output wire RAM_ZZ_N,
    // SPI Flash Interface
    output wire SPI_CS_B,
    output wire SPI_SCK,
    output wire SPI_MOSI,
    input  wire SPI_MISO,
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
    //input PMU_IRQ,
    output PMU_SCK,
    inout PMU_SDA,
    // LCD Interface
    output wire BL_EN,
    output wire BL_PWM,
    input  wire LCD_TE,
    output wire LCD_RESET,
    output wire LCD_D_LP_P,
    output wire LCD_D_LP_N,
    output wire LCD_D_HS_P,
    output wire LCD_D_HS_N,
    output wire LCD_C_LP_P,
    output wire LCD_C_LP_N,
    output wire LCD_C_HS_P,
    output wire LCD_C_HS_N,
    // Keyboard Matrix
    input [3:0] KEY_IN,
    output [1:0] KEY_OUT
    );
    
    // ----------------------------------------------------------------------
    // Clocking
	wire clk_in = CLK_IN;
    wire clk_in_bufg;
    wire clk_core;   // Clock for VerilogBoy Core, 4MHz
    wire clk_dsi;    // Clock for DSI (Logic), 33MHz (pixel clock)
    wire clk_phy;    // Clock for DSI (PHY, 8xLogic), 270MHz
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
    
    wire clk_rv = clk_core; // 4MHz
    
    /*debounce_rst debounce_rst(
        .clk(clk_in_bufg),
        .noisyRst(1'b0),
        .PLLLocked(pll_locked),
        .cleanPLLRst(rst_pll),
        .cleanAsyncRst(rst)
    );*/
	 
    // ----------------------------------------------------------------------
    // VerilogBoy core
    
    reg vb_rst;
    wire        vb_phi;
    wire [15:0] vb_a;
    wire [7:0]  vb_dout;
    wire [7:0]  vb_din;
    wire        vb_wr;
    wire        vb_rd;
    wire        vb_cs;
    wire [1:0]  vb_key_out;
    wire [7:0]  vb_key;
    wire        vb_hs;
    wire        vb_vs;
    wire        vb_cpl;
    wire [1:0]  vb_pixel;
    wire        vb_valid;
    wire [15:0] vb_left;
    wire [15:0] vb_right;

    boy boy(
        .rst(vb_rst),
        .clk(clk_core),
        .phi(),
        .a(vb_a),
        .dout(vb_dout),
        .din(vb_din),
        .wr(vb_wr),
        .rd(vb_rd),
        .cs(vb_cs),
        .key_out(vb_key_out),
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
    
    assign KEY_OUT = vb_key_out;
    assign vb_key = ~{KEY_IN, KEY_IN}; // Duplicate for high and low case

    // ----------------------------------------------------------------------
    // MBC5
    wire [22:0] vb_rom_a;
    wire [16:0] vb_ram_a;
    wire vb_ram_cs_n;
    wire vb_rom_cs_n;
    wire [7:0] vb_crom_dout;
    mbc5 mbc5(
        .vb_clk(clk_core),
        .vb_a(vb_a[15:12]),
        .vb_d(vb_dout),
        .vb_wr(vb_wr),
        .vb_rd(vb_rd),
        .vb_rst(vb_rst),
        .rom_a(vb_rom_a[22:14]),
        .ram_a(vb_ram_a[16:13]),
        .rom_cs_n(vb_rom_cs_n),
        .ram_cs_n(vb_ram_cs_n)
    );
    assign vb_rom_a[13:0] = vb_a[13:0];
    assign vb_ram_a[12:0] = vb_a[12:0];
    
    // ----------------------------------------------------------------------
    // Cartridge RAM
    wire [7:0] vb_cram_dout;
    wire vb_cram_wr = !vb_ram_cs_n & vb_wr;

    singleport_ram #(
        .WORDS(32768),
        .ABITS(15)
    ) br_cram (
        .clka(clk_core),
        .wea(vb_cram_wr),
        .addra(vb_ram_a[14:0]),
        .dina(vb_dout),
        .douta(vb_cram_dout)
    );
    
    // ----------------------------------------------------------------------
    // PSRAM
    reg psram_master_sel;
    wire [22:0] rv_psram_addr;
    wire rv_psram_ready;
    wire [31:0] rv_psram_rdata;
    wire [31:0] rv_psram_wdata;
    wire [3:0] rv_psram_wstrb;
    wire rv_psram_valid;
    wire rv_psram_wr = rv_psram_valid & (rv_psram_wstrb != 0);
    wire rv_psram_oe = rv_psram_valid & (rv_psram_wstrb == 0);
    wire [21:0] vb_psram_addr;
    wire vb_psram_rd;
    wire vb_psram_wr;
    wire [7:0] vb_psram_rdata;
    wire [7:0] vb_psram_wdata;
    
    assign RAM_WE_N = (psram_master_sel) ? (!rv_psram_wr) : (!vb_psram_wr);
    assign RAM_OE_N = (psram_master_sel) ? (!rv_psram_oe) : (!vb_psram_rd);
    assign RAM_CE_N = 1'b0;
    assign RAM_A[21:0] = (psram_master_sel) ? ({1'b0, rv_psram_addr[22:2]}) : (vb_psram_addr[21:0]);
    assign RAM_LB_N = 1'b0;
    assign RAM_UB_N = 1'b0;
    assign RAM_ZZ_N = 1'b1;
    assign RAM_DQ[15:0] = (RAM_WE_N) ? 16'hzz : ((psram_master_sel) ? (rv_psram_wdata[15:0]) : ({8'h00, vb_psram_wdata}));
    assign rv_psram_rdata = {16'd0, RAM_DQ[15:0]};
    assign vb_psram_rdata = RAM_DQ[7:0];
    
    assign vb_psram_addr = vb_rom_a[21:0];
    assign vb_psram_rd = !vb_rom_cs_n & vb_rd;
    assign vb_psram_wr = 1'b0;
    assign vb_psram_wdata = vb_dout;
    assign vb_din = (vb_ram_cs_n) ? (vb_psram_rdata) : (vb_cram_dout);
    
    
    // ----------------------------------------------------------------------
    // PicoRV32
    
    wire [16:0] spi_addr;
    wire spi_ready;
    wire [31:0] spi_rdata;
    wire spi_valid;
    
    wire [22:0] spinc_addr;
    wire spinc_ready;
    wire [31:0] spinc_rdata;
    wire spinc_valid;
    
    // Memory Map
    // 03000000 - 03000100 GPIO          See description below
    // 04000000 - 0400000F DSI           (16B)
    // 08000000 - 08000FFF Video RAM     (4KB)
    // 0C000000 - 0C7FFFFF PSRAM         (8MB)
    // 0E000000 - 0E01FFFF SPI Flash     (128KB, mapped from Flash 768K - 896K)
    // FFFF0000 - FFFFFFFF Internal RAM  (8KB w/ echo)
    parameter integer MEM_WORDS = 2048;
    parameter [31:0] STACKADDR = 32'hfffffffc;
    parameter [31:0] PROGADDR_RESET = 32'h0e000000;
    parameter [31:0] PROGADDR_IRQ = 32'h0e000010;
    
    wire mem_valid;
    wire mem_instr;
    wire mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0] mem_wstrb;
    wire [31:0] mem_rdata;
    wire [31:0] mem_la_addr;
    
    reg cpu_irq;
    
    wire la_addr_in_ram   = (mem_la_addr >= 32'hFFFF0000);
    wire la_addr_in_vram  = (mem_la_addr >= 32'h08000000) && (mem_la_addr < 32'h08004000);
    wire la_addr_in_gpio  = (mem_la_addr >= 32'h03000000) && (mem_la_addr < 32'h03000100);
    wire la_addr_in_dsi   = (mem_la_addr >= 32'h04000000) && (mem_la_addr < 32'h0400003F);
    wire la_addr_in_psram = (mem_la_addr >= 32'h0C000000) && (mem_la_addr < 32'h0C800000);
    wire la_addr_in_spi   = (mem_la_addr >= 32'h0E000000) && (mem_la_addr < 32'h0E020000);
    wire la_addr_in_spinc = (mem_la_addr >= 32'h0F000000) && (mem_la_addr < 32'h0F800000);
    
    reg addr_in_ram;
    reg addr_in_vram;
    reg addr_in_gpio;
    reg addr_in_dsi;
    reg addr_in_psram;
    reg addr_in_spi;
    reg addr_in_spinc;
    
    always@(posedge clk_rv) begin
        addr_in_ram <= la_addr_in_ram;
        addr_in_vram <= la_addr_in_vram;
        addr_in_gpio <= la_addr_in_gpio;
        addr_in_dsi <= la_addr_in_dsi;
        addr_in_psram <= la_addr_in_psram;
        addr_in_spi <= la_addr_in_spi;
        addr_in_spinc <= la_addr_in_spinc;
    end
    
    wire ram_valid = (mem_valid) && (!mem_ready) && (addr_in_ram);
    wire vram_valid = (mem_valid) && (!mem_ready) && (addr_in_vram);
    wire gpio_valid = (mem_valid) && (!mem_ready) && (addr_in_gpio);
    wire dsi_valid = (mem_valid) && (!mem_ready) && (addr_in_dsi);
    assign rv_psram_valid = (mem_valid) && (!mem_ready) && (addr_in_psram);
    assign spi_valid = (mem_valid) && (addr_in_spi);
    assign spinc_valid = (mem_valid) && (addr_in_spinc);
    wire general_valid = (mem_valid) && (!mem_ready) && (!addr_in_spi) && (!addr_in_spinc);
    
    reg default_ready;
    
    always @(posedge clk_rv) begin
        default_ready <= general_valid;
    end

    assign mem_ready = spi_ready || spinc_ready || default_ready;
    
    reg mem_valid_last;
    always @(posedge clk_rv) begin
        mem_valid_last <= mem_valid;
        if (mem_valid && !mem_valid_last && !(ram_valid || spi_valid || spinc_valid || vram_valid || gpio_valid || rv_psram_valid || dsi_valid))
            cpu_irq <= 1'b1;
        //else
        //    cpu_irq <= 1'b0;
        if (!rst_rv)
            cpu_irq <= 1'b0;
    end
    
    assign rv_psram_addr = mem_addr[22:0];
    assign rv_psram_wstrb = mem_wstrb;
    assign rv_psram_wdata = mem_wdata;
    
    assign spi_addr = mem_addr[16:0];
    
    assign spinc_addr = mem_addr[22:0];
    
    reg rst_rv;
    wire rst_rv_pre = rst;
    reg [3:0] rst_counter;
    
    always @(posedge clk_rv)
    begin
        if (rst_counter == 4'd15)
            rst_rv <= 1;
        else
            rst_counter <= rst_counter + 1;
        if (rst_rv_pre) begin
            rst_rv <= 0;
            rst_counter <= 4'd0;
        end
    end
    
     picorv32 #(
        .STACKADDR(STACKADDR),
        .PROGADDR_RESET(PROGADDR_RESET),
        .ENABLE_IRQ(1),
        .ENABLE_IRQ_QREGS(0),
        .ENABLE_IRQ_TIMER(0),
        .COMPRESSED_ISA(1),
        .PROGADDR_IRQ(PROGADDR_IRQ),
        .MASKED_IRQ(32'hfffffffe),
        .LATCHED_IRQ(32'hffffffff)
    ) cpu (
        .clk(clk_rv),
        .resetn(rst_rv),
        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),
        .mem_la_addr(mem_la_addr),
        .irq({31'b0, cpu_irq})
    );
    
    // Internal RAM & Boot ROM
    wire [31:0] ram_rdata;
    picosoc_mem #(
        .WORDS(MEM_WORDS)
    ) memory (
        .clk(clk_rv),
        .wen(ram_valid ? mem_wstrb : 4'b0),
        .addr({11'b0, mem_addr[12:2]}),
        .wdata(mem_wdata),
        .rdata(ram_rdata)
    );
    
    // ----------------------------------------------------------------------
    // SPI Flash
    
    // Wires to spimemio
    wire [16:0] spimem_addr;
    wire spimem_ready;
    wire [31:0] spimem_rdata;
    wire spimem_valid;
    
    cache cache(
        .clk(clk_rv),
        .rst(rst),
        .sys_addr(spi_addr), 
        .sys_rdata(spi_rdata),
        .sys_valid(spi_valid),
        .sys_ready(spi_ready),
        .mem_addr(spimem_addr),
        .mem_rdata(spimem_rdata),
        .mem_valid(spimem_valid),
        .mem_ready(spimem_ready)
    );
    
    wire spimemio_ready;
    wire [23:0] spimemio_addr;
    wire [31:0] spimemio_rdata;
    assign spimem_ready = (spimem_valid) ? (spimemio_ready) : (1'b0);
    assign spinc_ready = (spinc_valid) ? (spimemio_ready) : (1'b0);
    assign spimemio_addr = (spimem_valid) ? ({4'b0, 3'b110, spimem_addr}) : ({1'b0, spinc_addr});
    assign spimem_rdata = spimemio_rdata;
    assign spinc_rdata = spimemio_rdata;
    
    spimemio spimemio (
		.clk    (clk_dsi),
		.resetn (rst_rv),
		.valid  (spimem_valid || spinc_valid),
		.ready  (spimemio_ready),
		.addr   (spimemio_addr),
		.rdata  (spimemio_rdata),

		.flash_csb    (SPI_CS_B),
		.flash_clk    (SPI_SCK),

		.flash_io0_oe (),
		.flash_io1_oe (),
		.flash_io2_oe (),
		.flash_io3_oe (),

		.flash_io0_do (SPI_MOSI),
		.flash_io1_do (),
		.flash_io2_do (),
		.flash_io3_do (),

		.flash_io0_di (1'b0),
		.flash_io1_di (SPI_MISO),
		.flash_io2_di (1'b0),
		.flash_io3_di (1'b0),

		.cfgreg_we(4'b0000),
		.cfgreg_di(32'h0),
		.cfgreg_do()
	);
    
    // ----------------------------------------------------------------------
    // MIPI DSI controller
    wire        dsi_dat_lp_p;
    wire        dsi_dat_lp_n;
    wire        dsi_dat_lp_oe;
    wire        dsi_clk_lp_p;
    wire        dsi_clk_lp_n;
    wire        dsi_clk_lp_oe;
     
    wire        pix_next_frame;
    wire        pix_vsync;
    wire        pix_almost_full;
    wire [23:0] pix;
    wire        pix_wr;
    
    wire [5:0] char_x;
    wire [4:0] char_y;
    
    vga_mixer vga_mixer(
        .clk(clk_dsi),
        .rst(rst),
        // GameBoy Image Input
        .gb_hs(vb_hs),
        .gb_vs(vb_vs),
        .gb_pclk(vb_cpl),
        .gb_pdat(vb_pixel),
        .gb_valid(vb_valid),
        .gb_en(!vb_rst),
        // Debugger Char Input
        .dbg_x(char_x),
        .dbg_y(char_y),
        .dbg_char(vram_dout[6:0]),
        // DSI signal
        .pix(pix),
        .pix_next_frame(pix_next_frame),
        .pix_almost_full(pix_almost_full),
        .pix_wr(pix_wr),
        .hold(1'b0)
    );
    
    wire vram_wea = (vram_valid && (mem_wstrb != 0)) ? 1'b1 : 1'b0;
    
    wire [7:0] vram_dout;
    wire [11:0] rd_addr = char_y * 40 + char_x;
    dualport_ram vram(
        .clka(clk_rv),
        .wea(vram_wea),
        .addra(mem_addr[11:2]),
        .dina(mem_wdata[7:0]),
        .clkb(~clk_dsi),
        .addrb(rd_addr[9:0]),
        .doutb(vram_dout)
    );

// synthesis translate_off
    always @(posedge clk_rv) begin
        if (vram_wea) begin
            $display("%c", mem_wdata[7:0]);
        end
    end
// synthesis translate_on

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
        .wb_adr_i(mem_addr[5:2]),
        .wb_dat_i(mem_wdata),
        .wb_dat_o(),
        .wb_cyc_i(dsi_valid),
        .wb_stb_i(mem_wstrb),
        .wb_we_i((mem_wstrb != 0) ? 1'b1 : 1'b0),
        .wb_ack_o(),
        .wb_stall_o()
    );
    
    assign LCD_D_LP_P = ((dsi_dat_lp_p == 1'b1) && (dsi_dat_lp_oe == 1'b1)) ? 1'b1 : 1'bz;
    assign LCD_D_LP_N = ((dsi_dat_lp_n == 1'b1) && (dsi_dat_lp_oe == 1'b1)) ? 1'b1 : 1'bz;
    assign LCD_C_LP_P = ((dsi_clk_lp_p == 1'b1) && (dsi_clk_lp_oe == 1'b1)) ? 1'b1 : 1'bz;
    assign LCD_C_LP_N = ((dsi_clk_lp_n == 1'b1) && (dsi_clk_lp_oe == 1'b1)) ? 1'b1 : 1'bz;
    
    assign BL_EN = 1'b1;
    //assign BL_PWM = 1'b0;
    
    // ----------------------------------------------------------------------
    // GPIO
    
    // 03000000 (0) - W:  psram_master_sel
    // 03000004 (1) - ?
    // 03000008 (2) - ?
    // 0300000c (3) - W:  vb_rst
    // 03000010 (4) - ?
    // 03000014 (5) - W:  i2c_scl
    // 03000018 (6) - RW: i2c_sda
    // 0300001c (7) - ?
    
    reg [31:0] gpio_rdata;
    reg i2c_scl;
    reg i2c_sda;
    
    always@(posedge clk_rv) begin
        if (gpio_valid)
             if (mem_wstrb != 0) begin
                case (mem_addr[4:2])
                    3'd0: psram_master_sel <= mem_wdata[0];
                    3'd3: vb_rst <= mem_wdata[0];
                    3'd5: i2c_scl <= mem_wdata[0];
                    3'd6: i2c_sda <= mem_wdata[0];
                endcase
             end
             else begin
                case (mem_addr[4:2])
                    3'd6: gpio_rdata <= {31'd0, PMU_SDA};
                    default: gpio_rdata <= 32'd0;
                endcase
             end
         if (!rst_rv) begin
            psram_master_sel <= 1'b1;
            vb_rst <= 1'b1;
            i2c_scl <= 1'b1;
            i2c_sda <= 1'b1;
        end
    end
    
    assign PMU_SCK = i2c_scl;
    assign PMU_SDA = (i2c_sda) ? 1'bz : 1'b0;
    
    assign mem_rdata = 
        (addr_in_ram) ? (ram_rdata) : 
        ((addr_in_psram) ? (rv_psram_rdata) : 
        ((addr_in_gpio) ? (gpio_rdata) : 
        ((addr_in_spi) ? (spi_rdata) :
        ((addr_in_spinc) ? (spinc_rdata) : (32'hFFFFFFFF)))));


    // ----------------------------------------------------------------------
    // I2C Master Controller #1
    
    // ----------------------------------------------------------------------
    // I2C Master Controller #2
    
    // ----------------------------------------------------------------------
    // I2S Master Controller
    
    // ----------------------------------------------------------------------
    // PWM Controller
    pwm pwm(
        .clk(clk_core),
        .rst(rst),
        .duty(127),
        .out(BL_PWM)
    );

    // ----------------------------------------------------------------------
    // SDIO Controller
    
endmodule
