; ui.asm — οθόνες εκτός παιχνιδιού: title, redefine keys, high scores
;
; Δεν αλλάζουν το CRTC: το split screen μένει όπως στο παιχνίδι. Πάνω οι 21
; σειρές της σελίδας #C0 χωρίς scroll (MA 0), κάτω το HUD. Οι οθόνες
; γράφονται κατευθείαν στη σελίδα που φαίνεται (στατικές, δεν χρειάζονται
; double buffer) και τρέχουν στα 25 FPS με το wait_frame.

TITLE_PAGE         equ #C0
HI_N            equ 5
HI_SIZE         equ 5           ; 3 γράμματα + dw σκορ
HI_TIME         equ 250         ; 10 s στον πίνακα, μετά πίσω στον τίτλο
LEVEL_WAIT      equ 100         ; 4 s στις οθόνες των πιστών
CUT_WAIT        equ 250         ; 10 s σε κάθε οθόνη της ιστορίας
NAME_REPEAT     equ 8           ; καρέ πριν αρχίσει η επανάληψη στο όνομα

; Γραμμές της κάθε σειράς (8 γραμμές ανά σειρά χαρακτήρων)
        macro TROW n
        db {n}*8
        mend

;------------------------------------------------------------------
; Title
;------------------------------------------------------------------

; Επιστρέφει όταν ο παίκτης πατήσει fire ή το 1.
title_screen:
        ld a,mus_title
        call play_music
        ld hl,cut_table+4       ; η εικόνα (assets/src/cutscenes.py)
        call cut_play
        RAM_ENEMIES
        ld hl,title_lines
        call print_lines
        RAM_WORLD
        call hud_title
        call draw_difficulty
        call wait_release
.loop:  call wait_frame
        call read_input
        ld a,(ui_timer)         ; «PRESS FIRE» αναβοσβήνει
        inc a
        ld (ui_timer),a
        and 15
        jr nz,.keys
        ld hl,txt_fire
        ld a,(ui_timer)
        and 16
        jr z,$+5
        ld hl,txt_nofire
        ld b,19*8
        call print_center
.keys:  ld a,(input_new)
        and IN_FIRE
        ret nz
        ld a,(keymap+8)
        bit 0,a                 ; 1
        ret z
        bit 1,a                 ; 2
        jr nz,.no2
        call menu_sfx
        call redefine_keys
        jp title_screen
.no2:   ld a,(keymap+7)
        bit 0,a                 ; 4: η επόμενη δυσκολία
        jr nz,.no4
        call menu_sfx
        ld a,(difficulty)
        inc a
        cp 3
        jr c,$+3
        xor a
        ld (difficulty),a
        call draw_difficulty
        call wait_release
        jp .loop
.no4:   ld a,(keymap+7)
        bit 1,a                 ; 3
        jp nz,.loop
        call menu_sfx
        call hiscore_screen
        jp title_screen

; Η δυσκολία δίπλα στο «4  DIFFICULTY».
draw_difficulty:
        ld a,(difficulty)
        ld e,a
        add a,a
        add a,a
        add a,a
        sub e                   ; *7
        ld e,a
        ld d,0
        ld hl,txt_difficulty
        add hl,de
        ld b,16*8
        ld c,51
        jp print_str

txt_difficulty:
        db "EASY  ",0,"MEDIUM",0,"HARD  ",0

menu_sfx:
        ld a,sfx_menu
        jp play_sfx

; Καθαρή σελίδα UI στην οθόνη, καθαρό HUD, κείμενο στη σελίδα.
ui_page:
        RAM_WORLD
        ld a,HW_BLACK
        call set_sky
        ld a,TITLE_PAGE
        call clear_page_a
        ld a,TITLE_PAGE
        ld hl,0
        call show_page
        RAM_HUD
        call clear_hud
        RAM_WORLD
        ld a,TITLE_PAGE
        jp text_to_page

; Το HUD του τίτλου: το καλύτερο σκορ.
hud_title:
        call text_to_hud
        RAM_HUD
        ld hl,txt_best
        ld b,8
        ld c,24
        call print_str
        ld b,8
        ld c,36
        ld hl,hiscores
        call print_name
        ld hl,(hiscores+3)
        ld b,8
        ld c,46
        call print_u16
        ld hl,txt_credit
        ld b,24
        ld c,13
        call print_str
        RAM_WORLD
        ld a,TITLE_PAGE
        jp text_to_page

;------------------------------------------------------------------
; Redefine keys
;------------------------------------------------------------------

redefine_keys:
        call ui_page
        ld hl,txt_redefine
        ld b,8
        ld c,27
        call print_big
        ; οι τωρινές αντιστοιχίσεις
        ld b,0
.show:  push bc
        call .name
        call .key
        pop bc
        inc b
        ld a,b
        cp KEYS_USER
        jr nz,.show
        ld hl,txt_presskey
        ld b,19*8
        call print_center
        ; μία-μία
        ld b,0
.ask:   push bc
        ld a,b
        call key_row
        ld hl,txt_ask
        ld c,44
        call print_str
        call wait_release
.wait:  call wait_frame
        call read_keys
        call scan_key
        jr nc,.wait
        pop bc
        push bc
        ld a,b                  ; key_bindings[b] = γραμμή, bit
        add a,a
        add a,b
        ld l,a
        ld h,0
        push de
        ld de,key_bindings
        add hl,de
        pop de
        ld (hl),d
        inc hl
        ld (hl),e
        call menu_sfx
        call .key
        pop bc
        inc b
        ld a,b
        cp KEYS_USER
        jr nz,.ask
        call wait_release
        ld b,25                 ; μια στιγμή να φανεί το τελευταίο
.pause: push bc
        call wait_frame
        pop bc
        djnz .pause
        ret

; Το όνομα της ενέργειας B στη σειρά της.
.name:  push bc
        RAM_ENEMIES
        pop bc
        push bc
        ld a,b
        add a,a
        ld e,a
        ld d,0
        ld hl,action_names
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        ld a,b
        call key_row
        ld c,20
        call print_str
        RAM_WORLD
        pop bc
        ret

; Το όνομα του πλήκτρου της ενέργειας B στη σειρά της.
.key:   push bc
        ld a,b
        add a,a
        add a,b
        ld l,a
        ld h,0
        ld de,key_bindings
        add hl,de
        ld d,(hl)               ; γραμμή
        inc hl
        ld e,(hl)               ; bit (μάσκα)
        ld a,-1
.bit:   inc a
        srl e
        jr nc,.bit
        ld c,a
        ld a,d
        add a,a
        add a,a
        add a,a
        add a,c                 ; γραμμή*8 + bit
        ld c,a
        add a,a
        add a,c                 ; *3 (240 bytes: χωράει σε 8 bits)
        ld e,a
        ld d,0
        RAM_ENEMIES
        ld hl,key_names
        add hl,de
        ld de,txt_key
        ld bc,3
        ldir
        RAM_WORLD
        pop bc
        push bc
        ld a,b
        call key_row
        ld hl,txt_key
        ld c,44
        call print_str
        pop bc
        ret

; A = ενέργεια -> B = γραμμή της στην οθόνη
key_row:
        add a,a
        add a,5
        add a,a
        add a,a
        add a,a
        ld b,a                  ; (5 + 2A) * 8
        ret

; Το πρώτο πατημένο πλήκτρο του keymap.
; out: CF = 1 αν βρέθηκε, D = γραμμή, E = μάσκα του bit
scan_key:
        ld hl,keymap
        ld d,0
.line:  ld a,(hl)
        cpl
        or a
        jr nz,.found
        inc hl
        inc d
        ld a,d
        cp 10
        jr nz,.line
        or a
        ret
.found: ld e,a                  ; το χαμηλότερο bit: A & -A
        neg
        and e
        ld e,a
        scf
        ret

; Περιμένει να αφεθούν όλα τα πλήκτρα (και ενημερώνει το input).
wait_release:
        call wait_frame
        call read_keys
        call scan_key
        jr c,wait_release
        jp read_input

;------------------------------------------------------------------
; High scores
;------------------------------------------------------------------

; Ο πίνακας, ως το fire ή για HI_TIME καρέ.
hiscore_screen:
        call ui_page
        ld hl,txt_hiscores
        ld b,8
        ld c,29
        call print_big
        ld hl,hiscores
        ld b,5*8
        ld e,'1'
.entry: push bc
        push de
        push hl
        ld a,e
        ld c,24
        call print_char
        pop hl
        pop de
        pop bc
        push bc
        push de
        ld c,30
        call print_name         ; HL += 3
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        push hl
        ex de,hl
        ld c,42
        call print_u16
        pop hl
        pop de
        pop bc
        ld a,b
        add a,16
        ld b,a
        inc e
        ld a,e
        cp '1'+HI_N
        jr nz,.entry
        call hud_title
        call wait_release
        ld b,HI_TIME
.wait:  push bc
        call wait_frame
        call read_input
        pop bc
        ld a,(input_new)
        and IN_FIRE
        ret nz
        djnz .wait
        ret

; Τρία γράμματα από το HL (HL += 3), B = γραμμή, C = x.
print_name:
        ld e,3
.ch:    ld a,(hl)
        inc hl
        push de
        push hl
        push bc
        call print_char
        pop bc
        pop hl
        pop de
        inc c
        inc c
        dec e
        jr nz,.ch
        ret

; Σε ποια θέση του πίνακα μπαίνει το (score).
; out: A = 0-4, ή HI_N αν δεν μπαίνει· HL -> η εγγραφή
hi_rank:
        ld hl,hiscores
        ld b,0
.cmp:   push hl
        inc hl
        inc hl
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld hl,(score)
        or a
        sbc hl,de
        pop hl
        jr z,.next              ; ίσο σκορ: ο παλιός κρατάει τη θέση
        jr nc,.found
.next:  ld de,HI_SIZE
        add hl,de
        inc b
        ld a,b
        cp HI_N
        jr nz,.cmp
.found: ld a,b
        ret

; Το τέλος του παιχνιδιού (από το main_loop, όταν τελειώσει το GAME OVER).
game_end:
        ld sp,STACK_TOP
        call hi_rank
        cp HI_N
        jr nc,.show
        ; οι από κάτω κατεβαίνουν μία θέση (η τελευταία χάνεται)
        push hl
        ld c,a
        ld a,HI_N-1
        sub c
        jr z,.last
        ld b,a                  ; (HI_N-1-θέση) * HI_SIZE bytes
        xor a
.mul:   add a,HI_SIZE
        djnz .mul
        ld c,a
        ld b,0
        ld hl,hiscores+HI_N*HI_SIZE-HI_SIZE-1
        ld de,hiscores+HI_N*HI_SIZE-1
        lddr
.last:  pop hl
        push hl
        call name_entry         ; τα γράμματα στο name_buf
        pop de
        ld hl,name_buf
        ld bc,3
        ldir
        ld hl,(score)
        ex de,hl
        ld (hl),e
        inc hl
        ld (hl),d
.show:  call hiscore_screen
        jp title

; Το όνομα του νέου ρεκόρ: πάνω/κάτω αλλάζει γράμμα, fire = επόμενο.
name_entry:
        call ui_page
        ld hl,txt_newhi
        ld b,8
        ld c,25
        call print_big
        RAM_ENEMIES
        ld hl,name_lines
        call print_lines
        RAM_WORLD
        ld hl,(score)
        ld b,7*8
        ld c,35
        call print_u16
        ld hl,name_buf
        ld (hl),'A'
        inc hl
        ld (hl),'A'
        inc hl
        ld (hl),'A'
        xor a
        ld (name_pos),a
        call wait_release
.draw:  ld hl,name_buf
        ld b,12*8
        ld c,34
        call print_big
        ld hl,txt_marks         ; ο δείκτης κάτω από το τρέχον γράμμα
        ld a,(name_pos)
        neg
        add a,2                 ; από το (2 - θέση) του "  -  "
        ld e,a
        ld d,0
        add hl,de
        ld b,14*8
        ld c,34
        call print_str
.loop:  call wait_frame
        call read_input
        ld a,(input_new)
        and IN_FIRE
        jr z,.updown
        call menu_sfx
        ld hl,name_pos
        inc (hl)
        ld a,(hl)
        cp 3
        jr c,.draw
        ret
.updown:
        ld a,(input_new)
        and IN_UP+IN_DOWN
        jr z,.held
        ld a,NAME_REPEAT
        ld (ui_timer),a
        ld a,(input_new)
        jr .step
.held:  ld a,(input)            ; κρατημένο: επανάληψη ανά 2 καρέ
        and IN_UP+IN_DOWN
        jr z,.loop
        ld hl,ui_timer
        dec (hl)
        jr nz,.loop
        ld (hl),2
        ld a,(input)
.step:  ld hl,name_buf
        ld e,a
        ld a,(name_pos)
        add a,l
        ld l,a
        jr nc,$+3
        inc h
        ld a,e
        and IN_UP
        ld a,(hl)
        jr z,.down
        inc a                   ; A..Z, κενό, A...
        cp 'Z'+1
        jr nz,.put
        ld a,' '
        jr .put
.down:  dec a
        cp 'A'-1
        jr nz,.nosp
        ld a,' '
.nosp:  cp ' '-1
        jr nz,.put
        ld a,'Z'
.put:   cp ' '+1                ; από το κενό: A (πάνω) ή Z (κάτω)
        jr nz,.store
        ld a,'A'
.store: ld (hl),a
        call menu_sfx
        jp .draw

;------------------------------------------------------------------
; Πίστες: μετάβαση, Level Complete
;------------------------------------------------------------------

; Η οθόνη πριν από την πίστα: αριθμός, όνομα, δύο γραμμές χιούμορ από το
; header της (bank 4, ήδη φορτωμένο). Ως το fire ή για LEVEL_WAIT καρέ.
level_intro:
        call ui_page
        ld a,(level)
        add a,'1'
        ld (txt_level+6),a
        ld hl,txt_level
        ld b,3*8
        ld c,33
        call print_big
        ld hl,LEVEL_HDR+LV_TEXT
        ld b,7*8
        call .line
        ld b,10*8
        call .line
        ld b,11*8
        call .line
        ld hl,txt_ready
        ld b,16*8
        call print_center
        call hud_title
        jr ui_wait
.line:  push hl                 ; κεντραρισμένο, και HL μετά το 0 του
        call print_center
        pop hl
.skip:  ld a,(hl)
        inc hl
        or a
        jr nz,.skip
        ret

; Ως το fire (ή το ESC) ή για LEVEL_WAIT καρέ. Με B: για B καρέ.
ui_wait:
        ld b,LEVEL_WAIT
ui_wait_b:
        push bc
        call wait_release
        pop bc
.wait:  push bc
        call wait_frame
        call read_input
        pop bc
        ld a,(input_new)
        and IN_FIRE+IN_PAUSE
        ret nz
        djnz .wait
        ret

; Από το main_loop όταν τελειώσουν οι εχθροί της πίστας (ως το M12, που
; τελειώνει με τον boss).
level_end:
        ld sp,STACK_TOP
        ld a,#FF
        call play_music
        call ui_page
        ld hl,txt_complete
        ld b,3*8
        ld c,25
        call print_big
        ld hl,txt_score
        ld b,8*8
        ld c,26
        call print_str
        ld hl,(score)
        ld b,8*8
        ld c,44
        call print_u16
        ld hl,txt_antsaved
        ld b,10*8
        ld c,26
        call print_str
        ld hl,(ants_saved)
        ld b,10*8
        ld c,44
        call print_u16
        ld hl,txt_thanks
        ld b,14*8
        call print_center
        call hud_title
        call ui_wait
        ld hl,level
        inc (hl)
        ld a,(hl)
        cp LEVEL_COUNT
        jp c,level_start
        ld a,mus_ending         ; και οι 8: το τέλος
        call play_music
        ld hl,cut_table+2
        call cut_play
        ld a,#FF
        call play_music
        jp game_end

;------------------------------------------------------------------
; Σκηνές της ιστορίας (το σενάριο: assets/src/cutscenes.py)
;------------------------------------------------------------------

; in: HL -> dw στο cut_table (bank 7). Fire: η οθόνη αμέσως και μετά η
; επόμενη, ESC: τέλος.
cut_play:
        ld de,CUT_BUF
        ld a,#C4
        call level_load.part
        xor a
        ld (cut_skip),a
        ld hl,CUT_BUF
.screen:
        push hl
        call ui_page
        pop hl
        xor a
        ld (cut_fast),a
.cmd:   ld a,(hl)
        inc hl
        cp #F0
        jr c,.text
        cp #FF
        ret z
        cp #FE
        jr z,.wait
        cp #FD
        jr z,.big
        cp #FC
        jr z,.sprite
        cp #FB
        jr z,.sky
        push hl                 ; #FA: ένα καρέ
        call .tick
        pop hl
        jr .cmd
.sky:   ld a,(hl)
        inc hl
        call set_sky
        jr .cmd
.sprite:
        ld b,(hl)
        inc hl
        ld c,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld a,(hl)
        inc hl
        call blit_masked
        jr .cmd
.big:   ld b,(hl)
        inc hl
        call .center
        call print_big
        inc hl
        jr .cmd
.text:  ld b,a
        call .center
.char:  ld a,(hl)
        inc hl
        or a
        jr z,.cmd
        push hl
        push bc
        call print_char
        call .tick
        pop bc
        pop hl
        inc c
        inc c
        jr .char
.wait:  ld a,(cut_skip)
        or a
        ret nz
        push hl
        ld b,CUT_WAIT
        call ui_wait_b
        pop hl
        ld a,(input_new)
        and IN_PAUSE
        jr z,.screen
        ret
; C = το x για να κεντραριστεί το κείμενο στο HL
.center:
        push hl
        ld c,40
.len:   ld a,(hl)
        inc hl
        or a
        jr z,.got
        dec c
        jr .len
.got:   pop hl
        ret
; Ένα καρέ, εκτός αν ο παίκτης βιάζεται.
.tick:  ld a,(cut_fast)
        or a
        ret nz
        call wait_frame
        call read_input
        ld a,(input_new)
        and IN_FIRE+IN_PAUSE
        ret z
        ld (cut_fast),a
        and IN_PAUSE
        ld (cut_skip),a
        ret

;------------------------------------------------------------------
; Κοινά
;------------------------------------------------------------------

; Περιμένει το επόμενο καρέ των 25 FPS.
wait_frame:
        ld a,(vbl_count)
        cp FRAME_VBLS
        jr c,wait_frame
        xor a
        ld (vbl_count),a
        jp sound_frame

; Κείμενο στο κέντρο: HL = κείμενο, B = γραμμή
print_center:
        push hl
        ld c,40
.len:   ld a,(hl)
        or a
        jr z,.go
        inc hl
        dec c
        jr .len
.go:    pop hl
        jp print_str

; Λίστα κεντραρισμένων κειμένων: db γραμμή / db "κείμενο",0 ... db #FF
print_lines:
        ld a,(hl)
        cp #FF
        ret z
        ld b,a
        inc hl
        push hl
        call print_center
        pop hl
.skip:  ld a,(hl)
        inc hl
        or a
        jr nz,.skip
        jr print_lines

txt_redefine:  db "REDEFINE KEYS",0
txt_hiscores:  db "HIGH SCORES",0
txt_newhi:     db "NEW HIGH SCORE!",0
txt_fire:      db "PRESS FIRE",0
txt_nofire:    db "          ",0
txt_presskey:  db "PRESS A KEY FOR EACH ACTION",0
txt_ask:       db "?  ",0
txt_best:      db "BEST",0
txt_credit:    db "WING C - AMSTRAD CPC - 2442",0
txt_marks:     db "  -  ",0
txt_level:     db "LEVEL 1",0
txt_ready:     db "GET READY!",0
txt_complete:  db "LEVEL COMPLETE!",0
txt_antsaved:  db "ANTS",0
txt_thanks:    db "THE ANTS SAY THANK YOU.",0

; Ο πίνακας των ρεκόρ (μόνο στη μνήμη: χάνεται στο reset)
hiscores:
        db "KAT"
        dw 5000
        db "ANT"
        dw 4000
        db "PAT"
        dw 3000
        db "MUS"
        dw 2000
        db "SFC"
        dw 1000

txt_key:   ds 3
           db 0
name_buf:  ds 3
           db 0
name_pos:  db 0
ui_timer:  db 0
