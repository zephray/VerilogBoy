`include "cpu.vh"

/**
 * The GB80 register file.
 * 
 * Author: Joseph Carlos (jdcarlos1@gmail.com)
 */


/**
 * The register file. It contains the 16-bit registers BC, DE, HL, SP, and PC
 * in the following array:
 * 
 * 0 BC
 * 1 DE
 * 2 HL
 * 3 SP
 * 4 PC
 * 
 * Register select is performed by using 5-bit signals to select the input and
 * output bytes within the 16-bit registers. The signal's bits are allocated as
 * follows:
 * 
 * FHRRR
 * 
 * Where:
 * RRR is the 16-bit register index, from 3'd0 to 3'd4 (3'b000 to 3'b100).
 * F denotes whether to select a full register (only relevant for output).
 * H denotes whether to select the high or low byte of the register.
 * 
 * For example, a signal of 5'b10010 would select the full 2nd register, or HL.
 * 5'b00001 would select the low byte of the 1st register, or E.
 * 
 * Registers A and F are not included here. A is not included because
 * aritmetic operations would not finish in time using a single-output register
 * file.
 * 
 * @output data_out The 16-bit output of the register file.
 * @input data_in The 8-bit input of the register file.
 * @input rn_in The register code to select the input register.
 * @input rn_out The register code to select the output register.
 * @input we Writes to the selected register if this signal is asserted.
 * @input change16 If asserted, the selected 16-bit register is incremented.
 * @input inc 1 indicates the selected 16-bit register should be incremented.
 *    0 indicates that it should be decremented.
 * @input reset Posedge reset.
 * @input clock Clock signal.
 */
module regfile(/*AUTOARG*/
   // Outputs
   regs_data, regfile_data_out,
   // Inputs
   regfile_data_in, regfile_rn_in, regfile_rn_out, regfile_we,
   regfile_change16, regfile_inc, regfile_jp_hl, reset, clock, halt
   );
   output wire [79:0] regs_data;
   output wire [15:0] regfile_data_out;
   input [7:0]        regfile_data_in;
   input [4:0]        regfile_rn_in, regfile_rn_out;
   input              regfile_we, regfile_change16, regfile_inc, regfile_jp_hl;
   input              reset, clock;
   input              halt;

   reg [15:0]         mem[0:4];
   integer            i;

   wire [2:0]         ri_in, ri_out;
   wire               full_in, hi_in, full_out, hi_out;

   wire [7:0]         data_out8;

   // Debugging
   assign regs_data[79:64] = mem[0];
   assign regs_data[63:48] = mem[1];
   assign regs_data[47:32] = mem[2];
   assign regs_data[31:16] = mem[3];
   assign regs_data[15:0] = mem[4];
   
   assign full_out = regfile_rn_out[4];
   assign hi_out = regfile_rn_out[3];
   assign ri_out = regfile_rn_out[2:0];

   assign full_in = regfile_rn_in[4];
   assign hi_in = regfile_rn_in[3];
   assign ri_in = regfile_rn_in[2:0];
   
   always @(posedge clock or posedge reset) begin
      if (reset) begin
         for (i = 0; i < 5; i = i + 1) begin
            mem[i] <= 16'd0;
         end
      end
/*      else if (regfile_we) begin
         if (regfile_change_pc & regfile_inc_pc) begin
            mem[4] <= mem[4] + 16'd1;
         end
         else if (regfile_change_pc & ~regfile_inc_pc) begin
            mem[4] <= mem[4] - 16'd1;
         end
         else if (hi_in) begin
            mem[ri_in][15:8] <= regfile_data_in;
         end
         else begin
            mem[ri_in][7:0] <= regfile_data_in;
         end
      end*/ // always @ (posedge clock or posedge reset)
      else if (regfile_we) begin
         if (regfile_jp_hl) begin
            mem[4] <= mem[2];
         end else if (full_in & regfile_change16 & regfile_inc) begin
            mem[ri_in] <= mem[ri_in] + 16'd1;
         end else if (full_in & regfile_change16 & ~regfile_inc) begin
            mem[ri_in] <= mem[ri_in] - 16'd1;
         end else if (hi_in) begin
            mem[ri_in][15:8] <= regfile_data_in;
         end else begin
            mem[ri_in][7:0] <= regfile_data_in;
         end
      end
   end

   assign data_out8 = (hi_out) ? mem[ri_out][15:8] : mem[ri_out][7:0];
   assign regfile_data_out = (full_out) ? mem[ri_out] : {8'd0, data_out8};

   // synthesis translate_off
   integer fd;
   always @(posedge clock) begin
      if (~reset && halt) begin
         fd = $fopen("reg_dump.txt");
         $fdisplay(fd, "BC %4h", mem[0][15:0]);
         $fdisplay(fd, "DE %4h", mem[1][15:0]);
         $fdisplay(fd, "HL %4h", mem[2][15:0]);
         $fdisplay(fd, "SP %4h", mem[3][15:0]);
         $fdisplay(fd, "PC %4h", mem[4][15:0]);
         $fclose(fd);
      end
   end
   // synthesis translate_on
   
endmodule // regfile
