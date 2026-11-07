"""Τα πλακίδια του φόντου — 8x8 pixels, ΑΔΙΑΦΑΝΑ.

ΧΩΡΙΣ ΜΑΣΚΑ, ΓΙΑΤΙ ΔΕΝ ΕΧΟΥΝ ΤΙΠΟΤΑ ΑΠΟ ΚΑΤΩ

32 bytes το ένα και μπαίνει με `LDI`. Σε multi-directional scrolling το φόντο
ξαναζωγραφίζεται ΣΥΝΕΧΩΣ — είναι το πιο ακριβό πράγμα στο καρέ μετά τα
sprites. Μάσκα εδώ θα σήμαινε διπλά bytes και διπλό χρόνο για το τίποτα.

ΤΟ PEN 0 ΕΔΩ ΕΙΝΑΙ ΚΑΝΟΝΙΚΟ ΜΑΥΡΟ

Στα sprites το pen 0 είναι η μάσκα. Στα πλακίδια είναι το κενό διάστημα. Δεν
συγκρούονται ποτέ γιατί δεν περνάνε από την ίδια ρουτίνα.

ΟΙ ΚΟΥΚΚΙΔΕΣ ΜΕΝΟΥΝ ΜΑΚΡΙΑ ΑΠΟ ΤΙΣ ΑΚΜΕΣ

Ένα αστέρι στη στήλη 0 ή 7 γίνεται ΓΡΑΜΜΗ μόλις το πλακίδιο μπει δίπλα στον
εαυτό του, και το μάτι πιάνει αμέσως το πλέγμα 8x8. Με scrolling είναι
χειρότερο: το πλέγμα κυλάει και φαίνεται ακόμα πιο καθαρά.

ΔΕΚΑΕΞΙ, ΟΧΙ ΕΙΚΟΣΙ

Ο χάρτης είναι ένα nibble ανά πλακίδιο. Τα 16 εδώ καλύπτουν και τις τέσσερις
πίστες του διαστήματος: αστέρια (1), νεφέλωμα (2), σταθμός (3), Σελήνη (4).
"""
from gfx import art

W, H = 8, 8

VOID = """
........
........
........
........
........
........
........
........
"""
STAR_S = """
........
...I....
........
........
......I.
........
..I.....
........
"""
STAR_M = """
........
....I...
...III..
....I...
........
..I.....
........
.....i..
"""
STARS_3 = """
........
..i...i.
........
.....I..
........
.i......
....i...
........
"""
DUST = """
........
..K..b..
........
.b....K.
........
..K..b..
........
....K...
"""
NEBULA_A = """
..K..KK.
.KKKK.K.
K.KKKKK.
.KK.KKK.
KKKK..KK
.K.KKKK.
KK.KK.K.
.K..K.KK
"""
NEBULA_B = """
KKKKKKKK
KKKbKKKK
KKbKKKbK
KKKKbKKK
KbKKKKKK
KKKKKbKK
KKbKKKKK
KKKKKKKK
"""
NEBULA_C = """
KKKKKKKK
KKbKKKKK
KbKKKmKK
KKKKKKKK
KKmKKbKK
KKKKKKKK
KbKKKKbK
KKKKKKKK
"""
PLATE = """
iiiiiiii
iiiiiiii
iiiiiiKi
iiiiiiii
iiiiiiii
iKiiiiii
iiiiiiii
KKKKKKKK
"""
PLATE_RIVET = """
iiiiiiii
iIiiiiIi
iiiiiiii
iiiiiiii
iiiiiiii
iIiiiiIi
iiiiiiii
KKKKKKKK
"""
GRATE = """
KiKiKiKi
iKiKiKiK
KiKiKiKi
iKiKiKiK
KiKiKiKi
iKiKiKiK
KiKiKiKi
iKiKiKiK
"""
PIPE = """
KKKKKKKK
oooooooo
oIoooooo
oooooooo
oooooooo
oooooooo
oooooooo
KKKKKKKK
"""
MOON = """
iiiiiiii
iiiKiiii
iiiiiiii
iiiiiiKi
iiiiiiii
iKiiiiii
iiiiiiii
iiiiiiii
"""
MOON_CRATER = """
iiiiiiii
iiKKKKii
iKKiiKKi
iKiiiiKi
iKiiiiKi
iKKiiKKi
iiKKKKii
iiiiiiii
"""
TUNNEL = """
dddddddd
ddDddddd
dddddddd
ddddddDd
dddddddd
dDdddddd
dddddddd
dddddddd
"""
TRASH = """
oooooooo
ooKoiooo
oooooooo
ooooiKoo
oooooooo
oKoooooo
ooooiooo
oooooooo
"""

# κλειδί, όνομα, τέχνη, σε ποιες πίστες
TILES = [
    ('void',        'κενό',             VOID,        '1-4'),
    ('star_s',      'αστέρι μικρό',     STAR_S,      '1-4'),
    ('star_m',      'αστέρι μεγάλο',    STAR_M,      '1-4'),
    ('stars_3',     'αστερισμός',       STARS_3,     '1-4'),
    ('dust',        'σκόνη',            DUST,        '1,3'),
    ('nebula_a',    'νεφέλωμα αραιό',   NEBULA_A,    '2'),
    ('nebula_b',    'νεφέλωμα πυκνό',   NEBULA_B,    '2'),
    ('nebula_c',    'νεφέλωμα ροζ',     NEBULA_C,    '2'),
    ('plate',       'έλασμα σταθμού',   PLATE,       '2,3'),
    ('plate_rivet', 'έλασμα με καρφιά', PLATE_RIVET, '2,3'),
    ('grate',       'σχάρα',            GRATE,       '2,3'),
    ('pipe',        'σωλήνας',          PIPE,        '3'),
    ('moon',        'σεληνιακό έδαφος', MOON,        '4'),
    ('moon_crater', 'κρατήρας',         MOON_CRATER, '4'),
    ('tunnel',      'σήραγγα μυρμηγκιών', TUNNEL,    '4'),
    ('trash',       'σκουπίδια',        TRASH,       '3'),
]
assert len(TILES) == 16, 'ένα nibble ανά πλακίδιο χωράει ακριβώς 16'


def tile(key):
    a = dict((k, t) for k, _, t, _ in TILES)[key]
    img = art(a, W, H, 'tile/' + key, transparent='')
    assert all(p is not None for row in img for p in row), \
        '%s: το πλακίδιο είναι ΑΔΙΑΦΑΝΟ — χρησιμοποίησε το "." μόνο για μαύρο' \
        % key
    return img
