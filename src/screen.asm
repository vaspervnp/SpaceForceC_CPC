; screen.asm — διευθύνσεις οθόνης και blitters
;
; Όλα γράφουν στη σελίδα draw_page (#80 ή #C0), δηλαδή στο back buffer.
; Ο line_tab κρατάει offsets ως προς την αρχή της σελίδας (#0000-#3FFF),
; οπότε η ίδια ρουτίνα δουλεύει και για τις δύο: H = offset_h OR σελίδα.

; line_tab[y] = (y/8)*80 + (y%8)*#800
make_line_table:
        ld ix,line_tab
        ld hl,0
        ld de,80
        ld b,25
.row:   push hl
        ld c,8
.ln:    ld (ix+0),l
        ld (ix+1),h
        inc ix
        inc ix
        ld a,h
        add a,8
        ld h,a
        dec c
        jr nz,.ln
        pop hl
        add hl,de
        djnz .row
        ret

; in: B = γραμμή, C = byte x   out: DE = διεύθυνση στο back buffer
; (κρατάει HL, χαλάει A, B)
scr_addr:
        push hl
        ld l,b
        ld h,0
        add hl,hl
        ld de,line_tab
        add hl,de
        ld e,(hl)
        inc hl
        ld a,(hl)
draw_page equ $+1
        or #C0                  ; σελίδα: #80 ή #C0, την αλλάζει το flip
        ld d,a
        ld a,e                  ; + x: μέσα σε μία γραμμή, δεν περνάει όριο 2K
        add a,c
        ld e,a
        jr nc,.ok
        inc d
.ok:    pop hl
        ret

; Καθαρίζει το back buffer.
clear_page:
        ld a,(draw_page)
        ld h,a
        ld l,0
        ld d,a
        ld e,1
        ld bc,#3FFF
        ld (hl),0
        ldir
        ret

;------------------------------------------------------------------
; Blitters
;------------------------------------------------------------------

; Masked sprite, bytes πλεγμένα mask,data.
; in: HL = γραφικό, B = γραμμή, C = byte x, D = ύψος, A = bytes δεδομένων/γραμμή
; out: HL = αμέσως μετά το γραφικό
blit_masked:
        ld (.w+1),a
.row:   push bc
        push de
        call scr_addr
.w:     ld b,0
.px:    ld a,(de)
        and (hl)
        inc hl
        or (hl)
        inc hl
        ld (de),a
        inc de
        djnz .px
        pop de
        pop bc
        inc b
        dec d
        jr nz,.row
        ret

; Αδιαφανές πλακίδιο 8x8 (4 bytes x 8 γραμμές).
; in: HL = γραφικό, B = γραμμή, C = byte x
blit_tile:
        ld d,TILES_H
.row:   push bc
        push de
        call scr_addr
        ldi
        ldi
        ldi
        ldi
        pop de
        pop bc
        inc b
        dec d
        jr nz,.row
        ret

; Γεμίζει ορθογώνιο με το byte E.
; in: B = γραμμή, C = byte x, D = ύψος, A = πλάτος σε bytes, E = τιμή
fill_rect:
        ld (.w+1),a
        ld a,e
        ld (.v+1),a
.row:   push bc
        push de
        call scr_addr
.w:     ld b,0
.v:     ld a,0
.px:    ld (de),a
        inc de
        djnz .px
        pop de
        pop bc
        inc b
        dec d
        jr nz,.row
        ret
