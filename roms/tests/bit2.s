;; Contains tests for the following:
;; BIT b, [hl]
SECTION "rom", ROM0[$0000]

main:
    ld HL, $c040
    ld [hl], $ff
    bit #5, [hl]
    push AF
    pop BC
    
    ld HL, $c041
    ld [hl], $f0
    bit #3, [hl]
    push AF
    pop DE
    
    ld HL, $c042
    ld [hl], $fe
    bit #0, [hl]
    
    halt
