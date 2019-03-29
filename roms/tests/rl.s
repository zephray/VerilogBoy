;; Contains tests for:
;; RL m
SECTION "rom", ROM0[$0000]

main:
    ; Setup stack
    ld SP, $c040
    
    ld B, $a3
    rl B
    push AF
    pop HL
    ld C, L
    
    ld D, B
    rl D
    push AF
    pop HL
    ld E, L
    
    ld H, D
    rl H
    
    halt
