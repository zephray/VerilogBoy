;; Contains tests for:
;; ADD A, r
;; These tests are functional ALU tests, i.e. they test the ALU more than
;; the microcode. These are result tests.
;;
;; ZNHC

SECTION "rom", ROM0[$0000]
main:
    ld SP, $c040

    ld b, $10
    ld a, $00
    ld [$ff00+$0f], a ; clear all flags
    ld [$ff00+$ff], a ; disable all interrupts   
    call enable_int
    ld a, $20
    halt

enable_int:
    ld c, $10
    ei             ; no interrupt should dispatch here
    nop            ; not here, either
    ld c, $20
    ld a, $04
    ld [$ff00+$0f], a ; set timer interrupt flag
    ld [$ff00+$ff], a ; enable timer interrupt
    ret
    halt ; should not reach here

SECTION "tim", ROM0[$0050]
    ld b, c    
    reti
