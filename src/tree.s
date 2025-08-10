SCREEN_RAM   = $0400
CHAR_TO_DRAW = $2A    ; PETSCII '*'
SCREEN_WIDTH = 40


DrawPoints:
    ; Load base address of tree_points into tree_ptr
    LDA #<tree_points
    STA tree_ptr
    LDA #>tree_points
    STA tree_ptr+1

    LDA #0
    STA index

    ; Load number of points from tree_points[0]
    LDY #0
    LDA (tree_ptr),Y
    STA tempCount

    ; Start reading pairs after the count byte
    LDA #1
    STA index

DrawPoints_Loop:
    LDA tempCount
    BEQ DrawPoints_Done

    ; Load X coordinate
    LDY index
    LDA (tree_ptr),Y
    STA tempX
    INC index

    ; Load Y coordinate
    LDY index
    LDA (tree_ptr),Y
    STA tempY
    INC index

    ; --- Multiply Y * 40 directly (16-bit)
    LDA #0
    STA tempOffset      ; clear low
    STA tempOffset+1    ; clear high

    LDX #40             ; multiplier
MulY40:
    CLC
    LDA tempOffset
    ADC tempY
    STA tempOffset
    LDA tempOffset+1
    ADC #0
    STA tempOffset+1
    DEX
    BNE MulY40

    ; --- Add X coordinate ---
    CLC
    LDA tempOffset
    ADC tempX
    STA tempOffset
    LDA tempOffset+1
    ADC #0
    STA tempOffset+1

    ; --- screen_ptr = SCREEN_RAM + tempOffset ---
    CLC
    LDA tempOffset
    ADC #<SCREEN_RAM
    STA screen_ptr
    LDA tempOffset+1
    ADC #>SCREEN_RAM
    STA screen_ptr+1

    ; Put char on screen
    LDY #0
    LDA #CHAR_TO_DRAW
    STA (screen_ptr),Y

    ; --- color_ptr = COLOR_RAM + tempOffset ---
    CLC
    LDA tempOffset
    ADC #<COLOR_RAM
    STA color_ptr
    LDA tempOffset+1
    ADC #>COLOR_RAM
    STA color_ptr+1

    LDY #0
    LDA #COLOR_BROWN
    STA (color_ptr),Y

    DEC tempCount
    JMP DrawPoints_Loop

DrawPoints_Done:
    RTS
