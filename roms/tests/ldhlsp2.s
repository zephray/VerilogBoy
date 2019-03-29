;; Contains tests for:
;; ldhl, SP+e
SECTION "rom", ROM0[$0000]

main:
    ld SP, $24D2
    
    ldhl SP, $37
    
    halt
