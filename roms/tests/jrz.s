;; Contains a test for:
;; jr z
SECTION "rom", ROM0[$0000]

main:
    ;;24D0: 28 37          jr z, 2509
    ld HL, $24D0
    ld A, $28
    ld [HL+], A
    ld A, $37
    ld [HL+], A
    ld A, $76
    ld [hl], A
    
    ld HL, $2509
    ld [hl], $76
    
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
