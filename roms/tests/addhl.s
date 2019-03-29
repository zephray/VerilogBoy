;; Tests for the following:
;; ADD HL, ss
;;

SECTION "rom", ROM0[$0000]
main:
    ; Setup stack
    ld SP, $c040
    
    ; Attempt to set 0 flag, carry, half-carry
    ld BC, $0001
    ld HL, $ffff
    add HL, BC
    ld B, H
    ld C, L
    
    ; Set some random flags
    ld DE, $0e0f
    ld HL, $0613
    add HL, DE
    ld D, H
    ld E, L
    
    ; Add HL to itself because why not
    ld HL, $beef
    add HL, HL
    
    halt
