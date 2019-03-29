;; Contains tests for:
;; ADD SP, e

SECTION "rom", ROM0[$0000]
main:
    ld SP, $00FF
    add SP, $01
    halt
