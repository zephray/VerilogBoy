;; Contains tests for:
;; DEC ss
SECTION "rom", ROM0[$0000]

main:
    ld BC, $00
    dec BC
    
    ld DE, $ff
    dec DE
    
    ld HL, $f0
    dec HL
    
    halt
