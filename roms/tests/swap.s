SECTION "rom", ROM0[$0000]

main:
    ; Setup stack
    ld SP, $c040

    ld de, $3456

    ld hl, $c000
    ld [hl], $19
    swap [hl]
    ld a, [hl]
    
    ld bc, $0040
    swap c

    sub b ; set N flag
    swap b ; should clear the flag, set Z

    halt
