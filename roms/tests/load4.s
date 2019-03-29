;; Contains tests for:
;; LD SP, HL
;; LDHL SP, e
;; LD [nn], SP
SECTION "rom", ROM0[$0000]

main:
    ldhl SP, -128
    ld SP, HL
    ld [$c010], SP
    ld A, [$c010]
    ld C, A
    ld A, [$c011]
    ld B, A
    
    ldhl SP, 127
    ld D, H
    ld E, L
    inc hl
    ld SP, HL
    ldhl SP, 127
    halt
