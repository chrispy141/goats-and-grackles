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


    ; Copy third sprite
    ldx #0
copy_sprite_5_loop:
     
    lda grac_fly_left_up,x
    sta $20C0,x
    inx
    cpx #63
    bcc copy_sprite_5_loop

    ; Copy third sprite
    ldx #0
copy_sprite_6_loop:
     
    lda grac_fly_left_down,x
    sta $20C0,x
    inx
    cpx #63
    bcc copy_sprite_6_loop


    ; Copy third sprite
    ldx #0
copy_sprite_7_loop:
     
    lda grac_fly_right_up,x
    sta $20C0,x
    inx
    cpx #63
    bcc copy_sprite_7_loop

    ; Copy third sprite
    ldx #0
copy_sprite_8_loop:

    lda grac_fly_right_down,x
    sta $20C0,x
    inx
    cpx #63
    bcc copy_sprite_8_loop

    ; Copy third sprite
    ldx #0
copy_sprite_9_loop:
     
    lda grac_sit_left,x
    sta $20C0,x
    inx
    cpx #63
    bcc copy_sprite_9_loop

    ; Copy third sprite
    ldx #0
copy_sprite_10_loop:

    lda grac_sit_right,x
    sta $20C0,x
    inx
    cpx #63
    bcc copy_sprite_10_loop
