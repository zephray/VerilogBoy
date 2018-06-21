`include "cpu.vh"

/**
 * The GB80 ALU.
 * 
 * Author: Joseph Carlos (jdcarlos1@gmail.com)
 */

/**
 * The ALU.
 * 
 * @output data_out The result of the operation.
 * @output flags_out The result flags of the operation.
 * @input data0_in The first operand to the operation.
 * @input data1_in The second operand to the operation.
 * @input op The ALU opcode, such as ALU_ADD, ALU_ADC, etc. that determines the
 *    operation.
 * @input flags_in The current flags, for use in rotate and 16-bit operations.
 * @input size The current operation size. One of ALU_SIZE_8, ALU_SIZE_16.
 */
module alu
  (/*AUTOARG*/
   // Outputs
   alu_data_out, alu_flags_out,
   // Inputs
   alu_data0_in, alu_data1_in, alu_op, alu_flags_in, alu_size
   );

   parameter
     F_Z = 3, F_N = 2, F_H = 1, F_C = 0;
   
   output reg [7:0] alu_data_out;
   output reg [3:0] alu_flags_out;
   input [7:0]      alu_data0_in, alu_data1_in;
   input [4:0]      alu_op;
   input [3:0]      alu_flags_in;
   input [1:0]      alu_size;

   reg [8:0]        intermediate_result1, intermediate_result2;
   reg [4:0]        result_low;
   reg [4:0]        result_high;
   wire [2:0]       bit_index;
   reg              carry;

   assign bit_index = alu_data0_in[5:3];
   
   always @(*) begin
      // ZNHC
      alu_flags_out = 4'd0;
      carry = 1'b0;
      result_low = 5'd0;
      result_high = 5'd0;
      intermediate_result1 = 9'd0;
      intermediate_result2 = 9'd0;
      case (alu_op)
        `ALU_ADD, `ALU_ADC: begin
           carry = (alu_op == `ALU_ADC) ? alu_flags_in[F_C] : 1'b0;
           result_low = {1'b0, alu_data1_in[3:0]} + {1'b0, alu_data0_in[3:0]} + 
                        {4'b0, carry};
           alu_flags_out[F_H] = result_low[4];
           result_high = {1'b0, alu_data1_in[7:4]} + 
                         {1'b0, alu_data0_in[7:4]} + 
                         result_low[4];
           alu_flags_out[F_C] = result_high[4];
           alu_data_out = {result_high[3:0], result_low[3:0]};
           if (alu_size == `ALU_SIZE_16) begin
              alu_flags_out[F_Z] = alu_flags_in[F_Z];
           end else if (alu_size == `ALU_SIZE_SPEC) begin
              alu_flags_out[F_Z] = 1'b0;
           end else begin
              alu_flags_out[F_Z] = (alu_data_out == 8'd0) ? 1'b1 : 1'b0;
           end
        end
        `ALU_SUB, `ALU_SBC: begin
           alu_flags_out[F_N] = 1'b1;
           carry = (alu_op == `ALU_SBC) ? alu_flags_in[F_C] : 1'b0;
           result_low = {1'b0, alu_data1_in[3:0]} + 
                        ~({1'b0, alu_data0_in[3:0]} + 
                          {4'b0, carry}) + 5'b1;
           alu_flags_out[F_H] = result_low[4];
           result_high = {1'b0, alu_data1_in[7:4]} + 
                         ~({1'b0, alu_data0_in[7:4]}) +
                         {4'b0, ~result_low[4]};
           alu_flags_out[F_C] = result_high[4];
           alu_data_out = {result_high[3:0], result_low[3:0]};
           alu_flags_out[F_Z] = (alu_data_out == 8'd0) ? 1'b1 : 1'b0;
        end
        `ALU_AND: begin
           alu_flags_out[F_H] = 1'b1;
           alu_data_out = alu_data1_in & alu_data0_in;
           alu_flags_out[F_Z] = (alu_data_out == 8'd0) ? 1'b1 : 1'b0;
        end
        `ALU_OR: begin
           alu_data_out = alu_data1_in | alu_data0_in;
           alu_flags_out[F_Z] = (alu_data_out == 8'd0) ? 1'b1 : 1'b0;
        end
        `ALU_XOR: begin
           alu_data_out = alu_data1_in ^ alu_data0_in;
           alu_flags_out[F_Z] = (alu_data_out == 8'd0) ? 1'b1 : 1'b0;
        end
        `ALU_INC: begin
           alu_flags_out[F_C] = alu_flags_in[F_C];

           result_low = {1'b0, alu_data1_in[3:0]} + 5'd1;
           alu_flags_out[F_H] = result_low[4];
           result_high = {1'b0, alu_data1_in[7:4]} + result_low[4];
           alu_data_out = {result_high[3:0], result_low[3:0]};

           if (alu_size == `ALU_SIZE_16) begin
              alu_flags_out = alu_flags_in;
           end else begin
              alu_flags_out[F_Z] = (alu_data_out == 8'd0) ? 1'b1 : 1'b0;
           end
        end // case: `ALU_INC
        `ALU_DEC: begin
           alu_flags_out[F_C] = alu_flags_in[F_C];

           result_low = {1'b0, alu_data1_in[3:0]} + 
                        ~({1'b0, 4'd1}) + 5'b1;
           alu_flags_out[F_H] = result_low[4];
           result_high = {1'b0, alu_data1_in[7:4]} + 
                         ~({1'b0, 4'd0}) +
                         {4'b0, ~result_low[4]};

           alu_flags_out[F_N] = 1'b1;
           alu_data_out = {result_high[3:0], result_low[3:0]};

           if (alu_size == `ALU_SIZE_16) begin
              alu_flags_out = alu_flags_in;
           end else begin
              alu_flags_out[F_Z] = (alu_data_out == 8'd0) ? 1'b1 : 1'b0;
           end
        end // case: `ALU_DEC
        `ALU_DAA: begin
           // This is a stupid instruction.
           if (~alu_flags_in[F_N]) begin
              if (alu_flags_in[F_H] | 
                  ((alu_data1_in & 8'h0f) > 8'h9)) begin
                 intermediate_result1 = {1'b0, alu_data1_in} + 9'h6;
              end
              else begin
                 intermediate_result1 = {1'b0, alu_data1_in};
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
                 intermediate_result1 = {1'b0, (alu_data1_in - 8'h6)};
              end
              else begin
                 intermediate_result1 = {1'b0, alu_data1_in};
              end
              if (alu_flags_in[F_C]) begin
                 intermediate_result2 = intermediate_result1 - 9'h60;
              end
              else begin
                 intermediate_result2 = intermediate_result1;
              end
           end // else: !if(alu_flags_in[F_N])

           alu_data_out = intermediate_result2[7:0];
           
           alu_flags_out[F_N] = alu_flags_in[F_N];
           alu_flags_out[F_H] = 1'b0;
           alu_flags_out[F_C] = intermediate_result2[8] ? 1'b1 : 
                                alu_flags_in[F_C];
           alu_flags_out[F_Z] = (intermediate_result2[7:0] == 8'd0) ? 
                                1'b1 : 1'b0;
        end
        `ALU_NOT: begin
           alu_flags_out[F_Z] = alu_flags_in[F_Z];
           alu_flags_out[F_N] = 1'b1;
           alu_flags_out[F_H] = 1'b1;
           alu_flags_out[F_C] = alu_flags_in[F_C];
           alu_data_out = ~alu_data1_in;
        end
        `ALU_CCF: begin
           alu_flags_out[F_Z] = alu_flags_in[F_Z];
           alu_flags_out[F_C] = ~alu_flags_in[F_C];
           alu_data_out = alu_data0_in;
        end
        `ALU_SCF: begin
           alu_flags_out[F_Z] = alu_flags_in[F_Z];
           alu_flags_out[F_C] = 1'b1;
           alu_data_out = alu_data0_in;
        end
        `ALU_RLC: begin
           alu_data_out[0] = alu_data1_in[7];
           alu_data_out[7:1] = alu_data1_in[6:0];
           alu_flags_out[F_C] = alu_data1_in[7];
           if (alu_size == `ALU_SIZE_SPEC) begin
              alu_flags_out[F_Z] = 1'b0;
           end else begin
              alu_flags_out[F_Z] = (alu_data_out == 8'd0) ? 1'b1 : 1'b0;
           end
        end
        `ALU_RL: begin
           alu_data_out[0] = alu_flags_in[F_C];
           alu_data_out[7:1] = alu_data1_in[6:0];
           alu_flags_out[F_C] = alu_data1_in[7];
           if (alu_size == `ALU_SIZE_SPEC) begin
              alu_flags_out[F_Z] = 1'b0;
           end else begin
              alu_flags_out[F_Z] = (alu_data_out == 8'd0) ? 1'b1 : 1'b0;
           end
        end
        `ALU_RRC: begin
           alu_data_out[7] = alu_data1_in[0];
           alu_data_out[6:0] = alu_data1_in[7:1];
           alu_flags_out[F_C] = alu_data1_in[0];
           if (alu_size == `ALU_SIZE_SPEC) begin
              alu_flags_out[F_Z] = 1'b0;
           end else begin
              alu_flags_out[F_Z] = (alu_data_out == 8'd0) ? 1'b1 : 1'b0;
           end
        end
        `ALU_RR: begin
           alu_data_out[7] = alu_flags_in[F_C];
           alu_data_out[6:0] = alu_data1_in[7:1];
           alu_flags_out[F_C] = alu_data1_in[0];
           if (alu_size == `ALU_SIZE_SPEC) begin
              alu_flags_out[F_Z] = 1'b0;
           end else begin
              alu_flags_out[F_Z] = (alu_data_out == 8'd0) ? 1'b1 : 1'b0;
           end
        end
        `ALU_SL: begin
           alu_data_out[7:1] = alu_data1_in[6:0];
           alu_data_out[0] = 1'b0;
           alu_flags_out[F_C] = alu_data1_in[7];
           alu_flags_out[F_Z] = (alu_data_out == 8'd0) ? 1'b1 : 1'b0;
        end
        `ALU_SRA: begin
           alu_data_out[7] = alu_data1_in[7];
           alu_data_out[6:0] = alu_data1_in[7:1];
           alu_flags_out[F_C] = alu_data1_in[0];
           alu_flags_out[F_Z] = (alu_data_out == 8'd0) ? 1'b1 : 1'b0;
        end
        `ALU_SRL: begin
           alu_data_out[7] = 1'b0;
           alu_data_out[6:0] = alu_data1_in[7:1];
           alu_flags_out[F_C] = alu_data1_in[0];
           alu_flags_out[F_Z] = (alu_data_out == 8'd0) ? 1'b1 : 1'b0;
        end
        `ALU_PASS0: begin
           alu_data_out = alu_data0_in;
           alu_flags_out = alu_flags_in;
        end
        `ALU_PASS1: begin
           alu_data_out = alu_data1_in;
           alu_flags_out = alu_flags_in;
        end
        `ALU_PASSF: begin
           alu_data_out = alu_data0_in;
           alu_flags_out = alu_data0_in[7:4];
        end
        `ALU_BIT: begin
           // Bit index must be in data0[5:3]
           alu_flags_out[F_C] = alu_flags_in[F_C];
           alu_flags_out[F_H] = 1'b1;
           alu_flags_out[F_N] = 1'b0;
           alu_flags_out[F_Z] = ~alu_data1_in[bit_index];
           alu_data_out = alu_data0_in;
        end
        `ALU_SET: begin
           alu_flags_out = alu_flags_in;
           alu_data_out = alu_data1_in;
           alu_data_out[bit_index] = 1'b1;
        end
        `ALU_RES: begin
           alu_flags_out = alu_flags_in;
           alu_data_out = alu_data1_in;
           alu_data_out[bit_index] = 1'b0;
        end
        `ALU_SWAP: begin
           alu_flags_out[F_Z] = (alu_data_out == 8'd0) ? 1'd1: 1'd0;
           alu_flags_out[F_H] = 1'b0;
           alu_flags_out[F_C] = 1'b0;
           alu_flags_out[F_N] = 1'b0;
           alu_data_out = {alu_data1_in[3:0], alu_data1_in[7:4]};
        end
        default: begin
           alu_data_out = alu_data0_in;
           alu_flags_out = alu_flags_in;
        end
      endcase
   end
   
endmodule // alu
