SECTION "rom", ROM0[$0000]

    LD SP, $fffe
    LD HL, $C0ff
    LD DE, $0104
    LD A, $03
    XOR A
    LD A, $01
Loop1:
    LD [HL-], A
    BIT 1, L
    JR NZ, Loop1
    
    INC HL
    LD A, [HL+]
    LD B, A
    LD A, [hl]
    LD C, A
    
    halt
    
    ;LD C, $11
    ;LD [$ff00+C], A
    ;LD A, $02
    ;LD [$ff00+$12], A
