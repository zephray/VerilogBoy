SECTION "rom", ROM0[$0000]

        ld l,$8                 ; n
        ld c,$1                 ; count
        ld b,$1                 ; fib_n
        ld d,$1                 ; fib_n_1
        ld e,$0                 ; fib_n_2

loop0:  
        ld a,c                  ; a = c
        cp l                    ; C set if A < l, Z set if A == l
        jp NC, return0          ; if !(A < l), return
        ld a,e                  ; A = fib_n_2
        add a,d                 ; A = fib_n_2 + fib_n_1
        ld b,a                  ; fib_n = A
        ld e,d                  ; fib_n_2 = fib_n_1
        ld d,b                  ; fib_n_1 = fib_n
        inc c                   ; count += 1
        jp loop0                ; end of while loop
return0:
        ld a, b                 ; Put fib_n in A so we can see it on the LCD
        halt
