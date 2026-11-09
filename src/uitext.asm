; uitext.asm — κείμενα του UI στο bank 5 (RAM_ENEMIES όσο διαβάζονται): η
; κύρια μνήμη είναι για ό,τι χρειάζεται την ώρα του παιχνιδιού.

title_lines:
        TROW 13
        db "1  START         ",0
        TROW 14
        db "2  REDEFINE KEYS ",0
        TROW 15
        db "3  HIGH SCORES   ",0
        TROW 16
        db "4  DIFFICULTY    ",0
        db #FF

name_lines:
        TROW 5
        db "THE ANTS WILL REMEMBER YOU.",0
        TROW 9
        db "UP/DOWN: LETTER   FIRE: NEXT",0
        db #FF

action_names:
        dw .up,.down,.left,.right,.fire,.weapon,.pause
.up:    db "UP",0
.down:  db "DOWN",0
.left:  db "LEFT",0
.right: db "RIGHT",0
.fire:  db "FIRE",0
.weapon: db "WEAPON",0
.pause: db "PAUSE",0

; Τα 80 πλήκτρα του CPC (γραμμή*8 + bit), 3 χαρακτήρες το καθένα.
key_names:
        db "UP ","RGT","DWN","F9 ","F6 ","F3 ","ENT","F. "      ; 0
        db "LFT","CPY","F7 ","F8 ","F5 ","F1 ","F2 ","F0 "      ; 1
        db "CLR","LBR","RET","RBR","F4 ","SHF","BSL","CTL"      ; 2
        db "HAT","-  ","AT ","P  ","SMC",":  ","/  ",".  "      ; 3
        db "0  ","9  ","O  ","I  ","L  ","K  ","M  ",",  "      ; 4
        db "8  ","7  ","U  ","Y  ","H  ","J  ","N  ","SPC"      ; 5
        db "6  ","5  ","R  ","T  ","G  ","F  ","B  ","V  "      ; 6
        db "4  ","3  ","E  ","W  ","S  ","D  ","C  ","X  "      ; 7
        db "1  ","2  ","ESC","Q  ","TAB","A  ","CAP","Z  "      ; 8
        db "JU ","JD ","JL ","JR ","JF2","JF1","JF3","DEL"      ; 9

