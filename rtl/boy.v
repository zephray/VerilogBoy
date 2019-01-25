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
    wire        cpu_rd;   // CPU Read Enable
    wire        cpu_wr;   // CPU Write Enable
    reg  [7:0]  cpu_din;  // CPU Data Bus, to CPU
    wire [7:0]  cpu_dout; // CPU Data Bus, from CPU
    wire [15:0] cpu_a;    // CPU Address Bus
    
    cpu cpu(
        .clk(clk),
        .rst(rst),
        .phi(phi),
        .a(cpu_a),
        .dout(cpu_dout),
        .din(cpu_din),
        .rd(cpu_rd),
        .wr(cpu_wr),
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
            high_ram_dout <= (high_ram_rd) ? high_ram[high_ram_a] : 8'bz;
    end
        
    // Bus Multiplexing
    always @(*) begin
        wr = 1'b0;
        rd = 1'b0;
        a = cpu_a; // The address is always exposed
        dout = 8'h00; // But the data will be masked when accessing high page
        cpu_din = 8'hxx; // Should not happen
        high_ram_rd = 1'b0;
        high_ram_wr = 1'b0;
        high_ram_a = cpu_a[6:0];
        high_ram_din = 8'hxx;
        if ((cpu_a >= 16'hff80) && (cpu_a <= 16'hffff)) begin
            high_ram_rd = cpu_rd;
            high_ram_wr = cpu_wr;
            high_ram_din = cpu_dout;
            cpu_din = high_ram_dout;
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
