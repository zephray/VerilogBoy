;; Contains tests for:
;; INC [hl]
;;
;; ZNHC
SECTION "rom", ROM0[$0000]

main:
    ; Setup SP
    ld SP, $c040
    
    ; No flags set
    ld A, $0e
    ld HL, $c060
    ld [hl], A
    inc [hl]
    ld A, [hl]
    push AF
    pop BC
    
    ; H flag set
    ld A, $0f
    ld HL, $c061
    ld [hl], A
    inc [hl]
    ld A, [hl]
    push AF
    pop DE
    
    ; Z flag set, No Carry, Clear N flag
    ld A, $ff
    sub a, $00
    ld HL, $c062
    ld [hl], A
    inc [hl]
    ld A, [hl]
    push AF
    pop HL
    
    halt
