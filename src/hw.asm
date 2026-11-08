; hw.asm — υλικό: gate array, CRTC, interrupts, πληκτρολόγιο/joystick

GA_MODE0        equ #8C         ; gate array: mode 0, upper + lower ROM off
GA_RAM_C0       equ #C0         ; RAM config 0: τα 64K της κύριας μνήμης
FRAME_VBLS      equ 2           ; 50 Hz / 2 = 25 FPS

;------------------------------------------------------------------
; Interrupts: IM 1, ο handler μετράει μόνο τα VSYNC.
; Από τα 6 interrupts του καρέ (300 Hz) μόνο ένα πέφτει μέσα στο VSYNC
; (2 γραμμές μετά την αρχή του), άρα ο έλεγχος του PPI αρκεί.
;------------------------------------------------------------------

install_interrupts:
        di
        im 1
        ld a,#C3                ; JP int_handler στο #38
        ld (#38),a
        ld hl,int_handler
        ld (#39),hl
        xor a
        ld (vbl_count),a
        ei
        ret

int_handler:
        push af
        push bc
        ld b,PPI_B
        in a,(c)
        rra
        jr nc,.done
        ld a,(vbl_count)
        inc a
        ld (vbl_count),a
.done:  pop bc
        pop af
        ei
        ret

;------------------------------------------------------------------
; Double buffering
;
; Ζωγραφίζουμε πάντα στη σελίδα draw_page (#80 ή #C0) ενώ ο CRTC δείχνει
; την άλλη. Το flip περιμένει να περάσουν FRAME_VBLS καρέ, γράφει στο R12
; τη σελίδα που μόλις ζωγραφίστηκε και αλλάζει draw_page.
;
; Το R12/R13 κλειδώνει στην αρχή του επόμενου καρέ, που είναι ~8 σειρές
; χαρακτήρων ΜΕΤΑ το VSYNC (στο πάνω border). Από το VSYNC μέχρι εκεί η
; παλιά σελίδα δεν εμφανίζεται πια, οπότε μπορούμε να αρχίσουμε να
; γράφουμε σε αυτήν αμέσως.
;------------------------------------------------------------------

flip:
        ld hl,vbl_count
        ld a,(hl)
        cp FRAME_VBLS
        jr c,.wait
        ; Αργήσαμε: είμαστε στη μέση του καρέ. Αν αλλάζαμε σελίδα τώρα θα
        ; γράφαμε σε ό,τι εμφανίζεται, οπότε περιμένουμε το επόμενο VSYNC.
        ld de,(late_frames)
        inc de
        ld (late_frames),de
        ld a,(hl)
.late:  cp (hl)
        jr z,.late
        jr .swap
.wait:  ld a,(hl)
        cp FRAME_VBLS
        jr c,.wait
.swap:  ld (hl),0
        ld a,(draw_page)
        ld hl,(show_ma)
        call show_page
        ld a,(draw_page)
        xor #40                 ; #80 <-> #C0
        ld (draw_page),a
        ret

; in: A = high byte της σελίδας (#80 ή #C0), HL = MA της πάνω αριστερής
; γωνίας (0-1023, scroll.asm)
show_page:
        rrca                    ; #80 -> #20, #C0 -> #30 (R12 bits 5-4)
        rrca
        and #30
        or h                    ; MA bits 9-8
        ld bc,#BC0C
        out (c),c
        inc b
        out (c),a
        ld bc,#BC0D
        out (c),c
        inc b
        out (c),l
        ret

;------------------------------------------------------------------
; Παλέτα
;------------------------------------------------------------------

set_palette:
        ld hl,palette_hw
        ld bc,#7F00
.pen:   out (c),c               ; επιλογή pen
        ld a,(hl)
        inc hl
        out (c),a               ; χρώμα (hardware value, ήδη με bit 6)
        inc c
        ld a,c
        cp 16
        jr nz,.pen
        ld a,(palette_hw)       ; border = pen 0
        jp set_border

; in: A = hardware χρώμα (#40-#5F)
set_border:
        ld bc,#7F10
        out (c),c
        out (c),a
        ret

;------------------------------------------------------------------
; Πληκτρολόγιο και joystick
;------------------------------------------------------------------

; Διαβάζει και τις 10 γραμμές του πίνακα πλήκτρων (PSG reg 14 μέσω PPI)
; στο keymap. Bit = 0 σημαίνει πατημένο. Η γραμμή 9 είναι το joystick 0.
read_keys:
        ld hl,keymap
        ld bc,#F40E             ; PSG: επιλογή reg 14
        out (c),c
        ld bc,#F6C0             ; PSG: select register
        out (c),c
        xor a                   ; PSG: inactive
        out (c),a
        ld bc,#F792             ; PPI port A = είσοδος
        out (c),c
        ld a,#40                ; PSG read + γραμμή 0
.line:  ld b,#F6
        out (c),a
        ld b,#F4
        in e,(c)
        ld (hl),e
        inc hl
        inc a
        cp #4A
        jr nz,.line
        ld bc,#F782             ; PPI port A = έξοδος
        out (c),c
        ld bc,#F600             ; PSG: inactive
        out (c),c
        ret

; Ενέργειες του παίκτη, ένα bit η καθεμία.
IN_UP           equ 1
IN_DOWN         equ 2
IN_LEFT         equ 4
IN_RIGHT        equ 8
IN_FIRE         equ 16
IN_WEAPON       equ 32
IN_PAUSE        equ 64

; Διαβάζει πληκτρολόγιο + joystick και τα μεταφράζει σε ενέργειες μέσω
; του key_bindings. out: (input) = κρατημένα, (input_new) = όσα πατήθηκαν
; σε αυτό το καρέ.
read_input:
        call read_keys
        ld hl,key_bindings
        ld c,0
.next:  ld a,(hl)               ; γραμμή
        cp #FF
        jr z,.done
        inc hl
        ld e,a
        ld d,0
        push hl
        ld hl,keymap
        add hl,de
        ld a,(hl)
        pop hl
        and (hl)                ; bit του πλήκτρου: 0 = πατημένο
        inc hl
        jr nz,.up
        ld a,c
        or (hl)
        ld c,a
.up:    inc hl
        jr .next
.done:  ld a,(input)
        cpl
        and c
        ld (input_new),a
        ld a,c
        ld (input),a
        ret

; Αντιστοιχίσεις: γραμμή, bit mask, ενέργεια. Είναι στη RAM ώστε το μενού
; του M9 να τις ξαναγράφει. Πολλά πλήκτρα μπορούν να δίνουν την ίδια ενέργεια.
key_bindings:
        ; κέρσορες + Space
        db 0,%00000001,IN_UP
        db 0,%00000100,IN_DOWN
        db 1,%00000001,IN_LEFT
        db 0,%00000010,IN_RIGHT
        db 5,%10000000,IN_FIRE
        ; Q A O P
        db 8,%00001000,IN_UP
        db 8,%00100000,IN_DOWN
        db 4,%00000100,IN_LEFT
        db 3,%00001000,IN_RIGHT
        ; W: όπλο, ESC: παύση
        db 7,%00001000,IN_WEAPON
        db 8,%00000100,IN_PAUSE
        ; joystick 0
        db 9,%00000001,IN_UP
        db 9,%00000010,IN_DOWN
        db 9,%00000100,IN_LEFT
        db 9,%00001000,IN_RIGHT
        db 9,%00100000,IN_FIRE
        db 9,%00010000,IN_WEAPON
        db #FF
        ds 3*8                  ; χώρος για επιπλέον αντιστοιχίσεις
