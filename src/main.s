        .export _start

.segment "CODE"

_start:
    jsr $E544              ; Clear screen using KERNAL

    lda #6                 ; Blue background and border
    sta $d021              ; background
    sta $d020              ; border

    ; ---- Fill screen with spaces ----
    lda #$20               ; PETSCII space
    ldx #0
FillScreen:
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $06e8,x
    inx
    bne FillScreen

    ; ---- Draw vegetation on row 22 ----
    lda #$2a               ; PETSCII '*'
    ldx #0
DrawGrass:
    sta $0400 + (22*40),x
    inx
    cpx #40
    bne DrawGrass

    ; ---- Draw dirt on row 23 ----
    lda #$2e               ; PETSCII '.' for dirt
    ldx #0
DrawDirt:
    sta $0400 + (23*40),x
    inx
    cpx #40
    bne DrawDirt

    ; ---- Color vegetation row (green) ----
    lda #5                 ; green
    ldx #0
ColorGrass:
    sta $d800 + (22*40),x
    inx
    cpx #40
    bne ColorGrass

    ; ---- Color dirt row (brown) ----
    lda #2                 ; brown
    ldx #0
ColorDirt:
    sta $d800 + (23*40),x
    inx
    cpx #40
    bne ColorDirt

Forever:
    jmp Forever            ; Infinite loop
