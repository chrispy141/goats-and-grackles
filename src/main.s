.segment "EXEHDR"
    .word next_line
    .word 10
    .byte $9e
    .asciiz "2064"    ; SYS 2064
next_line:
    .word 0

.segment "ZEROPAGE"
var_goat_x: .res 1
var_vert_speed_lo: .res 1  ; somewhere in zero page
var_vert_speed_hi: .res 1  ; somewhere in zero page
var_float_left: .res 1
var_float_right: .res 1
tmp: .res 1
goat_y_hi: .res 1
goat_y_lo: .res 1
facing_forward: .res 1
.include "tree-zp.s"
.segment "BSS"       ; Or .segment "DATA" if using KickAssembler

.segment "CODE"
.export _start
; ; Constants
PTR_GOAT_SPRITE_X = $d000
PTR_GOAT_SPRITE_Y = $d001
PTR_JOYSTICK = $dc00
SPRITE_HIGH_BITS = $d010
GOAT_SPRITE_HIGH_BIT = $1
GRAVITY_HI = $00
GRAVITY_LO = $a0  ; try $01, $02, or $04 for different effects
VEG_HARDINESS = 64 
ARRAY_VEG_STATE = $1fd8 ; tracks how much each vegitation character has been munched.
COLOR_BLUE = $06
COLOR_BLACK = $00
_start:
    sei                   ; Disable interrupts during setup
    ; initialze variables
    lda #220
    sta goat_y_hi
    lda #0
    sta goat_y_lo
    lda #50
    sta var_goat_x
    
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
    lda #COLOR_BLACK
    sta $d020
    lda #COLOR_BLUE
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

    ; Copy third sprite
    ldx #0
copy_sprite_3_loop:
     
    lda munch,x
    sta $2080,x
    inx
    cpx #63
    bcc copy_sprite_3_loop

    ; Copy fourth sprite
    ldx #0
copy_sprite_4_loop:
     
    lda munch_rev,x
    sta $20C0,x
    inx
    cpx #63
    bcc copy_sprite_4_loop

    ; Enable sprite 0
    lda #$01
    sta $d015

initialize_sprite:

    ; Set sprite color (gray)
    jsr goat_gray

    ; Set sprite pointer in $07F8 (sprite 0)
    jsr forward_goat
    cli                   ; Re-enable interrupts
; Set up screen and color memory base addresses
SCREEN        = $0400      ; C64 default screen RAM
COLOR_RAM     = $D800      ; C64 color RAM

CHAR_DIRT     = $C6        ; PETSCII code for '-'
CHAR_VEG      = $41        ; PETSCII code for 'spade'
CHAR_VEG_MCHD = $58        ; PETSCII code for 'spade with hole'
COLOR_BROWN   = $09        ; Brown (C64 color code)
COLOR_GREEN   = $05        ; Green (C64 color code)


    ldx #0
initialize_vegitation:
    lda #VEG_HARDINESS
    sta ARRAY_VEG_STATE,x
    inx
    cpx #40
    bne initialize_vegitation

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

; Fill row above last (row 23) with VEGETATION 
    jsr draw_vegetation

draw_tree:
    jsr DrawPoints

arrival:
    lda #0
    sta var_goat_x
    sta PTR_GOAT_SPRITE_X
    lda #220
    sta goat_y_hi
    sta PTR_GOAT_SPRITE_Y
    lda #0
    sta goat_y_lo
    ldx #0
    lda #1
    sta facing_forward
    jsr delay
arrival_loop:
    lda var_goat_x 
    clc
    adc #01 
    sta var_goat_x
    sta PTR_GOAT_SPRITE_X
    txa         ; Transfer X to A
    pha         ; Push A onto stack
    jsr delay   
    pla         ; Pull from stack back to A
    tax         ; Transfer A back to X 
    inx
    cpx #50
    bne arrival_loop

main_loop:
    jsr draw_vegetation
    lda PTR_JOYSTICK
    and #%00010000   ; fire button
    beq try_jump     ; if 0, button is pressed

    lda goat_y_hi    ; if the goat isn't on the ground, don't bother left/right
    cmp #220   
    bcc brch_fall 

    lda PTR_JOYSTICK
    and #%00000100   ; left
    beq brch_move_left

    lda PTR_JOYSTICK
    and #%00001000   ; right
    beq brch_move_right
    
    lda PTR_JOYSTICK
    and #%00000010   ; down
    beq brch_munch

    ; reset forward/backwards goat
    lda facing_forward
    cmp #1
    beq brc_forward_goat
    jmp brc_reverse_goat

    
brch_move_left:
    jmp move_left    
brch_move_right:
    jmp move_right    
brch_fall:
    jmp apply_horz_movement
brch_munch:
    ; determine if facing left or right
    lda facing_forward 
    ; if right, jump to munch right
    cmp #1
    beq br_munch_right
    ; if left, jump to munch left 
    jmp munch_left
br_munch_right:
    jmp munch_right
    
brc_forward_goat:
    jsr forward_goat
    jmp fall

brc_reverse_goat:
    jsr reverse_goat
    jmp fall

update:
    lda var_goat_x
    sta PTR_GOAT_SPRITE_X
 
    lda goat_y_hi
    sta PTR_GOAT_SPRITE_Y
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
    sta var_vert_speed_hi
    lda #0
    sta var_vert_speed_lo
    lda #219
    sta goat_y_hi
    sta PTR_GOAT_SPRITE_Y
    
    lda PTR_JOYSTICK
    and #%00000100   ; left
    beq set_hz_var_float_left

    lda PTR_JOYSTICK
    and #%00001000   ; right
    beq set_hz_var_float_right

    jmp clear_hz_var_float 
    
set_hz_var_float_left:
    lda #1
    sta var_float_left
    
    jmp fall
set_hz_var_float_right:
    lda #1
    sta var_float_right
    jmp fall
clear_hz_var_float:
    lda #0
    sta var_float_left
    sta var_float_right
    jmp fall
not_on_ground:
    jsr experiance_gravity
    jmp apply_horz_movement

move_left:
    lda #0
    sta facing_forward
    jsr move_left_inc
    lda var_float_left
    cmp #1
    beq move_left_jmp 
    jmp fall
move_left_jmp:
    jsr move_left_inc
    jsr move_left_inc
    jmp fall
move_left_inc:
    ;if in high range
    lda SPRITE_HIGH_BITS ; >= 50 check to see if high bit is set
    and #GOAT_SPRITE_HIGH_BIT
    beq move_left_low_range ; high range not set, jump to low range
    jmp move_left_high_range
move_left_low_range:
    lda var_goat_x
    cmp #25             ; compare to minimum X boundary (adjust 10 as needed)
    bcc skip_x_dec      ; if less than 25, skip decrement but continue execution
    jmp dec_x
skip_x_dec:
    rts                 ; Return without changing X position

move_left_high_range:
    ; check if low range is zero
    lda var_goat_x
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
    lda var_goat_x
    sec
    sbc #1
    sta var_goat_x 
    rts
move_right:
    lda #1
    sta facing_forward
    jsr move_right_inc
    lda var_float_right
    cmp #1
    beq move_right_jmp 
    jmp fall
move_right_jmp:
    jsr move_right_inc
    jsr move_right_inc
    jmp fall
move_right_inc:
    lda var_goat_x
    cmp #65  ;check to see if greater than 50
    bcc inc_x ; less than 50, safe to increment in all cases
    lda SPRITE_HIGH_BITS ; >= 50 check to see if high bit is set
    and #GOAT_SPRITE_HIGH_BIT
    beq move_right_low_range  ;high bit was not set, continue low range
    ; high bit is set, and x >= 50, don't do anything, go back to update
    jmp fall
move_right_low_range:
    lda var_goat_x
    cmp #255 ; see if current x value is 255
    bcc inc_x  ; if x < 255, skip to increment`
    lda SPRITE_HIGH_BITS
    eor #GOAT_SPRITE_HIGH_BIT
    sta SPRITE_HIGH_BITS
    jmp inc_x
    
inc_x:
    jsr forward_goat
    lda var_goat_x
    clc
    adc #01
    sta var_goat_x
    rts

experiance_gravity:
    lda goat_y_hi
    cmp #220
    bcs on_ground
    clc

    lda var_vert_speed_lo
    adc #GRAVITY_LO
    sta var_vert_speed_lo

    lda var_vert_speed_hi
    adc #GRAVITY_HI
    sta var_vert_speed_hi
    
    lda var_vert_speed_hi
    bmi not_terminal_veloicty
    cmp #4
    bcc not_terminal_veloicty
    lda #4      ; clamp to terminal velocity
    sta var_vert_speed_hi
not_terminal_veloicty:
    rts

on_ground:
    lda #0
    sta var_vert_speed_hi
    sta var_vert_speed_lo
    lda #220
    sta goat_y_hi
    lda #0
    sta var_float_left
    sta var_float_right
    jmp update
apply_horz_movement:
    lda var_float_left
    cmp #01
    beq apply_var_float_left
    lda var_float_right
    cmp #01
    beq apply_var_float_right
    jmp fall
    
apply_var_float_left:
    jmp move_left
apply_var_float_right:
    jmp move_right

fall:
   jsr experiance_gravity
   ; Add vertical speed to goat's position
   clc
   
   lda goat_y_lo
   adc var_vert_speed_lo
   sta goat_y_lo

   lda goat_y_hi
   adc var_vert_speed_hi
   sta goat_y_hi

   ldy goat_y_hi
   cpy #220      ; Check if we're at or below ground level
   bcs landing   ; If so, handle landing
   jmp update    ; Otherwise continue

landing:
   lda #220      ; Make sure we're exactly at ground level
   sta goat_y_hi
   lda #0        ; Reset vertical speed
   sta var_vert_speed_hi
   sta var_vert_speed_lo
   sta var_float_left
   sta var_float_right
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

munch_left:
    lda #$83
    sta $07f8          ; Set sprite pointer? (Your code does this first)
    jsr calc_veg_index ; X = vegetation index
    lda ARRAY_VEG_STATE,x
    beq munch_done           ; If already 0, skip
    sec
    sbc #1             ; Subtract 1
    sta ARRAY_VEG_STATE,x
    
    jmp fall
munch_right:    
    lda #$82
    sta $07f8
    jsr calc_veg_index
    lda ARRAY_VEG_STATE,x
    beq munch_done
    sec
    sbc #1
    sta ARRAY_VEG_STATE,x
    jmp fall
    
munch_done:
    jmp fall
; Calculates the vegitation char index based on where the goat is.
; Saves the calculated value in the x register.

; Calculate vegetation index for sprite 0
; Reads from $d000 (sprite X low) and $d010 (MSB for all sprites)
; Output:
;   X = vegetation index (0–39)

calc_veg_index:

    lda SPRITE_HIGH_BITS           ; Read MSB register
    and #%00000001      ; Isolate bit for sprite 0
    lsr                 ; Move bit into carry
    lda var_goat_x           ; Low 8 bits of sprite X
    ror                 ; Rotate carry into bit 7
    lsr                 ; Divide by 8
    lsr
    tax 
    lda facing_forward
    bne calc_veg_cont
    txa
    clc
    sbc #2 ; go back 3 characters because goat is facing backwards
    tax
calc_veg_cont:
;    tax

    rts


; Set screen background color once at program start (not every loop)
    lda #COLOR_BLUE
    sta $d021         ; Set global background color to blue

draw_vegetation:
    lda #VEG_HARDINESS
    lsr               ; VEG_HARDINESS / 2
    sta threshold

    ldx #0
@veg_loop:
    lda ARRAY_VEG_STATE,x
    beq @clear_char           ; If zero, clear cell

    cmp threshold
    bcc @draw_mched           ; If less than threshold, draw damaged char

    lda #CHAR_VEG
    jmp @draw_char

@draw_mched:
    lda #CHAR_VEG_MCHD

@draw_char:
    sta SCREEN + 23*40,x
    lda #COLOR_GREEN           ; Foreground = green for character pixels (the “black” bits)
    sta COLOR_RAM + 23*40,x
    jmp @next

@clear_char:
    lda #$20                  ; Space character
    sta SCREEN + 23*40,x
    lda #COLOR_BLUE           ; Foreground same as background so it looks blank
    sta COLOR_RAM + 23*40,x

@next:
    inx
    cpx #40
    bne @veg_loop
    rts

threshold: .byte 0

    
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
    
goat_green: 
    lda #$05
    sta $d027
    rts

goat_red: 
    lda #$02
    sta $d027
    rts

goat_gray: 
    lda #$0f
    sta $d027
    rts
goat_white: 
    lda #$01
    sta $d027
    rts
.include "tree.s"
.segment "SPRITEDATA"
goat:
.include "sprites/goat_walk_right.inc"
goat_rev:
.include "sprites/goat_walk_left.inc"
munch:
.include "sprites/goat_munch_right.inc"
munch_rev:
.include "sprites/goat_munch_left.inc"
.segment "TREE"
.include "objects/tree.inc"