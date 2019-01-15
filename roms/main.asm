SECTION "rom", ROM0[$0000]
    ld b, $d0
    ld a, b
    call reverse_bits
    halt