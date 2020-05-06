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

`define ALU_SRC_A_ACC               2'b00
`define ALU_SRC_A_PC                2'b01
`define ALU_SRC_A_REG               2'b10
`define ALU_SRC_A_DB                2'b11
`define ALU_SRC_B_ACC               3'b000
`define ALU_SRC_B_CARRY             3'b001
`define ALU_SRC_B_ZERO              3'b010
`define ALU_SRC_B_ONE               3'b011
`define ALU_SRC_B_H                 3'b100
`define ALU_SRC_B_L                 3'b101
`define ALU_SRC_B_ABSIMM            3'b110
`define ALU_SRC_B_IMM               3'b111
`define ALU_OP_PREFIX_NORMAL        2'b00
`define ALU_OP_PREFIX_SHIFT_ROTATE  2'b01
`define ALU_OP_PREFIX_SPECIAL       2'b10
`define ALU_OP_PREFIX_CB            2'b11
`define ALU_OP_SRC_INSTR_5TO3       2'b00
`define ALU_OP_SRC_INSTR_7TO6       2'b01
`define ALU_OP_SRC_ADD_FTOR         2'b10
`define ALU_OP_SRC_SUB_ATOF         2'b11
`define ALU_OP_SIGNED_FORCE         1'b1
`define ALU_OP_SIGNED_AUTO          1'b0
`define ALU_DST_ACC                 2'b00
`define ALU_DST_PC                  2'b01
`define ALU_DST_REG                 2'b10
`define ALU_DST_DB                  2'b11
`define PC_SRC_REG                  2'b00
`define PC_SRC_RST                  2'b01
`define PC_SRC_TEMP                 2'b10
`define PC_WRITE_ENABLE             1'b1
`define RF_SEL_B                    3'b000
`define RF_SEL_C                    3'b001
`define RF_SEL_D                    3'b010
`define RF_SEL_E                    3'b011
`define RF_SEL_H                    3'b100
`define RF_SEL_L                    3'b101
`define RF_SEL_SP_H                 3'b110
`define RF_SEL_SP_L                 3'b111
`define RF_SEL_BC                   3'b001
`define RF_SEL_DE                   3'b011
`define RF_SEL_HL                   3'b101
`define RF_SEL_SP                   3'b111
`define BUS_OP_IDLE                 2'b00
`define BUS_OP_IF                   2'b01
`define BUS_OP_WRITE                2'b10
`define BUS_OP_READ                 2'b11
`define DB_SRC_ACC                  2'b00
`define DB_SRC_ALU                  2'b01
`define DB_SRC_REG                  2'b10
`define DB_SRC_DB                   2'b11
`define AB_SRC_PC                   2'b00
`define AB_SRC_TEMP                 2'b01
`define AB_SRC_REG                  2'b10
`define AB_SRC_SP                   2'b11
`define CT_OP_IDLE                  2'b00
`define CT_OP_PC_INC                2'b01
`define CT_OP_SP_DEC                2'b10
`define CT_OP_SP_INC                2'b11
`define FLAGS_ZNHC                  2'b00
`define FLAGS_x0HC                  2'b01
`define FLAGS_00HC                  2'b10
`define FLAGS_ZNHx                  2'b11
