`timescale 1ns / 1ps
`default_nettype wire
`include "common.v"
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
    input  [7:0] opcode_early,
    /* verilator lint_off UNUSED */
    input  [7:0] imm,
    /* verilator lint_on UNUSED */
    input  [7:0] cb,
    input  [2:0] m_cycle,
    input  [2:0] ct_state,
    input        f_z,
    input        f_c,
    output reg [1:0] alu_src_a,
    output reg [2:0] alu_src_b,
    output reg       alu_src_xchg,
    output reg [1:0] alu_op_prefix,
    output reg [1:0] alu_op_src,
    output reg       alu_op_signed,
    output reg [1:0] alu_dst,
    output reg [1:0] pc_src,
    output reg       pc_we,
    output reg       pc_b_sel,
    output reg       pc_jr,
    output reg       pc_revert,
    output reg [2:0] rf_wr_sel,
    output reg [2:0] rf_rd_sel,
    output reg [1:0] rf_rdw_sel,
    output reg       temp_redir,
    output reg       opcode_redir,
    output reg [1:0] bus_op,
    output reg [1:0] db_src,
    output reg [1:0] ab_src,
    output reg [1:0] ct_op,
    output reg       flags_we,
    output reg [1:0] flags_pattern,
    output reg       high_mask,
    output           int_master_en,
    input            int_dispatch,
    output reg       int_ack,
    output reg       next,
    output reg       stop,
    output reg       halt,
    input            wake,
    output reg       fault
    );

    reg [7:0] opcode;
    // opcode is available one clock earlier
    always @(posedge clk) begin
        // input should be high low nibble swapped
        opcode <= opcode_early;
    end

    reg ime_clear;
    reg ime_set;
    reg ime_delay_set;
    reg ime_delay_set_ff;
    reg ime;
    assign int_master_en = ime;

    always @(posedge clk)
        if (ct_state == 2'd3)
            ime_delay_set_ff <= ime_delay_set;

    always @(posedge clk, posedge rst) begin
        if (rst)
            ime <= 1'b0;
        else if (ime_clear)
            ime <= 1'b0;
        else if (ime_set)
            ime <= 1'b1;
        else if (ime_delay_set_ff)
            ime <= 1'b1;
    end

    reg int_dispatch_deffered;
    always @(posedge clk) begin
        int_dispatch_deffered <= int_dispatch;
    end
    //wire int_dispatch_deffered = int_dispatch;

    reg halt_last;
    reg stop_last;
    reg fault_last;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            halt_last <= 1'b0;
            stop_last <= 1'b0;
            fault_last <= 1'b0;
        end
        else begin
            halt_last <= halt;
            stop_last <= stop;
            fault_last <= fault;
        end
    end

    // All these nonsense will be replaced by a vector decoding ROM... 
    // in the future
    always @(*) begin
        // Set default output
        // ACC = ACC + 0
        alu_src_a = `ALU_SRC_A_ACC;
        alu_src_b = `ALU_SRC_B_ZERO;
        alu_op_prefix = `ALU_OP_PREFIX_NORMAL;
        alu_op_src = `ALU_OP_SRC_ADD_FTOR;
        alu_dst = `ALU_DST_ACC;
        pc_we = 0;
        rf_wr_sel = `RF_SEL_B; // Doesn't matter
        rf_rd_sel = `RF_SEL_B; // Doesn't matter
        bus_op = `BUS_OP_IF; // Fetch next instruction
        db_src = `DB_SRC_DB; // Should != ACC
        ab_src = `AB_SRC_PC; // Output PC
        ct_op = `CT_OP_PC_INC; // PC = PC + 1
        flags_we = 0;
        next = 0;
        alu_src_xchg = 0;
        rf_rdw_sel = 2'b10; // Select HL
        pc_src = 2'b00;
        pc_b_sel = m_cycle[0];
        pc_jr = 1'b0;
        pc_revert = 1'b0;
        stop = 1'b0;
        halt = 1'b0;
        fault = 1'b0;
        high_mask = 1'b0;
        alu_op_signed = 1'b0;
        temp_redir = 1'b0;
        opcode_redir = 1'b0;
        ime_set = 1'b0;
        ime_delay_set = 1'b0;
        ime_clear = 1'b0;
        int_ack = 1'b0;
        flags_pattern = 2'b00;
        // Though the idea behind the original GB is that when in halt or stop
        // mode, the clock can be stopped, thus lower the power consumption and
        // save the battery. On FPGA, this is hard to achieve since clocking in
        // FPGA works very differently than on ASIC. So here, when halted, CPU
        // would executing NOP in place as if it was halted.
        if (halt_last || stop_last || fault_last) begin
            // Wake up condition
            halt = halt_last;
            stop = stop_last;
            fault = fault_last;
            if (wake) begin
                halt = 1'b0;
                stop = 1'b0;
                // Fault could not be waked up 
            end
        end
        else if (int_dispatch_deffered) begin
            // Interrupt dispatch process
            case (m_cycle)
            0: begin
                // Revert PC
                pc_revert = 1'b1;
                bus_op = `BUS_OP_IDLE;
                ct_op = `CT_OP_SP_DEC;
                next = 1'b1;
            end
            1: begin
                // Save PCh
                alu_src_a = `ALU_SRC_A_PC;
                alu_dst = `ALU_DST_DB;
                bus_op = `BUS_OP_WRITE;
                ab_src = `AB_SRC_SP;
                db_src = `DB_SRC_DB;
                ct_op = `CT_OP_SP_DEC;
                next = 1'b1;
            end
            2: begin
                // Save PCl
                alu_src_a = `ALU_SRC_A_PC;
                alu_dst = `ALU_DST_DB;
                bus_op = `BUS_OP_WRITE;
                ab_src = `AB_SRC_SP;
                db_src = `DB_SRC_DB;
                ct_op = `CT_OP_IDLE;
                pc_we = 1;
                next = 1'b1;
            end
            3: begin
                // Normal instruction fetch process
                ime_clear = 1'b1;
                int_ack = 1'b1;
            end
            endcase
        end
        else begin
            if (opcode == 2'b00) begin // NOP
                // Default behavior is enough
            end
            else if (opcode == 8'h10) begin // STOP
                stop = 1;
            end
            else if (opcode == 8'h76) begin // HALT
                halt = 1;
            end
            else if (opcode == 8'hF3) begin // DI
                ime_clear = 1'b1;
            end
            else if (opcode == 8'hFB) begin // EI
                // EI here need to be delayed for 1 clock?
                ime_delay_set = 1'b1;
            end
            // 16-bit IMM to register LD instructions
            else if ((opcode[7:6] == 2'b00) && (opcode[3:0] == 4'b0001)) begin
                alu_src_a = `ALU_SRC_A_DB; // Load from databus
                alu_dst = `ALU_DST_REG; // Load to register
                db_src = `DB_SRC_DB; // DB destination to databus buffer
                if ((m_cycle == 0) || (m_cycle == 1)) begin
                    rf_wr_sel = {opcode[5:4], 1'b1}; // Register no based on opcode
                    bus_op = `BUS_OP_READ; // Read from databus
                    next = 1;
                end
                else begin
                    rf_wr_sel = {opcode[5:4], 1'b0};
                    next = 0;
                end
            end
            // LD (nn), SP
            else if (opcode == 8'h08) begin 
                if ((m_cycle == 0) || (m_cycle == 1)) begin
                    bus_op = `BUS_OP_READ;
                    db_src = `DB_SRC_DB;
                    ab_src = `AB_SRC_PC;
                    ct_op = `CT_OP_PC_INC;
                    next = 1;
                end
                else if (m_cycle == 2) begin
                    ab_src = `AB_SRC_TEMP;
                    db_src = `DB_SRC_REG;
                    rf_rd_sel = `RF_SEL_SP_L;
                    bus_op = `BUS_OP_WRITE;
                    ct_op = `CT_OP_SP_INC;
                    temp_redir = 1'b1;
                    next = 1'b1;
                end
                else if (m_cycle == 3) begin
                    ab_src = `AB_SRC_TEMP;
                    db_src = `DB_SRC_REG;
                    rf_rd_sel = `RF_SEL_SP_H;
                    bus_op = `BUS_OP_WRITE;
                    ct_op = `CT_OP_IDLE;
                    next = 1'b1;
                end
                else begin
                    // Default behaviour is enough.
                end
            end
            // 8 bit reg-to-reg, mem-to-reg, or reg-to-mem LD instructions
            else if (opcode[7:6] == 2'b01) begin
                if (opcode[2:0] == 3'b110)
                    alu_src_a = `ALU_SRC_A_DB; // Src A from data bus
                else if (opcode[2:0] == 3'b111)
                    alu_src_a = `ALU_SRC_A_ACC; // Src A from accumulator
                else
                    alu_src_a = `ALU_SRC_A_REG; // Src A from register file

                if (opcode[5:3] == 3'b110)
                    alu_dst = `ALU_DST_DB; // Destination is (HL)
                else if (opcode[5:3] == 3'b111) 
                    alu_dst = `ALU_DST_ACC; // Destination is A
                else
                    alu_dst = `ALU_DST_REG; // Destination is register
                
                rf_wr_sel = opcode[5:3];
                rf_rd_sel = opcode[2:0];

                if (opcode[5:3] == 3'b110) begin // Register to Memory
                    if (m_cycle == 0) begin
                        bus_op = `BUS_OP_WRITE;
                        db_src = `DB_SRC_ALU;
                        ab_src = `AB_SRC_REG;
                        ct_op = `CT_OP_IDLE;
                        next = 1;
                    end
                end
                else if (opcode[2:0] == 3'b110) begin // Memory to Register
                    if (m_cycle == 0) begin
                        bus_op = `BUS_OP_READ;
                        db_src = `DB_SRC_DB;
                        ab_src = `AB_SRC_REG;
                        ct_op = `CT_OP_IDLE;
                        next = 1;
                    end
                end
            end
            // 8 bit imm-to-reg, imm-to-mem LD instructions
            else if ((opcode[7:6] == 2'b00) && (opcode[2:0] == 3'b110)) begin
                alu_src_a = `ALU_SRC_A_DB;
                
                if (opcode[5:3] == 3'b110) begin // imm to mem
                    alu_dst = `ALU_DST_DB;
                    rf_rd_sel = `RF_SEL_HL;
                end
                else if (opcode[5:3] == 3'b111) begin
                    alu_dst = `ALU_DST_ACC;
                end
                else begin
                    alu_dst = `ALU_DST_REG;
                    rf_wr_sel = opcode[5:3];
                end

                if (m_cycle == 0) begin
                    bus_op = `BUS_OP_READ;
                    next = 1;
                end
                else if (m_cycle == 1) begin
                    if (opcode[5:3] == 3'b110) begin
                        bus_op = `BUS_OP_WRITE;
                        db_src = `DB_SRC_DB;
                        ab_src = `AB_SRC_REG;
                        ct_op = `CT_OP_IDLE;
                        next = 1;
                    end
                end
            end
            // LD (BC)/(DE), A
            else if ((opcode == 8'h02) || (opcode == 8'h12)) begin
                alu_dst = `ALU_DST_DB;
                if (opcode == 8'h02)
                    rf_rdw_sel = 2'b00; // Select BC
                else
                    rf_rdw_sel = 2'b01; // Select DE
                if (m_cycle == 0) begin
                    next = 1;
                    bus_op = `BUS_OP_WRITE;
                    ab_src = `AB_SRC_REG;
                    ct_op = `CT_OP_IDLE;
                end
            end
            // LD (HL+)/(HL-), A
            else if ((opcode == 8'h22) || (opcode == 8'h32)) begin
                alu_src_a = `ALU_SRC_A_REG;
                alu_dst = `ALU_DST_REG;
                if (opcode == 8'h22)
                    alu_op_src = `ALU_OP_SRC_ADD_FTOR;
                else
                    alu_op_src = `ALU_OP_SRC_SUB_ATOF;
                if (m_cycle == 0) begin
                    // A being written to the memory, calculate L +/- 1
                    alu_src_b = `ALU_SRC_B_ONE;
                    rf_rd_sel = `RF_SEL_L;
                    rf_wr_sel = `RF_SEL_L;
                    bus_op = `BUS_OP_WRITE;
                    db_src = `DB_SRC_ACC;
                    ab_src = `AB_SRC_REG;
                    ct_op = `CT_OP_IDLE;
                    next = 1;
                end
                else begin
                    // calculate H +/- carry
                    alu_src_b = `ALU_SRC_B_CARRY;
                    rf_rd_sel = `RF_SEL_H;
                    rf_wr_sel = `RF_SEL_H;
                end
            end
            // LD A, (BC)/(DE)
            else if ((opcode == 8'h0A) || (opcode == 8'h1A)) begin
                alu_src_a = `ALU_SRC_A_DB;
                if (opcode == 8'h0A) begin
                    rf_rdw_sel = 2'b00; // Select BC
                end
                else begin
                    rf_rdw_sel = 2'b01; // Select DE
                end

                if (m_cycle == 0) begin
                    bus_op = `BUS_OP_READ;
                    db_src = `DB_SRC_DB;
                    ab_src = `AB_SRC_REG;
                    ct_op = `CT_OP_IDLE;
                    next = 1;
                end
            end
            // LD A, (HL+)/(HL-)
            else if ((opcode == 8'h2A) || (opcode == 8'h3A)) begin
                alu_src_a = `ALU_SRC_A_REG;
                alu_src_b = `ALU_SRC_B_ONE;
                if (opcode == 8'h2A)
                    alu_op_src = `ALU_OP_SRC_ADD_FTOR;
                else
                    alu_op_src = `ALU_OP_SRC_SUB_ATOF;
                alu_dst = `ALU_DST_REG;
                if (m_cycle == 0) begin
                    alu_src_b = `ALU_SRC_B_ONE;
                    rf_rd_sel = `RF_SEL_L;
                    rf_wr_sel = `RF_SEL_L;
                    bus_op = `BUS_OP_READ;
                    db_src = `DB_SRC_ACC;
                    ab_src = `AB_SRC_REG;
                    ct_op = `CT_OP_IDLE;
                    next = 1;
                end
                else begin
                    alu_src_b = `ALU_SRC_B_CARRY;
                    rf_rd_sel = `RF_SEL_H;
                    rf_wr_sel = `RF_SEL_H;
                end
            end
            // 16-bit INC/DEC
            else if ((opcode[7:6] == 2'b00) && (opcode[2:0] == 3'b011)) begin
                alu_src_a = `ALU_SRC_A_REG;
                alu_dst = `ALU_DST_REG;
                if (opcode[3] == 1) begin
                    alu_op_src = `ALU_OP_SRC_SUB_ATOF;
                end
                if (m_cycle == 0) begin
                    alu_src_b = `ALU_SRC_B_ONE;
                    rf_rd_sel = {opcode[5:4], 1'b1};
                    rf_wr_sel = {opcode[5:4], 1'b1};
                    bus_op = `BUS_OP_IDLE;
                    ct_op = `CT_OP_IDLE;
                    db_src = `DB_SRC_DB;
                    next = 1;
                end
                else begin
                    alu_src_b = `ALU_SRC_B_CARRY;
                    rf_rd_sel = {opcode[5:4], 1'b0};
                    rf_wr_sel = {opcode[5:4], 1'b0};
                end
            end
            // 8-bit INC/DEC
            else if ((opcode[7:6] == 2'b00) && (opcode[2:1] == 2'b10)) begin
                alu_src_b = `ALU_SRC_B_ONE;
                flags_pattern = `FLAGS_ZNHx;
                flags_we = 1'b1;

                // INC or DEC
                if (opcode[0])
                    alu_op_src = `ALU_OP_SRC_SUB_ATOF;
                else
                    alu_op_src = `ALU_OP_SRC_ADD_FTOR;

                if (opcode[5:3] == 3'b110) begin
                    // INC/DEC (HL)
                    alu_src_a = `ALU_SRC_A_DB;
                    alu_dst = `ALU_DST_DB;
                    if (m_cycle == 0) begin
                        bus_op = `BUS_OP_READ;
                        db_src = `DB_SRC_REG;
                        ab_src = `AB_SRC_REG;
                        ct_op = `CT_OP_IDLE;
                        next = 1;
                    end
                    else if (m_cycle == 1) begin
                        bus_op = `BUS_OP_WRITE;
                        ab_src = `AB_SRC_REG;
                        ct_op = `CT_OP_IDLE;
                        next = 1;
                    end
                    else begin
                        // End cycle
                        flags_we = 0;
                    end
                end
                else if (opcode[5:3] == 3'b111) begin
                    // INC/DEC A
                    alu_src_a = `ALU_SRC_A_ACC;
                    alu_dst = `ALU_DST_ACC;
                end
                else begin
                    alu_src_a = `ALU_SRC_A_REG;
                    alu_dst = `ALU_DST_REG;
                    rf_rd_sel = opcode[5:3];
                    rf_wr_sel = opcode[5:3];
                end
            end
            // ADD HL, r16
            else if ((opcode[7:6] == 2'b00) && (opcode[3:0] == 4'b1001)) begin
                alu_dst = `ALU_DST_REG;
                flags_we = 1'b1;
                flags_pattern = `FLAGS_x0HC;
                if (m_cycle == 0) begin
                    alu_src_a = `ALU_SRC_A_REG;
                    alu_src_b = `ALU_SRC_B_L;
                    rf_wr_sel = `RF_SEL_L;
                    rf_rd_sel = {opcode[5:4], 1'b1};
                    bus_op = `BUS_OP_IDLE;
                    ct_op = `CT_OP_IDLE;
                    next = 1;
                end
                else begin
                    alu_src_a = `ALU_SRC_A_REG;
                    alu_src_b = `ALU_SRC_B_H;
                    rf_wr_sel = `RF_SEL_H;
                    rf_rd_sel = {opcode[5:4], 1'b0};
                    alu_op_signed = 1'b1;
                end
            end
            // 8 bit reg-to-reg, mem-to-reg ALU operation
            else if (opcode[7:6] == 2'b10) begin
                alu_src_b = `ALU_SRC_B_ACC;
                alu_op_src = `ALU_OP_SRC_INSTR_5TO3;
                rf_rd_sel = opcode[2:0];
                flags_we = 1'b1;
                if ((opcode[5:4] == 2'b01) || (opcode[5:3] == 3'b111)) begin
                    // Sub or CP
                    alu_src_xchg = 1'b1;
                end
                if (opcode[2:0] == 3'b110) begin // Source from HL
                    alu_src_a = `ALU_SRC_A_DB;
                    if (m_cycle == 0) begin 
                        bus_op = `BUS_OP_READ;
                        ab_src = `AB_SRC_REG;
                        // Do not writeback in the first cycle
                        alu_src_b = `ALU_SRC_B_ZERO;
                        alu_op_src = `ALU_OP_SRC_ADD_FTOR;
                        ct_op = `CT_OP_IDLE;
                        next = 1;
                    end
                end
                else if (opcode[2:0] == 3'b111) begin // Source from A
                    alu_src_a = `ALU_SRC_A_ACC;
                end
                else begin
                    alu_src_a = `ALU_SRC_A_REG;
                end
            end
            // 8 bit imm-to-reg ALU operation
            else if ((opcode[7:6] == 2'b11) && (opcode[2:0] == 3'b110)) begin
                if (m_cycle == 0) begin 
                    bus_op = `BUS_OP_READ;
                    next = 1;
                end
                else begin
                    if ((opcode[5:4] == 2'b01) || (opcode[5:3] == 3'b111)) begin
                        // Sub or CP
                        alu_src_xchg = 1'b1;
                    end
                    alu_src_a = `ALU_SRC_A_DB;
                    alu_src_b = `ALU_SRC_B_ACC;
                    alu_op_src = `ALU_OP_SRC_INSTR_5TO3;
                    flags_we = 1'b1;
                end
            end
            // 16-bit PUSH
            else if ((opcode[7:6] == 2'b11) && (opcode[3:0] == 4'b0101)) begin
                if (opcode[5:4] == 2'b11) begin
                    // AF
                    alu_op_prefix = `ALU_OP_PREFIX_SPECIAL;
                    db_src = `DB_SRC_ACC;
                end
                else begin
                    db_src = `DB_SRC_DB;
                end
                alu_src_a = `ALU_SRC_A_REG;
                alu_dst = `ALU_DST_DB;

                if (m_cycle == 0) begin
                    bus_op = `BUS_OP_IDLE;
                    ab_src = `AB_SRC_SP;
                    ct_op = `CT_OP_SP_DEC;
                    next = 1;
                end
                else if (m_cycle == 1) begin
                    bus_op = `BUS_OP_WRITE;
                    ab_src = `AB_SRC_SP;
                    ct_op = `CT_OP_SP_DEC;
                    rf_rd_sel = {opcode[5:4], 1'b0};
                    next = 1;
                end
                else if (m_cycle == 2) begin
                    bus_op = `BUS_OP_WRITE;
                    ab_src = `AB_SRC_SP;
                    ct_op = `CT_OP_IDLE;
                    rf_rd_sel = {opcode[5:4], 1'b1};
                    if (opcode[5:4] == 2'b11) begin
                        db_src = `DB_SRC_ALU;
                    end
                    next = 1;
                end
            end
            // 16-bit POP
            else if ((opcode[7:6] == 2'b11) && (opcode[3:0] == 4'b0001)) begin
                if ((m_cycle == 1) || (m_cycle == 2)) begin
                    alu_src_a = `ALU_SRC_A_DB;
                    if (opcode[5:4] == 2'b11) begin
                        alu_dst = `ALU_DST_ACC;
                    end
                    else begin 
                        alu_dst = `ALU_DST_REG;
                    end
                end

                if (m_cycle == 0) begin
                    bus_op = `BUS_OP_READ;
                    db_src = `DB_SRC_DB;
                    ab_src = `AB_SRC_SP;
                    ct_op = `CT_OP_SP_INC;
                    next = 1;
                end
                else if (m_cycle == 1) begin
                    bus_op = `BUS_OP_READ;
                    db_src = `DB_SRC_DB;
                    ab_src = `AB_SRC_SP;
                    ct_op = `CT_OP_SP_INC;
                    rf_wr_sel = {opcode[5:4], 1'b1};
                    next = 1;
                end
                else if (m_cycle == 2) begin
                    rf_wr_sel = {opcode[5:4], 1'b0};
                    if (opcode[5:4] == 2'b11) begin
                        // Copy from memory to flags
                        alu_op_prefix = `ALU_OP_PREFIX_SPECIAL;
                        alu_op_src = `ALU_OP_SRC_SUB_ATOF;
                        alu_src_b = `ALU_SRC_B_ACC;
                        flags_we = 1'b1;
                    end
                end
            end
            // LD (C), A
            else if (opcode == 8'he2) begin
                rf_rdw_sel = 2'b00; // Select BC
                high_mask = 1'b1; // Select C only
                alu_src_a = `ALU_SRC_A_ACC;
                if (m_cycle == 0) begin
                    bus_op = `BUS_OP_WRITE;
                    db_src = `DB_SRC_ACC;
                    ab_src = `AB_SRC_REG;
                    ct_op = `CT_OP_IDLE;
                    next = 1;
                end
            end
            // LD A, (C)
            else if (opcode == 8'hf2) begin
                rf_rdw_sel = 2'b00; // Select BC
                high_mask = 1'b1; // Select C only
                alu_src_a = `ALU_SRC_A_DB;
                if (m_cycle == 0) begin
                    bus_op = `BUS_OP_READ;
                    db_src = `DB_SRC_DB;
                    ab_src = `AB_SRC_REG;
                    ct_op = `CT_OP_IDLE;
                    next = 1'b1;
                end
            end
            // ADD SP, r8
            else if (opcode == 8'he8) begin
                if (m_cycle == 0) begin
                    bus_op = `BUS_OP_READ;
                    db_src = `DB_SRC_DB;
                    next = 1;
                end
                else if (m_cycle == 1) begin
                    alu_src_a = `ALU_SRC_A_REG;
                    alu_src_b = `ALU_SRC_B_IMM;
                    alu_dst = `ALU_DST_REG;
                    rf_rd_sel = `RF_SEL_SP_L;
                    rf_wr_sel = `RF_SEL_SP_L;
                    bus_op = `BUS_OP_IDLE;
                    ct_op = `CT_OP_IDLE;
                    flags_pattern = `FLAGS_00HC;
                    flags_we = 1'b1;
                    next = 1;
                end
                else if (m_cycle == 2) begin
                    alu_src_a = `ALU_SRC_A_REG;
                    alu_src_b = `ALU_SRC_B_IMM;
                    alu_dst = `ALU_DST_REG;
                    alu_op_signed = 1'b1;
                    rf_rd_sel = `RF_SEL_SP_H;
                    rf_wr_sel = `RF_SEL_SP_H;
                    bus_op = `BUS_OP_IDLE;
                    ct_op = `CT_OP_IDLE;
                    next = 1;
                end
            end
            // LD HL, SP+r8
            else if (opcode == 8'hf8) begin
                if (m_cycle == 0) begin
                    bus_op = `BUS_OP_READ;
                    db_src = `DB_SRC_DB;
                    next = 1;
                end
                else if (m_cycle == 1) begin
                    alu_src_a = `ALU_SRC_A_REG;
                    alu_src_b = `ALU_SRC_B_IMM;
                    alu_dst = `ALU_DST_REG;
                    rf_rd_sel = `RF_SEL_SP_L;
                    rf_wr_sel = `RF_SEL_L;
                    bus_op = `BUS_OP_IDLE;
                    ct_op = `CT_OP_IDLE;
                    flags_pattern = `FLAGS_00HC;
                    flags_we = 1'b1;
                    next = 1;
                end
                else begin
                    alu_op_signed = 1'b1;
                    alu_src_a = `ALU_SRC_A_REG;
                    alu_src_b = `ALU_SRC_B_IMM;
                    alu_dst = `ALU_DST_REG;
                    rf_rd_sel = `RF_SEL_SP_H;
                    rf_wr_sel = `RF_SEL_H;
                end
            end
            // LD SP, HL
            else if (opcode == 8'hf9) begin
                alu_src_a = `ALU_SRC_A_REG;
                alu_dst = `ALU_DST_REG;
                
                if (m_cycle == 0) begin
                    rf_wr_sel = `RF_SEL_SP_H;
                    rf_rd_sel = `RF_SEL_H;
                    bus_op = `BUS_OP_IDLE;
                    ct_op = `CT_OP_IDLE;
                    next = 1;
                end
                else begin
                    rf_wr_sel = `RF_SEL_SP_L;
                    rf_rd_sel = `RF_SEL_L;
                end
            end
            // LDH (a8), A
            else if (opcode == 8'hE0) begin
                if (m_cycle == 0) begin
                    bus_op = `BUS_OP_READ;
                    db_src = `DB_SRC_DB;
                    next = 1;
                end
                else if (m_cycle == 1) begin
                    alu_src_a = `ALU_SRC_A_ACC;
                    alu_dst = `ALU_DST_DB;
                    bus_op = `BUS_OP_WRITE;
                    db_src = `DB_SRC_ACC;
                    ab_src = `AB_SRC_TEMP;
                    ct_op = `CT_OP_IDLE;
                    high_mask = 1;
                    next = 1;
                end
            end
            // LDH A, (a8)
            else if (opcode == 8'hF0) begin
                if (m_cycle == 0) begin
                    bus_op = `BUS_OP_READ;
                    db_src = `DB_SRC_DB;
                    next = 1;
                end
                else if (m_cycle == 1) begin
                    bus_op = `BUS_OP_READ;
                    ab_src = `AB_SRC_TEMP;
                    ct_op = `CT_OP_IDLE;
                    high_mask = 1;
                    next = 1;
                end
                else begin
                    alu_src_a = `ALU_SRC_A_DB;
                    alu_dst = `ALU_DST_ACC;
                end
            end
            // LD (a16), A
            else if (opcode == 8'hEA) begin
                if ((m_cycle == 0) || (m_cycle == 1)) begin
                    bus_op = `BUS_OP_READ;
                    db_src = `DB_SRC_DB;
                    next = 1;
                end
                else if (m_cycle == 2) begin
                    alu_src_a = `ALU_SRC_A_ACC;
                    alu_dst = `ALU_DST_DB;
                    bus_op = `BUS_OP_WRITE;
                    db_src = `DB_SRC_ACC;
                    ab_src = `AB_SRC_TEMP;
                    ct_op = `CT_OP_IDLE;
                    next = 1;
                end
            end
            // LDH A, (a16)
            else if (opcode == 8'hFA) begin
                if ((m_cycle == 0) || (m_cycle == 1)) begin
                    bus_op = `BUS_OP_READ;
                    db_src = `DB_SRC_DB;
                    next = 1;
                end
                else if (m_cycle == 2) begin
                    bus_op = `BUS_OP_READ;
                    ab_src = `AB_SRC_TEMP;
                    ct_op = `CT_OP_IDLE;
                    next = 1;
                end
                else begin
                    alu_src_a = `ALU_SRC_A_DB;
                    alu_dst = `ALU_DST_ACC;
                end
            end
            // JP HL
            else if (opcode == 8'hE9) begin
                rf_rd_sel = `RF_SEL_H;
                ab_src = `AB_SRC_REG;
                pc_we = 1;
            end
            // JP CC, a16
            else if ((opcode == 8'hC3) || (opcode == 8'hC2) || (opcode == 8'hD2)
                    || (opcode == 8'hCA) || (opcode == 8'hDA)) begin
                if ((m_cycle == 0) || (m_cycle == 1)) begin
                    // Read 16 bit imm
                    bus_op = `BUS_OP_READ;
                    db_src = `DB_SRC_DB;
                    next = 1;
                end
                else if (m_cycle == 2) begin
                    if (((opcode == 8'hC2) && (!f_z)) ||     // JP NZ
                        ((opcode == 8'hD2) && (!f_c)) ||     // JP NC
                        ((opcode == 8'hC3)) ||               // JP
                        ((opcode == 8'hCA) && (f_z)) ||      // JP Z
                        ((opcode == 8'hDA) && (f_c))) begin  // JP C
                        // Branch taken
                        pc_src = `PC_SRC_TEMP;
                        bus_op = `BUS_OP_IDLE;
                        ct_op = `CT_OP_IDLE;
                        pc_we = 1;
                        next = 1;
                    end
                    // Branch not taken
                end
            end
            // CALL CC, a16
            else if ((opcode == 8'hCD) || (opcode == 8'hCC) || (opcode == 8'hDC)
                    || (opcode == 8'hC4) || (opcode == 8'hD4)) begin
                if ((m_cycle == 0) || (m_cycle == 1)) begin
                    // Read 16 bit imm
                    bus_op = `BUS_OP_READ;
                    db_src = `DB_SRC_DB;
                    next = 1;
                end
                else if (m_cycle == 2) begin
                    if (((opcode == 8'hC4) && (!f_z)) ||     // CALL NZ
                        ((opcode == 8'hD4) && (!f_c)) ||     // CALL NC
                        ((opcode == 8'hCD)) ||               // CALL
                        ((opcode == 8'hCC) && (f_z)) ||      // CALL Z
                        ((opcode == 8'hDC) && (f_c))) begin  // CALL C
                        // Call taken
                        bus_op = `BUS_OP_IDLE;
                        ct_op = `CT_OP_SP_DEC;
                        next = 1;
                    end
                end
                else if (m_cycle == 3) begin
                    alu_src_a = `ALU_SRC_A_PC;
                    alu_dst = `ALU_DST_DB;
                    bus_op = `BUS_OP_WRITE;
                    ab_src = `AB_SRC_SP;
                    db_src = `DB_SRC_DB;
                    ct_op = `CT_OP_SP_DEC;
                    next = 1;
                end
                else if (m_cycle == 4) begin
                    alu_src_a = `ALU_SRC_A_PC;
                    alu_dst = `ALU_DST_DB;
                    pc_src = `PC_SRC_TEMP;
                    pc_we = 1;
                    bus_op = `BUS_OP_WRITE;
                    ab_src = `AB_SRC_SP;
                    db_src = `DB_SRC_DB;
                    ct_op = `CT_OP_IDLE;
                    next = 1;
                end
            end
            // JR CC, imm8
            else if ((opcode == 8'h20) || (opcode == 8'h30) || (opcode == 8'h18)
                    || (opcode == 8'h28) || (opcode == 8'h38)) begin
                if (m_cycle == 0) begin
                    bus_op = `BUS_OP_READ;
                    db_src = `DB_SRC_DB;
                    next = 1;
                end
                else if (m_cycle == 1) begin
                    if (((opcode == 8'h20) && (!f_z)) ||     // JR NZ
                        ((opcode == 8'h30) && (!f_c)) ||     // JR NC
                        ((opcode == 8'h18)) ||               // JR
                        ((opcode == 8'h28) && (f_z)) ||      // JR Z
                        ((opcode == 8'h38) && (f_c))) begin  // JR C
                        bus_op = `BUS_OP_IDLE;
                        pc_jr = 1;
                        next = 1;
                    end
                end
            end
            // RET, RETI
            else if ((opcode == 8'hC9) || (opcode == 8'hD9)) begin
                if (m_cycle == 0) begin
                    if (opcode == 8'hD9) begin
                        ime_set = 1;
                    end
                    ab_src = `AB_SRC_SP;
                    db_src = `DB_SRC_DB;
                    bus_op = `BUS_OP_READ;
                    ct_op = `CT_OP_SP_INC;
                    next = 1;
                end
                else if (m_cycle == 1) begin
                    ab_src = `AB_SRC_SP;
                    db_src = `DB_SRC_DB;
                    bus_op = `BUS_OP_READ;
                    ct_op = `CT_OP_SP_INC;
                    alu_src_a = `ALU_SRC_A_DB;
                    alu_dst = `ALU_DST_PC;
                    pc_b_sel = 0;
                    next = 1;
                end
                else if (m_cycle == 2) begin
                    alu_src_a = `ALU_SRC_A_DB;
                    alu_dst = `ALU_DST_PC;
                    pc_b_sel = 1;
                    bus_op = `BUS_OP_IDLE;
                    ct_op = `CT_OP_IDLE;
                    next = 1;
                end
            end
            // RET CC
            else if ((opcode[7:5] == 3'b110) && (opcode[2:0] == 3'b000)) begin
                if (m_cycle == 0) begin
                    bus_op = `BUS_OP_IDLE;
                    ct_op = `CT_OP_IDLE;
                    next = 1;
                end
                else if (m_cycle == 1) begin
                    if (((opcode == 8'hC0) && (!f_z)) ||     // RET NZ
                        ((opcode == 8'hD0) && (!f_c)) ||     // RET NC
                        ((opcode == 8'hC8) && (f_z)) ||      // RET Z
                        ((opcode == 8'hD8) && (f_c))) begin  // RET C
                        ab_src = `AB_SRC_SP;
                        db_src = `DB_SRC_DB;
                        bus_op = `BUS_OP_READ;
                        ct_op = `CT_OP_SP_INC;
                        next = 1;
                    end
                end
                else if (m_cycle == 2) begin
                    ab_src = `AB_SRC_SP;
                    db_src = `DB_SRC_DB;
                    bus_op = `BUS_OP_READ;
                    ct_op = `CT_OP_SP_INC;
                    alu_src_a = `ALU_SRC_A_DB;
                    alu_dst = `ALU_DST_PC;
                    pc_b_sel = 0;
                    next = 1;
                end
                else if (m_cycle == 3) begin
                    alu_src_a = `ALU_SRC_A_DB;
                    alu_dst = `ALU_DST_PC;
                    pc_b_sel = 1;
                    bus_op = `BUS_OP_IDLE;
                    ct_op = `CT_OP_IDLE;
                    next = 1;
                end
            end
            // RST
            else if ((opcode[7:6] == 2'b11) && (opcode[2:0] == 3'b111)) begin
                if (m_cycle == 0) begin
                    bus_op = `BUS_OP_IDLE;
                    ct_op = `CT_OP_SP_DEC;
                    next = 1;
                end
                else if (m_cycle == 1) begin
                    alu_src_a = `ALU_SRC_A_PC;
                    alu_dst = `ALU_DST_DB;
                    db_src = `DB_SRC_DB;
                    ab_src = `AB_SRC_SP;
                    bus_op = `BUS_OP_WRITE;
                    ct_op = `CT_OP_SP_DEC;
                    next = 1;
                end
                else if (m_cycle == 2) begin
                    alu_src_a = `ALU_SRC_A_PC;
                    alu_dst = `ALU_DST_DB;
                    db_src = `DB_SRC_DB;
                    ab_src = `AB_SRC_SP;
                    pc_src = `PC_SRC_RST;
                    pc_we = 1;
                    bus_op = `BUS_OP_WRITE;
                    ct_op = `CT_OP_IDLE;
                    next = 1;
                end
            end
            // RLCA, RRCA, RLA, RRA
            else if ((opcode[7:5] == 3'b000) && (opcode[2:0] == 3'b111)) begin
                alu_src_b = `ALU_SRC_B_ACC;
                alu_op_prefix = `ALU_OP_PREFIX_SHIFT_ROTATE;
                alu_op_src = `ALU_OP_SRC_INSTR_5TO3;
                flags_pattern = `FLAGS_00HC;
                flags_we = 1;
            end
            // DAA, CPL, SCF, CCF
            else if ((opcode[7:5] == 3'b001) && (opcode[2:0] == 3'b111)) begin
                alu_src_b = `ALU_SRC_B_ACC;
                alu_op_prefix = `ALU_OP_PREFIX_SPECIAL;
                alu_op_src = `ALU_OP_SRC_INSTR_5TO3;
                flags_we = 1;
            end
            // CB prefix
            else if (opcode == 8'hCB) begin
                if (m_cycle == 0) begin
                    bus_op = `BUS_OP_READ;
                    db_src = `DB_SRC_DB;
                    next = 1;
                end
                else if (m_cycle == 1) begin
                    opcode_redir = 1'b1;
                    if (cb[2:0] == 3'b110) begin
                        alu_src_a = `ALU_SRC_A_DB;
                        alu_dst = `ALU_DST_DB;
                        ct_op = `CT_OP_IDLE;
                        ab_src = `AB_SRC_REG;
                        bus_op = `BUS_OP_READ;
                        flags_we = 0;
                        next = 1;
                    end
                    else if (cb[2:0] == 3'b111) begin
                        alu_src_a = `ALU_SRC_A_ACC;
                        alu_dst = `ALU_DST_ACC;
                        flags_we = !cb[7];
                    end
                    else begin
                        alu_src_a = `ALU_SRC_A_REG;
                        alu_dst = `ALU_DST_REG;
                        rf_rd_sel = cb[2:0];
                        rf_wr_sel = cb[2:0];
                        flags_we = !cb[7];
                    end
                    if (cb[7:6] == 2'b00) begin
                        alu_op_prefix = `ALU_OP_PREFIX_SHIFT_ROTATE;
                        alu_op_src = `ALU_OP_SRC_INSTR_5TO3;
                    end
                    else begin
                        alu_op_prefix = `ALU_OP_PREFIX_CB;
                        alu_op_src = `ALU_OP_SRC_INSTR_7TO6;
                    end
                    if (cb[7:6] == 2'b01) begin
                        // Only affects flags
                        alu_dst = `ALU_DST_DB;
                    end
                end
                else if (m_cycle == 2) begin
                    opcode_redir = 1'b1;
                    alu_src_a = `ALU_SRC_A_DB;
                    alu_dst = `ALU_DST_DB;
                    if (cb[7:6] == 2'b00) begin
                        alu_op_prefix = `ALU_OP_PREFIX_SHIFT_ROTATE;
                        alu_op_src = `ALU_OP_SRC_INSTR_5TO3;
                    end
                    else begin
                        alu_op_prefix = `ALU_OP_PREFIX_CB;
                        alu_op_src = `ALU_OP_SRC_INSTR_7TO6;
                    end
                    if (cb[7:6] != 2'b01) begin
                        // Write-back cycle required.
                        bus_op = `BUS_OP_WRITE;
                        db_src = `DB_SRC_ALU;
                        ab_src = `AB_SRC_REG;
                        ct_op = `CT_OP_IDLE;
                        next = 1;
                    end
                    flags_we = !cb[7];
                end
            end
        end
    end

endmodule
