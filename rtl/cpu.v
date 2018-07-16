`timescale 1ns / 1ps
`default_nettype wire
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    17:30:26 02/08/2018 
// Module Name:    cpu
// Project Name:   VerilogBoy
// Description: 
//   The Game Boy CPU.
// Dependencies: 
// 
// Additional Comments: 
//   
//////////////////////////////////////////////////////////////////////////////////

module cpu(
    input clk,
    input rst,
    output phi,
    output reg [15:0] a,
    output reg [7:0] dout,
    input [7:0] din,
    output rd,
    output wr
    );

endmodule

