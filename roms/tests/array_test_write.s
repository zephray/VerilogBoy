SECTION "rom", ROM0[$0000]

jp code_area
my_array:
    ; Starts at 0x0003
    nop                 ; 00            03
    ld BC, $0302        ; 01, 02, 03    04
    inc b               ; 04            07
    dec b               ; 05            08
    ld b, $07           ; 06, 07        09
    ld [$0a09], SP      ; 08, 09, 0a    0b
    dec BC              ; 0b            0e
    inc C               ; 0c            0f
    dec C               ; 0d            10
    ld C, $0f           ; 0e, 0f        11
    rst $38             ; ff            13
    stop                ; 10, 00        14
    jr NZ, $30          ; 20, 30        16
    ld B, B             ; 40            18
    ld D, B             ; 50            19
    ld H, B             ; 60            1a
    ld [hl], B          ; 70            1b
    add A, B            ; 80            1c
    sub B               ; 90            1d
    and B               ; a0            1e
    or B                ; b0            1f
    ret NZ              ; c0            20
    ret NC              ; d0            21
    ldh [$00f0], A      ; e0, f0, 00    22
    ; Last element at 0x0024
    
code_area:
    ld L, $04
    ld H, $00
    ld B, [hl]
    inc HL
    ld C, [hl]
    inc HL
    ld D, [hl]
    inc HL
    ld E, [hl]
    ld L, $00
    ld H, $C0
    ld [hl], B
    dec HL
    ld [hl], C
    dec HL
    ld [hl], D
    dec HL
    ld [hl], E
    ld B, [hl]
    inc HL
    ld C, [hl]
    inc HL
    ld D, [hl]
    inc HL
    ld E, [hl]
    halt
    
