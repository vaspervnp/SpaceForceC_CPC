; hazards.asm — ό,τι χτυπάει το σκάφος, και τα μυρμήγκια που σώζει
;
;   Laser Spaghetti    τυλίγει το σκάφος: μισή ταχύτητα για 3 s
;   Bureaucracy Beam   έντυπο Ε9 που κολλάει στο παρμπρίζ για 2 s: το
;                      σκάφος χάνεται από κάτω του (τύφλωση)
;   Bad Breath Torpedo zigzag γύρω από την πορεία της· κοστίζει ζωή
;   επαφή με εχθρό     κοστίζει ζωή, και ο εχθρός σκάει
;
; Μετά από ζημιά, 2 s άτρωτο (το σκάφος αναβοσβήνει). Με 0 ζωές: GAME OVER
; για 3 s και μετά ο πίνακας ρεκόρ. Το Bubble Wrap (items.asm) απορροφά ένα
; χτύπημα.

GUN_NONE        equ 0
GUN_E9          equ 1
GUN_SPAGHETTI   equ 2
GUN_TORPEDO     equ 3
GUN_JUNK        equ 4           ; το hardware του Lord Garbage-Can: κοστίζει ζωή

ESHOT_N         equ 5
ESHOT_SLOT      equ SHOT_SLOT+SHOT_N    ; 19-23

; Ανά εχθρικό βλήμα
ES_VX           equ 0
ES_VY           equ 1
ES_LIFE         equ 2
ES_KIND         equ 3
ES_DIR          equ 4
ES_STUCK        equ 5           ; Ε9 κολλημένο στο σκάφος: καρέ που μένουν
ES_SIZE         equ 6

ESHOT_LIFE      equ 60
STICK_TIME      equ 50          ; 2 s
SLOW_TIME       equ 75          ; 3 s
INVULN_TIME     equ 50          ; 2 s
GAMEOVER_TIME   equ 75
START_LIVES     equ 3

; Το «σώμα» του σκάφους για τις συγκρούσεις: λίγο μικρότερο από τα 12x24,
; ώστε να μη χτυπάει από μια γωνία που ίσα-ίσα ακούμπησε.
HIT_X0          equ 1
HIT_X1          equ SHIP_W-2
HIT_Y0          equ 4
HIT_Y1          equ SHIP_H-5

; Νέο εχθρικό βλήμα από το κέντρο του εχθρού IY.
; in: A = κατεύθυνση, (es_gun) = όπλο
spawn_enemy_shot:
        ld b,a
        push ix
        push iy
        ld ix,eshots
        ld hl,spr_table+ESHOT_SLOT*SPR_SIZE
        ld c,ESHOT_N
.find:  ld a,(ix+ES_LIFE)
        or a
        jr z,.free
        ld de,ES_SIZE
        add ix,de
        ld de,SPR_SIZE
        add hl,de
        dec c
        jr nz,.find
        pop iy
        pop ix
        ret                     ; όλα πετάνε
.free:  pop iy                  ; IY = εχθρός (θέση)
        push iy
        push hl
        ld a,sfx_eshot
        call play_sfx
        ld a,(es_gun)
        ld (ix+ES_KIND),a
        ld (ix+ES_DIR),b
        ld (ix+ES_LIFE),ESHOT_LIFE
        ld (ix+ES_STUCK),0
        ld a,b                  ; ταχύτητα = dir_vec (1 byte / 4 γραμμές)
        add a,a
        ld e,a
        ld d,0
        ld hl,dir_vec
        add hl,de
        ld a,(hl)
        ld (ix+ES_VX),a
        inc hl
        ld a,(hl)
        add a,a
        add a,a
        ld (ix+ES_VY),a
        ; θέση: κέντρο του εχθρού (8x8 -> -2 bytes, -4 γραμμές)
        ld a,(iy+SPR_W)
        srl a
        add a,(iy+SPR_X)
        sub 2
        ld c,a
        ld a,(iy+SPR_H)
        srl a
        sub 4
        ld e,a
        ld d,0
        ld l,(iy+SPR_Y)
        ld h,(iy+SPR_Y+1)
        add hl,de
        ex de,hl
        pop iy                  ; IY = το slot του βλήματος
        ld (iy+SPR_X),c
        ld (iy+SPR_Y),e
        ld (iy+SPR_Y+1),d
        ld (iy+SPR_W),SHOT_W
        ld (iy+SPR_H),SHOT_H
        ld (iy+SPR_BANK),BANK_WORLD
        pop iy
        pop ix
        ret

; Κίνηση των εχθρικών βλημάτων και τι κάνουν όταν βρουν το σκάφος.
update_enemy_shots:
        ld ix,eshots
        ld iy,spr_table+ESHOT_SLOT*SPR_SIZE
        ld b,ESHOT_N
.shot:  push bc
        ld (iy+SPR_FLAGS),0
        ld a,(ix+ES_LIFE)
        or a
        jp z,.next
        ld a,(ix+ES_STUCK)
        or a
        jr z,.fly
        ; --- Ε9 στο παρμπρίζ: ακολουθεί το σκάφος, πάνω από το θόλο
        dec (ix+ES_STUCK)
        jr nz,.stuck
        ld (ix+ES_LIFE),0
        jp .next
.stuck: ld a,(ship_x)
        inc a
        ld (iy+SPR_X),a
        ld hl,(ship_y)
        ld de,6
        add hl,de
        ld (iy+SPR_Y),l
        ld (iy+SPR_Y+1),h
        call .frame
        ld (iy+SPR_FLAGS),1
        jp .next

.fly:   dec (ix+ES_LIFE)
        jp z,.next
        ; x += vx (+ zigzag για την τορπίλη)
        call .zigzag            ; D = zx, E = zy
        ld a,(iy+SPR_X)
        add a,(ix+ES_VX)
        add a,d
        cp WORLD_W-SHOT_W+1
        jr nc,.kill
        ld (iy+SPR_X),a
        ld a,(ix+ES_VY)
        add a,e
        ld e,a
        add a,a
        sbc a,a
        ld d,a
        ld l,(iy+SPR_Y)
        ld h,(iy+SPR_Y+1)
        add hl,de
        bit 7,h
        jr nz,.kill
        push hl
        ld de,WORLD_H-SHOT_H+1
        or a
        sbc hl,de
        pop hl
        jr nc,.kill
        ld (iy+SPR_Y),l
        ld (iy+SPR_Y+1),h
        call .frame
        ld (iy+SPR_FLAGS),1
        ; --- πάνω στο σκάφος;
        ld a,(gameover)
        or a
        jr nz,.next
        ld a,(invuln)
        or a
        jr nz,.next
        call hits_ship          ; CF = 1: χτύπημα
        jr nc,.next
        ld a,(ix+ES_KIND)
        cp GUN_E9
        jr z,.e9
        cp GUN_SPAGHETTI
        jr z,.pasta
        call ship_hit           ; τορπίλη, hardware
        jr .kill
.pasta: ld a,SLOW_TIME
        ld (slowed),a
        ld hl,txt_pasta
        call set_status
        jr .kill
.e9:    ld (ix+ES_STUCK),STICK_TIME
        ld hl,txt_e9
        call set_status
        jr .next
.kill:  ld (ix+ES_LIFE),0
        ld (iy+SPR_FLAGS),0
.next:  ld de,ES_SIZE
        add ix,de
        ld de,SPR_SIZE
        add iy,de
        pop bc
        dec b
        jp nz,.shot
        ret

; Τορπίλη: κάθετα στην πορεία, ±1 ανά 4 καρέ (zigzag). out: D = x, E = y
.zigzag:
        ld de,0
        ld a,(ix+ES_KIND)
        cp GUN_TORPEDO
        ret nz
        ld a,(ix+ES_DIR)        ; κάθετη = κατεύθυνση + 2
        add a,2
        and 7
        add a,a
        ld e,a
        ld d,0
        ld hl,dir_vec
        add hl,de
        ld d,(hl)
        inc hl
        ld a,(hl)
        add a,a
        add a,a
        add a,a                 ; y: 8 γραμμές = 2 bytes
        ld e,a
        ld a,d
        add a,a                 ; x: 2 bytes
        ld d,a
        bit 2,(ix+ES_LIFE)
        ret z
        xor a                   ; αντίθετη πλευρά
        sub d
        ld d,a
        xor a
        sub e
        ld e,a
        ret

; Γραφικό του βλήματος IX στο sprite IY.
.frame: ld a,(ix+ES_KIND)
        cp GUN_JUNK
        jr nz,.nojunk
        ld a,(ix+ES_DIR)        ; δισκέτα, κασέτα ή οθόνη, από το bank 5
        and 3
        cp 3
        jr c,$+3
        xor a
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl               ; *64 = JUNK_SZ
        ld de,junk_gfx
        add hl,de
        ld (iy+SPR_GFX),l
        ld (iy+SPR_GFX+1),h
        ld (iy+SPR_BANK),BANK_ENEMIES
        ret
.nojunk:
        cp GUN_E9
        jr nz,.dirk
        ld a,(frames)           ; Ε9: στριφογυρίζει
        rrca
        and 3
        cp 3
        jr c,$+3
        xor a
        add a,sh_e90
        jr .gfx
.dirk:  ld c,sh_spaghetti_n0
        cp GUN_SPAGHETTI
        jr z,$+4
        ld c,sh_torpedo_n0
        ld a,(ix+ES_DIR)
        add a,c
.gfx:   ld l,a                  ; shots_gfx + καρέ*64
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,shots_gfx
        add hl,de
        ld (iy+SPR_GFX),l
        ld (iy+SPR_GFX+1),h
        ret

; CF = 1 αν το sprite IY ακουμπάει το σώμα του σκάφους.
hits_ship:
        ld a,(ship_x)           ; x: [X, X+w-1] με [ship_x+HIT_X0, ship_x+HIT_X1]
        add a,HIT_X0
        ld c,a
        ld a,(iy+SPR_W)
        dec a
        add a,(iy+SPR_X)        ; τελευταίο byte του sprite
        cp c
        jr c,.no
        ld a,(ship_x)
        add a,HIT_X1
        cp (iy+SPR_X)
        jr c,.no
        ld hl,(ship_y)          ; y, 16-bit
        ld de,HIT_Y0
        add hl,de
        ex de,hl                ; DE = πάνω όριο του σώματος
        ld l,(iy+SPR_Y)
        ld h,(iy+SPR_Y+1)
        ld c,(iy+SPR_H)
        dec c
        ld b,0
        add hl,bc               ; κάτω γραμμή του sprite
        or a
        sbc hl,de
        jr c,.no
        ld hl,(ship_y)
        ld de,HIT_Y1
        add hl,de               ; κάτω όριο του σώματος
        ld e,(iy+SPR_Y)
        ld d,(iy+SPR_Y+1)
        or a
        sbc hl,de
        jr c,.no
        scf
        ret
.no:    or a
        ret

; Επαφή σκάφους με ζωντανούς εχθρούς: ζημιά, και ο εχθρός σκάει.
check_ship_enemies:
        ld a,(gameover)
        or a
        ret nz
        ld a,(invuln)
        or a
        ret nz
        ld ix,enemies
        ld iy,spr_table
        ld b,ENEMY_N
.en:    push bc
        ld a,(ix+EN_STATE)
        cp ST_BOOM
        jr nc,.next
        call hits_ship
        jr nc,.next
        ld a,(ix+EN_KIND)       ; ο boss δεν σκάει από την επαφή
        cp KIND_BOSS
        call nz,enemy_explode
        call ship_hit
        pop bc
        ret                     ; ένα χτύπημα ανά καρέ φτάνει
.next:  ld de,EN_SIZE
        add ix,de
        ld de,SPR_SIZE
        add iy,de
        pop bc
        djnz .en
        ret

; Το σκάφος χάνει ζωή (αν δεν είναι άτρωτο).
ship_hit:
        ld a,(invuln)
        or a
        ret nz
        call use_shield
        ret c
        ld a,INVULN_TIME
        ld (invuln),a
        ld a,1
        ld (hud_dirty),a
        ld hl,lives
        dec (hl)
        jr z,.over
        ld a,sfx_hit
        call play_sfx
        ld hl,txt_ouch
        jp set_status
.over:  ld a,mus_gameover
        call play_music
        ld a,sfx_explode
        call play_sfx
        ld a,GAMEOVER_TIME
        ld (gameover),a
        ld hl,txt_gameover
        jp set_status

; Χρονόμετρα: άτρωτο, επιβράδυνση, game over. Μία φορά ανά καρέ.
update_hazards:
        ld hl,invuln
        ld a,(hl)
        or a
        jr z,$+3
        dec (hl)
        ld hl,slowed
        ld a,(hl)
        or a
        jr z,$+3
        dec (hl)
        ld hl,espresso
        call .tick
        ld hl,magnet
        call .tick
        ld hl,spray
        call .tick
        ld hl,gameover
        ld a,(hl)
        or a
        jr z,.ok
        dec (hl)
        jr nz,.ok
        ld a,1                  ; τέλος: το main_loop πάει στο game_end
        ld (game_done),a
.ok:    call check_ship_enemies
        call update_enemy_shots
        jp update_items

; Χρονόμετρο power-up (HL): στο 0 σβήνει η ένδειξη στο HUD.
.tick:  ld a,(hl)
        or a
        ret z
        dec (hl)
        ret nz
        ld a,1
        ld (hud_dirty),a
        ret



;------------------------------------------------------------------
; Μηνύματα στο HUD (γραμμή 24, αριστερά)
;------------------------------------------------------------------

STATUS_TIME     equ 50
STATUS_X        equ 0
STATUS_Y        equ 24

; in: HL = κείμενο (12 χαρακτήρες, με κενά)
set_status:
        ld (status_text),hl
        ld a,STATUS_TIME
        ld (status_timer),a
        ld a,1
        ld (status_new),a
        ret

; Σε RAM_HUD, όταν status_timer > 0.
update_status:
        ld a,(status_new)
        or a
        jr z,.wait
        xor a
        ld (status_new),a
        ld hl,txt_clear         ; τα κείμενα έχουν διαφορετικό μήκος
        ld b,STATUS_Y
        ld c,STATUS_X
        call print_str
        ld hl,(status_text)
        ld b,STATUS_Y
        ld c,STATUS_X
        call print_str
.wait:  ld hl,status_timer
        dec (hl)
        ret nz
        ld a,(gameover)         ; το GAME OVER μένει όσο διαρκεί
        or a
        jr z,.clear
        inc (hl)
        ret
.clear: ld hl,txt_clear
        ld b,STATUS_Y
        ld c,STATUS_X
        jp print_str

txt_pasta:    db "SPAGHETTI!  ",0
txt_e9:       db "E9 TAX FORM!",0
txt_ouch:     db "OUCH!       ",0
txt_gameover: db "GAME OVER   ",0
txt_clear:    db "             ",0       ; 13: όσο το μεγαλύτερο όνομα όπλου
