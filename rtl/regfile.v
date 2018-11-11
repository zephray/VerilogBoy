`timescale 1ns / 1ps
`default_nettype wire
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Module Name:    regfile
// Project Name:   VerilogBoy
// Description: 
//   The register file of Game Boy CPU.
// Dependencies: 
// 
// Additional Comments: 
//   Only BCDEHLSP are in the register file
//////////////////////////////////////////////////////////////////////////////////

module regfile(
    input clk,
    input rst,
    input [2:0] rdn,
    output [7:0] rd,
    output [15:0] rdw,
    output [7:0] h, // H, L output for 16bit addition
    output [7:0] l, 
    output [15:0] sp, // SP output for addressing
    input [2:0] wrn,
    input [7:0] wr,
    input we
    );

    reg [7:0] regfile [0:7];

    wire [7:0] rdhigh = regfile[{rdn[2:1], 1'b0}];
    wire [7:0] rdlow  = regfile[{rdn[2:1], 1'b1}];
    assign rdw = {rdhigh, rdlow};
    assign rd = regfile[rdn];
    assign h = regfile[3'd6];
    assign l = regfile[3'd7];

    integer i;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1)
                regfile[i] <= 8'b0;
        end
        else begin
            if (we)
                regfile[wrn] <= wr;
        end
    end

endmodule
