;; Contains tests for:
;; xor s
;;
;; ZNHC
;;
SECTION "rom", ROM0[$0000]

main:
    ; setup stack
    ld SP, $c040
    
    ; Zero flags result
    ld A, $e1
    ld B, $e1
    xor B
    push AF
    pop HL
    ld B, H
    ld C, L
    
    ; Non-zero flags result
    ld A, $aa
    ld D, $ef
    xor D
    push AF
    pop HL
    ld D, H
    ld E, L
    
    ; Another non-zero flags result
    ld A, $66
    ld H, $7f
    xor H

    halt
