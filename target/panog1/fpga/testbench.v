`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:29:30 02/21/2019
// Design Name:   pano_top
// Module Name:   C:/Users/Wenting/Documents/GitHub/VerilogBoy/target/panog1/fpga/top_testbench.v
// Project Name:  panog1
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: pano_top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module testbench;

	// Inputs
	reg CLK_OSC;
	reg IDT_CLK1;
	reg PB;

	// Outputs
	wire IDT_ICLK;
	wire IDT_SCLK;
	wire IDT_STROBE;
	wire IDT_DATA;
	wire LED_RED;
	wire LED_GREEN;
	wire LED_BLUE;
	wire [11:0] LPDDR_A;
	wire LPDDR_CK_P;
	wire LPDDR_CK_N;
	wire LPDDR_CKE;
	wire LPDDR_WE_B;
	wire LPDDR_CAS_B;
	wire LPDDR_RAS_B;
	wire [3:0] LPDDR_DM;
	wire [1:0] LPDDR_BA;
	wire VGA_CLK;
	wire VGA_VSYNC;
	wire VGA_HSYNC;
	wire VGA_BLANK_B;
	wire [7:0] VGA_R;
	wire [7:0] VGA_G;
	wire [7:0] VGA_B;
	wire USB_CLKIN;

	// Bidirs
	wire [31:0] LPDDR_DQ;
	wire [3:0] LPDDR_DQS;
	wire VGA_SCL;
	wire VGA_SDA;

	// Instantiate the Unit Under Test (UUT)
	pano_top uut (
		.CLK_OSC(CLK_OSC), 
		.IDT_ICLK(IDT_ICLK), 
		.IDT_CLK1(IDT_CLK1), 
		.IDT_SCLK(IDT_SCLK), 
		.IDT_STROBE(IDT_STROBE), 
		.IDT_DATA(IDT_DATA), 
		.LED_RED(LED_RED), 
		.LED_GREEN(LED_GREEN), 
		.LED_BLUE(LED_BLUE), 
		.PB(PB), 
		.LPDDR_A(LPDDR_A), 
		.LPDDR_CK_P(LPDDR_CK_P), 
		.LPDDR_CK_N(LPDDR_CK_N), 
		.LPDDR_CKE(LPDDR_CKE), 
		.LPDDR_WE_B(LPDDR_WE_B), 
		.LPDDR_CAS_B(LPDDR_CAS_B), 
		.LPDDR_RAS_B(LPDDR_RAS_B), 
		.LPDDR_DM(LPDDR_DM), 
		.LPDDR_BA(LPDDR_BA), 
		.LPDDR_DQ(LPDDR_DQ), 
		.LPDDR_DQS(LPDDR_DQS), 
		.VGA_CLK(VGA_CLK), 
		.VGA_VSYNC(VGA_VSYNC), 
		.VGA_HSYNC(VGA_HSYNC), 
		.VGA_BLANK_B(VGA_BLANK_B), 
		.VGA_SCL(VGA_SCL), 
		.VGA_SDA(VGA_SDA), 
		.VGA_R(VGA_R), 
		.VGA_G(VGA_G), 
		.VGA_B(VGA_B), 
		.USB_CLKIN(USB_CLKIN)
	);
    
    mobile_ddr mobile_ddr
    (
        .Dq    (LPDDR_DQ),
        .Dqs   (LPDDR_DQS),
        .Addr  (LPDDR_A),
        .Ba    (LPDDR_BA),
        .Clk   (LPDDR_CK_P),
        .Clk_n (LPDDR_CK_N),
        .Cke   (LPDDR_CKE),
        .Cs_n  (1'b0),
        .Ras_n (LPDDR_RAS_B),
        .Cas_n (LPDDR_CAS_B),
        .We_n  (LPDDR_WE_B),
        .Dm    (LPDDR_DM)
    );

	initial begin
		// Initialize Inputs
		CLK_OSC = 0;
		IDT_CLK1 = 0;
		PB = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
        PB = 1;
	end
    
    always
        #5 CLK_OSC = !CLK_OSC;
endmodule

