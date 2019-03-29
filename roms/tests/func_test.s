;; func_test.s
;; Tests the CALL, RETURN, PUSH, and POP instructions.
SECTION "rom", ROM0[$0000]

main:
    ld BC, $1122
    ld DE, $f0f0
    ld HL, $5566
    ld SP, $c010
    push BC
    pop HL
    call func
    halt

func:
    ld DE, $3344
    ret
