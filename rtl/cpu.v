`timescale 1ns / 1ps
`default_nettype wire
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    17:30:26 02/08/2018 
// Module Name:    cpu
// Project Name:   VerilogBoy
// Description: 
//   The Game Boy CPU.
// Dependencies: 
// 
// Additional Comments: 
//   See doc/cpu_internal.md for signal definitions
////////////////////////////////////////////////////////////////////////////////

module cpu(
    input clk,
    input rst,
    output reg phi,
    output wire [1:0] ct,
    output reg [15:0] a,
    output reg [7:0] dout,
    input [7:0] din,
    output reg rd,
    output reg wr,
    input [4:0] int_en,
    input [4:0] int_flags_in,
    output wire [4:0] int_flags_out,
    input [7:0] key_in,
    output reg done,
    output wire fault
    );

    reg  [7:0]  opcode;
    reg  [7:0]  cb;
    wire [2:0]  m_cycle;
    reg  [2:0]  m_cycle_early;
    wire [1:0]  alu_src_a;
    wire [2:0]  alu_src_b;
    wire        alu_src_xchg;
    wire [1:0]  alu_op_prefix;
    wire [1:0]  alu_op_src;
    wire [1:0]  alu_dst;
    wire [1:0]  pc_src;
    wire        pc_we;
    wire [2:0]  rf_wr_sel;
    wire [2:0]  rf_rd_sel;
    wire [1:0]  rf_rdw_sel;
    wire [1:0]  bus_op;
    wire [1:0]  db_src;
    wire [1:0]  ab_src;
    wire [1:0]  ct_op;
    wire        flags_we;
    wire [1:0]  flags_pattern;
    wire        high_mask;
    wire        next;
    wire        stop;
    wire        halt;
    reg         wake;
    //wire        fault;
    reg         int_dispatch;
    wire        int_master_en;
    wire        int_ack;

    wire [2:0]  rf_rdn;
    wire [7:0]  rf_rd;
    reg  [7:0]  rf_rd_ex; // Buffer Rd selected during EX stage
    wire [1:0]  rf_rdwn;
    wire [15:0] rf_rdw;
    wire [7:0]  rf_h;
    wire [7:0]  rf_l;
    wire [15:0] rf_sp;
    wire [2:0]  rf_wrn;
    wire [7:0]  rf_wr;
    wire        rf_we;

    wire [7:0]  alu_a;
    wire [7:0]  alu_b;
    wire [7:0]  alu_result;
    reg  [7:0]  alu_result_buffer;
    wire [3:0]  alu_flags_in;
    wire [3:0]  alu_flags_out;
    wire [4:0]  alu_op;
    wire        alu_op_signed;
    wire        alu_carry_out;
    reg         alu_carry_out_ex;
    reg         alu_carry_out_ct;

    wire [7:0]  acc_wr;
    wire        acc_we;
    wire [7:0]  acc_rd;

    wire [15:0] pc_rd;
    wire [7:0]  pc_rd_b;
    wire        pc_b_sel; // byte select
    wire [15:0] pc_wr;
    wire [7:0]  pc_wr_b;
    wire        pc_we_h;
    wire        pc_we_l;

    wire [15:0] temp_rd; // temp value for 16bit imm

    wire [3:0]  flags_rd;
    wire [3:0]  flags_wr;
        
    wire [7:0]  db_wr; // Data into buffer
    wire [7:0]  db_rd; // Data out from buffer
    wire        db_we;

    wire [7:0]  imm_abs;
    wire [7:0]  imm_low;
    wire [7:0]  imm_ext;

    reg  [1:0]  ct_state;

    // Control Logic
    // Control Logic is only used in EX stage
    // Signals are gated.
    wire [1:0] alu_src_a_ex;
    wire [2:0] alu_src_b_ex;
    wire [1:0] alu_op_prefix_ex;
    wire [1:0] alu_op_src_ex;
    wire       alu_op_signed_ex;
    wire [1:0] alu_dst_ex;
    wire [2:0] rf_wr_sel_ex;
    wire [2:0] rf_rd_sel_ex;
    wire       flags_we_ex;
    wire       pc_b_sel_ex;
    wire       pc_jr;
    wire       pc_we_ex;
    wire       pc_revert;
    wire       temp_redir; // redirect regfile operation to temp register
    wire       opcode_redir;

    control control(
        .clk(clk),
        .rst(rst),
        .opcode_early(opcode),
        .cb(cb),
        .imm(imm_low),
        .m_cycle_early(m_cycle_early),
        .ct_state(ct_state),
        .f_z(flags_rd[3]),
        .f_c(flags_rd[0]),
        .alu_src_a(alu_src_a_ex),
        .alu_src_b(alu_src_b_ex),
        .alu_src_xchg(alu_src_xchg),
        .alu_op_prefix(alu_op_prefix_ex),
        .alu_op_src(alu_op_src_ex),
        .alu_op_signed(alu_op_signed_ex),
        .alu_dst(alu_dst_ex),
        .pc_src(pc_src),
        .pc_we(pc_we_ex),
        .pc_b_sel(pc_b_sel_ex),
        .pc_jr(pc_jr),
        .pc_revert(pc_revert),
        .rf_wr_sel(rf_wr_sel_ex),
        .rf_rd_sel(rf_rd_sel_ex),
        .rf_rdw_sel(rf_rdw_sel),
        .temp_redir(temp_redir),
        .opcode_redir(opcode_redir),
        .bus_op(bus_op),
        .db_src(db_src),
        .ab_src(ab_src),
        .ct_op(ct_op),
        .flags_we(flags_we_ex),
        .flags_pattern(flags_pattern),
        .high_mask(high_mask),
        .int_master_en(int_master_en),
        .int_dispatch(int_dispatch),
        .int_ack(int_ack),
        .next(next),
        .stop(stop),
        .halt(halt),
        .wake(wake),
        .fault(fault)
    );
    
    always @(posedge clk) begin
        done <= stop | halt | fault; 
        // only used to stop simulation if needed
        // and delay 1 clk
    end

    wire wake_comb = 
        // Any enabled interrupt can wake up halted CPU, IME doesn't matter
        (halt) ? ((int_flags_in & int_en) != 0) : (
        // Any enabled interrupt and any keypress can wake up stopped CPU
        // IME doesn't matter. Though the typical usage is clear the IE before
        // entering STOP mode, so only keypad can wake up the CPU.
        (stop) ? (((int_flags_in & int_en) != 0) || (key_in != 0)) : 
        (1'b0));
    reg wake_delay; // Wake should be delayed for 1 Mcycle
    always @(posedge clk) begin
        if (ct_state == 2'b10) begin
            wake_delay <= wake_comb;
            wake <= wake_delay;
        end
    end

    wire [7:3] current_opcode;

    // Data Bus Buffer
    reg [7:0] db_wr_buffer;
    reg [7:0] db_rd_buffer;
    
    // Logic: if buffer is selected, use the data in the buffer,
    // otherwise the buffer is overrided.
    always @(posedge clk) begin
        if (db_we)
            db_wr_buffer <= alu_result;
    end
    assign db_rd = db_rd_buffer;
    assign db_wr = (
        (db_src == 2'b00) ? (acc_rd) : (
        (db_src == 2'b01) ? (alu_result_buffer) : (
        (db_src == 2'b10) ? (rf_rd_ex) : (
        (db_src == 2'b11) ? (db_wr_buffer) : (8'b0)))));
    assign db_we = (alu_dst == 2'b11);

    // Address Bus Buffer
    wire [15:0] ab_wr;
    assign ab_wr = (
        (ab_src == 2'b00) ? (pc_rd) : (
        (ab_src == 2'b01) ? ((high_mask) ? ({8'hFF, temp_rd[7:0]}) : (temp_rd)) : (
        (ab_src == 2'b10) ? ((high_mask) ? ({8'hFF, rf_rdw[7:0]}) : (rf_rdw)) : (
        (ab_src == 2'b11) ? (rf_sp) : (16'b0)))));

    // Interrupt
    wire [4:0] int_flags_masked = int_flags_in & int_en & {5{int_master_en}};
    wire [4:0] int_flags_out_cleared = 
        (int_flags_masked[0]) ? (int_flags_in & 5'b11110) : (
        (int_flags_masked[1]) ? (int_flags_in & 5'b11101) : (
        (int_flags_masked[2]) ? (int_flags_in & 5'b11011) : (
        (int_flags_masked[3]) ? (int_flags_in & 5'b10111) : (
        (int_flags_masked[4]) ? (int_flags_in & 5'b01111) : (
            int_flags_in
        )))));

    assign int_flags_out = 
        ((int_dispatch)&&(pc_we)) ? (int_flags_out_cleared) : (int_flags_in);

    // Regisiter file
    wire [7:0] rf_rd_raw;
    regfile regfile(
        .clk(clk),
        .rst(rst),
        .rdn(rf_rdn),
        .rd(rf_rd_raw),
        .rdwn(rf_rdwn),
        .rdw(rf_rdw),
        .h(rf_h),
        .l(rf_l),
        .sp(rf_sp),
        .wrn(rf_wrn),
        .wr(rf_wr),
        .we(rf_we)
    );
    assign rf_wr = alu_result;
    assign rf_we = (alu_dst == 2'b10) && (!temp_redir);
    assign rf_wrn = rf_wr_sel;
    assign rf_rdn = rf_rd_sel;
    assign rf_rdwn = rf_rdw_sel;
    assign rf_rd = (!temp_redir) ? (rf_rd_raw) : ((rf_rd_sel[0]) ? (temp_rd[7:0]) : (temp_rd[15:8]));
    always@(posedge clk) begin
        if (rst)
            rf_rd_ex <= 8'b0;
        else
            if (ct_state == 2'b00)
                rf_rd_ex <= rf_rd_raw;
    end

    // Register A
    reg [15:0] imm_reg;
    singlereg #(8) acc(
        .clk(clk),
        .rst(rst),
        .wr(acc_wr),
        .we(acc_we),
        .rd(acc_rd)
    );
    assign acc_wr = ((db_src == 2'b00) && (bus_op == 2'b11)) ? (imm_reg[7:0]) : (alu_result); 
    assign acc_we = ((alu_dst == 2'b00) || ((db_src == 2'b00) && (bus_op == 2'b11)));
    
    // Register PC
    reg [15:0] pc;
    reg [15:0] last_pc;
    assign pc_rd = pc;
    assign pc_rd_b = (pc_b_sel == 1'b0) ? (pc[7:0]) : (pc[15:8]);
    assign pc_wr_b = alu_result;
    assign pc_wr = (
        (pc_src == 2'b00) ? (rf_rdw) : (
        (pc_src == 2'b01) ? ({10'b00, opcode[5:3], 3'b000}) : (
        (pc_src == 2'b10) ? (temp_rd) : (
        (pc_src == 2'b11) ? (16'b0) : (16'b0)))));
    wire [15:0] pc_int = 
        (int_flags_masked[0]) ? (16'h0040) : (
        (int_flags_masked[1]) ? (16'h0048) : (
        (int_flags_masked[2]) ? (16'h0050) : (
        (int_flags_masked[3]) ? (16'h0058) : (
        (int_flags_masked[4]) ? (16'h0060) : (
            // no interrupts anymore, dispatching is cancelled.
            // jump to 0000 instead
            // this behavior is tested by acceptence/interrupts/ie_push
            16'h0000
        )))));
    assign pc_we_l = ((alu_dst == 2'b01) && (pc_b_sel == 1'b0)) ? (1'b1) : (1'b0);
    assign pc_we_h = ((alu_dst == 2'b01) && (pc_b_sel == 1'b1)) ? (1'b1) : (1'b0);
    always @(posedge clk) begin
        if (rst)
            pc <= 16'b0;
        else begin
            if (pc_we_l) begin
                pc[7:0] <= pc_wr_b;
                last_pc[7:0] <= pc[7:0];
            end
            else if (pc_we_h) begin
                pc[15:8] <= pc_wr_b;
                last_pc[15:8] <= pc[15:8];
            end
            else if (pc_revert)
                pc <= last_pc;
            else if (pc_we)
                if (int_dispatch)
                    // this might need to be deffered
                    pc <= pc_int;
                else begin
                    pc <= pc_wr;
                    last_pc <= pc;
                end
        end
    end

    // Register F
    /*singlereg #(4) flags(
        .clk(clk),
        .rst(rst),
        .wr(flags_wr),
        .we((flags_we != 2'b00) ? 1'b1 : 1'b0),
        .rd(flags_rd)
    );*/
    reg [3:0] flags;
    always @(posedge clk) begin
        if (rst)
            flags <= 4'b0;
        else if (flags_we)
            if (flags_pattern == 2'b00)
                flags[3:0] <= flags_wr[3:0];
            else if (flags_pattern == 2'b01)
                flags[2:0] <= {1'b0, flags_wr[1:0]};
            else if (flags_pattern == 2'b10)
                flags[3:0] <= {2'b0, flags_wr[1:0]};
            else if (flags_pattern == 2'b11)
                flags[3:1] <= flags_wr[3:1];
    end
    assign flags_rd = flags;
    assign flags_wr = alu_flags_out;
    

    // ALU
    wire [2:0] alu_op_mux;
    wire [7:0] alu_a_pre;
    wire [7:0] alu_b_pre;

    alu alu(
        .alu_a(alu_a),
        .alu_b(alu_b),
        .alu_bit_index(imm_reg[5:3]),
        .alu_result(alu_result),
        .alu_flags_in(alu_flags_in),
        .alu_flags_out(alu_flags_out),
        .alu_op(alu_op)
    );

    assign alu_a_pre = (
        (alu_src_a == 2'b00) ? (acc_rd) : (
        (alu_src_a == 2'b01) ? (pc_rd_b) : (
        (alu_src_a == 2'b10) ? (rf_rd) : (
        (alu_src_a == 2'b11) ? (db_rd) : (8'b0)))));

    assign alu_b_pre = (
        (alu_src_b == 3'b000) ? (acc_rd) : (
        (alu_src_b == 3'b001) ? ({7'b0, alu_carry_out}) : (
        (alu_src_b == 3'b010) ? (8'd0) : (
        (alu_src_b == 3'b011) ? (8'd1) : (
        (alu_src_b == 3'b100) ? (rf_h) : (
        (alu_src_b == 3'b101) ? (rf_l) : (
        (alu_src_b == 3'b110) ? (imm_abs) : (
        (alu_src_b == 3'b111) ? ((pc_b_sel) ? (imm_low) : (imm_ext)) : (8'b0))))))))); // cursed

    assign alu_a = (alu_src_xchg) ? (alu_b_pre) : (alu_a_pre);
    assign alu_b = (alu_src_xchg) ? (alu_a_pre) : (alu_b_pre);

    assign alu_op_mux = (
        (alu_op_src == 2'b00) ? (current_opcode[5:3]) : (
        (alu_op_src == 2'b01) ? ({1'b1, current_opcode[7:6]}) : (
        (alu_op_src == 2'b10) ? ((alu_op_signed) ? (3'b001) : (3'b000)) : (
        (alu_op_src == 2'b11) ? ((alu_op_signed) ? (3'b011) : (3'b010)) : (3'b0)))));

    assign alu_flags_in = flags_rd;
    assign alu_op = {alu_op_prefix, alu_op_mux};

    assign current_opcode[7:3] = (opcode_redir) ? (imm_reg[7:3]) : (opcode[7:3]);

    // CT FSM
    wire [1:0] ct_next_state;

    assign ct_next_state = ct_state + 2'b01;
    always @(posedge clk) begin
        if (rst)
            ct_state <= 2'b00;
        else
            ct_state <= ct_next_state;
    end

    assign ct = ct_state;

    //reg [15:0] imm_reg; decleared before
    assign temp_rd = imm_reg;
    assign imm_low = imm_reg[7:0];
    assign imm_ext = {8{imm_reg[7]}};
    assign imm_abs = (imm_reg[7]) ? (~imm_reg[7:0] + 1'b1) : (imm_reg[7:0]);

    // CT - FSM / Bus Operation 
    always @(posedge clk) begin
        if (rst) begin
            a <= 16'b0;
            rd <= 1'b0;
            wr <= 1'b0;
            phi <= 1;
            opcode <= 8'b0;
            imm_reg <= 16'b0;
            db_rd_buffer <= 8'b0;
            dout <= 8'b0;
            int_dispatch <= 1'b0;
            alu_result_buffer <= 8'b0;
        end
        else begin
            if ((alu_dst == 2'b10) && temp_redir && !(ct_state == 2'b10 && bus_op == 2'b11))
                if (rf_wr_sel[0]) imm_reg[7:0] <= rf_wr;
                else imm_reg[15:8] <= rf_wr;

            case (ct_state)
            2'b00: begin
                // Setup Address
                a <= ab_wr;
                rd <= ((bus_op == 2'b01)||(bus_op == 2'b11)) ? (1'b1) : (1'b0);
                wr <= 0;
                phi <= 1;
                // Backup ALU results
                alu_result_buffer <= alu_result;
            end
            2'b01: begin
                // Read in progress
            end
            2'b10: begin
                if (bus_op == 2'b10) begin
                    // Write cycle
                    wr <= 1;
                    dout <= db_wr;
                end
                else if (bus_op == 2'b01) begin
                    // Instruction Fetch Cycle
                    wr <= 0;
                    opcode <= din;
                end
                else if (bus_op == 2'b11) begin
                    // Data Read cycle
                    wr <= 0;
                    db_rd_buffer <= din;
                    if ((opcode == 8'hCB) && (m_cycle == 0)) cb <= din[7:0];
                    // mcycle is slower
                    if (m_cycle == 3'd0) imm_reg[7:0] <= din;
                    else if (m_cycle == 3'd1) imm_reg[15:8] <= din; 
                end
                else begin
                    wr <= 0;
                end
                rd <= 0;
                phi <= 0;

                // Interrupt dispatch happens here
                // Guarenteed if it is at instruction fetch cycle,
                // It is at instruction boundaries,
                // and m_cycle will start from 0.
                if ((!int_dispatch) && (int_flags_masked != 0) && (int_master_en) && ((bus_op == 2'b01) || (halt == 1'b1)))
                    int_dispatch <= 1'b1;
                else if ((int_dispatch) && (int_ack)) begin
                    int_dispatch <= 1'b0;
                end
            end
            2'b11: begin
                // Bus Idle
                rd <= 0;
                wr <= 0;
                dout <= 8'b0;
            end
            endcase
        end
    end

    // CT - FSM / Instruction Execution
    reg  [1:0] alu_src_a_ct;
    reg  [2:0] alu_src_b_ct;
    wire [1:0] alu_op_prefix_ct = 2'b00;
    reg  [1:0] alu_op_src_ct;
    reg  [1:0] alu_dst_ct;
    reg  [2:0] rf_wr_sel_ct;
    reg  [2:0] rf_rd_sel_ct;
    reg        pc_b_sel_ct; 
      
 
    always @(*) begin
        // Do nothing by default
        alu_src_a_ct = 2'b00;  // From A
        alu_src_b_ct = 3'b010; // Constant 0
        alu_op_src_ct = 2'b10; // Add
        alu_dst_ct = 2'b00;    // To A
        rf_wr_sel_ct = 3'b000;
        rf_rd_sel_ct = 3'b000;
        pc_b_sel_ct = 1'b0;
        case (ct_state)
        2'b00: begin
            // Decoding and Execution
            // Actually cannot control anything
        end
        2'b01: begin
            // CT_OP first clock
            case (ct_op)
            2'b00: begin
                // Do nothing
            end
            2'b01: begin
                // Calculate PC low + 1
                pc_b_sel_ct = 1'b0;
                alu_src_a_ct = 2'b01;  // From PC byte
                alu_src_b_ct = (pc_jr) ? (3'b110) : (3'b011); // Imm Abs or Constant 1
                alu_op_src_ct = (pc_jr) ? (imm_low[7] ? 2'b11 : 2'b10) : 2'b10; // Add
                alu_dst_ct = 2'b01;    // To PC byte
            end
            2'b10: begin
                // Calculate SP low - 1
                rf_rd_sel_ct = 3'b111; // Read from SP low
                rf_wr_sel_ct = 3'b111; // Write to SP low
                alu_src_a_ct = 2'b10;  // From register file
                alu_src_b_ct = 3'b011; // Constant 1
                alu_op_src_ct = 2'b11; // Sub
                alu_dst_ct = 2'b10;    // To register file
            end
            2'b11: begin
                // Calculate SP low + 1
                rf_rd_sel_ct = 3'b111; // Read from SP low
                rf_wr_sel_ct = 3'b111; // Write to SP low
                alu_src_a_ct = 2'b10;  // From register file
                alu_src_b_ct = 3'b011; // Constant 1
                alu_op_src_ct = 2'b10; // Add
                alu_dst_ct = 2'b10;    // To register file
            end
            endcase
        end
        2'b10: begin
            // CT_OP second clock
            case (ct_op)
            2'b00: begin
                // Do nothing
            end
            2'b01: begin
                // Calculate PC high + carry
                pc_b_sel_ct = 1'b1;
                alu_src_a_ct = 2'b01;  // From PC byte
                alu_src_b_ct = 3'b001; // Carry
                alu_op_src_ct = (pc_jr) ? (imm_low[7] ? 2'b11 : 2'b10) : 2'b10; // Add
                alu_dst_ct = 2'b01;    // To PC byte
            end
            2'b10: begin
                // Calculate SP high - carry
                rf_rd_sel_ct = 3'b110; // Read from SP high
                rf_wr_sel_ct = 3'b110; // Write to SP high
                alu_src_a_ct = 2'b10;  // From register file
                alu_src_b_ct = 3'b001; // Carry
                alu_op_src_ct = 2'b11; // Sub
                alu_dst_ct = 2'b10;    // To register file
            end
            2'b11: begin
                // Calculate SP high + carry
                rf_rd_sel_ct = 3'b110; // Read from SP high
                rf_wr_sel_ct = 3'b110; // Write to SP high
                alu_src_a_ct = 2'b10;  // From register file
                alu_src_b_ct = 3'b001; // Carry
                alu_op_src_ct = 2'b10; // Add
                alu_dst_ct = 2'b10;    // To register file
            end
            endcase
        end
        2'b11: begin
            // End, it is safe to overwrite DB as doing nothing
            alu_dst_ct = 2'b11;
        end
        endcase
    end

    assign alu_src_a = (ct_state == 2'b00) ? (alu_src_a_ex) : (alu_src_a_ct);
    assign alu_src_b = (ct_state == 2'b00) ? (alu_src_b_ex) : (alu_src_b_ct);
    assign alu_op_prefix = (ct_state == 2'b00) ? (alu_op_prefix_ex) : (alu_op_prefix_ct);
    assign alu_op_src = (ct_state == 2'b00) ? (alu_op_src_ex) : (alu_op_src_ct);
    assign alu_op_signed = (ct_state == 2'b00) ? (alu_op_signed_ex) : (1'b0);
    assign alu_dst = (ct_state == 2'b00) ? (alu_dst_ex) : (alu_dst_ct);
    assign rf_wr_sel = (ct_state == 2'b00) ? (rf_wr_sel_ex) : (rf_wr_sel_ct);
    assign rf_rd_sel = (ct_state == 2'b00) ? (rf_rd_sel_ex) : (rf_rd_sel_ct);
    assign flags_we = (ct_state == 2'b00) ? (flags_we_ex) : (1'b0);
    assign pc_b_sel = (ct_state == 2'b00) ? (pc_b_sel_ex) : (pc_b_sel_ct);
    assign pc_we = (ct_state == 2'b00) ? (pc_we_ex) : (1'b0);
    assign alu_carry_out = (ct_state == 2'b00) ? (alu_carry_out_ex) : (alu_carry_out_ct);

    // EX - FSM / Mutli-M-cycle Instruction Handling
    reg  [2:0] ex_state;
    wire [2:0] ex_next_state;

    assign ex_next_state = (next) ? (ex_state + 3'd1) : (3'd0);

    always @(posedge clk) begin
        if (rst) begin
            ex_state <= 3'd0;
            m_cycle_early <= 3'd0;
            alu_carry_out_ex <= 1'b0;
            alu_carry_out_ct <= 1'b0;
        end
        else begin
            alu_carry_out_ct <= alu_flags_out[0];
            if (ct_state == 2'b11) begin
                ex_state <= ex_next_state;
            end
            else if (ct_state == 2'b10) begin
                m_cycle_early <= ex_next_state;
            end
            else if (ct_state == 2'b00) begin
                // Backup flag output
                alu_carry_out_ex <= alu_flags_out[0];
            end
        end
    end

    assign m_cycle = ex_state;

endmodule
