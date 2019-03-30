;; Contains tests for:
;; ADD A, [HL]
;; ADD A, n
;;

SECTION "rom", ROM0[$0000]
main:
    ; Setup stack
    ld SP, $c040
    
    ld HL, $c041
    ld [HL], $0f
    ld A, $0e
    add A, [HL]
    push AF
    pop BC
    
    ld A, $10
    add A, $05
    
    halt
