SECTION "rom", ROM0[$0000]

main:
    ; Setup stack
    ld SP, $c040

    ld b, $00
    ld c, $00
    push bc
    pop af ; clear flags

    scf
    push af
    pop bc

    ccf
    push af
    pop de

    or a, $00 ; set Z flag
    scf ; should not affect Z flag
    push af
    pop hl

    sub a, $80 ; set N flag
    ccf ; should clear N flag
    
    halt
