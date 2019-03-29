;; Contains tests for:
;; OR s
;;
;; ZNHC
;;
SECTION "rom", ROM0[$0000]

main:
    ; setup stack
    ld SP, $c040
    
    ; Zero flags result
    ld A, $00
    ld B, $00
    or B
    push AF
    pop BC
    
    ; Non-zero flags result
    ld A, $aa
    ld D, $ef
    or D
    push AF
    pop DE
    
    ; Another non-zero flags result
    ld A, $66
    ld H, $7f
    or H

    halt
