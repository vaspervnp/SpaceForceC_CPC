; main.asm — Space Force C, M0: hello world
;
; Ελέγχει όλη την αλυσίδα: rasm -> iDSK -> Extended DSK -> emulator.
; Mode 0 με την παλέτα του παιχνιδιού, φόντο από τα πλακίδια, τα 16
; καρέ του σκάφους, κείμενο με τη γραμματοσειρά του HUD, και ένα σκάφος
; στο κέντρο που στρίβει σε 8 κατευθύνσεις πάνω από το φόντο
; (επαναφορά πλακιδίων + masked blit, συγχρονισμένα με το VSYNC).
;
; Το firmware σβήνει: DI, ROMs off, δικό μας stack. Επιστροφή δεν υπάρχει.

        ifdef SNAPSHOT
        buildsna                ; αλλιώς: save σε DSK, στο τέλος
        bankset 0
        endif

        org #1000
        run start

SCREEN          equ #C000
GA_PORT         equ #7F         ; gate array (high byte)
PPI_B           equ #F5         ; PPI port B: bit 0 = VSYNC

BG_ROWS         equ 21          ; παράθυρο παιχνιδιού: 20x21 πλακίδια (γραμμές 0-167)
BG_COLS         equ 20

SPIN_X          equ 36          ; byte x του περιστρεφόμενου σκάφους (στήλη πλακιδίου 9)
SPIN_Y          equ 104         ; γραμμή (σειρά πλακιδίου 13)
SPIN_DELAY      equ 6           ; καρέ ανά κατεύθυνση (25 FPS => ~4 στροφές/δευτ.)

start:
        di
        ld sp,#C000
        ld bc,#7F8C             ; mode 0, upper + lower ROM off
        out (c),c

        call set_palette
        call clear_screen
        call make_line_table
        call draw_background
        call draw_ship_rows
        call draw_texts

        xor a
        ld (spin_dir),a
main_loop:
        ; 25 FPS: ένα καρέ λογικής ανά δύο VSYNC
        call wait_vbl
        call read_keys
        call wait_vbl

        ld hl,spin_timer
        dec (hl)
        jr nz,main_loop
        ld (hl),SPIN_DELAY

        ld a,(spin_dir)
        inc a
        and 7
        ld (spin_dir),a

        call restore_spin_bg
        ld a,(spin_dir)
        ld hl,ship_gfx
        ld de,SHIP_SZ
        or a
        jr z,.got
.mul:   add hl,de
        dec a
        jr nz,.mul
.got:   ld b,SPIN_Y
        ld c,SPIN_X
        ld d,SHIP_H
        ld a,SHIP_W
        call blit_masked
        jr main_loop

;------------------------------------------------------------------
; Υλικό
;------------------------------------------------------------------

set_palette:
        ld hl,palette_hw
        ld bc,#7F00
.pen:   out (c),c               ; επιλογή pen
        ld a,(hl)
        inc hl
        out (c),a               ; χρώμα (hardware value, ήδη με bit 6)
        inc c
        ld a,c
        cp 16
        jr nz,.pen
        ld c,#10                ; border
        out (c),c
        ld a,(palette_hw)       ; ίδιο με το pen 0
        out (c),a
        ret

wait_vbl:
        ld b,PPI_B
.out:   in a,(c)                ; περίμενε να τελειώσει το τρέχον VSYNC
        rra
        jr c,.out
.in:    in a,(c)                ; και να αρχίσει το επόμενο
        rra
        jr nc,.in
        ret

; Διαβάζει και τις 10 γραμμές του πίνακα πλήκτρων (PSG reg 14 μέσω PPI)
; στο keymap. Bit = 0 σημαίνει πατημένο.
read_keys:
        ld hl,keymap
        ld bc,#F40E             ; PSG: επιλογή reg 14
        out (c),c
        ld bc,#F6C0             ; PSG: select register
        out (c),c
        xor a                   ; PSG: inactive
        out (c),a
        ld bc,#F792             ; PPI port A = είσοδος
        out (c),c
        ld a,#40                ; PSG read + γραμμή 0
.line:  ld b,#F6
        out (c),a
        ld b,#F4
        in e,(c)
        ld (hl),e
        inc hl
        inc a
        cp #4A
        jr nz,.line
        ld bc,#F782             ; PPI port A = έξοδος
        out (c),c
        ld bc,#F600             ; PSG: inactive
        out (c),c
        ret

clear_screen:
        ld hl,SCREEN
        ld de,SCREEN+1
        ld bc,#3FFF
        ld (hl),0
        ldir
        ret

;------------------------------------------------------------------
; Διευθύνσεις οθόνης
;------------------------------------------------------------------

; line_tab[y] = SCREEN + (y/8)*80 + (y%8)*#800
make_line_table:
        ld ix,line_tab
        ld hl,SCREEN
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

; in: B = γραμμή, C = byte x   out: DE = διεύθυνση   (κρατάει HL)
scr_addr:
        push hl
        ld l,b
        ld h,0
        add hl,hl
        ld de,line_tab
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl
        ld b,0
        add hl,bc
        ex de,hl
        pop hl
        ret

;------------------------------------------------------------------
; Blitters
;------------------------------------------------------------------

; Masked sprite, bytes πλεγμένα mask,data.
; in: HL = γραφικό, B = γραμμή, C = byte x, D = ύψος, A = bytes δεδομένων/γραμμή
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

;------------------------------------------------------------------
; Φόντο
;------------------------------------------------------------------

; Γεμίζει bg_map με ψευδοτυχαία αστέρια και τα ζωγραφίζει.
draw_background:
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

        ld hl,bg_map
        ld b,0                  ; γραμμή
.trow:  ld c,0                  ; byte x
.tcol:  push hl
        push bc
        call draw_map_tile
        pop bc
        pop hl
        inc hl
        ld a,c
        add a,TILES_W
        ld c,a
        cp BG_COLS*TILES_W
        jr nz,.tcol
        ld a,b
        add a,TILES_H
        ld b,a
        cp BG_ROWS*TILES_H
        jr nz,.trow
        ret

; in: HL -> κελί του bg_map, B = γραμμή, C = byte x
draw_map_tile:
        ld a,(hl)
        ld l,a
        ld h,0
        add hl,hl               ; *32 = TILES_SZ
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,tiles_gfx
        add hl,de
        jp blit_tile

; Επαναφέρει τα πλακίδια κάτω από το περιστρεφόμενο σκάφος:
; 6 bytes x 24 γραμμές = στήλες 9-10, σειρές 13-15.
restore_spin_bg:
        ld b,SPIN_Y
.row:   ld c,SPIN_X
.col:   push bc
        ; κελί = (y/8)*20 + x/4
        ld a,b
        rrca
        rrca
        rrca
        and 31
        ld l,a
        ld h,0
        ld e,l
        ld d,h
        add hl,hl               ; *4
        add hl,hl
        add hl,de               ; *5
        add hl,hl               ; *10
        add hl,hl               ; *20
        ld a,c
        rrca
        rrca
        and 63
        ld e,a
        ld d,0
        add hl,de
        ld de,bg_map
        add hl,de
        call draw_map_tile
        pop bc
        ld a,c
        add a,TILES_W
        ld c,a
        cp SPIN_X+2*TILES_W
        jr nz,.col
        ld a,b
        add a,TILES_H
        ld b,a
        cp SPIN_Y+3*TILES_H
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

;------------------------------------------------------------------
; Περιεχόμενο της δοκιμής
;------------------------------------------------------------------

; Οι 16 όψεις του σκάφους σε δύο σειρές: space (γραμμή 32), earth (γραμμή 64).
draw_ship_rows:
        ld hl,ship_gfx
        ld b,32
        call .one_row
        ld b,64
.one_row:
        ld c,8
.next:  push bc
        ld d,SHIP_H
        ld a,SHIP_W
        call blit_masked        ; HL προχωράει στο επόμενο καρέ
        pop bc
        ld a,c
        add a,8
        ld c,a
        cp 8+8*8
        jr nz,.next
        ret

draw_texts:
        ld hl,txt_title
        ld b,8
        ld c,27
        call print_str
        ld hl,txt_m0
        ld b,176
        ld c,0
        call print_str
        ld hl,txt_tools
        ld b,188
        ld c,0
        jp print_str

; in: HL = κείμενο με 0 στο τέλος, B = γραμμή, C = byte x
print_str:
        ld a,(hl)
        or a
        ret z
        inc hl
        push hl
        push bc
        sub 32
        ld e,a
        ld d,0
        ld hl,font_map
        add hl,de
        ld l,(hl)
        ld h,0
        add hl,hl               ; *32 = FONT_SZ
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,font_gfx
        add hl,de
        ld d,FONT_H
        ld a,FONT_W
        call blit_masked
        pop bc
        pop hl
        inc c
        inc c
        jr print_str

; ASCII 32..95 -> γλύφος (άγνωστοι χαρακτήρες -> κενό)
font_map:
        db ch_32,ch_33,ch_32,ch_32,ch_32,ch_37,ch_32,ch_32     ; ' '..'''
        db ch_40,ch_41,ch_42,ch_43,ch_44,ch_45,ch_46,ch_47     ; '('..'/'
        db ch_48,ch_49,ch_50,ch_51,ch_52,ch_53,ch_54,ch_55     ; '0'..'7'
        db ch_56,ch_57,ch_58,ch_32,ch_32,ch_32,ch_32,ch_63     ; '8'..'?'
        db ch_32,ch_65,ch_66,ch_67,ch_68,ch_69,ch_70,ch_71     ; '@'..'G'
        db ch_72,ch_73,ch_74,ch_75,ch_76,ch_77,ch_78,ch_79     ; 'H'..'O'
        db ch_80,ch_81,ch_82,ch_83,ch_84,ch_85,ch_86,ch_87     ; 'P'..'W'
        db ch_88,ch_89,ch_90,ch_32,ch_32,ch_32,ch_32,ch_32     ; 'X'..'_'

txt_title:  db "SPACE FORCE C",0
txt_m0:     db "M0: HELLO CPC - MODE 0, 16 PENS",0
txt_tools:  db "RASM + IDSK + EXTENDED DSK",0

spin_timer: db SPIN_DELAY
spin_dir:   db 0

;------------------------------------------------------------------
; Γραφικά (assets/data, παράγονται από assets/src/make_assets.py)
;------------------------------------------------------------------

        include "../assets/data/palette.asm"
        include "../assets/data/ship.asm"
        include "../assets/data/tiles.asm"
        include "../assets/data/font.asm"

code_end:

;------------------------------------------------------------------
; Μεταβλητές χωρίς αρχική τιμή (δεν γράφονται στο αρχείο)
;------------------------------------------------------------------

        align 2
line_tab    equ $               ; 200 x dw
bg_map      equ line_tab+400    ; BG_ROWS*BG_COLS bytes
keymap      equ bg_map+BG_ROWS*BG_COLS  ; 10 bytes

        assert keymap+10 < #C000-#100, "code + data overlap the stack"

; Το rasm γράφει το αρχείο κατευθείαν σε Extended DSK, με AMSDOS header
; (load = exec = #1000 από το RUN). Η διαδρομή είναι ως προς τη ρίζα του
; repo, απ' όπου τρέχει το Makefile. Με -DSNAPSHOT=1 βγαίνει αντί γι'
; αυτό snapshot (.sna) που ξεκινάει κατευθείαν στο start.
        ifndef SNAPSHOT
        save "SFC.BIN",#1000,code_end-#1000,DSK,"build/SpaceForceC.dsk"
        endif
