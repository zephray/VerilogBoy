# CPU Control Unit Signals

## alu_src_a

Select ALU Operand 1 source:

00 - A register
01 - PC byte
10 - Register file
11 - Databus buffer

## alu_src_b

Select ALU Operand 2 source:

000 - A register
001 - Carry bit
010 - Constant 0
011 - Constant 1
100 - H register
101 - L register
110 - Absolute Imm Low
111 - Imm Low

## alu_op_prefix

Prepend to alu_op_mux

00 - Normal ALU operations
01 - Shift&Rotate ALU operations
10 - Special ALU operations
11 - CB prefix ALU operations

## alu_op_src

Selection source of alu_op

00 - Instruction[5:3]
01 - {1'b1, Instruction[7:6]}
10 - Fixed ADD ; F to result
11 - Fixed SUB ; A to F

# alu_op_signed

Force signed operation

## alu_dst

Selection of destination of ALU.
00 - A register
01 - PC byte
10 - Register file 
11 - Databus buffer

## pc_src

16-bit PC write source

00 - Register file
01 - {10'b00, Instruction[7:6], Instruction[3], 3'b000}
10 - temp register
11 - 

## pc_we

16-bit PC write enable (from register file)

## pc_b_sel

Cycle 0, 2, 4 select PCl
Cycle 1, 3, 5 select PCh
This could not be overrided

## rf_wr_sel

Register file write target selection.

000 - B / BC
001 - C
010 - D / DE
011 - E
100 - H / HL
101 - L
110 - SP High / SP
111 - SP Low

## rf_rd_sel

Register file read source selection.

## bus_op

00 - Idle cycle
01 - Instruction Fetch
10 - Write cycle
11 - Read cycle (Imm or Data)

## db_src

00 - A register
01 - ALU result
10 - Register file
11 - Databus Buffer

## ab_src

00 - PC register
01 - temp register
10 - Register file 16bit read out
11 - SP register

## ct_op

Operation of CT-FSM at this M-cycle.

00 - Nothing
01 - PC + 1
10 - SP - 1
11 - SP + 1

## temp_redir

Redirect regfile operation to temp register

0 - Normal
1 - Redir

## opcode_redir

Redirect opcode read to temp register (for 0xCB)

0 - Normal
1 - Redir


## flags_we

Will the flag being written to F register?

## next

Does this instruction end at this cycle

## int_master_en

The global interrupt enable flag is handled inside the control unit. This signal is the current enable flag status from control unit.

## int_dispatch

The flag to control unit indicating if the interrupt dispatch is ongoing.

## int_ack

The flag from control unit indicating that the dispatching is finished and the dispatch flag should be cleared.
