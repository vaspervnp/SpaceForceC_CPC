; actors.asm — εχθροί του demo: κινούνται ευθεία και αναπηδούν στα όρια του
; κόσμου, με δύο καρέ animation. Όταν τους χτυπήσει όπλο (weapons.asm)
; χορεύουν (Disco-Ray) ή σκάνε κατευθείαν, και μετά από 3 s ξαναβγαίνουν
; στη θέση που ξεκίνησαν. Η πραγματική AI είναι M7.
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
EN_SIZE         equ 8

ST_ALIVE        equ 0
ST_DANCE        equ 1           ; Macarena: δεν κινείται, κουνιέται, μετά σκάει
ST_BOOM         equ 2
ST_DEAD         equ 3

DANCE_TIME      equ 25          ; 1 s
BOOM_TIME       equ 9           ; 3 καρέ έκρηξης x 3
DEAD_TIME       equ 75          ; 3 s ως την επανεμφάνιση
KILL_SCORE      equ 100
BANK_ENEMIES    equ #C5

        macro ENEMY x,y,vx,vy,kind
        db {x},0
        dw {y}
        db {vx},{vy},{kind}
        mend

enemy_init:
        ENEMY 110,150, 1, 2,en_grunt0
        ENEMY 140,150,-1, 2,en_grunt0
        ENEMY 100,220, 1,-2,en_saucer0
        ENEMY 150,210,-1,-4,en_roach0
        ENEMY  90,180, 1, 0,en_sock0
        ENEMY 160,180,-1, 0,en_suitcase0
        ENEMY 120,120, 0, 2,en_mine0
        ENEMY 130,240, 0,-2,en_grunt0
        ENEMY  60, 60, 1, 4,en_saucer0
        ENEMY 200,300,-1,-2,en_roach0

init_actors:
        ld ix,enemies
        ld iy,spr_table
        ld b,ENEMY_N
        ld c,0
.en:    push bc
        ld a,c
        call spawn_enemy
        call update_actors.frame_anim
        ld de,EN_SIZE
        add ix,de
        ld de,SPR_SIZE
        add iy,de
        pop bc
        inc c
        djnz .en
        ret

; Ο εχθρός IX (slot IY) στη θέση εκκίνησής του, ζωντανός.
; in: A = δείκτης στο enemy_init
spawn_enemy:
        ld l,a
        ld h,0
        ld e,l
        ld d,h
        add hl,hl
        add hl,hl
        add hl,hl
        or a
        sbc hl,de               ; *7
        ld de,enemy_init
        add hl,de
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
        ld (iy+SPR_FLAGS),1
        ret

; Κίνηση / κατάσταση + γραφή στο spr_table (θέση, γραφικό, μέγεθος, bank).
update_actors:
        ld ix,enemies
        ld iy,spr_table
        ld b,ENEMY_N
.en:    push bc
        ld a,(ix+EN_STATE)
        cp ST_DANCE
        jr z,.dance
        cp ST_BOOM
        jp z,.boom
        cp ST_DEAD
        jp z,.dead

        ; --- ζωντανός: x += vx, αναπήδηση στο [0, WORLD_W - w]
        call .frame_anim
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

.boom:  ; --- έκρηξη 8x16 στο κέντρο του εχθρού, καρέ 0/1/2
        ld a,(ix+EN_TIMER)
        ld c,fx_booms0+2
        cp 4
        jr c,.bph
        dec c
        cp 7
        jr c,.bph
        dec c
.bph:   ld a,c
        call fx_frame
        dec (ix+EN_TIMER)
        jr nz,.next
        ld (ix+EN_STATE),ST_DEAD
        ld (ix+EN_TIMER),DEAD_TIME
        ld (iy+SPR_FLAGS),0
        ld hl,(score)
        ld de,KILL_SCORE
        add hl,de
        ld (score),hl
        ld a,1
        ld (hud_dirty),a
        jr .next

.dead:  dec (ix+EN_TIMER)
        jr nz,.next
        pop bc
        push bc
        ld a,ENEMY_N
        sub b                   ; δείκτης = ENEMY_N - B
        call spawn_enemy
        call .frame_anim

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

; Ο εχθρός IX (slot IY) σκάει: έκρηξη 8x16 στο κέντρο του.
enemy_explode:
        ld (ix+EN_STATE),ST_BOOM
        ld (ix+EN_TIMER),BOOM_TIME
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
