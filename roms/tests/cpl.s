;; Contains tests for:
;; CPL
;;
;; ZNHC
;;
SECTION "rom", ROM0[$0000]

main:
    ; setup stack
    ld SP, $c040
    
    ; Zero result
    ld A, $ff
    cpl
    push AF
    pop BC
    
    ; Non-zero result
    ld A, $aa
    cpl
    push AF
    pop DE
    
    ; Another non-zero result
    ld A, $66
    cpl

    halt
