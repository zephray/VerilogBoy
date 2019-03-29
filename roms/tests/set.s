;; Contains tests for:
;; SET b,r
;; RESET b,r
;;
SECTION "rom", ROM0[$0000]

main:
    ld B, $00
    set #4, B
    
    ld C, $ff
    set #2, C
    
    ld D, $00
    res #5, D
    
    ld E, $ff
    res #1, E
    
    ld HL, $c010
    ld [hl], $0f
    set #7, [hl]
    res #0, [hl]
    ld A, [hl]
    
    halt
