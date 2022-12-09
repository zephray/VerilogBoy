`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    21:19:04 04/08/2018 
// Module Name:    edgedet
// Project Name:   VerilogBoy
// Description: 
//
// Dependencies: 
//
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module edgedet(
    input wire clk,
    input wire i,
    output wire o
);

    reg last_i;
    always @(posedge clk)
        last_i <= i;
    assign o = (!last_i) && i;

endmodule
