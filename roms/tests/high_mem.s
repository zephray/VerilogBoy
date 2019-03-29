;; Contains a test for high memory access
;;
SECTION "rom", ROM0[$0000]

main:
    ld a, $09
    ldh [$ff00+$80], a
    xor a
    ld a, [$ff00+$80]
    halt
