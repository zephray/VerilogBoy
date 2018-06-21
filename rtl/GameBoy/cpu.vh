/**
 * Definition of useful constants for the GB80 CPU.
 * 
 * @author Joseph Carlos (jcarlos)
 */

/**
 * Obligatory default nettype
 */
`default_nettype none

/**
 * ALU operations
 */
`define ALU_ADD 5'd0
`define ALU_ADC 5'd1
`define ALU_SUB 5'd2
`define ALU_SBC 5'd3
`define ALU_AND 5'd4
`define ALU_OR 5'd5
`define ALU_XOR 5'd6
`define ALU_DEC 5'd7
`define ALU_INC 5'd8
`define ALU_DAA 5'd9
`define ALU_NOT 5'd10
`define ALU_CCF 5'd11
`define ALU_SCF 5'd12
`define ALU_RLC 5'd13
`define ALU_RL 5'd14
`define ALU_RRC 5'd15
`define ALU_RR 5'd16
`define ALU_SL 5'd17
`define ALU_SRA 5'd18
`define ALU_SRL 5'd19
`define ALU_PASS0 5'd20
`define ALU_PASS1 5'd21
`define ALU_PASSF 5'd22
`define ALU_BIT 5'd23
`define ALU_SET 5'd24
`define ALU_RES 5'd25
`define ALU_SWAP 5'd26

/**
 * ALU size select
 */
`define ALU_SIZE_8 2'd0
`define ALU_SIZE_16 2'd1
`define ALU_SIZE_SPEC 2'd2

/**
 * ALU flag indices
 */
`define F_Z 3
`define F_N 2
`define F_H 1
`define F_C 0

/**
 * Regfile select
 */
`define RGF_B 5'b01_000
`define RGF_C 5'b00_000
`define RGF_D 5'b01_001
`define RGF_E 5'b00_001
`define RGF_H 5'b01_010
`define RGF_L 5'b00_010
`define RGF_SPH 5'b01_011
`define RGF_SPL 5'b00_011
`define RGF_PCH 5'b01_100
`define RGF_PCL 5'b00_100
`define RGF_BC 5'b10_000
`define RGF_DE 5'b10_001
`define RGF_HL 5'b10_010
`define RGF_SP 5'b10_011
`define RGF_PC 5'b10_100
`define RGF_NONE 5'b11_111

/**
 * Nintendo register numbers - used in opcodes
 */
`define NIN_A 3'b111
`define NIN_B 3'b000
`define NIN_C 3'b001
`define NIN_D 3'b010
`define NIN_E 3'b011
`define NIN_H 3'b100
`define NIN_L 3'b101
`define NIN_BC 3'b000
`define NIN_DE 3'b001
`define NIN_HL 3'b010
`define NIN_SP 3'b011

/**
 * ALU mux selects
 */
`define ALU_1_SEL_A 2'd0
`define ALU_1_SEL_DATA 2'd1
`define ALU_1_SEL_RGF 2'd2
`define ALU_1_SEL_TEMP1 2'd3
`define ALU_0_SEL_DATA 2'd0
`define ALU_0_SEL_TEMP0 2'd1
`define ALU_0_SEL_RSTP 2'd2
`define ALU_0_SEL_FF 2'd3

/**
 * Multibyte instruction codes
 */
`define MB_NONE 3'h0
`define MB_CB 3'h1
`define MB_BIT 3'h2
`define MB_SET 3'h3
`define MB_RES 3'h4

/**
 * MMIO defines
 */
`define MMIO_IF 16'hff0f
`define MMIO_IE 16'hffff
`define MMIO_DMA 16'hff46
`define MMIO_DIV 16'hff04
`define MMIO_TIMA 16'hff05
`define MMIO_TMA 16'hff06
`define MMIO_TAC 16'hff07
`define MMIO_BOOTSTRAP 16'hff50
`define MMIO_JOYSTICK 16'hff00
`define MMIO_SB 16'hff01
`define MMIO_SC 16'hff02
  
/**
 * Memory defines
 */
`define MEM_HIGH_END 16'hfffe
`define MEM_HIGH_START 16'hff80
`define MEM_OAM_END 16'hfe9f
`define MEM_OAM_START 16'hfe00
`define MEM_ECHO_END 16'hfdff
`define MEM_ECHO_START 16'he000
`define MEM_CRAM_END 16'hbfff
`define MEM_CRAM_START 16'ha000
`define MEM_CART_END 16'h7fff
`define MEM_CART_START 16'h0000
`define MEM_WRAM_END 16'hdfff
`define MEM_WRAM_START 16'hc000
`define MEM_VRAM_END 16'h9fff
`define MEM_VRAM_START 16'h8000
  
/**
 * Small chart of values
 * 0000  0  0
 * 0001  1  1
 * 0010  2  2
 * 0011  3  3
 * 0100  4  4
 * 0101  5  5
 * 0110  6  6
 * 0111  7  7
 * 1000  8  8
 * 1001  9  9
 * 1010 10  A
 * 1011 11  B
 * 1100 12  C
 * 1101 13  D
 * 1110 14  E
 * 1111 15  F
 */
  
  
