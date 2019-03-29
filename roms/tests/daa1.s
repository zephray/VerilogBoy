;; Contains tests for the following:
;; DAA
SECTION "rom", ROM0[$0000]

main:
    ld A, $00
    ld B, $00
    add B
    daa
    ld C, A
    
    ld A, $07
    ld B, $13
    add B
    daa
    ld D, A
    
    ld A, $07
    ld B, $09
    add B
    daa
    ld E, A
    
    ld A, $88
    ld B, $10
    add B
    daa
    ld H, A
    
    ld A, $99
    ld B, $01
    add B
    daa
    ld L, A
    
    halt
