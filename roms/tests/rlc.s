;; Contains tests for:
;; RLC m
SECTION "rom", ROM0[$0000]

main:
    ; Setup stack
    ld SP, $c040
    
    ld B, $a3
    rlc B
    push AF
    pop HL
    ld C, L
    
    ld D, B
    rlc D
    push AF
    pop HL
    ld E, L
    
    ld H, D
    rlc H
    
    halt
