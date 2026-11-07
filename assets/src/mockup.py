"""Μια ολόκληρη οθόνη 160x200 του Level 1 — ο μόνος τρόπος να κριθεί το σύνολο.

    python3 assets/src/mockup.py

Τα contact sheets δείχνουν αν ΕΝΑ sprite είναι καλό. Δεν δείχνουν αν το
σκάφος ξεχωρίζει από τα αστέρια, αν τα βλήματα χάνονται μέσα στους εχθρούς,
αν το HUD χωράει ή αν η παλέτα κρατάει όταν όλα είναι στην οθόνη μαζί.

Η ΔΙΑΤΑΞΗ ΠΟΥ ΔΟΚΙΜΑΖΕΤΑΙ

    γραμμές   0-167   παράθυρο παιχνιδιού, 20x21 πλακίδια
    γραμμές 168-199   HUD, 32 γραμμές

Το παράθυρο είναι 320x168 μονάδες και το HUD 320x32. Αν ο κώδικας κόψει το
πλάτος της οθόνης για ταχύτητα (CRTC R1), το HUD κόβεται μαζί — γι' αυτό
τίποτα κρίσιμο δεν ακουμπάει τις δύο τελευταίες στήλες.
"""
import os
import random

import boss1
import font as FO
import fx
import gfx
import pickups as PU
import preview
import shots as SH
import ship as SP
import tiles as TI

W, H = 160, 200
PLAY_H = 168
TILES_X, TILES_Y = 20, 21
PREVIEW = os.path.join(gfx.OUT, 'preview')


def starfield(seed=11):
    rnd = random.Random(seed)
    grid = []
    for y in range(TILES_Y):
        row = []
        for x in range(TILES_X):
            r = rnd.random()
            row.append('star_s' if r < .10 else
                       'star_m' if r < .14 else
                       'stars_3' if r < .18 else
                       'dust' if r < .22 else 'void')
        grid.append(row)
    # ένα νεφέλωμα πάνω δεξιά, να φανεί ότι τα πλακίδια ενώνονται
    for y in range(1, 5):
        for x in range(13, 19):
            d = abs(x - 16) + abs(y - 3)
            grid[y][x] = ('nebula_b' if d < 2 else
                          'nebula_c' if d < 3 else 'nebula_a')
    return grid


def hud(img):
    """Μία γραμμή χωρίσματος και τρεις σειρές πληροφορίας."""
    for y in range(PLAY_H, H):
        for x in range(W):
            img[y][x] = gfx.PEN['.']
    for x in range(W):
        img[PLAY_H][x] = gfx.PEN['b']

    gfx.stamp(img, FO.text('SCORE', 'I'), 2, 170)
    gfx.stamp(img, FO.text('0123450', 'y'), 24, 170)
    # ΟΙ ΖΩΕΣ ΔΕΝ ΕΙΝΑΙ ΤΟ ΚΑΝΟΝΙΚΟ ΣΚΑΦΟΣ
    #
    # Ήταν, και 24 γραμμές μέσα σε HUD 32 γραμμών πατούσαν πάνω στην μπάρα
    # του boss. Το `pu_life` είναι ήδη μικρογραφία του σκάφους σε 8x16 —
    # φτιαγμένο ακριβώς γι' αυτή τη θέση.
    for k in range(3):
        gfx.stamp(img, PU.pickup('life'), 128 + k * 10, 170)

    gfx.stamp(img, PU.ant(0), 2, 180)
    gfx.stamp(img, FO.text('034/100', 'I'), 12, 180)
    gfx.stamp(img, PU.pickup('disco'), 46, 178)
    gfx.stamp(img, PU.pickup('shield'), 58, 178)
    gfx.stamp(img, FO.text('WING C', 'g'), 74, 180)

    gfx.stamp(img, FO.text('LORD GARBAGE-CAN', 'I'), 2, 190)
    for x in range(70, 158):
        img[191][x] = gfx.PEN['K']
        img[196][x] = gfx.PEN['K']
    for x in range(70, 158):
        img[190][x] = img[197][x] = gfx.PEN['i']
    for y in range(192, 196):
        for x in range(71, 157):
            img[y][x] = gfx.PEN['r'] if x < 128 else gfx.PEN['K']
    return img


def draw():
    img = gfx.blank(W, H, gfx.PEN['.'])
    grid = starfield()
    for y in range(TILES_Y):
        for x in range(TILES_X):
            gfx.stamp(img, TI.tile(grid[y][x]), x * 8, y * 8)

    # ---------------------------------------------------- ο boss ψηλά
    gfx.stamp(img, boss1.frame(1), 68, 4)

    # ------------------------------------------------------- εχθροί
    import enemies as EN
    for key, fr, x, y in (('suitcase', 0, 10, 28), ('sock', 1, 34, 20),
                          ('grunt', 0, 24, 66), ('grunt', 1, 40, 72),
                          ('grunt', 0, 56, 66), ('saucer', 0, 112, 60),
                          ('mine', 0, 136, 96), ('roach', 1, 8, 104),
                          ('sock', 0, 146, 32)):
        gfx.stamp(img, EN.frames(key)[fr], x, y)

    # --------------------------------------------- βλήματα του παίκτη
    for y in (78, 90, 102):
        gfx.stamp(img, SH.shot('baguette', 'n', 0), 76, y)
    gfx.stamp(img, SH.shot('disco', 'ne', 0), 96, 96)
    gfx.stamp(img, SH.shot('disco', 'ne', 1), 104, 88)
    # ----------------------------------------- βλήματα των εξωγήινων
    gfx.stamp(img, SH.shot('spaghetti', 's', 0), 114, 78)
    gfx.stamp(img, SH.shot('torpedo', 'sw', 0), 130, 110)
    gfx.stamp(img, SH.shot('e9', phase=1), 20, 120)

    # ------------------------------------------------ μαζεύω και σκάει
    gfx.stamp(img, PU.pickup('espresso'), 128, 128)
    for x, y in ((48, 118), (60, 126), (36, 132)):
        gfx.stamp(img, PU.ant(0), x, y)
    gfx.stamp(img, fx.boom_big(2), 24, 128)

    # -------------------------------------------- το σκάφος, με φλόγα
    sx, sy, d = 72, 128, 'n'
    fdx, fdy = SP.FLAME_AT[d]
    gfx.stamp(img, fx.flame(d, 2), sx + fdx, sy + fdy)
    gfx.stamp(img, SP.frame(d), sx, sy)

    return hud(img)


def main():
    os.makedirs(PREVIEW, exist_ok=True)
    path = os.path.join(PREVIEW, 'screen.png')
    preview.contact_sheet(path, [('', draw())], zoom=4, cols=1, title='',
                          grid=False)
    print(path)


if __name__ == '__main__':
    main()
