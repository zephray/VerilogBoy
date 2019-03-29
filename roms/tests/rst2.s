;; Contains tests for:
;; RST
SECTION "rom", ROM0[$0000]

Addr_00:
    jr nz, code_area
    add $01
    ret
    nop
    nop
    nop
    
Addr_08:
    add $02
    ret
    nop
    nop
    nop
    nop
    nop

Addr_10:
    add $04
    ret
    nop
    nop
    nop
    nop
    nop
    
Addr_18:
    add $08
    ret
    nop
    nop
    nop
    nop
    nop
   
Addr_20:
    add $10
    ret
    nop
    nop
    nop
    nop
    nop
    
Addr_28:
    add $20
    ret
    nop
    nop
    nop
    nop
    nop
    
Addr_30:
    add $40
    ret
    nop
    nop
    nop
    nop
    nop
    
Addr_38:
    add $80
    ret
    nop
    nop
    nop
    nop
    nop
    
code_area:
rst00:
    add A, $00
    ld HL, $c030
    ld SP, HL
    rst $00
rst08:
    rst $08
rst10:
    rst $10
rst18:
    rst $18
rst20:
    rst $20
rst28:
    rst $28
rst30:
    rst $30
rst38:
    rst $38
end:
    halt
