;; Contains tests for:
;; ADD A, r
;; These tests are functional ALU tests, i.e. they test the ALU more than
;; the microcode. These are result tests.
;;
;; ZNHC

SECTION "rom", ROM0[$0100]
main:
    ; Setup SP
    ld SP, $c040

    ld A, $00
    ld B, $0f
    ld C, $01
    
    ; No flags set
    add B
    push AF
    pop HL
    ld B, H
    
    ; H flag set
    add C
    push AF
    pop HL
    ld C, H
    
    ; C flag set
    ld A, $fe
    ld D, $e0
    add D
    push AF
    pop HL
    ld D, H
    
    ; C, H, Z flag set
    ld A, $fe
    ld E, $02
    add E
    push AF
    pop HL
    ld E, H
    
    ; Z flag set
    ld A, $00
    ld L, $00
    add L
    
    halt
