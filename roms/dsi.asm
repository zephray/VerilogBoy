SECTION "dsi", ROM0

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
; description
;   simply reverse the bits of a byte
; parameter:
;   B: original byte
; return:
;   A: result
; caller saved:
;   ?
reverse_bits:
    ld b,8
    ld l,a
reverse_loop:
    rl l
    rra
    dec b
    jr nz, reverse_loop
    halt
    ;ret

export byte_parity
export reverse_bits