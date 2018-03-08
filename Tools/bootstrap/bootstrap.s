SECTION "rom", ROM0[$0000]
    LD SP,$fffe           ; $0000  Setup Stack

    XOR A                 ; $0003  Zero the memory from $8000-$9FFF (VRAM)
    LD HL,$9fff           ; $0004
Addr_0007:
    LD [HL-],A            ; $0007
    BIT 7,H               ; $0008
    JR NZ, Addr_0007      ; $000a

    ;JP Prepare            ; for debug purpose only
    LD HL,$ff26           ; $000c  Setup Audio
    LD C,$11              ; $000f
    LD A,$80              ; $0011 
    LD [HL-],A            ; $0013  All Sound On
    LD [$FF00+C],A        ; $0014  Channel 1 Duty = 50% Length = 0.25s
    INC C                 ; $0015 
    LD A,$f3              ; $0016  
    LD [$FF00+C],A        ; $0018  Channel 1 Vol = 15 Envelope = Dec, 7
    LD [HL-],A            ; $0019  Enable Sound Output to SO1/2
    LD A,$77              ; $001a
    LD [HL],A             ; $001c  SO1/2 Vol 7 Vin Off

    LD A,$fc              ; $001d  Setup BG palette
    LD [$FF00+$47],A      ; $001f  11 11 11 00

    LD DE,$0104           ; $0021  Convert and load logo data from cart into Video RAM
    LD HL,$8010           ; $0024  Target VRAM
Addr_0027:
    LD A,[DE]             ; $0027  Load byte from Logo
    CALL Addr_0095        ; $0028  
    CALL Addr_0096        ; $002b
    INC DE                ; $002e  Next Byte
    LD A,E                ; $002f  
    CP $34                ; $0030  Have we finished the Logo?
    JR NZ, Addr_0027      ; $0032  If not go back to next byte

    LD DE,$00D8           ; $0034  Load (R) icon into Video RAM
    LD B,$08              ; $0037  
Addr_0039:
    LD A,[DE]             ; $0039  Read one byte
    INC DE                ; $003a  Ready for next byte
    LD [HL+],A            ; $003b  Continue on writing
    INC HL                ; $003c  Skip one byte, since we only need BW
    DEC B                 ; $003d  Have we finished the icon?
    JR NZ, Addr_0039      ; $003e  If not go back to next byte

    LD A,$19              ; $0040  Setup background tilemap
    LD [$9910],A          ; $0042  $1910 in VRAM 9th Line 16th tile
    LD HL,$992f           ; $0045  $192f in VRAM 10th Line 15st tile
Addr_0048:
    LD C,$0c              ; $0048  Every line has 12 tiles to fill
Addr_004A:
    DEC A                 ; $004a  A is the tile number
    JR Z, Addr_0055       ; $004b  If we finished all go to $0055
    LD [HL-],A            ; $004d  Filling the 10th Line
    DEC C                 ; $004e  Have we finished the line?
    JR NZ, Addr_004A      ; $004f  If not, continue this line
    LD L,$0f              ; $0051  If yes, go to the end of previous line
    JR Addr_0048          ; $0053  Start next line

    ; === Scroll logo on screen, and play logo sound===

Addr_0055:
    LD H,A                ; $0055  Initialize scroll count, H=0
    LD A,$64              ; $0056
    LD D,A                ; $0058  set loop count, D=$64
    LD [$FF00+$42],A      ; $0059  Set vertical scroll register
    LD A,$91              ; $005b
    LD [$FF00+$40],A      ; $005d  Turn on LCD, showing Background
    INC B                 ; $005f  Set B=1
Addr_0060:
    LD E,$02              ; $0060
Addr_0062:
    LD C,$0c              ; $0062
Addr_0064:
    LD A,[$FF00+$44]      ; $0064  wait for screen frame
    CP $90                ; $0066  Are we at Line 144? (Start of VBlank)
    JR NZ, Addr_0064      ; $0068  If not, wait
    DEC C                 ; $006a  Just some delay loop
    JR NZ, Addr_0064      ; $006b
    DEC E                 ; $006d  Another delay loop
    JR NZ, Addr_0062      ; $006e

    LD C,$13              ; $0070  Sound register address, will be used later
    INC H                 ; $0072  increment scroll count
    LD A,H                ; $0073  
    LD E,$83              ; $0074  Prepare sound $83
    CP $62                ; $0076  $62 counts in, play sound #1
    JR Z, Addr_0080       ; $0078
    LD E,$c1              ; $007a  Prepare sound $C1
    CP $64                ; $007c  $64 counts in, play sound #2
    JR NZ, Addr_0086      ; $007e  If no sounds is needed, goto $0086
Addr_0080:
    LD A,E                ; $0080  play sound
    LD [$FF00+C],A        ; $0081  Set channel 1 Freq Lo
    INC C                 ; $0082
    LD A,$87              ; $0083  
    LD [$FF00+C],A        ; $0085  Set channel 1 Freq hi to $87
Addr_0086:
    LD A,[$FF00+$42]      ; $0086  Read current LYC
    SUB B                 ; $0088
    LD [$FF00+$42],A      ; $0089  scroll logo up if B=1
    DEC D                 ; $008b  
    JR NZ, Addr_0060      ; $008c

    DEC B                 ; $008e  set B=0 first time
    JR NZ, Addr_00E0      ; $008f    ... next time, cause jump to "Nintendo Logo check"

    LD D,$20              ; $0091  use scrolling loop to pause
    JR Addr_0060          ; $0093

    ; ==== Graphic routine ====

Addr_0095:
    LD C,A                ; $0095  "Double up" all the bits of the graphics data
Addr_0096:
    LD B,$04              ; $0096  and store in Video RAM
Addr_0098:
    PUSH BC               ; $0098  
    RL C                  ; $0099
    RLA                   ; $009b
    POP BC                ; $009c
    RL C                  ; $009d
    RLA                   ; $009f
    DEC B                 ; $00a0
    JR NZ, Addr_0098      ; $00a1
    LD [HL+],A            ; $00a3
    INC HL                ; $00a4
    LD [HL+],A            ; $00a5
    INC HL                ; $00a6
    RET                   ; $00a7

Addr_00A8:
    ;Nintendo Logo
    DB $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D 
    DB $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99 
    DB $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E 

Addr_00D8:
    ;More video data
    DB $3C,$42,$B9,$A5,$B9,$A5,$42,$3C

    ; ===== Nintendo logo comparison routine =====

Addr_00E0:    
    LD HL,$0104             ; $00e0    ; point HL to Nintendo logo in cart
    LD DE,$00a8             ; $00e3    ; point DE to Nintendo logo in DMG rom

Addr_00E6:
    LD A,[DE]               ; $00e6
    INC DE                  ; $00e7
    CP [HL]                 ; $00e8    ;compare logo data in cart to DMG rom
    ;JR NZ, $FE             ; $00e9    ;if not a match, lock up here
    DB $20, $FE             ; $00e9    ; Original code won't pass assembler
    INC HL                  ; $00eb
    LD A,L                  ; $00ec
    CP $34                  ; $00ed    ;do this for $30 bytes
    JR NZ, Addr_00E6        ; $00ef

    LD B,$19                ; $00f1
    LD A,B                  ; $00f3
Addr_00F4:
    ADD [HL]                ; $00f4
    INC HL                  ; $00f5
    DEC B                   ; $00f6
    JR NZ, Addr_00F4        ; $00f7
    ADD [HL]                ; $00f9
    ;JR NZ, $FE             ; $00fa    ; if $19 + bytes from $0134-$014D  don't add to $00
    DB $20, $FE             ; $00fa
                            ;  ... lock up

    LD A,$01                ; $00fc
Addr_00FE:
    LD [$FF00+$50],A        ; $00fe    ;turn off DMG rom

; These codes are NOT parts of boot ROM
Addr_0100:
    JP Prepare
    DB $00

Addr_0104:
    DB $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
    DB $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
    DB $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E
    
    DB "TESTROM",0,0,0,0,0,0,0,0 ; Cart name - 15bytes
    DB 0                         ; $143
    DB 0,0                       ; $144 - Licensee code (not important)
    DB 0                         ; $146 - SGB Support indicator
    DB 1                         ; $147 - Cart type
    DB 2                         ; $148 - ROM Size
    DB 3                         ; $149 - RAM Size
    DB 1                         ; $14a - Destination code
    DB $33                       ; $14b - Old licensee code
    DB 0                         ; $14c - Mask ROM version
    DB $7F                       ; $14d - Complement check (important)
    DW 0                         ; $14e - Checksum (not important)

Prepare:
    LD A,$00            
    LD [$FF00+$13],A           
    LD [$FF00+$14],A             
    LD [$FF00+$40],A
    LD HL, $FE9F
    LD A, $00
OAMClear:
    LD [HL-], A
    BIT 0, H
    JR Z, OAMClear
    ; Write a black tile
    LD HL, $81BF
    LD A, $FF
OAMWRLoop:
    LD [HL-], A
    BIT 5, L
    JR NZ, OAMWRLoop
    ; Enable objects
    LD HL, $FE00
    ; Object 0
    LD A, $90
    LD [HL+], A
    LD A, $48
    LD [HL+], A
    LD A, $1A
    LD [HL+], A
    LD A, $80
    LD [HL+], A
    ; Object 1
    LD A, $98
    LD [HL+], A
    LD A, $48
    LD [HL+], A
    LD A, $1A
    LD [HL+], A
    LD A, $80
    LD [HL+], A
    ; Object 2
    LD A, $98
    LD [HL+], A
    LD A, $50
    LD [HL+], A
    LD A, $1A
    LD [HL+], A
    LD A, $80
    LD [HL+], A
    ; Object 3
    LD A, $98
    LD [HL+], A
    LD A, $58
    LD [HL+], A
    LD A, $1A
    LD [HL+], A
    LD A, $80
    LD [HL+], A
    ; Setup palette
    LD A, $FC
    LD [$FF00+$47],A
    LD [$FF00+$48],A
    LD [$FF00+$49],A
    ; Enable LCD
    LD A, $93
    LD [$FF00+$40],A
    HALT
    