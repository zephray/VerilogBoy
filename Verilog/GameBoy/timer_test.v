`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   14:34:25 04/18/2018
// Design Name:   timer
// Module Name:   C:/Users/ZephRay/Documents/GitHub/GameBoy/Verilog/GameBoy/timer_test.v
// Project Name:  GameBoy
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: timer
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module timer_test;

	// Inputs
	wire clk;
	reg rst;
	reg [15:0] a;
	reg [7:0] din;
	reg rd;
	reg wr;
	reg int_tim_ack;

	// Outputs
	wire [7:0] dout;
	wire int_tim_req;
    
    clk_gen #(250) clk_gen_1(clk);

	// Instantiate the Unit Under Test (UUT)
	timer uut (
		.clk(clk), 
		.rst(rst), 
		.a(a), 
		.dout(dout), 
		.din(din), 
		.rd(rd), 
		.wr(wr), 
		.int_tim_req(int_tim_req), 
		.int_tim_ack(int_tim_ack)
	);

	initial begin
		// Initialize Inputs
		rst = 0;
		a = 0;
		din = 0;
		rd = 0;
		wr = 0;
		int_tim_ack = 0;

		#10000;
        rst = 1;
        #10000;
        rst = 0;
        #10000;
        
		// Add stimulus here
        a = 16'hFF06;// TMA
        din = 8'hC5; // 1100 0101
        wr = 1;
        #10000;
        wr = 0;
        #10000;
        
        a = 16'hFF07;// TAC
        din = 8'hFC; // 1111 1100
        wr = 1;
        #10000;
        wr = 0;
        #10000;
	end
      
endmodule

