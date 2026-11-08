"""Οι bosses: όλοι 24x48 px, δύο καρέ, τρία βλήματα 8x8.

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


# ----------------------------------------------- The Undefeated Toll Booth

def toll(attack=False):
    """Διόδια με φάτσα. Πριν από τη βολή κατεβαίνει η μπάρα και ανάβει κόκκινο."""
    img = blank(W, H, None)
    # στέγη
    _box(img, 2, 2, 21, 7, r)
    for x in range(4, 20, 4):
        _rect(img, x, 3, x + 1, 6, I)
    # φανάρι
    _box(img, 9, 8, 14, 12, K)
    _rect(img, 10, 9, 13, 11, r if attack else g)
    # θάλαμος
    _box(img, 3, 12, 20, 45, i)
    # παράθυρο-πρόσωπο
    _box(img, 5, 14, 18, 28, c)
    for x0 in (7, 13):
        _rect(img, x0, 17, x0 + 3, 20, I)
        _rect(img, x0 + 1, 18, x0 + 2, 20, K)
    for k in range(4):
        img[15 + k // 2][7 + k] = K
        img[15 + k // 2][16 - k] = K
    _rect(img, 8, 24, 15, 26, K)
    if attack:
        _rect(img, 9, 25, 14, 25, r)
    # θυρίδα για τα κέρματα
    _box(img, 7, 31, 16, 38, y)
    _rect(img, 9, 33, 14, 34, K)
    # η μπάρα, ριγέ: οριζόντια ή σηκωμένη
    if attack:
        for k in range(8):
            _rect(img, 0, 40 - k * 2, 2, 40 - k * 2 + 1, r if k % 2 else I)
    else:
        for x in range(0, 24, 2):
            _rect(img, x, 40, x + 1, 42, r if x // 2 % 2 else I)
    _rect(img, 4, 46, 19, 47, K)
    return img


TOLL_SHOTS = [
    ('coin', 'κέρμα', """
..yyyy..
.yyDDyy.
yyDyyDyy
yyDyyDyy
yyDyyDyy
yyDyyDyy
.yyDDyy.
..yyyy..
"""),
    ('bar', 'μπάρα', """
........
........
rrIIrrII
rrIIrrII
KKKKKKKK
........
........
........
"""),
    ('ticket', 'απόδειξη', """
.IIIIII.
.IKKKKI.
.IIIIII.
.IKKIII.
.IIIIII.
.IKKKKI.
.IIIIII.
.I.II.I.
"""),
]


# --------------------------------------------------------- Queen Ant-Zilla

def antzilla(attack=False):
    """Η βασίλισσα με κορώνα, πράσινη από το ραδιενεργό τσάι."""
    img = blank(W, H, None)
    _disc(img, 11.5, 38, 10, 9, n)              # κοιλιά
    for yy in (33, 38, 43):
        for xx in range(3, 21):
            if img[yy][xx] == n:
                img[yy][xx] = g
    _disc(img, 11.5, 25, 6, 5, d)               # θώρακας
    for yy, dx in ((22, 0), (26, 1), (30, 0)):  # πόδια
        for k in range(6):
            for yd in (yy + k // 2, yy + 1 + k // 2):
                img[yd][5 - k + dx] = d
                img[yd][18 + k - dx] = d
    _disc(img, 11.5, 14, 8, 7, g)               # κεφάλι
    for x0 in (6, 13):                          # σύνθετα μάτια
        _disc(img, x0 + 2, 12, 3, 3, r if attack else y)
        img[11][x0 + 1] = I
    if attack:                                  # ανοιχτό στόμα, τσάι
        _rect(img, 8, 17, 15, 20, K)
        _rect(img, 9, 18, 14, 19, y)
    else:
        for k in range(4):
            img[18 + k // 2][9 - k // 2] = K
            img[18 + k // 2][14 + k // 2] = K
    # κορώνα
    _rect(img, 6, 4, 17, 7, y)
    for x in (6, 10, 13, 17):
        _rect(img, x, 1, x, 4, y)
    img[5][8] = img[5][15] = r
    img[5][11] = c
    _rect(img, 6, 7, 17, 7, K)
    # κεραίες
    for k in range(5):
        img[8 - k // 2][4 - k // 2] = d
        img[8 - k // 2][19 + k // 2] = d
    return img


ZILLA_SHOTS = [
    ('tea', 'ραδιενεργό τσάι', """
...gg...
...gg...
..gggg..
.ggyggg.
.gggggg.
.ggggyg.
..gggg..
........
"""),
    ('egg', 'αυγό', """
...II...
..IIII..
.IIIIII.
.IIIIiI.
.IIIIiI.
.IIIiiI.
..Iiii..
........
"""),
    ('cup', 'φλιτζάνι', """
........
.IIIIII.
.IggggIK
.IIIIIIK
.IIIIIIK
..IIII..
.iiiiii.
........
"""),
]


# --------------------------------------------------------- Parthenon-Bot 2.0

def parthenon(attack=False):
    """Ναός. Στην επίθεση σηκώνει τις δύο εξωτερικές κολόνες, σαν χέρια."""
    img = blank(W, H, None)
    # αέτωμα, με τα μάτια μέσα
    for row in range(2, 13):
        half = (row - 1)
        _rect(img, 11 - half, row, 12 + half, row, S)
        img[row][max(0, 11 - half)] = K
        img[row][min(W - 1, 12 + half)] = K
    _rect(img, 0, 13, 23, 13, K)
    for x0 in (7, 13):
        _rect(img, x0, 8, x0 + 3, 11, r if attack else c)
        _rect(img, x0 + 1, 9, x0 + 2, 10, K)
    # θριγκός
    _box(img, 0, 13, 23, 17, S)
    for x in range(2, 22, 3):
        _rect(img, x, 14, x, 16, i)
    # κολόνες: οι εσωτερικές πάντα, οι εξωτερικές ανεβαίνουν
    def column(x0, y0, y1):
        _rect(img, x0, y0, x0 + 3, y1, S)
        img[y0][x0] = img[y0][x0 + 3] = K
        for yy in range(y0, y1 + 1):
            img[yy][x0] = K
            img[yy][x0 + 3] = K
            img[yy][x0 + 1] = i
    for x0 in (6, 14):
        column(x0, 18, 38)
    up = 12 if attack else 0
    for x0 in (0, 20):
        column(x0, 18 - up, 38 - up)
    # το στόμα: η πόρτα του ναού
    _rect(img, 10, 26, 13, 38, K)
    if attack:
        _rect(img, 11, 28, 12, 36, r)
    # πόδια-κρηπίδα
    _box(img, 2, 39, 21, 42, S)
    for x0 in (3, 14):
        _box(img, x0, 42, x0 + 6, 47, i)
    return img


TEMPLE_SHOTS = [
    ('chunk', 'κομμάτι μάρμαρο', """
........
..SSS...
.SSSSSS.
.SSiSSS.
.SSSSSi.
..SSiSi.
...iii..
........
"""),
    ('drum', 'σπόνδυλος', """
.SSSSSS.
SiSiSiSK
SiSiSiSK
SiSiSiSK
SiSiSiSK
SiSiSiSK
.KKKKKK.
........
"""),
    ('flash', 'φλας τουρίστα', """
...I....
.I.I.I..
..III...
IIIyIII.
..III...
.I.I.I..
...I....
........
"""),
]


# ------------------------------------------------------ Chef Xylokorinthos

def chef(attack=False):
    """Εξωγήινος σεφ με έξι χέρια: τα σηκώνει πριν πετάξει κάτι."""
    img = blank(W, H, None)
    # σκούφος
    _disc(img, 11.5, 5, 8, 5, I)
    _rect(img, 6, 8, 17, 12, I)
    _rect(img, 6, 12, 17, 12, K)
    for x in (9, 12, 15):
        _rect(img, x, 9, x, 11, i)
    # κεφάλι
    _disc(img, 11.5, 17, 7, 6, g)
    for x0 in (7, 13):
        _rect(img, x0, 15, x0 + 3, 17, I)
        _rect(img, x0 + 1, 16, x0 + 2, 17, r if attack else K)
    if attack:
        _rect(img, 9, 20, 14, 22, K)
    else:
        _rect(img, 9, 21, 14, 21, K)
    # μουστάκι
    _rect(img, 6, 19, 8, 19, K)
    _rect(img, 15, 19, 17, 19, K)
    # σακάκι
    _box(img, 6, 23, 17, 44, I)
    for yy in (27, 32, 37):
        img[yy][11] = img[yy][12] = K
    _rect(img, 7, 23, 16, 24, r)                # κόκκινο μαντήλι
    # ποδιά, πόδια
    _rect(img, 8, 36, 15, 43, i)
    for x0 in (7, 13):
        _rect(img, x0, 45, x0 + 3, 47, K)
    # έξι χέρια: τρία ανά πλευρά, με τηγάνια στα χέρια
    for k, yy in enumerate((24, 30, 36)):
        rise = (3 + k * 2) if attack else 0
        for x in range(1, 6):
            yl = yy - (5 - x) * rise // 5
            img[yl][x] = img[yl + 1][x] = g
            img[yl][W - 1 - x] = img[yl + 1][W - 1 - x] = g
        tip = yy - rise
        _rect(img, 0, tip - 2, 1, tip + 1, K)
        _rect(img, 22, tip - 2, 23, tip + 1, K)
    return img


CHEF_SHOTS = [
    ('soup', 'καυτή σούπα', """
..g..g..
...g....
.KKKKKK.
.KggggK.
.KgygyK.
.KiiiiK.
..KKKK..
........
"""),
    ('frypan', 'τηγάνι', """
.KKKK...
KiiiiK..
KiKKiK..
KiKKiK..
KiiiiKdd
.KKKK.dd
........
........
"""),
    ('ladle', 'κουτάλα', """
......ii
.....ii.
....ii..
...ii...
.KKi....
KggK....
KggK....
.KK.....
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
    5: ('Undefeated Toll Booth', [toll(), toll(True)], _shots(TOLL_SHOTS)),
    6: ('Queen Ant-Zilla', [antzilla(), antzilla(True)], _shots(ZILLA_SHOTS)),
    7: ('Parthenon-Bot 2.0', [parthenon(), parthenon(True)], _shots(TEMPLE_SHOTS)),
    8: ('Chef Xylokorinthos', [chef(), chef(True)], _shots(CHEF_SHOTS)),
}
