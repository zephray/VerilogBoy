;; Contains tests for:
;; RLCA
SECTION "rom", ROM0[$0000]

main:
    ; Setup stack
    ld SP, $c040
    
    ld A, $a3
    rlca
    push AF
    pop BC
    
    rlca
    push AF
    pop DE
    
    rlca
    push AF
    pop HL
    
    rlca
    halt
