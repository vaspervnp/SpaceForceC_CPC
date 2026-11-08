; actors.asm — εχθροί του demo: κινούνται ευθεία και αναπηδούν στα όρια του
; κόσμου, με δύο καρέ animation. Είναι εδώ για να δοκιμαστεί το sprite engine
; (clip, save-under, πόσα sprites χωράνε στο καρέ)· η πραγματική AI είναι M7.

ENEMY_N         equ 10          ; στα slots 0-9 του spr_table
SHIP_SLOT       equ SPR_MAX-1   ; το σκάφος ζωγραφίζεται τελευταίο, από πάνω

; Ανά εχθρό: X, Y (dw), vx, vy (signed), πρώτο καρέ στο enemies_table
EN_X            equ 0
EN_Y            equ 1
EN_VX           equ 3
EN_VY           equ 4
EN_KIND         equ 5
EN_SIZE         equ 6

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

; Αντιγράφει τις αρχικές θέσεις και ενεργοποιεί τα slots.
init_actors:
        ld hl,enemy_init
        ld de,enemies
        ld b,ENEMY_N
.en:    ld a,(hl)               ; X
        ld (de),a
        inc hl
        inc hl                  ; (το 0 μετά το X)
        inc de
        ld a,(hl)               ; Y
        ld (de),a
        inc hl
        inc de
        ld a,(hl)
        ld (de),a
        inc hl
        inc de
        ldi                     ; vx
        ldi                     ; vy
        ldi                     ; kind
        inc bc                  ; (τα ldi μετράνε το BC)
        inc bc
        inc bc
        djnz .en
        ld iy,spr_table
        ld b,ENEMY_N
        ld de,SPR_SIZE
.on:    ld (iy+SPR_FLAGS),1
        add iy,de
        djnz .on
        ld iy,spr_table+SHIP_SLOT*SPR_SIZE
        ld (iy+SPR_FLAGS),1
        ld (iy+SPR_W),SHIP_W
        ld (iy+SPR_H),SHIP_H
        ret

; Κίνηση + γραφή στο spr_table (θέση, γραφικό, μέγεθος).
update_actors:
        ld ix,enemies
        ld iy,spr_table
        ld b,ENEMY_N
.en:    push bc
        ; καρέ = kind + (frames/8 & 1)
        ld a,(frames)
        rrca
        rrca
        rrca
        and 1
        add a,(ix+EN_KIND)
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
        ld d,a                  ; DE = vy με πρόσημο
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
        ld de,EN_SIZE
        add ix,de
        ld de,SPR_SIZE
        add iy,de
        pop bc
        dec b
        jp nz,.en

        ; το σκάφος
        ld iy,spr_table+SHIP_SLOT*SPR_SIZE
        ld a,(ship_x)
        ld (iy+SPR_X),a
        ld hl,(ship_y)
        ld (iy+SPR_Y),l
        ld (iy+SPR_Y+1),h
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
.got:   ld (iy+SPR_GFX),l
        ld (iy+SPR_GFX+1),h
        ret
