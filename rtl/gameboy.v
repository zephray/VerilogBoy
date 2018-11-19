`timescale 1ns / 1ps
`default_nettype wire
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    17:30:26 02/08/2018 
// Module Name:    gameboy 
// Project Name:   VerilogBoy
// Description: 
//   Gameboy main file. This is the file connect the CPU and all the peripherals
//   in the LR35902 together.
// Dependencies: 
//   cpu
// Additional Comments: 
//   Hardware specific code should be implemented outside of this file
//////////////////////////////////////////////////////////////////////////////////

module gameboy(
    input rst, // Async Reset Input
    input clk, // 4.19MHz Clock Input
	output phi, // 1.05MHz Reference Clock Output
    // Cartridge interface
    output [15:0] a, // Address Bus
    output [7:0] dout,  // Data Bus
    input  [7:0] din,
    output wr, // Write Enable
    output rd, // Read Enable
    output cs, // External RAM Chip Select
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
    output [19:0] left,
    output [19:0] right
    );
    
    // CPU
    wire        cpu_wr;   // CPU Write Enable
    wire        cpu_rd;   // CPU Read Enable
    wire [7:0]  cpu_din;  // CPU Data Bus, to CPU
    wire [7:0]  cpu_dout; // CPU Data Bus, from CPU
    wire [15:0] cpu_a;    // CPU Address Bus
    
    cpu cpu(
        .clk(clk),
        .rst(rst),
        .phi(phi),
        .a(cpu_a),
        .dout(cpu_dout),
        .din(cpu_din),
        .rd(cpu_wr),
        .wr(cpu_rd));
        
        
    // Bus Multiplexing
    // Currently CPU is the only bus master
    assign wr = cpu_wr;
    assign rd = cpu_rd;
    assign cpu_din[7:0] = din[7:0];
    assign dout[7:0] = cpu_dout[7:0];
    assign a[15:0] = cpu_a[15:0];
    assign cs = cpu_wr | cpu_rd;

    // Disable unused signals
    assign hs = 0;
    assign vs = 0;
    assign cpl = 0;
    assign pixel = 0;
    assign valid = 0;
    assign left = 0;
    assign right = 0;

endmodule
