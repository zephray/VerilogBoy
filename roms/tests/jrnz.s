;; Contains a test for:
;; jr nz
SECTION "rom", ROM0[$0000]

main:
    ld b, $12

    ld HL, $2400
    jp hl
    
    halt

SECTION "final", ROM0[$23a0]
    halt

SECTION "stepping", ROM0[$2400]
    dec b
    jr nz, $23a0
    halt

