; boss.asm — ο boss της πίστας
;
; Βγαίνει όταν τελειώσει η λίστα εχθρών της πίστας (LV_BOSS στο header), στο
; slot του τελευταίου εχθρού. Μένει ένα slot του actors.asm με EN_KIND =
; KIND_BOSS, οπότε βλήματα και επαφή περνούν από τον ίδιο κώδικα. Τα γραφικά
; του (BOSS_GFX) και οι παράμετροι (BP_*, στο header) έρχονται με την πίστα:
; ο κώδικας είναι ένας, κάθε boss ένα σετ αριθμών (assets/src/levels.py).
;
; Από εκεί η κάμερα κλειδώνει και το σκάφος μένει μέσα στην οθόνη (arena).
; Ο boss αιωρείται στην κορυφή, ακολουθώντας το σκάφος οριζόντια. BOSS_WARN
; καρέ πριν από κάθε βολή δείχνει το καρέ της επίθεσης, ώστε να προλαβαίνεις
; να φύγεις, και πετάει βεντάλια 1, 3 ή 5 βλημάτων. Κάτω από τη μισή αντοχή
; αλλάζει ρυθμό και βεντάλια. Ανάλογα με το BP_DIVE κατεβαίνει και όλη την
; οθόνη (η επαφή κοστίζει ζωή). Όταν σκάσει: εκρήξεις για 3 s, 3 s για τα
; μυρμήγκια, και μετά το spawn_enemy τελειώνει την πίστα.
;
; EN_TIMER: 1 = καρέ επίθεσης, EN_COOL: καρέ ως τη βολή, EN_VX: μετρητής
; βολών, EN_VY: 1 = κατεβαίνει.

KIND_BOSS       equ 12          ; kind_info[6]
BOSS_W          equ 12          ; bytes δεδομένων (assets/src/bosses.py: 24x48)
BOSS_H          equ 48
BOSS_SZ         equ 1152        ; bytes ανά καρέ, με μάσκα
BOSS_GFX        equ #6000       ; bank 5: 2 καρέ, μετά 3 βλήματα 8x8
BOSS_SHOTS      equ BOSS_GFX+2*BOSS_SZ
BOSS_WARN       equ 25
BOSS_TOP        equ 8           ; γραμμές από την κορυφή της οθόνης
BOSS_BOTTOM     equ VIEW_H*8-BOSS_H-8   ; ως εκεί στην κάθοδο
BOSS_BOOM_TIME  equ 75
BOSS_SCORE      equ 2000
BAR_Y           equ 0           ; η πάνω γραμμή του HUD είναι ελεύθερη
BAR_LABEL_X     equ 0
BAR_X           equ 10          ; ως 15 κελιά

; Οι παράμετροι, στο header της πίστας (bank 4)
BP_HP           equ LEVEL_HDR+LV_PARAMS
BP_RAGE_AT      equ BP_HP+1     ; κάτω από εδώ: οι δεύτεροι ρυθμός και βεντάλια
BP_COOL         equ BP_HP+2
BP_FAN          equ BP_HP+3
BP_RAGE_COOL    equ BP_HP+4
BP_RAGE_FAN     equ BP_HP+5
BP_DIVE         equ BP_HP+6
BP_VY           equ BP_HP+7
BP_XMASK        equ BP_HP+8
BP_HELLO        equ BP_HP+9     ; 2 x 13 bytes

; Ο boss στο slot IX/IY. Από το spawn_enemy, όταν τελειώσουν οι εχθροί.
boss_start:
        ld (boss_ptr),ix
        ld a,1
        ld (boss_on),a
        ld (enemies_left),a
        ld (ix+EN_KIND),KIND_BOSS
        ld (ix+EN_STATE),ST_ALIVE
        ld a,(BP_HP)
        ld (ix+EN_HP),a
        ld a,(BP_COOL)
        ld (ix+EN_COOL),a
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
        ld de,BOSS_H
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
        ld (iy+SPR_FLAGS),SPR_BOSS
        ld a,mus_boss
        call play_music
        ld hl,BP_HELLO
        ld de,boss_hello
        ld bc,2*13
        ldir
        ld hl,boss_hello
        call set_status
        call boss_place
        jp boss_frame

; A = το x που θέλει: στο κέντρο του σκάφους, μέσα στον κόσμο
boss_target_x:
        ld a,(ship_x)
        sub (BOSS_W-SHIP_W)/2
        jr nc,$+3
        xor a
        cp WORLD_W-BOSS_W+1
        ret c
        ld a,WORLD_W-BOSS_W
        ret

; Κάθε καρέ, ζωντανός.
boss_update:
        ld a,(frames)           ; x: 1 byte όταν (καρέ & BP_XMASK) == 0
        ld hl,BP_XMASK
        and (hl)
        jr nz,.y
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
.move:  ld a,(BP_VY)
        ld c,a
        ld b,0
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
        ld hl,BP_COOL           ; ρυθμός και βεντάλια
        ld a,(BP_RAGE_AT)
        cp (ix+EN_HP)
        jr c,.calm
        ld hl,BP_RAGE_COOL
.calm:  ld a,(hl)
        ld (ix+EN_COOL),a
        inc hl
        ld a,(hl)
        ld (boss_fan),a
        inc (ix+EN_VX)
        ld a,(BP_DIVE)
        and (ix+EN_VX)
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
        ld a,(boss_fan)
        cp 3
        jp c,boss_frame
        ld a,1
        call .side
        ld a,-1
        call .side
        ld a,(boss_fan)
        cp 5
        jp c,boss_frame
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

; Το sprite IY στη θέση του, με το κούνημα του wave_table στο y, ανά 4 καρέ:
; τα 2 από τα 4 ο boss δεν ξαναζωγραφίζεται (sprites.asm), και είναι το
; μεγαλύτερο sprite του παιχνιδιού.
boss_place:
        ld a,(frames)
        and 3
        ret nz
        inc (ix+EN_PHASE)
        ld a,(ix+EN_PHASE)
        rrca                    ; το κούνημα ανά 8 καρέ
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
.put:   ld a,l                  ; άλλαξε κάτι; (κανένα καρέ ξανά χωρίς λόγο)
        xor (iy+SPR_Y)
        ld b,a
        ld a,h
        xor (iy+SPR_Y+1)
        or b
        ld b,a
        ld a,(ix+EN_X)
        xor (iy+SPR_X)
        or b
        ret z
        ld a,(ix+EN_X)
        ld (iy+SPR_X),a
        ld (iy+SPR_Y),l
        ld (iy+SPR_Y+1),h
; Η εικόνα του boss άλλαξε: οι σελίδες πρέπει να τον ξαναζωγραφίσουν.
boss_changed:
        ld hl,boss_ver
        ld a,(hl)
        inc a
        and #7F
        ld (hl),a
        ret

; Το γραφικό: καπάκι κλειστό ή ανοιχτό (bank 5).
boss_frame:
        ld hl,BOSS_GFX
        ld a,(ix+EN_TIMER)
        or a
        jr z,.set
        ld hl,BOSS_GFX+BOSS_SZ
.set:   ld a,l
        cp (iy+SPR_GFX)
        call nz,boss_set_changed
        ld (iy+SPR_GFX),l
        ld (iy+SPR_GFX+1),h
        ld (iy+SPR_W),BOSS_W
        ld (iy+SPR_H),BOSS_H
        ld (iy+SPR_BANK),BANK_ENEMIES
        ret

boss_set_changed:
        push hl
        call boss_changed
        pop hl
        ret

; Από το enemy_explode: η αντοχή του τελείωσε.
boss_explode:
        ld (iy+SPR_FLAGS),1
        call boss_changed
        ld (ix+EN_TIMER),BOSS_BOOM_TIME
        ld de,BOSS_SCORE
        call add_score
        ld a,1
        ld (hud_dirty),a
        ld hl,boss_bye
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
        ld b,BAR_Y
        ld c,BAR_LABEL_X
        jp print_str
.bar:   ld hl,(boss_ptr)
        ld de,EN_HP
        add hl,de
        ld a,(hl)
        add a,15                ; ένα κελί = 16 αντοχής (ως 240)
        rrca
        rrca
        rrca
        rrca
        and 15
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
        ld b,BAR_Y
        jp print_char

txt_boss:   db "BOSS",0
