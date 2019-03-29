;; Contains tests for:
;; DAA
SECTION "rom", ROM0[$0000]

main:
    ld A, $89
    ld B, $71
    add B
    daa
    ld C, A
    
    ld A, $89
    ld B, $69
    add B
    daa
    ld D, A
    
    ld A, $89
    ld B, $77
    sub B
    daa
    ld E, A
    
    ld A, $80
    ld B, $15
    sub B
    daa
    ld H, A
    
    ld A, $00
    ld B, $33
    sub B
    daa
    ld L, A
    
    halt
