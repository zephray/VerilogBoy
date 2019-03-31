;; Contains tests for:
;; ADC A, d8

SECTION "rom", ROM0[$0000]
main:
    ; Setup SP
    ld SP, $c040

    ld A, $00
    
    ; No flags set
    adc a, $0f
    push AF
    pop HL
    ld B, L
    
    ; H flag set
    adc a, $01
    push AF
    pop HL
    ld C, L
    
    ; C flag set
    ld A, $fe
    adc a, $e0
    push AF
    pop HL
    ld D, L
    
    ; C, H, Z flag set
    ld A, $fe
    adc a, $02
    push AF
    pop HL
    ld E, L
    
    ; Z flag set
    ld A, $00
    adc a, $00
    
    halt
