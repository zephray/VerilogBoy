//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    17:30:26 02/08/2018 
// Module Name:    None
// Project Name:   VerilogBoy
// Description: 
//   Common definitions for VerilogBoy. Use as a header inclusion.
// Dependencies: 
// 
// Additional Comments: 
//   It is also used in Verilated simulation
//////////////////////////////////////////////////////////////////////////////////


`define ALU_ADD 3'b000
`define ALU_ADC 3'b001
`define ALU_SUB 3'b010
`define ALU_SBC 3'b011
`define ALU_AND 3'b100
`define ALU_XOR 3'b101
`define ALU_OR  3'b110
`define ALU_CP  3'b111

`define INT_LCDC   0
`define INT_STAT   1
`define INT_TIMER  2
`define INT_SERIAL 3
`define INT_JOYPAD 4