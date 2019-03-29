;; Contains tests for:
;; AND s
;;
;; ZNHC
;;

SECTION "rom", ROM0[$0000]
main:
    ; setup stack
    ld SP, $c040
    
    ; Zero flags result
    ld A, $1e
    ld B, $e1
    and B
    push AF
    pop HL
    ld B, H
    ld C, L
    
    ; Non-zero flags result
    ld A, $aa
    ld D, $ef
    and D
    push AF
    pop HL
    ld D, H
    ld E, L
    
    ; Another non-zero flags result
    ld A, $66
    ld H, $7f
    and H

    halt
