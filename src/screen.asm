; screen.asm — η σταθερή (χωρίς scroll) οθόνη του HUD και οι blitters της
;
; Το HUD είναι το δεύτερο «καρέ» του CRTC (split screen, hw.asm): 4 σειρές x
; 40 words στη φυσική σελίδα #4000, στα MA 864-1023, δηλαδή στα τελευταία
; 320 bytes κάθε block των 2K (#x6C0-#x7FF). Το video διαβάζει πάντα την
; κύρια μνήμη, οπότε το HUD φαίνεται ακόμα και όταν η CPU έχει βάλει άλλο
; bank στο #4000. Δεν έχει double buffer: γράφεται σπάνια και σε λίγα σημεία.

HUD_PAGE        equ #40
HUD_MA          equ 1024-HUD_ROWS*VIEW_W        ; 864
HUD_OFFSET      equ HUD_MA*2                    ; #6C0
HUD_LINES       equ HUD_ROWS*8                  ; 32

; Το κείμενο (text.asm) γράφει στη σελίδα text_page, με αρχή text_off:
; στο HUD (text_to_hud) ή σε μια ολόκληρη οθόνη χωρίς scroll (text_to_page).

text_to_hud:
        ld a,HUD_PAGE
        ld hl,HUD_OFFSET
        jr text_set
; in: A = σελίδα (#80 ή #C0)
text_to_page:
        ld hl,0
text_set:
        ld (text_page),a
        ld (text_off),hl
        ret

; in: B = γραμμή (στο HUD 0-31, σε σελίδα 0-199), C = byte x
; out: DE   (κρατάει HL)
scr_addr:
        push hl
        ld a,b
        and #F8                 ; σειρά*8
        ld l,a
        ld h,0
        add hl,hl               ; σειρά*16
        ld e,l
        ld d,h
        add hl,hl
        add hl,hl               ; σειρά*64
        add hl,de               ; σειρά*80
        ld e,c
        ld d,0
        add hl,de
        ld de,(text_off)
        add hl,de               ; <= #7FF
        ld e,l
        ld a,b
        and 7
        add a,a
        add a,a
        add a,a
        or h
        ld hl,text_page
        or (hl)
        ld d,a
        pop hl
        ret

; Καθαρίζει το HUD (τα 320 bytes σε καθένα από τα 8 blocks).
clear_hud:
        ld hl,HUD_PAGE*256+HUD_OFFSET
        ld b,8
.block: push bc
        push hl
        ld d,h
        ld e,l
        inc de
        ld (hl),0
        ld bc,HUD_ROWS*VIEW_W*2-1
        ldir
        pop hl
        ld a,h
        add a,8
        ld h,a
        pop bc
        djnz .block
        ret

; Καθαρίζει το back buffer του παιχνιδιού.
clear_page:
        ld a,(draw_page)
; in: A = σελίδα
clear_page_a:
        ld h,a
        ld l,0
        ld d,a
        ld e,1
        ld bc,#3FFF
        ld (hl),0
        ldir
        ret

; Masked sprite σε σελίδα χωρίς scroll (title): μία διεύθυνση ανά γραμμή.
; in: HL = γραφικό (mask,data), B = γραμμή, C = byte x, D = ύψος, A = πλάτος
blit_masked:
        ld (.w+1),a
.row:   push bc
        push de
        call scr_addr
.w:     ld b,0
.px:    ld a,(de)
        and (hl)
        inc hl
        or (hl)
        inc hl
        ld (de),a
        inc de
        djnz .px
        pop de
        pop bc
        inc b
        dec d
        jr nz,.row
        ret
