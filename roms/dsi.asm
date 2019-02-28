SECTION "dsi", ROM0

REG_DSIC_CTL   EQU $10
REG_DSIC_TICK  EQU $11
REG_DSIC_TXDR  EQU $12
REG_DSIC_H1    EQU $13
REG_DSIC_H2    EQU $14
REG_DSIC_H3L   EQU $15
REG_DSIC_H3H   EQU $16
REG_DSIC_H4    EQU $17
REG_DSIC_V1    EQU $18
REG_DSIC_V2    EQU $19
REG_DSIC_V3L   EQU $1A
REG_DSIC_V3H   EQU $1B
REG_DSIC_V4L   EQU $1C
REG_DSIC_V4H   EQU $1D

VAL_DSIC_CTL_NORM EQU $40
VAL_DSIC_CTL_LPR  EQU $42
VAL_DSIC_CTL_RST  EQU $40
VAL_DSIC_CTL_HSC  EQU $41
VAL_DSIC_CTL_TIM  EQU $51

; name: dsi_parity
; description:
;   Calculate parity of a byte
; parameter:
;   B: original number
; return:
;   A: result
; caller saved:
;   A, B
byte_parity:
    ld b, a
    rra
    rra
    rra
    rra
    xor a, b
    ld b, a
    rra
    rra
    xor a, b
    ld b, a
    rra
    xor a, b
    ld b, $01
    and a, b
    ret

; name: reverse bits
; description:
;   simply reverse the bits of a byte
; parameter:
;   A: original byte
; return:
;   A: result
; caller saved:
;   H, L
reverse_bits:
    ld h, 8
    ld l,a
reverse_bits__loop:
    rl l
    rra
    dec h
    jr nz, reverse_bits__loop
    ret

; name: dsi_ecc
; description:
;   calculate DSI packet header ECC checksum
; parameter:
;   B: first byte
;   C: second byte
;   D: third byte
; return:
;   A: forth byte (ECC byte)
; caller saved:
;   A, E, H, L
dsi_ecc__lut:
    ; ECC LUT
    db $ef, $fc, $00
    db $df, $03, $f0
    db $b8, $e3, $8e
    db $74, $9a, $6d
    db $f2, $55, $5b
    db $f1, $2c, $b7

dsi_ecc:
    ld hl, dsi_ecc__lut
    ld e, 6
    ld a, 0
    ccf
dsi_ecc__loop:
    ; save the iterator and arguments
    push bc
    push de
    ; save the result of last round
    push af
    ; load the lut and calculate this round
    ld a, [hl+]
    and a, b
    call byte_parity
    ld e, a
    ld a, [hl+]
    and a, c
    call byte_parity
    xor a, e
    ld e, a
    ld a, [hl+]
    and a, d
    call byte_parity
    xor a, e
    ; now a have the result of this round
    ld e, a
    ; fetch last round result and shift left
    pop af
    sla a
    ; combine the result from this round
    or a, e
    ; restor the iterator and arguments
    pop de
    pop bc
    dec e
    jr nz, dsi_ecc__loop
    ; finished
    ret

; name: dsi_ecc
; description:
;   transmit a command (1-n parameters) over DSI LP channel
; parameter:
;   [HL]: number of params
;   [HL+1]: 1st param
;   ...
; return:
;   none
; caller saved:
;   A, B, C, D, E, H, L
dsi_lp_write_cmd:
    ld a, VAL_DSIC_CTL_LPR
    ldh [$ff00+REG_DSIC_CTL], a
    ld a, $e1 ; beginning of LP transmission
    ldh [$ff00+REG_DSIC_TXDR], a
    ld b, [hl] ; load number of parameters
    dec b
    jr z, dsi_lp_write_cmd__1p
    dec b
    jr z, dsi_lp_write_cmd__2p
dsi_lp_write_cmd__np:
    ld a, $9c  ; DCS long packet, reversed '39'
    ld d, $39  ; save for ECC calculation
    ldh [$ff00+REG_DSIC_TXDR], a ; ptype
    ld a, [hl+] ; packet length
    ld c, a    ; save for ECC calculation
    push hl
    call reverse_bits
    ldh [$ff00+REG_DSIC_TXDR], a ; length
    ld a, $00 
    ld b, a
    ldh [$ff00+REG_DSIC_TXDR], a ; 0
    call dsi_ecc
    call reverse_bits
    ldh [$ff00+REG_DSIC_TXDR], a ; ecc
    pop hl
dsi_lp_write_cmd__long_packet_loop:
    ld a, [hl+]
    push hl
    call reverse_bits
    pop hl
    ldh [$ff00+REG_DSIC_TXDR], a 
    dec c
    jr nz, dsi_lp_write_cmd__long_packet_loop
    ld a, $00
    ldh [$ff00+REG_DSIC_TXDR], a ; The screen ignore CRC
    nop 
    nop 
    ldh [$ff00+REG_DSIC_TXDR], a ; The screen ignore CRC
    ld a, VAL_DSIC_CTL_NORM
    ldh [$ff00+REG_DSIC_CTL], a
    ret
dsi_lp_write_cmd__1p:
    ld a, $a0   ; DCS command write 05
    ld d, $05   ; save for ECC calculation
    ldh [$ff00+REG_DSIC_TXDR], a ; ptype
    inc hl      ; skip the number
    ld a, [hl+] ; first param
    ld c, a     ; save for ECC calculation
    push hl
    call reverse_bits
    ldh [$ff00+REG_DSIC_TXDR], a
    ld a, $00   ; zero for second param
    ld b, a
    ldh [$ff00+REG_DSIC_TXDR], a
    jr dsi_lp_write_cmd__finish
dsi_lp_write_cmd__2p:
    ld a, $a8   ; DCS command write 15
    ld d, $15   ; save for ECC calculation
    ldh [$ff00+REG_DSIC_TXDR], a ; ptype
    inc hl      ; skip the number
    ld a, [hl+] ; first param
    ld c, a     ; save for ECC calculation
    push hl
    call reverse_bits
    ldh [$ff00+REG_DSIC_TXDR], a
    pop hl
    ld a, [hl+] ; second param
    ld b, a
    push hl
    call reverse_bits
    ldh [$ff00+REG_DSIC_TXDR], a
dsi_lp_write_cmd__finish:
    call dsi_ecc
    call reverse_bits
    ldh [$ff00+REG_DSIC_TXDR], a ; ecc
    pop hl
    ld a, VAL_DSIC_CTL_NORM
    ldh [$ff00+REG_DSIC_CTL], a
    ret

lcd_init_sequence:
    ; Memory data access control: Reverse X, BGR
    db $02, $36, $48
    ; Interface pixel format: 16.7M Color
    db $02, $3a, $77
    ; Interface pixel format: 64K Color
    ;db $02, $3a, $55
    ; Command Set Control: Enable Command 2 Part I
    db $02, $f0, $c3
    ; Command Set Control: Enable Command 2 Part II
    db $02, $f0, $96
    ; Frame Rate Control
    db $03, $b1, $a0, $10
    ; Display Inversion Control: 00: Column INV, 01: 1-Dot INV, 10: 2-Dot INV
    db $02, $b4, $00
    ; Blacking Porch Control
    db $05, $b5, $40, $40, $00, $04
    ; Display Function Control
    db $04, $b6, $8a, $07, $27
    ; There is no B9 in datasheet
    db $02, $b9, $02
    ; VCOM Control: 1.450V
    db $02, $c5, $2e
    ; Display Output
    db $09, $e8, $40, $8a, $00, $00, $29, $19, $a5, $93
    ; Positive Gamma Control
    db $0f, $e0, $f0, $07, $0e, $0a, $08, $25, $38, $43, $51, $38, $14, $12, $32, $3f
    ; Negative Gamma Control
    db $0f, $e1, $f0, $08, $0d, $09, $09, $26, $39, $45, $52, $07, $13, $16, $32, $3f
    ; Command Set Control: Disable Command 2 Part I
    db $02, $f0, $3c
    ; Command Set Control: Disable Command 2 Part II
    db $02, $f0, $69
    ; Sleep Out
    db $01, $11
    ; Display ON
    db $01, $29
    ; Display Inversion ON
    db $01, $21
    ; Set column address
    ;db $05, $2a, $00, $00, $01, $3f
    ; Set row address
    ;db $05, $2b, $00, $00, $01, $3f
lcd_init_sequence_end:

; name: delay
; caller saved:
;   A, B
delay:
    ld a, $ff
delay__loop_outer:
    ld b, $ff
delay__loop_inner:
    dec b
    jp nz, delay__loop_inner
    dec a
    jp nz, delay__loop_outer
    ret

; name: dsi_init
; description:
;   Initialize the LCD
; parameter:
;   none
; return:
;   none
; caller saved:
;   A, B, C, D, H, L
dsi_init:
    ; Disable the DSI core
    ld a, 0
    ld [$ff00+REG_DSIC_CTL], a
    ; Set LP mode tick = 1
    ld a, 1
    ld [$ff00+REG_DSIC_TICK], a
    ; Reset the LCD
    ld a, VAL_DSIC_CTL_RST
    ld [$ff00+REG_DSIC_CTL], a
    call delay
    ld a, 0
    ld [$ff00+REG_DSIC_CTL], a
    call delay
    ld a, VAL_DSIC_CTL_RST
    ld [$ff00+REG_DSIC_CTL], a
    call delay

    ld hl, lcd_init_sequence
dsi_init__send_loop:
    call dsi_lp_write_cmd
    ld bc, lcd_init_sequence_end
    ld a, b
    cp a, h
    jp nz, dsi_init__send_loop
    ld a, c
    cp a, l
    jp nz, dsi_init__send_loop
    
    ; LCD should be ON at this stage
    ; Setting up Timing Gen
    ; To programming the DSIC:
    ; DSIC_H1 = HS * 3
    ; DSIC_H2 = HFP * 3
    ; DSIC_H3 = HACT * 3
    ; DSIC_H4 = HBP * 3
    ; DSIC_V1 = VS
    ; DSIC_V2 = VS + VBP
    ; DSIC_V3 = VS + VBP + VACT
    ; DSIC_V4 = VS + VBP + VACT + VFP
; 24bpp configuration
    ld a, $1E ; H1 = 10 * 3 = 0x1E
    ld [$ff00+REG_DSIC_H1], a
    ld a, $1E ; H2 = 10 * 3 = 0x1E
    ld [$ff00+REG_DSIC_H2], a
    ld a, $C0 ; H3 = 320 * 3 = 0x03C0
    ld [$ff00+REG_DSIC_H3L], a
    ld a, $03
    ld [$ff00+REG_DSIC_H3H], a
    ld a, $3C ; H4 = 20 * 3 = 0x3C
    ld [$ff00+REG_DSIC_H4], a
    ld a, $08 ; V1 = 8 = 0x08
    ld [$ff00+REG_DSIC_V1], a
    ld a, $10 ; V2 = 8 + 8 = 0x10
    ld [$ff00+REG_DSIC_V2], a
    ld a, $50 ; V3 = 8 + 8 + 320 = 0x150
    ld [$ff00+REG_DSIC_V3L], a
    ld a, $01
    ld [$ff00+REG_DSIC_V3H], a
    ld a, $60 ; V4 = 8 + 8 + 320 + 16 = 0x160
    ld [$ff00+REG_DSIC_V4L], a
    ld a, $01
    ld [$ff00+REG_DSIC_V4H], a

; 16bpp configuration
;    ld a, $14 ; H1 = 10 * 2 = 0x14
;    ld [$ff00+REG_DSIC_H1], a
;    ld a, $14 ; H2 = 10 * 2 = 0x14
;    ld [$ff00+REG_DSIC_H2], a
;    ld a, $80 ; H3 = 320 * 2 = 0x0280
;    ld [$ff00+REG_DSIC_H3L], a
;    ld a, $02
;    ld [$ff00+REG_DSIC_H3H], a
;    ld a, $3C ; H4 = 20 * 2 = 0x28
;    ld [$ff00+REG_DSIC_H4], a
;    ld a, $08 ; V1 = 8 = 0x08
;    ld [$ff00+REG_DSIC_V1], a
;    ld a, $10 ; V2 = 8 + 8 = 0x10
;    ld [$ff00+REG_DSIC_V2], a
;    ld a, $50 ; V3 = 8 + 8 + 320 = 0x150
;    ld [$ff00+REG_DSIC_V3L], a
;    ld a, $01
;    ld [$ff00+REG_DSIC_V3H], a
;    ld a, $60 ; V4 = 8 + 8 + 320 + 16 = 0x160
;    ld [$ff00+REG_DSIC_V4L], a
;    ld a, $01
;    ld [$ff00+REG_DSIC_V4H], a

    ; enable HS clock
    ld a, VAL_DSIC_CTL_HSC
    ld [$ff00+REG_DSIC_CTL], a
    ; Enable DSI HS mode
    ld a, VAL_DSIC_CTL_TIM
    ld [$ff00+REG_DSIC_CTL], a
    ret

export byte_parity
export reverse_bits
export dsi_ecc
export dsi_init