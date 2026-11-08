; actors.asm — οι εχθροί: συμπεριφορά ανά τύπο, όπλα, ζημιά, θάνατος
;
; Κάθε τύπος (kind_info) ορίζει κίνηση, όπλο, αντοχή και πόσα μυρμήγκια
; αφήνει όταν σκάσει. Όταν τους χτυπήσει όπλο (weapons.asm) χάνουν αντοχή ή
; χορεύουν (Disco-Ray), σκάνε, και μετά από 3 s το slot παίρνει τον επόμενο
; της λίστας της πίστας (level.asm), έξω από την κάμερα. Τα εχθρικά βλήματα και τα μυρμήγκια είναι στο hazards.asm.
;
; Τα γραφικά τους είναι στο bank 5 (RAM_ENEMIES), οι εκρήξεις στο bank 4:
; το ίδιο slot αλλάζει bank όταν ο εχθρός σκάει.

ENEMY_N         equ 10          ; στα slots 0-9 του spr_table
SHIP_SLOT       equ SPR_MAX-1   ; το σκάφος ζωγραφίζεται τελευταίο, από πάνω

; Ανά εχθρό
EN_X            equ 0
EN_Y            equ 1           ; dw
EN_VX           equ 3           ; signed, bytes/καρέ
EN_VY           equ 4           ; signed, γραμμές/καρέ
EN_KIND         equ 5           ; πρώτο καρέ στο enemies_table
EN_STATE        equ 6
EN_TIMER        equ 7
EN_HP           equ 8
EN_COOL         equ 9           ; καρέ ως την επόμενη βολή
EN_PHASE        equ 10          ; μετρητής της κίνησης
EN_SIZE         equ 11

ST_ALIVE        equ 0
ST_DANCE        equ 1           ; Macarena: δεν κινείται, κουνιέται, μετά σκάει
ST_BOOM         equ 2
ST_DEAD         equ 3
ST_GONE         equ 4           ; η λίστα της πίστας τελείωσε για αυτό το slot

; Κινήσεις
AI_BOUNCE       equ 0           ; ευθεία, αναπηδά στα όρια του κόσμου
AI_WAVE         equ 1           ; οριζόντια, με κύμα πάνω-κάτω (σχηματισμοί)
AI_STATIC       equ 2           ; νάρκη: δεν κινείται
AI_CIRCLE       equ 3           ; κύκλοι: στρίβει 45 μοίρες ανά 8 καρέ
AI_CHASE        equ 4           ; κυνηγάει το σκάφος, στη μισή του ταχύτητα

DANCE_TIME      equ 25          ; 1 s
BOOM_TIME       equ 9           ; 3 καρέ έκρηξης x 3
DEAD_TIME       equ 75          ; 3 s ως τον επόμενο της λίστας
SPAWN_RETRY     equ 10          ; ο επόμενος θα έβγαινε μέσα στην κάμερα
SPAWN_SIZE      equ 7           ; x, 0, y (dw), vx, vy, kind
KILL_SCORE      equ 100
BANK_ENEMIES    equ #C5

; Ανά τύπο (kind/2): κίνηση, όπλο, αντοχή, μυρμήγκια, ρυθμός βολής (καρέ)
KI_AI           equ 0
KI_GUN          equ 1
KI_HP           equ 2
KI_ANTS         equ 3
KI_COOL         equ 4
KI_SIZE         equ 5

kind_info:
        db AI_WAVE,  GUN_E9,       1,1,90   ; grunt: η μάζα, σε σχηματισμούς
        db AI_STATIC,GUN_NONE,     1,0,0    ; νάρκη: σκάει στην επαφή
        db AI_CIRCLE,GUN_SPAGHETTI,2,1,70   ; δίσκος: Laser Spaghetti
        db AI_CHASE, GUN_TORPEDO,  3,2,60   ; κατσαρίδα-διοικητής
        db AI_BOUNCE,GUN_NONE,     1,1,0    ; κάλτσα (ή ό,τι φέρνει η πίστα)
        db AI_BOUNCE,GUN_NONE,     3,1,0    ; βαλίτσα (ή ό,τι φέρνει η πίστα)
        db AI_STATIC,GUN_NONE,     0,3,0    ; boss (όλα τα άλλα στο boss.asm)

; Οι πρώτοι ENEMY_N της λίστας της πίστας (level.asm), όπου κι αν είναι.
init_actors:
        ld a,ENEMY_N
        ld (enemies_left),a
        ld ix,enemies
        ld iy,spr_table
        ld b,ENEMY_N
.en:    push bc
        call spawn_now
        ld a,(ix+EN_STATE)
        or a                    ; ST_ALIVE
        call z,update_actors.frame_anim
        ld de,EN_SIZE
        add ix,de
        ld de,SPR_SIZE
        add iy,de
        pop bc
        djnz .en
        ret

; Ο εχθρός IX (slot IY) από την επόμενη θέση της λίστας της πίστας (bank 4,
; RAM_WORLD). Δεν βγαίνει μέσα στην κάμερα: τότε περιμένει λίγο. Όταν η
; λίστα τελειώσει μένει ST_GONE, και με τον τελευταίο η πίστα τελειώνει.
spawn_enemy:
        ld a,(spawn_left)
        or a
        jr z,.gone
        ld hl,(spawn_ptr)       ; x, y: δοκιμή στο sprite (που είναι σβηστό)
        ld a,(hl)
        ld (iy+SPR_X),a
        inc hl
        inc hl
        ld a,(hl)
        ld (iy+SPR_Y),a
        inc hl
        ld a,(hl)
        ld (iy+SPR_Y+1),a
        call on_camera
        jr c,spawn_now
        ld (ix+EN_STATE),ST_DEAD
        ld (ix+EN_TIMER),SPAWN_RETRY
        ret
.gone:  ld (ix+EN_STATE),ST_GONE
        ld (iy+SPR_FLAGS),0
        ld hl,enemies_left
        dec (hl)
        ret nz
        ld a,(boss_on)          ; όλοι τέλος: ο boss της πίστας, αν υπάρχει
        or a
        jr nz,.done
        ld a,(LEVEL_HDR+LV_BOSS)
        or a
        jp nz,boss_start
.done:  ld a,1
        ld (level_done),a
        ret

; Όπως το spawn_enemy, χωρίς τον έλεγχο της κάμερας (αρχή της πίστας).
spawn_now:
        ld hl,spawn_left
        ld a,(hl)
        or a
        jr z,spawn_enemy.gone
        dec (hl)
        ld hl,(spawn_ptr)
        push hl
        ld de,SPAWN_SIZE
        add hl,de
        ld (spawn_ptr),hl
        pop hl
        ld a,(hl)
        ld (ix+EN_X),a
        ld (iy+SPR_X),a
        inc hl
        inc hl                  ; (το 0 μετά το X)
        ld a,(hl)
        ld (ix+EN_Y),a
        ld (iy+SPR_Y),a
        inc hl
        ld a,(hl)
        ld (ix+EN_Y+1),a
        ld (iy+SPR_Y+1),a
        inc hl
        ld a,(hl)
        ld (ix+EN_VX),a
        inc hl
        ld a,(hl)
        ld (ix+EN_VY),a
        inc hl
        ld a,(hl)
        ld (ix+EN_KIND),a
        ld (ix+EN_STATE),ST_ALIVE
        ld (ix+EN_PHASE),0
        call kind_ptr
        inc hl
        inc hl
        ld a,(hl)               ; KI_HP
        ld (ix+EN_HP),a
        inc hl
        inc hl
        ld a,(hl)               ; KI_COOL
        ld (ix+EN_COOL),a
        ld (iy+SPR_FLAGS),1
        ret

; HL -> kind_info του εχθρού IX
kind_ptr:
        ld a,(ix+EN_KIND)
        srl a                   ; kind/2
        ld l,a
        add a,a
        add a,a
        add a,l                 ; *5
        ld l,a
        ld h,0
        ld de,kind_info
        add hl,de
        ret

; Κίνηση / κατάσταση + γραφή στο spr_table (θέση, γραφικό, μέγεθος, bank).
update_actors:
        ld ix,enemies
        ld iy,spr_table
        ld b,ENEMY_N
.en:    push bc
        ld a,(ix+EN_STATE)
        cp ST_DANCE
        jp z,.dance
        cp ST_BOOM
        jp z,.boom
        cp ST_DEAD
        jp z,.dead
        cp ST_GONE
        jp z,.next

        ; --- ζωντανός
        ld a,(ix+EN_KIND)
        cp KIND_BOSS
        jp z,.boss
        call .frame_anim
        call enemy_think        ; ταχύτητα ανάλογα με τον τύπο
        call enemy_gun
        ; x += vx, αναπήδηση στο [0, WORLD_W - w]
        ld a,(ix+EN_X)
        add a,(ix+EN_VX)
        ld c,a
        ld a,(iy+SPR_W)
        neg
        ld b,a                  ; B = 256 - w = WORLD_W - w
        ld a,c
        cp b
        jr c,.xok               ; 0 <= x < 256 - w (και το «αρνητικό» > B)
        ld a,(ix+EN_VX)
        neg
        ld (ix+EN_VX),a
        ld a,(ix+EN_X)
.xok:   ld (ix+EN_X),a
        ld (iy+SPR_X),a
        ; y += vy (16-bit), αναπήδηση στο [0, WORLD_H - h]
        ld l,(ix+EN_Y)
        ld h,(ix+EN_Y+1)
        ld a,(ix+EN_VY)
        ld e,a
        add a,a
        sbc a,a
        ld d,a
        add hl,de
        bit 7,h
        jr nz,.ybounce
        push hl
        ld a,(iy+SPR_H)
        ld e,a
        ld d,0
        add hl,de
        ld de,WORLD_H+1
        or a
        sbc hl,de
        pop hl
        jr c,.yok
.ybounce:
        ld a,(ix+EN_VY)
        neg
        ld (ix+EN_VY),a
        ld l,(ix+EN_Y)
        ld h,(ix+EN_Y+1)
.yok:   ld (ix+EN_Y),l
        ld (ix+EN_Y+1),h
        ld (iy+SPR_Y),l
        ld (iy+SPR_Y+1),h
        jp .next

.dance: ; --- Macarena: ένα byte δεξιά-αριστερά και animation ανά 2 καρέ
        ld a,(frames)
        add a,a
        add a,a
        call .frame_n
        ld a,(ix+EN_TIMER)
        rrca
        and 1
        add a,(ix+EN_X)
        ld (iy+SPR_X),a
        dec (ix+EN_TIMER)
        jr nz,.next
        call enemy_explode
        jr .next

.boss:  call boss_update
        jp .next

.boom:  ; --- έκρηξη 8x16 στο κέντρο του εχθρού, καρέ 0/1/2
        ld a,(ix+EN_KIND)
        cp KIND_BOSS
        jr nz,.small
        call boss_boom
        jr .boomed
.small: ld a,(ix+EN_TIMER)
        ld c,fx_booms0+2
        cp 4
        jr c,.bph
        dec c
        cp 7
        jr c,.bph
        dec c
.bph:   ld a,c
        call fx_frame
.boomed:
        dec (ix+EN_TIMER)
        jr nz,.next
        ld (ix+EN_STATE),ST_DEAD
        ld (ix+EN_TIMER),DEAD_TIME
        ld (iy+SPR_FLAGS),0
        ld de,KILL_SCORE
        call add_score
        ld a,1
        ld (hud_dirty),a
        call kind_ptr           ; μυρμήγκια εκεί που έσκασε
        inc hl
        inc hl
        inc hl
        ld a,(hl)               ; KI_ANTS
        call drop_items
        jr .next

.dead:  dec (ix+EN_TIMER)
        jr nz,.next
        call spawn_enemy
        ld a,(ix+EN_STATE)
        or a                    ; ST_ALIVE
        call z,.frame_anim

.next:  ld de,EN_SIZE
        add ix,de
        ld de,SPR_SIZE
        add iy,de
        pop bc
        dec b
        jp nz,.en
        ret

; Καρέ animation: kind + (frames/8 & 1)· από το .frame_n με άλλο ρυθμό.
.frame_anim:
        ld a,(ix+EN_KIND)
        cp KIND_BOSS
        jp z,boss_frame
        ld a,(frames)
.frame_n:
        rrca
        rrca
        rrca
        and 1
        add a,(ix+EN_KIND)
        RAM_ENEMIES             ; enemies_table στο bank 5
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl               ; *4: db w,h / dw offset
        ld de,enemies_table
        add hl,de
        ld a,(hl)
        ld (iy+SPR_W),a
        inc hl
        ld a,(hl)
        ld (iy+SPR_H),a
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld hl,enemies_gfx
        add hl,de
        ld (iy+SPR_GFX),l
        ld (iy+SPR_GFX+1),h
        ld (iy+SPR_BANK),BANK_ENEMIES
        RAM_WORLD
        ret

; Η ταχύτητα του εχθρού IX ανάλογα με την κίνηση του τύπου του.
enemy_think:
        call kind_ptr
        ld a,(hl)               ; KI_AI
        inc (ix+EN_PHASE)
        cp AI_WAVE
        jr z,.wave
        cp AI_CIRCLE
        jr z,.circle
        cp AI_CHASE
        jr z,.chase
        ret                     ; BOUNCE, STATIC: η ταχύτητα μένει ίδια

.wave:  ld a,(ix+EN_PHASE)      ; vy = wave[(phase/2) & 15]
        rrca
        and 15
        ld e,a
        ld d,0
        ld hl,wave_table
        add hl,de
        ld a,(hl)
        ld (ix+EN_VY),a
        ret

.circle:
        ld a,(ix+EN_PHASE)      ; κατεύθυνση = phase/8 (mod 8)
        rrca
        rrca
        and 7*2                 ; (phase/8 & 7) * 2
        ld e,a
        ld d,0
        ld hl,dir_vec
        add hl,de
        ld a,(hl)
        ld (ix+EN_VX),a
        inc hl
        ld a,(hl)
        add a,a                 ; y: 2 γραμμές (μισή ταχύτητα από το x)
        ld (ix+EN_VY),a
        ret

.chase: ld (ix+EN_VX),0         ; μία στις δύο: κίνηση προς το σκάφος
        ld (ix+EN_VY),0
        bit 0,(ix+EN_PHASE)
        ret z
        call aim_at_ship        ; B = dx, C = dy (-1/0/1)
        ld (ix+EN_VX),b
        ld a,c
        add a,a
        add a,a                 ; 4 γραμμές = ίδια ταχύτητα με 1 byte
        ld (ix+EN_VY),a
        ret

; Κατεύθυνση από τον εχθρό IX (slot IY) προς το κέντρο του σκάφους.
; out: B = dx, C = dy (-1/0/1), με νεκρή ζώνη ώστε να μην τρέμει
aim_at_ship:
        ld a,(ship_x)           ; dx = (ship_x + 3) - (x + w/2)
        add a,SHIP_W/2
        ld b,a
        ld a,(iy+SPR_W)
        srl a
        add a,(ix+EN_X)
        ld c,a
        ld a,b
        sub c                   ; carry = το σκάφος αριστερά
        ld b,0
        jr c,.left
        cp 3
        jr c,.ydir
        inc b
        jr .ydir
.left:  cp -2
        jr nc,.ydir
        dec b
.ydir:  ld hl,(ship_y)          ; dy = (ship_y + 12) - (y + h/2)
        ld de,SHIP_H/2
        add hl,de
        ld e,(iy+SPR_H)
        srl e
        ld d,0
        push hl
        ld l,(ix+EN_Y)
        ld h,(ix+EN_Y+1)
        add hl,de
        ex de,hl
        pop hl
        or a
        sbc hl,de               ; HL = dy
        ld c,0
        bit 7,h
        jr nz,.up
        ld a,h
        or a
        jr nz,.down
        ld a,l
        cp 12
        ret c
.down:  inc c
        ret
.up:    ld a,h
        inc a
        jr nz,.upgo
        ld a,l
        cp -11
        ret nc
.upgo:  dec c
        ret

; Βολή του εχθρού IX, αν ο τύπος του έχει όπλο και φαίνεται στην κάμερα.
enemy_gun:
        ld a,(ix+EN_COOL)
        or a
        jr z,.ready
        dec (ix+EN_COOL)
        ret
.ready: call kind_ptr
        inc hl
        ld a,(hl)               ; KI_GUN
        or a
        ret z
        ld (es_gun),a
        inc hl
        inc hl
        inc hl
        ld a,(hl)               ; KI_COOL
        ld (ix+EN_COOL),a
        call on_camera
        ret c
        call aim_at_ship
        ld a,b
        or c
        ret z                   ; ακριβώς πάνω του: τίποτα
        call aim_dir
        jp spawn_enemy_shot

; Κατεύθυνση 0-7 από το αποτέλεσμα του aim_at_ship: dir_from[(dy+1)*3 + dx+1]
aim_dir:
        ld a,c
        inc a
        ld e,a
        add a,a
        add a,e
        inc a
        add a,b
        ld e,a
        ld d,0
        ld hl,dir_from
        add hl,de
        ld a,(hl)
        ret

; (dx, dy) -> κατεύθυνση 0-7
dir_from:
        db 7,0,1                ; πάνω:  nw n ne
        db 6,0,2                ; μέση:  w  - e
        db 5,4,3                ; κάτω:  sw s se

; CF = 1 αν το sprite IY είναι έξω από την κάμερα (με λίγο περιθώριο).
on_camera:
        ld a,(cam_x)
        add a,a
        ld b,a                  ; πρώτο byte της κάμερας
        ld a,(iy+SPR_X)
        sub b
        ret c
        cp VIEW_W*2-4
        ccf
        ret c
        ld a,(cam_y)
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ex de,hl
        ld l,(iy+SPR_Y)
        ld h,(iy+SPR_Y+1)
        or a
        sbc hl,de
        ret c
        ld de,VIEW_H*8-8
        or a
        sbc hl,de
        ccf
        ret

; Κύμα για τους σχηματισμούς: γραμμές/καρέ
wave_table:
        db 0,1,1,2,2,2,1,1,0,-1,-1,-2,-2,-2,-1,-1

; Ο εχθρός IX (slot IY) σκάει: έκρηξη 8x16 στο κέντρο του.
enemy_explode:
        ld a,sfx_explode
        call play_sfx
        ld (ix+EN_STATE),ST_BOOM
        ld (ix+EN_TIMER),BOOM_TIME
        ld a,(ix+EN_KIND)
        cp KIND_BOSS
        jp z,boss_explode
        ld a,(iy+SPR_W)         ; X += (w - 4) / 2
        sub 4
        srl a
        add a,(ix+EN_X)
        ld (iy+SPR_X),a
        ld a,(iy+SPR_H)         ; Y += (h - 16) / 2
        sub 16
        srl a
        ld e,a
        ld d,0
        ld l,(ix+EN_Y)
        ld h,(ix+EN_Y+1)
        add hl,de
        ld (iy+SPR_Y),l
        ld (iy+SPR_Y+1),h
        ld a,fx_booms0
        jp fx_frame

; Ζημιά από όπλο του παίκτη: -1 αντοχή, στο 0 σκάει.
enemy_damage:
        dec (ix+EN_HP)
        ret nz
        jp enemy_explode
