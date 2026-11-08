; boss.asm — ο boss της πίστας: Lord Garbage-Can
;
; Βγαίνει όταν τελειώσει η λίστα εχθρών της πίστας (LV_BOSS στο header), στο
; slot του τελευταίου εχθρού. Μένει ένα slot του actors.asm με EN_KIND =
; KIND_BOSS, οπότε βλήματα και επαφή περνούν από τον ίδιο κώδικα.
;
; Από εκεί η κάμερα κλειδώνει και το σκάφος μένει μέσα στην οθόνη (arena).
; Ο boss αιωρείται στην κορυφή, ακολουθώντας το σκάφος οριζόντια. Το καπάκι
; ανοίγει BOSS_WARN καρέ πριν από κάθε βολή, ώστε να προλαβαίνεις να φύγεις,
; και πετάει τρία κομμάτια hardware σε βεντάλια· κάτω από τη μισή αντοχή
; πέντε, και πιο συχνά. Κάθε 4η βολή κατεβαίνει και όλη την οθόνη (η επαφή
; κοστίζει ζωή). Όταν σκάσει: εκρήξεις για 3 s, 3 s για τα μυρμήγκια, και
; μετά το spawn_enemy τελειώνει την πίστα.
;
; EN_TIMER: 1 = καπάκι ανοιχτό, EN_COOL: καρέ ως τη βολή, EN_VX: μετρητής
; βολών, EN_VY: 1 = κατεβαίνει.

KIND_BOSS       equ 12          ; kind_info[6]
BOSS_HP         equ 120
BOSS_COOL       equ 75
BOSS_RAGE_COOL  equ 50
BOSS_WARN       equ 25
BOSS_TOP        equ 8           ; γραμμές από την κορυφή της οθόνης
BOSS_BOTTOM     equ VIEW_H*8-BOSS1_H-8  ; ως εκεί στην κάθοδο
BOSS_VY         equ 2
BOSS_BOOM_TIME  equ 75
BOSS_SCORE      equ 5000
BAR_LABEL_X     equ 36          ; στο HUD, γραμμή 24
BAR_X           equ 46

; Ο boss στο slot IX/IY. Από το spawn_enemy, όταν τελειώσουν οι εχθροί.
boss_start:
        ld (boss_ptr),ix
        ld a,1
        ld (boss_on),a
        ld (enemies_left),a
        ld (ix+EN_KIND),KIND_BOSS
        ld (ix+EN_STATE),ST_ALIVE
        ld (ix+EN_HP),BOSS_HP
        ld (ix+EN_COOL),BOSS_COOL
        ld (ix+EN_TIMER),0
        ld (ix+EN_PHASE),0
        ld (ix+EN_VX),0
        ld (ix+EN_VY),0
        call boss_target_x
        ld (ix+EN_X),a
        ; μπαίνει από πάνω από την κάμερα, ή από κάτω αν δεν χωράει
        ld a,(cam_y)
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,BOSS1_H
        or a
        sbc hl,de
        jr nc,.y
        ld a,(cam_y)
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,VIEW_H*8
        add hl,de
.y:     ld (ix+EN_Y),l
        ld (ix+EN_Y+1),h
        ld (iy+SPR_FLAGS),1
        ld a,mus_boss
        call play_music
        ld hl,txt_trash
        call set_status
        call boss_place
        jp boss_frame

; A = το x που θέλει: στο κέντρο του σκάφους, μέσα στον κόσμο
boss_target_x:
        ld a,(ship_x)
        sub (BOSS1_W-SHIP_W)/2
        jr nc,$+3
        xor a
        cp WORLD_W-BOSS1_W+1
        ret c
        ld a,WORLD_W-BOSS1_W
        ret

; Κάθε καρέ, ζωντανός.
boss_update:
        ld a,(frames)           ; x: 1 byte ανά 2 καρέ
        rrca
        jr c,.y
        call boss_target_x
        cp (ix+EN_X)
        jr z,.y
        ld a,(ix+EN_X)
        jr c,.left
        inc a
        jr .x
.left:  dec a
.x:     ld (ix+EN_X),a
.y:     ld a,(cam_y)            ; στόχος: κορυφή της οθόνης, ή κάτω στην κάθοδο
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,BOSS_TOP
        ld a,(ix+EN_VY)
        or a
        jr z,$+5
        ld de,BOSS_BOTTOM
        add hl,de
        ld e,(ix+EN_Y)
        ld d,(ix+EN_Y+1)
        or a
        sbc hl,de               ; > 0: πρέπει να κατέβει
        ex de,hl
        jr nz,.move
        ld (ix+EN_VY),0         ; έφτασε: πίσω στην κορυφή
        jr .gun
.move:  ld bc,BOSS_VY
        jr nc,.down
        or a
        sbc hl,bc
        jr .ysave
.down:  add hl,bc
.ysave: ld (ix+EN_Y),l
        ld (ix+EN_Y+1),h
.gun:   call boss_place
        dec (ix+EN_COOL)
        jr z,.fire
        ld a,(ix+EN_COOL)
        cp BOSS_WARN
        jp nz,boss_frame
        ld (ix+EN_TIMER),1      ; το καπάκι: προειδοποίηση
        jp boss_frame
.fire:  ld (ix+EN_TIMER),0
        ld (ix+EN_COOL),BOSS_COOL
        inc (ix+EN_VX)
        ld a,(ix+EN_VX)
        and 3
        jr nz,.nodive
        ld (ix+EN_VY),1
.nodive:
        call on_camera
        jp c,boss_frame
        ld a,GUN_JUNK
        ld (es_gun),a
        call aim_at_ship
        call aim_dir
        ld (boss_dir),a
        call spawn_enemy_shot
        ld a,1
        call .side
        ld a,-1
        call .side
        ld a,(ix+EN_HP)
        cp BOSS_HP/2
        jp nc,boss_frame
        ld (ix+EN_COOL),BOSS_RAGE_COOL
        ld a,2
        call .side
        ld a,-2
        call .side
        jp boss_frame
.side:  ld hl,boss_dir
        add a,(hl)
        and 7
        jp spawn_enemy_shot

; Αντί για το update_camera όσο υπάρχει boss: η κάμερα μένει, το σκάφος μέσα
; στην οθόνη (χάνει την ταχύτητά του στην άκρη).
boss_arena:
        ld a,(cam_x)
        add a,a
        ld b,a                  ; αριστερή άκρη
        add a,VIEW_W*2-SHIP_W
        ld c,a                  ; δεξιά
        ld a,(ship_x)
        cp b
        jr c,.left
        cp c
        jr c,.vert
        jr z,.vert
        ld a,c
        jr .setx
.left:  ld a,b
.setx:  ld (ship_x),a
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl               ; *16
        ld (ship_x16),hl
        xor a
        ld (ship_vx),a
.vert:  ld a,(cam_y)
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ex de,hl                ; DE = πάνω
        ld hl,(ship_y)
        or a
        sbc hl,de
        jr c,.top               ; πάνω από την οθόνη
        ld bc,VIEW_H*8-SHIP_H
        or a
        sbc hl,bc
        ret c
        ret z
        ex de,hl                ; κάτω από την οθόνη: στο πάτο
        add hl,bc
        jr .sety
.top:   ex de,hl
.sety:  ld (ship_y),hl
        add hl,hl
        add hl,hl               ; *4
        ld (ship_y4),hl
        xor a
        ld (ship_vy),a
        ret

; Το sprite IY στη θέση του, με το κούνημα του wave_table στο y.
boss_place:
        ld a,(ix+EN_X)
        ld (iy+SPR_X),a
        inc (ix+EN_PHASE)
        ld a,(ix+EN_PHASE)
        rrca
        and 15
        ld e,a
        ld d,0
        ld hl,wave_table
        add hl,de
        ld e,(hl)
        ld a,e
        add a,a
        sbc a,a
        ld d,a
        ld l,(ix+EN_Y)
        ld h,(ix+EN_Y+1)
        ld a,h
        or a
        jr nz,.add
        ld a,l                  ; στην κορυφή του κόσμου, χωρίς κούνημα
        cp 8
        jr c,.put
.add:   add hl,de
.put:   ld (iy+SPR_Y),l
        ld (iy+SPR_Y+1),h
        ret

; Το γραφικό: καπάκι κλειστό ή ανοιχτό (bank 5).
boss_frame:
        ld hl,boss1_gfx+boss1_closed*BOSS1_SZ
        ld a,(ix+EN_TIMER)
        or a
        jr z,.set
        ld hl,boss1_gfx+boss1_open*BOSS1_SZ
.set:   ld (iy+SPR_GFX),l
        ld (iy+SPR_GFX+1),h
        ld (iy+SPR_W),BOSS1_W
        ld (iy+SPR_H),BOSS1_H
        ld (iy+SPR_BANK),BANK_ENEMIES
        ret

; Από το enemy_explode: η αντοχή του τελείωσε.
boss_explode:
        ld (ix+EN_TIMER),BOSS_BOOM_TIME
        ld hl,(score)
        ld de,BOSS_SCORE
        add hl,de
        ld (score),hl
        ld a,1
        ld (hud_dirty),a
        ld hl,txt_binned
        call set_status
        ld a,#FF
        jp play_music

; Κάθε καρέ όσο σκάει: μεγάλες εκρήξεις, κάθε φορά αλλού πάνω του.
boss_boom:
        ld a,(ix+EN_TIMER)
        rrca
        and 3
        add a,fx_boomb0
        call fx_frame
        ld a,(ix+EN_TIMER)
        and 7
        ret nz
        ld a,sfx_explode
        call play_sfx
        call rand
        and 7
        add a,(ix+EN_X)
        ld (iy+SPR_X),a
        call rand
        and 31
        ld e,a
        ld d,0
        ld l,(ix+EN_Y)
        ld h,(ix+EN_Y+1)
        add hl,de
        ld (iy+SPR_Y),l
        ld (iy+SPR_Y+1),h
        ret

; Η μπάρα αντοχής στο HUD, ένα κελί ανά καρέ το πολύ. Σε RAM_HUD.
draw_boss_bar:
        ld a,(boss_on)
        cp 2
        jr z,.bar
        ld a,2
        ld (boss_on),a
        ld hl,txt_boss
        ld b,STATUS_Y
        ld c,BAR_LABEL_X
        jp print_str
.bar:   ld hl,(boss_ptr)
        ld de,EN_HP
        add hl,de
        ld a,(hl)
        add a,7                 ; ένα κελί = 8 αντοχής
        rrca
        rrca
        rrca
        and 31
        ld hl,boss_cells
        cp (hl)
        ret z
        ld e,'*'
        jr nc,.grow
        dec (hl)
        ld a,(hl)
        ld e,' '
        jr .cell
.grow:  ld a,(hl)
        inc (hl)
.cell:  add a,a
        add a,BAR_X
        ld c,a
        ld a,e
        ld b,STATUS_Y
        jp print_char

txt_boss:   db "BOSS",0
txt_trash:  db "TRASH DAY!  ",0
txt_binned: db "RECYCLED!   ",0
