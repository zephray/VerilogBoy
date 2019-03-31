;; Tests for the following:
;; ADD HL, SP
;;

SECTION "rom", ROM0[$0000]
main:
    ; Attempt to set carry, half-carry, but not zero
    ld a, $80
    ld b, $01
    sub b
    ld SP, $0001
    ld HL, $ffff
    add HL, SP
    ld SP, $c040
    push AF
    pop BC
    ld D, H
    ld E, L
    
    ; it should not clear zero flag
    ld a, $00
    or a, $00
    ld hl, $000c
    ld sp, $1204
    add hl, sp
    
    halt
