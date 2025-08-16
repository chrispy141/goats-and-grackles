
SCREEN_RAM   = $0400
DrawPoints:
    ; Load base address of tree_points into tree_ptr
    LDA #<tree_points
    STA tree_ptr
    LDA #>tree_points
    STA tree_ptr+1

    ; 16-bit index for reading points
    LDA #1
    STA index_lo
    LDA #0
    STA index_hi

    ; Load number of points from tree_points[0]
    LDY #0
    LDA (tree_ptr),Y
    STA tempCount
    JMP DrawPoints_Loop

DrawPoints_Done:
    RTS
DrawPoints_Loop:
    LDA tempCount
    BEQ DrawPoints_Done

    ; Calculate full address for each access: tree_points + index_lo + 256*index_hi
    LDA #<tree_points
    CLC
    ADC index_lo
    STA temp_ptr
    LDA #>tree_points
    ADC index_hi
    STA temp_ptr+1

    ; Load X coordinate
    LDY #0
    LDA (temp_ptr),Y
    STA tempX
    JSR IncIndex

    LDA #<tree_points
    CLC
    ADC index_lo
    STA temp_ptr
    LDA #>tree_points
    ADC index_hi
    STA temp_ptr+1

    ; Load Y coordinate
    LDY #0
    LDA (temp_ptr),Y
    STA tempY
    JSR IncIndex

    LDA #<tree_points
    CLC
    ADC index_lo
    STA temp_ptr
    LDA #>tree_points
    ADC index_hi
    STA temp_ptr+1

    ; Load PETSCII character
    LDY #0
    LDA (temp_ptr),Y
    STA tempChar
    JSR IncIndex

    LDA #<tree_points
    CLC
    ADC index_lo
    STA temp_ptr
    LDA #>tree_points
    ADC index_hi
    STA temp_ptr+1

    ; Load Color code
    LDY #0
    LDA (temp_ptr),Y
    STA tempColor
    JSR IncIndex

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


; 16-bit index increment subroutine
IncIndex:
    INC index_lo
    LDA index_lo
    CMP #0
    BNE IncIndex_Done
    INC index_hi
IncIndex_Done:
    RTS
