; level.asm — οι πίστες: φόρτωμα από το bank 7 και αποσυμπίεση στο bank 4
;
; Όλες οι πίστες (assets/src/levels.py) είναι συμπιεσμένες στο bank 7
; (LEVELS.BIN, το φορτώνει το DISC.BAS). Ανά πίστα πέντε κομμάτια: ο χάρτης,
; που ανοίγει στο bg_map, το header (κόσμος, μουσική, κείμενα, λίστα εχθρών),
; που ανοίγει στο LEVEL_HDR, ο boss στο BOSS_GFX του bank 5, τα πλακίδια της
; στα tiles_gfx και οι δύο εχθροί της στο bank 5. Τα τρία τελευταία τα
; μοιράζονται πίστες και είναι στο bank 6, μετά τον ήχο (bit 15 της διεύθυνσης
; στον πίνακα). Το bank 7 και το bank 4 βγαίνουν στο
; ίδιο παράθυρο (#4000), οπότε τα συμπιεσμένα περνούν πρώτα στη σελίδα
; #8000 της οθόνης, που στη μετάβαση δεν φαίνεται και μετά ξαναζωγραφίζεται.

LEVEL_HDR       equ #7C00       ; bank 4, ως το #7FFF
LV_WORLD        equ 0           ; 0 = διάστημα, 8 = Γη (ship_world)
LV_MUSIC        equ 1
LV_COUNT        equ 2           ; πόσοι εχθροί στη λίστα
LV_BOSS         equ 3           ; 0 = χωρίς boss (οι παράμετροι: boss.asm)
LV_SKY          equ 4           ; το χρώμα του pen 0 (gate array)
LV_TEXT         equ 5           ; όνομα, 2 γραμμές χιούμορ, με 0 στο τέλος
STAGE           equ #8000       ; προσωρινά τα συμπιεσμένα
STAGE_SIZE      equ 2048        ; >= το μεγαλύτερο κομμάτι (levels.py)
GA_RAM_C7       equ #C7

; Η πίστα (level): χάρτης και header στο bank 4, οι μεταβλητές της.
level_load:
        ld a,(level)
        add a,a
        ld e,a
        add a,a
        add a,a
        add a,e                 ; *10
        ld e,a
        ld d,0
        ld hl,level_table
        add hl,de               ; (στο bank 7)
        ld de,bg_map
        ld a,#C4
        call .part
        ld de,LEVEL_HDR
        ld a,#C4
        call .part
        ld de,BOSS_GFX
        ld a,#C5
        call .part
        ld de,tiles_gfx
        ld a,#C4
        call .part
        ld de,enemies_gfx+MOBS_OFF
        ld a,#C5
        call .part
        call make_halftiles     ; από τα νέα πλακίδια
        ld a,(LEVEL_HDR+LV_WORLD)
        ld (ship_world),a
        ld a,(LEVEL_HDR+LV_COUNT)
        ld (spawn_left),a
        ld hl,LEVEL_HDR+LV_SPAWNS
        ld (spawn_ptr),hl
        ld a,(LEVEL_HDR+LV_MUSIC)
        jp play_music

; Ένα κομμάτι: HL -> dw στο level_table (bank 7), DE = πού ανοίγει, A = σε
; ποια ρύθμιση μνήμης. out: HL -> το επόμενο dw
.part:  ld (.cfg+1),a
        push de
        ld bc,#7F00+GA_RAM_C7
        out (c),c
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        push hl
        ex de,hl
        bit 7,h                 ; bit 15: στο bank 6
        jr z,.copy
        res 7,h
        ld bc,#7F00+GA_RAM_C6
        out (c),c
.copy:  ld de,STAGE
        ld bc,STAGE_SIZE
        ldir
.cfg:   ld a,0
        ld b,#7F
        out (c),a
        pop hl
        pop de
        push hl
        ld hl,STAGE
        call lz_unpack
        RAM_WORLD
        pop hl
        ret

; Το pen 0: ο ουρανός της πίστας, μαύρο στις οθόνες. in: A = χρώμα (gate array)
set_sky:
        ld bc,#7F00
        out (c),c
        out (c),a
        ret

; Αποσυμπίεση (η μορφή είναι στο levels.py). in: HL = από, DE = προς
lz_unpack:
        ld a,(hl)
        inc hl
        or a
        ret z
        jp m,.match
        ld c,a                  ; #01-#7F: τόσα bytes όπως είναι
        ld b,0
        ldir
        jr lz_unpack
.match: and #7F                 ; #80+k: k+3 bytes από απόσταση o πίσω
        add a,3
        ld c,a
        ld b,0
        ld a,(hl)
        inc hl
        push hl
        ld h,(hl)
        ld l,a
        ld a,e
        sub l
        ld l,a
        ld a,d
        sbc a,h
        ld h,a
        ldir                    ; byte-byte: η επικάλυψη επαναλαμβάνει
        pop hl
        inc hl
        jr lz_unpack
