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
verticalSpeed_lo: .res 1  ; somewhere in zero page
verticalSpeed_hi: .res 1  ; somewhere in zero page
horzizontalSpeed: .res 1
tmp: .res 1
goat_y_hi: .res 1
goat_y_lo: .res 1

goat_x_low: .res 1
goat_x_hi: .res 1

.segment "CODE"
.export _start
goat_sprite_x = $d000
goat_sprite_y = $d001
joystick = $dc00
SPRITE_HIGH_BITS = $d010
GOAT_SPRITE_HIGH_BIT = $1
GRAVITY_HI = $00
GRAVITY_LO = $01  ; try $01, $02, or $04 for different effects

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
    lda goat,x
    sta $2000,x
    inx
    cpx #63
    bcc copy_sprite_loop

    ; Enable sprite 0
    lda #$01
    sta $d015
initialize_sprite:
    ; Set sprite 0 X/Y position
    lda #200
    sta $d000
    lda #200
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

        jmp main_loop

main_loop:
    ldx $d000
    ldy $d001

    lda joystick
    and #%00010000   ; fire button
    beq try_jump     ; if 0, button is pressed

    lda joystick
    and #%00000100   ; left
    beq move_left

    lda joystick
    and #%00001000   ; right

    beq move_right

    jsr experiance_gravity

update:
    jsr fall 
    stx goat_sprite_x
    sty goat_sprite_y

    jsr delay

    jmp main_loop

on_ground:
    sta tmp
    lda #0
    sta verticalSpeed_hi
    sta verticalSpeed_lo
    lda tmp
    jmp update

try_jump:
    ; Only allow jump if Y position is at ground level
    ldy goat_y_hi
    cpy #220
    bcc not_on_ground     ; Not on ground (hi < 220), ignore jump
    cpy #220
    bne not_on_ground     ; Not exactly on ground

    ; On ground, perform jump!
    lda #$F8              ; -8 in two's complement (tune as needed)
    sta verticalSpeed_hi
    lda #0
    sta verticalSpeed_lo
    jmp update

not_on_ground:
    jsr experiance_gravity
    
move_left:
    ;if in high range
    lda SPRITE_HIGH_BITS ; >= 50 check to see if high bit is set
    and #GOAT_SPRITE_HIGH_BIT
    beq move_left_low_range ; high range not set, jump to low range
    jmp move_left_high_range
move_left_low_range:
    cpx #25             ; compare to minimum X boundary (adjust 10 as needed)
    bcc update  ; if less than 10, skip decrement (already at left edge)
    jmp dec_x

move_left_high_range:
    ; check if low range is zero
    cpx #$0
    beq transition_to_low_range_x
    ; low range is not zero, decrement and continue
    jmp dec_x

transition_to_low_range_x:
    lda SPRITE_HIGH_BITS
    eor #GOAT_SPRITE_HIGH_BIT
    sta SPRITE_HIGH_BITS
    jmp dec_x
dec_x:
    dex
    jmp update
move_right:
    cpx #65  ;check to see if greater than 50
    bcc inc_x ; less than 50, safe to increment in all cases
    lda SPRITE_HIGH_BITS ; >= 50 check to see if high bit is set
    and #GOAT_SPRITE_HIGH_BIT
    beq move_right_low_range  ;high bit was not set, continue low range
    ; high bit is set, and x >= 50, don't do anything, go back to update
    jmp update
move_right_low_range:
    cpx #255 ; see if current x value is 255
    bcc inc_x  ; if x < 255, skip to increment`
    lda SPRITE_HIGH_BITS
    eor #GOAT_SPRITE_HIGH_BIT
    sta SPRITE_HIGH_BITS
    jmp inc_x
    
inc_x:
    inx
    jmp update

experiance_gravity:
    cpy #220
    bcs on_ground
    clc

    lda verticalSpeed_lo
    adc #GRAVITY_LO
    sta verticalSpeed_lo

    lda verticalSpeed_hi
    adc #GRAVITY_HI
    sta verticalSpeed_hi

    cmp #4
    bcc :+
    lda #4      ; clamp to terminal velocity
    sta verticalSpeed_hi
:
    rts

fall:
   ; Add vertical speed to goat's position
   clc
   
;   lda goat_y_vlo
;   adc verticalSpeed_vlo
;   sta goat_y_vlo

   lda goat_y_lo
   adc verticalSpeed_lo
   sta goat_y_lo

   lda goat_y_hi
   adc verticalSpeed_hi
   sta goat_y_hi

   ldy goat_y_hi

  ; jsr debug_print_speed

   rts

delay:
    ldx #$ff
wait1:
    ldy #$08
wait2:
    dey
    bne wait2
    dex
    bne wait1
    rts

long_delay:
    ldx #$ff
ld_wait1:
    ldy #$ff
ld_wait2:
    dey
    bne ld_wait2
    dex
    bne ld_wait1
jump:
; To jump, set verticalSpeed to a negative value
   ; lda #$F8       ; -8 in two's complement
   ; sta verticalSpeed_hi
    rts
    
; .include "debug_print.inc"   
.segment "SPRITEDATA"
goat:
.include "sprites/sprite1_frame1.inc"
