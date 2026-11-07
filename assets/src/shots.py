"""Τα βλήματα — του παίκτη και των εξωγήινων. Όλα 8x8 pixels.

ΕΝΑ ΜΕΓΕΘΟΣ ΓΙΑ ΟΛΑ ΤΑ ΒΛΗΜΑΤΑ

8x8 px = 16x8 μονάδες οθόνης, 64 bytes με μάσκα. Ένα blit ~0,7 ms. Με 12
βλήματα στην οθόνη αυτό είναι 8,4 ms από τα 40 του καρέ — και γι' αυτό δεν
υπάρχει δεύτερο μέγεθος: ένα βλήμα 12x24 θα κόστιζε όσο τέσσερα.

ΟΣΑ ΤΑΞΙΔΕΥΟΥΝ ΕΧΟΥΝ ΚΑΤΕΥΘΥΝΣΗ, ΟΣΑ ΑΠΛΩΝΟΥΝ ΟΧΙ

    με κατεύθυνση   disco, baguette, spaghetti, torpedo  — 8 όψεις
    χωρίς           sneeze, e9                           — 3 καρέ κίνησης

Στα κατευθυνόμενα ζωγραφίζονται τρεις όψεις (N, NE, E) και οι πέντε βγαίνουν
με καθρέφτισμα, ακριβώς όπως στο σκάφος.

Η ΔΙΑΓΩΝΙΟΣ ΠΑΕΙ ΜΙΑ ΣΤΗΛΗ ΑΝΑ ΔΥΟ ΓΡΑΜΜΕΣ

Μια δέσμη που φαίνεται στις 45 μοίρες στην οθόνη κουνιέται μισό pixel ανά
γραμμή. Αν ζωγραφιστεί 1:1 στο πλέγμα, στην οθόνη βγαίνει 63 μοίρες και δεν
δείχνει να πηγαίνει εκεί που πηγαίνει το βλήμα.
"""
from gfx import art, flip, mirror

W, H = 8, 8
DIRS = ('n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw')
DERIVED = {
    's':  ('n',  True,  False),
    'se': ('ne', True,  False),
    'nw': ('ne', False, True),
    'sw': ('ne', True,  True),
    'w':  ('e',  False, True),
}

# ------------------------------------------- Disco-Ray: neon που αναβοσβήνει
# Δύο καρέ με ανταλλαγμένα ματζέντα/κυανό. Σε 25 FPS το μάτι το βλέπει να
# τρεμοπαίζει — που είναι ακριβώς ο λόγος που οι εξωγήινοι χορεύουν.
DISCO = {
    'n': ["""
..mccm..
..mccm..
..mccm..
..mccm..
..mccm..
..mccm..
..mccm..
..mccm..
""", """
..cmmc..
..cmmc..
..cmmc..
..cmmc..
..cmmc..
..cmmc..
..cmmc..
..cmmc..
"""],
    'ne': ["""
......mc
......mc
.....mc.
.....mc.
....mc..
....mc..
...mc...
...mc...
""", """
......cm
......cm
.....cm.
.....cm.
....cm..
....cm..
...cm...
...cm...
"""],
    'e': ["""
........
........
mmmmmmmm
cccccccc
cccccccc
mmmmmmmm
........
........
""", """
........
........
cccccccc
mmmmmmmm
mmmmmmmm
cccccccc
........
........
"""],
}

# ------------------------------- Mega-Baguette: μπαγκέτα μπαγιάτικη, διαπερνά
BAGUETTE = {
    'n': ["""
...yy...
..ySSy..
..ySSy..
..yDSy..
..ySSy..
..ySDy..
..ySSy..
...yy...
"""],
    'ne': ["""
......yy
.....ySy
.....ySy
....ySy.
....yDy.
...ySy..
...ySy..
...yy...
"""],
    'e': ["""
........
........
.yyyyyy.
ySSDSSSy
ySSSSDSy
.yyyyyy.
........
........
"""],
}

# --------------------------- Sneeze Cannon: πράσινα σωματίδια που σκορπίζουν
# Δεν έχει κατεύθυνση επίτηδες: το φτάρνισμα ΑΠΛΩΝΕΙ. Τα τρία καρέ είναι
# πυκνό -> φαρδύ -> αραιό, και παίζουν μία φορά όσο ζει το βλήμα.
SNEEZE = ["""
........
...gg...
..gngg..
..ggng..
...gg...
........
........
........
""", """
..g..g..
.ggggg..
.gnggng.
..ggggg.
.g.gg.g.
..g...g.
........
........
""", """
.g....g.
....g...
..g...g.
.....g..
.g..g...
....g..g
..g.....
.g....g.
"""]

# ------------------------- Laser Spaghetti: κολλάει και κόβει την ταχύτητα
SPAGHETTI = {
    'n': ["""
...oo...
..o..o..
..o..o..
...oo...
..o..o..
..o..o..
...oo...
........
"""],
    'ne': ["""
.....oo.
....o..o
....o..o
...oo...
...o..o.
..o..o..
..oo....
........
"""],
    'e': ["""
........
........
.oo..oo.
o..oo..o
o..oo..o
.oo..oo.
........
........
"""],
}

# ------------------- Bureaucracy Beam: έντυπο Ε9 που ανεμίζει στο παρμπρίζ
# Χωρίς κατεύθυνση: το χαρτί στριφογυρίζει. Τρία καρέ = φαρδύ, μισό, κόψη.
E9 = ["""
.pppppp.
.pKKKKp.
.pppppp.
.pKKKKp.
.pppppp.
.pKKKKp.
.pppppp.
........
""", """
..pppp..
..pKKp..
..pppp..
..pKKp..
..pppp..
..pKKp..
..pppp..
........
""", """
...pp...
...pK...
...pp...
...pK...
...pp...
...pK...
...pp...
........
"""]

# --------------- Bad Breath Torpedo: ζιγκ-ζαγκ από ναυτία, με ίχνος δυσοσμίας
TORPEDO = {
    'n': ["""
...gg...
..gggg..
..gnng..
..gnng..
..gggg..
...gg...
..n..n..
.n....n.
"""],
    'ne': ["""
.....gg.
....gggg
....gnng
...gngg.
...ggg..
..gg....
..n.n...
.n...n..
"""],
    'e': ["""
........
..gggg..
.gggnnng
nggnnnng
.gggnnng
..gggg..
.n..n...
n..n....
"""],
}

DIRECTED = {'disco': DISCO, 'baguette': BAGUETTE,
            'spaghetti': SPAGHETTI, 'torpedo': TORPEDO}
SPREAD = {'sneeze': SNEEZE, 'e9': E9}


def phases(kind):
    return len(DIRECTED[kind]['n']) if kind in DIRECTED else len(SPREAD[kind])


def shot(kind, direction='n', phase=0):
    if kind in SPREAD:
        return art(SPREAD[kind][phase], W, H, '%s%d' % (kind, phase))
    table = DIRECTED[kind]
    if direction in table:
        return art(table[direction][phase], W, H,
                   '%s/%s%d' % (kind, direction, phase))
    src, do_flip, do_mirror = DERIVED[direction]
    img = art(table[src][phase], W, H, '%s/%s%d' % (kind, src, phase))
    if do_flip:
        img = flip(img)
    if do_mirror:
        img = mirror(img)
    return img
