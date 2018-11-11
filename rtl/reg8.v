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

module reg8(
    input clk,
    input rst,
    input [7:0] wr,
    output [7:0] rd,
    input we
    );

    reg [7:0] data;

    assign rd = data;

    always @(posedge clk, posedge rst) begin
        if (rst)
            data <= 8'b0;
        else
            if (we)
                data <= wr;
    end

endmodule
