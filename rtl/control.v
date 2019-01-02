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
    input  [7:0] opcode_early,
    input  [2:0] m_cycle,
    input        f_z,
    input        f_c,
    output [1:0] alu_src_a,
    output [2:0] alu_src_b,
    output [1:0] alu_op_prefix,
    output [1:0] alu_op_src,
    output [1:0] alu_dst,
    output [1:0] pc_src,
    output       pc_we,
    output [2:0] rf_wr_sel,
    output [2:0] rf_rd_sel,
    output [1:0] rf_rdw_sel,
    output [1:0] bus_op,
    output [1:0] db_src,
    output [1:0] ab_src,
    output [1:0] ct_op,
    output       flags_we,
    output       high_mask,
    output       next,
    output       stop,
    output       halt
    );

    wire [1:0] cond_bit = {opcode[7], opcode[0]}; // 00 - NZ 01 - NC 10 - Z 11 - C
    /* verilator lint_off UNUSED */
    wire cond = (
        (cond_bit == 2'b00) ? (!f_z) : (
        (cond_bit == 2'b01) ? (!f_c) : (
        (cond_bit == 2'b10) ? (f_z) : (
        (cond_bit == 2'b11) ? (f_c) : (0)))));
    /* verilator lint_on UNUSED */

    reg [27:0] decoding_lut [0:255]; // pc_src is not in the lut
    wire [27:0] decoding_output;
    reg [7:0] opcode;
    // opcode is available one clock earlier
    always @(posedge clk) begin
        // input should be high low nibble swapped
        decoding_output <= decoding_lut[{opcode_early[3:0], opcode_early[7:4]}];
        opcode <= opcode_early;
    end

    always @(*) begin
        // Set default output
        {alu_src_a, alu_src_b, alu_op_prefix, alu_op_src, 
        alu_dst, pc_we, rf_wr_sel, rf_rd_sel, bus_op, 
        db_src, ab_src, ct_op, flags_we, next} = decoding_output;
        rf_rdw_sel = 2'b10; // Select HL
        pc_src = 2'b00;
        stop = 1'b0;
        halt = 1'b0;
        case (m_cycle)
        3'd0: begin
            // First cycle is usually handled by the decoding lut
            if (opcode == 8'h10) begin
                stop = 1'b1;
            end
            else if (opcode == 8'h76) begin
                halt = 1'b1;
            end
            else if (opcode == 8'h02) begin
                rf_rdw_sel = 2'b00; // Select BC
            end
            else if (opcode == 8'h12) begin
                rf_rdw_sel = 2'b01; // Select DE
            end
            else if (opcode == 8'hE2) begin
                rf_rdw_sel = 2'b00; // Select BC
                high_mask = 1'b1; // Select C only
            end
            else if (opcode == 8'hF2) begin
                rf_rdw_sel = 2'b00; // Select BC
                high_mask = 1'b1; // Select C only
            end
            else if ((opcode == 8'hD3) || 
                     (opcode == 8'hD3) ||
                     (opcode == 8'hE4) ||
                     (opcode == 8'hF4) ||
                     (opcode == 8'hDB) ||
                     (opcode == 8'hEB) ||
                     (opcode == 8'hCE) ||
                     (opcode == 8'hCF) ||
                     (opcode == 8'hDD) ||
                     (opcode == 8'hDE) ||
                     (opcode == 8'hDF)) begin
                // Invalid Op
                stop = 1'b1;
                halt = 1'b1;
            end

        end
        3'd1: begin
            if ((opcode[7:6] == 2'b00)&&(opcode[3:0] == 4'b0001)) begin
                // 16bit Load Imm
                next = 1'b1;
            end 
            else if ((opcode[7:6] == 2'b11)&&(opcode[3:0] == 4'b0001)) begin
                // POP instruction 
                next = 1'b1;
            end
            else if (opcode == 8'hE0) begin
                // LDH (n), A
                bus_op = 2'b10;
                db_src = 2'b00;
                ab_src = 2'b01;
                ct_op = 2'b00;
                next = 1'b1;
                high_mask = 1'b1;
            end
            else if (opcode == 8'hF0) begin
                // LDH A, (n)
                bus_op = 2'b11;
                ab_src = 2'b01;
                ct_op = 2'b00;
                next = 1'b1;
                high_mask = 1'b1;
            end
            else if (opcode == 8'hC3) begin
                next = 1'b1;
            end
            else begin
                // Case for instructions end at this cycle
                bus_op = 2'b01; // Restore to normal instruction fetch
                ab_src = 2'b00; // Restore to fetch from PC
                ct_op = 2'b01;  // Restore to PC + 1
                next = 1'b0;
                if ((opcode == 8'h22) || (opcode == 8'h32)) begin
                    // LD [HL+/-], A
                    alu_src_b = 3'b001; // Input from carry
                    rf_rd_sel = 3'b100; // Select H
                    rf_wr_sel = 3'b100; // Select H
                end
                else if ((opcode[7:6] == 2'b00)&&
                    ((opcode[3:0] == 4'b0011)||(opcode[3:0] == 4'b1011))) begin
                    // 16-bit INC or DEC
                    alu_src_b = 3'b001;
                    rf_rd_sel = {opcode[5:4], 1'b0};
                    rf_wr_sel = {opcode[5:4], 1'b0};
                end
            end
        end
        3'd2: begin
            if (opcode == 8'hC3) begin
                // JP nn
                pc_src = 2'b10;// PC from temp register
                bus_op = 2'b00;
                ct_op = 2'b00;
                pc_we = 1'b1;  // PC write en
                next = 1'b1;
            end
            else begin
                // Case for instructions end at this cycle
                bus_op = 2'b01; // Restore to normal instruction fetch
                ab_src = 2'b00; // Restore to fetch from PC
                ct_op = 2'b01;  // Restore to PC + 1
                next = 1'b0;
                if ((opcode[7:6] == 2'b00)&&(opcode[3:0] == 4'b0001)) begin
                    // 16bit Load Imm
                    rf_wr_sel = {opcode[5:4], 1'b0};
                end
                else if ((opcode == 8'hC1) || (opcode == 8'hD1) || (opcode == 8'hE1)) begin
                    // POP BC/DE/HL
                    rf_wr_sel = {opcode[5:4], 1'b1};
                end
                else if (opcode == 8'hF1) begin
                    // POP AF
                    alu_op_prefix = 2'b10; // Special
                    alu_op_src = 2'b11;    // Input A to Flags
                    alu_src_b = 3'b000;    // Acc to Input B
                    flags_we = 1'b1;
                end
            end
        end
        3'd3: begin
            // Case for instructions end at this cycle
            bus_op = 2'b01; // Restore to normal instruction fetch
            ab_src = 2'b00; // Restore to fetch from PC
            ct_op = 2'b01;  // Restore to PC + 1
            next = 1'b0;
        end
        default: begin
            // Illegal Instruction ??
            stop = 1'b1;
            halt = 1'b1;
            next = 1'b1;
        end
        endcase
    end

    // Generated from control_unit.ods sheet, don't patch here
    initial begin
        decoding_lut[0] =   28'b0001000100000000000100000100;
        decoding_lut[1] =   28'b0001000100000000000100000100;
        decoding_lut[2] =   28'b0001000100000000000100000101;
        decoding_lut[3] =   28'b0001000100000000000100000101;
        decoding_lut[4] =   28'b1001000101000000000100000100;
        decoding_lut[5] =   28'b1001000101000100000100000100;
        decoding_lut[6] =   28'b1001000101001000000100000100;
        decoding_lut[7] =   28'b1001000101100000001010100001;
        decoding_lut[8] =   28'b1000000000000000000100000110;
        decoding_lut[9] =   28'b1000000000000000000100000110;
        decoding_lut[10] =  28'b1000000000000000000100000110;
        decoding_lut[11] =  28'b1000000000000000000100000110;
        decoding_lut[12] =  28'b0001000100000000000011000001;
        decoding_lut[13] =  28'b0001000100000000000011000001;
        decoding_lut[14] =  28'b0001000101100000001100000101;
        decoding_lut[15] =  28'b1101000100000000001111000101;
        decoding_lut[16] =  28'b1101000101000010001111000101;
        decoding_lut[17] =  28'b1101000101000110001111000101;
        decoding_lut[18] =  28'b1101000101001010001111000101;
        decoding_lut[19] =  28'b1101000101001110001111000101;
        decoding_lut[20] =  28'b1001000101000000010100000100;
        decoding_lut[21] =  28'b1001000101000100010100000100;
        decoding_lut[22] =  28'b1001000101001000010100000100;
        decoding_lut[23] =  28'b1001000101100000011010100001;
        decoding_lut[24] =  28'b1000000000000000010100000110;
        decoding_lut[25] =  28'b1000000000000000010100000110;
        decoding_lut[26] =  28'b1000000000000000010100000110;
        decoding_lut[27] =  28'b1000000000000000010100000110;
        decoding_lut[28] =  28'b1101000101000000001111111101;
        decoding_lut[29] =  28'b1101000101000100001111111101;
        decoding_lut[30] =  28'b1101000101001000001111111101;
        decoding_lut[31] =  28'b1101000100000000001111111101;
        decoding_lut[32] =  28'b0001000101100000001000100001;
        decoding_lut[33] =  28'b0001000101100000001000100001;
        decoding_lut[34] =  28'b1001100101001011011000100001;
        decoding_lut[35] =  28'b1001100111001011011000100001;
        decoding_lut[36] =  28'b1001000101000000100100000100;
        decoding_lut[37] =  28'b1001000101000100100100000100;
        decoding_lut[38] =  28'b1001000101001000100100000100;
        decoding_lut[39] =  28'b1001000101100000101010100001;
        decoding_lut[40] =  28'b1000000000000000100100000110;
        decoding_lut[41] =  28'b1000000000000000100100000110;
        decoding_lut[42] =  28'b1000000000000000100100000110;
        decoding_lut[43] =  28'b1000000000000000100100000110;
        decoding_lut[44] =  28'b0001000100000000001111000101;
        decoding_lut[45] =  28'b0001000100000000001111000101;
        decoding_lut[46] =  28'b0001000100000000001000100001;
        decoding_lut[47] =  28'b1101000100000000001111100001;
        decoding_lut[48] =  28'b1001100101000010010011000001;
        decoding_lut[49] =  28'b1001100101000110110011000001;
        decoding_lut[50] =  28'b1001100101001011010011000001;
        decoding_lut[51] =  28'b1001100101001111110011000001;
        decoding_lut[52] =  28'b1001000101000000110100000100;
        decoding_lut[53] =  28'b1001000101000100110100000100;
        decoding_lut[54] =  28'b1001000101001000110100000100;
        decoding_lut[55] =  28'b1001000101100000111010100001;
        decoding_lut[56] =  28'b1000000000000000110100000110;
        decoding_lut[57] =  28'b1000000000000000110100000110;
        decoding_lut[58] =  28'b1000000000000000110100000110;
        decoding_lut[59] =  28'b1000000000000000110100000110;
        decoding_lut[60] =  28'b0001000100000000001111000101;
        decoding_lut[61] =  28'b0001000100000000000100000100;
        decoding_lut[62] =  28'b0001000100000000000100000100;
        decoding_lut[63] =  28'b0001000100000000000100000100;
        decoding_lut[64] =  28'b1001100101000000000100000110;
        decoding_lut[65] =  28'b1001100101000100100100000110;
        decoding_lut[66] =  28'b1001100101001001000100000110;
        decoding_lut[67] =  28'b1101100101100000001111100011;
        decoding_lut[68] =  28'b1001000101000001000100000100;
        decoding_lut[69] =  28'b1001000101000101000100000100;
        decoding_lut[70] =  28'b1001000101001001000100000100;
        decoding_lut[71] =  28'b1001000101100001001010100001;
        decoding_lut[72] =  28'b1000000000000001000100000110;
        decoding_lut[73] =  28'b1000000000000001000100000110;
        decoding_lut[74] =  28'b1000000000000001000100000110;
        decoding_lut[75] =  28'b1000000000000001000100000110;
        decoding_lut[76] =  28'b0001000100000000001111000101;
        decoding_lut[77] =  28'b0001000100000000001111000101;
        decoding_lut[78] =  28'b0001000100000000000100000100;
        decoding_lut[79] =  28'b0001000100000000000100000100;
        decoding_lut[80] =  28'b1001100111000000000100000110;
        decoding_lut[81] =  28'b1001100111000100100100000110;
        decoding_lut[82] =  28'b1001100111001001000100000110;
        decoding_lut[83] =  28'b1101100111100000001111100011;
        decoding_lut[84] =  28'b1001000101000001010100000100;
        decoding_lut[85] =  28'b1001000101000101010100000100;
        decoding_lut[86] =  28'b1001000101001001010100000100;
        decoding_lut[87] =  28'b1001000101100001011010100001;
        decoding_lut[88] =  28'b1000000000000001010100000110;
        decoding_lut[89] =  28'b1000000000000001010100000110;
        decoding_lut[90] =  28'b1000000000000001010100000110;
        decoding_lut[91] =  28'b1000000000000001010100000110;
        decoding_lut[92] =  28'b0001000100000000000011111001;
        decoding_lut[93] =  28'b0001000100000000000011111001;
        decoding_lut[94] =  28'b0001000100000000000011111001;
        decoding_lut[95] =  28'b0001000100000000000011111001;
        decoding_lut[96] =  28'b1101000101000000001111000101;
        decoding_lut[97] =  28'b1101000101000100001111000101;
        decoding_lut[98] =  28'b1101000101001000001111000101;
        decoding_lut[99] =  28'b1101000101100000001111000101;
        decoding_lut[100] = 28'b1101000101000000001111100001;
        decoding_lut[101] = 28'b1101000101000100001111100001;
        decoding_lut[102] = 28'b1101000101001000001111100001;
        decoding_lut[103] = 28'b0001000100000000000100000100;
        decoding_lut[104] = 28'b1100000000000000001111100011;
        decoding_lut[105] = 28'b1100000000000000001111100011;
        decoding_lut[106] = 28'b1100000000000000001111100011;
        decoding_lut[107] = 28'b1100000000000000001111100011;
        decoding_lut[108] = 28'b1100000000000000001111000111;
        decoding_lut[109] = 28'b1100000000000000001111000111;
        decoding_lut[110] = 28'b1100000000000000001111000111;
        decoding_lut[111] = 28'b1100000000000000001111000111;
        decoding_lut[112] = 28'b0000001000000000000100000110;
        decoding_lut[113] = 28'b0000001000000000000100000110;
        decoding_lut[114] = 28'b0000010000000000000100000110;
        decoding_lut[115] = 28'b0000010000000000000100000110;
        decoding_lut[116] = 28'b0001000101000000000100000100;
        decoding_lut[117] = 28'b0001000101000100000100000100;
        decoding_lut[118] = 28'b0001000101001000000100000100;
        decoding_lut[119] = 28'b0001000101100000001000100001;
        decoding_lut[120] = 28'b0000000000000000000100000110;
        decoding_lut[121] = 28'b0000000000000000000100000110;
        decoding_lut[122] = 28'b0000000000000000000100000110;
        decoding_lut[123] = 28'b0000000000000000000100000110;
        decoding_lut[124] = 28'b0001000100000000000011001001;
        decoding_lut[125] = 28'b0001000100000000000011001001;
        decoding_lut[126] = 28'b0001000100000000000011001001;
        decoding_lut[127] = 28'b0001000100000000000011001001;
        decoding_lut[128] = 28'b1001000101100001101111000101;
        decoding_lut[129] = 28'b0001000100000000001111000101;
        decoding_lut[130] = 28'b0001000100000000001111000101;
        decoding_lut[131] = 28'b0001000100000000001111000101;
        decoding_lut[132] = 28'b1001000101000010000100000100;
        decoding_lut[133] = 28'b1001000101000110000100000100;
        decoding_lut[134] = 28'b1001000101001010000100000100;
        decoding_lut[135] = 28'b1001000100000000000100000100;
        decoding_lut[136] = 28'b1000000000000000000100000110;
        decoding_lut[137] = 28'b1000000000000000000100000110;
        decoding_lut[138] = 28'b1000000000000000000100000110;
        decoding_lut[139] = 28'b1000000000000000000100000110;
        decoding_lut[140] = 28'b0001000100000000000011000001;
        decoding_lut[141] = 28'b0001000100000000000011000001;
        decoding_lut[142] = 28'b0001000100000000001111000111;
        decoding_lut[143] = 28'b0001000100000000001111000111;
        decoding_lut[144] = 28'b1010100101000010010011000011;
        decoding_lut[145] = 28'b1010100101000110110011000011;
        decoding_lut[146] = 28'b1010100101001011010011000011;
        decoding_lut[147] = 28'b1010100101001111110011000011;
        decoding_lut[148] = 28'b1001000101000010010100000100;
        decoding_lut[149] = 28'b1001000101000110010100000100;
        decoding_lut[150] = 28'b1001000101001010010100000100;
        decoding_lut[151] = 28'b1001000100000000010100000100;
        decoding_lut[152] = 28'b1000000000000000010100000110;
        decoding_lut[153] = 28'b1000000000000000010100000110;
        decoding_lut[154] = 28'b1000000000000000010100000110;
        decoding_lut[155] = 28'b1000000000000000010100000110;
        decoding_lut[156] = 28'b0001000100000000001111111101;
        decoding_lut[157] = 28'b0001000100000000001111111101;
        decoding_lut[158] = 28'b0001000100010001000100100100;
        decoding_lut[159] = 28'b1001000101001101000011000001;
        decoding_lut[160] = 28'b1101000100000000001111100001;
        decoding_lut[161] = 28'b1101000100000000001111100001;
        decoding_lut[162] = 28'b1001100101000000001111100001;
        decoding_lut[163] = 28'b1001100111000000001111100001;
        decoding_lut[164] = 28'b1001000101000010100100000100;
        decoding_lut[165] = 28'b1001000101000110100100000100;
        decoding_lut[166] = 28'b1001000101001010100100000100;
        decoding_lut[167] = 28'b1001000100000000100100000100;
        decoding_lut[168] = 28'b1000000000000000100100000110;
        decoding_lut[169] = 28'b1000000000000000100100000110;
        decoding_lut[170] = 28'b1000000000000000100100000110;
        decoding_lut[171] = 28'b1000000000000000100100000110;
        decoding_lut[172] = 28'b0001000100000000001111000101;
        decoding_lut[173] = 28'b0001000100000000001111000101;
        decoding_lut[174] = 28'b0001000100000000001111000101;
        decoding_lut[175] = 28'b0001000100000000001111000101;
        decoding_lut[176] = 28'b1001100111000010010011000001;
        decoding_lut[177] = 28'b1001100111000110110011000001;
        decoding_lut[178] = 28'b1001100111001011010011000001;
        decoding_lut[179] = 28'b1001100111001111110011000001;
        decoding_lut[180] = 28'b1001000101000010110100000100;
        decoding_lut[181] = 28'b1001000101000110110100000100;
        decoding_lut[182] = 28'b1001000101001010110100000100;
        decoding_lut[183] = 28'b1001000100000000110100000100;
        decoding_lut[184] = 28'b1000000000000000110100000110;
        decoding_lut[185] = 28'b1000000000000000110100000110;
        decoding_lut[186] = 28'b1000000000000000110100000110;
        decoding_lut[187] = 28'b1000000000000000110100000110;
        decoding_lut[188] = 28'b0001000100000000001111000101;
        decoding_lut[189] = 28'b0001000100000000000100000100;
        decoding_lut[190] = 28'b0001000100000000000100000100;
        decoding_lut[191] = 28'b0001000100000000000100000100;
        decoding_lut[192] = 28'b1001100101000010010100000110;
        decoding_lut[193] = 28'b1001100101000110110100000110;
        decoding_lut[194] = 28'b1001100101001011010100000110;
        decoding_lut[195] = 28'b0001100100000000000100000110;
        decoding_lut[196] = 28'b1001000101000011000100000100;
        decoding_lut[197] = 28'b1001000101000111000100000100;
        decoding_lut[198] = 28'b1001000101001011000100000100;
        decoding_lut[199] = 28'b1001000100000001000100000100;
        decoding_lut[200] = 28'b1000000000000001000100000110;
        decoding_lut[201] = 28'b1000000000000001000100000110;
        decoding_lut[202] = 28'b1000000000000001000100000110;
        decoding_lut[203] = 28'b1000000000000001000100000110;
        decoding_lut[204] = 28'b0001000100000000001111000101;
        decoding_lut[205] = 28'b0001000100000000001111000101;
        decoding_lut[206] = 28'b0001000100000000000100000100;
        decoding_lut[207] = 28'b0001000100000000000100000100;
        decoding_lut[208] = 28'b1001100111000010010100000110;
        decoding_lut[209] = 28'b1001100111000110110100000110;
        decoding_lut[210] = 28'b1001100111001011010100000110;
        decoding_lut[211] = 28'b0001100110000000000100000110;
        decoding_lut[212] = 28'b1001000101000011010100000100;
        decoding_lut[213] = 28'b1001000101000111010100000100;
        decoding_lut[214] = 28'b1001000101001011010100000100;
        decoding_lut[215] = 28'b1001000100000001010100000100;
        decoding_lut[216] = 28'b1000000000000001010100000110;
        decoding_lut[217] = 28'b1000000000000001010100000110;
        decoding_lut[218] = 28'b1000000000000001010100000110;
        decoding_lut[219] = 28'b1000000000000001010100000110;
        decoding_lut[220] = 28'b0001000100000000001111000101;
        decoding_lut[221] = 28'b0001000100000000000100000100;
        decoding_lut[222] = 28'b0001000100000000000100000100;
        decoding_lut[223] = 28'b0001000100000000000100000100;
        decoding_lut[224] = 28'b1101000101000010001111000101;
        decoding_lut[225] = 28'b1101000101000110001111000101;
        decoding_lut[226] = 28'b1101000101001010001111000101;
        decoding_lut[227] = 28'b1101000100000000001111000101;
        decoding_lut[228] = 28'b1101000101000010001111100001;
        decoding_lut[229] = 28'b1101000101000110001111100001;
        decoding_lut[230] = 28'b1101000101001010001111100001;
        decoding_lut[231] = 28'b1101000100000000001111100001;
        decoding_lut[232] = 28'b1100000000000000001111100011;
        decoding_lut[233] = 28'b1100000000000000001111100011;
        decoding_lut[234] = 28'b1100000000000000001111100011;
        decoding_lut[235] = 28'b1100000000000000001111100011;
        decoding_lut[236] = 28'b1100000000000000001111000111;
        decoding_lut[237] = 28'b1100000000000000001111000111;
        decoding_lut[238] = 28'b1100000000000000001111000111;
        decoding_lut[239] = 28'b1100000000000000001111000111;
        decoding_lut[240] = 28'b0000001000000000000100000110;
        decoding_lut[241] = 28'b0000001000000000000100000110;
        decoding_lut[242] = 28'b0000010000000000000100000110;
        decoding_lut[243] = 28'b0000010000000000000100000110;
        decoding_lut[244] = 28'b1001000101000010000100000100;
        decoding_lut[245] = 28'b1001000101000110000100000100;
        decoding_lut[246] = 28'b1001000101001010000100000100;
        decoding_lut[247] = 28'b1001000100000000000100000100;
        decoding_lut[248] = 28'b0000000000000000000100000110;
        decoding_lut[249] = 28'b0000000000000000000100000110;
        decoding_lut[250] = 28'b0000000000000000000100000110;
        decoding_lut[251] = 28'b0000000000000000000100000110;
        decoding_lut[252] = 28'b0001000100000000000011001001;
        decoding_lut[253] = 28'b0001000100000000000011001001;
        decoding_lut[254] = 28'b0001000100000000000011001001;
        decoding_lut[255] = 28'b0001000100000000000011001001;
    end
    


endmodule
