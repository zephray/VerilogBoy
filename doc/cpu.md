# CPU

The Game Boy® is powered by a 8-bit Intel 8080-like CISC processor. It is usually called as "GB-Z80", however, it is not a Z80 compatible processor, nor a 8080 compatible processor. This page is not a full document of the original GameBoy processor, but some brief description of the processor and some of my own understanding. The information in this page may or may not be correct.

For a comprehensive and more reliable documentation of GB CPU, see https://github.com/Gekkio/gb-ctr.

## Registers

The Game Boy CPU have one bank of general purpose 8-bit registers:

* B
* C
* D
* E
* H
* L

These 8-bit registers may be accessed as 16-bit registers:

* BC
* DE
* HL

There are two SF 8-bit registers:

* A - Accumulator
* F - Flags

There are 4 usable flags in the flags register, all other bits are 0:

* 7 - Z (Zero)
* 6 - N (Substract)
* 5 - H (Half Carry)
* 4 - C (Carry)

There are also two SF 16-bit registers:

* PC - Program Counter
* SP - Stack Pointer

Since the PC is 16-bit, SP should always be 16-bit aligned. SP always point to last used stack slot. Means that the first slot should be always empty.

Note, though there are 16-bit register, and the 8-bit register may be accessed in the 16-bit manner, the internal datapath is limited to 8-bit, means it could not finish 16-bit data transfer in one cycle. These are solely for addressing.

## Instructions

Instruction length can be 1 - 4 bytes long depending on the specific instruction. Opcodes can be seen as 9 bits long, and will be encoded into 1 or 2 bytes. If the first byte is 0xCB, then the second byte would be one of the high 256 opcodes, otherwise, the first byte is one of the low 256 opcodes. 

For example, if the first byte is 0x43, then the opcode of this instruction is 0x043; if the first byte is 0xCB and the next byte is the 0x43, then the opcode of this instruction is 0x143.

After the opcode, there can be a optional immediate, 8-bit or 16-bit long, gives the total length of 1 - 4 bytes.

## Execution Timing

The processor runs at either 4 MiHz (4194304 Hz = 2^12 Hz) or 8 MiHz (Double Speed Mode on GBC). The instruction execution time is always dividable by 4, ranging from 4 cycles to 20 cycles. Ususally a clock cycle at 4 MiHz is called a T-cycle. 4 T-cycles combined together is called a M-cycle (1 MiHz). So, one instruction could take 1 - 5 M-cycles to execute. 

The processor can do one memory read or memory write in one M-cycle, since the instruction itself needed be fetched, the execution speed can never be faster than the speed it can read the instruction. For example, a 3 byte instruction needs at least 3 M-cycles (12 T-cycles) to execute. If the instruction involves memory read or write, the processor would have to spend more M-cycles just to access the memory. 

The processor is also only capable of doing 1 8-bit ALU operation each M-cycle, if the instruction need to do 16-bit ALU operation, additional 1 M-cycle may be needed to complete the operation.

The processor also has a prefetch queue with the length of 1 byte.

## Bus Timing

The GB CPU has one 8080 bus compatible bus. The bus supports only memory access, not IO access. All the ROM, RAM, and MMIO peripherals are on the same bus. Here is a timing diagram:

```text
            |  1  |  2  |  3  |  4  |
          ___________             _____            
CLK  ____|           |___________|     
    __    __    __    __    __    __    
CK    |__|  |__|  |__|  |__|  |__|  |__
    ___________                   _____
CS             |_________________|
             ____________________
RD  ________|                    |_____
    _________________       ___________
WR                   |_____|
     _______ _______________________ __
ADDR _______X_______________________X__
                      _____
DATA ----------------<_____>-----------
```

CLK: 1 MiHz Bus Reference Clock
CK:  4 MiHz Internal Clock (need to verify the phase)
ADDR: Address Bus
CS, RAM Access Enable, Low Active
RD: Read Enable, Low Active
WR, Write Enable, Low Active

Note: See GB-CTR for more information.

## Instructions

## Common Encodings

### 16bit Reg addressing encoding 1 (e_ad1)
* 2'b00: BC
* 2'b01: DE
* 2'b10: HL
* 2'b11: SP

### 16bit Reg addressing encoding 2 (e_ad2)
* 2'b00: BC
* 2'b01: DE
* 2'b10: HL+
* 2'b11: HL-

### 16bit Reg addressing encoding 3 (e_ad3)
* 2'b00: BC
* 2'b01: DE
* 2'b10: HL
* 2'b11: AF

### 8bit Reg addressing encoding 1 (e_ab1)
* 3'b000: B
* 3'b001: C
* 3'b010: D
* 3'b011: E
* 3'b100: H
* 3'b101: L
* 3'b110: databus
* 3'b111: A

### 8bit Reg addressing encoding 2 (e_ab2)
* e_ab1 with LSB moved to MSB (021)

### ALU operations (e_alu)
* 3'b000 ADD
* 3'b001 ADC
* 3'b010 SUB
* 3'b011 SBC
* 3'b100 AND
* 3'b101 XOR
* 3'b110 OR
* 3'b111 CP

### Special ALU operations (e_alu_sp)
* 2'b00 DAA
* 2'b01 CPL
* 2'b10 SCF
* 2'b11 CCF

### Bitwise ALU operations part 1 (e_alu_b1)
* 3'b000 RLC
* 3'b001 RRC
* 3'b010 RL
* 3'b011 RR
* 3'b100 SLA
* 3'b101 SRA
* 3'b110 SWAP
* 3'b111 SRL

### Bitwise ALU operations part 2 (e_alu_b2)

* 2'b00 Used by other opcodes
* 2'b01 BIT
* 2'b10 RES
* 2'b11 SET

## Load SP to Immediate Address

* LD (a16), SP
* 3 bytes long
* 5 M-cycles to execute
* No flags shall be altered
* 8'b00001000

## Load 16bit immediate to 16bit register

* LD rr, d16
* 3 bytes long
* 3 M-cycles to execute
* No flags shall be altered
* 8'b00rr0001
* Use e_ad1 for rr encoding

## Load Register to Memory

* LD (rr), A
* 1 byte long
* 2 M-cycles to execute
* No flags shall be altered
* If self increment/decrement is involved, it should happen after the access
* 8'b00dd0010
* Use e_ad2 for rr encoding

## Load 8bit Immediate to 8bit Register/ to Memory

* LD r, d8 / LD (HL), d8
* 2 bytes long
* 2 (reg)/ 3 (mem) M-cycles to execute
* No flags shall be altered
* 8'b00rrr110
* Use e_ab2 for rrr encoding

## Load Memory to Register

* LD A, (rr)
* 8'b00dd1010
* Otherwise the same as load reg to mem

## Load 8bit Register to 8bit Register/ to/ from Memory

* LD rd, rs
* 1 byte long
* 1 (reg)/ 2 (mem) M-cycles to execute
* No flags shall be altered
* 8'b01dddsss
* Use e_ab1 for ddd encoding
* Use e_ab1 for sss encoding
* Note that LD (HL), (HL) is impossible, it is replaced by HALT

## 16bit Register Self Increment/ Decrement

* INC dd / DEC dd
* 1 byte long
* 2 M-cycles to execute
* No flags shall be altered
* 8'b00dd0011 (INC) / 8'b00dd1011 (DEC)
* Use e_ad1 for dd encoding

## 8bit Register/ Memory Self Increment/ Decrement

* INC d / DEC d / INC (HL) / DEC (HL)
* 1 byte long
* 1 (reg)/ 3 (mem) M-cycles to execute
* Zero, Substract, and Half-Carry flag are altered
* 8'b00ddd100 (INC) / 8'b00ddd101 (DEC)
* Use e_ab2 for ddd encoding

## 8bit ALU Operations

* ADD r / ADC r / SUB r / SBC r / AND r / XOR r / OR r / CP r
* 1 byte (reg/mem) / 2 (imm) long
* 1 (reg) / 2 (mem) / 2 (imm) M-cycles to execute
* Flags depending on operation
* 8'b1iaaarrr
* i: 0 - Read from (HL), 1 - Use immediate value
* Use e_alu for aaa encoding
* Use e_ab1 for rrr encoding

## 8bit Special ALU Operations

* DAA / SCF / CPL / CCF
* 1 byte long
* 1 M-cycle to execute
* Flag depends
* 8'b001ss1111
* Use e_alu_sp for ss encoding

## 8bit Bitwise ALU Operations Part 1

* RLC r / RRC r / RL r / RR r / SLA r / SRA r / SWAP r / SRL r
* 1 byte long (not include CB)
* 1 (reg) / 3 (mem) to execute
* Flag depends
* 8'b00bbbrrr
* Use e_alu_b1 for bbb encoding
* Use e_ab1 for rrr encoding

## 8bit Bitwise ALU Operations Part 2

* BIT n, r / RES n, r / SET n, r
* 1 byte long (not include CB)
* 1 (reg) / 2 (memwb) / 3 (memtest) to execute
* Flags depends
* 8'bccnnnrrr
* Use e_alu_b2 for cc encoding
* Use e_ab1 for rrr encoding

## Microarchitecture

Note: This is NOT the microarchitecture of the GameBoy CPU, but that of the VerilogBoy CPU. It is a non-pipelined multi-cycle CISC core with hardwired control logic. To optimize the resource usage, the first stage decoding is actually a 256 entries LUT.

BCDEHLSP are in the register file, while A, F, and PC are not.

One M-cycle is 4 T-cycle. 

### CT-FSM

CT-FSM is a FSM running with the main 4 MiHz clock. It takes care of all the bus operations and instruction execution. It has 4 states,  always executed in a loop, from S0 to S3. To be clear, I am describing it from 2 perspectives: bus operation and instruction execution.

Bus Operation:

* S0: High Page access from last M-cycle
* S1: Setup Address
* S2: Wait
* S3: Setup Data for write cycle, Latch data for read cycle 

Instruction Execution:

* S0: Decoding & Execution
* S1: Register Write Back
* S2: PC Increment Cycle 1 / SP Operation Cycle 1
* S3: PC Increment Cycle 2 / SP Operation Cycle 2

### EX-FSM

EX-FSM is a FSM running only in S0 state in CT-FSM. The reason of having this FSM is that the CPU might need multiple M cycles to finish the execution of a single instruction, the FSM would keep track of which cycle it is in. Means the state of this FSM should always match the M cycle number.

If the instruction finishes this cycle, next cycle would be S0.

Main tasks of this FSM:
pc_wr
* Determine if this M-cycle would be memory write, memory read, or instruction fetch.
* Determine the input numbers of the ALU.
* Determine if the output of ALU should be write back to register.
* Determine if PC needs to be incremented.

Example:

ADD A, B, 1 cycle operation
During M0 - S1, EX-FSM instruct ALU OpA to be A, ALU OpB to be B, ALU Res WB En.

ADD A, (HL), 2 cycle operation

During M0 - S1, EX-FSM instruct ALU OpA to be A, ALU OpB to be Data Bus, ALU Res WB NEN, HL output to be next cycle ABUS Src, next state is S2

During M1 - S2, EX-FSM instruct ALU Res WB EN, PC output to be next cycle ABUS Src, next state is S1

```
       -----------             -----------             -----------             -----------             -----------
   ___|           |___________|           |___________|           |___________|           |___________|
      ^ S3 - Instr Fetch      ^ S0 - Control Unit     ^ S1 - Output PC low    ^ S2 - Output PC high   ^ S3 - ALU Free
                                                      ^ S1 - Output Last PC
                                                      ^ S1 - Register WB      ^ PC low WB             ^ PC high WB
```

JR:
Cycle 0: Fetch PC (JR); Calculate PC + 1
Cycle 1: JR execution, Fetching PC + 1, PC + 2 interrupted.
Cycle 2: r ready, calculate PC + r low byte
Cycle 3: calculate PC + r high byte, save to PC, and output to bus (!!!)

PUSH:
Cycle 0: Fetch PC (PUSH); Calculate PC + 1
Cycle 1: ALU: Nothing. No bus op. PC + 1 circuit use to calculate SP - 1
Cycle 2: ALU: Fetch B; DATA from Regfile; PC + 1 circuit use to calculate SP - 1
Cycle 3: ALU: Fetch C; DATA from Regfile; PC + 1 stopped.
Cycle 4: PC + 2 calculated; Fetch PC + 1;

POP:
Cycle 0: Fetch PC (POP), Calculate PC + 1
Cycle 1: ALU: Nothing. DATA Read from SP. PC + 1 circuit use to calculate SP + 1
Cycle 2: ALU: Data buffer to B; Data Read from SP. PC + 1 circuit use to calculate SP + 1
Cycle 3: ALU: Data buffer to C; Fetch PC + 1; Calculate PC + 1

LD (nn), A:
Cycle 0: Fetch PC, Calculate PC + 1
Cycle 1: ALU do nothing. Fetch PC + 1 (Imm), Calculate PC + 1
Cycle 2: ALU do nothing. Fetch PC + 1 (Imm), Stop PC calculation.
Cycle 3: ALU do nothing. Data write from A to TEMP. Stop PC calculation.
Cycle 4: ALU do nothing. Fetch PC + 1; Calculate PC + 1;

LD (nn), SP:
Cycle 0: Fetch PC, Calculate PC + 1
Cycle 1: ALU do nothing. Fetch PC + 1 (Imm), Calculate PC + 1
Cycle 2: ALU do nothing. Fetch PC + 1 (Imm), Stop PC calculation.
Cycle 3: ALU do nothing. Addr from Imm, Data write from SP to bus. Calculate Imm + 1
Cycle 4: ALU do nothing. Addr from Imm, Data write from SP to bus. 
Cycle 5: ALU do nothing. Fetch PC + 1; Calculate PC + 1;

LD A, (nn):
Cycle 0: Fetch PC, Calculate PC + 1
Cycle 1: ALU do nothing. Fetch PC + 1 (Imm), Calculate PC + 1
Cycle 2: ALU do nothing. Fetch PC + 1 (Imm), Stop PC calculation.
Cycle 3: ALU do nothing. Data read from TEMP. Stop PC calculation.
Cycle 4: ALU store data buffer to A. Fetch PC + 1; Calculate PC + 1;

RST:
Cycle 0: Fetch PC, Calculate PC + 1
Cycle 1: ALU: PCl to DB. No bus op. PC + 1 circuit use to calculate SP - 1
Cycle 2: ALU: PCh to DB; DATA from PCl to SP; PC + 1 circuit use to calculate SP - 1
Cycle 3: ALU: 16bit PC from Opcode; DATA from PCh to SP; Stop PC calculation.
Cycle 4: Fetch new PC; Calculate PC + 1

CALL nn:
Cycle 0: Fetch PC, Calculate PC + 1
Cycle 1: ALU do nothing. Fetch PC + 1 (Imm), Stop PC calculation.
Cycle 2: ALU do nothing. Fetch PC + 1 (Imm), Stop PC calculation.
Cycle 3: ALU: Nothing. No bus op. PC + 1 circuit use to calculate SP - 1
Cycle 4: ALU: Nothing; DATA from PCh to SP; PC + 1 circuit use to calculate SP - 1
Cycle 5: ALU: 16bit PC from Temp; DATA from PCl to SP; Stop PC calculation.
Cycle 6: Fetch new PC; Calculate PC + 1

RET:
Cycle 0: Fetch PC, Calculate PC + 1
Cycle 1: ALU: Nothing. Read SP. PC + 1 circuit use to calculate SP + 1
Cycle 2: ALU: Copy from Databus to PCl; Read SP + 1; PC + 1 circuit use to calculate SP + 1
Cycle 3: ALU: Copy from Databus to PCh; Databus no op. Stop PC calculation.
Cycle 4: Fetch new PC; Calculate PC + 1

RET cc:
Cycle 0: Fetch PC, Calculate PC + 1
Cycle 1: Check condition and decide if need to continue
Cycle 2: If taken, same as ret start from Cycle 1; If not, fetch new PC; Calculate PC + 1

## Interrupt

The interrupt check happens at the same time as the instruction fetch (S3). If there is an interrupt, the normal execution would be stopped, and the instruction fetch for the ISR would happen at the fifth M cycle:

Cycle 0: During normal PC fetch and PC+1 calculation, interrupt happend, dispatch scheduled.
Cycle 1: Calculate SP - 1. Bus no op.
Cycle 2: Calculate SP - 1. Bus write PCh.
Cycle 3: No calculate. Bus write PCl. Check interrupt source, decide which to dispatch
Cycle 4: Fetch first byte of ISR
Cycle 5: Start ISR execution

## Reference

* http://www.pastraiser.com/cpu/gameboy/gameboy_opcodes.html
* http://sgate.emt.bme.hu/patai/publications/z80guide/app1a.html
* http://www.devrs.com/gb/files/GBCPU_Instr.html
* https://github.com/Gekkio/mooneye-gb/blob/master/docs/accuracy.markdown
* https://gekkio.fi/files/gb-docs/gbctr.pdf
