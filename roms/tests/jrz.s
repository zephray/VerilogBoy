;; Contains a test for:
;; jr z
SECTION "rom", ROM0[$0000]

main:
    ld HL, $24D0
    
    ld A, $00
    and A
    
    jp hl
    
    halt

SECTION "stepping", ROM0[$24D0]
    jr z, $2509
    halt

SECTION "final", ROM0[$2509]
    halt
