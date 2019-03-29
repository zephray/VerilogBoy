;; Contains tests for:
;; RRCA
SECTION "rom", ROM0[$0000]

main:
    ; Setup stack
    ld SP, $c040
    
    ld A, $a3
    rrca
    push AF
    pop HL
    ld B, H
    ld C, L
    
    rrca
    push AF
    pop HL
    ld D, H
    ld E, L
    
    rrca
    push AF
    pop HL
    
    rrca
    halt
