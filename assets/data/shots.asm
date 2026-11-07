; shots.asm — βλήματα παίκτη και εχθρών, Amstrad CPC Mode 0
; ΠΑΡΑΓΕΤΑΙ ΑΥΤΟΜΑΤΑ από assets/src/make_assets.py.
;
; 46 καρέ, 2944 bytes.
; Τα κατευθυνόμενα έχουν 8 όψεις (3 ζωγραφισμένες), τα
; απλωτά 3 καρέ κίνησης. Όλα 8x8 — ένα μέγεθος, ένα blit.
;
; Όλα ίδιο μέγεθος: offset = index * SHOTS_SZ, χωρίς πίνακα.

SHOTS_W        equ 4     ; bytes ΔΕΔΟΜΕΝΩΝ (στη μνήμη το ΔΙΠΛΟ) ανά γραμμή
SHOTS_H        equ 8     ; γραμμές
SHOTS_SZ       equ 64    ; bytes ανά καρέ

sh_disco_n0            equ 0    ; disco n φάση 0
sh_disco_n1            equ 1    ; disco n φάση 1
sh_disco_ne0           equ 2    ; disco ne φάση 0
sh_disco_ne1           equ 3    ; disco ne φάση 1
sh_disco_e0            equ 4    ; disco e φάση 0
sh_disco_e1            equ 5    ; disco e φάση 1
sh_disco_se0           equ 6    ; disco se φάση 0
sh_disco_se1           equ 7    ; disco se φάση 1
sh_disco_s0            equ 8    ; disco s φάση 0
sh_disco_s1            equ 9    ; disco s φάση 1
sh_disco_sw0           equ 10   ; disco sw φάση 0
sh_disco_sw1           equ 11   ; disco sw φάση 1
sh_disco_w0            equ 12   ; disco w φάση 0
sh_disco_w1            equ 13   ; disco w φάση 1
sh_disco_nw0           equ 14   ; disco nw φάση 0
sh_disco_nw1           equ 15   ; disco nw φάση 1
sh_baguette_n0         equ 16   ; baguette n φάση 0
sh_baguette_ne0        equ 17   ; baguette ne φάση 0
sh_baguette_e0         equ 18   ; baguette e φάση 0
sh_baguette_se0        equ 19   ; baguette se φάση 0
sh_baguette_s0         equ 20   ; baguette s φάση 0
sh_baguette_sw0        equ 21   ; baguette sw φάση 0
sh_baguette_w0         equ 22   ; baguette w φάση 0
sh_baguette_nw0        equ 23   ; baguette nw φάση 0
sh_spaghetti_n0        equ 24   ; spaghetti n φάση 0
sh_spaghetti_ne0       equ 25   ; spaghetti ne φάση 0
sh_spaghetti_e0        equ 26   ; spaghetti e φάση 0
sh_spaghetti_se0       equ 27   ; spaghetti se φάση 0
sh_spaghetti_s0        equ 28   ; spaghetti s φάση 0
sh_spaghetti_sw0       equ 29   ; spaghetti sw φάση 0
sh_spaghetti_w0        equ 30   ; spaghetti w φάση 0
sh_spaghetti_nw0       equ 31   ; spaghetti nw φάση 0
sh_torpedo_n0          equ 32   ; torpedo n φάση 0
sh_torpedo_ne0         equ 33   ; torpedo ne φάση 0
sh_torpedo_e0          equ 34   ; torpedo e φάση 0
sh_torpedo_se0         equ 35   ; torpedo se φάση 0
sh_torpedo_s0          equ 36   ; torpedo s φάση 0
sh_torpedo_sw0         equ 37   ; torpedo sw φάση 0
sh_torpedo_w0          equ 38   ; torpedo w φάση 0
sh_torpedo_nw0         equ 39   ; torpedo nw φάση 0
sh_sneeze0             equ 40   ; sneeze φάση 0
sh_sneeze1             equ 41   ; sneeze φάση 1
sh_sneeze2             equ 42   ; sneeze φάση 2
sh_e90                 equ 43   ; e9 φάση 0
sh_e91                 equ 44   ; e9 φάση 1
sh_e92                 equ 45   ; e9 φάση 2

shots_gfx:
  ; sh_disco_n0
  db #FF,#00,#00,#CB,#00,#C7,#FF,#00,#FF,#00,#00,#CB,#00,#C7,#FF,#00
  db #FF,#00,#00,#CB,#00,#C7,#FF,#00,#FF,#00,#00,#CB,#00,#C7,#FF,#00
  db #FF,#00,#00,#CB,#00,#C7,#FF,#00,#FF,#00,#00,#CB,#00,#C7,#FF,#00
  db #FF,#00,#00,#CB,#00,#C7,#FF,#00,#FF,#00,#00,#CB,#00,#C7,#FF,#00
  ; sh_disco_n1
  db #FF,#00,#00,#C7,#00,#CB,#FF,#00,#FF,#00,#00,#C7,#00,#CB,#FF,#00
  db #FF,#00,#00,#C7,#00,#CB,#FF,#00,#FF,#00,#00,#C7,#00,#CB,#FF,#00
  db #FF,#00,#00,#C7,#00,#CB,#FF,#00,#FF,#00,#00,#C7,#00,#CB,#FF,#00
  db #FF,#00,#00,#C7,#00,#CB,#FF,#00,#FF,#00,#00,#C7,#00,#CB,#FF,#00
  ; sh_disco_ne0
  db #FF,#00,#FF,#00,#FF,#00,#00,#CB,#FF,#00,#FF,#00,#FF,#00,#00,#CB
  db #FF,#00,#FF,#00,#AA,#45,#55,#82,#FF,#00,#FF,#00,#AA,#45,#55,#82
  db #FF,#00,#FF,#00,#00,#CB,#FF,#00,#FF,#00,#FF,#00,#00,#CB,#FF,#00
  db #FF,#00,#AA,#45,#55,#82,#FF,#00,#FF,#00,#AA,#45,#55,#82,#FF,#00
  ; sh_disco_ne1
  db #FF,#00,#FF,#00,#FF,#00,#00,#C7,#FF,#00,#FF,#00,#FF,#00,#00,#C7
  db #FF,#00,#FF,#00,#AA,#41,#55,#8A,#FF,#00,#FF,#00,#AA,#41,#55,#8A
  db #FF,#00,#FF,#00,#00,#C7,#FF,#00,#FF,#00,#FF,#00,#00,#C7,#FF,#00
  db #FF,#00,#AA,#41,#55,#8A,#FF,#00,#FF,#00,#AA,#41,#55,#8A,#FF,#00
  ; sh_disco_e0
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  db #00,#CF,#00,#CF,#00,#CF,#00,#CF,#00,#C3,#00,#C3,#00,#C3,#00,#C3
  db #00,#C3,#00,#C3,#00,#C3,#00,#C3,#00,#CF,#00,#CF,#00,#CF,#00,#CF
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  ; sh_disco_e1
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  db #00,#C3,#00,#C3,#00,#C3,#00,#C3,#00,#CF,#00,#CF,#00,#CF,#00,#CF
  db #00,#CF,#00,#CF,#00,#CF,#00,#CF,#00,#C3,#00,#C3,#00,#C3,#00,#C3
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  ; sh_disco_se0
  db #FF,#00,#AA,#45,#55,#82,#FF,#00,#FF,#00,#AA,#45,#55,#82,#FF,#00
  db #FF,#00,#FF,#00,#00,#CB,#FF,#00,#FF,#00,#FF,#00,#00,#CB,#FF,#00
  db #FF,#00,#FF,#00,#AA,#45,#55,#82,#FF,#00,#FF,#00,#AA,#45,#55,#82
  db #FF,#00,#FF,#00,#FF,#00,#00,#CB,#FF,#00,#FF,#00,#FF,#00,#00,#CB
  ; sh_disco_se1
  db #FF,#00,#AA,#41,#55,#8A,#FF,#00,#FF,#00,#AA,#41,#55,#8A,#FF,#00
  db #FF,#00,#FF,#00,#00,#C7,#FF,#00,#FF,#00,#FF,#00,#00,#C7,#FF,#00
  db #FF,#00,#FF,#00,#AA,#41,#55,#8A,#FF,#00,#FF,#00,#AA,#41,#55,#8A
  db #FF,#00,#FF,#00,#FF,#00,#00,#C7,#FF,#00,#FF,#00,#FF,#00,#00,#C7
  ; sh_disco_s0
  db #FF,#00,#00,#CB,#00,#C7,#FF,#00,#FF,#00,#00,#CB,#00,#C7,#FF,#00
  db #FF,#00,#00,#CB,#00,#C7,#FF,#00,#FF,#00,#00,#CB,#00,#C7,#FF,#00
  db #FF,#00,#00,#CB,#00,#C7,#FF,#00,#FF,#00,#00,#CB,#00,#C7,#FF,#00
  db #FF,#00,#00,#CB,#00,#C7,#FF,#00,#FF,#00,#00,#CB,#00,#C7,#FF,#00
  ; sh_disco_s1
  db #FF,#00,#00,#C7,#00,#CB,#FF,#00,#FF,#00,#00,#C7,#00,#CB,#FF,#00
  db #FF,#00,#00,#C7,#00,#CB,#FF,#00,#FF,#00,#00,#C7,#00,#CB,#FF,#00
  db #FF,#00,#00,#C7,#00,#CB,#FF,#00,#FF,#00,#00,#C7,#00,#CB,#FF,#00
  db #FF,#00,#00,#C7,#00,#CB,#FF,#00,#FF,#00,#00,#C7,#00,#CB,#FF,#00
  ; sh_disco_sw0
  db #FF,#00,#AA,#41,#55,#8A,#FF,#00,#FF,#00,#AA,#41,#55,#8A,#FF,#00
  db #FF,#00,#00,#C7,#FF,#00,#FF,#00,#FF,#00,#00,#C7,#FF,#00,#FF,#00
  db #AA,#41,#55,#8A,#FF,#00,#FF,#00,#AA,#41,#55,#8A,#FF,#00,#FF,#00
  db #00,#C7,#FF,#00,#FF,#00,#FF,#00,#00,#C7,#FF,#00,#FF,#00,#FF,#00
  ; sh_disco_sw1
  db #FF,#00,#AA,#45,#55,#82,#FF,#00,#FF,#00,#AA,#45,#55,#82,#FF,#00
  db #FF,#00,#00,#CB,#FF,#00,#FF,#00,#FF,#00,#00,#CB,#FF,#00,#FF,#00
  db #AA,#45,#55,#82,#FF,#00,#FF,#00,#AA,#45,#55,#82,#FF,#00,#FF,#00
  db #00,#CB,#FF,#00,#FF,#00,#FF,#00,#00,#CB,#FF,#00,#FF,#00,#FF,#00
  ; sh_disco_w0
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  db #00,#CF,#00,#CF,#00,#CF,#00,#CF,#00,#C3,#00,#C3,#00,#C3,#00,#C3
  db #00,#C3,#00,#C3,#00,#C3,#00,#C3,#00,#CF,#00,#CF,#00,#CF,#00,#CF
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  ; sh_disco_w1
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  db #00,#C3,#00,#C3,#00,#C3,#00,#C3,#00,#CF,#00,#CF,#00,#CF,#00,#CF
  db #00,#CF,#00,#CF,#00,#CF,#00,#CF,#00,#C3,#00,#C3,#00,#C3,#00,#C3
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  ; sh_disco_nw0
  db #00,#C7,#FF,#00,#FF,#00,#FF,#00,#00,#C7,#FF,#00,#FF,#00,#FF,#00
  db #AA,#41,#55,#8A,#FF,#00,#FF,#00,#AA,#41,#55,#8A,#FF,#00,#FF,#00
  db #FF,#00,#00,#C7,#FF,#00,#FF,#00,#FF,#00,#00,#C7,#FF,#00,#FF,#00
  db #FF,#00,#AA,#41,#55,#8A,#FF,#00,#FF,#00,#AA,#41,#55,#8A,#FF,#00
  ; sh_disco_nw1
  db #00,#CB,#FF,#00,#FF,#00,#FF,#00,#00,#CB,#FF,#00,#FF,#00,#FF,#00
  db #AA,#45,#55,#82,#FF,#00,#FF,#00,#AA,#45,#55,#82,#FF,#00,#FF,#00
  db #FF,#00,#00,#CB,#FF,#00,#FF,#00,#FF,#00,#00,#CB,#FF,#00,#FF,#00
  db #FF,#00,#AA,#45,#55,#82,#FF,#00,#FF,#00,#AA,#45,#55,#82,#FF,#00
  ; sh_baguette_n0
  db #FF,#00,#AA,#54,#55,#A8,#FF,#00,#FF,#00,#00,#A9,#00,#56,#FF,#00
  db #FF,#00,#00,#A9,#00,#56,#FF,#00,#FF,#00,#00,#F8,#00,#56,#FF,#00
  db #FF,#00,#00,#A9,#00,#56,#FF,#00,#FF,#00,#00,#A9,#00,#F4,#FF,#00
  db #FF,#00,#00,#A9,#00,#56,#FF,#00,#FF,#00,#AA,#54,#55,#A8,#FF,#00
  ; sh_baguette_ne0
  db #FF,#00,#FF,#00,#FF,#00,#00,#FC,#FF,#00,#FF,#00,#AA,#54,#00,#56
  db #FF,#00,#FF,#00,#AA,#54,#00,#56,#FF,#00,#FF,#00,#00,#A9,#55,#A8
  db #FF,#00,#FF,#00,#00,#F8,#55,#A8,#FF,#00,#AA,#54,#00,#56,#FF,#00
  db #FF,#00,#AA,#54,#00,#56,#FF,#00,#FF,#00,#AA,#54,#55,#A8,#FF,#00
  ; sh_baguette_e0
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  db #AA,#54,#00,#FC,#00,#FC,#55,#A8,#00,#A9,#00,#52,#00,#03,#00,#56
  db #00,#A9,#00,#03,#00,#52,#00,#56,#AA,#54,#00,#FC,#00,#FC,#55,#A8
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  ; sh_baguette_se0
  db #FF,#00,#AA,#54,#55,#A8,#FF,#00,#FF,#00,#AA,#54,#00,#56,#FF,#00
  db #FF,#00,#AA,#54,#00,#56,#FF,#00,#FF,#00,#FF,#00,#00,#F8,#55,#A8
  db #FF,#00,#FF,#00,#00,#A9,#55,#A8,#FF,#00,#FF,#00,#AA,#54,#00,#56
  db #FF,#00,#FF,#00,#AA,#54,#00,#56,#FF,#00,#FF,#00,#FF,#00,#00,#FC
  ; sh_baguette_s0
  db #FF,#00,#AA,#54,#55,#A8,#FF,#00,#FF,#00,#00,#A9,#00,#56,#FF,#00
  db #FF,#00,#00,#A9,#00,#F4,#FF,#00,#FF,#00,#00,#A9,#00,#56,#FF,#00
  db #FF,#00,#00,#F8,#00,#56,#FF,#00,#FF,#00,#00,#A9,#00,#56,#FF,#00
  db #FF,#00,#00,#A9,#00,#56,#FF,#00,#FF,#00,#AA,#54,#55,#A8,#FF,#00
  ; sh_baguette_sw0
  db #FF,#00,#AA,#54,#55,#A8,#FF,#00,#FF,#00,#00,#A9,#55,#A8,#FF,#00
  db #FF,#00,#00,#A9,#55,#A8,#FF,#00,#AA,#54,#00,#F4,#FF,#00,#FF,#00
  db #AA,#54,#00,#56,#FF,#00,#FF,#00,#00,#A9,#55,#A8,#FF,#00,#FF,#00
  db #00,#A9,#55,#A8,#FF,#00,#FF,#00,#00,#FC,#FF,#00,#FF,#00,#FF,#00
  ; sh_baguette_w0
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  db #AA,#54,#00,#FC,#00,#FC,#55,#A8,#00,#A9,#00,#03,#00,#A1,#00,#56
  db #00,#A9,#00,#A1,#00,#03,#00,#56,#AA,#54,#00,#FC,#00,#FC,#55,#A8
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  ; sh_baguette_nw0
  db #00,#FC,#FF,#00,#FF,#00,#FF,#00,#00,#A9,#55,#A8,#FF,#00,#FF,#00
  db #00,#A9,#55,#A8,#FF,#00,#FF,#00,#AA,#54,#00,#56,#FF,#00,#FF,#00
  db #AA,#54,#00,#F4,#FF,#00,#FF,#00,#FF,#00,#00,#A9,#55,#A8,#FF,#00
  db #FF,#00,#00,#A9,#55,#A8,#FF,#00,#FF,#00,#AA,#54,#55,#A8,#FF,#00
  ; sh_spaghetti_n0
  db #FF,#00,#AA,#55,#55,#AA,#FF,#00,#FF,#00,#55,#AA,#AA,#55,#FF,#00
  db #FF,#00,#55,#AA,#AA,#55,#FF,#00,#FF,#00,#AA,#55,#55,#AA,#FF,#00
  db #FF,#00,#55,#AA,#AA,#55,#FF,#00,#FF,#00,#55,#AA,#AA,#55,#FF,#00
  db #FF,#00,#AA,#55,#55,#AA,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  ; sh_spaghetti_ne0
  db #FF,#00,#FF,#00,#AA,#55,#55,#AA,#FF,#00,#FF,#00,#55,#AA,#AA,#55
  db #FF,#00,#FF,#00,#55,#AA,#AA,#55,#FF,#00,#AA,#55,#55,#AA,#FF,#00
  db #FF,#00,#AA,#55,#FF,#00,#55,#AA,#FF,#00,#55,#AA,#AA,#55,#FF,#00
  db #FF,#00,#00,#FF,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  ; sh_spaghetti_e0
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  db #AA,#55,#55,#AA,#AA,#55,#55,#AA,#55,#AA,#AA,#55,#55,#AA,#AA,#55
  db #55,#AA,#AA,#55,#55,#AA,#AA,#55,#AA,#55,#55,#AA,#AA,#55,#55,#AA
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  ; sh_spaghetti_se0
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#00,#FF,#FF,#00,#FF,#00
  db #FF,#00,#55,#AA,#AA,#55,#FF,#00,#FF,#00,#AA,#55,#FF,#00,#55,#AA
  db #FF,#00,#AA,#55,#55,#AA,#FF,#00,#FF,#00,#FF,#00,#55,#AA,#AA,#55
  db #FF,#00,#FF,#00,#55,#AA,#AA,#55,#FF,#00,#FF,#00,#AA,#55,#55,#AA
  ; sh_spaghetti_s0
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#AA,#55,#55,#AA,#FF,#00
  db #FF,#00,#55,#AA,#AA,#55,#FF,#00,#FF,#00,#55,#AA,#AA,#55,#FF,#00
  db #FF,#00,#AA,#55,#55,#AA,#FF,#00,#FF,#00,#55,#AA,#AA,#55,#FF,#00
  db #FF,#00,#55,#AA,#AA,#55,#FF,#00,#FF,#00,#AA,#55,#55,#AA,#FF,#00
  ; sh_spaghetti_sw0
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#00,#FF,#FF,#00
  db #FF,#00,#55,#AA,#AA,#55,#FF,#00,#AA,#55,#FF,#00,#55,#AA,#FF,#00
  db #FF,#00,#AA,#55,#55,#AA,#FF,#00,#55,#AA,#AA,#55,#FF,#00,#FF,#00
  db #55,#AA,#AA,#55,#FF,#00,#FF,#00,#AA,#55,#55,#AA,#FF,#00,#FF,#00
  ; sh_spaghetti_w0
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  db #AA,#55,#55,#AA,#AA,#55,#55,#AA,#55,#AA,#AA,#55,#55,#AA,#AA,#55
  db #55,#AA,#AA,#55,#55,#AA,#AA,#55,#AA,#55,#55,#AA,#AA,#55,#55,#AA
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  ; sh_spaghetti_nw0
  db #AA,#55,#55,#AA,#FF,#00,#FF,#00,#55,#AA,#AA,#55,#FF,#00,#FF,#00
  db #55,#AA,#AA,#55,#FF,#00,#FF,#00,#FF,#00,#AA,#55,#55,#AA,#FF,#00
  db #AA,#55,#FF,#00,#55,#AA,#FF,#00,#FF,#00,#55,#AA,#AA,#55,#FF,#00
  db #FF,#00,#FF,#00,#00,#FF,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  ; sh_torpedo_n0
  db #FF,#00,#AA,#15,#55,#2A,#FF,#00,#FF,#00,#00,#3F,#00,#3F,#FF,#00
  db #FF,#00,#00,#7B,#00,#B7,#FF,#00,#FF,#00,#00,#7B,#00,#B7,#FF,#00
  db #FF,#00,#00,#3F,#00,#3F,#FF,#00,#FF,#00,#AA,#15,#55,#2A,#FF,#00
  db #FF,#00,#55,#A2,#AA,#51,#FF,#00,#AA,#51,#FF,#00,#FF,#00,#55,#A2
  ; sh_torpedo_ne0
  db #FF,#00,#FF,#00,#AA,#15,#55,#2A,#FF,#00,#FF,#00,#00,#3F,#00,#3F
  db #FF,#00,#FF,#00,#00,#7B,#00,#B7,#FF,#00,#AA,#15,#00,#B7,#55,#2A
  db #FF,#00,#AA,#15,#00,#3F,#FF,#00,#FF,#00,#00,#3F,#FF,#00,#FF,#00
  db #FF,#00,#55,#A2,#55,#A2,#FF,#00,#AA,#51,#FF,#00,#AA,#51,#FF,#00
  ; sh_torpedo_e0
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#00,#3F,#00,#3F,#FF,#00
  db #AA,#15,#00,#3F,#00,#F3,#00,#B7,#00,#B7,#00,#7B,#00,#F3,#00,#B7
  db #AA,#15,#00,#3F,#00,#F3,#00,#B7,#FF,#00,#00,#3F,#00,#3F,#FF,#00
  db #AA,#51,#FF,#00,#55,#A2,#FF,#00,#55,#A2,#AA,#51,#FF,#00,#FF,#00
  ; sh_torpedo_se0
  db #AA,#51,#FF,#00,#AA,#51,#FF,#00,#FF,#00,#55,#A2,#55,#A2,#FF,#00
  db #FF,#00,#00,#3F,#FF,#00,#FF,#00,#FF,#00,#AA,#15,#00,#3F,#FF,#00
  db #FF,#00,#AA,#15,#00,#B7,#55,#2A,#FF,#00,#FF,#00,#00,#7B,#00,#B7
  db #FF,#00,#FF,#00,#00,#3F,#00,#3F,#FF,#00,#FF,#00,#AA,#15,#55,#2A
  ; sh_torpedo_s0
  db #AA,#51,#FF,#00,#FF,#00,#55,#A2,#FF,#00,#55,#A2,#AA,#51,#FF,#00
  db #FF,#00,#AA,#15,#55,#2A,#FF,#00,#FF,#00,#00,#3F,#00,#3F,#FF,#00
  db #FF,#00,#00,#7B,#00,#B7,#FF,#00,#FF,#00,#00,#7B,#00,#B7,#FF,#00
  db #FF,#00,#00,#3F,#00,#3F,#FF,#00,#FF,#00,#AA,#15,#55,#2A,#FF,#00
  ; sh_torpedo_sw0
  db #FF,#00,#55,#A2,#FF,#00,#55,#A2,#FF,#00,#AA,#51,#AA,#51,#FF,#00
  db #FF,#00,#FF,#00,#00,#3F,#FF,#00,#FF,#00,#00,#3F,#55,#2A,#FF,#00
  db #AA,#15,#00,#7B,#55,#2A,#FF,#00,#00,#7B,#00,#B7,#FF,#00,#FF,#00
  db #00,#3F,#00,#3F,#FF,#00,#FF,#00,#AA,#15,#55,#2A,#FF,#00,#FF,#00
  ; sh_torpedo_w0
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#00,#3F,#00,#3F,#FF,#00
  db #00,#7B,#00,#F3,#00,#3F,#55,#2A,#00,#7B,#00,#F3,#00,#B7,#00,#7B
  db #00,#7B,#00,#F3,#00,#3F,#55,#2A,#FF,#00,#00,#3F,#00,#3F,#FF,#00
  db #FF,#00,#AA,#51,#FF,#00,#55,#A2,#FF,#00,#FF,#00,#55,#A2,#AA,#51
  ; sh_torpedo_nw0
  db #AA,#15,#55,#2A,#FF,#00,#FF,#00,#00,#3F,#00,#3F,#FF,#00,#FF,#00
  db #00,#7B,#00,#B7,#FF,#00,#FF,#00,#AA,#15,#00,#7B,#55,#2A,#FF,#00
  db #FF,#00,#00,#3F,#55,#2A,#FF,#00,#FF,#00,#FF,#00,#00,#3F,#FF,#00
  db #FF,#00,#AA,#51,#AA,#51,#FF,#00,#FF,#00,#55,#A2,#FF,#00,#55,#A2
  ; sh_sneeze0
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#AA,#15,#55,#2A,#FF,#00
  db #FF,#00,#00,#7B,#00,#3F,#FF,#00,#FF,#00,#00,#3F,#00,#B7,#FF,#00
  db #FF,#00,#AA,#15,#55,#2A,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  ; sh_sneeze1
  db #FF,#00,#55,#2A,#AA,#15,#FF,#00,#AA,#15,#00,#3F,#00,#3F,#FF,#00
  db #AA,#15,#00,#B7,#00,#7B,#55,#2A,#FF,#00,#00,#3F,#00,#3F,#55,#2A
  db #AA,#15,#AA,#15,#55,#2A,#55,#2A,#FF,#00,#55,#2A,#FF,#00,#55,#2A
  db #FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  ; sh_sneeze2
  db #AA,#15,#FF,#00,#FF,#00,#55,#2A,#FF,#00,#FF,#00,#55,#2A,#FF,#00
  db #FF,#00,#55,#2A,#FF,#00,#55,#2A,#FF,#00,#FF,#00,#AA,#15,#FF,#00
  db #AA,#15,#FF,#00,#55,#2A,#FF,#00,#FF,#00,#FF,#00,#55,#2A,#AA,#15
  db #FF,#00,#55,#2A,#FF,#00,#FF,#00,#AA,#15,#FF,#00,#FF,#00,#55,#2A
  ; sh_e90
  db #AA,#11,#00,#33,#00,#33,#55,#22,#AA,#11,#00,#C0,#00,#C0,#55,#22
  db #AA,#11,#00,#33,#00,#33,#55,#22,#AA,#11,#00,#C0,#00,#C0,#55,#22
  db #AA,#11,#00,#33,#00,#33,#55,#22,#AA,#11,#00,#C0,#00,#C0,#55,#22
  db #AA,#11,#00,#33,#00,#33,#55,#22,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  ; sh_e91
  db #FF,#00,#00,#33,#00,#33,#FF,#00,#FF,#00,#00,#62,#00,#91,#FF,#00
  db #FF,#00,#00,#33,#00,#33,#FF,#00,#FF,#00,#00,#62,#00,#91,#FF,#00
  db #FF,#00,#00,#33,#00,#33,#FF,#00,#FF,#00,#00,#62,#00,#91,#FF,#00
  db #FF,#00,#00,#33,#00,#33,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
  ; sh_e92
  db #FF,#00,#AA,#11,#55,#22,#FF,#00,#FF,#00,#AA,#11,#55,#80,#FF,#00
  db #FF,#00,#AA,#11,#55,#22,#FF,#00,#FF,#00,#AA,#11,#55,#80,#FF,#00
  db #FF,#00,#AA,#11,#55,#22,#FF,#00,#FF,#00,#AA,#11,#55,#80,#FF,#00
  db #FF,#00,#AA,#11,#55,#22,#FF,#00,#FF,#00,#FF,#00,#FF,#00,#FF,#00
