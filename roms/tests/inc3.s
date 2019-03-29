;; Contains tests for:
;; INC ss
SECTION "rom", ROM0[$0000]

main:
    ld BC, $ff
    inc BC
    
    ld DE, $03
    inc DE
    
    ld HL, $0f
    inc HL
    
    halt
    
