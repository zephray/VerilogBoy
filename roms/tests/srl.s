;; Contains tests for:
;; srl m
SECTION "rom", ROM0[$0000]

main:
    ; Setup stack
    ld SP, $c040
    
    ld B, $a3
    srl B
    push AF
    pop HL
    ld C, L
    
    ld D, B
    srl D
    push AF
    pop HL
    ld E, L
    
    ld H, D
    srl H
    
    halt
