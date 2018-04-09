`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   23:55:03 04/07/2018
// Design Name:   sound
// Module Name:   C:/Users/ZephRay/Documents/GitHub/GameBoy/Verilog/GameBoy/sound_test.v
// Project Name:  GameBoy
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: sound
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module sound_test;

	// Inputs
	wire clk;
	reg clk_audio;
	reg rst;
	reg [15:0] a;
	reg [7:0] din;
	reg rd;
	reg wr;

	// Outputs
	wire [7:0] dout;
	wire [19:0] left;
	wire [19:0] right;

	// Instantiate the Unit Under Test (UUT)
	sound uut (
		.clk(clk), 
		.clk_audio(clk_audio), 
		.rst(rst), 
		.a(a), 
		.dout(dout), 
		.din(din), 
		.rd(rd), 
		.wr(wr), 
		.left(left), 
		.right(right)
	);

    clk_gen #(250) clk_gen_1(clk);

	initial begin
		// Initialize Inputs
		clk_audio = 0;
		rst = 0;
		a = 0;
		din = 0;
		rd = 0;
		wr = 0;

		// Wait 100 ns for global reset to finish
		#10000;
        rst = 1;
        #10000;
        rst = 0;
        #10000;
        
        a = 16'hFF26;
        din = 8'h80;
        wr = 1;
        #10000;
        wr = 0;
        #10000;
        
        a = 16'hFF11;
        din = 8'h80;
        wr = 1;
        #10000;
        wr = 0;
        #10000;
        
        a = 16'hFF12;
        din = 8'hF3;
        wr = 1;
        #10000;
        wr = 0;
        #10000;
        
        a = 16'hFF25;
        din = 8'hF3;
        wr = 1;
        #10000;
        wr = 0;
        #10000;
        
        a = 16'hFF24;
        din = 8'h77;
        wr = 1;
        #10000;
        wr = 0;
        #10000;
        
        a = 16'hFF13;
        din = 8'h83;
        wr = 1;
        #10000;
        wr = 0;
        #10000;
        
        /*a = 16'hFF14;
        din = 8'h87;
        wr = 1;
        #10000;
        wr = 0;
        #10000;*/
        
        a = 16'hFF21;
        din = 8'h98; // Vol 1001 Inc No Env
        wr = 1;
        #10000;
        wr = 0;
        #10000;
        
        a = 16'hFF22;
        din = 8'h34; // s = 3 15-b r = 4
        wr = 1;
        #10000;
        wr = 0;
        #10000;
        
        a = 16'hFF23;
        din = 8'hBF; // Initiated
        wr = 1;
        #10000;
        wr = 0;
        #10000;
        
        a = 16'hFF1C;
        din = 8'h01;
        wr = 1;
        #10000;
        wr = 0;
        #10000;
        
        a = 16'hFF1D;
        din = 8'hFF;
        wr = 1;
        #10000;
        wr = 0;
        #10000;
        
        a = 16'hFF1E;
        din = 8'h87; // Initiated
        wr = 1;
        #10000;
        wr = 0;
        #10000;
        
		// Add stimulus here

	end
      
endmodule

