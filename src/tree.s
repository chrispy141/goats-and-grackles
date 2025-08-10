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

    ; Calculate Y*32 = Y * 2^5
    LDA tempY
    ASL A
    ASL A
    ASL A
    ASL A
    ASL A
    STA tempMul32

    ; Calculate Y*8 = Y * 2^3
    LDA tempY
    ASL A
    ASL A
    ASL A
    STA tempMul8

    ; tempOffset = Y*40 = Y*32 + Y*8
    CLC
    LDA tempMul32
    ADC tempMul8
    STA tempOffset      ; low byte
    LDA #0
    STA tempOffset+1    ; high byte (no carry expected here)

    ; Add X coordinate
    CLC
    LDA tempOffset
    ADC tempX
    STA tempOffset

    ; Calculate screen RAM address = SCREEN_RAM + tempOffset
    LDA tempOffset
    CLC
    ADC #<SCREEN_RAM
    STA screen_ptr
    LDA tempOffset+1
    ADC #>SCREEN_RAM
    STA screen_ptr+1

    ; Store character at (screen_ptr),Y=0
    LDY #0
    LDA #CHAR_TO_DRAW
    STA (screen_ptr),Y

    ; Calculate color RAM address = COLOR_RAM + tempOffset
    LDA tempOffset
    CLC
    ADC #<COLOR_RAM
    STA color_ptr
    LDA tempOffset+1
    ADC #>COLOR_RAM
    STA color_ptr+1

    ; Store color brown at (color_ptr),Y=0
    LDY #0
    LDA #COLOR_BROWN
    STA (color_ptr),Y

    DEC tempCount
    JMP DrawPoints_Loop

DrawPoints_Done:
    RTS
