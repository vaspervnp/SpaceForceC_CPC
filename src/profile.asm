; profile.asm — raster bars για μέτρηση χρόνου (include πριν από τη χρήση)
;
; Raster bars: με make PROFILE=1 το border αλλάζει χρώμα σε κάθε φάση του
; καρέ, και το ύψος κάθε λωρίδας είναι ο χρόνος της. Χωρίς PROFILE δεν
; παράγεται τίποτα.
        macro PROFILE_BORDER colour
        ifdef PROFILE
        ld a,{colour}
        call set_border
        endif
        mend

HW_BLACK        equ #54
HW_BLUE         equ #44
HW_BRIGHT_BLUE  equ #55
HW_RED          equ #4C
HW_GREEN        equ #56
HW_BRIGHT_GREEN equ #52
HW_YELLOW       equ #4A
HW_MAGENTA      equ #58
HW_WHITE        equ #4B
