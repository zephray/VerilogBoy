;; Contains tests for:
;; ADD SP, 1

;;.word $0000,$0001,$000F,$0010,$001F,$007F,$0080,$00FF
;;.word $0100,$0F00,$1F00,$1000,$7FFF,$8000,$FFFF

SECTION "rom", ROM0[$0000]
main:
    ld SP, $FFFF
    add SP, $01
    halt
