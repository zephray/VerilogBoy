`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:52:53 02/10/2018 
// Design Name: 
// Module Name:    debugger 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module debugger(
    input rst,
    input clk,
    input [6:0] x,
    input [4:0] y,
    output [7:0] chr,
    input [7:0] instr,
    input [7:0] reg_a,
    input [7:0] reg_f,
    input [15:0] reg_bc,
    input [15:0] reg_de,
    input [15:0] reg_hl,
    input [15:0] reg_sp,
    input [15:0] reg_pc,
    input [4:0] reg_ie,
    input [4:0] reg_if,
    input [7:0] reg_scx,
    input [7:0] reg_scy,
    input [15:0] bp_addr
    );
    
    reg [7:0] line1 [0:79];
    reg [7:0] line2 [0:79];

    assign chr = (y == 7'd0) ? (line1[x]) : (
                 (y == 7'd29) ? (line2[x]) : (8'h00));
    
    initial begin
        $readmemh("screen1.mif", line1, 0, 79);
        $readmemh("screen2.mif", line2, 0, 79);
    end
    
    wire [7:0] reg_a_a;
    wire [7:0] reg_a_b;
    wire [7:0] reg_bc_a;
    wire [7:0] reg_bc_b;
    wire [7:0] reg_bc_c;
    wire [7:0] reg_bc_d;
    wire [7:0] reg_de_a;
    wire [7:0] reg_de_b;
    wire [7:0] reg_de_c;
    wire [7:0] reg_de_d;
    wire [7:0] reg_hl_a;
    wire [7:0] reg_hl_b;
    wire [7:0] reg_hl_c;
    wire [7:0] reg_hl_d;
    wire [7:0] reg_sp_a;
    wire [7:0] reg_sp_b;
    wire [7:0] reg_sp_c;
    wire [7:0] reg_sp_d;
    wire [7:0] reg_pc_a;
    wire [7:0] reg_pc_b;
    wire [7:0] reg_pc_c;
    wire [7:0] reg_pc_d;
    wire [7:0] instr_a;
    wire [7:0] instr_b;
    wire [7:0] reg_scx_a;
    wire [7:0] reg_scx_b;
    wire [7:0] reg_scy_a;
    wire [7:0] reg_scy_b;
    wire [7:0] bp_addr_a;
    wire [7:0] bp_addr_b;
    wire [7:0] bp_addr_c;
    wire [7:0] bp_addr_d;
    
    int_to_hex reg_a_a_disp  (reg_a [ 7: 4], reg_a_a);
    int_to_hex reg_a_b_disp  (reg_a [ 3: 0], reg_a_b);
    int_to_hex reg_bc_a_disp (reg_bc[15:12], reg_bc_a);
    int_to_hex reg_bc_b_disp (reg_bc[11: 8], reg_bc_b);
    int_to_hex reg_bc_c_disp (reg_bc[ 7: 4], reg_bc_c);
    int_to_hex reg_bc_d_disp (reg_bc[ 3: 0], reg_bc_d);
    int_to_hex reg_de_a_disp (reg_de[15:12], reg_de_a);
    int_to_hex reg_de_b_disp (reg_de[11: 8], reg_de_b);
    int_to_hex reg_de_c_disp (reg_de[ 7: 4], reg_de_c);
    int_to_hex reg_de_d_disp (reg_de[ 3: 0], reg_de_d);
    int_to_hex reg_hl_a_disp (reg_hl[15:12], reg_hl_a);
    int_to_hex reg_hl_b_disp (reg_hl[11: 8], reg_hl_b);
    int_to_hex reg_hl_c_disp (reg_hl[ 7: 4], reg_hl_c);
    int_to_hex reg_hl_d_disp (reg_hl[ 3: 0], reg_hl_d);
    int_to_hex reg_sp_a_disp (reg_sp[15:12], reg_sp_a);
    int_to_hex reg_sp_b_disp (reg_sp[11: 8], reg_sp_b);
    int_to_hex reg_sp_c_disp (reg_sp[ 7: 4], reg_sp_c);
    int_to_hex reg_sp_d_disp (reg_sp[ 3: 0], reg_sp_d);
    int_to_hex reg_pc_a_disp (reg_pc[15:12], reg_pc_a);
    int_to_hex reg_pc_b_disp (reg_pc[11: 8], reg_pc_b);
    int_to_hex reg_pc_c_disp (reg_pc[ 7: 4], reg_pc_c);
    int_to_hex reg_pc_d_disp (reg_pc[ 3: 0], reg_pc_d);
    int_to_hex instr_a_disp  (instr [ 7: 4], instr_a);
    int_to_hex instr_b_disp  (instr [ 3: 0], instr_b);
    int_to_hex reg_scx_a_disp(reg_scx[7: 4], reg_scx_a);
    int_to_hex reg_scx_b_disp(reg_scx[3: 0], reg_scx_b);
    int_to_hex reg_scy_a_disp(reg_scy[7: 4], reg_scy_a);
    int_to_hex reg_scy_b_disp(reg_scy[3: 0], reg_scy_b);
    int_to_hex bp_addr_a_disp(bp_addr[15:12],bp_addr_a);
    int_to_hex bp_addr_b_disp(bp_addr[11: 8],bp_addr_b);
    int_to_hex bp_addr_c_disp(bp_addr[ 7: 4],bp_addr_c);
    int_to_hex bp_addr_d_disp(bp_addr[ 3: 0],bp_addr_d);
    
    always @(*)
    begin
        line2[2]  = reg_a_a;
        line2[3]  = reg_a_b;
        line2[8]  = reg_bc_a;
        line2[9]  = reg_bc_b;
        line2[10] = reg_bc_c;
        line2[11] = reg_bc_d;
        line2[16] = reg_de_a;
        line2[17] = reg_de_b;
        line2[18] = reg_de_c;
        line2[19] = reg_de_d;
        line2[24] = reg_hl_a;
        line2[25] = reg_hl_b;
        line2[26] = reg_hl_c;
        line2[27] = reg_hl_d;
        line2[32] = reg_sp_a;
        line2[33] = reg_sp_b;
        line2[34] = reg_sp_c;
        line2[35] = reg_sp_d;
        line2[40] = reg_pc_a;
        line2[41] = reg_pc_b;
        line2[42] = reg_pc_c;
        line2[43] = reg_pc_d;
        line2[47] = instr_a;
        line2[48] = instr_b;
        line2[50] = (reg_f[7]) ? "Z" : " ";
        line2[51] = (reg_f[6]) ? "N" : " ";
        line2[52] = (reg_f[5]) ? "H" : " ";
        line2[53] = (reg_f[4]) ? "C" : " ";
        line2[58] = (reg_ie[4]) ? "H" : " ";
        line2[59] = (reg_ie[3]) ? "S" : " ";
        line2[60] = (reg_ie[2]) ? "T" : " ";
        line2[61] = (reg_ie[1]) ? "L" : " ";
        line2[62] = (reg_ie[0]) ? "V" : " ";
        line2[67] = (reg_if[4]) ? "H" : " ";
        line2[68] = (reg_if[3]) ? "S" : " ";
        line2[69] = (reg_if[2]) ? "T" : " ";
        line2[70] = (reg_if[1]) ? "L" : " ";
        line2[71] = (reg_if[0]) ? "V" : " ";
        line2[76] = bp_addr_a;
        line2[77] = bp_addr_b;
        line2[78] = bp_addr_c;
        line2[79] = bp_addr_d;
        line1[4]  = reg_scx_a;
        line1[5]  = reg_scx_b;
        line1[11] = reg_scy_a;
        line1[12] = reg_scy_b;
    end

    //assign screen_buffer[0][23] = "G";

endmodule
