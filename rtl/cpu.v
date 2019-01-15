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
    output reg [15:0] a,
    output reg [7:0] dout,
    input [7:0] din,
    output reg rd,
    output reg wr,
    output wire done
    );

    reg  [7:0]  opcode;
    wire [2:0]  m_cycle;
    wire [1:0]  alu_src_a;
    wire [2:0]  alu_src_b;
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
    wire        high_mask;
    wire        next;
    wire        stop;
    wire        halt;

    wire [2:0]  rf_rdn;
    wire [7:0]  rf_rd;
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
    wire [3:0]  alu_flags_in;
    wire [3:0]  alu_flags_out;
    wire [4:0]  alu_op;
    reg         alu_carry_out;

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
    //wire        flags_we;
    
    wire [7:0]  db_wr; // Data into buffer
    wire [7:0]  db_rd; // Data out from buffer
    wire        db_we;

    wire [7:0]  imm_abs;
    wire [7:0]  imm_low;

    // Control Logic
    // Control Logic is only used in EX stage
    // Signals are gated.
    wire [1:0] alu_src_a_ex;
    wire [2:0] alu_src_b_ex;
    wire [1:0] alu_op_prefix_ex;
    wire [1:0] alu_op_src_ex;
    wire [1:0] alu_dst_ex;
    wire [2:0] rf_wr_sel_ex;
    wire [2:0] rf_rd_sel_ex;
    wire       flags_we_ex;
    wire       pc_b_sel_ex;
    wire       pc_jr;

    control control(
        .clk(clk),
        .opcode_early(opcode),
        .imm(imm_low),
        .m_cycle(m_cycle),
        .f_z(flags_rd[3]),
        .f_c(flags_rd[0]),
        .alu_src_a(alu_src_a_ex),
        .alu_src_b(alu_src_b_ex),
        .alu_op_prefix(alu_op_prefix_ex),
        .alu_op_src(alu_op_src_ex),
        .alu_dst(alu_dst_ex),
        .pc_src(pc_src),
        .pc_we(pc_we),
        .pc_b_sel(pc_b_sel_ex),
        .pc_jr(pc_jr),
        .rf_wr_sel(rf_wr_sel_ex),
        .rf_rd_sel(rf_rd_sel_ex),
        .rf_rdw_sel(rf_rdw_sel),
        .bus_op(bus_op),
        .db_src(db_src),
        .ab_src(ab_src),
        .ct_op(ct_op),
        .flags_we(flags_we_ex),
        .high_mask(high_mask),
        .next(next),
        .stop(stop),
        .halt(halt)
    );
    
    always @(posedge clk) begin
        done <= stop | halt; 
        // only used to stop simulation if needed
        // and delay 1 clk
    end

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
        (db_src == 2'b01) ? (alu_result) : (
        (db_src == 2'b10) ? (rf_rd) : (
        (db_src == 2'b11) ? (db_wr_buffer) : (0)))));
    assign db_we = (alu_dst == 2'b11);

    // Address Bus Buffer
    wire [15:0] ab_wr;
    assign ab_wr = (
        (ab_src == 2'b00) ? (pc_rd) : (
        (ab_src == 2'b01) ? ((high_mask) ? ({8'hFF, temp_rd[15:8]}) : (temp_rd)) : (
        (ab_src == 2'b10) ? ((high_mask) ? ({8'hFF, rf_rdw[7:0]}) : (rf_rdw)) : (
        (ab_src == 2'b11) ? (rf_sp) : (0)))));

    // Regisiter file
    regfile regfile(
        .clk(clk),
        .rst(rst),
        .rdn(rf_rdn),
        .rd(rf_rd),
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
    assign rf_we = (alu_dst == 2'b10);
    assign rf_wrn = rf_wr_sel;
    assign rf_rdn = rf_rd_sel;
    assign rf_rdwn = rf_rdw_sel;

    // Register A
    singlereg #(8) acc(
        .clk(clk),
        .rst(rst),
        .wr(acc_wr),
        .we(acc_we),
        .rd(acc_rd)
    );
    assign acc_wr = alu_result; 
    assign acc_we = (alu_dst == 2'b00);
    
    // Register PC
    reg [15:0] pc;
    assign pc_rd = pc; 
    assign pc_rd_b = (pc_b_sel == 1'b0) ? (pc[7:0]) : (pc[15:8]);
    assign pc_wr_b = alu_result;
    assign pc_wr = (
        (pc_src == 2'b00) ? (rf_rdw) : (
        (pc_src == 2'b01) ? ({10'b00, opcode[5:3], 3'b000}) : (
        (pc_src == 2'b10) ? (temp_rd) : (
        (pc_src == 2'b11) ? (16'b0) : (0)))));
    assign pc_we_l = ((alu_dst == 2'b01) && (pc_b_sel == 1'b0)) ? (1) : (0);
    assign pc_we_h = ((alu_dst == 2'b01) && (pc_b_sel == 1'b1)) ? (1) : (0);
    always @(posedge clk) begin
        if (rst)
            pc <= 16'b0;
        else begin
            if (pc_we)
                pc <= pc_wr;
            else if (pc_we_l)
                pc[7:0] <= pc_wr_b;
            else if (pc_we_h)
                pc[15:8] <= pc_wr_b;
        end
    end

    // Register F
    singlereg #(4) flags(
        .clk(clk),
        .rst(rst),
        .wr(flags_wr),
        .we(flags_we),
        .rd(flags_rd)
    );
    assign flags_wr = alu_flags_out;
    

    // ALU
    wire [2:0] alu_op_mux;
    alu alu(
        .alu_a(alu_a),
        .alu_b(alu_b),
        .alu_bit_index(imm_reg[5:3]),
        .alu_result(alu_result),
        .alu_flags_in(alu_flags_in),
        .alu_flags_out(alu_flags_out),
        .alu_op(alu_op)
    );
    always @(posedge clk) begin
        alu_carry_out <= alu_flags_out[0];
    end

    assign alu_a = (
        (alu_src_a == 2'b00) ? (acc_rd) : (
        (alu_src_a == 2'b01) ? (pc_rd_b) : (
        (alu_src_a == 2'b10) ? (rf_rd) : (
        (alu_src_a == 2'b11) ? (db_rd) : (0)))));

    assign alu_b = (
        (alu_src_b == 3'b000) ? (acc_rd) : (
        (alu_src_b == 3'b001) ? ({7'b0, alu_carry_out}) : (
        (alu_src_b == 3'b010) ? (8'd0) : (
        (alu_src_b == 3'b011) ? (8'd1) : (
        (alu_src_b == 3'b100) ? (rf_h) : (
        (alu_src_b == 3'b101) ? (rf_l) : (
        (alu_src_b == 3'b110) ? (imm_abs) : (
        (alu_src_b == 3'b111) ? (imm_low) : (0)))))))));

    assign alu_op_mux = (
        (alu_op_src == 2'b00) ? (imm_reg[5:3]) : (
        (alu_op_src == 2'b01) ? ({1'b1, imm_reg[7:6]}) : (
        (alu_op_src == 2'b10) ? (3'b000) : (
        (alu_op_src == 2'b11) ? (3'b010) : (0)))));

    assign alu_flags_in = flags_rd;
    assign alu_op = {alu_op_prefix, alu_op_mux};

    // CT FSM
    reg  [1:0] ct_state;
    wire [1:0] ct_next_state;

    assign ct_next_state = ct_state + 2'b01;
    always @(posedge clk) begin
        if (rst)
            ct_state <= 2'b00;
        else
            ct_state <= ct_next_state;
    end

    reg [15:0] imm_reg;
    assign temp_rd = imm_reg;
    assign imm_low = imm_reg[7:0];
    assign imm_abs = (imm_reg[7]) ? (~imm_reg[7:0] + 1'b1) : (imm_reg[7:0]);

    // CT - FSM / Bus Operation 
    always @(posedge clk) begin
        case (ct_state)
        2'b00: begin
            // Setup Address
            a <= ab_wr;
            rd <= ((bus_op == 2'b01)||(bus_op == 2'b11)) ? (1) : (0);
            wr <= 0;
            phi <= 1;
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
                // mcycle is slower
                if (m_cycle == 3'd0) imm_reg[7:0] <= din;
                else if (m_cycle == 3'd1) imm_reg[15:8] <= din; 
            end
            else begin
                wr <= 0;
            end
            rd <= 0;
            phi <= 0;
        end
        2'b11: begin
            // Bus Idle
            rd <= 0;
            wr <= 0;
            dout <= 8'b0;
        end
        endcase
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
                alu_op_src_ct = 2'b10; // Ad
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
                alu_src_b_ct = 3'b001; // Carryt 1
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
    assign alu_dst = (ct_state == 2'b00) ? (alu_dst_ex) : (alu_dst_ct);
    assign rf_wr_sel = (ct_state == 2'b00) ? (rf_wr_sel_ex) : (rf_wr_sel_ct);
    assign rf_rd_sel = (ct_state == 2'b00) ? (rf_rd_sel_ex) : (rf_rd_sel_ct);
    assign flags_we = (ct_state == 2'b00) ? (flags_we_ex) : (1'b0);
    assign pc_b_sel = (ct_state == 2'b00) ? (pc_b_sel_ex) : (pc_b_sel_ct);

    // EX - FSM / Mutli-M-cycle Instruction Handling
    reg  [2:0] ex_state;
    wire [2:0] ex_next_state;

    assign ex_next_state = (next) ? (ex_state + 3'd1) : (3'd0);

    always @(posedge clk) begin
        if (rst)
            ex_state <= 3'd0;
        else
            if (ct_state == 2'b11) begin
                ex_state <= ex_next_state;
            end
    end

    assign m_cycle = ex_state;

endmodule

