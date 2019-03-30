;; Contains tests for:
;; LD SP, HL
;; LDHL SP, e
;; LD [nn], SP
SECTION "rom", ROM0[$0000]

main:
    ld hl, SP-128
    ld SP, HL
    ld [$c010], SP
    ld A, [$c010]
    ld C, A
    ld A, [$c011]
    ld B, A
    
    ld hl, SP+127
    ld D, H
    ld E, L
    inc hl
    ld SP, HL
    ld hl, SP+127
    halt
