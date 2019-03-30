;; Contains tests for:
;; CP

SECTION "rom", ROM0[$0000]
main:
    ; Setup SP
    ld SP, $c040

    ld A, $00
    ld B, $0f

    CP B
    push AF
    pop BC

    ld E, $00
    CP E
    push AF
    pop DE

    ld A, $fe
    ld L, $e0
    CP L
    push AF
    pop HL

    CP H

    halt
