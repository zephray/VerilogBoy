`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:24:07 11/13/2013 
// Design Name: 
// Module Name:    x4_dcm 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module x2_dcm(
  output x2_clk,
  output ready,
  input clk100,
  input rst //asynchronous active High reset
);
   
  wire locked, clk0, clk2x;
  
  assign ready = locked;

  BUFG CLK2X_BUFG_INST (.I(clk2x),
                 .O(x2_clk));
                 
  DCM_BASE DCM_2X_INST (.CLKIN(clk100),
                 .CLKFB(clk0),
                 .CLK0(clk0),
                 .RST(rst),
                 .CLK2X(clk2x),
                 .LOCKED(locked));
                 
  defparam DCM_2X_INST.CLK_FEEDBACK = "1X";
  //defparam DCM_SP_INST.CLKDV_DIVIDE = 4;
  //defparam DCM_SP_INST.CLKIN_DIVIDE_BY_2 = "FALSE";
  defparam DCM_2X_INST.CLKIN_PERIOD = 10.000;
  defparam DCM_2X_INST.CLKOUT_PHASE_SHIFT = "NONE";
  defparam DCM_2X_INST.DESKEW_ADJUST = "SYSTEM_SYNCHRONOUS";
  defparam DCM_2X_INST.DFS_FREQUENCY_MODE = "LOW";
  defparam DCM_2X_INST.DLL_FREQUENCY_MODE = "LOW";
  defparam DCM_2X_INST.DUTY_CYCLE_CORRECTION = "TRUE";
  defparam DCM_2X_INST.FACTORY_JF = 16'hF0F0;
  defparam DCM_2X_INST.PHASE_SHIFT = 0;
  defparam DCM_2X_INST.STARTUP_WAIT = "TRUE";

endmodule
