;; func_test.s
;; Tests the conditional call and return function
SECTION "rom", ROM0[$0000]

main:
    ld BC, $1122
    ld DE, $f0f0
    ld HL, $5566
    ld SP, $c010
    xor a ; Z flag set
    call z, func_should
    xor a ; Z flag set 
    call nz, func_never
    call c, func_never
    sub a, $1
    call nc, func_never
    halt

func_never:
    ld DE, $3344
    ret
    
func_should:
	ld DE, $7788
	ld a, $ff
	add a, $02 ; C-flag should be set, but not Z
	ret z ; should not return
	ld HL, $2211
	ret nc ; should not return
	ld BC, $3344
	ret c ; should return
	ld BC, $DEAD
	ret
