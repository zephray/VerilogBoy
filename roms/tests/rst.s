;; Contains tests for:
;; RST
;; JP [hl]
SECTION "rom", ROM0[$0000]

Addr_00:
    jr nz, code_area
    add $01
    ret
    nop
    nop
    nop
    nop
    
Addr_08:
    ld HL, $0010 ; rst10
    jp hl
    ld D, $03
    nop
    nop

Addr_10:
    ret
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    
Addr_18:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
   
Addr_20:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    
Addr_28:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    
Addr_30:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    
Addr_38:
    nop
    nop
    nop
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
end:
    halt
