;; Contains tests for:
;; LD A, [HLI]
;; LD [HLI], A
;; LD A, [HLD]
;; LD [HLD], A
SECTION "rom", ROM0[$0000]

main:
    ld HL, $c010
    ld A, $01
    ld [HLI], A
    ld A, $02
    ld [HL], A
    
    xor A
    
    ld A, [HLD]
    ld B, A
    ld A, [HL]
    ld C, A
    
    ld HL, $c020
    ld A, $04
    ld [HLD], A
    ld A, $03
    ld [HL], A
    
    xor A
    
    ld A, [HLI]
    ld D, A
    ld A, [HLI]
    ld E, A
    halt
