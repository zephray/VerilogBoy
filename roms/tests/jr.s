;; Contains tests for:
;; jr
SECTION "rom", ROM0[$0000]

jp main
    
useless:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

b1:
    add $01
    jp j2
    halt
    
b2:
    add $02
    jp j3
    halt
    
b3:
    add $04
    jp j4
    halt
    
main:
    jr nz, b1
    halt
j2:
    jr b2
    halt
j3:
    jr b3
    halt
j4:
    jr nz, b4
    halt
j5:
    jr b5
    halt
j6:
    jr z, b6
    halt

b4:
    add $08
    jp j5
    halt
    
b5:
    add $10
    jp j6
    halt
    
b6:
    add $20
    ld C, $42
    halt
    
error_zone:
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    halt
    
