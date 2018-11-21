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
    input [1:0] rdwn,
    output [15:0] rdw,
    output [7:0] h, // H, L output for 16bit addition
    output [7:0] l, 
    output [15:0] sp, // SP output for addressing
    input [2:0] wrn,
    input [7:0] wr,
    input we
    );

    reg [7:0] regs [0:7];

    wire [7:0] rdhigh = regs[{rdwn, 1'b0}];
    wire [7:0] rdlow  = regs[{rdwn, 1'b1}];
    assign rdw = {rdhigh, rdlow};
    assign rd = regs[rdn];
    assign h = regs[3'd4];
    assign l = regs[3'd5];
    assign sp = {regs[3'd7], regs[3'd6]};

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1)
                regs[i] <= 8'b0;
        end
        else begin
            if (we)
                regs[wrn] <= wr;
        end
    end

endmodule
