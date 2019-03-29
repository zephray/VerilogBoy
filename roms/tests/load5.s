;; Contains tests for the following:
;; LD A, [C]
;; LD [C], A
SECTION "rom", ROM0[$0000]

main:
    ld C, $00
    ld A, $01
    ld [FF00+C], A
    xor A
    ld A, [C]
    ld B, A
    
    ld C, $ff
    ld A, $02
    ld [C], A
    xor A
    ld A, [C]
    ld D, A
    
    halt
