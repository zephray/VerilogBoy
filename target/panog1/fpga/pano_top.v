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
module pano_top(
    // Global Clock Input
    input wire CLK_OSC,
    
    // IDT Clock Generator
    output wire IDT_ICLK,
    input  wire IDT_CLK1,
    output wire IDT_SCLK,
    output wire IDT_STROBE,
    output wire IDT_DATA,

    // Power LED
    output wire LED_RED,
    output wire LED_GREEN,
    output wire LED_BLUE,
    
    // Push Button
    input  wire PB,

    // SPI Flash
    /*output wire SPI_CS_B,
    output wire SPI_SCK,
    output wire SPI_MOSI,
    input  wire SPI_MISO,*/

    // WM8750 Codec
    /*output wire AUDIO_MCLK,
    output wire AUDIO_BCLK,
    output wire AUDIO_DACDATA,
    output wire AUDIO_DACLRCK,
    input  wire AUDIO_ADCDATA,
    output wire AUDIO_ADCLRCK,
    output wire AUDIO_SCL,
    inout  wire AUDIO_SDA,*/

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
    output wire USB_CLKIN
    /*output wire USB_RESET_B,
    output wire USB_CS_B,
    output wire USB_RD_B,
    output wire USB_WR_B,
    input  wire USB_IRQ,
    output wire [17:1] USB_A,
    inout  wire [15:0] USB_D*/
    );
    
    // ----------------------------------------------------------------------
    // Clocking
    wire clk_100_in;
    wire clk_12_raw;
    wire clk_12;
    wire clk_100_raw;
    wire clk_100;
    wire clk_100_90_raw;
    wire clk_100_90;
    wire clk_100_180_raw;
    wire clk_100_180;
    //wire clk_50_raw;
    //wire clk_50;
    wire clk_vga_in;
    wire clk_vga_raw;
    wire clk_vga;
    //wire clk_vga_2x_raw;
    //wire clk_vga_2x;
    wire clk_vga_90_raw;
    wire clk_vga_90;
    wire clk_rv = clk_100;
    wire dcm_locked_12;
    wire dcm_locked;
    wire rst_12 = !dcm_locked_12;
    wire rst = !dcm_locked;
    
    IBUFG ibufg_clk_100 (
        .O(clk_100_in),
        .I(CLK_OSC)
    );
    
    // DCM for 12MHz USB & Audio Clock
    // The WM8750 can accept 12MHz input
    DCM_SP #(
        // 100 / 25 * 3 = 12MHz
        .CLKFX_DIVIDE(25),   
        .CLKFX_MULTIPLY(3),
        .CLKIN_DIVIDE_BY_2("FALSE"),          // TRUE/FALSE to enable CLKIN divide by two feature
        .CLKIN_PERIOD(10.0),                  // 100MHz input
        .CLK_FEEDBACK("1X"),
        .CLKOUT_PHASE_SHIFT("NONE"),
        .CLKDV_DIVIDE(2.0),
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
        .CLKFX(clk_12_raw),                   // DCM CLK synthesis out (M/D)
        //.CLKDV(clk_50_raw),
        .CLKFB(clk_100),                      // DCM clock feedback
        .PSCLK(1'b0),                         // Dynamic phase adjust clock input
        .PSEN(1'b0),                          // Dynamic phase adjust enable input
        .PSINCDEC(1'b0),                      // Dynamic phase adjust increment/decrement
        .RST(PB),                             // DCM asynchronous reset input
        .LOCKED(dcm_locked_12)
    );
    
    BUFG bufg_clk_12 (
        .O(clk_12),
        .I(clk_12_raw)
    );
    
    /*BUFG bufg_clk_50 (
        .O(clk_50),
        .I(clk_50_raw)
    );*/
    
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
    
    // IDT Clock Synthesizer for VGA Clock
    wire idt_ready;
    idt_clkgen idt_clkgen(
        .clk            (clk_12),
        .rst            (rst_12),

        .idt_iclk       (IDT_ICLK),

        .idt_sclk       (IDT_SCLK),     
        .idt_data       (IDT_DATA),     
        .idt_strobe     (IDT_STROBE),

        .idt_ready      (idt_ready)
    );
    
    IBUFG ibufg_clk_vga_in (
        .O(clk_vga_in),
        .I(IDT_CLK1)
    );
    
    DCM_SP #(
        // 25.175MHz * 2 / 12 = 4.196MHz
        .CLKIN_DIVIDE_BY_2("FALSE"),
        .CLKIN_PERIOD(39.722),
        .CLK_FEEDBACK("1X"),
        .CLKOUT_PHASE_SHIFT("NONE"),      
        .CLKDV_DIVIDE(6.0),
        .CLKFX_DIVIDE(1),
        .CLKFX_MULTIPLY(4),
        .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"),
        .DFS_FREQUENCY_MODE("LOW"),
        .DLL_FREQUENCY_MODE("LOW"),
        .DUTY_CYCLE_CORRECTION("TRUE"),
        .FACTORY_JF(16'hC080),
        .PHASE_SHIFT(0),
        .STARTUP_WAIT("FALSE")
    ) dcm_gb (
        .CLKIN(clk_vga_in),                   // Clock input (from IBUFG, BUFG or DCM)
        .CLK0(clk_vga_raw),
        //.CLK2X(clk_vga_2x_raw),
        .CLK90(clk_vga_90_raw),
        .CLKFB(clk_vga),
        .RST(!idt_ready),
        .LOCKED(dcm_locked),
        .DSSEN(1'b0),
        .PSCLK(1'b0),
        .PSEN(1'b0),
        .PSINCDEC(1'b0)
    );
    
    BUFG bufg_clk_vga (
        .O(clk_vga),
        .I(clk_vga_raw)
    );
    
    BUFG bufg_clk_vga_90 (
        .O(clk_vga_90),
        .I(clk_vga_90_raw)
    );
    
    //BUFG bufg_clk_vga_2x (
    //    .O(clk_vga_2x),
    //    .I(clk_vga_2x_raw)
    //);
    
    // ----------------------------------------------------------------------
    // VerilogBoy core
    
    /*wire        vb_phi;
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
    );*/
	 
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
    
    /*wire        vb_brom_en = 1'b1; // Fixed to enable for now
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
    );*/
    
    // ----------------------------------------------------------------------
    // MIG
    
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
    
    assign LPDDR_DM[3:2] = 2'b11;
    //assign LPDDR_DQS[3:2] = LPDDR_DQS[1:0];
    assign LPDDR_DQS[3:2] = 2'b00;
    assign LPDDR_DQ[31:16] = 16'bz;
    
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
        .ddr_ck                (),
        .ddr_ck_n              (),

        .clk_int               (clk_100),
        .clk90_int             (clk_100_90),
        .delay_sel_val         (delay_sel_val),
        .sys_rst_val           (sys_rst),
        .sys_rst90_val         (sys_rst90),
        .sys_rst180_val        (sys_rst180)
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
        .auto_refresh_req(auto_refresh_req),
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
    // PicoRV32
    
    // Memory Map
    // 00000000 - 000007FF Internal RAM  (2KB)
    // 01000000 - 0103FFFF SPI Flash ROM (256KB)
    // 03000000 - 03000003 LED           (4B)
    // 08000000 - 08000FFF Video RAM     (4KB)
    // 0C000000 - 0BFFFFFF LPDDR SDRAM   (32MB)
    parameter integer MEM_WORDS = 1024;
    parameter [31:0] STACKADDR = (4*MEM_WORDS);      // end of memory
    parameter [31:0] PROGADDR_RESET = 32'h00000000; // start of the RAM
    
    wire mem_valid;
    wire mem_instr;
    reg mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0] mem_wstrb;
    wire [31:0] mem_rdata;
    wire [31:0] mem_la_addr;
    
    wire la_addr_in_ram = (mem_la_addr < 4*MEM_WORDS);
    wire la_addr_in_vram = (mem_la_addr >= 32'h08000000) && (mem_la_addr < 32'h08004000);
    wire la_addr_in_led = (mem_la_addr >= 32'h03000000) && (mem_la_addr < 32'h03000004);
    wire la_addr_in_ddr = (mem_la_addr >= 32'h0C000000) && (mem_la_addr < 32'h0D000000);
    
    reg addr_in_ram;
    reg addr_in_vram;
    reg addr_in_led;
    reg addr_in_ddr;
    
    always@(posedge clk_rv) begin
        addr_in_ram <= la_addr_in_ram;
        addr_in_vram <= la_addr_in_vram;
        addr_in_led <= la_addr_in_led;
        addr_in_ddr <= la_addr_in_ddr;
    end
    
    always @(posedge clk_rv) begin
        mem_ready <= (la_addr_in_ddr) ? (ddr_ready) : (mem_valid);
    end
    
    wire ram_valid = (mem_valid) && (!mem_ready) && (addr_in_ram);
    wire vram_valid = (mem_valid) && (!mem_ready) && (addr_in_vram);
    wire led_valid = (mem_valid) && (!mem_ready) && (addr_in_led);
    assign ddr_valid = (mem_valid) && (addr_in_ddr);
    
    assign ddr_addr = mem_addr[23:0];
    assign ddr_wstrb = mem_wstrb;
    assign ddr_wdata = mem_wdata;
    
    wire rst_rv_pre = !init_done;
    reg rst_rv;
    reg [3:0] rst_counter;
    
    always @(posedge clk_rv)
    begin
        if (rst_rv_pre) begin
            rst_rv <= 0;
            rst_counter <= 4'd0;
        end
        else begin
            if (rst_counter == 4'd15)
                rst_rv <= 1;
            else
                rst_counter <= rst_counter + 1;
        end
    end
    
    picorv32 #(
        .STACKADDR(STACKADDR),
        .PROGADDR_RESET(PROGADDR_RESET)
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
        .mem_la_addr(mem_la_addr)
    );
    
    wire [31:0] ram_rdata;
    picosoc_mem #(
        .WORDS(MEM_WORDS)
    ) memory (
        .clk(clk_rv),
        .wen(ram_valid ? mem_wstrb : 4'b0),
        .addr(mem_addr[23:2]),
        .wdata(mem_wdata),
        .rdata(ram_rdata)
    );
    
    assign mem_rdata = (addr_in_ram) ? (ram_rdata) : ((addr_in_ddr) ? (ddr_rdata) : ((addr_in_led) ? ({27'b0, delay_sel_val_det}) : (32'hFFFFFFFF)));

    always@(posedge clk_rv) begin
        if (!rst_rv)
            delay_sel_val[4:0] <= delay_sel_val_det[4:0];
        else if (led_valid && (mem_wstrb != 0))
            delay_sel_val[4:0] <= mem_wdata[4:0];
    end

    // ----------------------------------------------------------------------
    // VGA Controller
    wire vga_hs;
    wire vga_vs;
    wire [6:0] dbg_x;
    wire [4:0] dbg_y;
    wire [6:0] dbg_char;
    
    vga_mixer vga_mixer(
        .clk(clk_vga),
        .rst(rst),
        // GameBoy Image Input
        .gb_hs(1'b0),
        .gb_vs(1'b0),
        .gb_pclk(1'b0),
        .gb_pdat(2'b00),
        .gb_valid(1'b0),
        .gb_en(1'b0),
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
    
    assign VGA_CLK = clk_vga_90;
    assign VGA_VSYNC = vga_vs;
    assign VGA_HSYNC = vga_hs;
    //assign VGA_VSYNC = 1'b1;
    //assign VGA_HSYNC = 1'b1;
    //assign VGA_VSYNC = clk_vga_in;
    //assign VGA_HSYNC = clk_vga;
    
    assign VGA_SCL = 1'bz;
    assign VGA_SDA = 1'bz;
    
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
    // USB
    assign USB_CLKIN = clk_12;
    
    // ----------------------------------------------------------------------
    // LED
    //reg led;
    
    
    
    assign LED_RED = init_done;
    assign LED_BLUE = dcm_locked_12;
    //assign LED_GREEN = !led;
    assign LED_GREEN = 1'b0;
    

endmodule
