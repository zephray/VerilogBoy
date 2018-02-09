SECTION "rom", ROM0[$0000]

    LD SP, $fffe        ; #0x0000  Setup Stack

    XOR A               ; #0x0003  Zero the memory from #0x8000-#0x9FFF (VRAM)
    LD HL, $9fff        ; #0x0004
Addr_0007:
    LD [HL-], A         ; #0x0007
    BIT 7, H            ; #0x0008
    JR NZ, Addr_0007    ; #0x000a
    
    HALT                ; Stop here for now