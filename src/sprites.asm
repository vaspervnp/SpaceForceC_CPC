; sprites.asm — sprite engine: λίστα, clip στην κάμερα, save-under
;
; Κάθε sprite έχει συντεταγμένες κόσμου και γραφικό με μάσκα (mask,data)
; σε ένα από τα banks (SPR_BANK: η ρύθμιση μνήμης που το βάζει στο #4000). Σε κάθε καρέ, για τη σελίδα που ζωγραφίζουμε (IX):
;
;   sprites_restore   πριν από το scroll: γράφει πίσω, με την ανάποδη σειρά,
;                     τα bytes που είχαν σωθεί κάτω από τα sprites της
;   scroll_buffer     (scroll.asm)
;   sprites_draw      για κάθε ενεργό sprite: clip στην κάμερα, σώζει τα
;                     bytes της οθόνης κάτω του και κάνει masked blit
;
; Η επαναφορά γίνεται με την κάμερα που είχε η σελίδα όταν ζωγραφίστηκαν,
; άρα οι διευθύνσεις ισχύουν ακόμα· ό,τι μετά βγει από την κάμερα το
; ξαναγράφει το scroll.
;
; Κόστος: blit + save 17 µs/byte, επαναφορά 6 µs/byte (LDIR), συν ~30 µs
; ανά γραμμή και ~100 µs ανά σειρά χαρακτήρων. Η επαναφορά δεν υπολογίζει
; διευθύνσεις: το spr_put γράφει μια κεφαλίδα 4 bytes ανά σειρά μαζί με τα
; σωσμένα bytes. Αν η στοίβα δεν χωράει το χειρότερο sprite, το sprite
; παραλείπεται σε αυτό το καρέ (δεν ξεχειλίζει ποτέ).

SPR_MAX         equ 28
SPR_FLAGS       equ 0           ; 0 = ελεύθερο
SPR_X           equ 1           ; world X (bytes)
SPR_Y           equ 2           ; world Y (γραμμές, 16-bit)
SPR_GFX         equ 4           ; γραφικό (mask,data), στο #4000-#7FFF
SPR_W           equ 6           ; bytes δεδομένων ανά γραμμή
SPR_H           equ 7           ; γραμμές
SPR_BANK        equ 8           ; ρύθμιση μνήμης: #C4 = bank 4, #C5 = bank 5
SPR_SIZE        equ 9

REC_SIZE        equ 8           ; x, y(2), w, h, σειρές, σωσμένα(2)
REC_ROWS        equ 5
REC_SAVE        equ 6
SAVE_MARGIN     equ 640         ; το μεγαλύτερο sprite (12x48) + κεφαλίδες
SAVE_SIZE       equ #780        ; bytes ανά σελίδα

; Σβήνει τα sprites της σελίδας IX (επαναφέρει το φόντο).
sprites_restore:
        ld a,(ix+BUF_NREC)
        or a
        ret z
        ld b,a
        ld (ix+BUF_NREC),0
        ; τελευταία εγγραφή = recs + (n-1)*REC_SIZE
        ld l,(ix+BUF_RECS)
        ld h,(ix+BUF_RECS+1)
        ld de,REC_SIZE
        dec a
        jr z,.rec
.mul:   add hl,de
        dec a
        jr nz,.mul
.rec:   push bc
        push hl
        ld de,3
        add hl,de
        ld a,(hl)               ; w
        ld (sp_w),a
        inc hl
        inc hl
        ld a,(hl)               ; σειρές
        ld (back_rows),a
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        ex de,hl                ; HL = σωσμένα bytes, με τις κεφαλίδες τους
        call spr_back
        pop hl
        ld de,-REC_SIZE
        add hl,de
        pop bc
        djnz .rec
        ret

; Ζωγραφίζει όλα τα ενεργά sprites στη σελίδα IX (με την κάμερά της).
sprites_draw:
        ld l,(ix+BUF_SAVE)
        ld h,(ix+BUF_SAVE+1)
        ld (save_ptr),hl
        ld de,SAVE_SIZE-SAVE_MARGIN
        add hl,de
        ld (save_limit),hl
        ld l,(ix+BUF_RECS)
        ld h,(ix+BUF_RECS+1)
        ld (rec_ptr),hl
        ld iy,spr_table
        ld b,SPR_MAX
.spr:   push bc
        ld a,(iy+SPR_FLAGS)
        or a
        jr z,.next
        call spr_clip
        jr c,.next              ; εκτός κάμερας
        ld hl,(save_ptr)        ; χωράει το χειρότερο sprite; αλλιώς παράλειψη
        ld de,(save_limit)
        or a
        sbc hl,de
        jr nc,.next
        ; εγγραφή: x, y, w, h, σειρές (μετά), πού σώζονται
        ld hl,(rec_ptr)
        ld a,(sp_x)
        ld (hl),a
        inc hl
        ld de,(sp_y)
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        ld a,(sp_w)
        ld (hl),a
        inc hl
        ld a,(sp_h)
        ld (hl),a
        inc hl
        ld (rows_ptr),hl        ; οι σειρές γράφονται μετά το blit
        inc hl
        ld de,(save_ptr)
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        ld (rec_ptr),hl
        inc (ix+BUF_NREC)
        ld b,#7F                ; το bank του γραφικού στο #4000
        ld a,(iy+SPR_BANK)
        out (c),a
        xor a
        ld (put_rows),a
        call spr_put
        ld hl,(rows_ptr)
        ld a,(put_rows)
        ld (hl),a
.next:  ld de,SPR_SIZE
        add iy,de
        pop bc
        djnz .spr
        RAM_WORLD
        ret

; Κόβει το sprite IY στην κάμερα της σελίδας IX.
; out: CF = 1 αν δεν φαίνεται καθόλου· αλλιώς sp_x, sp_y, sp_w, sp_h,
;      sp_src (πρώτο ορατό byte), sp_skip (bytes γραφικού ανάμεσα σε γραμμές)
spr_clip:
        ld a,(iy+SPR_W)         ; άδειο sprite: τίποτα (και όχι 256 γραμμές)
        or a
        scf
        ret z
        ld a,(iy+SPR_H)
        or a
        scf
        ret z
        ; --- x: όλα <= 255, με ΤΕΛΕΥΤΑΙΟ byte αντί για «ένα μετά» ---
        ld a,(ix+BUF_CX)
        add a,a
        ld c,a                  ; C = πρώτο byte της κάμερας
        add a,VIEW_W*2-1
        ld d,a                  ; D = τελευταίο byte της κάμερας
        ld b,(iy+SPR_X)         ; B = X
        ld a,(iy+SPR_W)
        dec a
        add a,b
        ld e,a                  ; E = τελευταίο byte του sprite
        cp c
        ret c                   ; όλο αριστερά
        ld a,d
        cp b
        ret c                   ; όλο δεξιά
        ld a,c
        sub b
        jr nc,$+3
        xor a
        ld (sp_left),a
        ld a,e
        sub d
        jr nc,$+3
        xor a
        ld (sp_right),a
        ld a,(sp_left)
        add a,b
        ld (sp_x),a

        ; --- y: 16-bit ---
        ld a,(ix+BUF_CY)
        ld l,a
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        ld (sp_vy0),hl          ; πρώτη γραμμή της κάμερας
        ld c,(iy+SPR_Y)
        ld b,(iy+SPR_Y+1)       ; BC = Y
        ld e,(iy+SPR_H)
        ld d,0
        dec e
        ld h,b
        ld l,c
        add hl,de               ; HL = τελευταία γραμμή του sprite
        ld (sp_ylast),hl
        ld de,(sp_vy0)
        or a
        sbc hl,de
        ret c                   ; όλο πάνω
        ld hl,(sp_vy0)
        ld de,VIEW_H*8-1
        add hl,de               ; HL = τελευταία γραμμή της κάμερας
        ld (sp_vyl),hl
        or a
        sbc hl,bc
        ret c                   ; όλο κάτω
        ; top = vy0 - Y αν θετικό
        ld hl,(sp_vy0)
        or a
        sbc hl,bc
        jr nc,.top
        ld hl,0
.top:   ld a,l
        ld (sp_top),a
        ld l,a
        ld h,0
        add hl,bc
        ld (sp_y),hl
        ; bottom = ylast - vyl αν θετικό
        ld hl,(sp_ylast)
        ld de,(sp_vyl)
        or a
        sbc hl,de
        jr nc,.bot
        ld hl,0
.bot:   ld a,(iy+SPR_H)
        sub l
        ld hl,sp_top
        sub (hl)
        ld (sp_h),a

        ; πλάτος, skip, πηγή
        ld a,(iy+SPR_W)
        ld hl,sp_left
        sub (hl)
        ld hl,sp_right
        sub (hl)
        ld (sp_w),a
        ld a,(sp_left)
        ld hl,sp_right
        add a,(hl)
        add a,a
        ld (sp_skip),a
        ; src = gfx + top*w*2 + left*2
        ld l,(iy+SPR_GFX)
        ld h,(iy+SPR_GFX+1)
        ld a,(iy+SPR_W)
        add a,a
        ld e,a
        ld d,0
        ld a,(sp_top)
        or a
        jr z,.notop
.tmul:  add hl,de
        dec a
        jr nz,.tmul
.notop: ld a,(sp_left)
        add a,a
        ld e,a
        add hl,de
        ld (sp_src),hl
        or a                    ; CF = 0: φαίνεται
        ret

; Masked blit με save-under, ανά σειρά χαρακτήρων: μέσα στη σειρά οι
; γραμμές απέχουν +#800 και ο έλεγχος για το όριο #x7FF του δαχτυλιδιού
; ισχύει για όλες, οπότε η διεύθυνση υπολογίζεται μία φορά ανά σειρά.
;
; Γρήγορος δρόμος: DI και SP = γραφικό για όλη τη σειρά (<= 8 γραμμές,
; < 1 ms: τα interrupts καθυστερούν το πολύ ~15 γραμμές, ενώ το split
; screen αντέχει 50+, hw.asm). Ανά γραμμή, άλμα μέσα στο ξεδιπλωμένο
; put_unroll ώστε να εκτελεστούν ακριβώς w φορές τα «POP BC (C = μάσκα,
; B = δεδομένα) / σώσε στο (HL') / AND C / OR B»: 17 µs/byte, ~30 µs/γραμμή.
; Αργός δρόμος: σειρά που περνάει το #x7FF (σπάνια), byte-byte.
; in: sp_src, sp_x, sp_y, sp_w, sp_h, sp_skip, save_ptr
spr_put:
        push iy
        ld a,(sp_w)
        ld (.ws+1),a
        ld (.wc+1),a
        ld l,a                  ; είσοδος = put_unroll_end - w*PUT_LEN
        ld h,0
        add hl,hl
        ld e,l
        ld d,h
        add hl,hl
        add hl,hl
        add hl,de               ; w*10
        ex de,hl
        ld hl,put_unroll_end
        or a
        sbc hl,de
        ld (.entry+1),hl
        ld a,(sp_skip)
        ld (.skip+1),a
        ld (.sskip+1),a
        ld a,(sp_h)
        ld (line_n),a
        ld hl,(sp_y)
        ld (line_y),hl
        ld hl,(sp_src)
        ld (sp_cur),hl
        exx
        ld hl,(save_ptr)
        exx
.row:   call row_setup          ; DE, IYL = γραμμές
        ld hl,put_rows
        inc (hl)
        xor a                   ; περνάει η σειρά το #x7FF; (A = 1)
        ld b,a
        ld a,d
        and 7
        cp 7
        jr nz,.hdr
        ld a,e
.wc:    add a,0
        rl b
.hdr:   ld a,b
        ld (row_slow),a
        ; κεφαλίδα στα σωσμένα: διεύθυνση, περνάει;, γραμμές
        push de
        exx
        pop de
        ld (hl),e
        inc hl
        ld (hl),d
        inc hl
        ld (hl),a
        inc hl
        ld a,iyl
        ld (hl),a
        inc hl
        exx
        ld a,(row_slow)
        or a
        jr nz,.slow
.fast:  ld hl,(sp_cur)
        di
        ld (.sp+1),sp
        ld sp,hl
.fl:    ld h,d                  ; HL = αρχή της γραμμής
        ld l,e
.entry: jp 0
.back:  ex de,hl                ; DE = αρχή της γραμμής
.skip:  ld hl,0                 ; προς την επόμενη γραμμή του γραφικού
        add hl,sp
        ld sp,hl
        ld a,d
        add a,8
        ld d,a
        dec iyl
        jr nz,.fl
        ld (sp_cur),sp
.sp:    ld sp,0
        ei
        jr .rowdone
.slow:  ld hl,(sp_cur)
.sline: push de
.ws:    ld b,0
.spx:   ld a,(de)
        exx
        ld (hl),a
        inc hl
        exx
        and (hl)
        inc hl
        or (hl)
        inc hl
        ld (de),a
        inc e
        jr nz,.sok
        ld a,d                  ; #x7FF -> #x000 του ίδιου block
        sub 7
        ld d,a
.sok:   djnz .spx
        pop de
.sskip: ld bc,0
        add hl,bc
        ld a,d
        add a,8
        ld d,a
        dec iyl
        jr nz,.sline
        ld (sp_cur),hl
.rowdone:
        ld a,(line_n)
        or a
        jp nz,.row
        exx
        ld (save_ptr),hl
        exx
        pop iy
        ret

PUT_LEN         equ 10          ; bytes κώδικα ανά byte sprite
PUT_MAX_W       equ 12          ; ο boss: 24 pixels

put_unroll:
        repeat PUT_MAX_W
        pop bc
        ld a,(de)
        exx
        ld (hl),a
        inc hl
        exx
        and c
        or b
        ld (de),a
        inc de
        rend
put_unroll_end:
        jp spr_put.back

        assert put_unroll_end-put_unroll == PUT_LEN*PUT_MAX_W, "PUT_LEN"

; Γράφει πίσω τα σωσμένα bytes μιας εγγραφής. Κάθε σειρά χαρακτήρων
; ξεκινάει με την κεφαλίδα που έγραψε το spr_put (διεύθυνση, περνάει το
; #x7FF;, γραμμές), οπότε εδώ δεν υπολογίζεται καμία διεύθυνση.
; in: HL = σωσμένα, sp_w, back_rows
spr_back:
        push iy
        ld a,(sp_w)
        ld (.wf+1),a
        ld (.ws+1),a
.row:   ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld a,(hl)               ; 1 = περνάει το #x7FF
        inc hl
        ld c,(hl)               ; γραμμές
        inc hl
        ld iyl,c
        or a
        jr nz,.slow
.fast:  push de
.wf:    ld bc,0
        ldir
        pop de
        ld a,d
        add a,8
        ld d,a
        dec iyl
        jr nz,.fast
        jr .rowdone
.slow:  push de
.ws:    ld b,0
.spx:   ld a,(hl)
        ld (de),a
        inc hl
        inc e
        jr nz,.sok
        ld a,d
        sub 7
        ld d,a
.sok:   djnz .spx
        pop de
        ld a,d
        add a,8
        ld d,a
        dec iyl
        jr nz,.slow
.rowdone:
        ld a,(back_rows)
        dec a
        ld (back_rows),a
        jr nz,.row
        pop iy
        ret

; Αρχή σειράς χαρακτήρων: DE = διεύθυνση της γραμμής line_y, IYL = πόσες
; γραμμές μένουν ως το τέλος της σειράς (ή του sprite)· line_y και line_n
; προχωράνε κατά τόσες.
row_setup:
        ld a,(line_y)
        and 7
        neg
        add a,8
        ld b,a                  ; ως το τέλος της σειράς
        ld a,(line_n)
        cp b
        jr c,.n
        ld a,b
.n:     ld iyl,a
        ld b,a
        ld a,(line_n)
        sub b
        ld (line_n),a
        ld a,(sp_x)
        ld c,a
        ld hl,(line_y)
        call world_addr         ; DE (κρατάει HL)
        ld a,iyl
        add a,l
        ld l,a
        jr nc,.s
        inc h
.s:     ld (line_y),hl
        ret
