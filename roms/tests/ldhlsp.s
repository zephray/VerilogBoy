;; Contains tests for:
;; LD HL, SP+e
SECTION "rom", ROM0[$0000]

main:
    ld SP, $dfe2
    ldhl SP, #14
    ld b, h
    ld c, l
    push af
    pop de
    
    ld SP, $0100
    ldhl SP, #-7

    halt
