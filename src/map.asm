; map.asm — δοκιμαστικός χάρτης 64x48 πλακίδια (μέχρι το M11 που έρχονται
; οι πραγματικές πίστες): αστέρια, σταθμοί από ελάσματα, Σελήνη στο κάτω
; μέρος και σχάρα γύρω-γύρω, ώστε να φαίνεται πού και πόσο κινείται η κάμερα.

make_map:
        ; αστέρια παντού
        ld hl,bg_map
        ld bc,MAP_W*MAP_H
.gen:   push bc
        push hl
        call rand
        pop hl
        pop bc
        and 15
        cp 4
        jr c,.star
        xor a                   ; ti_void, τα 3/4 του ουρανού
        jr .put
.star:  inc a                   ; 1..4: star_s, star_m, stars_3, dust
.put:   ld (hl),a
        inc hl
        dec bc
        ld a,b
        or c
        jr nz,.gen

        ; Σελήνη: οι 6 τελευταίες σειρές, με κρατήρες
        ld hl,bg_map+(MAP_H-6)*MAP_W
        ld bc,6*MAP_W
.moon:  push bc
        push hl
        call rand
        pop hl
        pop bc
        and 7
        ld a,ti_moon
        jr nz,$+4
        ld a,ti_moon_crater
        ld (hl),a
        inc hl
        dec bc
        ld a,b
        or c
        jr nz,.moon

        ; σταθμοί: ορθογώνια από ελάσματα με καρφιά στο περίγραμμα
        ld b,14
.station:
        push bc
        call rand
        and 63
        cp MAP_W-9
        jr c,$+4
        sub 16
        inc a
        ld (rect_x),a
        call rand
        and 31
        add a,3
        ld (rect_y),a
        call rand
        and 3
        add a,4
        ld (rect_w),a
        call rand
        and 3
        add a,2
        ld (rect_h),a
        ld a,ti_plate_rivet
        call fill_map_rect
        ld hl,rect_x
        inc (hl)
        ld hl,rect_y
        inc (hl)
        ld hl,rect_w
        dec (hl)
        dec (hl)
        ld hl,rect_h
        dec (hl)
        dec (hl)
        ld a,ti_plate
        call fill_map_rect
        pop bc
        djnz .station

        ; σχάρα: πάνω σειρά, αριστερή και δεξιά στήλη
        ld hl,bg_map
        ld b,MAP_W
.top:   ld (hl),ti_grate
        inc hl
        djnz .top
        ld hl,bg_map
        ld de,MAP_W
        ld b,MAP_H
.side:  ld (hl),ti_grate
        push hl
        add hl,de
        dec hl
        ld (hl),ti_grate
        pop hl
        add hl,de
        djnz .side
        ret

; Γεμίζει (rect_x, rect_y, rect_w, rect_h) με το πλακίδιο A. Πλάτος ή ύψος
; 0 (ή «αρνητικό») = τίποτα.
fill_map_rect:
        ld (.tile+1),a
        ld a,(rect_w)
        or a
        ret z
        cp 128
        ret nc
        ld a,(rect_h)
        or a
        ret z
        cp 128
        ret nc
        ld b,a
        ld a,(rect_y)
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl               ; *64
        ld a,(rect_x)
        ld e,a
        ld d,bg_map/256
        add hl,de
.row:   push hl
        ld a,(rect_w)
        ld c,a
.tile:  ld (hl),0
        inc hl
        dec c
        jr nz,.tile
        pop hl
        ld de,MAP_W
        add hl,de
        djnz .row
        ret

; 16-bit xorshift (J. Metcalf). out: A, HL
rand:
seed equ $+1
        ld hl,#ACE1
        ld a,h
        rra
        ld a,l
        rra
        xor h
        ld h,a
        ld a,l
        rra
        ld a,h
        rra
        xor l
        ld l,a
        xor h
        ld h,a
        ld (seed),hl
        ret
