; weapons.asm — τα τρία όπλα του Wing C
;
;   Disco-Ray       γρήγορη δέσμη neon· ο εχθρός που χτυπάει χορεύει
;                   Macarena για 1 s και μετά σκάει (actors.asm)
;   Mega-Baguette   διαπερνάει: σκάει τον εχθρό και συνεχίζει. Αναβάθμιση
;                   1/2/3: μία μπαγκέτα, δύο ή τρεις σε βεντάλια
;   Sneeze Cannon   πράσινο spray που απλώνει, κοντινό, με ανάκρουση
;
; Τα βλήματα είναι sprites 8x8 (shots.asm, bank 4) στα slots SHOT_SLOT..+5.
; Fire = ρίχνει (με ρυθμό ανά όπλο), W = επόμενο όπλο. Τα power-ups όπλων
; (items.asm) διαλέγουν όπλο και ανεβάζουν τη μπαγκέτα. Με το Insecticide
; ψεκάζει μόνο του σε κύκλο.

SHOT_N          equ 6
SHOT_SLOT       equ SMOKE_SLOT+SMOKE_N  ; 13-18
SHOT_W          equ SHOTS_W             ; 4 bytes
SHOT_H          equ SHOTS_H             ; 8 γραμμές

WP_DISCO        equ 0
WP_BAGUETTE     equ 1
WP_SNEEZE       equ 2
WP_COUNT        equ 3

; Ανά βλήμα
SH_VX           equ 0           ; signed, bytes/καρέ
SH_VY           equ 1           ; signed, γραμμές/καρέ
SH_LIFE         equ 2           ; καρέ ζωής, 0 = ελεύθερο
SH_KIND         equ 3           ; όπλο
SH_DIR          equ 4
SH_SIZE         equ 5

; Ανά όπλο: ρυθμός (καρέ ανάμεσα σε βολές), ταχύτητα (x: bytes, y = 4x
; γραμμές), ζωή (καρέ)
DISCO_COOL      equ 4
DISCO_SPEED     equ 2
DISCO_LIFE      equ 14
BAGUETTE_COOL   equ 8
BAGUETTE_SPEED  equ 2
BAGUETTE_LIFE   equ 18
SNEEZE_COOL     equ 2
SNEEZE_SPEED    equ 1
SNEEZE_LIFE     equ 9
SNEEZE_RECOIL   equ 3
SPRAY_EVERY     equ 5

update_weapons:
        ; --- W: επόμενο όπλο
        ld a,(input_new)
        and IN_WEAPON
        jr z,.noswitch
        ld a,(weapon)
        inc a
        cp WP_COUNT
        jr c,$+3
        xor a
        ld (weapon),a
        ld a,1
        ld (hud_dirty),a
.noswitch:
        ; --- Fire
        ld hl,fire_cool
        ld a,(hl)
        or a
        jr z,.ready
        dec (hl)
        jr .move
.ready: ld a,(input)
        and IN_FIRE
        jr z,.auto
        call fire
.auto:  ; --- Insecticide: ένας ψεκασμός ανά SPRAY_EVERY καρέ, γύρω-γύρω
        ld a,(spray)
        or a
        jr z,.move
        ld hl,spray_cool
        dec (hl)
        jr nz,.move
        ld (hl),SPRAY_EVERY
        ld a,(spray_dir)
        inc a
        and 7
        ld (spray_dir),a
        ld a,sfx_sneeze
        call play_sfx
        ld a,(spray_dir)
        ld c,WP_SNEEZE
        call spawn_shot
.move:  ; --- κίνηση, ζωή, συγκρούσεις
        ld ix,shots
        ld iy,spr_table+SHOT_SLOT*SPR_SIZE
        ld b,SHOT_N
.shot:  push bc
        ld (iy+SPR_FLAGS),0
        ld a,(ix+SH_LIFE)
        or a
        jp z,.next
        dec (ix+SH_LIFE)
        jp z,.next
        ; x += vx: έξω από τον κόσμο = τέλος
        ld a,(iy+SPR_X)
        add a,(ix+SH_VX)
        cp WORLD_W-SHOT_W+1
        jr nc,.kill
        ld (iy+SPR_X),a
        ; y += vy (16-bit)
        ld a,(ix+SH_VY)
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
        call shot_frame
        ld (iy+SPR_FLAGS),1
        call shot_hits
        jr .next
.kill:  ld (ix+SH_LIFE),0
.next:  ld de,SH_SIZE
        add ix,de
        ld de,SPR_SIZE
        add iy,de
        pop bc
        dec b
        jp nz,.shot
        ret

; Βολή με το τρέχον όπλο, στην κατεύθυνση του σκάφους.
fire:
        ld a,(weapon)           ; ήχος: sfx_disco + όπλο
        add a,sfx_disco
        call play_sfx
        ld a,(weapon)
        cp WP_BAGUETTE
        jr z,.baguette
        cp WP_SNEEZE
        jr z,.sneeze
        ld a,DISCO_COOL
        ld (fire_cool),a
        ld a,(ship_dir)
        ld c,WP_DISCO
        jp spawn_shot

.baguette:
        ld a,BAGUETTE_COOL
        ld (fire_cool),a
        ld a,(baguette_level)
        cp 2
        jr z,.two
        ld a,(ship_dir)         ; 1 ή 3: η κεντρική
        ld c,WP_BAGUETTE
        call spawn_shot
        ld a,(baguette_level)
        cp 3
        ret nz
.two:   ld a,(ship_dir)         ; 2 ή 3: ±45 μοίρες
        dec a
        and 7
        ld c,WP_BAGUETTE
        call spawn_shot
        ld a,(ship_dir)
        inc a
        and 7
        ld c,WP_BAGUETTE
        jp spawn_shot

.sneeze:
        ld a,SNEEZE_COOL
        ld (fire_cool),a
        call rand               ; κατεύθυνση -1/0/+1 τυχαία: απλώνει
        and 3
        jr nz,$+3
        inc a                   ; 0 -> 1 (τα 0..3 γίνονται 1..3)
        sub 2
        ld hl,ship_dir
        add a,(hl)
        and 7
        push af
        ld c,WP_SNEEZE
        call spawn_shot
        pop af
        ; ανάκρουση: ώθηση αντίθετα από τη βολή
        add a,a
        ld e,a
        ld d,0
        ld hl,dir_vec
        add hl,de
        ld a,(hl)
        ld b,SNEEZE_RECOIL
        ld hl,ship_vx
        call .recoil
        ld hl,dir_vec
        add hl,de
        inc hl
        ld a,(hl)
        ld hl,ship_vy
; ταχύτητα (HL) -= A*B, στο ±SHIP_VMAX
.recoil:
        or a
        ret z
        ld c,a
        ld a,(hl)
        bit 7,c
        jr nz,.rplus
        sub b
        jp p,.rst
        cp -SHIP_VMAX
        jr nc,.rst
        ld a,-SHIP_VMAX
        jr .rst
.rplus: add a,b
        jp m,.rst
        cp SHIP_VMAX+1
        jr c,.rst
        ld a,SHIP_VMAX
.rst:   ld (hl),a
        ret

; Νέο βλήμα από το κέντρο του σκάφους. in: A = κατεύθυνση, C = όπλο
spawn_shot:
        ld b,a
        ld ix,shots
        ld iy,spr_table+SHOT_SLOT*SPR_SIZE
        ld de,SH_SIZE
        ld a,SHOT_N
.find:  ex af,af'
        ld a,(ix+SH_LIFE)
        or a
        jr z,.free
        add ix,de
        push de
        ld de,SPR_SIZE
        add iy,de
        pop de
        ex af,af'
        dec a
        jr nz,.find
        ret                     ; όλα πετάνε: η βολή χάνεται
.free:  ld (ix+SH_KIND),c
        ld (ix+SH_DIR),b
        ; ταχύτητα = dir_vec * ταχύτητα όπλου (y: x4)
        ld a,b
        add a,a
        ld e,a
        ld d,0
        ld hl,dir_vec
        add hl,de
        ld a,c
        ld de,DISCO_SPEED*256+DISCO_LIFE
        cp WP_BAGUETTE
        jr nz,$+5
        ld de,BAGUETTE_SPEED*256+BAGUETTE_LIFE
        cp WP_SNEEZE
        jr nz,$+5
        ld de,SNEEZE_SPEED*256+SNEEZE_LIFE
        ld (ix+SH_LIFE),e
        ld a,(hl)               ; dx (-1/0/1) * ταχύτητα
        call .mul
        ld (ix+SH_VX),a
        inc hl
        ld a,(hl)               ; dy * ταχύτητα * 4
        call .mul
        add a,a
        add a,a
        ld (ix+SH_VY),a
        ; θέση: κέντρο του σκάφους (12x24 -> 8x8: +1 byte, +8 γραμμές)
        ld a,(ship_x)
        inc a
        ld (iy+SPR_X),a
        ld hl,(ship_y)
        ld de,8
        add hl,de
        ld (iy+SPR_Y),l
        ld (iy+SPR_Y+1),h
        ld (iy+SPR_W),SHOT_W
        ld (iy+SPR_H),SHOT_H
        ld (iy+SPR_BANK),BANK_WORLD
        ret
; A = A (-1/0/1) * D
.mul:   or a
        ret z
        ld a,d
        ret p
        neg
        ret

; Το γραφικό του βλήματος IX στο sprite IY.
shot_frame:
        ld a,(ix+SH_KIND)
        cp WP_BAGUETTE
        jr z,.bag
        cp WP_SNEEZE
        jr z,.snz
        ld a,(ix+SH_DIR)        ; disco: dir*2 + φάση (αναβοσβήνει)
        add a,a
        ld b,a
        ld a,(ix+SH_LIFE)
        and 1
        add a,b
        add a,sh_disco_n0
        jr .set
.bag:   ld a,(ix+SH_DIR)
        add a,sh_baguette_n0
        jr .set
.snz:   ld a,(ix+SH_LIFE)       ; απλώνει: 0 -> 1 -> 2 καθώς λιγοστεύει η ζωή
        ld c,sh_sneeze0
        cp SNEEZE_LIFE*2/3
        jr nc,.sset
        inc c
        cp SNEEZE_LIFE/3
        jr nc,.sset
        inc c
.sset:  ld a,c
.set:   ld l,a                  ; shots_gfx + καρέ*64
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

; Το βλήμα IX (sprite IY) πάνω σε εχθρούς: Disco = χορός, αλλιώς σκάει·
; η μπαγκέτα συνεχίζει, τα άλλα σβήνουν.
shot_hits:
        ld a,(ix+SH_KIND)
        ld (shot_kind),a
        ld a,(iy+SPR_X)
        ld (hit_x),a
        ld l,(iy+SPR_Y)
        ld h,(iy+SPR_Y+1)
        ld (hit_y),hl
        push ix
        push iy
        ld ix,enemies
        ld iy,spr_table
        ld b,ENEMY_N
.en:    push bc
        ld a,(ix+EN_STATE)
        cp ST_BOOM
        jr nc,.miss             ; σκάει ή νεκρός
        ; x: βλήμα [hx, hx+3] με εχθρό [ex, ex+w-1]
        ld a,(iy+SPR_X)
        ld c,a
        add a,(iy+SPR_W)
        dec a                   ; ex + w - 1
        ld hl,hit_x
        cp (hl)
        jr c,.miss              ; ο εχθρός τελειώνει πριν από το βλήμα
        ld a,(hl)
        add a,SHOT_W-1
        cp c
        jr c,.miss              ; το βλήμα τελειώνει πριν από τον εχθρό
        ; y, 16-bit
        ld l,(iy+SPR_Y)
        ld h,(iy+SPR_Y+1)
        ld e,(iy+SPR_H)
        ld d,0
        dec e
        add hl,de               ; ey + h - 1
        ld de,(hit_y)
        or a
        sbc hl,de
        jr c,.miss
        ld hl,(hit_y)
        ld de,SHOT_H-1
        add hl,de               ; hy + 7
        ld e,(iy+SPR_Y)
        ld d,(iy+SPR_Y+1)
        or a
        sbc hl,de
        jr c,.miss
        ; χτύπημα
        ld a,(ix+EN_KIND)       ; ο boss δεν χορεύει και δεν διαπερνιέται
        cp KIND_BOSS
        jr nz,.notboss
        ld a,#FF
        ld (shot_kind),a
        jr .boom
.notboss:
        ld a,(shot_kind)
        cp WP_DISCO
        jr nz,.boom
        ld a,(ix+EN_STATE)
        cp ST_DANCE
        jr z,.hit               ; ήδη χορεύει
        ld (ix+EN_STATE),ST_DANCE
        ld (ix+EN_TIMER),DANCE_TIME
        jr .hit
.boom:  call enemy_damage
.hit:   pop bc
        pop iy
        pop ix
        ld a,(shot_kind)
        cp WP_BAGUETTE
        ret z                   ; διαπερνάει
        ld (ix+SH_LIFE),0
        ld (iy+SPR_FLAGS),0
        ret
.miss:  ld de,EN_SIZE
        add ix,de
        ld de,SPR_SIZE
        add iy,de
        pop bc
        dec b
        jp nz,.en
        pop iy
        pop ix
        ret

; Μοναδιαία διανύσματα των 8 κατευθύνσεων: dx, dy
dir_vec:
        db  0,-1                ; n
        db  1,-1                ; ne
        db  1, 0                ; e
        db  1, 1                ; se
        db  0, 1                ; s
        db -1, 1                ; sw
        db -1, 0                ; w
        db -1,-1                ; nw

; Όπλο στο HUD (γραμμή 8): όνομα + επίπεδο μπαγκέτας. Σε RAM_HUD.
draw_weapon:
        ld a,(weapon)
        ld l,a
        ld h,0
        add hl,hl
        ld de,weapon_names
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ld b,8
        ld c,32
        call print_str
        ld a,(weapon)
        cp WP_BAGUETTE
        ld a,' '
        jr nz,.lvl
        ld a,(baguette_level)
        add a,'0'
.lvl:   ld b,8
        ld c,60
        jp print_char

weapon_names:
        dw txt_disco,txt_baguette,txt_sneeze
txt_disco:    db "DISCO-RAY    ",0
txt_baguette: db "MEGA-BAGUETTE",0
txt_sneeze:   db "SNEEZE CANNON",0
