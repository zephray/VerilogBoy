# CPU

The Game Boy® is powered by a 8-bit Intel 8080-like CISC processor. It is usually called as "GB-Z80", however, it is not a Z80 compatible processor, nor a 8080 compatible processor. This page is not a full document of the original GameBoy processor, but some brief description of the processor and some of my own understanding. The information in this page may or may not be correct.

## Registers

The Game Boy CPU have one bank of general purpose 8-bit registers:

* B
* C
* D
* E
* H
* L

These 8-bit registers may be accessed as 16-bit registers:

*BC
*DE
*HL

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

Note: It is currently unclear about high page (0xFF00 - 0xFFFF) access timing diagram. WR doesn't seems to pulse during a high page write.

## Instruction Timing

## Microarchitecture

Note: the microarchitecutre part is mainly my guess of the GB CPU based on the given documents and tested behavior. I am implementing the CPU as follows.

BCDEHL are in the register file, while A, F, PC, and SP are not.

## Reference

* http://www.pastraiser.com/cpu/gameboy/gameboy_opcodes.html
* http://sgate.emt.bme.hu/patai/publications/z80guide/app1a.html
* http://www.devrs.com/gb/files/GBCPU_Instr.html
* https://github.com/Gekkio/mooneye-gb/blob/master/docs/accuracy.markdown