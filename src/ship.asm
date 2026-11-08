; ship.asm — The Flying Patates: κίνηση με αδράνεια, φλόγα, καπνός, κραυγές
;
; Θέσεις σε fixed point: ship_x16 = X*16 (bytes), ship_y4 = Y*4 (γραμμές).
; Η ταχύτητα (vx, vy) είναι στην ίδια κλίμακα και για τους δύο άξονες:
; 16 = 1 byte = 4 γραμμές ανά καρέ, δηλαδή 2 pixels και στις δύο
; κατευθύνσεις στην οθόνη (το pixel του Mode 0 είναι 2:1).
;
; Στο διάστημα το σκάφος γλιστράει (τριβή 1), στη Γη η ατμόσφαιρα το
; φρενάρει (τριβή 3). Επιτάχυνση 2: τελική ταχύτητα σε 8 καρέ (0,3 s).

SHIP_VMAX       equ 16          ; βασική· +4 ανά engine, +8 με espresso (ως 32)
SHIP_ACC        equ 2
FRICTION_SPACE  equ 1
FRICTION_EARTH  equ 3

BANK_WORLD      equ #C4
SMOKE_N         equ 3           ; slots 10-12
SMOKE_SLOT      equ ENEMY_N
FLAME_SLOT      equ SPR_MAX-2   ; πριν από το σκάφος: χώνεται από κάτω του
SMOKE_EVERY     equ 6           ; καρέ ανάμεσα σε δύο τολύπες
SMOKE_LIFE      equ 18
SCREAM_TIME     equ 25          ; 1 s

move_ship:
        ; --- κατεύθυνση: από τα πατημένα βελάκια (αντίθετα = καμία αλλαγή)
        ld a,(input)
        and 15
        ld e,a
        ld d,0
        ld hl,dir_table
        add hl,de
        ld a,(hl)
        cp #FF
        ld (thrust),a           ; #FF = χωρίς ώθηση
        jr z,.keep
        ld hl,ship_dir
        ld b,(hl)
        ld (hl),a
        sub b                   ; στροφή >= 135 μοίρες: οι πιλότοι ουρλιάζουν
        and 7
        cp 3
        jr c,.keep
        cp 6
        jr nc,.keep
        ld a,SCREAM_TIME
        ld (scream),a
.keep:
        ; --- μέγιστη ταχύτητα: 16 + 4*engine (+8 espresso). Ως 32 = 2 bytes ή
        ; 8 γραμμές ανά καρέ, όσο και η κάμερα: την προλαβαίνει ακόμα.
        ld a,(engine)
        add a,a
        add a,a
        add a,SHIP_VMAX
        ld b,a
        ld a,(espresso)
        or a
        ld a,b
        jr z,$+4
        add a,8
        ld (.vp1+1),a
        ld (.vp2+1),a
        neg
        ld (.vm1+1),a
        ld (.vm2+1),a
        ld a,(.vp1+1)
        inc a
        ld (.vp1+1),a

        ; --- τριβή του κόσμου
        ld a,(ship_world)
        or a
        ld a,FRICTION_SPACE
        jr z,$+4
        ld a,FRICTION_EARTH
        ld (.fric+1),a
        ld (.fric2+1),a

        ; --- vx: αριστερά = bit 2, δεξιά = bit 3
        ld a,(input)
        rrca
        rrca
        and 3
        ld b,a
        ld hl,ship_vx
        call .accel
        ; --- vy: πάνω = bit 0, κάτω = bit 1
        ld a,(input)
        and 3
        ld b,a
        ld hl,ship_vy
        call .accel

        ; --- X16 += vx, όρια [0, SHIP_MAX_X*16]
        ld hl,(ship_x16)
        ld a,(ship_vx)
        call .slow
        call .add_signed
        ld de,SHIP_MAX_X*16
        ld bc,ship_vx
        call .clamp
        ld (ship_x16),hl
        ld a,l                  ; ship_x = X16 / 16
        srl h
        rra
        srl h
        rra
        srl h
        rra
        srl h
        rra
        ld (ship_x),a
        ; --- Y4 += vy, όρια [0, SHIP_MAX_Y*4]
        ld hl,(ship_y4)
        ld a,(ship_vy)
        call .slow
        call .add_signed
        ld de,SHIP_MAX_Y*4
        ld bc,ship_vy
        call .clamp
        ld (ship_y4),hl
        srl h                   ; ship_y = Y4 / 4
        rr l
        srl h
        rr l
        ld (ship_y),hl
        ret

; B: bit 0 = προς τα αρνητικά, bit 1 = προς τα θετικά. HL -> ταχύτητα.
.accel: ld a,b
        or a
        jr z,.friction
        cp 3
        jr z,.friction          ; και τα δύο: σαν κανένα
        ld a,(hl)
        bit 0,b
        jr z,.plus
        sub SHIP_ACC
        jp p,.st
.vm1:   cp -SHIP_VMAX
        jr nc,.st
.vm2:   ld a,-SHIP_VMAX
        jr .st
.plus:  add a,SHIP_ACC
        jp m,.st
.vp1:   cp SHIP_VMAX+1
        jr c,.st
.vp2:   ld a,SHIP_VMAX
.st:    ld (hl),a
        ret
.friction:
        ld a,(hl)
        or a
        ret z
        jp m,.neg
.fric:  sub 0
        jr nc,.st
        xor a
        jr .st
.neg:
.fric2: add a,0
        jr nc,.st
        xor a
        jr .st

; Laser Spaghetti (hazards.asm): η κίνηση στο μισό.
.slow:  ld b,a
        ld a,(slowed)
        or a
        ld a,b
        ret z
        sra a
        ret

; HL += A (με πρόσημο)
.add_signed:
        ld e,a
        add a,a
        sbc a,a
        ld d,a
        add hl,de
        ret

; HL στο [0, DE]· αν κόπηκε, η ταχύτητα (BC) μηδενίζεται.
.clamp: bit 7,h
        jr nz,.low
        push hl
        or a
        sbc hl,de
        pop hl
        ret c
        ret z
        ex de,hl
        jr .stop
.low:   ld hl,0
.stop:  xor a
        ld (bc),a
        ret

;------------------------------------------------------------------

; Σκάφος, φλόγα και καπνός στο spr_table. Τρέχει μετά το move_ship.
update_ship_sprites:
        ; --- το σκάφος
        ld iy,spr_table+SHIP_SLOT*SPR_SIZE
        ld (iy+SPR_FLAGS),1
        ld (iy+SPR_BANK),BANK_WORLD
        ld (iy+SPR_W),SHIP_W
        ld (iy+SPR_H),SHIP_H
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
        ld a,(gameover)         ; game over: η μεγάλη έκρηξη, μετά τίποτα
        or a
        jr z,.alive
        ld b,a
        ld a,GAMEOVER_TIME
        sub b                   ; καρέ από τη ζημιά
        ld c,0
.div3:  sub 3
        jr c,.d3
        inc c
        jr .div3
.d3:    ld a,c
        cp 5
        jr nc,.hide
        add a,fx_boomb0         ; (6x24, ίδιο πλαίσιο με το σκάφος)
        call fx_frame
        jr .noflame
.alive: ld a,(invuln)           ; άτρωτο: αναβοσβήνει
        or a
        jr z,.solid
        ld a,(frames)
        and 2
        jr nz,.solid
.hide:  ld (iy+SPR_FLAGS),0
.noflame:
        ld iy,spr_table+FLAME_SLOT*SPR_SIZE
        ld (iy+SPR_FLAGS),0
        jp .age                 ; χωρίς φλόγα και χωρίς νέο καπνό
.solid:

        ; --- η φλόγα: μόνο με ώθηση, στην ουρά της κατεύθυνσης
        ld iy,spr_table+FLAME_SLOT*SPR_SIZE
        ld (iy+SPR_FLAGS),0
        ld a,(thrust)
        cp #FF
        jr z,.smoke
        ld a,(ship_dir)
        add a,a
        ld e,a
        ld d,0
        ld hl,flame_at
        add hl,de
        ld a,(ship_x)
        add a,(hl)              ; dx σε bytes, με πρόσημο
        cp WORLD_W-4+1
        jr nc,.smoke            ; έξω από τον κόσμο (και το «αρνητικό»)
        ld (iy+SPR_X),a
        inc hl
        ld a,(hl)               ; dy σε γραμμές, με πρόσημο
        ld e,a
        add a,a
        sbc a,a
        ld d,a
        ld hl,(ship_y)
        add hl,de
        bit 7,h
        jr nz,.smoke
        ld (iy+SPR_Y),l
        ld (iy+SPR_Y+1),h
        ; καρέ = fx_flame_<dir>0 + (frames mod 3)
        ld a,(flame_phase)
        inc a
        cp 3
        jr c,$+3
        xor a
        ld (flame_phase),a
        ld b,a
        ld a,(ship_dir)
        ld c,a
        add a,a
        add a,c                 ; dir*3
        add a,b
        call fx_frame
        ld (iy+SPR_FLAGS),1

.smoke: ; --- καπνός: μόνο στη Γη, από την ουρά, κάθε SMOKE_EVERY καρέ
        ld a,(ship_world)
        or a
        jr z,.age
        ld a,(iy+SPR_FLAGS)     ; υπάρχει φλόγα (IY = FLAME_SLOT)
        or a
        jr z,.age
        ld hl,smoke_timer
        dec (hl)
        jr nz,.age
        ld (hl),SMOKE_EVERY
        ; ελεύθερη τολύπη (ή η παλαιότερη: η επόμενη στη σειρά)
        ld a,(smoke_next)
        ld c,a
        inc a
        cp SMOKE_N
        jr c,$+3
        xor a
        ld (smoke_next),a
        ld b,0
        ld hl,smoke_age
        add hl,bc
        ld (hl),SMOKE_LIFE
        ld a,c                  ; slot = SMOKE_SLOT + c
        add a,a
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld ix,spr_table+SMOKE_SLOT*SPR_SIZE
        add ix,de
        ld a,(iy+SPR_X)
        ld (ix+SPR_X),a
        ld a,(iy+SPR_Y)
        ld (ix+SPR_Y),a
        ld a,(iy+SPR_Y+1)
        ld (ix+SPR_Y+1),a

.age:   ; --- οι τολύπες γερνάνε: καρέ 0/1/2 και μετά σβήνουν
        ld ix,spr_table+SMOKE_SLOT*SPR_SIZE
        ld hl,smoke_age
        ld b,SMOKE_N
.puff:  push bc
        push hl
        ld (ix+SPR_FLAGS),0
        ld a,(hl)
        or a
        jr z,.dead
        dec (hl)
        jr z,.dead
        ld c,fx_smoke0
        cp SMOKE_LIFE*2/3
        jr nc,.ph
        inc c
        cp SMOKE_LIFE/3
        jr nc,.ph
        inc c
.ph:    push ix
        pop iy
        ld a,c
        call fx_frame
        ld (iy+SPR_FLAGS),1
.dead:  ld de,SPR_SIZE
        add ix,de
        pop hl
        inc hl
        pop bc
        djnz .puff
        ret

; Γράφει στο sprite IY το καρέ A του fx_table (γραφικό, πλάτος, ύψος, bank).
fx_frame:
        ld (iy+SPR_BANK),BANK_WORLD
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl               ; *4: db w,h / dw offset
        ld de,fx_table
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
        ld hl,fx_gfx
        add hl,de
        ld (iy+SPR_GFX),l
        ld (iy+SPR_GFX+1),h
        ret

; Πού κάθεται η φλόγα 8x8 ως προς την πάνω αριστερή γωνία του σκάφους,
; ανά κατεύθυνση (assets/src/ship.py: FLAME_AT, με το x σε bytes).
flame_at:
        db  1,20                ; n
        db  0,14                ; ne
        db -3, 7                ; e
        db  0, 2                ; se
        db  1,-4                ; s
        db  3, 2                ; sw
        db  5, 7                ; w
        db  3,14                ; nw

;------------------------------------------------------------------

; Οι πιλότοι στις απότομες στροφές. Τρέχει σε RAM_HUD (γράφει στο HUD).
SCREAM_X        equ 56
SCREAM_Y        equ 24

update_scream:
        ld a,(scream)
        or a
        ret z
        cp SCREAM_TIME
        jr nz,.wait
        ld a,(scream_text)      ; δύο κραυγές, εναλλάξ
        xor 1
        ld (scream_text),a
        ld hl,txt_scream0
        jr z,$+5
        ld hl,txt_scream1
        ld a,(espresso)         ; με espresso μιλάνε 3x πιο γρήγορα
        or a
        jr z,$+5
        ld hl,txt_scream2
        ld b,SCREAM_Y
        ld c,SCREAM_X
        call print_str
.wait:  ld hl,scream
        dec (hl)
        ret nz
        ld hl,txt_noscream
        ld b,SCREAM_Y
        ld c,SCREAM_X
        jp print_str

txt_scream0:  db "AAAAAAH!",0
txt_scream1:  db "MAMAAA!!",0
txt_scream2:  db "AH!AH!AH",0
txt_noscream: db "        ",0
