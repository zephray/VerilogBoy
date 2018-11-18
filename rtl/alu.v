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
    output [3:0] alu_flags_out,
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
    //           unused 5'b10000
    //           unused 5'b10001
    //           unused 5'b10010
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


    always@(*) begin
        alu_flags_out = 4'b0;
        carry = 1'b0;
        result_low = 5'd0;
        result_high = 5'd0;
        intermediate_result1 = 9'd0;
        intermediate_result2 = 9'd0;
        case (alu_op)
            ALU_ADD, ALU_ADC: begin
                carry = (alu_op == `ALU_ADC) ? alu_flags_in[F_C] : 1'b0;
                result_low = {1'b0, alu_b[3:0]} + {1'b0, alu_a[3:0]} + 
                    {4'b0, carry};
                alu_flags_out[F_H] = result_low[4];
                result_high = {1'b0, alu_b[7:4]} + 
                    {1'b0, alu_a[7:4]} + 
                    result_low[4];
                alu_flags_out[F_C] = result_high[4];
                alu_result = {result_high[3:0], result_low[3:0]};
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            ALU_SUB, ALU_SBC: begin
                alu_flags_out[F_N] = 1'b1;
                carry = (alu_op == `ALU_SBC) ? alu_flags_in[F_C] : 1'b0;
                result_low = {1'b0, alu_b[3:0]} + 
                    ~({1'b0, alu_a[3:0]} + 
                    {4'b0, carry}) + 5'b1;
                alu_flags_out[F_H] = result_low[4];
                result_high = {1'b0, alu_b[7:4]} + 
                    ~({1'b0, alu_a[7:4]}) +
                    {4'b0, ~result_low[4]};
                alu_flags_out[F_C] = result_high[4];
                alu_result = {result_high[3:0], result_low[3:0]};
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            ALU_AND: begin
                alu_flags_out[F_H] = 1'b1;
                alu_result = alu_b & alu_a;
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            ALU_OR: begin
                alu_result = alu_b | alu_a;
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            ALU_XOR: begin
                alu_result = alu_b ^ alu_a;
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            ALU_DAA: begin
            // This is a stupid instruction.
                if (~alu_flags_in[F_N]) begin
                    if (alu_flags_in[F_H] | 
                        ((alu_b & 8'h0f) > 8'h9)) begin
                        intermediate_result1 = {1'b0, alu_b} + 9'h6;
                    end
                    else begin
                        intermediate_result1 = {1'b0, alu_b};
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
                        intermediate_result1 = {1'b0, (alu_b - 8'h6)};
                    end
                    else begin
                        intermediate_result1 = {1'b0, alu_b};
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
            ALU_NOT: begin
                alu_flags_out[F_Z] = alu_flags_in[F_Z];
                alu_flags_out[F_N] = 1'b1;
                alu_flags_out[F_H] = 1'b1;
                alu_flags_out[F_C] = alu_flags_in[F_C];
                alu_result = ~alu_b;
            end
            ALU_CCF: begin
                alu_flags_out[F_Z] = alu_flags_in[F_Z];
                alu_flags_out[F_C] = ~alu_flags_in[F_C];
                alu_result = alu_a;
            end
            ALU_SCF: begin
                alu_flags_out[F_Z] = alu_flags_in[F_Z];
                alu_flags_out[F_C] = 1'b1;
                alu_result = alu_a;
            end
            ALU_RLC: begin
                alu_result[0] = alu_b[7];
                alu_result[7:1] = alu_b[6:0];
                alu_flags_out[F_C] = alu_b[7];
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            ALU_RL: begin
                alu_result[0] = alu_flags_in[F_C];
                alu_result[7:1] = alu_b[6:0];
                alu_flags_out[F_C] = alu_b[7];
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            ALU_RRC: begin
                alu_result[7] = alu_b[0];
                alu_result[6:0] = alu_b[7:1];
                alu_flags_out[F_C] = alu_b[0];
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            ALU_RR: begin
                alu_result[7] = alu_flags_in[F_C];
                alu_result[6:0] = alu_b[7:1];
                alu_flags_out[F_C] = alu_b[0];
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            ALU_SL: begin
                alu_result[7:1] = alu_b[6:0];
                alu_result[0] = 1'b0;
                alu_flags_out[F_C] = alu_b[7];
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            ALU_SRA: begin
                alu_result[7] = alu_b[7];
                alu_result[6:0] = alu_b[7:1];
                alu_flags_out[F_C] = alu_b[0];
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            ALU_SRL: begin
                alu_result[7] = 1'b0;
                alu_result[6:0] = alu_b[7:1];
                alu_flags_out[F_C] = alu_b[0];
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
            end
            ALU_BIT: begin
            // Bit index must be in data0[5:3]
                alu_flags_out[F_C] = alu_flags_in[F_C];
                alu_flags_out[F_H] = 1'b1;
                alu_flags_out[F_N] = 1'b0;
                alu_flags_out[F_Z] = ~alu_b[bit_index];
                alu_result = alu_a;
            end
            ALU_SET: begin
                alu_flags_out = alu_flags_in;
                alu_result = alu_b;
                alu_result[bit_index] = 1'b1;
            end
            ALU_RES: begin
                alu_flags_out = alu_flags_in;
                alu_result = alu_b;
                alu_result[bit_index] = 1'b0;
            end
            ALU_SWAP: begin
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'd1: 1'd0;
                alu_flags_out[F_H] = 1'b0;
                alu_flags_out[F_C] = 1'b0;
                alu_flags_out[F_N] = 1'b0;
                alu_result = {alu_b[3:0], alu_b[7:4]};
            end
            default: begin
                alu_result = alu_a;
                alu_flags_out = alu_flags_in;
            end
        endcase
    end

endmodule