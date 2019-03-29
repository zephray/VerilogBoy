SECTION "rom", ROM0[$0000]

        nop
        nop
        nop
        ld a, $00
        ld	b,$05
        add     b
        ld      b,$03
        add     b
        halt
