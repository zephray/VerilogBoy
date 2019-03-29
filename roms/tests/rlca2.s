;; Contains tests for:
;; RLCA

; .byte $00,$01,$0F,$10,$1F,$7F,$80,$F0,$FF
SECTION "rom", ROM0[$0000]

main:
    ; Setup stack
    ld SP, $c040
    
    ld BC, $f0
    push BC
    pop AF
    
    ld A, $00
    rlca
    push AF
    pop BC
    
    ld DE, $f0
    push DE
    pop AF
    
    ld A, $01
    rlca
    push AF
    pop DE
    
    ld HL, $f0
    push HL
    pop AF
    
    ld A, $0f
    rlca
    push AF
    pop HL
    
    rlca
    halt
