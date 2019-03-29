;; Contains tests for:
;; LD r, [HL]
;; LD [HL], r
;; LD [HL], n
;; LD A, [nn]
;; LD [nn], A
;;
SECTION "rom", ROM0[$0000]

main:
    ld B, $01
    ld HL, $C010
    ld [HL], B
    ld C, [HL]
    
    inc HL
    ld [HL], $02
    ld D, [HL]
    
    ld A, $05
    ld [$C012], A
    xor A
    ld A, [$C012]
    halt
