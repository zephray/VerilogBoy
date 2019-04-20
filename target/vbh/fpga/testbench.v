`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:56:59 04/17/2019
// Design Name:   vbh_top
// Module Name:   C:/Users/Wenting/Documents/GitHub/VerilogBoy/target/vbh/fpga/testbench.v
// Project Name:  fpga
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: vbh_top
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
	reg CLK_IN;
	wire SPI_MISO;
	reg LCD_TE;

	// Outputs
	wire [21:0] RAM_A;
	wire RAM_LB_N;
	wire RAM_UB_N;
	wire RAM_OE_N;
	wire RAM_CE_N;
	wire RAM_WE_N;
	wire RAM_ZZ_N;
	wire SPI_CS_B;
	wire SPI_SCK;
	wire SPI_MOSI;
	wire PMU_SCK;
	wire BL_EN;
	wire BL_PWM;
	wire LCD_RESET;
	wire LCD_D_LP_P;
	wire LCD_D_LP_N;
	wire LCD_D_HS_P;
	wire LCD_D_HS_N;
	wire LCD_C_LP_P;
	wire LCD_C_LP_N;
	wire LCD_C_HS_P;
	wire LCD_C_HS_N;

	// Bidirs
	wire [15:0] RAM_DQ;
	wire PMU_SDA;

	// Instantiate the Unit Under Test (UUT)
	vbh_top uut (
		.CLK_IN(CLK_IN), 
		.RAM_DQ(RAM_DQ), 
		.RAM_A(RAM_A), 
		.RAM_LB_N(RAM_LB_N), 
		.RAM_UB_N(RAM_UB_N), 
		.RAM_OE_N(RAM_OE_N), 
		.RAM_CE_N(RAM_CE_N), 
		.RAM_WE_N(RAM_WE_N), 
		.RAM_ZZ_N(RAM_ZZ_N), 
		.SPI_CS_B(SPI_CS_B), 
		.SPI_SCK(SPI_SCK), 
		.SPI_MOSI(SPI_MOSI), 
		.SPI_MISO(SPI_MISO), 
		.PMU_SCK(PMU_SCK), 
		.PMU_SDA(PMU_SDA), 
		.BL_EN(BL_EN), 
		.BL_PWM(BL_PWM), 
		.LCD_TE(LCD_TE), 
		.LCD_RESET(LCD_RESET), 
		.LCD_D_LP_P(LCD_D_LP_P), 
		.LCD_D_LP_N(LCD_D_LP_N), 
		.LCD_D_HS_P(LCD_D_HS_P), 
		.LCD_D_HS_N(LCD_D_HS_N), 
		.LCD_C_LP_P(LCD_C_LP_P), 
		.LCD_C_LP_N(LCD_C_LP_N), 
		.LCD_C_HS_P(LCD_C_HS_P), 
		.LCD_C_HS_N(LCD_C_HS_N)
	);
    
    spiflash spiflash (
        .csb(SPI_CS_B),
        .clk(SPI_SCK),
        .io0(SPI_MOSI), // MOSI
        .io1(SPI_MISO), // MISO
        .io2(),
        .io3()
    );

	initial begin
		// Initialize Inputs
		CLK_IN = 0;
		LCD_TE = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
    
    always begin
        #20 CLK_IN = !CLK_IN;
    end
      
endmodule

