`timescale 1ns / 1ps
`default_nettype wire
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    17:30:26 02/08/2018 
// Module Name:    boy 
// Project Name:   VerilogBoy
// Description: 
//   VerilogBoy portable top level file. This is the file connect the CPU and 
//   all the peripherals in the LR35902 together.
// Dependencies: 
//   cpu
// Additional Comments: 
//   Hardware specific code should be implemented outside of this file
//   So normally in an implementation, this will not be the top level.
////////////////////////////////////////////////////////////////////////////////

module boy(
    input rst, // Async Reset Input
    input clk, // 4.19MHz Clock Input
    output phi, // 1.05MHz Reference Clock Output
    // Cartridge interface
    output reg [15:0] a, // Address Bus
    output reg [7:0] dout,  // Data Bus
    input  [7:0] din,
    output reg wr, // Write Enable
    output reg rd, // Read Enable
    output reg cs, // External RAM Chip Select
    // Keyboard input
    /* verilator lint_off UNUSED */
    input [7:0] key,
    /* verilator lint_on UNUSED */
    // LCD output
    output hs, // Horizontal Sync Output
    output vs, // Vertical Sync Output
    output cpl, // Pixel Data Latch
    output [1:0] pixel, // Pixel Data
    output valid,
    // Sound output
    output [15:0] left,
    output [15:0] right,
    // Debug interface
    output done
    );
    
    // CPU
    wire        cpu_rd;            // CPU Read Enable
    wire        cpu_wr;            // CPU Write Enable
    reg  [7:0]  cpu_din;           // CPU Data Bus, to CPU
    wire [7:0]  cpu_dout;          // CPU Data Bus, from CPU
    wire [15:0] cpu_a;             // CPU Address Bus
    wire [4:0]  cpu_int_en;        // CPU Interrupt Enable input
    wire [4:0]  cpu_int_flags_in;  // CPU Interrupt Flags input
    wire [4:0]  cpu_int_flags_out; // CPU Interrupt Flags output
    
    cpu cpu(
        .clk(clk),
        .rst(rst),
        .phi(phi),
        .a(cpu_a),
        .dout(cpu_dout),
        .din(cpu_din),
        .rd(cpu_rd),
        .wr(cpu_wr),
        .int_en(cpu_int_en),
        .int_flags_in(cpu_int_flags_in),
        .int_flags_out(cpu_int_flags_out),
        .key_in(key),
        .done(done));
        
    // High RAM
    reg [7:0] high_ram [0:127];
    reg high_ram_rd;
    reg high_ram_wr;
    reg [6:0] high_ram_a;
    reg [7:0] high_ram_din;
    reg [7:0] high_ram_dout;
    always @(posedge clk) begin
        if (high_ram_wr)
            high_ram[high_ram_a] <= high_ram_din;
        else
            high_ram_dout <= (high_ram_rd) ? high_ram[high_ram_a] : 8'bx;
    end

    // Interrupt
    // int_req is the request signal from peripherals.
    // When an interrupt is generated, the peripheral should send a pulse on
    // the int_req for exactly one clock (using 4MHz clock).
    wire [4:0] int_req;
    
    wire int_tim_req = 0;
    wire int_tim_ack;
    wire int_lcdc_req;
    wire int_lcdc_ack;
    wire int_vblank_req;
    wire int_vblank_ack;

    assign int_req[2] = int_tim_req;
    assign int_req[1] = int_lcdc_req;
    assign int_req[0] = int_vblank_req;

    /* -- DEBUG -- */
    assign int_req = 5'd0;

    //reg reg_ie_rd;
    reg reg_ie_wr;
    reg [4:0] reg_ie;
    reg [4:0] reg_ie_din;
    wire [4:0] reg_ie_dout;
    always @(posedge clk) begin
        if (reg_ie_wr)
            reg_ie <= reg_ie_din;
    end

    assign reg_ie_dout = reg_ie;
    assign cpu_int_en = reg_ie_dout;

    // Interrupt may be manually triggered
    // int_req should only stay high for only 1 cycle for each interrupt
    //reg reg_if_rd;
    reg reg_if_wr;
    reg [4:0] reg_if;
    reg [4:0] reg_if_din;
    wire [4:0] reg_if_dout;
    always @(posedge clk) begin
        if (reg_if_wr)
            reg_if <= reg_if_din | int_req;
        else
            reg_if <= cpu_int_flags_out | int_req;
    end
    assign reg_if_dout = reg_if | int_req;
    assign cpu_int_flags_in = reg_if_dout;

    assign int_tim_ack = reg_if[2];
    assign int_lcdc_ack = reg_if[1];
    assign int_vblank_ack = reg_if[0];

    // PPU
    wire [7:0] ppu_dout;

    ppu ppu(
        .clk(clk),
        .rst(rst),
        .a(cpu_a),
        .dout(ppu_dout), // VRAM & OAM RW goes through PPU
        .din(cpu_dout),
        .rd(cpu_rd), 
        .wr(cpu_wr),
        .int_vblank_req(int_vblank_req),
        .int_lcdc_req(int_lcdc_req),
        .int_vblank_ack(int_vblank_ack),
        .int_lcdc_ack(int_lcdc_ack),
        .cpl(cpl), // Pixel clock
        .pixel(pixel), // Pixel Data (2bpp)
        .valid(valid),
        .hs(hs), // Horizontal Sync, Low Active
        .vs(vs)  // Vertical Sync, Low Active
    );

    // Bus Multiplexing
    always @(*) begin
        wr = 1'b0;
        rd = 1'b0;
        a = cpu_a; // The address is always exposed
        dout = 8'h00; // But the data will be masked when accessing high page
        cpu_din = 8'hxx; // Should not happen
        reg_ie_wr = 1'b0;
        reg_ie_din = 5'hxx;
        high_ram_rd = 1'b0;
        high_ram_wr = 1'b0;
        high_ram_a = cpu_a[6:0];
        high_ram_din = 8'hxx;
        if (cpu_a == 16'hffff) begin  // 0xFFFF - IE
            //reg_ie_rd = cpu_rd;
            reg_ie_wr = cpu_wr;
            reg_ie_din = cpu_dout[4:0];
            cpu_din = {3'b0, reg_ie_dout};
        end
        else if (cpu_a == 16'hff0f) begin // 0xFF0F - IF
            //reg_if_rd = cpu_rd;
            reg_if_wr = cpu_wr;
            reg_if_din = cpu_dout[4:0];
            cpu_din = {3'b0, reg_if_dout};
        end
        if (cpu_a >= 16'hff80) begin
            high_ram_rd = cpu_rd;
            high_ram_wr = cpu_wr;
            high_ram_din = cpu_dout;
            cpu_din = high_ram_dout;
        end
        if ((cpu_a >= 16'hff40 && cpu_a <= 16'hff4b && cpu_a != 16'hff46) ||
            (cpu_a >= 16'h8000 && cpu_a <= 16'h9fff) ||
            (cpu_a >= 16'hfe00 && cpu_a <= 16'hfe9f)) begin
            cpu_din = ppu_dout;
        end
        else begin
            rd = cpu_rd;
            wr = cpu_wr;
            dout = cpu_dout;
            cpu_din = din;
        end
        cs = wr | rd;
    end

    // Disable unused signals
    assign hs = 0;
    assign vs = 0;
    assign cpl = 0;
    assign pixel = 0;
    assign valid = 0;
    assign left = 0;
    assign right = 0;

endmodule
