;; Contains tests for:
;; RLA
SECTION "rom", ROM0[$0000]

main:
    ; Setup stack
    ld SP, $c040
    
    ld A, $a3
    rla
    push AF
    pop HL
    ld B, H
    ld C, L
    
    rla
    push AF
    pop HL
    ld D, H
    ld E, L
    
    rla
    push AF
    pop HL
    
    rla
    halt
