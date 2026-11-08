; main.asm — Space Force C, M2: engine core
;
; Το σκάφος κινείται με κέρσορες / QAOP / joystick πάνω από το φόντο, σε
; double buffering, κλειδωμένο στα 25 FPS. Fire (Space / joystick)
; αλλάζει κόσμο (space <-> earth), ESC = παύση. Το HUD δείχνει τα καρέ
; και πόσα άργησαν (late): αν το late ανεβαίνει, το καρέ δεν χωράει στα 40 ms.
; Με make PROFILE=1 το border δείχνει τον χρόνο κάθε φάσης (hw.asm).
;
; Memory map (RAM config C0 σε όλο το παιχνίδι, εκτός από τις προσβάσεις
; στα banks):
;   #0000-#003F  vectors (IM 1: JP int_handler στο #38)
;   #0040-#0FFF  stack (από το #1000 προς τα κάτω)
;   #1000-#3FFF  κώδικας + μόνιμα δεδομένα (12K)
;   #4000-#7FFF  παράθυρο banks: εδώ μπαίνει (#7FC4-#7FC7) ένα από τα 4
;                επιπλέον 16K του 6128, για τα δεδομένα των levels.
;                Γι' αυτό καμία οθόνη δεν είναι εδώ.
;   #8000-#BFFF  οθόνη, σελίδα 2
;   #C000-#FFFF  οθόνη, σελίδα 3

        ifdef SNAPSHOT
        buildsna                ; αλλιώς: save σε DSK, στο τέλος
        bankset 0
        endif

        org #1000
        run start

        include "profile.asm"

STACK_TOP       equ #1000
PPI_B           equ #F5         ; PPI port B: bit 0 = VSYNC

SPEED_X         equ 1           ; bytes/καρέ = 2 pixels = 4 μονάδες οθόνης
SPEED_Y         equ 4           ; γραμμές/καρέ = 4 μονάδες: ίδια ταχύτητα με το x
SHIP_MAX_X      equ BG_COLS*TILES_W-SHIP_W
SHIP_MAX_Y      equ BG_LINES-SHIP_H
SHIP_WORLD_EARTH equ 8          ; ship_earth_n - ship_space_n

HUD_Y           equ BG_LINES+4

start:
        di
        ld sp,STACK_TOP
        ld bc,#7F00+GA_RAM_C0
        out (c),c
        ld bc,#7F00+GA_MODE0
        out (c),c
        call set_palette
        call make_line_table
        call make_background

        ; και οι δύο σελίδες ξεκινούν ίδιες: φόντο + σταθερό HUD
        ld a,#C0
        ld (draw_page),a
        call init_page
        ld a,#80
        ld (draw_page),a
        call init_page
        ld a,#C0                ; δείξε τη #C0, ζωγράφιζε στη #80
        call show_page

        ld a,(ship_x)
        ld (old_pos+0),a
        ld (old_pos+2),a
        ld a,(ship_y)
        ld (old_pos+1),a
        ld (old_pos+3),a

        call install_interrupts

main_loop:
        PROFILE_BORDER HW_BRIGHT_GREEN  ; είσοδος + λογική
        call read_input
        ld a,(input_new)
        and IN_PAUSE
        jr z,.nopause
        ld a,(paused)
        xor 1
        ld (paused),a
.nopause:
        ld a,(paused)
        or a
        jr nz,.frame_end

        ld a,(input_new)
        and IN_FIRE
        jr z,.nofire
        ld a,(ship_world)
        xor SHIP_WORLD_EARTH
        ld (ship_world),a
.nofire:
        call move_ship

        PROFILE_BORDER HW_BRIGHT_BLUE   ; σβήσιμο
        call page_slot
        ld c,(hl)
        inc hl
        ld b,(hl)
        ld d,SHIP_H
        ld a,SHIP_W
        call restore_rect

        PROFILE_BORDER HW_RED           ; sprites
        call draw_ship
        call page_slot
        ld a,(ship_x)
        ld (hl),a
        inc hl
        ld a,(ship_y)
        ld (hl),a

        ld hl,(frames)
        inc hl
        ld (frames),hl

.frame_end:
        PROFILE_BORDER HW_YELLOW        ; HUD
        call draw_hud
        PROFILE_BORDER HW_BLACK         ; αναμονή για το VSYNC
        call flip
        jr main_loop

;------------------------------------------------------------------

init_page:
        call clear_page
        call draw_background
        ld hl,txt_title
        ld b,HUD_Y
        ld c,0
        call print_str
        ld hl,txt_frames
        ld b,HUD_Y+12
        ld c,0
        call print_str
        ld hl,txt_late
        ld b,HUD_Y+12
        ld c,40
        jp print_str

draw_hud:
        ld hl,(frames)
        ld b,HUD_Y+12
        ld c,14
        call print_u16
        ld hl,(late_frames)
        ld b,HUD_Y+12
        ld c,50
        jp print_u16

; out: HL -> old_pos της σελίδας που ζωγραφίζουμε (x, y)
page_slot:
        ld a,(draw_page)
        and #40                 ; #80 -> 0, #C0 -> #40
        rlca
        rlca                    ; 0 ή 1
        add a,a                 ; *2
        ld l,a
        ld h,0
        ld de,old_pos
        add hl,de
        ret

move_ship:
        ; κατεύθυνση από τα πατημένα βελάκια (αντίθετα = καμία αλλαγή)
        ld a,(input)
        and 15
        ld e,a
        ld d,0
        ld hl,dir_table
        add hl,de
        ld a,(hl)
        cp #FF
        jr z,.keep
        ld (ship_dir),a
.keep:
        ld a,(input)
        ld c,a
        ld hl,ship_x
        bit 2,c                 ; IN_LEFT
        jr z,.right
        ld a,(hl)
        sub SPEED_X
        jr nc,$+3
        xor a
        ld (hl),a
.right: bit 3,c                 ; IN_RIGHT
        jr z,.up
        ld a,(hl)
        add a,SPEED_X
        cp SHIP_MAX_X+1
        jr c,$+4
        ld a,SHIP_MAX_X
        ld (hl),a
.up:    ld hl,ship_y
        bit 0,c                 ; IN_UP
        jr z,.down
        ld a,(hl)
        sub SPEED_Y
        jr nc,$+3
        xor a
        ld (hl),a
.down:  bit 1,c                 ; IN_DOWN
        ret z
        ld a,(hl)
        add a,SPEED_Y
        cp SHIP_MAX_Y+1
        jr c,$+4
        ld a,SHIP_MAX_Y
        ld (hl),a
        ret

draw_ship:
        ld a,(ship_dir)
        ld hl,ship_world
        add a,(hl)
        ld hl,ship_gfx
        ld de,SHIP_SZ
        or a
        jr z,.got
.mul:   add hl,de
        dec a
        jr nz,.mul
.got:   ld a,(ship_y)
        ld b,a
        ld a,(ship_x)
        ld c,a
        ld d,SHIP_H
        ld a,SHIP_W
        jp blit_masked

; input & 15 (U=1 D=2 L=4 R=8) -> ship_space_*, #FF = κράτα την παλιά
dir_table:
        db #FF                  ; -
        db ship_space_n         ; U
        db ship_space_s         ; D
        db #FF                  ; U D
        db ship_space_w         ; L
        db ship_space_nw        ; U L
        db ship_space_sw        ; D L
        db ship_space_w         ; U D L
        db ship_space_e         ; R
        db ship_space_ne        ; U R
        db ship_space_se        ; D R
        db ship_space_e         ; U D R
        db #FF                  ; L R
        db ship_space_n         ; U L R
        db ship_space_s         ; D L R
        db #FF                  ; όλα

txt_title:  db "SPACE FORCE C - M2 ENGINE CORE",0
txt_frames: db "FRAMES",0
txt_late:   db "LATE",0

;------------------------------------------------------------------
; Μεταβλητές με αρχική τιμή
;------------------------------------------------------------------

ship_x:      db (SHIP_MAX_X/2)
ship_y:      db (SHIP_MAX_Y/2)
ship_dir:    db ship_space_n
ship_world:  db 0
old_pos:     ds 4               ; x,y ανά σελίδα (#80, #C0)
paused:      db 0
input:       db 0
input_new:   db 0
vbl_count:   db 0
frames:      dw 0
late_frames: dw 0

;------------------------------------------------------------------

        include "hw.asm"
        include "screen.asm"
        include "bg.asm"
        include "text.asm"

; Γραφικά (assets/data, παράγονται από assets/src/make_assets.py)
        include "../assets/data/palette.asm"
        include "../assets/data/ship.asm"
        include "../assets/data/tiles.asm"
        include "../assets/data/font.asm"

code_end:

;------------------------------------------------------------------
; Μεταβλητές χωρίς αρχική τιμή (δεν γράφονται στο αρχείο)
;------------------------------------------------------------------

line_tab    equ code_end                ; 200 x dw
bg_map      equ line_tab+400            ; BG_ROWS*BG_COLS bytes
keymap      equ bg_map+BG_ROWS*BG_COLS  ; 10 bytes
ram_end     equ keymap+10

        assert ram_end <= #4000, "code + data overflow into the bank window"

; Το rasm γράφει το αρχείο κατευθείαν σε Extended DSK, με AMSDOS header
; (load = exec = #1000 από το RUN). Η διαδρομή είναι ως προς τη ρίζα του
; repo, απ' όπου τρέχει το Makefile. Με -DSNAPSHOT=1 βγαίνει αντί γι'
; αυτό snapshot (.sna) που ξεκινάει κατευθείαν στο start.
        ifndef SNAPSHOT
        save "SFC.BIN",#1000,code_end-#1000,DSK,"build/SpaceForceC.dsk"
        endif
