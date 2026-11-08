; main.asm — Space Force C, M4: sprite engine
;
; Το σκάφος κινείται με κέρσορες / QAOP / joystick σε χάρτη 64x48
; πλακιδίων (4 οθόνες επί 2) και η κάμερα το ακολουθεί με hardware scroll
; (scroll.asm), σε double buffering, κλειδωμένο στα 25 FPS. Από κάτω, HUD
; σε split screen (hw.asm, screen.asm). 10 εχθροί κινούνται στον κόσμο
; (actors.asm) ως sprites με clip και save-under (sprites.asm). Fire
; (Space / joystick) αλλάζει κόσμο (space <-> earth), ESC = παύση.
; Με make PROFILE=1 το border δείχνει τον χρόνο κάθε φάσης (hw.asm).
;
; Memory map (RAM config C0 σε όλο το παιχνίδι, εκτός από τις προσβάσεις
; στα banks):
;   #0000-#003F  vectors (IM 1: JP int_handler στο #38)
;   #0040-#0FFF  stack (από το #1000 προς τα κάτω)
;   #1000-#3FFF  κώδικας + μόνιμα δεδομένα (12K)
;   #4000-#7FFF  παράθυρο banks. Δύο ρυθμίσεις μνήμης:
;                C4 (RAM_WORLD, σχεδόν πάντα): το bank 4 = ο κόσμος
;                  #4000 χάρτης (3K), #4C00 μισά πλακίδια (512),
;                  #4E00- GFX4.BIN: πλακίδια, σκάφος (και ό,τι μπει)
;                C0 (RAM_HUD, μόνο όσο γράφεται το HUD): η φυσική
;                  σελίδα, με το HUD στα #x6C0-#x7FF κάθε block των 2K
;                Το DISC.BAS φορτώνει το GFX4.BIN κατευθείαν στο bank 4.
;   #8000-#BFFF  οθόνη, σελίδα 2
;   #C000-#FFFF  οθόνη, σελίδα 3

        ifdef SNAPSHOT
        buildsna                ; αλλιώς: save σε DSK, στο τέλος
        bankset 0
        endif

        org #1000
        run start

        include "macros.asm"

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
        RAM_WORLD
        call set_palette
        call make_row40
        call make_halftiles
        call make_map
        call init_actors
        call update_actors

        RAM_HUD
        call clear_hud
        call draw_hud_static
        RAM_WORLD

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
        call update_actors
        call page_buf           ; IX = η σελίδα που ζωγραφίζουμε

        PROFILE_BORDER HW_BRIGHT_BLUE   ; σβήσιμο (με την παλιά κάμερα)
        call sprites_restore

        PROFILE_BORDER HW_MAGENTA       ; scroll: στήλες/σειρές που μπαίνουν
        call scroll_buffer

        PROFILE_BORDER HW_RED           ; sprites
        call sprites_draw

        ld a,(cam_x)
        ld c,a
        ld a,(cam_y)
        ld b,a
        call cell_ma
        ld (show_ma),hl

        ld hl,(frames)
        inc hl
        ld (frames),hl

        PROFILE_BORDER HW_YELLOW        ; HUD: μία φορά ανά 16 καρέ
        ld a,(frames)
        and 15
        jr nz,.nohud
        RAM_HUD
        call draw_hud
        RAM_WORLD
.nohud:

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
        ld (ix+BUF_NREC),0
        ld hl,recs0
        ld de,save0
        ld a,(draw_page)
        cp #C0
        jr nz,.p80
        ld hl,recs1
        ld de,save1
.p80:   ld (ix+BUF_RECS),l
        ld (ix+BUF_RECS+1),h
        ld (ix+BUF_SAVE),e
        ld (ix+BUF_SAVE+1),d
        jp draw_view

draw_hud_static:
        ld hl,txt_title
        ld b,8
        ld c,0
        call print_str
        ld hl,txt_frames
        ld b,16
        ld c,0
        call print_str
        ld hl,txt_late
        ld b,16
        ld c,40
        jp print_str

draw_hud:
        ld hl,(frames)
        ld b,16
        ld c,14
        call print_u16
        ld hl,(late_frames)
        ld b,16
        ld c,50
        jp print_u16

txt_title:  db "SPACE FORCE C - M4 SPRITES",0
txt_frames: db "FRAMES",0
txt_late:   db "LATE",0

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
        include "sprites.asm"
        include "actors.asm"
        include "text.asm"

; Γραφικά (assets/data, παράγονται από assets/src/make_assets.py)
        include "../assets/data/palette.asm"
        include "../assets/data/font.asm"      ; το HUD γράφεται σε C0

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
int_idx:     db #80
game_r12:    db #20
game_r13:    db 0
frames:      dw 0
late_frames: dw 0
sp_x:        db 0               ; sprites.asm: το τρέχον sprite μετά το clip
sp_y:        dw 0
sp_w:        db 0
sp_h:        db 0
sp_skip:     db 0
sp_left:     db 0
sp_right:    db 0
sp_top:      db 0
sp_src:      dw 0
sp_cur:      dw 0
sp_vy0:      dw 0
sp_vyl:      dw 0
sp_ylast:    dw 0
line_y:      dw 0
line_n:      db 0
save_ptr:    dw 0
rec_ptr:     dw 0
rect_x:      db 0               ; fill_map_rect
rect_y:      db 0
rect_w:      db 0
rect_h:      db 0

code_end:

;------------------------------------------------------------------
; Μεταβλητές χωρίς αρχική τιμή (δεν γράφονται στο αρχείο)
;------------------------------------------------------------------

row40       equ code_end                ; MAP_H x dw
keymap      equ row40+2*MAP_H           ; 10 bytes
spr_table   equ keymap+10               ; SPR_MAX x SPR_SIZE
enemies     equ spr_table+SPR_MAX*SPR_SIZE      ; ENEMY_N x EN_SIZE
recs0       equ enemies+ENEMY_N*EN_SIZE ; εγγραφές sprites, σελίδα #80
recs1       equ recs0+SPR_MAX*REC_SIZE  ; σελίδα #C0
save0       equ recs1+SPR_MAX*REC_SIZE  ; bytes κάτω από τα sprites, #80
save1       equ save0+SAVE_SIZE         ; #C0
ram_end     equ save1+SAVE_SIZE

        assert ram_end <= #4000, "code + data overflow into the bank window"

;------------------------------------------------------------------
; Bank 4 (RAM_WORLD, στο #4000-#7FFF)
;------------------------------------------------------------------

bg_map      equ #4000                   ; MAP_W*MAP_H, στοιχισμένο σε 256
halftiles   equ #4C00                   ; 512, στοιχισμένο σε 256
GFX4_START  equ #4E00

        ifdef SNAPSHOT
        bank 4                  ; το rasm ξεκινάει το bank από το πρώτο org του
        org #4000
        ds GFX4_START-#4000
        endif
        org GFX4_START
gfx4_data:
        include "../assets/data/tiles.asm"
        include "../assets/data/ship.asm"
        include "../assets/data/enemies.asm"
gfx4_end:

        assert bg_map+MAP_W*MAP_H <= halftiles, "map overlaps halftiles"
        assert halftiles+512 <= GFX4_START, "halftiles overlap GFX4"
        assert gfx4_end <= #8000, "bank 4 is full"

; Το rasm γράφει το αρχείο κατευθείαν σε Extended DSK, με AMSDOS header
; (load = exec = #1000 από το RUN). Η διαδρομή είναι ως προς τη ρίζα του
; repo, απ' όπου τρέχει το Makefile. Με -DSNAPSHOT=1 βγαίνει αντί γι'
; αυτό snapshot (.sna) που ξεκινάει κατευθείαν στο start.
        ifndef SNAPSHOT
        save "SFC.BIN",#1000,code_end-#1000,DSK,"build/SpaceForceC.dsk"
        save "GFX4.BIN",gfx4_data,gfx4_end-gfx4_data,DSK,"build/SpaceForceC.dsk"
        endif
