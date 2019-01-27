`timescale 1ns / 1ps
`default_nettype wire
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Module Name:    reg
// Project Name:   VerilogBoy
// Description: 
//   The register file of Game Boy CPU.
// Dependencies: 
// 
// Additional Comments: 
//  Single 8-bit register
//////////////////////////////////////////////////////////////////////////////////

module singlereg(clk, rst, wr, rd, we);
    parameter WIDTH = 8;

    input clk;
    input rst;
    input [WIDTH-1:0] wr;
    output [WIDTH-1:0] rd;
    input we;

    reg [WIDTH-1:0] data;

    assign rd = data;

    always @(posedge clk, posedge rst) begin
        if (rst)
            data <= 0;
        else
            if (we)
                data <= wr;
    end

endmodule
