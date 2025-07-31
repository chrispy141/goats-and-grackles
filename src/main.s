.segment "EXEHDR"
    .word next_line
    .word 10
    .byte $9e
    .asciiz "2064"    ; SYS 2064
next_line:
    .word 0

.segment "ZEROPAGE"
goat_x: .res 1
verticalSpeed_lo: .res 1  ; somewhere in zero page
verticalSpeed_hi: .res 1  ; somewhere in zero page
horzizontalSpeed: .res 1
tmp: .res 1
goat_y_hi: .res 1
goat_y_lo: .res 1


.segment "CODE"
.export _start
goat_sprite_x = $d000
goat_sprite_y = $d001
joystick = $dc00
SPRITE_HIGH_BITS = $d010
GOAT_SPRITE_HIGH_BIT = $1
GRAVITY_HI = $00
GRAVITY_LO = $a0  ; try $01, $02, or $04 for different effects

_start:
    sei                   ; Disable interrupts during setup
    ; initialze variables
    lda #120
    sta goat_x
    sta goat_y_hi
    
;clear screen loop
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

    ; Copy second sprite
    ldx #0
copy_sprite_2_loop:
     
    lda goat_rev,x
    sta $2040,x
    inx
    cpx #63
    bcc copy_sprite_2_loop

    ; Enable sprite 0
    lda #$01
    sta $d015

initialize_sprite:
    ; Set sprite 0 X/Y position
    lda goat_x
    sta goat_sprite_x
    lda goat_y_hi
    sta goat_sprite_y

    ; Set sprite color (yellow)
    lda #$0e
    sta $d027

    ; Set sprite pointer in $07F8 (sprite 0)
;    lda #$80
;    sta $07f8
    jsr forward_goat
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
    lda joystick
    and #%00010000   ; fire button
    beq try_jump     ; if 0, button is pressed

    lda goat_y_hi    ; if the goat isn't on the ground, don't bother left/right
    cmp #220   
    bcc brch_fall 

    lda joystick
    and #%00000100   ; left
    beq brch_move_left

    lda joystick
    and #%00001000   ; right
    beq brch_move_right

    jmp fall
    
brch_move_left:
    jmp move_left    
brch_move_right:
    jmp move_right    
brch_fall:
    jmp fall    
update:
    lda goat_x
    sta goat_sprite_x
 
    lda goat_y_hi
    sta goat_sprite_y

    jsr delay

    jmp main_loop

try_jump:
    ldy goat_y_hi
    cpy #220
    beq can_jump        ; goat_y_hi == 220: jump allowed
    bcc not_on_ground   ; goat_y_hi < 220: not on ground, can't jump
    jmp update

can_jump:
    ; On ground, perform jump!
    lda #$F8              ; -8 in two's complement (tune as needed)
    sta verticalSpeed_hi
    lda #0
    sta verticalSpeed_lo
    lda #219
    sta goat_y_hi
    sta goat_sprite_y
    
    lda joystick
    and #%00000100   ; left
    beq set_hz_spd_left

    lda joystick
    and #%00001000   ; right
    beq set_hz_spd_right
    
    
    jmp fall

set_hz_spd_left:
    jmp fall
set_hz_spd_right:
    jmp fall

not_on_ground:
    jsr experiance_gravity
    jmp fall

move_left:
    ;if in high range
    lda SPRITE_HIGH_BITS ; >= 50 check to see if high bit is set
    and #GOAT_SPRITE_HIGH_BIT
    beq move_left_low_range ; high range not set, jump to low range
    jmp move_left_high_range
move_left_low_range:
    lda goat_x
    cmp #25             ; compare to minimum X boundary (adjust 10 as needed)
    bcc update  ; if less than 10, skip decrement (already at left edge)
    jmp dec_x

move_left_high_range:
    ; check if low range is zero
    lda goat_x
    cmp #$0
    beq transition_to_low_range_x
    ; low range is not zero, decrement and continue
    jmp dec_x

transition_to_low_range_x:
    lda SPRITE_HIGH_BITS
    eor #GOAT_SPRITE_HIGH_BIT
    sta SPRITE_HIGH_BITS
    jmp dec_x
dec_x:
    jsr reverse_goat
    lda goat_x
    sec
    sbc #1
    sta goat_x 
    jmp fall
move_right:
    lda goat_x
    cmp #65  ;check to see if greater than 50
    bcc inc_x ; less than 50, safe to increment in all cases
    lda SPRITE_HIGH_BITS ; >= 50 check to see if high bit is set
    and #GOAT_SPRITE_HIGH_BIT
    beq move_right_low_range  ;high bit was not set, continue low range
    ; high bit is set, and x >= 50, don't do anything, go back to update
    jmp fall
move_right_low_range:
    lda goat_x
    cmp #255 ; see if current x value is 255
    bcc inc_x  ; if x < 255, skip to increment`
    lda SPRITE_HIGH_BITS
    eor #GOAT_SPRITE_HIGH_BIT
    sta SPRITE_HIGH_BITS
    jmp inc_x
    
inc_x:
    jsr forward_goat
    lda goat_x
    clc
    adc #01
    sta goat_x
    jmp fall

experiance_gravity:
    lda goat_y_hi
    cmp #220
    bcs on_ground
    clc

    lda verticalSpeed_lo
    adc #GRAVITY_LO
    sta verticalSpeed_lo

    lda verticalSpeed_hi
    adc #GRAVITY_HI
    sta verticalSpeed_hi
    
    lda verticalSpeed_hi
    bmi not_terminal_veloicty
    cmp #4
    bcc not_terminal_veloicty
    lda #4      ; clamp to terminal velocity
    sta verticalSpeed_hi
not_terminal_veloicty:
    rts

on_ground:
    lda #0
    sta verticalSpeed_hi
    sta verticalSpeed_lo
    lda #220
    sta goat_y_hi
    jmp update

fall:
   jsr experiance_gravity
   ; Add vertical speed to goat's position
   clc
   
   lda goat_y_lo
   adc verticalSpeed_lo
   sta goat_y_lo

   lda goat_y_hi
   adc verticalSpeed_hi
   sta goat_y_hi

   ldy goat_y_hi

  ; jsr debug_print_speed

   jmp update

reverse_goat:
    ; Set sprite pointer in $07F8 (sprite 0)
    lda #$81
    sta $07f8
    rts
forward_goat:
    ; Set sprite pointer in $07F8 (sprite 0)
    lda #$80
    sta $07f8
    rts
delay:
    ldx #$ff
wait1:
    ldy #$0f
wait2:
    dey
    bne wait2
    dex
    bne wait1
    rts

long_delay:
    ldx #$ff
ld_wait1:
    ldy #$8f
ld_wait2:
    dey
    bne ld_wait2
    dex
    bne ld_wait1
    rts 
; .include "debug_print.inc"   
.segment "SPRITEDATA"
goat:
.include "sprites/sprite1_frame1.inc"
goat_rev:
.include "sprites/sprite1_frame2.inc"
