.segment "EXEHDR"
    .word next_line
    .word 10
    .byte $9e
    .asciiz "2064"    ; SYS 2064
next_line:
    .word 0

.segment "ZEROPAGE"
spriteX: .res 1
spriteY: .res 1

.segment "CODE"
.export _start

_start:
    sei                   ; Disable interrupts during setup

    ; clear screen
    ldx #$00
clear_loop:
    lda #$20
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $06E8,x
    inx
    bne clear_loop

    ; Set background and border color (blue)
    lda #$06
    sta $d020
    sta $d021

    ; Copy sprite data to $2000 for VIC-II
    ldx #0
copy_sprite_loop:
    lda smiley,x
    sta $2000,x
    inx
    cpx #63
    bcc copy_sprite_loop

    ; Enable sprite 0
    lda #$01
    sta $d015

    ; Set sprite 0 X/Y position
    lda #200
    sta $d000
    lda #150
    sta $d001

    ; Set sprite color (yellow)
    lda #$0e
    sta $d027

    ; Set sprite pointer in $07F8 (sprite 0)
    lda #$80
    sta $07f8

    cli                   ; Re-enable interrupts
; Set up screen and color memory base addresses
SCREEN        = $0400      ; C64 default screen RAM
COLOR_RAM     = $D800      ; C64 color RAM

CHAR_DIRT     = $C5        ; PETSCII code for '-'
CHAR_VEG      = $D8        ; PETSCII code for '*'
COLOR_BROWN   = $09        ; Brown (C64 color code)
COLOR_GREEN   = $05        ; Green (C64 color code)

        ldx #0

; Fill last row (row 24) with DIRT ('-')
        ldy #0
@dirt_loop:
        lda #CHAR_DIRT
        sta SCREEN + 24*40,y
        lda #COLOR_BROWN
        sta COLOR_RAM + 24*40,y
        iny
        cpy #40
        bne @dirt_loop

; Fill row above last (row 23) with VEGETATION ('*')
        ldy #0
@veg_loop:
        lda #CHAR_VEG
        sta SCREEN + 23*40,y
        lda #COLOR_GREEN
        sta COLOR_RAM + 23*40,y
        iny
        cpy #40
        bne @veg_loop

        jmp loop
loop:
    jmp loop

.segment "SPRITEDATA"
smiley:
.include "sprites/sprite1_frame1.inc"
