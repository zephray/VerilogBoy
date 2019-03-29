;; Contains tests for:
;; DAA

;; $00,$01,$0F,$10,$1F,$7F,$80,$F0,$FF,$02,$04,$08,$20,$40
SECTION "rom", ROM0[$0000]

main:
    ld SP, $C040
    
    ld A, $02
    daa
    push AF
    pop DE
    
    ld A, $04
    daa
    push AF
    pop DE
    
    ld A, $08
    daa
    push AF
    pop HL
    
    ld A, $20
    daa
    
    halt
