`include "cpu.vh"

/**
 * The GB80 CPU.
 * 
 * Consists of a microcode module, register file, and ALU connected to some 
 * extra control hardware and parallel data and address buses. The buses output
 * to the user of the CPU through some buffers.
 * 
 * Author: Joseph Carlos (jdcarlos1@gmail.com)
 */

/**
 * The top module.
 */
module cpu(/*AUTOARG*/
   // Outputs
   high_mem_data, high_mem_addr, F_data, A_data, instruction, IF_data,
   IE_data, regs_data, mem_we, mem_re, halt, debug_halt,
   // Inouts
   addr_ext, data_ext,
   // Inputs
   IF_in, IE_in, IF_load, IE_load, cpu_mem_disable, clock, reset,
   bp_addr, bp_step, bp_continue
   );
   inout [15:0] addr_ext;
   inout [7:0]  data_ext;

   // Debugging outputs: translated high memory address line and high memory
   // data line.
   output wire [7:0] high_mem_data;
   output wire [15:0] high_mem_addr;

   // Debugging outputs
   output wire [7:0] F_data;
   output wire [7:0] A_data, instruction;
   
   // Debugging output: all registers except AF.
   output wire [79:0] regs_data;

   output wire [4:0] IF_data, IE_data;
   
   output wire  mem_we, mem_re;
   output wire  halt;
   output wire  debug_halt;

   input [4:0]  IF_in, IE_in;
   input        IF_load, IE_load;
   input        cpu_mem_disable;
   input        clock, reset;

   input [15:0] bp_addr;
   input        bp_step, bp_continue;
   
   // Constant Parameters //////////////////////////////////////////////////////
   parameter
     F_Z = 3, F_N = 2, F_H = 1, F_C = 0,
     I_HILO = 4, I_SERIAL = 3, I_TIMA = 2, I_LCDC = 1, I_VBLANK = 0;
   
   // Global wires /////////////////////////////////////////////////////////////

   // Buses
   wire [15:0]  addr_bus;
   wire [7:0]   data_bus;

   // Intermediate data signals ////////////////////////////////////////////////

   // Debugging
   wire         bp_pc;
   assign bp_pc = regs_data[15:0] == bp_addr;

   // To/from external bus
   wire        addr_buf_load_ext, addr_buf_write_ext;
   wire        data_buf_load_ext, data_buf_write_ext;
   
   // Buffers/High memory
   wire [7:0]   data_ext_out, data_ext_in;
   wire [15:0]  addr_ext_out, addr_ext_in;
//   wire [7:0]   high_mem_data;
   
   wire         high_mem = (`MEM_HIGH_START <= addr_ext_out) & 
                (addr_ext_out <= `MEM_HIGH_END); 
   
   assign data_ext_in = (high_mem) ? high_mem_data :
                        (cpu_mem_disable) ? 8'h0 : data_ext;
   assign addr_ext_in = (high_mem) ? 16'hzz :
                        (cpu_mem_disable) ? 16'hzz : addr_ext;

   tristate #(8) data_ext_tri(.out(data_ext),
                              .in(data_ext_out),
                              .en(data_buf_write_ext & ~cpu_mem_disable
                                  & ~high_mem));
   tristate #(16) addr_ext_tri(.out(addr_ext),
                               .in(addr_ext_out),
                               .en(addr_buf_write_ext & ~cpu_mem_disable &
                                   ~high_mem));
   
  // wire [15:0]  high_mem_addr;
   assign high_mem_addr = addr_ext_out - `MEM_HIGH_START;

   tristate #(8) high_mem_data_tri(.out(high_mem_data[7:0]),
                                   .in(data_ext_out),
                                   .en(data_buf_write_ext & high_mem));
   
   mem #(127, 0) high_mmmod(.data_ext(high_mem_data[7:0]),
                            .addr_ext(high_mem_addr[15:0]),
                            .mem_we(addr_buf_write_ext & high_mem),
                            .mem_re(data_buf_load_ext & high_mem),
                            .reset(reset),
                            .clock(clock));

   // Registers
   wire [7:0]   /*F_data, */temp1_data, temp0_data;
   wire [4:0]   IF_in_l, IE_in_l;
   wire         IME_data;
   wire         IE_load_l;
//   wire [7:0]   A_data, instruction;  

   reg [4:0]   interrupt_mask; // IF mask
   reg [2:0]   interrupt_sel; // select
   reg [3:0]   interrupt_addr_bits; // bits [6:3] of interrupt jump addr  

   wire         IF_load_l; // Decode output: mask IF with the interrupt
   wire         interrupt_data_gate; // Decode output: gate interrupt address
   wire         interrupt; // Decode input: is there an interrupt?
   
   assign interrupt = ~((IF_data & IE_data) == 5'd0);
   assign IF_in_l = (IF_load_l) ? IF_in | (IF_data & interrupt_mask) : IF_in;

   assign IE_load_l = (mem_we) ? addr_ext == `MMIO_IE : 1'b0;
   assign IE_in_l = (IE_load_l) ? data_ext[4:0] : IE_in;
   
   always @(*) begin
      // interrupt select and mask priority decoder/encoder
      casex (IF_data & IE_data)
        5'bxx_xx1: begin
           interrupt_sel = 3'd0;
           interrupt_mask = 5'b11_110;
        end
        5'bxx_x10: begin
           interrupt_sel = 3'd1;
           interrupt_mask = 5'b11_101;
        end
        5'bxx_100: begin
           interrupt_sel = 3'd2;
           interrupt_mask = 5'b11_011;
        end
        5'bx1_000: begin
           interrupt_sel = 3'd3;
           interrupt_mask = 5'b10_111;
        end
        5'b10_000: begin
           interrupt_sel = 3'd4;
           interrupt_mask = 5'b01_111;
        end
        5'b00_000: begin
           interrupt_sel = 3'd0;
           interrupt_mask = 5'b11_111;
        end
      endcase // casex (IF_data & IE_data)

      // Interrupt jump address mux
      case (interrupt_sel)
        3'd0: interrupt_addr_bits = 4'b1000;
        3'd1: interrupt_addr_bits = 4'b1001;
        3'd2: interrupt_addr_bits = 4'b1010;
        3'd3: interrupt_addr_bits = 4'b1011;
        3'd4: interrupt_addr_bits = 4'b1100;
        default: interrupt_addr_bits = 4'd0;
      endcase // case (interrupt_sel)
   end
   
   // ALU
   wire [7:0]   alu_data_out;
   reg [7:0]    alu_data1_in, alu_data0_in;
   wire [3:0]   alu_flags_in, alu_flags_out;
   assign alu_flags_in = F_data[7:4];
   
   // Regfile
   // regfile_data_addr is necessary for instructions that output 
   // 16'hff00 + regfile_data_out[7:0] to the address bus.
   wire [15:0]  regfile_data_out, regfile_data_addr;
   wire [7:0]   regfile_data_in;
   
   // Control signals //////////////////////////////////////////////////////////
   
   // Buffers
   // To/from internal bus
   wire        addr_buf_load, addr_buf_write;
   wire        data_buf_load, data_buf_write;

   // Outputs
   assign mem_we = data_buf_write_ext & ~high_mem & ~cpu_mem_disable;
   assign mem_re = data_buf_load_ext & ~high_mem & ~cpu_mem_disable;
   
   // Registers
   wire        inst_reg_load, A_load, F_load, temp1_load, temp0_load;
   wire        IME_set, IME_reset;
   
   // Tristate buffer enables
   wire        regfile_data_gate, A_data_gate, F_data_gate, regfile_addr_gate;
   wire        alu_data_gate;
   
   // Mux selects
   wire [1:0]  alu_data1_in_sel, alu_data0_in_sel;
   wire        addr_ff00_sel;

   // ALU
   wire [4:0]  alu_op;
   wire [1:0]  alu_size;
   
   // Regfile
   wire [4:0]  regfile_rn_in, regfile_rn_out;
   wire        regfile_we, regfile_change16, regfile_inc, regfile_jp_hl;

   // Branch instructions
   reg         taken;
   wire [3:0]  flags;
   assign flags = F_data[7:4];
   always @(*) begin
      case (instruction[4:3])
        2'b00: taken = ~flags[F_Z];
        2'b01: taken = flags[F_Z];
        2'b10: taken = ~flags[F_C];
        2'b11: taken = flags[F_C];
      endcase
   end
   
   // Multiplexers /////////////////////////////////////////////////////////////

   assign regfile_data_addr = (addr_ff00_sel) ? {8'hff, regfile_data_out[7:0]} :
                              regfile_data_out;

   always @(*) begin
      case (alu_data0_in_sel)
         `ALU_0_SEL_DATA: alu_data0_in = data_bus;
         `ALU_0_SEL_TEMP0: alu_data0_in = temp0_data;
         `ALU_0_SEL_RSTP: alu_data0_in = {2'd0, instruction[5:3], 3'd0};
         `ALU_0_SEL_FF: alu_data0_in = (temp0_data[7]) ? 8'hff : 8'h00;
      endcase
   end

   always @(*) begin
      case (alu_data1_in_sel)
        `ALU_1_SEL_A: alu_data1_in = A_data;
        `ALU_1_SEL_DATA: alu_data1_in = data_bus;
        `ALU_1_SEL_RGF: alu_data1_in = regfile_data_out;
        `ALU_1_SEL_TEMP1: alu_data1_in = temp1_data;
      endcase
   end

   assign regfile_data_in = data_bus;
   
   // Input/Output buffers /////////////////////////////////////////////////////
   
/*   buffer #(16, 0) addr_buf(.bus_in(addr_bus),
                            .bus_ext(addr_ext),
                            .bus_in_read(addr_buf_load),
                            .bus_in_write(addr_buf_write),
                            .bus_ext_read(addr_buf_load_ext),
                            .bus_ext_write(addr_buf_write_ext),
                            .clock(clock),
                            .reset(reset));
   buffer #(8, 0) data_buf(.bus_in(data_bus),
                           .bus_ext(data_ext),
                           .bus_in_read(data_buf_load),
                           .bus_in_write(data_buf_write),
                           .bus_ext_read(data_buf_load_ext),
                           .bus_ext_write(data_buf_write_ext),
                           .clock(clock),
                           .reset(reset));*/


   
   nobus_buffer #(8, 0) data_buf(.bus(data_bus),
                                 .bus_ext_out(data_ext_out),
                                 .bus_ext_in(data_ext_in),
                                 .bus_read(data_buf_load),
                                 .bus_write(data_buf_write),
                                 .bus_ext_read(data_buf_load_ext),
                                 .clock(clock),
                                 .reset(reset));

   nobus_buffer #(16, 0) addr_buf(.bus(addr_bus),
                                  .bus_ext_out(addr_ext_out),
                                  .bus_ext_in(addr_ext_in),
                                  .bus_read(addr_buf_load),
                                  .bus_write(addr_buf_write),
                                  .bus_ext_read(addr_buf_load_ext),
                                  .clock(clock),
                                  .reset(reset));

   
   // Registers ////////////////////////////////////////////////////////////////

   register #(8, 0) inst_reg(.q(instruction),
                             .d(data_bus),
                             .load(inst_reg_load),
                             .clock(clock),
                             .reset(reset));

   register #(8, 0) A_reg(.q(A_data),
                          .d(alu_data_out),
                          .load(A_load),
                          .clock(clock),
                          .reset(reset));

   register #(8, 0) F_reg(.q(F_data),
                          .d({alu_flags_out, 4'b0}),
                          .load(F_load),
                          .clock(clock),
                          .reset(reset));

   register #(8, 0) temp1_reg(.q(temp1_data),
                              .d(data_bus),
                              .load(temp1_load),
                              .clock(clock),
                              .reset(reset));

   register #(8, 0) temp0_reg(.q(temp0_data),
                              .d(data_bus),
                              .load(temp0_load),
                              .clock(clock),
                              .reset(reset));

   register #(5, 0) IF_reg(.q(IF_data),
                           .d(IF_in_l),
                           .load(IF_load_l | IF_load),
                           .clock(clock),
                           .reset(reset));

   register #(5, 0) IE_reg(.q(IE_data),
                           .d(IE_in_l),
                           .load(IE_load_l | IE_load),
                           .clock(clock),
                           .reset(reset));

   register #(1, 1) IME_reg(.q(IME_data),
                            .d(IME_set),
                            .load(IME_set | IME_reset),
                            .clock(clock),
                            .reset(reset));
   
   // Tristate buffers /////////////////////////////////////////////////////////

   tristate #(.width(8)) regfile_data_tri(.out(data_bus),
                                          .in(regfile_data_out[7:0]),
                                          .en(regfile_data_gate));
   tristate #(.width(8)) A_data_tri(.out(data_bus),
                                    .in(A_data),
                                    .en(A_data_gate));
   tristate #(.width(8)) F_data_tri(.out(data_bus),
                                    .in(F_data),
                                    .en(F_data_gate));
   tristate #(.width(8)) alu_data_tri(.out(data_bus),
                                      .in(alu_data_out),
                                      .en(alu_data_gate));
   tristate #(.width(8)) interrupt_addr_tri(.out(data_bus),
                                            .in({1'd0, interrupt_addr_bits,
                                                 3'd0}),
                                            .en(interrupt_data_gate));   
   tristate #(.width(16)) regfile_addr_tri(.out(addr_bus),
                                   .in(regfile_data_addr[15:0]),
                                   .en(regfile_addr_gate));

   
   // ALU //////////////////////////////////////////////////////////////////////

   alu gb80_alu(/*AUTOINST*/
                // Outputs
                .alu_data_out           (alu_data_out[7:0]),
                .alu_flags_out          (alu_flags_out[3:0]),
                // Inputs
                .alu_data0_in           (alu_data0_in[7:0]),
                .alu_data1_in           (alu_data1_in[7:0]),
                .alu_op                 (alu_op[4:0]),
                .alu_flags_in           (alu_flags_in[3:0]),
                .alu_size               (alu_size[1:0]));

   // Regfile //////////////////////////////////////////////////////////////////

   regfile gb80_regfile(/*AUTOINST*/
                        // Outputs
                        .regs_data      (regs_data[79:0]),
                        .regfile_data_out(regfile_data_out[15:0]),
                        // Inputs
                        .regfile_data_in(regfile_data_in[7:0]),
                        .regfile_rn_in  (regfile_rn_in[4:0]),
                        .regfile_rn_out (regfile_rn_out[4:0]),
                        .regfile_we     (regfile_we),
                        .regfile_change16(regfile_change16),
                        .regfile_inc    (regfile_inc),
                        .regfile_jp_hl  (regfile_jp_hl),
                        .reset          (reset),
                        .clock          (clock),
                        .halt           (halt));

   // Decode module ////////////////////////////////////////////////////////////

   decode gb80_decode(/*AUTOINST*/
                      // Outputs
                      .regfile_rn_in    (regfile_rn_in[4:0]),
                      .regfile_rn_out   (regfile_rn_out[4:0]),
                      .regfile_we       (regfile_we),
                      .regfile_change16 (regfile_change16),
                      .regfile_inc      (regfile_inc),
                      .regfile_jp_hl    (regfile_jp_hl),
                      .addr_buf_load    (addr_buf_load),
                      .addr_buf_write   (addr_buf_write),
                      .data_buf_load    (data_buf_load),
                      .data_buf_write   (data_buf_write),
                      .addr_buf_load_ext(addr_buf_load_ext),
                      .addr_buf_write_ext(addr_buf_write_ext),
                      .data_buf_load_ext(data_buf_load_ext),
                      .data_buf_write_ext(data_buf_write_ext),
                      .inst_reg_load    (inst_reg_load),
                      .A_load           (A_load),
                      .F_load           (F_load),
                      .temp1_load       (temp1_load),
                      .temp0_load       (temp0_load),
                      .IF_load_l        (IF_load_l),
                      .IME_set          (IME_set),
                      .IME_reset        (IME_reset),
                      .regfile_data_gate(regfile_data_gate),
                      .A_data_gate      (A_data_gate),
                      .F_data_gate      (F_data_gate),
                      .alu_data_gate    (alu_data_gate),
                      .regfile_addr_gate(regfile_addr_gate),
                      .interrupt_data_gate(interrupt_data_gate),
                      .alu_data1_in_sel (alu_data1_in_sel[1:0]),
                      .alu_data0_in_sel (alu_data0_in_sel[1:0]),
                      .addr_ff00_sel    (addr_ff00_sel),
                      .alu_op           (alu_op[4:0]),
                      .alu_size         (alu_size[1:0]),
                      .halt             (halt),
                      .debug_halt       (debug_halt),
                      // Inputs
                      .bp_step          (bp_step),
                      .bp_continue      (bp_continue),
                      .bp_pc            (bp_pc),
                      .instruction      (instruction[7:0]),
                      .taken            (taken),
                      .interrupt        (interrupt),
                      .IME_data         (IME_data),
                      .clock            (clock),
                      .reset            (reset));

    /*
   // synthesis translate_off
   integer fd;
   always @(posedge clock) begin
      if (~reset && halt) begin
         fd = $fopen("cpu_dump.txt");
         $fdisplay(fd, "AF %4h", {A_data, F_data});
         $fclose(fd);
      end
   end
   // synthesis translate_on
   */
endmodule // cpu

/**
 * Decoder for Nintendo's register values.
 * 
 * @output rgf_rn_out The regfile index value.
 * @input rgf_rn_in A regfile index value. If it is not `RGF_NONE, then this
 *    value is passed through. Otherwise, {rn16, rn} is decoded.
 * @input rn A 3-bit register number as specified in the GB Programming Manual.
 * @input rn16 1 if using a 16-bit register code in rn, 0 if using an 8-bit
 *    register code.
 * @input lo 1 if selecting the low bits of a 16-bit register code, 0 otherwise
 *    (should use this only in conjunction with rn16 == 1).
 * @input hi 1 if selecting the high bits of a 16-bit register code, 0
 *    otherwise.
 */
module rn_decode(/*AUTOARG*/
   // Outputs
   rgf_rn_out,
   // Inputs
   rgf_rn_in, rn, rn16, lo, hi
   );
   output reg [4:0]   rgf_rn_out;
   input [4:0]        rgf_rn_in;
   input [2:0]        rn;
   input              rn16, lo, hi;
   
   always @(*) begin
      if (rgf_rn_in == `RGF_NONE) begin
         if (~rn16) begin
            case (rn)
              `NIN_B: rgf_rn_out = `RGF_B;
              `NIN_C: rgf_rn_out = `RGF_C;
              `NIN_D: rgf_rn_out = `RGF_D;
              `NIN_E: rgf_rn_out = `RGF_E;
              `NIN_H: rgf_rn_out = `RGF_H;
              `NIN_L: rgf_rn_out = `RGF_L;
              default: rgf_rn_out = `RGF_B;
            endcase
         end else if (hi) begin
            case (rn)
              `NIN_BC: rgf_rn_out = `RGF_B;
              `NIN_DE: rgf_rn_out = `RGF_D;
              `NIN_HL: rgf_rn_out = `RGF_H;
              `NIN_SP: rgf_rn_out = `RGF_SPH;
              default: rgf_rn_out = `RGF_B;
            endcase
         end else if (lo) begin
            case (rn)
              `NIN_BC: rgf_rn_out = `RGF_C;
              `NIN_DE: rgf_rn_out = `RGF_E;
              `NIN_HL: rgf_rn_out = `RGF_L;
              `NIN_SP: rgf_rn_out = `RGF_SPL;
              default: rgf_rn_out = `RGF_B;
            endcase
         end else begin
            case(rn)
              `NIN_BC: rgf_rn_out = `RGF_BC;
              `NIN_DE: rgf_rn_out = `RGF_DE;
              `NIN_HL: rgf_rn_out = `RGF_HL;
              `NIN_SP: rgf_rn_out = `RGF_SP;
              default: rgf_rn_out = `RGF_B;
            endcase
         end
      end else begin
         rgf_rn_out = rgf_rn_in;
      end
   end
endmodule // rn_decode

/**
 * A simple register.
 * 
 * @parameter width The width of the register in bits.
 * @parameter reset_value The value to reset the register to.
 * @output q The data output.
 * @input d The data input.
 * @input load Loads the register with the value on d.
 * @input clock A clock.
 * @input reset A posedge reset.
 */
module register(/*AUTOARG*/
   // Outputs
   q,
   // Inputs
   d, load, clock, reset
   );
   parameter
     width = 8,
     reset_value = 0;
   
   output reg [(width - 1):0] q;
   input [(width - 1):0]      d;
   input                      load;
   input                      clock, reset;

   always @(posedge clock or posedge reset) begin
      if (reset) begin
         q <= reset_value;
      end
      else if (load) begin
         q <= d;
      end
   end
   
endmodule // register

/**
 * A buffer.
 * 
 * @parameter width The width of the buffer in bits.
 * @parameter reset_value The value to set the buffer to on reset.
 * @inout bus_in An internal bus.
 * @inout bus_ext An external bus.
 * @input bus_in_read Reads data from the internal bus to the buffer.
 * @input bus_in_write Writes the data from the buffer to the internal bus.
 * @input bus_ext_read Reads data from the external bus to the buffer.
 * @input bus_ext_write Writes data from the buffer to the external bus.
 * @input clock The clock.
 * @input reset A posedge reset.
 */
module buffer(/*AUTOARG*/
   // Inouts
   bus_in, bus_ext,
   // Inputs
   bus_in_read, bus_in_write, bus_ext_read, bus_ext_write, clock,
   reset
   );
   parameter
     width = 8,
     reset_value = 0;

   inout [(width - 1):0] bus_in;
   inout [(width - 1):0] bus_ext;
   input                 bus_in_read, bus_in_write, bus_ext_read, bus_ext_write;
   input                 clock, reset;
   
   reg [(width - 1):0]   q;

   assign bus_in = (bus_in_write) ? q : {width{1'bz}};
   assign bus_ext = (bus_ext_write) ? q : {width{1'bz}};

   always @(posedge clock or posedge reset) begin
      if (reset) begin
         q <= reset_value;
      end
      else if (bus_in_read) begin
         q <= bus_in;
      end
      else if (bus_ext_read) begin
         q <= bus_ext;
      end
   end
   
endmodule // buffer

/**
 * A buffer that has an internal bus and external data in and out lines.
 * 
 * This is used to facilitate connection to the high memory module in the CPU.
 */
module nobus_buffer(/*AUTOARG*/
   // Outputs
   bus_ext_out,
   // Inouts
   bus,
   // Inputs
   bus_ext_in, bus_read, bus_write, bus_ext_read, clock, reset
   );
   parameter
     width = 8,
     reset_value = 0;

   inout [width-1:0] bus;
   
   output wire [(width-1):0] bus_ext_out;
   input [(width-1):0]       bus_ext_in;

   input                     bus_read, bus_write, bus_ext_read;
   input                     clock, reset;
   
   reg [(width - 1):0] q;

   assign bus = (bus_write) ? q : {width{1'bz}};
   assign bus_ext_out = q;
   
   always @(posedge clock or posedge reset) begin
      if (reset) begin
         q <= reset_value;
      end
      else if (bus_read) begin
         q <= bus;
      end
      else if (bus_ext_read) begin
         q <= bus_ext_in;
      end
   end
   
endmodule

// Local Variables:
// verilog-library-directories:(".")
// End:
