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
    input [7:0] alu_b,
    input [7:0] alu_a,
    input [2:0] alu_bit_index,
    output reg [7:0] alu_result,
    input [3:0] alu_flags_in,
    output reg [3:0] alu_flags_out,
    input [4:0] alu_op
    );

    localparam OP_ADD = 5'b00000;
    localparam OP_ADC = 5'b00001;
    localparam OP_SUB = 5'b00010;
    localparam OP_SBC = 5'b00011;
    localparam OP_AND = 5'b00100;
    localparam OP_XOR = 5'b00101;
    localparam OP_OR  = 5'b00110;
    localparam OP_CP  = 5'b00111;
    localparam OP_RLC = 5'b01000;
    localparam OP_RRC = 5'b01001;
    localparam OP_RL  = 5'b01010;
    localparam OP_RR  = 5'b01011;
    localparam OP_SLA = 5'b01100;
    localparam OP_SRA = 5'b01101;
    localparam OP_SWAP= 5'b01110;
    localparam OP_SRL = 5'b01111;
    localparam OP_LF  = 5'b10000; // Load Flags
    //           unused 5'b10001
    localparam OP_SF  = 5'b10010; // Save Flags
    //           unused 5'b10011
    localparam OP_DAA = 5'b10100;
    localparam OP_CPL = 5'b10101;
    localparam OP_SCF = 5'b10110;
    localparam OP_CCF = 5'b10111;
    //           unused 5'b11000
    //           unused 5'b11001
    //           unused 5'b11010
    //           unused 5'b11011
    //           unused 5'b11100
    localparam OP_BIT = 5'b11101;
    localparam OP_RES = 5'b11110;
    localparam OP_SET = 5'b11111;

    localparam F_Z = 2'd3;
    localparam F_N = 2'd2;
    localparam F_H = 2'd1;
    localparam F_C = 2'd0;

    reg [8:0]        intermediate_result1, intermediate_result2;
    reg [4:0]        result_low;
    reg [4:0]        result_high;
    wire [2:0]       bit_index;
    reg carry;
 
    assign bit_index = alu_bit_index;

    always@(*) begin
        alu_flags_out = 4'b0;
        carry = 1'b0;
        result_low = 5'd0;
        result_high = 5'd0;
        intermediate_result1 = 9'd0;
        intermediate_result2 = 9'd0;
        case (alu_op)
            OP_ADD, OP_ADC: begin
                carry = (alu_op == OP_ADC) ? alu_flags_in[F_C] : 1'b0;
                result_low = {1'b0, alu_a[3:0]} + {1'b0, alu_b[3:0]} + 
                    {4'b0, carry};
                alu_flags_out[F_H] = result_low[4];
                result_high = {1'b0, alu_a[7:4]} + 
                    {1'b0, alu_b[7:4]} + 
                    {4'b0, result_low[4]};
                alu_flags_out[F_C] = result_high[4];
                alu_result = {result_high[3:0], result_low[3:0]};
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            OP_SUB, OP_SBC: begin
                alu_flags_out[F_N] = 1'b1;
                carry = (alu_op == OP_SBC) ? alu_flags_in[F_C] : 1'b0;
                result_low = {1'b0, alu_a[3:0]} + 
                    ~({1'b0, alu_b[3:0]} + 
                    {4'b0, carry}) + 5'b1;
                alu_flags_out[F_H] = result_low[4];
                result_high = {1'b0, alu_a[7:4]} + 
                    ~({1'b0, alu_b[7:4]}) +
                    {4'b0, ~result_low[4]};
                alu_flags_out[F_C] = result_high[4];
                alu_result = {result_high[3:0], result_low[3:0]};
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            OP_AND: begin
                alu_flags_out[F_H] = 1'b1;
                alu_result = alu_a & alu_b;
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            OP_OR: begin
                alu_result = alu_a | alu_b;
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            OP_XOR: begin
                alu_result = alu_a ^ alu_b;
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            OP_DAA: begin
                if (~alu_flags_in[F_N]) begin
                    if (alu_flags_in[F_H] | 
                        ((alu_a & 8'h0f) > 8'h9)) begin
                        intermediate_result1 = {1'b0, alu_a} + 9'h6;
                    end
                    else begin
                        intermediate_result1 = {1'b0, alu_a};
                    end
                    if (alu_flags_in[F_C] | (intermediate_result1 > 9'h9f)) begin
                        intermediate_result2 = intermediate_result1 + 9'h60;
                    end
                    else begin
                        intermediate_result2 = intermediate_result1;
                    end
                end
                else begin
                    if (alu_flags_in[F_H]) begin
                        intermediate_result1 = {1'b0, (alu_a - 8'h6)};
                    end
                    else begin
                        intermediate_result1 = {1'b0, alu_a};
                    end
                    if (alu_flags_in[F_C]) begin
                        intermediate_result2 = intermediate_result1 - 9'h60;
                    end
                    else begin
                        intermediate_result2 = intermediate_result1;
                    end
                end // else: !if(alu_flags_in[F_N])

                alu_result = intermediate_result2[7:0];
                
                alu_flags_out[F_N] = alu_flags_in[F_N];
                alu_flags_out[F_H] = 1'b0;
                alu_flags_out[F_C] = intermediate_result2[8] ? 1'b1 : 
                                        alu_flags_in[F_C];
                alu_flags_out[F_Z] = (intermediate_result2[7:0] == 8'd0) ? 
                                        1'b1 : 1'b0;
            end
            OP_CPL: begin
                alu_flags_out[F_Z] = alu_flags_in[F_Z];
                alu_flags_out[F_N] = 1'b1;
                alu_flags_out[F_H] = 1'b1;
                alu_flags_out[F_C] = alu_flags_in[F_C];
                alu_result = ~alu_a;
            end
            OP_CCF: begin
                alu_flags_out[F_Z] = alu_flags_in[F_Z];
                alu_flags_out[F_C] = ~alu_flags_in[F_C];
                alu_result = alu_b;
            end
            OP_SCF: begin
                alu_flags_out[F_Z] = alu_flags_in[F_Z];
                alu_flags_out[F_C] = 1'b1;
                alu_result = alu_b;
            end
            OP_RLC: begin
                alu_result[0] = alu_a[7];
                alu_result[7:1] = alu_a[6:0];
                alu_flags_out[F_C] = alu_a[7];
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            OP_RL: begin
                alu_result[0] = alu_flags_in[F_C];
                alu_result[7:1] = alu_a[6:0];
                alu_flags_out[F_C] = alu_a[7];
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            OP_RRC: begin
                alu_result[7] = alu_a[0];
                alu_result[6:0] = alu_a[7:1];
                alu_flags_out[F_C] = alu_a[0];
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            OP_RR: begin
                alu_result[7] = alu_flags_in[F_C];
                alu_result[6:0] = alu_a[7:1];
                alu_flags_out[F_C] = alu_a[0];
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            OP_SLA: begin
                alu_result[7:1] = alu_a[6:0];
                alu_result[0] = 1'b0;
                alu_flags_out[F_C] = alu_a[7];
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            OP_SRA: begin
                alu_result[7] = alu_a[7];
                alu_result[6:0] = alu_a[7:1];
                alu_flags_out[F_C] = alu_a[0];
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            OP_SRL: begin
                alu_result[7] = 1'b0;
                alu_result[6:0] = alu_a[7:1];
                alu_flags_out[F_C] = alu_a[0];
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            OP_BIT: begin
            // Bit index must be in data0[5:3]
                alu_flags_out[F_C] = alu_flags_in[F_C];
                alu_flags_out[F_H] = 1'b1;
                alu_flags_out[F_N] = 1'b0;
                alu_flags_out[F_Z] = ~alu_a[bit_index];
                alu_result = alu_b;
            end
            OP_SET: begin
                alu_flags_out = alu_flags_in;
                alu_result = alu_a;
                alu_result[bit_index] = 1'b1;
            end
            OP_RES: begin
                alu_flags_out = alu_flags_in;
                alu_result = alu_a;
                alu_result[bit_index] = 1'b0;
            end
            OP_SWAP: begin
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'd1: 1'd0;
                alu_flags_out[F_H] = 1'b0;
                alu_flags_out[F_C] = 1'b0;
                alu_flags_out[F_N] = 1'b0;
                alu_result = {alu_a[3:0], alu_a[7:4]};
            end
            OP_SF: begin
                alu_flags_out = alu_b[7:4];
                alu_result = alu_a;
            end
            OP_LF: begin
                alu_result = {alu_flags_in, 4'b0};
            end
            default: begin
                alu_result = alu_b;
                alu_flags_out = alu_flags_in;
            end
        endcase
    end

endmodule
