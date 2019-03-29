;; Contains tests for:
;; RR m
SECTION "rom", ROM0[$0000]

main:
    ; Setup stack
    ld SP, $c040
    
    ld B, $a3
    rr B
    push AF
    pop HL
    ld C, L
    
    ld D, B
    rr D
    push AF
    pop HL
    ld E, L
    
    ld H, D
    rr H
    
    halt
