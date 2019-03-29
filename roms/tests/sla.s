;; Contains tests for:
;; SLA m
SECTION "rom", ROM0[$0000]

main:
    ; Setup stack
    ld SP, $c040
    
    ld B, $a3
    sla B
    push AF
    pop HL
    ld C, L
    
    ld D, B
    sla D
    push AF
    pop HL
    ld E, L
    
    ld H, D
    sla H
    
    halt
