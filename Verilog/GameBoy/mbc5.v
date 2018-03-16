`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    23:34:43 03/15/2018 
// Design Name: 
// Module Name:    mbc5 
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
module mbc5(
    input gb_clk,
    input [15:12] gb_a,
    input [7:0] gb_d,
    input gb_cs,
    input gb_wr,
    input gb_rd,
    input gb_rst,
    output [22:14] rom_a,
    output [16:13] ram_a,
    output rom_cs,
    output ram_cs,
    output ddir,
    output reg [8:0] rom_bank
    );

    //reg [8:0] rom_bank = 9'b000000001;
    reg [3:0] ram_bank = 4'b0;
    reg ram_en = 1'b0; // RAM Access Enable

    wire rom_addr_en;//RW Address in ROM range
    wire ram_addr_en;//RW Address in RAM range

    wire [15:0] gb_addr;

    assign gb_addr[15:12] = gb_a[15:12];
    assign gb_addr[11:0] = 12'b0;

    assign rom_addr_en =  (gb_addr >= 16'h0000)&(gb_addr <= 16'h7FFF); //Request Addr in ROM range
    assign ram_addr_en =  (gb_addr >= 16'hA000)&(gb_addr <= 16'hBFFF); //Request Addr in RAM range
    assign rom_addr_lo =  (gb_addr >= 16'h0000)&(gb_addr <= 16'h3FFF); //Request Addr in LoROM range

    assign rom_cs = ((rom_addr_en) & (gb_rst == 0)) ? 0 : 1; //ROM output enable
    assign ram_cs = ((ram_addr_en) & (ram_en) & (gb_rst == 0)) ? 0 : 1; //RAM output enable

    assign rom_a[22:14] = rom_addr_lo ? 9'b0 : rom_bank[8:0];
    assign ram_a[16:13] = ram_bank[3:0];

    //LOW: GB->CART, HIGH: CART->GB
    // ADDR_EN GB_WR DIR
    // 0       x     L
    // 1       H     H
    // 1       L     L
    //assign DDIR = (((rom_addr_en) | (ram_addr_en))&(GB_WR)) ? 1 : 0;
    // (ROM_CS = 0 | RAM_CS = 0) & RD = 0 -> output, otherwise, input
    assign ddir = (((rom_cs) | (ram_cs)) & (gb_rd)) ? 1 : 0;

    wire rom_bank_lo_clk;
    wire rom_bank_hi_clk;
    wire ram_bank_clk;
    wire ram_en_clk;
    
    reg gb_wr_last;
    
    always@(posedge gb_clk)
    begin
        if (gb_rst) begin
            gb_wr_last <= 0;
            rom_bank[8:0] <= 9'b000000001;
            ram_bank[3:0] <= 4'b0000;
            ram_en <= 0;
        end
        else begin
            gb_wr_last <= gb_wr;
            if ((gb_wr_last == 0)&&(gb_wr == 1)) begin
                case (gb_addr)
                    16'h0000: ram_en <= (gb_d[3:0] == 4'hA) ? 1 : 0;
                    16'h1000: ram_en <= (gb_d[3:0] == 4'hA) ? 1 : 0;
                    16'h2000: rom_bank[7:0] <= gb_d[7:0];
                    16'h3000: rom_bank[8] <= gb_d[0];
                    16'h4000: ram_bank[3:0] <= gb_d[3:0];
                    16'h5000: ram_bank[3:0] <= gb_d[3:0];
                endcase
            end
        end
    end

endmodule
