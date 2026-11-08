; hw.asm — υλικό: gate array, CRTC, interrupts, πληκτρολόγιο/joystick

GA_MODE0        equ #8C         ; gate array: mode 0, upper + lower ROM off
GA_RAM_C0       equ #C0         ; RAM config 0: τα 64K της κύριας μνήμης
GA_RAM_C4       equ #C4         ; RAM config 4: bank 4 στο #4000-#7FFF


FRAME_VBLS      equ 2           ; 50 Hz / 2 = 25 FPS

;------------------------------------------------------------------
; Interrupts και split screen
;
; Τα 6 interrupts του καρέ (300 Hz, ανά 52 γραμμές) είναι συγχρονισμένα με
; το VSYNC: το ένα πέφτει 2 γραμμές μετά την αρχή του, και μόνο αυτό βλέπει
; το bit του VSYNC στο PPI. Από εκεί μετράμε int_idx 0-5.
;
; Split screen: δύο «καρέ» του CRTC μέσα σε κάθε καρέ των 50 Hz (312 γραμμές,
; 39 σειρές), μετρημένα από την πρώτη γραμμή του παιχνιδιού:
;
;   σειρές  0-20  καρέ A: παιχνίδι, R12/R13 = κάμερα (scroll)    γρ.   0-167
;   σειρές 21-38  καρέ B: HUD (4 σειρές), border, VSYNC          γρ. 168-311
;
;   int_idx 0  γρ. 242  VSYNC (στη σειρά 30, όπως στη standard ρύθμιση).
;                       R6 = 21 για το επόμενο A: το B έχει ήδη περάσει τη
;                       σειρά 4 του, και το R6 ελέγχεται μόνο όταν ο μετρητής
;                       σειρών το συναντήσει. Γραμμένο μέσα στο A θα ερχόταν
;                       αργά: η εικόνα σβήνει στη σειρά 4 ως το επόμενο καρέ.
;   int_idx 2  γρ.  34  μέσα στο A: R4 = 20 (το A τελειώνει στη σειρά 20),
;                       R7 = 127 (χωρίς VSYNC), R12/R13 = HUD -> στην αρχή του B
;   int_idx 4  γρ. 138  μέσα στο A (σειρά 17): R6 = 4 για το HUD. Το A
;                       τελειώνει στη σειρά 20 χωρίς να ξαναπεράσει τη 4, και
;                       ως τη σειρά 4 του B (γρ. 200) μένουν 62 γραμμές για
;                       όσο κρατήσει ένα DI (blit sprite, copy_half)
;   int_idx 5  γρ. 190  μέσα στο B (σειρά 2): R4 = 17, R7 = 9 (VSYNC στη
;                       γρ. 240), R12/R13 = κάμερα -> στην αρχή του επόμενου A
;
; Κάθε εγγραφή γίνεται μακριά από την πρώτη σειρά του καρέ (εκεί ο CRTC 1
; διαβάζει το R12/R13) και πριν φτάσει ο μετρητής στο R4/R7 που αλλάζει, άρα
; δουλεύει σε όλους τους τύπους CRTC. Η πρώτη φορά ξεκινάει από τη standard
; ρύθμιση (R4 = 38, R7 = 30) και κουμπώνει από το πρώτο καρέ.
;------------------------------------------------------------------

GAME_ROWS       equ VIEW_H      ; 21
HUD_ROWS        equ 4
FRAME_ROWS      equ 39
VSYNC_ROW       equ 30

install_interrupts:
        di
        im 1
        ld a,#C3                ; JP int_handler στο #38
        ld (#38),a
        ld hl,int_handler
        ld (#39),hl
        xor a
        ld (vbl_count),a
        ld a,#80                ; ως το πρώτο VSYNC: κανένα split (δεν φτάνει 2 ή 5)
        ld (int_idx),a
        ei
        ret

int_handler:
        push af
        push bc
        ld b,PPI_B
        in a,(c)
        rra
        jr nc,.next
        ld a,(vbl_count)
        inc a
        ld (vbl_count),a
        ld bc,#BC06
        out (c),c
        ld bc,#BD00+GAME_ROWS
        out (c),c
        xor a
        jr .store
.next:  ld a,(int_idx)
        inc a
        cp 2
        jr z,.split_a
        cp 4
        jr z,.hud_r6
        cp 5
        jr z,.split_b
.store: ld (int_idx),a
        pop bc
        pop af
        ei
        ret

.split_a:
        ld (int_idx),a
        ld bc,#BC04
        out (c),c
        ld bc,#BD00+GAME_ROWS-1
        out (c),c
        ld bc,#BC07
        out (c),c
        ld bc,#BD7F
        out (c),c
        ld bc,#BC0C
        out (c),c
        ld bc,#BD00+(HUD_PAGE/4&#30)+(HUD_MA/256)
        out (c),c
        ld bc,#BC0D
        out (c),c
        ld bc,#BD00+(HUD_MA&255)
        out (c),c
        pop bc
        pop af
        ei
        ret

.hud_r6:
        ld (int_idx),a
        ld bc,#BC06
        out (c),c
        ld bc,#BD00+HUD_ROWS
        out (c),c
        pop bc
        pop af
        ei
        ret

.split_b:
        ld (int_idx),a
        ld bc,#BC04
        out (c),c
        ld bc,#BD00+FRAME_ROWS-GAME_ROWS-1
        out (c),c
        ld bc,#BC07
        out (c),c
        ld bc,#BD00+VSYNC_ROW-GAME_ROWS
        out (c),c
        ld bc,#BC0C
        out (c),c
        ld a,(game_r12)
        inc b
        out (c),a
        ld bc,#BC0D
        out (c),c
        ld a,(game_r13)
        inc b
        out (c),a
        pop bc
        pop af
        ei
        ret

;------------------------------------------------------------------
; Double buffering
;
; Ζωγραφίζουμε πάντα στη σελίδα draw_page (#80 ή #C0) ενώ ο CRTC δείχνει
; την άλλη. Το flip περιμένει να περάσουν FRAME_VBLS καρέ, γράφει στο R12/R13
; τη σελίδα που μόλις ζωγραφίστηκε και αλλάζει draw_page.
;
; Το flip τρέχει αμέσως μετά το VSYNC (γρ. 240), στο καρέ B: το R12/R13
; κλειδώνει στην αρχή του επόμενου καρέ A (γρ. 312) και η παλιά σελίδα δεν
; εμφανίζεται πια, οπότε μπορούμε να γράφουμε σε αυτήν αμέσως. Το int_idx 5
; ξαναγράφει τις ίδιες τιμές (game_r12/13) σε κάθε καρέ, γιατί το int_idx 2
; τις αντικαθιστά με του HUD.
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
        ld (game_r12),a
        ld a,l
        ld (game_r13),a
        di                      ; ο handler επιλέγει κι αυτός registers
        ld a,(game_r12)
        ld bc,#BC0C
        out (c),c
        inc b
        out (c),a
        ld bc,#BC0D
        out (c),c
        inc b
        out (c),l
        ei
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
