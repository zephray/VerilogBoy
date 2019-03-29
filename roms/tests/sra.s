;; Contains tests for:
;; SRA m
SECTION "rom", ROM0[$0000]

main:
    ; Setup stack
    ld SP, $c040
    
    ld B, $a3
    sra B
    push AF
    pop HL
    ld C, L
    
    ld D, B
    sra D
    push AF
    pop HL
    ld E, L
    
    ld H, D
    sra H
    
    halt
