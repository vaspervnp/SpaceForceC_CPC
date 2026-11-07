"""Lord Garbage-Can — ο boss του Level 1, 24x48 px = 48x48 μονάδες.

ΧΤΙΖΕΤΑΙ ΜΕ ΚΩΔΙΚΑ, ΟΧΙ ΜΕ ASCII

Όλα τα άλλα sprites είναι ζωγραφισμένα χαρακτήρα-χαρακτήρα, γιατί σε 8x16 ή
12x24 κάθε pixel είναι απόφαση. Εδώ όχι: 48 γραμμές x 24 στήλες είναι 1.152
χαρακτήρες, από τους οποίους οι ~900 είναι η ΙΔΙΑ νεύρωση του τενεκέ
επαναλαμβανόμενη. Γραμμένο με το χέρι θα ήταν αδιάβαστο και μια νεύρωση θα
έβγαινε λάθος χωρίς να το δει κανείς.

Έτσι το σώμα είναι βρόχος με κωνικότητα, οι νευρώσεις είναι `% 5` και τα
μάτια/στόμα μπαίνουν από πάνω. Το δεύτερο καρέ δεν ξαναζωγραφίζεται: είναι η
ίδια συνάρτηση με το καπάκι σηκωμένο.

ΔΥΟ ΚΑΡΕ, ΟΧΙ ΤΕΣΣΕΡΑ

Ένα καρέ boss είναι 1.152 bytes με μάσκα. Τέσσερα θα ήταν 4,6 KB για έναν
εχθρό που εμφανίζεται μία φορά στην πίστα. Δύο αρκούν: καπάκι κλειστό και
καπάκι ανοιχτό (τη στιγμή που πετάει το παλιό Amstrad hardware). Η υπόλοιπη
«κίνηση» βγαίνει από το ότι ο boss ΚΟΥΝΙΕΤΑΙ — που δεν κοστίζει μνήμη.
"""
from gfx import PEN, blank

W, H = 24, 48

K, i, I, r, y, o, d = (PEN['K'], PEN['i'], PEN['I'], PEN['r'],
                       PEN['y'], PEN['o'], PEN['d'])

BODY_TOP, BODY_BOT = 12, 46
LID_TOP, LID_BOT = 4, 11


def _hline(img, yy, x0, x1, pen):
    if not 0 <= yy < H:
        return
    for xx in range(max(0, x0), min(W, x1 + 1)):
        img[yy][xx] = pen


def _body_inset(row):
    """Ο τενεκές στενεύει προς τα κάτω — αλλιώς είναι κουτί, όχι κάδος."""
    t = (row - BODY_TOP) / float(BODY_BOT - BODY_TOP)
    return 1 + int(t * 2.99)


def _can(lid_lift=0, mouth_open=False):
    img = blank(W, H, None)

    # ----------------------------------------------------------- σώμα
    for row in range(BODY_TOP, BODY_BOT + 1):
        ins = _body_inset(row)
        x0, x1 = ins, W - 1 - ins
        _hline(img, row, x0, x1, i)
        img[row][x0] = img[row][x1] = K
        if (row - BODY_TOP) % 5 == 0:            # νεύρωση
            _hline(img, row, x0 + 1, x1 - 1, K)
    # σκουριά: λίγες κηλίδες, πάντα στις ίδιες θέσεις ώστε τα δύο καρέ να
    # μη «βράζουν»
    for (rx, ry) in ((4, 17), (18, 23), (6, 33), (16, 38), (9, 42)):
        img[ry][rx] = o
        img[ry][rx + 1] = d
    # βάση
    _hline(img, BODY_BOT, 3, W - 4, K)
    _hline(img, BODY_BOT + 1, 4, W - 5, K)

    # -------------------------------------------------------- χερούλια
    for row in range(24, 31):
        for x in (0, 1):
            img[row][x] = i if row in (25, 26, 27, 28) else K
        for x in (W - 2, W - 1):
            img[row][x] = i if row in (25, 26, 27, 28) else K
    for row in (24, 30):
        _hline(img, row, 0, 2, K)
        _hline(img, row, W - 3, W - 1, K)

    # ----------------------------------------------------------- μάτια
    for row in range(18, 24):
        _hline(img, row, 5, 9, r)
        _hline(img, row, 14, 18, r)
    for row in (18, 23):
        _hline(img, row, 5, 9, K)
        _hline(img, row, 14, 18, K)
    for row in range(20, 22):                    # κόρες
        _hline(img, row, 6, 7, K)
        _hline(img, row, 16, 17, K)
    img[19][6] = img[19][15] = I                 # ανταύγεια

    # ----------------------------------------------------------- στόμα
    if mouth_open:
        for row in range(29, 39):
            _hline(img, row, 6, 17, K)
        for row in range(31, 37):
            _hline(img, row, 7, 16, r)
        for x in range(7, 17, 2):                # δόντια
            img[31][x] = img[32][x] = I
            img[35][x] = img[36][x] = I
    else:
        for row in range(31, 35):
            _hline(img, row, 6, 17, K)
        for x in range(7, 17, 2):
            img[32][x] = img[33][x] = I

    # ---------------------------------------------------------- καπάκι
    lift = lid_lift
    for row in range(LID_TOP, LID_BOT + 1):
        t = (row - LID_TOP) / float(LID_BOT - LID_TOP)
        ins = 3 - int(t * 3.0)                   # θόλος: στενό πάνω, φαρδύ κάτω
        x0, x1 = ins, W - 1 - ins
        _hline(img, row - lift, x0, x1, i)
        if 0 <= row - lift < H:
            img[row - lift][x0] = img[row - lift][x1] = K
    _hline(img, LID_TOP - lift, 3, W - 4, K)     # κορυφή
    _hline(img, LID_BOT - lift, 0, W - 1, K)     # χείλος
    _hline(img, LID_BOT - 1 - lift, 0, W - 1, I)
    # λαβή
    for row in range(LID_TOP - 4, LID_TOP):
        _hline(img, row - lift, 10, 13, K)
    _hline(img, LID_TOP - 3 - lift, 11, 12, i)

    # Όταν σηκώνεται το καπάκι, φαίνεται το φως από μέσα.
    if lift:
        for row in range(LID_BOT - lift + 1, LID_BOT + 1):
            _hline(img, row, 4, W - 5, y)
            img[row][4] = img[row][W - 5] = r
    return img


FRAMES = [('closed', lambda: _can(0, False)),
          ('open',   lambda: _can(4, True))]

NOTE = ('Γιγάντιος μεταλλικός κάδος που πετάει παλιό Amstrad hardware. '
        'Το καπάκι ανοίγει πριν από κάθε βολή — είναι η προειδοποίηση '
        'που δίνει στον παίκτη χρόνο να ξεφύγει.')


def frame(n):
    return FRAMES[n][1]()
