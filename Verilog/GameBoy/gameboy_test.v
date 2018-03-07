`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   18:39:46 02/17/2018
// Design Name:   gameboy
// Module Name:   C:/Users/ZephRay/Documents/GitHub/GameBoy/Verilog/GameBoy/gameboy_test.v
// Project Name:  GameBoy
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: gameboy
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////
`default_nettype wire

module gameboy_test;

	// Inputs
	reg rst;
	wire clk;
	wire clk_mem;
	reg [7:0] key;
	reg [15:0] bp_addr;
	reg bp_step;
	reg bp_continue;

	// Outputs
	wire [15:0] a;
	wire [7:0] d;
	wire wr;
	wire rd;
	wire cs;
	wire hs;
	wire vs;
	wire cpl;
	wire [1:0] pixel;
	wire valid;
	wire halt;
	wire debug_halt;
	wire [7:0] A_data;
	wire [7:0] F_data;
	wire [4:0] IE_data;
	wire [4:0] IF_data;
	wire [7:0] high_mem_data;
	wire [15:0] high_mem_addr;
	wire [7:0] instruction;
	wire [79:0] regs_data;

	// Instantiate the Unit Under Test (UUT)
	gameboy uut (
		.rst(rst), 
		.clk(clk), 
		.clk_mem(clk_mem), 
		.a(a), 
		.dout(d),
        .din(8'hFF),
		.wr(wr), 
		.rd(rd), 
		.cs(cs), 
		.key(key), 
		.hs(hs), 
		.vs(vs), 
		.cpl(cpl), 
		.pixel(pixel), 
		.valid(valid), 
		.halt(halt), 
		.debug_halt(debug_halt), 
		.A_data(A_data), 
		.F_data(F_data), 
		.IE_data(IE_data), 
		.IF_data(IF_data), 
		.high_mem_data(high_mem_data), 
		.high_mem_addr(high_mem_addr), 
		.instruction(instruction), 
		.regs_data(regs_data), 
		.bp_addr(bp_addr), 
		.bp_step(bp_step), 
		.bp_continue(bp_continue)
	);
    
    
    
    clk_gen #(250) clk_gen_1(clk);
    clk_gen #(62.5) clk_gen_2(clk_mem);

	initial begin
		// Initialize Inputs
		rst = 0;
		key = 0;
		bp_addr = 16'h8000;
		bp_step = 0;
		bp_continue = 0;

		// Reset
		#100;
        rst = 1;
        #100;
        rst = 0;
        #100;
        
		// Add stimulus here

	end
      
endmodule

module clk_gen(output reg clk);

	parameter period = 250;
	
	initial clk = 0;
	
	always begin
		#(period/2);
		clk = ~clk;
	end
	
endmodule
