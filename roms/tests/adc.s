;; Contains tests for:
;; ADC A, r
;; These tests are functional ALU tests, i.e. they test the ALU more than
;; the microcode. These are flags tests.
;;
;; ZNHC

SECTION "rom", ROM0[$0000]
main:
    ; Setup SP
    ld SP, $c040

    ld A, $00
    ld B, $0f
    ld C, $01
    
    ; No flags set
    adc B
    push AF
    pop HL
    ld B, L
    
    ; H flag set
    adc C
    push AF
    pop HL
    ld C, L
    
    ; C flag set
    ld A, $fe
    ld D, $e0
    adc D
    push AF
    pop HL
    ld D, L
    
    ; C, H, Z flag set
    ld A, $fe
    ld E, $02
    adc E
    push AF
    pop HL
    ld E, L
    
    ; Z flag set
    ld A, $00
    ld H, $00
    adc H
    
    halt
