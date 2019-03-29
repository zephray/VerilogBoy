;; Contains tests for the following:
;; DAA
SECTION "rom", ROM0[$0000]

main:
    ld SP, $c040

    ld A, $89
    ld B, $71
    add B
    daa
    push AF
    pop BC
    
    ld A, $89
    ld B, $69
    add B
    daa
    push AF
    pop HL
    ld D, L
    
    ld A, $89
    ld B, $77
    sub B
    daa
    push AF
    pop HL
    ld E, L
    
    ld A, $80
    ld B, $15
    sub B
    daa
    push AF
    pop HL
    
    ld A, $00
    ld B, $33
    sub B
    daa
    
    halt
