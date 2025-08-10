tree_ptr:    .res 2    ; pointer to tree_points data
index:       .res 1    ; offset into tree_points
tempX:       .res 1
tempY:       .res 1
tempMul32:   .res 1
tempMul8:    .res 1
tempOffset:  .res 2    ; 16-bit offset Y*40 + X
tempCount:   .res 1
screen_ptr:  .res 2    ; pointer to screen RAM + offset
color_ptr:   .res 2    ; pointer to color RAM + offset