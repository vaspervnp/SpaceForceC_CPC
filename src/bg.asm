; bg.asm — φόντο από πλακίδια και επαναφορά του κάτω από τα sprites
;
; Μέχρι το M3 (scrolling) ο χάρτης είναι ένα στατικό παράθυρο 20x21
; πλακιδίων, γραμμές 0-167. Τα sprites σβήνονται ξαναζωγραφίζοντας τα
; πλακίδια που κάλυπταν (restore_rect): για το σκάφος 12x24 είναι
; ως 3x4 = 12 πλακίδια, ~2 ms.

BG_ROWS         equ 21
BG_COLS         equ 20
BG_LINES        equ BG_ROWS*TILES_H     ; 168: από εδώ και κάτω το HUD

; Γεμίζει bg_map με ψευδοτυχαία αστέρια.
make_background:
        ld hl,bg_map
        ld bc,BG_ROWS*BG_COLS
.gen:   push bc
        push hl
        call rand
        pop hl
        pop bc
        and 15
        cp 4
        jr c,.star
        xor a                   ; ti_void, τα 3/4 του ουρανού
        jr .put
.star:  inc a                   ; 1..4: star_s, star_m, stars_3, dust
.put:   ld (hl),a
        inc hl
        dec bc
        ld a,b
        or c
        jr nz,.gen
        ret

; Ζωγραφίζει όλο τον χάρτη στο back buffer.
draw_background:
        ld b,0
        ld c,0
        ld d,BG_LINES
        ld a,BG_COLS*TILES_W
        jp restore_rect

; Ξαναζωγραφίζει τα πλακίδια που καλύπτουν ένα ορθογώνιο.
; in: B = γραμμή, C = byte x, D = ύψος σε γραμμές, A = πλάτος σε bytes
; Το ορθογώνιο κόβεται στο κάτω όριο του χάρτη (το HUD δεν έχει πλακίδια).
restore_rect:
        ; τελευταία στήλη πλακιδίου = (x + w - 1) / 4
        add a,c
        dec a
        rrca
        rrca
        and 63
        ld (.lastcol+1),a
        ; τελευταία σειρά = min((y + h - 1) / 8, BG_ROWS - 1)
        ld a,b
        add a,d
        dec a
        cp BG_LINES
        jr c,.inmap
        ld a,BG_LINES-1
.inmap: rrca
        rrca
        rrca
        and 31
        ld (.lastrow+1),a
        ; πρώτη στήλη/σειρά
        ld a,c
        rrca
        rrca
        and 63
        ld (.firstcol+1),a
        ld a,b
        cp BG_LINES
        ret nc                  ; όλο μέσα στο HUD
        rrca
        rrca
        rrca
        and 31
        ld b,a                  ; B = σειρά
.row:
.firstcol:
        ld c,0                  ; C = στήλη
.col:   push bc
        ; κελί = σειρά*20 + στήλη
        ld l,b
        ld h,0
        ld e,l
        ld d,h
        add hl,hl               ; *4
        add hl,hl
        add hl,de               ; *5
        add hl,hl               ; *10
        add hl,hl               ; *20
        ld e,c
        ld d,0
        add hl,de
        ld de,bg_map
        add hl,de
        ld l,(hl)               ; *32 = TILES_SZ
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,tiles_gfx
        add hl,de
        ; οθόνη: γραμμή = σειρά*8, x = στήλη*4
        ld a,b
        add a,a
        add a,a
        add a,a
        ld b,a
        ld a,c
        add a,a
        add a,a
        ld c,a
        call blit_tile
        pop bc
        ld a,c
        inc c
.lastcol:
        cp 0
        jr nz,.col
        ld a,b
        inc b
.lastrow:
        cp 0
        jr nz,.row
        ret

; 16-bit xorshift (J. Metcalf). out: A, HL
rand:
seed equ $+1
        ld hl,#ACE1
        ld a,h
        rra
        ld a,l
        rra
        xor h
        ld h,a
        ld a,l
        rra
        ld a,h
        rra
        xor l
        ld l,a
        xor h
        ld h,a
        ld (seed),hl
        ret
