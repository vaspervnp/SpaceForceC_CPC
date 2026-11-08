; sound.asm — player μουσικής και ηχητικών εφέ για το AY-3-8912 (bank 6)
;
; Ζει στο bank 6 μαζί με τα δεδομένα του (assets/data/sound.asm, από το
; assets/src/music.py). Το καλεί το sound_frame (hw.asm) μία φορά ανά καρέ
; του παιχνιδιού, σε C6, και τρέχει όσα ticks των 50 Hz πέρασαν (snd_ticks,
; από το VSYNC): το τέμπο μένει σταθερό ακόμα κι όταν ένα καρέ αργήσει.
; Δεν τρέχει μέσα στο interrupt, γιατί τότε θα έπρεπε να ξέρει ποιο bank
; είχε ανοιχτό ο κώδικας που διέκοψε, και το AY το διαβάζει και το
; read_keys.
;
; Κανάλια A, B, C: μουσική. Ένα ηχητικό εφέ παίρνει το C (τα ντραμς)
; όσο κρατάει. Οι αιτήσεις έρχονται από την κύρια μνήμη (music_req,
; sfx_req), αφού ο υπόλοιπος κώδικας δεν βλέπει το bank 6.

CH_ON           equ 0           ; 0 = σιωπή
CH_WAIT         equ 1           ; ticks ως το επόμενο γεγονός
CH_DUR          equ 2           ; διάρκεια νότας
CH_PTR          equ 3           ; θέση στο κανάλι
CH_START        equ 5           ; αρχή, για το loop
CH_INS          equ 7           ; όργανο
CH_ENV          equ 9           ; θέση στις εντάσεις του οργάνου
CH_PER          equ 11          ; περίοδος τόνου
CH_VOL          equ 13
CH_SIZE         equ 14

SND_MAX_TICKS   equ 3           ; μετά από μεγάλη καθυστέρηση, δεν τρέχει να προλάβει

snd_update:
        ld a,(music_req)
        or a
        jr z,.nomusic
        ld e,a
        xor a
        ld (music_req),a
        ld a,e
        call music_start
.nomusic:
        ld a,(sfx_req)
        or a
        jr z,.nosfx
        ld e,a
        xor a
        ld (sfx_req),a
        ld a,e
        ld hl,sfx_cur           ; ίση ή μεγαλύτερη προτεραιότητα
        cp (hl)
        call nc,sfx_start
.nosfx:
        di
        ld a,(snd_ticks)
        ld b,a
        xor a
        ld (snd_ticks),a
        ei
        ld a,b
        or a
        ret z
        cp SND_MAX_TICKS+1
        jr c,.tick
        ld b,SND_MAX_TICKS
.tick:  push bc
        call snd_tick
        pop bc
        djnz .tick
        call snd_regs           ; οι registers μία φορά, μετά τα ticks
        jp psg_write

; in: A = κομμάτι (mus_*), ή #FF = σιωπή
music_start:
        ld ix,channels
        cp #FF
        jr nz,.song
        ld b,3
.off:   ld (ix+CH_ON),0
        ld (ix+CH_VOL),0
        ld de,CH_SIZE
        add ix,de
        djnz .off
        ret
.song:  dec a
        add a,a
        ld e,a
        add a,a
        add a,e                 ; *6
        ld e,a
        ld d,0
        ld hl,songs
        add hl,de
        ld b,3
.ch:    ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld (ix+CH_PTR),e
        ld (ix+CH_PTR+1),d
        ld (ix+CH_START),e
        ld (ix+CH_START+1),d
        ld (ix+CH_ON),1
        ld (ix+CH_WAIT),1
        ld (ix+CH_DUR),12
        ld (ix+CH_INS),ins_lead&255
        ld (ix+CH_INS+1),ins_lead/256
        ld (ix+CH_ENV),env_silent&255
        ld (ix+CH_ENV+1),env_silent/256
        ld (ix+CH_VOL),0
        ld de,CH_SIZE
        add ix,de
        djnz .ch
        ret

; in: A = εφέ (sfx_*)
sfx_start:
        ld (sfx_cur),a
        dec a
        add a,a
        add a,a
        add a,a                 ; *8
        ld e,a
        ld d,0
        ld hl,sfx_table
        add hl,de
        ld de,sfx_per
        ld bc,8
        ldir
        ld a,(sfx_decay)
        ld (sfx_dc),a
        ret

; Ένα tick των 50 Hz: τα τρία κανάλια και το εφέ.
snd_tick:
        ld ix,channels
        call chan_tick
        ld ix,channels+CH_SIZE
        call chan_tick
        ld ix,channels+2*CH_SIZE
        call chan_tick
        ld a,(sfx_len)
        or a
        ret z
        dec a
        ld (sfx_len),a
        jr nz,.sfx
        ld (sfx_cur),a          ; τελείωσε: οποιοδήποτε εφέ μπορεί να μπει
        ret
.sfx:   ld hl,(sfx_per)
        ld de,(sfx_dper)
        add hl,de
        ld (sfx_per),hl
        ld hl,sfx_dc
        dec (hl)
        ret nz
        ld a,(sfx_decay)
        ld (hl),a
        ld a,(sfx_vol)
        or a
        ret z
        dec a
        ld (sfx_vol),a
        ret

; Η τωρινή κατάσταση στο psg_regs: περίοδοι, εντάσεις, mixer, θόρυβος,
; και από πάνω το εφέ στο κανάλι C.
snd_regs:
        ld ix,channels
        ld hl,psg_regs
        ld c,%00111111          ; mixer: όλα κλειστά (1 = κλειστό)
        ld b,0                  ; κανάλι
.reg:   ld a,(ix+CH_PER)
        ld (hl),a
        inc hl
        ld a,(ix+CH_PER+1)
        ld (hl),a
        inc hl
        push hl
        ld a,b
        add a,8
        ld e,a
        ld d,0
        ld hl,psg_regs
        add hl,de
        ld a,(ix+CH_VOL)
        ld (hl),a
        ld l,(ix+CH_INS)
        ld h,(ix+CH_INS+1)
        ld e,(hl)               ; flags
        inc hl
        ld d,(hl)               ; περίοδος θορύβου
        ld a,b
        inc a                   ; bit του καναλιού: 1, 2, 4
        cp 3
        jr nz,$+3
        inc a
        ld h,a
        bit 1,e
        jr nz,.notone
        cpl
        and c
        ld c,a
.notone:
        bit 0,e
        jr z,.nonoise
        ld a,h
        add a,a
        add a,a
        add a,a                 ; bits 3-5
        cpl
        and c
        ld c,a
        ld a,d
        ld (psg_regs+6),a
.nonoise:
        pop hl
        ld de,CH_SIZE
        add ix,de
        inc b
        ld a,b
        cp 3
        jr nz,.reg
        ld a,c
        ld (psg_regs+7),a
        ; --- εφέ στο κανάλι C
        ld a,(sfx_len)
        or a
        ret z
        ld hl,(sfx_per)
        ld (psg_regs+4),hl
        ld a,(sfx_vol)
        ld (psg_regs+10),a
        ld a,(psg_regs+7)
        or %00100100            ; C: πρώτα όλα κλειστά
        ld c,a
        ld a,(sfx_noise)
        bit 7,a
        jr nz,$+4
        res 2,c                 ; τόνος
        and 31
        jr z,.done
        ld (psg_regs+6),a
        res 5,c                 ; θόρυβος
.done:  ld a,c
        ld (psg_regs+7),a
        ret

; Το κανάλι IX ένα tick: γεγονότα όταν τελειώσει η νότα, μετά η ένταση.
chan_tick:
        ld a,(ix+CH_ON)
        or a
        ret z
        dec (ix+CH_WAIT)
        jp nz,.env
        ld l,(ix+CH_PTR)
        ld h,(ix+CH_PTR+1)
.next:  ld a,(hl)
        inc hl
        cp #60
        jr c,.note
        jr z,.rest
        cp #61
        jr z,.wait
        cp #FE
        jr z,.stop
        cp #FF
        jr z,.loop
        cp #C0
        jr nc,.ins
        and #3F                 ; #80+d: διάρκεια
        ld (ix+CH_DUR),a
        jr .next
.ins:   and #3F
        add a,a
        ld e,a
        ld d,0
        push hl
        ld hl,instruments
        add hl,de
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld (ix+CH_INS),a
        ld (ix+CH_INS+1),h
        pop hl
        jr .next
.loop:  ld l,(ix+CH_START)
        ld h,(ix+CH_START+1)
        jr .next
.stop:  ld (ix+CH_ON),0
        ld (ix+CH_VOL),0
        ret
.rest:  ld (ix+CH_ENV),env_silent&255
        ld (ix+CH_ENV+1),env_silent/256
        jr .wait
.note:  push hl
        add a,a
        ld e,a
        ld d,0
        ld hl,note_periods
        add hl,de
        ld a,(hl)
        ld (ix+CH_PER),a
        inc hl
        ld a,(hl)
        ld (ix+CH_PER+1),a
        ld l,(ix+CH_INS)        ; οι εντάσεις ξεκινούν μετά τα flags, θόρυβο
        ld h,(ix+CH_INS+1)
        inc hl
        inc hl
        ld (ix+CH_ENV),l
        ld (ix+CH_ENV+1),h
        pop hl
.wait:  ld (ix+CH_PTR),l
        ld (ix+CH_PTR+1),h
        ld a,(ix+CH_DUR)
        ld (ix+CH_WAIT),a
.env:   ld l,(ix+CH_ENV)
        ld h,(ix+CH_ENV+1)
        ld a,(hl)
        cp #FF
        jr nz,.step
        dec hl                  ; τέλος: μένει η τελευταία ένταση
        ld a,(hl)
        jr .vol
.step:  inc hl
        ld (ix+CH_ENV),l
        ld (ix+CH_ENV+1),h
.vol:   ld (ix+CH_VOL),a
        ret

; Οι registers 0-10 του AY από το psg_regs, μόνο όσοι άλλαξαν από το
; psg_last (το 13 δεν γράφεται: θα ξανάρχιζε το hardware envelope, που δεν
; χρησιμοποιούμε). ~35 µs ο καθένας.
psg_write:
        ld hl,psg_regs
        ld de,psg_last
.reg:   ld a,(de)
        cp (hl)
        jr z,.same
        ld a,(hl)
        ld (de),a
        push de
        ld a,e
        sub psg_last&255
        ld e,a
        ld b,#F4                ; PPI A = αριθμός register
        out (c),e
        ld bc,#F6C0             ; select
        out (c),c
        ld bc,#F600             ; inactive
        out (c),c
        ld b,#F4
        ld a,(hl)
        out (c),a
        ld bc,#F680             ; write
        out (c),c
        ld bc,#F600
        out (c),c
        pop de
.same:  inc hl
        inc de
        ld a,e
        cp (psg_last+11)&255
        jr nz,.reg
        ret

env_silent:
        db 0,#FF

        include "../assets/data/sound.asm"

; Κατάσταση (στο bank 6)
channels:   ds 3*CH_SIZE
psg_regs:   ds 11
psg_last:   ds 11,#FF           ; ό,τι έχει ήδη ο AY (#FF: γράψ' τα την πρώτη φορά)
sfx_cur:    db 0
sfx_per:    dw 0                ; τα 8 bytes του sfx_table, με αυτή τη σειρά
sfx_dper:   dw 0
sfx_vol:    db 0
sfx_decay:  db 0
sfx_noise:  db 0
sfx_len:    db 0
sfx_dc:     db 0
