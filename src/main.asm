; main.asm — Space Force C, M12: πίστα 1 με τον boss της
;
; Το σκάφος κινείται με κέρσορες (ή όποια πλήκτρα ορίσει ο παίκτης) / joystick σε χάρτη 64x48
; πλακιδίων (4 οθόνες επί 2) και η κάμερα το ακολουθεί με hardware scroll
; (scroll.asm), σε double buffering, κλειδωμένο στα 25 FPS. Από κάτω, HUD
; σε split screen (hw.asm, screen.asm). 10 εχθροί κινούνται στον κόσμο
; (actors.asm) ως sprites με clip και save-under (sprites.asm). Το σκάφος
; έχει αδράνεια, φλόγα, καπνό στη Γη και πιλότους που ουρλιάζουν στις
; απότομες στροφές (ship.asm). Fire (Space / joystick) ρίχνει με το τρέχον
; όπλο, W = επόμενο όπλο (weapons.asm), E = διάστημα <-> Γη, ESC = παύση.
; Οι εχθροί αφήνουν μυρμήγκια και power-ups (items.asm).
; Με make PROFILE=1 το border δείχνει τον χρόνο κάθε φάσης (hw.asm).
;
; Memory map (RAM config C0 σε όλο το παιχνίδι, εκτός από τις προσβάσεις
; στα banks):
;   #0000-#003F  vectors (IM 1: JP int_handler στο #38)
;   #0040-#0F3F  save-under των sprites, 2 x 1920 (sprites.asm)
;   #0F40-#0FFF  stack (από το #1000 προς τα κάτω, 192 bytes)
;   #1000-#3FFF  κώδικας + μόνιμα δεδομένα (12K)
;   #4000-#7FFF  παράθυρο banks. Δύο ρυθμίσεις μνήμης:
;                C4 (RAM_WORLD, σχεδόν πάντα): το bank 4 = ο κόσμος
;                  #4000 χάρτης (3K), #4C00 μισά πλακίδια (512),
;                  #4E00- GFX4.BIN: πλακίδια, σκάφος, fx, βλήματα
;                C5 (RAM_ENEMIES, ανά sprite): GFX5.BIN, εχθροί, pickups
;                C7 (μόνο στο level_load): bank 7, οι πίστες (LEVELS.BIN)
;                C6 (μόνο στο sound_frame): bank 6, ο ήχος (SND6.BIN)
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
        ld hl,game_vars         ; οι αρχικές τιμές, για κάθε νέο παιχνίδι
        ld de,game_backup
        ld bc,GAME_VARS_SIZE
        ldir

title:
        ld sp,STACK_TOP
        call title_screen       ; ui.asm: επιστρέφει όταν πατηθεί fire

game_start:
        ld hl,game_backup       ; νέο παιχνίδι: όλα από την αρχή
        ld de,game_vars
        ld bc,GAME_VARS_SIZE
        ldir
        ifdef START_LEVEL       ; make START=n: από άλλη πίστα, για δοκιμή
        ld a,START_LEVEL-1
        else
        xor a
        endif
        ld (level),a
        ld hl,LIFE_EVERY
        ld (next_life),hl
        call energy_full
        ifndef START_LEVEL
        ld hl,cut_table         ; η ιστορία
        call cut_play
        endif
level_start:
        ld sp,STACK_TOP
        call game_init
main_loop:
        ld a,(game_done)
        or a
        jp nz,game_end
        ld a,(level_done)
        or a
        jp nz,level_end         ; ui.asm
        call sound_frame        ; μία φορά ανά καρέ, μετά το flip
        PROFILE_BORDER HW_BRIGHT_GREEN  ; είσοδος + λογική
        call read_input
        ld a,(input_new)
        and IN_PAUSE
        jr z,.nopause
        ld a,(paused)
        xor 1
        ld (paused),a
        RAM_HUD
        call draw_paused
        RAM_WORLD
.nopause:
        ld a,(paused)
        or a
        jr z,.run
        call flip               ; παύση: ίδια εικόνα, δείξε την άλλη σελίδα
        jr main_loop
.run:
        ifdef PROFILE           ; E: διάστημα <-> Γη, για δοκιμές
        ld a,(input_new)
        and IN_WORLD
        jr z,.noworld
        ld a,(ship_world)
        xor SHIP_WORLD_EARTH
        ld (ship_world),a
.noworld:
        endif
        call move_ship
        call update_weapons
        call update_camera
        call update_actors
        call update_hazards
        call update_ship_sprites
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
        ld a,(scream)
        or a
        jr z,.noscream
        RAM_HUD
        call update_scream
        RAM_WORLD
.noscream:
        ld a,(status_timer)
        or a
        jr z,.nostatus
        RAM_HUD
        call update_status
        RAM_WORLD
.nostatus:
        ld a,(energy)
        ld hl,energy_cells
        cp (hl)
        jr z,.noenergy
        RAM_HUD
        call draw_energy
        RAM_WORLD
.noenergy:
        ld a,(boss_on)
        or a
        jr z,.nobar
        RAM_HUD
        call draw_boss_bar
        RAM_WORLD
.nobar:
        ld a,(hud_dirty)
        or a
        jr z,.noscore
        RAM_HUD
        call draw_hud_game
        RAM_WORLD
.noscore:
        ifdef PROFILE           ; ο μετρητής των αργών καρέ
        ld a,(frames)
        and 15
        jr nz,.nohud
        RAM_HUD
        call draw_hud
        RAM_WORLD
.nohud:
        endif

        PROFILE_BORDER HW_BLACK         ; αναμονή για το VSYNC
        call flip
        jp main_loop

;------------------------------------------------------------------

; Αρχή πίστας: οι μεταβλητές από το game_backup (εκτός από όσα κρατάει ο
; παίκτης από πίστα σε πίστα), καθαρά sprites/βλήματα, η πίστα από το bank
; 7, η οθόνη της μετάβασης, HUD, και οι δύο σελίδες ζωγραφισμένες.
game_init:
        ld a,(energy)           ; (από πίστα σε πίστα)
        push af
        ld hl,(score)
        push hl
        ld hl,(ants_saved)
        push hl
        ld a,(lives)
        ld h,a
        ld a,(weapon)
        ld l,a
        push hl
        ld a,(baguette_level)
        ld h,a
        ld a,(engine)
        ld l,a
        push hl
        ld hl,game_backup
        ld de,game_vars
        ld bc,GAME_VARS_SIZE
        ldir
        pop hl
        ld a,l
        ld (engine),a
        ld a,h
        ld (baguette_level),a
        pop hl
        ld a,l
        ld (weapon),a
        ld a,h
        ld (lives),a
        pop hl
        ld (ants_saved),hl
        pop hl
        ld (score),hl
        pop af
        ld (energy),a
        ld hl,spr_table         ; sprites, εχθροί, βλήματα: όλα ελεύθερα
        ld de,spr_table+1
        ld bc,recs0-spr_table-1
        ld (hl),0
        ldir
        RAM_WORLD
        call level_load
        call level_intro        ; ui.asm
        ld a,(LEVEL_HDR+LV_SKY)
        call set_sky
        call init_actors
        call update_actors
        call update_ship_sprites
        call text_to_hud
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
        ret

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
        ld (ix+BUF_VER),#FF
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
        ld hl,txt_score
        ld b,8
        ld c,0
        call print_str
        call draw_hud_game
        ld hl,txt_lives
        ld b,16
        ld c,0
        call print_str
        ld hl,txt_ants
        ld b,16
        ld c,18
        call print_str
        ld hl,txt_energy_h
        ld b,16
        ld c,42
        ifdef PROFILE
        call print_str
        ld hl,txt_late
        ld b,0
        ld c,44
        jp print_str

draw_hud:
        ld hl,(late_frames)
        ld b,0
        ld c,54
        jp print_u16
        else
        jp print_str
        endif

; Σκορ και όπλο: μόνο όταν αλλάξουν (hud_dirty).
draw_hud_game:
        xor a
        ld (hud_dirty),a
        ld hl,(score)
        ld b,8
        ld c,12
        call print_u16
        ld a,(lives)
        add a,'0'
        ld b,16
        ld c,12
        call print_char
        ld hl,(ants_saved)
        ld b,16
        ld c,28
        call print_u16
        call draw_powerups
        jp draw_weapon

; «PAUSED» στη θέση των μηνυμάτων, ή πίσω ό,τι έδειχναν.
draw_paused:
        ld hl,txt_clear
        ld b,STATUS_Y
        ld c,STATUS_X
        call print_str
        ld a,(paused)
        or a
        jr z,.resume
        ld hl,txt_paused
        ld b,STATUS_Y
        ld c,STATUS_X
        jp print_str
.resume:
        ld a,(status_timer)     ; το μήνυμα που έτρεχε, ξανά
        or a
        ret z
        ld a,1
        ld (status_new),a
        ret

txt_paused: db "PAUSED",0
txt_score:  db "SCORE",0
txt_lives:  db "LIVES",0
txt_ants:   db "ANTS",0
txt_energy_h: db "ENERGY",0
        ifdef PROFILE
txt_late:   db "LATE",0
        endif

; out: IX -> κατάσταση της σελίδας που ζωγραφίζουμε
page_buf:
        ld ix,bufs
        ld a,(draw_page)
        cp #C0
        ret nz
        ld ix,bufs+BUF_SIZE
        ret

; Μετακινεί την κάμερα ένα βήμα το πολύ ανά άξονα, όταν το σκάφος μπει στο
; περιθώριο. Η κάμερα (2 bytes, 8 γραμμές ανά βήμα) είναι πιο γρήγορη από το
; σκάφος (1 byte, 4 γραμμές), οπότε το προλαβαίνει πάντα.
update_camera:
        ld a,(boss_on)          ; boss: κλειδωμένη (boss.asm)
        or a
        jp nz,boss_arena
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
        include "boss.asm"
        include "ship.asm"
        include "weapons.asm"
        include "hazards.asm"
        include "items.asm"
        include "text.asm"
        include "ui.asm"
        include "level.asm"

; Γραφικά (assets/data, παράγονται από assets/src/make_assets.py)
        include "../assets/data/palette.asm"
        include "../assets/data/font.asm"      ; το HUD γράφεται σε C0

;------------------------------------------------------------------
; Μεταβλητές με αρχική τιμή
;------------------------------------------------------------------

; Ό,τι ξεκινάει από την αρχή σε κάθε παιχνίδι (game_init): αντίγραφο στο
; game_backup στην εκκίνηση, πίσω από εκεί σε κάθε νέο παιχνίδι.
game_vars:
ship_x:      db SHIP_START_X     ; = ship_x16 / 16
ship_y:      dw SHIP_START_Y     ; = ship_y4 / 4
ship_x16:    dw SHIP_START_X*16
ship_y4:     dw SHIP_START_Y*4
ship_vx:     db 0
ship_vy:     db 0
thrust:      db #FF             ; κατεύθυνση της ώθησης, #FF = καμία
flame_phase: db 0
smoke_timer: db 1
smoke_next:  db 0
smoke_age:   ds SMOKE_N
scream:      db 0
scream_text: db 0
score:       dw 0
hud_dirty:   db 0
weapon:      db WP_DISCO
baguette_level: db 1
fire_cool:   db 0
shot_kind:   db 0
hit_x:       db 0
hit_y:       dw 0
es_gun:      db 0
lives:       db START_LIVES
ants_saved:  dw 0
invuln:      db 0
slowed:      db 0
gameover:    db 0
status_text: dw 0
status_timer: db 0
status_new:  db 0
shield:      db 0
espresso:    db 0
magnet:      db 0
spray:       db 0
spray_dir:   db 0
spray_cool:  db 1
engine:      db 0
item_dx:     db 0
item_cur:    db 0
item_timer:  ds ITEM_N
item_type:   ds ITEM_N          ; (ακριβώς μετά το item_timer)
ship_dir:    db ship_space_n
ship_world:  db 0
cam_x:       db CAM_START_X
cam_y:       db CAM_START_Y
paused:      db 0
game_done:   db 0
level_done:  db 0
spawn_left:  db 0               ; εχθροί της λίστας της πίστας που μένουν
spawn_ptr:   dw 0
enemies_left: db 0              ; slots που δεν έχουν τελειώσει (ST_GONE)
boss_on:     db 0               ; boss.asm: 0 = όχι ακόμα, 1 = μόλις, 2 = HUD έτοιμο
boss_cells:  db 0
boss_dir:    db 0
boss_fan:    db 0
boss_ptr:    dw 0
boss_ver:    db 0               ; αλλάζει όταν αλλάξει η εικόνα του boss
boss_drop:   db 0               ; η μπαταρία της μάχης δόθηκε
energy:      db 0               ; hazards.asm
energy_cells: db 0              ; όσα κελιά φαίνονται στο HUD
frames:      dw 0
late_frames: dw 0
game_vars_end:
GAME_VARS_SIZE equ game_vars_end-game_vars

bufs:        ds 2*BUF_SIZE      ; σελίδα #80, σελίδα #C0
show_ma:     dw 0
draw_page:   db #80
input:       db 0
input_new:   db 0
vbl_count:   db 0
int_idx:     db #80
game_r12:    db #20
game_r13:    db 0
level:       db 0               ; 0-7
difficulty:  db 0               ; 0 Easy, 1 Medium, 2 Hard: μένει από παιχνίδι σε παιχνίδι
next_life:   dw LIFE_EVERY      ; το σκορ της επόμενης ζωής (items.asm)
cut_fast:    db 0               ; ui.asm: οι σκηνές
cut_skip:    db 0
snd_ticks:   db 0               ; ήχος (hw.asm, sound.asm)
sfx_req:     db 0
music_req:   db 0
music_now:   db 0
text_page:   db HUD_PAGE        ; text.asm: πού γράφει το κείμενο
text_off:    dw HUD_OFFSET
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
save_limit:  dw 0
rec_ptr:     dw 0
rows_ptr:    dw 0
put_rows:    db 0
back_rows:   db 0
row_slow:    db 0

code_end:

;------------------------------------------------------------------
; Μεταβλητές χωρίς αρχική τιμή (δεν γράφονται στο αρχείο)
;------------------------------------------------------------------

row40       equ code_end                ; MAP_H x dw
keymap      equ row40+2*MAP_H           ; 10 bytes
spr_table   equ keymap+10               ; SPR_MAX x SPR_SIZE
enemies     equ spr_table+SPR_MAX*SPR_SIZE      ; ENEMY_N x EN_SIZE
shots       equ enemies+ENEMY_N*EN_SIZE ; SHOT_N x SH_SIZE
eshots      equ shots+SHOT_N*SH_SIZE    ; ESHOT_N x ES_SIZE
recs0       equ eshots+ESHOT_N*ES_SIZE  ; εγγραφές sprites, σελίδα #80
recs1       equ recs0+SPR_MAX*REC_SIZE  ; σελίδα #C0
game_backup equ recs1+SPR_MAX*REC_SIZE  ; GAME_VARS_SIZE
boss_hello  equ game_backup+GAME_VARS_SIZE      ; τα μηνύματα του boss, 2 x 13:
boss_bye    equ boss_hello+13                   ; το HUD γράφεται σε C0, όπου
ram_end     equ boss_bye+13                     ; το header δεν φαίνεται

; Τα bytes κάτω από τα sprites, στη χαμηλή μνήμη (κάτω από τη στοίβα)
save0       equ #0040                   ; σελίδα #80 (μετά τα vectors)
save1       equ save0+SAVE_SIZE         ; σελίδα #C0
        assert save1+SAVE_SIZE <= STACK_TOP-#C0, "save-under overlaps the stack"

        assert ram_end <= #4000, "code + data overflow into the bank window"

; Το rasm γράφει κάθε αρχείο κατευθείαν σε Extended DSK, με AMSDOS header,
; ΑΜΕΣΩΣ μετά το κομμάτι του: το save διαβάζει από το τρέχον bank του rasm.
; Το SFC.BIN: load = exec = #1000 (από το RUN). Η διαδρομή είναι ως προς τη
; ρίζα του repo, απ' όπου τρέχει το Makefile. Με -DSNAPSHOT=1 βγαίνει αντί
; γι' αυτό snapshot (.sna) που ξεκινάει κατευθείαν στο start.
        ifndef SNAPSHOT
        save "SFC.BIN",#1000,code_end-#1000,DSK,"build/SpaceForceC.dsk"
        endif

;------------------------------------------------------------------
; Bank 4 (RAM_WORLD, στο #4000-#7FFF)
;------------------------------------------------------------------

bg_map      equ #4000                   ; MAP_W*MAP_H, στοιχισμένο σε 256
halftiles   equ #4C00                   ; 512, στοιχισμένο σε 256
GFX4_START  equ #4E00

        bank 4                  ; το rasm ξεκινάει το bank από το πρώτο org του
        org #4000
        ds GFX4_START-#4000
        org GFX4_START
gfx4_data:
        include "../assets/data/tiles.asm"
        include "../assets/data/ship.asm"
        include "../assets/data/fx.asm"
        include "../assets/data/shots.asm"
gfx4_end:

        assert bg_map+MAP_W*MAP_H <= halftiles, "map overlaps halftiles"
        assert halftiles+512 <= GFX4_START, "halftiles overlap GFX4"
        assert gfx4_end <= LEVEL_HDR, "bank 4: GFX4 overlaps the level header"
        ifndef SNAPSHOT
        save "GFX4.BIN",gfx4_data,gfx4_end-gfx4_data,DSK,"build/SpaceForceC.dsk"
        endif

;------------------------------------------------------------------
; Bank 5 (RAM_ENEMIES): οι εχθροί της πίστας
;------------------------------------------------------------------

        bank 5
        org #4000
gfx5_data:
        include "../assets/data/enemies.asm"
        include "../assets/data/pickups.asm"    ; μυρμήγκια (και τα power-ups του M8)
        include "uitext.asm"
gfx5_end:

        assert gfx5_end <= BOSS_GFX, "bank 5: GFX5 overlaps the boss"
        assert BOSS_GFX+2*BOSS_SZ+3*64 <= #8000, "bank 5 is full"
        ifndef SNAPSHOT
        save "GFX5.BIN",gfx5_data,gfx5_end-gfx5_data,DSK,"build/SpaceForceC.dsk"
        endif

;------------------------------------------------------------------
; Bank 7 (C7): όλες οι πίστες, συμπιεσμένες (level.asm)
;------------------------------------------------------------------

        bank 7
        org #4000
lvl7_data:
        include "../assets/data/levels.asm"
lvl7_end:

        assert lvl7_end <= #8000, "bank 7 is full"
        ifndef SNAPSHOT
        save "LEVELS.BIN",lvl7_data,lvl7_end-lvl7_data,DSK,"build/SpaceForceC.dsk"
        endif

;------------------------------------------------------------------
; Bank 6 (C6): ο player του ήχου και η μουσική
;------------------------------------------------------------------

        bank 6
        org #4000
snd6_data:
        include "sound.asm"
        include "../assets/data/levels2.asm"
snd6_end:

        assert snd6_end <= #8000, "bank 6 is full"
        ifndef SNAPSHOT
        save "SND6.BIN",snd6_data,snd6_end-snd6_data,DSK,"build/SpaceForceC.dsk"
        endif

