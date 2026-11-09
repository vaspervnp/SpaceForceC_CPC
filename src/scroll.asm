; scroll.asm — hardware scroll με CRTC R12/R13
;
; Η οθόνη (40 words x 21 σειρές) είναι παράθυρο σε δαχτυλίδι 1024 words
; ανά γραμμή raster (2K). Κάθε κελί του κόσμου — ένα word (2 bytes = 4
; pixels) επί μία σειρά (8 γραμμές) — έχει ΣΤΑΘΕΡΗ διεύθυνση:
;
;     MA = (wy*40 + wx) mod 1024     byte = σελίδα + γραμμή*#800 + 2*MA
;
; και το R12/R13 δείχνει το MA της πάνω αριστερής γωνίας της κάμερας. Μέσα
; σε κάθε παράθυρο 40x21 τα MA είναι διαφορετικά (840 <= 1024), οπότε όταν
; η κάμερα κινηθεί ένα βήμα ζωγραφίζεται ΜΟΝΟ ό,τι μπαίνει: μια στήλη από
; 21 μισά πλακίδια ή μια σειρά από 40. Τα κελιά που φεύγουν απλώς
; ξαναχρησιμοποιούνται.
;
; Βήμα: 1 word οριζόντια (4 pixels = 8 μονάδες) και 1 σειρά κάθετα (8
; γραμμές = 8 μονάδες), ίδιο στους δύο άξονες. Το σκάφος κινείται ανά
; byte πάνω στη σκηνή, οπότε η κίνησή του μένει ομαλή.
;
; Double buffering: κάθε σελίδα έχει τη δική της κάμερα (buf_*), που μένει
; δύο καρέ πίσω. Το scroll_buffer τη φέρνει στη νέα κάμερα βήμα-βήμα: πρώτα
; οι στήλες, μετά οι σειρές, ώστε ό,τι ζωγραφίζεται τελευταίο να είναι όσα
; κελιά μοιράζονται MA με κελιά που μόλις βγήκαν.

MAP_W           equ 64          ; πλακίδια = 128 words = 256 bytes: το X χωράει σε byte
MAP_H           equ 48          ; πλακίδια = 384 γραμμές
VIEW_W          equ 40          ; words
VIEW_H          equ 21          ; σειρές: το παιχνίδι, κάτω του το HUD (hw.asm)
CAM_MAX_X       equ MAP_W*2-VIEW_W
CAM_MAX_Y       equ MAP_H-VIEW_H
WORLD_W         equ MAP_W*TILES_W       ; 256 bytes
WORLD_H         equ MAP_H*TILES_H       ; 384 γραμμές

; Κατάσταση ανά σελίδα (IX): η κάμερα όταν ζωγραφίστηκε και τα sprites της
; (sprites.asm).
BUF_CX          equ 0           ; κάμερα, words
BUF_CY          equ 1           ; κάμερα, σειρές
BUF_NREC        equ 2           ; πόσα sprites ζωγραφίστηκαν
BUF_RECS        equ 3           ; οι εγγραφές τους (dw)
BUF_SAVE        equ 5           ; τα σωσμένα bytes (dw)
BUF_VER         equ 7           ; ο boss στην εγγραφή 0: ποιο boss_ver (#FF = κανένα)
BUF_KEEP        equ 8           ; πού τελειώνουν τα σωσμένα του (dw)
BUF_SIZE        equ 10

; row40[wy] = (wy*40) mod 1024
make_row40:
        ld hl,0
        ld de,VIEW_W
        ld ix,row40
        ld b,MAP_H
.row:   ld (ix+0),l
        ld a,h
        and 3
        ld (ix+1),a
        inc ix
        inc ix
        add hl,de
        djnz .row
        ret

; MA της πάνω αριστερής γωνίας της κάμερας (για το R12/R13).
; in: C = wx, B = wy   out: HL = MA (0-1023)
cell_ma:
        ld l,b
        ld h,0
        add hl,hl
        ld de,row40
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ld e,c
        ld d,0
        add hl,de
        ld a,h
        and 3
        ld h,a
        ret

; Διεύθυνση της πρώτης γραμμής ενός κελιού στη σελίδα draw_page.
; in: C = wx, B = wy   out: DE   (κρατάει BC)
cell_addr:
        call cell_ma
        add hl,hl               ; σε bytes
        ld e,l
        ld a,h
        and 7
        ld hl,draw_page
        or (hl)
        ld d,a
        ret

; Διεύθυνση ενός byte του κόσμου στη σελίδα draw_page.
; in: C = X (bytes), HL = Y (γραμμές)   out: DE   (κρατάει BC, HL)
world_addr:
        push hl
        push bc
        ld a,l
        and 7
        add a,a
        add a,a
        add a,a
        ld (.ra+1),a            ; γραμμή μέσα στη σειρά -> bits 11-13
        srl h
        rr l
        srl h
        rr l
        srl h
        rr l                    ; L = wy
        ld b,l
        ld a,c
        srl c                   ; C = wx
        and 1
        push af
        call cell_ma
        add hl,hl
        pop af
        or l                    ; + μονό byte μέσα στο word (το L είναι ζυγό)
        ld e,a
        ld a,h
        and 7
.ra:    or 0
        ld hl,draw_page
        or (hl)
        ld d,a
        pop bc
        pop hl
        ret

;------------------------------------------------------------------
; Φόντο
;------------------------------------------------------------------

; Ζωγραφίζει μισό πλακίδιο (2 bytes x 8 γραμμές) σε ένα κελί.
; in: C = wx, B = wy   (κρατάει BC)
draw_halftile:
        call cell_addr          ; DE
        call map_ptr            ; HL
        ld a,(hl)
        call half_src
        jp copy_half

; HL = &bg_map[wy*64 + wx/2]   in: C = wx, B = wy   (κρατάει BC, DE)
map_ptr:
        ld l,b
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld a,c
        srl a
        add a,l                 ; το L είναι πολλαπλάσιο του 64: χωρίς κρατούμενο
        ld l,a
        ld a,h
        add a,bg_map/256        ; bg_map στοιχισμένο σε 256
        ld h,a
        ret

; Τα μισά πλακίδια, το καθένα σε 16 συνεχόμενα bytes (8 γραμμές x 2), ώστε
; το copy_half να τα διαβάζει με POP. Φτιάχνονται από τα tiles_gfx στην αρχή.
; halftiles + (πλακίδιο*2 + μισό)*16, στοιχισμένο σε 256.
make_halftiles:
        ld hl,tiles_gfx
        ld de,halftiles
        ld b,16                 ; πλακίδια
.tile:  push bc
        push hl
        call .half              ; αριστερό μισό
        pop hl
        push hl
        inc hl
        inc hl
        call .half              ; δεξί μισό
        pop hl
        ld bc,TILES_SZ
        add hl,bc
        pop bc
        djnz .tile
        ret
.half:  ld b,8
.line:  ld a,(hl)
        ld (de),a
        inc de
        inc hl
        ld a,(hl)
        ld (de),a
        inc de
        inc hl
        inc hl
        inc hl
        djnz .line
        ret

; HL = μισό πλακίδιο   in: A = πλακίδιο, C = wx   (κρατάει BC, DE)
half_src:
        ld l,a
        ld h,0
        add hl,hl               ; *32 = (πλακίδιο*2)*16
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        bit 0,c
        jr z,.left
        set 4,l                 ; δεξί μισό: +16
.left:  ld a,h
        add a,halftiles/256
        ld h,a
        ret

; Αντιγράφει μισό πλακίδιο στην οθόνη διαβάζοντάς το με POP: 13 µs/γραμμή
; αντί για 22. Με κλειστά interrupts (ο handler θα έγραφε πάνω στα
; δεδομένα)· το gate array κρατάει το αίτημα ως το EI, άρα δεν χάνεται VSYNC.
; in: HL = μισό πλακίδιο, DE = οθόνη (ζυγό E: το inc l δεν κρατάει ποτέ)
; out: DE ίδιο   (κρατάει BC)
copy_half:
        push bc
        di
        ld (.sp+1),sp
        ld sp,hl
        ex de,hl
        repeat 7
        pop bc
        ld (hl),c
        inc l
        ld (hl),b
        dec l
        ld a,h
        add a,8
        ld h,a
        rend
        pop bc
        ld (hl),c
        inc l
        ld (hl),b
        dec l
        ld a,h
        sub 7*8
        ld h,a
        ex de,hl
.sp:    ld sp,0
        ei
        pop bc
        ret

; Στήλη 21 κελιών. Από κελί σε κελί: οθόνη +80 bytes (40 words), χάρτης +64.
; in: C = wx, B = wy της πρώτης σειράς   (κρατάει BC)
draw_column:
        push bc
        call cell_addr
        call map_ptr
        ld b,VIEW_H
.cell:  push bc
        push hl
        ld a,(hl)
        call half_src
        call copy_half
        pop hl
        ld bc,MAP_W
        add hl,bc
        ld a,e                  ; DE += 80 μέσα στο δαχτυλίδι των 2K
        add a,VIEW_W*2
        ld e,a
        jr nc,.same
        inc d
        bit 3,d                 ; πέρασε το #x7FF (γραμμή 0: τα bits 5-3 είναι 0)
        jr z,.same
        ld a,d
        sub 8
        ld d,a
.same:  pop bc
        djnz .cell
        pop bc
        ret

; Σειρά 40 κελιών. Από κελί σε κελί: οθόνη +2 bytes, χάρτης +1 ανά δύο κελιά.
; in: B = wy, C = wx της πρώτης στήλης   (κρατάει BC)
draw_row:
        push bc
        call cell_addr
        call map_ptr
        ld b,VIEW_W
.cell:  push hl
        ld a,(hl)
        call half_src
        call copy_half
        pop hl
        bit 0,c
        jr z,.half
        inc hl                  ; τελείωσε το πλακίδιο
.half:  inc c
        inc e                   ; DE += 2 μέσα στο δαχτυλίδι των 2K
        inc e
        jr nz,.same
        inc d
        bit 3,d
        jr z,.same
        ld a,d
        sub 8
        ld d,a
.same:  djnz .cell
        pop bc
        ret


; Ζωγραφίζει όλη την κάμερα της σελίδας IX.
draw_view:
        ld b,(ix+BUF_CY)
        ld a,VIEW_H
.row:   push af
        ld c,(ix+BUF_CX)
        call draw_row
        pop af
        inc b
        dec a
        jr nz,.row
        ret

; Φέρνει την κάμερα της σελίδας IX στην (cam_x, cam_y), ζωγραφίζοντας
; μόνο τις στήλες και σειρές που μπαίνουν.
scroll_buffer:
.horiz: ld a,(cam_x)
        cp (ix+BUF_CX)
        jr z,.vert
        jr c,.left
        ; δεξιά: μπαίνει η στήλη cx+40
        ld a,(ix+BUF_CX)
        inc a
        ld (ix+BUF_CX),a
        add a,VIEW_W-1
        jr .col
.left:  ld a,(ix+BUF_CX)
        dec a
        ld (ix+BUF_CX),a
.col:   ld c,a
        ld b,(ix+BUF_CY)
        call draw_column
        jr .horiz
.vert:  ld a,(cam_y)
        cp (ix+BUF_CY)
        ret z
        jr c,.up
        ld a,(ix+BUF_CY)
        inc a
        ld (ix+BUF_CY),a
        add a,VIEW_H-1
        jr .row
.up:    ld a,(ix+BUF_CY)
        dec a
        ld (ix+BUF_CY),a
.row:   ld b,a
        ld c,(ix+BUF_CX)
        call draw_row
        jr .vert
