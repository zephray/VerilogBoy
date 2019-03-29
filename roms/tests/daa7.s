;; Contains tests for:
;; DAA

;; $00,$01,$0F,$10,$1F,$7F,$80,$F0,$FF,$02,$04,$08,$20,$40
SECTION "rom", ROM0[$0000]

main:
    ld SP, $C040
    
    ld BC, $F0
    push BC
    pop AF
    ld A, $80
    daa
    push AF
    pop DE
    
    ld BC, $F0
    push BC
    pop AF
    ld A, $F0
    daa
    push AF
    pop HL
    
    ld BC, $F0
    push BC
    pop AF
    ld A, $FF
    daa
    
    halt
