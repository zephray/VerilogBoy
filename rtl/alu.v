`timescale 1ns / 1ps
`default_nettype wire
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    17:30:26 02/08/2018 
// Module Name:    alu
// Project Name:   VerilogBoy
// Description: 
//   The Game Boy ALU.
// Dependencies: 
// 
// Additional Comments: 
//   
//////////////////////////////////////////////////////////////////////////////////

module alu(
    input [7:0] alu_a,
    input [7:0] alu_b,
    output [7:0] alu_result,
    input [3:0] alu_flags_in,
    output [3:0] alu_flags_out
    input [5:0] alu_op
)