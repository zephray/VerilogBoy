`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    21:43:15 11/21/2018 
// Design Name: 
// Module Name:    pano_top 
// Project Name:   VerilogBoy
// Description: 
//   Top level file for Pano Logic G1
// Dependencies: 
// 
// Additional Comments: 
//   
////////////////////////////////////////////////////////////////////////////////
module pano_top(
    // Global Clock Input
    input wire CLK_OSC,
    
    // IDT Clock Generator
    // Not used, DCM is used to generate the clock
    /*output wire IDT_ICLK,
    input  wire IDT_CLK1,
    output wire IDT_SCLK,
    output wire IDT_STROBE,
    output wire IDT_DATA,*/

    // Power LED
    output wire LED_RED,
    output wire LED_GREEN,
    output wire LED_BLUE,
    
    // Push Button
    input  wire PB,

    // SPI Flash
    output wire SPI_CS_B,
    output wire SPI_SCK,
    output wire SPI_MOSI,
    input  wire SPI_MISO,

    // WM8750 Codec
    output wire AUDIO_MCLK,
    output wire AUDIO_BCLK,
    output wire AUDIO_DACDATA,
    output wire AUDIO_DACLRCK,
    //input  wire AUDIO_ADCDATA,
    //output wire AUDIO_ADCLRCK,
    output wire AUDIO_SCL,
    inout  wire AUDIO_SDA,

    // LPDDR SDRAM
    output wire [11:0] LPDDR_A,
    output wire LPDDR_CK_P,
    output wire LPDDR_CK_N,
    output wire LPDDR_CKE,
    output wire LPDDR_WE_B,
    output wire LPDDR_CAS_B,
    output wire LPDDR_RAS_B,
    output wire [3:0] LPDDR_DM,
    output wire [1:0] LPDDR_BA,
    inout  wire [31:0] LPDDR_DQ,
    inout  wire [3:0] LPDDR_DQS,

    // VGA
    output wire VGA_CLK,
    output wire VGA_VSYNC,
    output wire VGA_HSYNC,
    output wire VGA_BLANK_B,
    inout  wire VGA_SCL,
    inout  wire VGA_SDA,
    output wire [7:0] VGA_R,
    output wire [7:0] VGA_G,
    output wire [7:0] VGA_B,

    // USB
    output wire USB_CLKIN,
    output wire USB_RESET_B,
    output wire USB_CS_B,
    output wire USB_RD_B,
    output wire USB_WR_B,
    input  wire USB_IRQ,
    output wire [17:1] USB_A,
    inout  wire [15:0] USB_D,
    
    // USB HUB
    output wire USB_HUB_CLKIN,
    output wire USB_HUB_RESET_B
    );
    
    // ----------------------------------------------------------------------
    // Clocking
    wire clk_100_in;       // On-board 100M clock source 
    wire clk_4_raw;        // 4.196MHz for VerilogBoy Core
    wire clk_4;
    wire clk_12_raw;       // 12MHz for USB controller and codec
    wire clk_12;
    wire clk_24_raw;       // 24MHz for on-board USB hub
    wire clk_24;
    wire clk_100_raw;      // 100MHz for PicoRV32 and LPDDR controller
    wire clk_100;
    wire clk_100_90_raw;
    wire clk_100_90;
    wire clk_100_180_raw;
    wire clk_100_180;
    wire clk_25_in;        // 25MHz clock divided from 100MHz, for VGA and RV
    wire clk_25_raw;
    wire clk_25;
    wire clk_rv = clk_25;
    wire clk_vga = clk_25;
    wire dcm_locked_12;
    wire dcm_locked_4;
    wire rst_12 = !dcm_locked_4;
    wire rst = !dcm_locked_4;
    reg rst_rv;
    
    IBUFG ibufg_clk_100 (
        .O(clk_100_in),
        .I(CLK_OSC)
    );
    
    DCM_SP #(
        // 100 / 25 * 6 = 24MHz
        .CLKFX_DIVIDE(25),   
        .CLKFX_MULTIPLY(6),
        .CLKIN_DIVIDE_BY_2("FALSE"),          // TRUE/FALSE to enable CLKIN divide by two feature
        .CLKIN_PERIOD(10.0),                  // 100MHz input
        .CLK_FEEDBACK("1X"),
        .CLKOUT_PHASE_SHIFT("NONE"),
        .CLKDV_DIVIDE(4.0),
        .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
        .DLL_FREQUENCY_MODE("LOW"),           // HIGH or LOW frequency mode for DLL
        .DUTY_CYCLE_CORRECTION("TRUE"),       // Duty cycle correction, TRUE or FALSE
        .PHASE_SHIFT(0),                      // Amount of fixed phase shift from -255 to 255
        .STARTUP_WAIT("FALSE")                // Delay configuration DONE until DCM LOCK, TRUE/FALSE
    ) dcm_12 (
        .CLKIN(clk_100_in),                   // Clock input (from IBUFG, BUFG or DCM)
        .CLK0(clk_100_raw),
        .CLK90(clk_100_90_raw),
        .CLK180(clk_100_180_raw),
        .CLKFX(clk_24_raw),                    // DCM CLK synthesis out (M/D)
        .CLKDV(clk_25_in),
        .CLKFB(clk_100),                      // DCM clock feedback
        .PSCLK(1'b0),                         // Dynamic phase adjust clock input
        .PSEN(1'b0),                          // Dynamic phase adjust enable input
        .PSINCDEC(1'b0),                      // Dynamic phase adjust increment/decrement
        .RST(PB),                             // DCM asynchronous reset input
        .LOCKED(dcm_locked_12)
    );
    
    DCM_SP #(
        .CLKFX_DIVIDE(25),   
        .CLKFX_MULTIPLY(12),
        .CLKIN_DIVIDE_BY_2("FALSE"),          // TRUE/FALSE to enable CLKIN divide by two feature
        .CLKIN_PERIOD(40.0),                  // 25 MHz
        .CLK_FEEDBACK("1X"),
        .CLKOUT_PHASE_SHIFT("NONE"),
        .CLKDV_DIVIDE(6.0),
        .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
        .DLL_FREQUENCY_MODE("LOW"),           // HIGH or LOW frequency mode for DLL
        .DUTY_CYCLE_CORRECTION("TRUE"),       // Duty cycle correction, TRUE or FALSE
        .PHASE_SHIFT(0),                      // Amount of fixed phase shift from -255 to 255
        .STARTUP_WAIT("FALSE")                // Delay configuration DONE until DCM LOCK, TRUE/FALSE
    ) dcm_4 (
        .CLKIN(clk_25_in),                    // Clock input (from IBUFG, BUFG or DCM)
        .CLK0(clk_25_raw),
        .CLKFX(clk_12_raw),                   // DCM CLK synthesis out (M/D)
        .CLKFB(clk_25),                       // DCM clock feedback
        .CLKDV(clk_4_raw),
        .PSCLK(1'b0),                         // Dynamic phase adjust clock input
        .PSEN(1'b0),                          // Dynamic phase adjust enable input
        .PSINCDEC(1'b0),                      // Dynamic phase adjust increment/decrement
        .RST(PB),                             // DCM asynchronous reset input
        .LOCKED(dcm_locked_4)
    );
    
    assign clk_24 = clk_24_raw;
    
    assign clk_12 = clk_12_raw;
    
    BUFG bufg_clk_100 (
        .O(clk_100),
        .I(clk_100_raw)
    );
    
    BUFG bufg_clk_100_90 (
        .O(clk_100_90),
        .I(clk_100_90_raw)
    );
    
    BUFG bufg_clk_100_180 (
        .O(clk_100_180),
        .I(clk_100_180_raw)
    );
 
    BUFG bufg_clk_25 (
        .O(clk_25),
        .I(clk_25_raw)
    );
    
    /*reg [1:0] vb_divider;
    always @(posedge clk_25, posedge rst) begin
        if (rst) begin
            vb_divider <= 0;
            clk_4_raw <= 0;
        end
        else 
            if (vb_divider == 0) begin
                vb_divider <= 2'd2;
                clk_4_raw <= ~clk_4_raw;
            end
            else
                vb_divider <= vb_divider - 1;
    end*/
    
    BUFG bufg_clk_4 (
        .O(clk_4),
        .I(clk_4_raw)
    );
    
    // ----------------------------------------------------------------------
    // VerilogBoy core
    
    reg         vb_rst;
    wire        vb_phi;
    wire [15:0] vb_a;
    wire [7:0]  vb_dout;
    wire [7:0]  vb_din;
    wire        vb_wr;
    wire        vb_rd;
    wire        vb_cs;
    reg  [7:0]  vb_key;
    wire        vb_hs;
    wire        vb_vs;
    wire        vb_cpl;
    wire [1:0]  vb_pixel;
    wire        vb_valid;
    wire [15:0] vb_left;
    wire [15:0] vb_right;
    wire        vb_fault;

    boy boy(
        .rst(vb_rst),
        .clk(clk_4),
        .phi(vb_phi),
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
        .done(),
        .fault(vb_fault)
    );
    
    // ----------------------------------------------------------------------
    // MBC5
    wire [22:0] vb_rom_a;
    mbc5 mbc5(
        .vb_clk(clk_4),
        .vb_a(vb_a[15:12]),
        .vb_d(vb_dout),
        .vb_wr(vb_wr),
        .vb_rd(vb_rd),
        .vb_rst(vb_rst),
        .rom_a(vb_rom_a[22:14]),
        .ram_a(),
        .rom_cs_n(),
        .ram_cs_n()
    );
    assign vb_rom_a[13:0] = vb_a[13:0];
    
    // ----------------------------------------------------------------------
    // Audio
    
    // TODO: Implement an ASRC ?
    // DSP mode B
    reg [31:0] a_sr;
    reg a_lrck;
    wire a_dat;
    reg a_bclk;
    reg [1:0] a_state;
    reg [5:0] a_bitcounter;
    
    always @(posedge clk_12, posedge vb_rst) begin
        if (vb_rst) begin
            a_state <= 2'b0;
            a_bitcounter <= 5'd0;
        end
        else begin
            a_state <= a_state + 1;
            case (a_state)
            2'b00: begin
                a_bclk <= 1'b0;
                if (a_bitcounter == 5'd0) begin
                    a_bitcounter <= 5'd31;
                    a_lrck <= 1'b1;
                    a_sr <= {vb_left, vb_right};
                end
                else begin
                    a_bitcounter <= a_bitcounter - 1'd1;
                    a_lrck <= 1'b0;
                    a_sr <= {a_sr[30:0], 1'b0};
                end
            end
            2'b01: begin end
            2'b10: begin
                a_bclk <= 1'b1;
            end
            2'b11: begin end
            endcase
        end
    end
    
    assign a_dat = a_sr[31];
    
    assign AUDIO_MCLK = clk_12;
    assign AUDIO_BCLK = a_bclk;
    assign AUDIO_DACDATA = a_dat;
    assign AUDIO_DACLRCK = a_lrck;
    
    // ----------------------------------------------------------------------
    // MIG
    
    // Access from/ to MIG is non-cached.
    wire       wait_200us;
    wire       sys_rst;
    wire       sys_rst90;
    wire       sys_rst180;
    wire [4:0] delay_sel_val_det;
    reg  [4:0] delay_sel_val;
    
    mig_infrastructure_top mig_infrastructure_top(
        .reset_in_n(!PB),
        .dcm_lock(dcm_locked_12),
        .delay_sel_val1_val(delay_sel_val_det),
        .sys_rst_val(sys_rst),
        .sys_rst90_val(sys_rst90),
        .sys_rst180_val(sys_rst180),
        .wait_200us_rout(wait_200us),
        .clk_int(clk_100),
        .clk90_int(clk_100_90)
    );
    
    wire rst_dqs_div_in;
    
    // Bus master signal from RV
    wire [23:0] rv_ddr_addr;
    wire [31:0] rv_ddr_wdata;
    wire [31:0] rv_ddr_rdata;
    wire [3:0] rv_ddr_wstrb;
    wire rv_ddr_valid;
    wire rv_ddr_ready;
    
    reg [31:0] rv_ddr_rdata_buf;
    reg rv_ddr_ready_buf;
    always @(posedge clk_rv) begin
        rv_ddr_rdata_buf <= rv_ddr_rdata;
        rv_ddr_ready_buf <= rv_ddr_ready;
    end
    
    // Bus master signal after arbitrator
    wire [23:0] ddr_addr;
    wire [31:0] ddr_wdata;
    wire [31:0] ddr_rdata;
    wire [3:0] ddr_wstrb;
    wire ddr_valid;
    wire ddr_ready;
    
    wire auto_ref_req;
    wire [31:0] user_input_data;
    wire [31:0] user_output_data;
    wire user_data_valid;
    wire [22:0] user_input_address;
    wire [2:0] user_command_register;
    wire user_cmd_ack;
    wire [3:0] user_data_mask;
    wire burst_done;
    wire init_done;
    wire ar_done;
    
    mig_top_0 mig_top_0(
        .auto_ref_req          (auto_ref_req),
        .wait_200us            (wait_200us),
        .rst_dqs_div_in        (rst_dqs_div_in),
        .rst_dqs_div_out       (rst_dqs_div_in),
        .user_input_data       (user_input_data),
        .user_output_data      (user_output_data),
        .user_data_valid       (user_data_valid),
        .user_input_address    (user_input_address),
        .user_command_register (user_command_register),
        .user_cmd_ack          (user_cmd_ack),
        .user_data_mask        (user_data_mask),
        .burst_done            (burst_done),
        .init_val              (init_done),
        .ar_done               (ar_done),
        .ddr_dqs               (LPDDR_DQS[1:0]),
        .ddr_dq                (LPDDR_DQ[15:0]),
        .ddr_cke               (LPDDR_CKE),
        .ddr_cs_n              (),
        .ddr_ras_n             (LPDDR_RAS_B),
        .ddr_cas_n             (LPDDR_CAS_B),
        .ddr_we_n              (LPDDR_WE_B),
        .ddr_ba                (LPDDR_BA),
        .ddr_a                 (LPDDR_A),
        .ddr_dm                (LPDDR_DM[1:0]),
/*        .ddr_ck                (),
        .ddr_ck_n              (),*/

        .clk_int               (clk_100),
        .clk90_int             (clk_100_90),
        .delay_sel_val         (delay_sel_val),
        .sys_rst_val           (sys_rst),
        .sys_rst90_val         (sys_rst90),
        .sys_rst180_val        (sys_rst180)
    );

    // upper 16bits are unused
    assign LPDDR_DM[3:2] = 2'b11;
    assign LPDDR_DQS[3:2] = 2'b00;
    assign LPDDR_DQ[31:16] = 16'bz;
    
    // Memory arbiter
    rv_vbc_ddr_arbitrator rv_vbc_ddr_arbitrator(
        .rst(rst),
        .clkrv(clk_100),
        .clkgb(clk_4),
        .rv_addr(rv_ddr_addr),
        .rv_wdata(rv_ddr_wdata),
        .rv_rdata(rv_ddr_rdata),
        .rv_wstrb(rv_ddr_wstrb),
        .rv_valid(rv_ddr_valid),
        .rv_ready(rv_ddr_ready),
        .ddr_addr(ddr_addr),
        .ddr_wdata(ddr_wdata),
        .ddr_rdata(ddr_rdata),
        .ddr_wstrb(ddr_wstrb),
        .ddr_valid(ddr_valid),
        .ddr_ready(ddr_ready),
        .vb_a(vb_rom_a),
        .vb_din(vb_din),
        .vb_dout(vb_dout),
        .vb_rd(vb_rd),
        .vb_wr(1'b0)
    );
    
    mig_picorv_bridge mig_picorv_bridge(
        .clk0(clk_100),
        .clk90(clk_100_90),
        .sys_rst180(sys_rst180),
        .ddr_addr(ddr_addr),
        .ddr_wdata(ddr_wdata),
        .ddr_rdata(ddr_rdata),
        .ddr_wstrb(ddr_wstrb),
        .ddr_valid(ddr_valid),
        .ddr_ready(ddr_ready),
        .auto_refresh_req(auto_ref_req),
        .user_input_data(user_input_data),
        .user_output_data(user_output_data),
        .user_data_valid(user_data_valid),
        .user_input_address(user_input_address),
        .user_command_register(user_command_register),
        .user_cmd_ack(user_cmd_ack),
        .user_data_mask(user_data_mask),
        .burst_done(burst_done),
        .init_done(init_done),
        .ar_done(ar_done)
    );
    
    assign LPDDR_CK_P = clk_100;
    assign LPDDR_CK_N = clk_100_180;
        
    
    // ----------------------------------------------------------------------
    // USB
    
    wire [18:0] usb_addr;
    wire [31:0] usb_wdata;
    wire [31:0] usb_rdata;
    wire [3:0] usb_wstrb;
    wire usb_valid;
    wire usb_ready;
    wire [15:0] usb_din;
    wire [15:0] usb_dout;
    wire bus_dir;
        
    assign USB_CLKIN = clk_12;
    assign USB_HUB_CLKIN = clk_24;
    
    usb_picorv_bridge usb_picorv_bridge(
        .clk(clk_rv),
        .rst(!rst_rv),
        .sys_addr(usb_addr),
        .sys_rdata(usb_rdata),
        .sys_wdata(usb_wdata),
        .sys_wstrb(usb_wstrb),
        .sys_valid(usb_valid),
        .sys_ready(usb_ready),
        .usb_csn(USB_CS_B),
        .usb_rdn(USB_RD_B),
        .usb_wrn(USB_WR_B),
        .usb_a(USB_A),
        .usb_dout(usb_dout),
        .usb_din(usb_din),
        .bus_dir(bus_dir)
    );
    
    // Tristate bus
    // 0 - output, 1 - input 
    assign USB_D = (bus_dir) ? (16'bz) : (usb_dout);
    assign usb_din = USB_D;
    
    // SPI Flash
    // ----------------------------------------------------------------------
    
    // Wires to PicoRV
    wire [16:0] spi_addr;
    wire spi_ready;
    wire [31:0] spi_rdata;
    wire spi_valid;
    
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
    
    spimemio spimemio (
		.clk    (clk_rv),
		.resetn (rst_rv),
		.valid  (spimem_valid),
		.ready  (spimem_ready),
		.addr   ({4'b0, 3'b110, spimem_addr}),
		.rdata  (spimem_rdata),

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
    // PicoRV32
    
    // Memory Map
    // 03000000 - 03000100 GPIO          See description below
    // 03000100 - 03000104 UART          (4B)
    // 04000000 - 04080000 USB           (512KB)
    // 08000000 - 08000FFF Video RAM     (4KB)
    // 0C000000 - 0CFFFFFF LPDDR SDRAM   (16MB)
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
    
    wire la_addr_in_ram = (mem_la_addr >= 32'hFFFF0000);
    wire la_addr_in_vram = (mem_la_addr >= 32'h08000000) && (mem_la_addr < 32'h08004000);
    wire la_addr_in_gpio = (mem_la_addr >= 32'h03000000) && (mem_la_addr < 32'h03000100);
    wire la_addr_in_uart = (mem_la_addr == 32'h03000100);
    wire la_addr_in_usb = (mem_la_addr >= 32'h04000000) && (mem_la_addr < 32'h04080000);
    wire la_addr_in_ddr = (mem_la_addr >= 32'h0C000000) && (mem_la_addr < 32'h0D000000);
    wire la_addr_in_spi = (mem_la_addr >= 32'h0E000000) && (mem_la_addr < 32'h0E020000);
    
    reg addr_in_ram;
    reg addr_in_vram;
    reg addr_in_gpio;
    reg addr_in_uart;
    reg addr_in_usb;
    reg addr_in_ddr;
    reg addr_in_spi;
    
    always@(posedge clk_rv) begin
        addr_in_ram <= la_addr_in_ram;
        addr_in_vram <= la_addr_in_vram;
        addr_in_gpio <= la_addr_in_gpio;
        addr_in_uart <= la_addr_in_uart;
        addr_in_usb <= la_addr_in_usb;
        addr_in_ddr <= la_addr_in_ddr;
        addr_in_spi <= la_addr_in_spi;
    end
    
    wire ram_valid = (mem_valid) && (!mem_ready) && (addr_in_ram);
    wire vram_valid = (mem_valid) && (!mem_ready) && (addr_in_vram);
    wire gpio_valid = (mem_valid) && (!mem_ready) && (addr_in_gpio);
    wire uart_valid = (mem_valid) && (addr_in_uart);
    assign rv_ddr_valid = (mem_valid) && (addr_in_ddr);
    assign usb_valid = (mem_valid) && (addr_in_usb);
    assign spi_valid = (mem_valid) && (addr_in_spi);
    wire general_valid = (mem_valid) && (!mem_ready) && (!addr_in_ddr) && (!addr_in_uart) && (!addr_in_usb) && (!addr_in_spi);
    
    reg default_ready;
    
    always @(posedge clk_rv) begin
        //default_ready <= ram_valid || vram_valid || gpio_valid || usb_valid || uart_valid;
        default_ready <= general_valid;
    end
    
    wire uart_ready;
    assign mem_ready = uart_ready || rv_ddr_ready_buf || usb_ready || spi_ready || default_ready;
    
    reg mem_valid_last;
    always @(posedge clk_rv) begin
        mem_valid_last <= mem_valid;
        if (mem_valid && !mem_valid_last && !(ram_valid || spi_valid || vram_valid || gpio_valid || usb_valid || uart_valid || rv_ddr_valid))
            cpu_irq <= 1'b1;
        //else
        //    cpu_irq <= 1'b0;
        if (!rst_rv)
            cpu_irq <= 1'b0;
    end
    
    assign rv_ddr_addr = mem_addr[23:0];
    assign rv_ddr_wstrb = mem_wstrb;
    assign rv_ddr_wdata = mem_wdata;
    
    assign usb_addr = mem_addr[18:0];
    assign usb_wstrb = mem_wstrb;
    assign usb_wdata = mem_wdata;
    
    assign spi_addr = mem_addr[16:0];
    
    wire rst_rv_pre = !init_done;
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
    
    // UART
    // ----------------------------------------------------------------------
    
    simple_uart simple_uart(
        .clk(clk_rv),
        .rst(!rst_rv),
        .wstrb(uart_valid),
        .ready(uart_ready),
        .dat(mem_wdata[7:0]),
        .txd(VGA_SCL)
    );
    
    // GPIO
    // ----------------------------------------------------------------------
    
    // 03000000 (0) - R:  delay_sel_det / W: delay_sel_val
    // 03000004 (1) - W:  led_green
    // 03000008 (2) - W:  led_red
    // 0300000c (3) - W:  vb_rst
    // 03000010 (4) - W:  vb_keyin
    // 03000014 (5) - W:  i2c_scl
    // 03000018 (6) - RW: i2c_sda
    // 0300001c (7) - W:  usb_rst_n
    
    reg [31:0] gpio_rdata;
    reg led_green;
    reg led_red;
    reg usb_rstn;
    reg i2c_scl;
    reg i2c_sda;
    
    always@(posedge clk_rv) begin
        if (gpio_valid)
             if (mem_wstrb != 0) begin
                case (mem_addr[4:2])
                    3'd0: delay_sel_val[4:0] <= mem_wdata[4:0];
                    3'd1: led_green <= mem_wdata[0];
                    3'd2: led_red <= mem_wdata[0];
                    3'd3: vb_rst <= mem_wdata[0];
                    3'd4: vb_key <= mem_wdata[7:0];
                    3'd5: i2c_scl <= mem_wdata[0];
                    3'd6: i2c_sda <= mem_wdata[0];
                    3'd7: usb_rstn <= mem_wdata[0];
                endcase
             end
             else begin
                case (mem_addr[4:2])
                    3'd0: gpio_rdata <= {27'd0, delay_sel_val_det};
                    3'd6: gpio_rdata <= {31'd0, AUDIO_SDA};
                    default: gpio_rdata <= 32'd0;
                endcase
             end
         if (!rst_rv) begin
            delay_sel_val[4:0] <= delay_sel_val_det[4:0];
            led_green <= 1'b0;
            led_red <= 1'b0;
            vb_key <= 8'd0;
            vb_rst <= 1'b1;
            i2c_scl <= 1'b1;
            i2c_sda <= 1'b1;
        end
    end
    
    assign AUDIO_SCL = i2c_scl;
    assign AUDIO_SDA = (i2c_sda) ? 1'bz : 1'b0;
    
    assign USB_RESET_B = usb_rstn;
    assign USB_HUB_RESET_B = usb_rstn;
    
    assign mem_rdata = 
        (addr_in_ram) ? (ram_rdata) : 
        ((addr_in_ddr) ? (rv_ddr_rdata_buf) : 
        ((addr_in_gpio) ? (gpio_rdata) : 
        ((addr_in_usb) ? (usb_rdata) :
        ((addr_in_spi) ? (spi_rdata) : (32'hFFFFFFFF)))));

    // ----------------------------------------------------------------------
    // VGA Controller
    wire vga_hs;
    wire vga_vs;
    wire [6:0] dbg_x;
    wire [4:0] dbg_y;
    wire [6:0] dbg_char;
    wire dbg_clk;
    
    vga_mixer vga_mixer(
        .clk(clk_vga),
        .rst(rst),
        // GameBoy Image Input
        .gb_hs(vb_hs),
        .gb_vs(vb_vs),
        .gb_pclk(vb_cpl),
        .gb_pdat(vb_pixel),
        .gb_valid(vb_valid),
        .gb_en(!vb_rst),
        // Debugger Char Input
        .dbg_x(dbg_x),
        .dbg_y(dbg_y),
        .dbg_char(dbg_char),
        .dbg_sync(dbg_clk),
        // VGA signal Output
        .vga_hs(vga_hs),
        .vga_vs(vga_vs),
        .vga_blank(VGA_BLANK_B),
        .vga_r(VGA_R),
        .vga_g(VGA_G),
        .vga_b(VGA_B),
        .hold(1'b0)
    );
    
    assign VGA_CLK = ~clk_vga;
    assign VGA_VSYNC = vga_vs;
    assign VGA_HSYNC = vga_hs;
    
    assign VGA_SDA = 1'bz;
    //assign VGA_SCL = 1'bz;
    
    wire vram_wea = (vram_valid && (mem_wstrb != 0)) ? 1'b1 : 1'b0;
    
    wire [7:0] vram_dout;
    wire [11:0] rd_addr = dbg_y * 80 + dbg_x;
    dualport_ram vram(
        .clka(clk_rv),
        .wea(vram_wea),
        .addra(mem_addr[13:2]),
        .dina(mem_wdata[7:0]),
        .clkb(!clk_vga),
        .addrb(rd_addr[11:0]),
        .doutb(vram_dout)
    );
    assign dbg_char = vram_dout[6:0];
    
// synthesis translate_off
    always @(posedge clk_rv) begin
        if (vram_wea) begin
            $display("%c", mem_wdata[7:0]);
        end
    end
// synthesis translate_on
    
    // ----------------------------------------------------------------------
    // LED 
    assign LED_BLUE = 1'b1;
    assign LED_RED = !led_red;
    assign LED_GREEN = !led_green;
    
endmodule
