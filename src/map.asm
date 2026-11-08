; map.asm — ο γεννήτορας τυχαίων αριθμών (ο χάρτης έρχεται από την πίστα,
; level.asm)

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
