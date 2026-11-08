; level.asm — οι πίστες: φόρτωμα από το bank 7 και αποσυμπίεση στο bank 4
;
; Όλες οι πίστες (assets/src/levels.py) είναι συμπιεσμένες στο bank 7
; (LEVELS.BIN, το φορτώνει το DISC.BAS). Ανά πίστα δύο κομμάτια: ο χάρτης,
; που ανοίγει στο bg_map, και το header (κόσμος, μουσική, κείμενα, λίστα
; εχθρών), που ανοίγει στο LEVEL_HDR. Το bank 7 και το bank 4 βγαίνουν στο
; ίδιο παράθυρο (#4000), οπότε τα συμπιεσμένα περνούν πρώτα στη σελίδα
; #8000 της οθόνης, που στη μετάβαση δεν φαίνεται και μετά ξαναζωγραφίζεται.

LEVEL_HDR       equ #7C00       ; bank 4, ως το #7FFF
LV_WORLD        equ 0           ; 0 = διάστημα, 8 = Γη (ship_world)
LV_MUSIC        equ 1
LV_COUNT        equ 2           ; πόσοι εχθροί στη λίστα
LV_TEXT         equ 3           ; όνομα, 2 γραμμές χιούμορ, με 0 στο τέλος
STAGE           equ #8000       ; προσωρινά τα συμπιεσμένα
STAGE_SIZE      equ 2048        ; >= το μεγαλύτερο κομμάτι (levels.py)
GA_RAM_C7       equ #C7

; Η πίστα (level): χάρτης και header στο bank 4, οι μεταβλητές της.
level_load:
        ld a,(level)
        add a,a
        add a,a
        ld e,a
        ld d,0
        ld hl,level_table
        add hl,de               ; (στο bank 7)
        ld de,bg_map
        call .part
        ld de,LEVEL_HDR
        call .part
        ld a,(LEVEL_HDR+LV_WORLD)
        ld (ship_world),a
        ld a,(LEVEL_HDR+LV_COUNT)
        ld (spawn_left),a
        ld hl,LEVEL_HDR+LV_SPAWNS
        ld (spawn_ptr),hl
        ld a,(LEVEL_HDR+LV_MUSIC)
        jp play_music

; Ένα κομμάτι: HL -> dw στο level_table (bank 7), DE = πού ανοίγει (bank 4).
; out: HL -> το επόμενο dw
.part:  push de
        ld bc,#7F00+GA_RAM_C7
        out (c),c
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        push hl
        ex de,hl
        ld de,STAGE
        ld bc,STAGE_SIZE
        ldir
        RAM_WORLD
        pop hl
        pop de
        push hl
        ld hl,STAGE
        call lz_unpack
        pop hl
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
