; items.asm — ό,τι αφήνουν οι εχθροί: κλεμμένα μυρμήγκια και power-ups
;
; Όταν σκάει ένας εχθρός αφήνει τα μυρμήγκιά του (kind_info) και, με
; πιθανότητα 1/8 (πάντα η κατσαρίδα-διοικητής), ένα power-up. Αναβοσβήνουν
; (καρέ λάμψης του pickups.asm, bank 5) και χάνονται σε 10 s. Όποιο αγγίξει
; το σκάφος μαζεύεται:
;
;   μυρμήγκι      +50, μετράει στο ANTS
;   Bubble Wrap   απορροφά το επόμενο χτύπημα («POP!»)
;   Espresso      10 s: x1,5 ταχύτητα, οι πιλότοι ουρλιάζουν 3x πιο γρήγορα
;   Ant-Magnet    10 s: τα μυρμήγκια έρχονται μόνα τους
;   Engine        μόνιμα +25% ταχύτητα (ως 2 φορές)
;   όπλο          αυτό το όπλο· αν το έχεις ήδη, η μπαγκέτα ανεβαίνει επίπεδο
;   Insecticide   10 s: αυτόματος ψεκασμός σε κύκλο (weapons.asm)
;   Extra life    +1 ζωή

ITEM_N          equ 3
ITEM_SLOT       equ ESHOT_SLOT+ESHOT_N  ; 24-26
ITEM_LIFE       equ 250                 ; 10 s
ITEM_SCORE      equ 25
ANT_SCORE       equ 50
POWER_TIME      equ 250                 ; 10 s για τα προσωρινά
MAGNET_SPEED    equ 1                   ; bytes/καρέ (y: x4)

IT_ANT          equ 0
IT_SHIELD       equ 1
IT_ESPRESSO     equ 2
IT_MAGNET       equ 3
IT_ENGINE       equ 4
IT_DISCO        equ 5
IT_BAGUETTE     equ 6
IT_SNEEZE       equ 7
IT_SPRAY        equ 8
IT_LIFE         equ 9

; Πρώτο καρέ ανά τύπο (+1 = λάμψη, ή ant1)
item_frame:
        db ant0,pu_shield,pu_espresso,pu_magnet,pu_engine
        db pu_disco,pu_baguette,pu_sneeze,pu_spray,pu_life

; Ποιο power-up: rand & 15 -> τύπος (η ζωή σπάνια)
drop_table:
        db IT_SHIELD,IT_SHIELD,IT_ESPRESSO,IT_ESPRESSO,IT_MAGNET,IT_MAGNET
        db IT_ENGINE,IT_DISCO,IT_DISCO,IT_BAGUETTE,IT_BAGUETTE,IT_BAGUETTE
        db IT_SNEEZE,IT_SNEEZE,IT_SPRAY,IT_LIFE

; Ο εχθρός IX σκάει στη θέση του sprite IY: A μυρμήγκια + ίσως power-up.
drop_items:
        or a
        jr z,.power
        ld b,a
.ant:   push bc
        ld a,IT_ANT
        call spawn_item
        pop bc
        djnz .ant
.power: ld a,(ix+EN_KIND)
        cp en_roach0            ; ο διοικητής αφήνει πάντα
        jr z,.always
        call rand
        and 7
        ret nz
.always:
        call rand
        and 15
        ld e,a
        ld d,0
        ld hl,drop_table
        add hl,de
        ld a,(hl)
        ; (συνέχεια στο spawn_item)

; Νέο αντικείμενο τύπου A στη θέση του sprite IY, δίπλα στα προηγούμενα
; (item_dx). Αν δεν υπάρχει ελεύθερο slot, χάνεται.
spawn_item:
        push ix
        ld c,a
        ld hl,item_timer
        ld ix,spr_table+ITEM_SLOT*SPR_SIZE
        ld b,ITEM_N
.find:  ld a,(hl)
        or a
        jr z,.free
        inc hl
        ld de,SPR_SIZE
        add ix,de
        djnz .find
        pop ix
        ret
.free:  ld (hl),ITEM_LIFE
        ld de,ITEM_N            ; item_type[i] = item_timer[i] + ITEM_N
        add hl,de
        ld (hl),c
        ld a,(item_dx)
        add a,(iy+SPR_X)
        cp WORLD_W-4+1
        jr c,$+4
        ld a,WORLD_W-4
        ld (ix+SPR_X),a
        ld a,(iy+SPR_Y)
        ld (ix+SPR_Y),a
        ld a,(iy+SPR_Y+1)
        ld (ix+SPR_Y+1),a
        ld a,(item_dx)
        add a,4
        and 15
        ld (item_dx),a
        pop ix
        ret

; Κάθε καρέ: γραφικό, μαγνήτης, χρόνος, μάζεμα.
update_items:
        ld hl,item_timer
        ld iy,spr_table+ITEM_SLOT*SPR_SIZE
        ld b,ITEM_N
.item:  push bc
        push hl
        ld (iy+SPR_FLAGS),0
        ld a,(hl)
        or a
        jp z,.next
        dec (hl)
        jp z,.next
        ld de,ITEM_N
        add hl,de
        ld a,(hl)
        ld (item_cur),a
        ; γραφικό: πρώτο καρέ + (frames/4 & 1), από το pickups_table (bank 5)
        ld e,a
        ld d,0
        ld hl,item_frame
        add hl,de
        ld a,(frames)
        rrca
        rrca
        and 1
        add a,(hl)
        RAM_ENEMIES
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl               ; *4: db w,h / dw offset
        ld de,pickups_table
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
        ld hl,pickups_gfx
        add hl,de
        ld (iy+SPR_GFX),l
        ld (iy+SPR_GFX+1),h
        ld (iy+SPR_BANK),BANK_ENEMIES
        RAM_WORLD
        ld (iy+SPR_FLAGS),1
        ; μαγνήτης: τα μυρμήγκια προς το σκάφος
        ld a,(item_cur)
        or a
        jr nz,.nomag
        ld a,(magnet)
        or a
        call nz,.pull
.nomag: ld a,(gameover)
        or a
        jr nz,.next
        call hits_ship
        jr nc,.next
        pop hl                  ; μαζεύτηκε
        ld (hl),0
        push hl
        ld (iy+SPR_FLAGS),0
        ld a,(item_cur)
        call apply_item
.next:  ld de,SPR_SIZE
        add iy,de
        pop hl
        inc hl
        pop bc
        dec b
        jp nz,.item
        ret

; Το αντικείμενο IY ένα βήμα προς το κέντρο του σκάφους.
.pull:  ld a,(ship_x)
        inc a                   ; κέντρο: +3 - 2 (μισό πλάτος του αντικειμένου)
        sub (iy+SPR_X)
        jr z,.py
        ld a,(iy+SPR_X)
        jr c,.pl
        add a,MAGNET_SPEED
        jr .px
.pl:    sub MAGNET_SPEED
.px:    ld (iy+SPR_X),a
.py:    ld hl,(ship_y)
        ld de,SHIP_H/2-4
        add hl,de
        ld e,(iy+SPR_Y)
        ld d,(iy+SPR_Y+1)
        or a
        sbc hl,de               ; > 0: το σκάφος πιο κάτω
        ret z
        ex de,hl
        ld bc,MAGNET_SPEED*4
        jr nc,.pd
        or a
        sbc hl,bc
        jr .pst
.pd:    add hl,bc
.pst:   ld (iy+SPR_Y),l
        ld (iy+SPR_Y+1),h
        ret

; Τι κάνει το αντικείμενο A όταν μαζευτεί.
apply_item:
        ld hl,txt_none
        or a
        jr nz,.power
        ; μυρμήγκι
        ld a,sfx_ant
        call play_sfx
        ld hl,(ants_saved)
        inc hl
        ld (ants_saved),hl
        ld de,ANT_SCORE
        jp .score
.power: push af
        ld a,sfx_pickup
        call play_sfx
        ld hl,(score)
        ld de,ITEM_SCORE
        add hl,de
        ld (score),hl
        pop af
        cp IT_SHIELD
        jr nz,.esp
        ld a,1
        ld (shield),a
        ld hl,txt_shield
        jr .msg
.esp:   cp IT_ESPRESSO
        jr nz,.mag
        ld a,POWER_TIME
        ld (espresso),a
        ld hl,txt_espresso
        jr .msg
.mag:   cp IT_MAGNET
        jr nz,.eng
        ld a,POWER_TIME
        ld (magnet),a
        ld hl,txt_magnet
        jr .msg
.eng:   cp IT_ENGINE
        jr nz,.spr
        ld a,(engine)
        cp 2
        jr nc,$+6
        inc a
        ld (engine),a
        ld hl,txt_engine
        jr .msg
.spr:   cp IT_SPRAY
        jr nz,.life
        ld a,POWER_TIME
        ld (spray),a
        ld hl,txt_spray
        jr .msg
.life:  cp IT_LIFE
        jr nz,.weapon
        ld a,(lives)
        cp 9
        jr nc,$+6
        inc a
        ld (lives),a
        ld hl,txt_life
        jr .msg
.weapon:                        ; IT_DISCO / IT_BAGUETTE / IT_SNEEZE
        sub IT_DISCO            ; -> WP_DISCO / WP_BAGUETTE / WP_SNEEZE
        ld hl,weapon
        cp (hl)
        ld (hl),a
        jr nz,.wname
        cp WP_BAGUETTE          ; ίδιο όπλο: η μπαγκέτα ανεβαίνει επίπεδο
        jr nz,.wname
        ld a,(baguette_level)
        cp 3
        jr nc,.wname
        inc a
        ld (baguette_level),a
.wname: ld a,(weapon)           ; το όνομα του όπλου από το HUD
        add a,a
        ld e,a
        ld d,0
        ld hl,weapon_names
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
.msg:   call set_status
.dirty: ld a,1
        ld (hud_dirty),a
        ret
.score: ld hl,(score)
        add hl,de
        ld (score),hl
        jr .dirty

; Το Bubble Wrap απορροφά ένα χτύπημα. out: CF = 1 αν το απορρόφησε.
use_shield:
        ld a,(shield)
        or a
        ret z
        ld a,sfx_pop
        call play_sfx
        xor a
        ld (shield),a
        ld a,INVULN_TIME/2
        ld (invuln),a
        ld hl,txt_pop
        call set_status
        ld a,1
        ld (hud_dirty),a
        scf
        ret

; Οι ενδείξεις των ενεργών power-ups στο HUD (γραμμή 24, x 26-33):
; S = ασπίδα, E = espresso, M = μαγνήτης, I = εντομοκτόνο. Σε RAM_HUD.
draw_powerups:
        ld hl,shield
        ld a,'S'
        ld c,26
        call .one
        ld hl,espresso
        ld a,'E'
        ld c,28
        call .one
        ld hl,magnet
        ld a,'M'
        ld c,30
        call .one
        ld hl,spray
        ld a,'I'
        ld c,32
.one:   ld e,a
        ld a,(hl)
        or a
        ld a,e
        jr nz,$+4
        ld a,' '
        ld b,24
        jp print_char

txt_shield:   db "BUBBLE WRAP!",0
txt_espresso: db "ESPRESSO!!! ",0
txt_magnet:   db "ANT-MAGNET! ",0
txt_engine:   db "ENGINE UP!  ",0
txt_spray:    db "INSECTICIDE!",0
txt_life:     db "EXTRA LIFE! ",0
txt_pop:      db "POP!        ",0
txt_none:     db 0
