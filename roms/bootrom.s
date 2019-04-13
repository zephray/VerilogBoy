SECTION "rom", ROM0[$0000]
    ld sp, $fffe          ; Setup Stack

    xor a                 ; Zero the memory from $8000-$9FFF (VRAM)
    ld hl, $9fff
clear_vram_loop:
    ld [hl-], a
    bit 7, h
    jr nz, clear_vram_loop

    ld a, $00
    ld [$ff00+$42], a     ; Set vertical scroll register
    ld a, $91
    ld [$ff00+$40], a     ; Turn on LCD, showing Background
    ld a, $01
    jp addr_00fe

SECTION "final", ROM0[$00FE]

addr_00fe:
    ld [$ff00+$50], a     ;turn off boot rom
