"""Οι bosses του διαστήματος: όλοι 24x48 px, δύο καρέ, τρία βλήματα 8x8.

    καρέ 0   κανονικός
    καρέ 1   η προειδοποίηση πριν από τη βολή
    βλήματα  ό,τι πετάει (διαλέγεται από την κατεύθυνση)

Ο Lord Garbage-Can είναι στο boss1.py / junk.py, οι υπόλοιποι εδώ. Όπως κι
εκείνος χτίζονται με κώδικα: σε 1.152 pixels το χέρι κάνει λάθη που δεν
φαίνονται. Οι παράμετροι της συμπεριφοράς τους είναι στο levels.py.
"""
import boss1
import junk
from gfx import PEN, art, blank

W, H = 24, 48
SHOT_W, SHOT_H = 8, 8

K, i, I, r, d, D, y, S, c, b, m, p, n, g, o = (
    PEN[x] for x in 'KiIrdDySc bmpngo'.replace(' ', ''))


def _rect(img, x0, y0, x1, y1, pen):
    for yy in range(max(0, y0), min(H, y1 + 1)):
        for xx in range(max(0, x0), min(W, x1 + 1)):
            img[yy][xx] = pen


def _box(img, x0, y0, x1, y1, fill, line=K):
    _rect(img, x0, y0, x1, y1, line)
    _rect(img, x0 + 1, y0 + 1, x1 - 1, y1 - 1, fill)


def _disc(img, cx, cy, rx, ry, fill, line=K):
    """Έλλειψη με περίγραμμα. Το κέντρο είναι ανάμεσα σε pixels (cx = 11.5)."""
    for yy in range(H):
        for xx in range(W):
            dx, dy = (xx - cx) / float(rx), (yy - cy) / float(ry)
            dist = dx * dx + dy * dy
            if dist <= 1.0:
                dx2 = (xx - cx) / max(0.5, rx - 1.0)
                dy2 = (yy - cy) / max(0.5, ry - 1.0)
                img[yy][xx] = fill if dx2 * dx2 + dy2 * dy2 <= 1.0 else line


# ------------------------------------------------------- The Grand Inspector

def inspector(attack=False):
    """Μια τεράστια κόκκινη σφραγίδα. Πριν χτυπήσει, σηκώνεται και στάζει."""
    img = blank(W, H, None)
    up = 3 if attack else 0
    # ξύλινη λαβή
    _disc(img, 11.5, 7 - up, 6, 5, D)
    _rect(img, 9, 4 - up, 11, 5 - up, S)
    _box(img, 9, 11 - up, 14, 17 - up, d)
    # ώμοι και σώμα
    _box(img, 5, 16 - up, 18, 20 - up, r)
    _box(img, 1, 20 - up, 22, 36 - up, r)
    _rect(img, 2, 21 - up, 21, 22 - up, y)      # χρυσή λωρίδα: είναι Grand
    # μάτια γραφειοκράτη, με γυαλάκια
    for x0 in (4, 13):
        _box(img, x0, 25 - up, x0 + 6, 30 - up, I)
        _rect(img, x0 + 2, 27 - up, x0 + 4, 29 - up, K)
    _rect(img, 11, 26 - up, 12, 27 - up, K)     # γέφυρα
    for k in range(5):                          # φρύδια, θυμωμένα
        img[23 - up + k // 2][4 + k] = K
        img[23 - up + k // 2][19 - k] = K
    # το λάστιχο: τα γράμματα του REJECTED ανάποδα
    _box(img, 0, 37 - up, 23, 44 - up, d)
    for x in range(2, 22, 3):
        _rect(img, x, 39 - up, x + 1, 42 - up, I)
        img[40 - up][x + 1] = d
    if attack:                                  # στάζει μελάνι
        for x, ln in ((3, 4), (9, 7), (15, 5), (20, 6)):
            _rect(img, x, 42, x + 1, 41 + ln, m)
    return img


STAMP_SHOTS = [
    ('form', 'απορριφθείσα αίτηση', """
.IIIIII.
.IrIIrI.
.IIrrII.
.IIrrII.
.IrIIrI.
.IIIIII.
.KKKKKK.
........
"""),
    ('ink', 'σταγόνα μελάνι', """
...mm...
...mm...
..mmmm..
.mmIImm.
.mmmmmm.
.mmmmmm.
..mmmm..
........
"""),
    ('clip', 'συνδετήρας', """
.iiiiii.
.i....i.
.i.ii.i.
.i.i..i.
.i.iiii.
.i......
.iiiiii.
........
"""),
]


# ---------------------------------------------------- Mecha-Trashcan 3000

def _floppy(img, x0, y0, x1, y1, body, shutter=i):
    _box(img, x0, y0, x1, y1, body)
    mid = (x0 + x1) // 2
    _rect(img, mid - 3, y0 + 1, mid + 2, y0 + 2, shutter)
    _rect(img, x0 + 2, y1 - 2, x1 - 2, y1 - 1, I)


def mecha(attack=False):
    """Ρομπότ από δισκέτες: κεφάλι, κορμός, χέρια, πόδια."""
    img = blank(W, H, None)
    # κεραία
    _rect(img, 11, 0, 12, 3, K)
    _rect(img, 10, 0, 13, 1, r if attack else o)
    # κεφάλι: μια μεγάλη δισκέτα, το κλείστρο είναι το στόμα
    _box(img, 5, 3, 18, 16, b)
    for x0 in (7, 13):                          # LED μάτια
        _rect(img, x0, 6, x0 + 3, 8, r if attack else y)
        _rect(img, x0 + 1, 7, x0 + 2, 7, K)
    if attack:
        _rect(img, 7, 11, 16, 15, K)
        _rect(img, 8, 12, 15, 14, r)
    else:
        _rect(img, 7, 12, 16, 14, i)
        _rect(img, 12, 12, 13, 14, K)
    # κορμός: στοίβα από τρεις δισκέτες
    _floppy(img, 4, 17, 19, 23, m)
    _floppy(img, 4, 24, 19, 30, n, o)
    _floppy(img, 4, 31, 19, 37, b)
    # χέρια: δισκέτες στη σειρά, σηκώνονται πριν από τη βολή
    top = 10 if attack else 19
    for x0 in (0, 20):
        for k in range(3):
            _box(img, x0, top + k * 5, x0 + 3, top + k * 5 + 4, m if k % 2 else n)
    # πόδια
    for x0 in (5, 13):
        _box(img, x0, 38, x0 + 5, 44, i)
        _box(img, x0 - 1, 44, x0 + 6, 47, K)
        _rect(img, x0, 45, x0 + 5, 46, o)
    return img


MECHA_SHOTS = [
    ('disk', 'δισκέτα', """
.KKKKKK.
KmmIImmK
KmmIImmK
KmmmmmmK
KmIIIImK
KmIIIImK
KKKKKKKK
........
"""),
    ('gear', 'γρανάζι', """
...ii...
.i.ii.i.
..iiii..
iiiKKiii
iiiKKiii
..iiii..
.i.ii.i.
...ii...
"""),
    ('spark', 'σπίθα', """
...y....
...yy...
..yyy...
.yyyyyy.
...yyy..
...yy...
....y...
........
"""),
]


# -------------------------------------------------------- General Formix

def formix(attack=False):
    """Γιγάντιο μυρμήγκι με κράνος και γυαλιά ηλίου, από μπροστά."""
    img = blank(W, H, None)
    # κοιλιά και θώρακας
    _disc(img, 11.5, 39, 8, 8, d)
    for yy in (36, 40, 44):                     # ραβδώσεις
        for xx in range(6, 18):
            if img[yy][xx] == d:
                img[yy][xx] = K
    _disc(img, 11.5, 27, 5, 5, D)
    # πόδια (έξι), γωνιακά
    for yy, dx in ((24, 0), (29, 1), (34, 0)):
        for k in range(7):
            yl = yy + (k // 3 if yy > 24 else -(k // 3))
            for yd in (yl, yl + 1):         # χοντρά: το μαύρο τα τρώει
                img[yd][6 - k + dx] = d
                img[yd][17 + k - dx] = d
    # μέταλλα στο στήθος: είναι Στρατηγός
    _rect(img, 9, 25, 10, 26, y)
    _rect(img, 12, 25, 13, 26, r)
    _rect(img, 9, 28, 14, 28, y)
    # κεφάλι
    _disc(img, 11.5, 15, 8, 7, D)
    # γυαλιά ηλίου
    _rect(img, 3, 12, 20, 13, K)
    _box(img, 4, 12, 10, 17, K, K)
    _box(img, 13, 12, 19, 17, K, K)
    img[13][5] = img[13][14] = I                # ανταύγεια
    img[14][6] = img[14][15] = c
    # σαγόνια: ανοίγουν πριν από τη βολή
    if attack:
        for k in range(5):
            img[20 + k][8 - k // 2] = K
            img[20 + k][15 + k // 2] = K
        _rect(img, 9, 20, 14, 22, r)
    else:
        for k in range(3):
            img[20 + k][10 - k // 2] = K
            img[20 + k][13 + k // 2] = K
    # στρατιωτικό κράνος
    _disc(img, 11.5, 8, 9, 6, n)
    _rect(img, 1, 9, 22, 11, n)
    _rect(img, 1, 11, 22, 11, K)
    _rect(img, 5, 4, 8, 5, g)                   # γυαλάδα
    _rect(img, 10, 5, 13, 8, y)                 # το σήμα
    _rect(img, 11, 6, 12, 7, r)
    # κεραίες, από το κράνος
    for k in range(4):
        img[2 - k // 2][7 - k] = d
        img[2 - k // 2][16 + k] = d
    if attack:                                  # οργή: κόκκινα ανάμεσα στα γυαλιά
        _rect(img, 11, 14, 12, 15, r)
    return img


FORMIX_SHOTS = [
    ('grenade', 'χειροβομβίδα', """
...KK...
..KyyK..
.nnnnnn.
.nKnnKn.
.nnnnnn.
.nKnnKn.
.nnnnnn.
..nnnn..
"""),
    ('sugar', 'κύβος ζάχαρης', """
........
.IIIIII.
.IIIIIi.
.IIIIIi.
.IIIIIi.
.IIIIIi.
.iiiiii.
........
"""),
    ('medal', 'μετάλλιο', """
..rIIr..
..rIIr..
...rr...
..yyyy..
.yyDDyy.
.yyDDyy.
..yyyy..
........
"""),
]


def _shots(items):
    return [art(t, SHOT_W, SHOT_H, nm) for nm, _, t in items]


# Ο αριθμός είναι αυτός του LV_BOSS στο header της πίστας.
BOSSES = {
    1: ('Lord Garbage-Can', [boss1.frame(0), boss1.frame(1)],
        [junk.frame(k) for k in range(3)]),
    2: ('The Grand Inspector', [inspector(), inspector(True)], _shots(STAMP_SHOTS)),
    3: ('Mecha-Trashcan 3000', [mecha(), mecha(True)], _shots(MECHA_SHOTS)),
    4: ('General Formix', [formix(), formix(True)], _shots(FORMIX_SHOTS)),
}
