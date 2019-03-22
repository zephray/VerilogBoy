; Interrupt Vectors
SECTION "vblank", ROM0[$0040]
	reti
SECTION "lcdc",   ROM0[$0048]
	reti
SECTION "timer",  ROM0[$0050]
	reti
SECTION "serial", ROM0[$0058]
	reti
SECTION "joypad", ROM0[$0060]
	reti


SECTION "rom", ROM0[$0000]
    ld sp, $fffe
    call dsi_init
    nop
end:
    jr end
    halt

; just for BGB debug
SECTION "boot", ROM0[$0100]
    nop
    jp $0000

    ; ROM header
    ; This is not supposed to be load as a normal ROM
    ; but just to help debugging in the emulator
    ; (otherwise code would be placed here and emulator)
    ; (doesn't want to disassemble this)
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

    DB "VERILOGBOYBROM",0        ; Cart name - 15bytes
    DB 0                         ; $143
    DB 0,0                       ; $144 - Licensee code (not important)
    DB 0                         ; $146 - SGB Support indicator
    DB 0                         ; $147 - Cart type
    DB 0                         ; $148 - ROM Size
    DB 0                         ; $149 - RAM Size
    DB 1                         ; $14a - Destination code
    DB $33                       ; $14b - Old licensee code
    DB 0                         ; $14c - Mask ROM version
    DB 0                         ; $14d - Complement check (important)
    DW 0                         ; $14e - Checksum (not important)