;; Contains tests for:
;; RRC m
SECTION "rom", ROM0[$0000]

main:
    ; Setup stack
    ld SP, $c040
    
    ld B, $a3
    rrc B
    push AF
    pop HL
    ld C, L
    
    ld D, B
    rrc D
    push AF
    pop HL
    ld E, L
    
    ld H, D
    rrc H
    
    halt
