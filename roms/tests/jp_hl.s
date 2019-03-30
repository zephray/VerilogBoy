;; Contains tests for the following:
;; jp hl
SECTION "rom", ROM0[$0000]

main:
    ld HL, $0007 ; jump1
    jp hl
    
    ld B, $01
    halt
    
jump1:
    ld HL, $000E ; jump2
    jp hl
    
    ld C, $02
    halt
    
jump2:
    ld D, $03
    halt
