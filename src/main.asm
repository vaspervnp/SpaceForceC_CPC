; main.asm — Space Force C, M3: multi-directional scrolling
;
; Το σκάφος κινείται με κέρσορες / QAOP / joystick σε χάρτη 64x48
; πλακιδίων (4 οθόνες επί 2) και η κάμερα το ακολουθεί με hardware scroll
; (scroll.asm), σε double buffering, κλειδωμένο στα 25 FPS. Fire (Space /
; joystick) αλλάζει κόσμο (space <-> earth), ESC = παύση.
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
SHIP_MAX_X      equ WORLD_W-SHIP_W
SHIP_MAX_Y      equ WORLD_H-SHIP_H
SHIP_WORLD_EARTH equ 8          ; ship_earth_n - ship_space_n

; Η κάμερα κινείται όταν το σκάφος πλησιάσει την άκρη της οθόνης.
CAM_MARGIN_X    equ 24          ; bytes
CAM_MARGIN_Y    equ 64          ; γραμμές

SHIP_START_X    equ WORLD_W/2-SHIP_W/2
SHIP_START_Y    equ 180
CAM_START_X     equ (SHIP_START_X-(VIEW_W-SHIP_W/2))/2  ; σκάφος στη μέση της οθόνης
CAM_START_Y     equ (SHIP_START_Y-100)/8

start:
        di
        ld sp,STACK_TOP
        ld bc,#7F00+GA_RAM_C0
        out (c),c
        ld bc,#7F00+GA_MODE0
        out (c),c
        call install_interrupts ; πριν από όλα: το copy_half κάνει EI
        call set_palette
        call make_line_table
        call make_row40
        call make_halftiles
        call make_map

        ; και οι δύο σελίδες ξεκινούν με όλη την κάμερα ζωγραφισμένη
        ld a,#C0
        call init_page
        ld a,#80
        call init_page
        ld a,(cam_x)
        ld c,a
        ld a,(cam_y)
        ld b,a
        call cell_ma
        ld a,#C0                ; δείξε τη #C0, ζωγράφιζε στη #80
        call show_page
        xor a                   ; η αρχικοποίηση δεν μετράει ως καρέ
        ld (vbl_count),a

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
        jr z,.run
        call flip               ; παύση: ίδια εικόνα, δείξε την άλλη σελίδα
        jr main_loop
.run:
        ld a,(input_new)
        and IN_FIRE
        jr z,.nofire
        ld a,(ship_world)
        xor SHIP_WORLD_EARTH
        ld (ship_world),a
.nofire:
        call move_ship
        call update_camera
        call page_buf           ; IX = η σελίδα που ζωγραφίζουμε

        PROFILE_BORDER HW_BRIGHT_BLUE   ; σβήσιμο (με την παλιά κάμερα)
        ld c,(ix+BUF_OX)
        ld l,(ix+BUF_OY)
        ld h,(ix+BUF_OY+1)
        ld d,SHIP_H
        ld e,SHIP_W
        call restore_world_rect

        PROFILE_BORDER HW_MAGENTA       ; scroll: στήλες/σειρές που μπαίνουν
        call scroll_buffer

        PROFILE_BORDER HW_RED           ; sprites
        call draw_ship
        ld a,(ship_x)
        ld (ix+BUF_OX),a
        ld hl,(ship_y)
        ld (ix+BUF_OY),l
        ld (ix+BUF_OY+1),h

        ld a,(cam_x)
        ld c,a
        ld a,(cam_y)
        ld b,a
        call cell_ma
        ld (show_ma),hl

        ld hl,(frames)
        inc hl
        ld (frames),hl

        PROFILE_BORDER HW_BLACK         ; αναμονή για το VSYNC
        call flip
        jp main_loop

;------------------------------------------------------------------

; in: A = σελίδα
init_page:
        ld (draw_page),a
        call clear_page
        call page_buf
        ld a,(cam_x)
        ld (ix+BUF_CX),a
        ld a,(cam_y)
        ld (ix+BUF_CY),a
        ld a,(ship_x)
        ld (ix+BUF_OX),a
        ld hl,(ship_y)
        ld (ix+BUF_OY),l
        ld (ix+BUF_OY+1),h
        jp draw_view

; out: IX -> κατάσταση της σελίδας που ζωγραφίζουμε
page_buf:
        ld ix,bufs
        ld a,(draw_page)
        cp #C0
        ret nz
        ld ix,bufs+BUF_SIZE
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
.up:    ld hl,(ship_y)
        ld de,SPEED_Y
        bit 0,c                 ; IN_UP
        jr z,.down
        or a
        sbc hl,de
        jr nc,.down
        ld hl,0
.down:  bit 1,c                 ; IN_DOWN
        jr z,.store
        add hl,de
        push hl
        ld de,SHIP_MAX_Y+1
        or a
        sbc hl,de
        pop hl
        jr c,.store
        ld hl,SHIP_MAX_Y
.store: ld (ship_y),hl
        ret

; Μετακινεί την κάμερα ένα βήμα το πολύ ανά άξονα, όταν το σκάφος μπει στο
; περιθώριο. Η κάμερα (2 bytes, 8 γραμμές ανά βήμα) είναι πιο γρήγορη από το
; σκάφος (1 byte, 4 γραμμές), οπότε το προλαβαίνει πάντα.
update_camera:
        ld a,(cam_x)
        add a,a
        ld b,a
        ld a,(ship_x)
        sub b                   ; x στην οθόνη (bytes)
        cp CAM_MARGIN_X
        jr nc,.notleft
        ld a,(cam_x)
        or a
        jr z,.vert
        dec a
        ld (cam_x),a
        jr .vert
.notleft:
        cp VIEW_W*2-SHIP_W-CAM_MARGIN_X+1
        jr c,.vert
        ld a,(cam_x)
        cp CAM_MAX_X
        jr nc,.vert
        inc a
        ld (cam_x),a
.vert:  ld a,(cam_y)
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ex de,hl
        ld hl,(ship_y)
        or a
        sbc hl,de
        ld a,l                  ; y στην οθόνη (γραμμές)
        cp CAM_MARGIN_Y
        jr nc,.notup
        ld a,(cam_y)
        or a
        ret z
        dec a
        ld (cam_y),a
        ret
.notup: cp VIEW_H*8-SHIP_H-CAM_MARGIN_Y+1
        ret c
        ld a,(cam_y)
        cp CAM_MAX_Y
        ret nc
        inc a
        ld (cam_y),a
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
.got:   ld a,(ship_x)
        ld c,a
        ld de,(ship_y)
        ld b,SHIP_H
        ld a,SHIP_W
        jp blit_world

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


;------------------------------------------------------------------

        include "hw.asm"
        include "screen.asm"
        include "scroll.asm"
        include "map.asm"
        ; text.asm + font.asm: ξαναμπαίνουν με το HUD (split screen)

; Γραφικά (assets/data, παράγονται από assets/src/make_assets.py)
        include "../assets/data/palette.asm"
        include "../assets/data/ship.asm"
        include "../assets/data/tiles.asm"

;------------------------------------------------------------------
; Μεταβλητές με αρχική τιμή
;------------------------------------------------------------------

ship_x:      db SHIP_START_X
ship_y:      dw SHIP_START_Y
ship_dir:    db ship_space_n
ship_world:  db 0
cam_x:       db CAM_START_X
cam_y:       db CAM_START_Y
bufs:        ds 2*BUF_SIZE      ; σελίδα #80, σελίδα #C0
show_ma:     dw 0
draw_page:   db #80
paused:      db 0
input:       db 0
input_new:   db 0
vbl_count:   db 0
frames:      dw 0
late_frames: dw 0
bw_x:        db 0               ; blit_world
bw_y:        dw 0
bw_h:        db 0
rect_x:      db 0               ; fill_map_rect
rect_y:      db 0
rect_w:      db 0
rect_h:      db 0

code_end:

;------------------------------------------------------------------
; Μεταβλητές χωρίς αρχική τιμή (δεν γράφονται στο αρχείο)
;------------------------------------------------------------------

line_tab    equ code_end                ; 200 x dw
row40       equ line_tab+400            ; MAP_H x dw
keymap      equ row40+2*MAP_H           ; 10 bytes
bg_map      equ (keymap+10+255)&#FF00   ; MAP_W*MAP_H, στοιχισμένο σε 256
halftiles   equ bg_map+MAP_W*MAP_H      ; 512 bytes, στοιχισμένο σε 256
ram_end     equ halftiles+512

        assert ram_end <= #4000, "code + data overflow into the bank window"

; Το rasm γράφει το αρχείο κατευθείαν σε Extended DSK, με AMSDOS header
; (load = exec = #1000 από το RUN). Η διαδρομή είναι ως προς τη ρίζα του
; repo, απ' όπου τρέχει το Makefile. Με -DSNAPSHOT=1 βγαίνει αντί γι'
; αυτό snapshot (.sna) που ξεκινάει κατευθείαν στο start.
        ifndef SNAPSHOT
        save "SFC.BIN",#1000,code_end-#1000,DSK,"build/SpaceForceC.dsk"
        endif
