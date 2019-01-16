`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:24:14 01/14/2019 
// Design Name: 
// Module Name:    mc 
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
module mc(
    input vb_clk,
    input vb_rst,
    output reg [7:0] vb_din,
    input [7:0] vb_dout,
    input [15:0] vb_a,
    input vb_wr,
    input vb_rd,
    input vb_brom_en,
    input [4:0] vb_wram_bank, // Up to 32 pages
    output reg [7:0] wb_a,
    output reg [7:0] wb_din,
    input [7:0] wb_dout,
    output reg wb_cyc,
    output reg wb_stb,
    output reg wb_we,
    input wb_ack,
    input wb_stall,
    output reg [22:0] rom_a,
    input [7:0] rom_d,
    output reg rom_rd,
    output reg [17:0] ram_a,
    output reg [7:0] ram_din,
    input [7:0] ram_dout,
    output reg ram_wr,
    output reg ram_rd,
    output reg [13:0] brom_a,
    input [7:0] brom_d,
    output reg brom_rd
    );
    
    // VB Core Memory Map: (16-bit address, 64KiB)
    // 0000 - 3EFF Cartridge Bank 0 (PSRAM) / BootROM (BRAM)
    // 3F00 - 3FFF Cartridge Bank 0 (PSRAM) / Peripherals (Wishbone)
    // 4000 - 7FFF Cartridge Bank X (PSRAM)
    // 8000 - 9FFF Blank (Mapped inside the VB Core)
    // A000 - BFFF CRAM (PSRAM)
    // C000 - DFFF WRAM (PSRAM)
    // E000 - FFFF Blank (No mapping exist)
    
    // Virtual Cartridge Interface, connect to MBC module
    wire [22:14] rom_a_high;
    wire [16:13] ram_a_high;
    
    mbc5 mbc(
        .vb_clk(vb_clk),
        .vb_a(vb_a[15:12]),
        .vb_d(vb_dout[7:0]),
        .vb_wr(vb_wr),
        .vb_rd(vb_rd),
        .vb_rst(vb_rst),
        .rom_a(rom_a_high),
        .ram_a(ram_a_high),
        .rom_cs_n(),
        .ram_cs_n()
    );
    
    always @(*) begin
        brom_rd = 1'b0;
        brom_a = 14'bX;
        wb_a = 8'bX;
        wb_din = 8'bX;
        wb_cyc = 1'b0;
        wb_stb = 1'b0;
        wb_we = 1'b0;
        rom_rd = 1'b0;
        rom_a = 23'bX;
        ram_rd = 1'b0;
        ram_wr = 1'b0;
        ram_a = 18'bX;
        ram_din = 8'bX;
        vb_din = 8'bX;
        if ((vb_a >= 16'h0000) && (vb_a <= 16'h3EFF) && (vb_brom_en)) begin
            // Map to BootROM
            brom_a[13:0] = vb_a[13:0];
            brom_rd = vb_rd;
            vb_din = brom_d;
        end
        else if ((vb_a >= 16'h3F00) && (vb_a <= 16'h3FFF) && (vb_brom_en)) begin
            // Map to Wishbone (Ignoring ACK and STALL)
            wb_a = vb_a[7:0];
            wb_din[7:0] = vb_dout[7:0];
            vb_din[7:0] = wb_dout;
            wb_we = vb_wr;
            wb_cyc = vb_wr | vb_rd;
            wb_stb = wb_cyc;
        end
        else if ((vb_a >= 16'h0000) && (vb_a <= 16'h7FFF)) begin
            // Map to ROM
            rom_rd = vb_rd;
            rom_a[22:14] = rom_a_high[22:14];
            rom_a[13:0] = vb_a[13:0];
            vb_din[7:0] = rom_d[7:0];
        end
        else if ((vb_a >= 16'hA000) && (vb_a <= 16'hBFFF)) begin
            // Map to Cart RAM
            ram_wr = vb_wr;
            ram_rd = vb_rd;
            ram_a[17] = 1'b0;
            ram_a[16:13] = ram_a_high[16:13];
            ram_a[12:0] = vb_a[12:0];
            ram_din = vb_dout;
            vb_din = ram_dout;
        end
        else if ((vb_a >= 16'hA000) && (vb_a <= 16'hAFFF)) begin
            // Map to Work RAM (Bank 0)
            ram_wr = vb_wr;
            ram_rd = vb_rd;
            ram_a[17:12] = 6'b100000;
            ram_a[11:0] = vb_a[11:0];
            ram_din = vb_dout;
            vb_din = ram_dout;
        end
        else if ((vb_a >= 16'hB000) && (vb_a <= 16'hBFFF)) begin
            // Map to Work RAM (Bank X)
            ram_wr = vb_wr;
            ram_rd = vb_rd;
            ram_a[17] = 1'b1;
            ram_a[16:12] = vb_wram_bank[4:0];
            ram_a[11:0] = vb_a[11:0];
            ram_din = vb_dout;
            vb_din = ram_dout;
        end
    end


endmodule
