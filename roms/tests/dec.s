;; Contains tests for:
;; DEC r
;; These tests are functional ALU tests, i.e. they test the ALU more than
;; the microcode.
;;
;; ZNHC
SECTION "rom", ROM0[$0000]

main:
    ; Setup SP
    ld SP, $c040
    
    ; No flags set
    ld A, $0e
    dec A
    push AF
    pop HL
    ld B, H
    ld C, L
    
    ; H flag set
    ld A, $f0
    dec A
    push AF
    pop HL
    ld D, H
    ld E, L
    
    ; Z flag set
    ld A, $01
    dec A
    push AF
    pop HL
    
    halt
