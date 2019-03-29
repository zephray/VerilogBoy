;; Contains tests for:
;; ADD SP, e
SECTION "rom", ROM0[$0000]

main:
    ; Attempt to set Z
    ld SP, $0000
    add SP, 0
    
    ; Stack overflow! Ahahahahahahahahahahahaha! Hahaha... ha ha ha.
    ld SP, $ffff
    add SP, 7
    
    ; Negative immediate
    ld SP, $ffff
    add SP, -99
    
    halt
