;; Contains tests for:
;; RRA
SECTION "rom", ROM0[$0000]

main:
    ; Setup stack
    ld SP, $c040
    
    ld A, $a3
    rra
    push AF
    pop HL
    ld B, H
    ld C, L
    
    rra
    push AF
    pop HL
    ld D, H
    ld E, L
    
    rra
    push AF
    pop HL
    
    rra
    halt
