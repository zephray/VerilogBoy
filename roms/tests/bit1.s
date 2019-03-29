SECTION "rom", ROM0[$0000]

;; Contains tests for the following:
;; BIT b, r

main:
    ld A, $0f
    bit #3, A
    push AF
    pop BC
    
    ld D, $0f
    bit #6, D
    push AF
    pop DE
    
    ld H, $00
    bit #7, H
    
    halt
