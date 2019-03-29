;; Contains tests for:
;; SLA [hl]
SECTION "rom", ROM0[$0000]

main:
    ; Setup stack
    ld SP, $c040
    
    ld HL, $c041
    ld [hl], $aa
    
    SLA [hl]
    push AF
    pop BC
    ld B, [hl]
    
    SLA [hl]
    push AF
    pop DE
    ld D, [hl]
    
    SLA [hl]
    ld A, [hl]
    
    halt
