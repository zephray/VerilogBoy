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
    input [7:0] key,
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
    
    // Bus & Memory Signals
    wire [15:0] soc_a;     // SoC Internal Address Bus
    wire [7:0]  soc_din;   // SoC Internal Data Bus, Slave to Master
    wire [7:0]  soc_dout;  // SoC Internal Data Bus, Master to Slave

    wire soc_wr; // SoC Bus Master Memory Write Enable
    wire soc_rd; // SoC Bus Master Memory Read Enable

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
    assign soc_wr = cpu_wr;
    assign soc_rd = cpu_rd;
    assign soc_din[7:0] = cpu_din[7:0];
    assign soc_dout[7:0] = cpu_dout[7:0];
    assign soc_a[15:0] = cpu_a[15:0];


endmodule
