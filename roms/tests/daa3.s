;; Contains tests for the following:
;; DAA
SECTION "rom", ROM0[$0000]

main:
    ld SP, $c040

    ld A, $00
    ld B, $00
    add B
    daa
    push AF
    pop BC
    
    ld A, $07
    ld B, $13
    add B
    daa
    push AF
    pop HL
    ld D, L
    
    ld A, $07
    ld B, $09
    add B
    daa
    push AF
    pop HL
    ld E, L
    
    ld A, $88
    ld B, $10
    add B
    daa
    push AF
    pop HL
    
    ld A, $99
    ld B, $01
    add B
    daa
    
    halt
