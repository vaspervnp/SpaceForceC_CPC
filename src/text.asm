; text.asm — κείμενο με τη γραμματοσειρά 4x8 του HUD (40 χαρακτήρες/γραμμή)
;
; Το HUD είναι πάντα μαύρο από κάτω, οπότε ο γλύφος γράφεται αδιαφανής: μόνο
; τα bytes δεδομένων (pen 0 = μαύρο). Σβήνει έτσι και ό,τι ήταν εκεί πριν,
; χωρίς καθάρισμα. Η γραμμή B είναι πολλαπλάσιο του 8 (όριο σειράς), ώστε η
; διεύθυνση να υπολογίζεται μία φορά ανά γλύφο: ~0,2 ms ο χαρακτήρας.

; in: HL = κείμενο με 0 στο τέλος, B = γραμμή, C = byte x
print_str:
        ld a,(hl)
        or a
        ret z
        inc hl
        push hl
        push bc
        call print_char
        pop bc
        pop hl
        inc c
        inc c
        jr print_str

; in: A = χαρακτήρας ASCII, B = γραμμή, C = byte x
print_char:
        sub 32
        ld e,a
        ld d,0
        ld hl,font_map
        add hl,de
        ld l,(hl)
        ld h,0
        add hl,hl               ; *32 = FONT_SZ
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld de,font_gfx+1        ; τα bytes δεδομένων (mask,data)
        add hl,de
        call scr_addr
        ld b,FONT_H
.line:  ld a,(hl)
        ld (de),a
        inc hl
        inc hl
        inc de                  ; μέσα στο block: γραμμικό ως το #x7FF
        ld a,(hl)
        ld (de),a
        inc hl
        inc hl
        dec de
        ld a,d
        add a,8
        ld d,a
        djnz .line
        ret

; Τυπώνει αριθμό 0-65535 με 5 ψηφία.
; in: HL = αριθμός, B = γραμμή, C = byte x
print_u16:
        ld de,10000
        call .digit
        ld de,1000
        call .digit
        ld de,100
        call .digit
        ld de,10
        call .digit
        ld de,1
.digit: ld a,'0'-1
.sub:   inc a
        or a                    ; CF = 0
        sbc hl,de
        jr nc,.sub
        add hl,de
        push hl
        push bc
        call print_char
        pop bc
        pop hl
        inc c
        inc c
        ret

; ASCII 32..95 -> γλύφος (άγνωστοι χαρακτήρες -> κενό)
font_map:
        db ch_32,ch_33,ch_32,ch_32,ch_32,ch_37,ch_32,ch_32     ; ' '..'''
        db ch_40,ch_41,ch_42,ch_43,ch_44,ch_45,ch_46,ch_47     ; '('..'/'
        db ch_48,ch_49,ch_50,ch_51,ch_52,ch_53,ch_54,ch_55     ; '0'..'7'
        db ch_56,ch_57,ch_58,ch_32,ch_32,ch_32,ch_32,ch_63     ; '8'..'?'
        db ch_32,ch_65,ch_66,ch_67,ch_68,ch_69,ch_70,ch_71     ; '@'..'G'
        db ch_72,ch_73,ch_74,ch_75,ch_76,ch_77,ch_78,ch_79     ; 'H'..'O'
        db ch_80,ch_81,ch_82,ch_83,ch_84,ch_85,ch_86,ch_87     ; 'P'..'W'
        db ch_88,ch_89,ch_90,ch_32,ch_32,ch_32,ch_32,ch_32     ; 'X'..'_'
