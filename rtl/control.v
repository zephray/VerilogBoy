`timescale 1ns / 1ps
`default_nettype wire
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Module Name:    control
// Project Name:   VerilogBoy
// Description: 
//   The control unit of Game Boy CPU.
// Dependencies: 
// 
// Additional Comments: 
//   
//////////////////////////////////////////////////////////////////////////////////

module control(
    input        clk,
    input        rst,
    input  [7:0] opcode,
    output [1:0] alu_src_a,
    output [2:0] alu_src_b,
    output [1:0] alu_op_prefix,
    output [1:0] alu_op_src,
    output [1:0] alu_dst,
    output [1:0] pc_src,
    output       pc_we,
    output [2:0] rf_wr_sel,
    output [2:0] rf_rd_sel
);

    reg [19:0] decoding_lut [0:255];
    wire [19:0] decoding_output;
    always @(posedge clk) begin
        decoding_output = decoding_lut[opcode];
    end

    assign {alu_src_a, alu_src_b, alu_op_prefix, alu_op_src, 
        alu_dst, pc_src, pc_we, rf_wr_sel, rf_rd_sel}
        = decoding_output;

endmodule
