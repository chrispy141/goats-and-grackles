; Assemble: ca65 sprite_demo.asm
; Link: ld65 -C c64sprite.cfg -o sprite_demo.prg sprite_demo.o -u __EXEHDR__

.segment "ZEROPAGE"
spriteX: .res 1
spriteY: .res 1

.segment "CODE"
.export _start

SPRITE_ADDR = $2000       ; Matches SPRITES memory in .cfg
SPRITE_PTR  = SPRITE_ADDR / 64  ; VIC-II expects /64 pointer

_start:
    sei                   ; Disable interrupts during setup
    lda #$93       ; PETSCII code for "clear screen"
    jsr $ffd2      ; Output via CHROUT

    ; Set background and border color (blue)
    lda #$06
    sta $d020
    sta $d021

    ; Enable sprite 0
    lda #$01
    sta $d015

    ; Set sprite 0 X/Y position
    lda #100
    sta $d000
    lda #50
    sta $d001

    ; Set sprite color (yellow)
    lda #$0e
    sta $d027

    ; Set sprite pointer in $07F8 (sprite 0)
    lda #SPRITE_PTR
    sta $07f8

    cli                   ; Re-enable interrupts

print_msg:
    lda #$0e              ; Switch to lowercase mode
    jsr $ffd2
    lda #'s'
    jsr $ffd2
    lda #'p'
    jsr $ffd2
    lda #'r'
    jsr $ffd2
    lda #'i'
    jsr $ffd2
    lda #'t'
    jsr $ffd2
    lda #'e'
    jsr $ffd2
    lda #$0d
    jsr $ffd2

loop:
    jmp loop

.segment "SPRITEDATA"
smiley:
; 24x21 pixels = 63 bytes per sprite
    .byte %00011111,%11100000,%00000000
    .byte %00111111,%11110000,%00000000
    .byte %01111111,%11111000,%00000000
    .byte %11111000,%00011111,%00000000
    .byte %11100111,%11100111,%00000000
    .byte %11001111,%11110011,%00000000
    .byte %11011111,%11111011,%00000000
    .byte %10111100,%00111101,%00000000
    .byte %10111000,%00011101,%00000000
    .byte %10111000,%00011101,%00000000
    .byte %10111100,%00111101,%00000000
    .byte %10111111,%11111101,%00000000
    .byte %11011111,%11111011,%00000000
    .byte %11001111,%11110011,%00000000
    .byte %11100111,%11100111,%00000000
    .byte %11111000,%00011111,%00000000
    .byte %01111111,%11111000,%00000000
    .byte %00111111,%11110000,%00000000
    .byte %00011111,%11100000,%00000000
    .byte %00000000,%00000000,%00000000
    .byte %00000000,%00000000,%00000000
    .byte %00000000,%00000000,%00000000
