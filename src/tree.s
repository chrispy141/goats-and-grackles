SCREEN_RAM   = $0400
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

    ; Start reading points after count byte
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

    ; Load PETSCII character
    LDY index
    LDA (tree_ptr),Y
    STA tempChar
    INC index

    ; Load Color code
    LDY index
    LDA (tree_ptr),Y
    STA tempColor
    INC index

    ; Multiply Y * 40 (16-bit) = Y*40 to get screen offset

    ; Clear tempOffset (16-bit)
    LDA #0
    STA tempOffset
    STA tempOffset+1

    ; 16-bit multiply tempY * 40
    LDX #40
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

    ; Add X to offset
    CLC
    LDA tempOffset
    ADC tempX
    STA tempOffset
    LDA tempOffset+1
    ADC #0
    STA tempOffset+1

    ; Calculate screen RAM address = SCREEN_RAM + tempOffset
    CLC
    LDA tempOffset
    ADC #$00         ; low byte of SCREEN_RAM ($0400)
    STA screen_ptr
    LDA tempOffset+1
    ADC #$04         ; high byte of SCREEN_RAM ($0400)
    STA screen_ptr+1

    ; Write character at screen_ptr
    LDY #0
    LDA tempChar
    STA (screen_ptr),Y

    ; Calculate color RAM address = COLOR_RAM + tempOffset
    CLC
    LDA tempOffset
    ADC #$00         ; low byte of COLOR_RAM ($D800)
    STA color_ptr
    LDA tempOffset+1
    ADC #$D8         ; high byte of COLOR_RAM ($D800)
    STA color_ptr+1

    ; Write color at color_ptr
    LDY #0
    LDA tempColor
    STA (color_ptr),Y

    DEC tempCount
    JMP DrawPoints_Loop

DrawPoints_Done:
    RTS
