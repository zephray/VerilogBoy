;; Contains tests for:
;; LD A, [n]
;; LD [n], A
SECTION "rom", ROM0[$0000]

main:
    ld A, $01
    ldh [$15], A
    xor A
    ldh A, [$15]
    ld D, A
    
    ld A, $02
    ldh [$f0], A
    xor A
    ldh A, [$f0]
    ld E, A
    
    halt
