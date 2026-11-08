"""Οι εχθροί που αλλάζουν ανά πίστα: οι θέσεις «κάλτσα» (8x16) και «βαλίτσα»
(12x20) του enemies.py. Μπαίνουν από το levels.py πάνω στα γραφικά του bank 5.

Κάθε ένας έχει ένα ζωγραφισμένο καρέ. Το δεύτερο βγαίνει αλλάζοντας χρώματα
(φώτα, φλας), όπως οι λάμψεις των power-ups: καμία δεύτερη ζωγραφιά.
"""
import enemies as EN
from gfx import PEN, art, recolour


def _anim(img, swap):
    return [img, recolour(img, {PEN[a]: PEN[b] for a, b in swap})]


CONE = """
...KK...
...DD...
...DD...
..KDDK..
..DIID..
..DIID..
..KDDK..
.KDDDDK.
.DDDDDD.
.DIIIID.
.DIIIID.
.KDDDDK.
KDDDDDDK
KKKKKKKK
K.yyyy.K
..yyyy..
"""
CAR = """
............
............
...KKKKKK...
..KccccccK..
..KcIccccK..
.KKccccccKK.
.KrrrrrrrrK.
KrrIrrrrrrrK
KrrrrrrrrrrK
KrrrrrrrrrrK
KyyrrrrrrrrK
KyyrrrrrryyK
KKKKKKKKKKKK
.KiiK..KiiK.
.KiiK..KiiK.
..yy....yy..
..yy....yy..
...y....y...
............
............
"""
BEETLE = """
..K....K
...K..K.
...KKKK.
..KddddK
..KdIdIK
..KddddK
.KKKKKKK
KDDDKDDD
KDDDKDDD
KDdDKDdD
KDDDKDDD
KDDDKDDD
KdDDKDDd
.KDDKDDK
..KKKKK.
.K..K..K
"""
BIG_ANT = """
..K......K..
...K....K...
....KKKK....
...KddddK...
...KdIdIK...
...KddddK...
....KKKK....
.K..KddK..K.
..K.KddK.K..
...KKddKK...
....KKKK....
...KddddK...
.KKKddddKKK.
K..KddddK..K
...KdDDdK...
..KKdDDdKK..
.K.KddddK.K.
K...KddK...K
.....KK.....
............
"""
TOURIST = """
..KKKK..
.KyyyyK.
.KppppK.
.KpKpKK.
.KppppK.
..KppK..
.KmmmmK.
KmmKKmmK
KmKiIKmK
KmKiiKmK
KmmKKmmK
.KmmmmK.
..KccK..
..KccK..
..KccK..
..KKKK..
"""
BUS = """
.KKKKKKKKKK.
KyyyyyyyyyyK
KyKccKccKcyK
KyKcIKccKcyK
KyKccKccKcyK
KyKKKKKKKKyK
KyyyyyyyyyyK
KrrrrrrrrrrK
KyyyyyyyyyyK
KyyyyyyyyyyK
KyyyyIIyyyyK
KyyyyIIyyyyK
KyyyyyyyyyyK
KKKKKKKKKKKK
.KiiK..KiiK.
.KiKK..KKiK.
..KK....KK..
............
............
............
"""
PAN = """
........
.KKKKKK.
KiiiiiiK
KiKKKKiK
KiKyyKiK
KiKyyKiK
KiKKKKiK
KiiiiiiK
.KKKKKK.
...dd...
...dd...
...dd...
...dd...
...dd...
...KK...
........
"""
POT = """
............
...I....I...
....I..I....
...I....I...
............
KKKKKKKKKKKK
KIIIIIIIIIIK
KggggyggggyK
KKKKKKKKKKKK
KiiKiiiiiiiK
KiiKiiiiiiiK
KiiKiiiiiiiK
KiiKiiiiiiiK
KiiKiiiiiiiK
KiiKiiiiiiiK
KiiKiiiiiiiK
.KKKKKKKKKK.
..rryyrryy..
...yrryyr...
............
"""

# ανά σετ: (μικρός 8x16 x 2 καρέ, μεγάλος 12x20 x 2 καρέ)
SETS = {
    'space': (EN.frames('sock'), EN.frames('suitcase')),
    'attiki': (_anim(art(CONE, 8, 16, 'cone'), [('I', 'y')]),
               _anim(art(CAR, 12, 20, 'car'), [('y', 'r')])),
    'megara': (_anim(art(BEETLE, 8, 16, 'beetle'), [('I', 'r')]),
               _anim(art(BIG_ANT, 12, 20, 'ant'), [('I', 'r')])),
    'acropolis': (_anim(art(TOURIST, 8, 16, 'tourist'), [('I', 'y'), ('i', 'I')]),
                  _anim(art(BUS, 12, 20, 'bus'), [('I', 'S')])),
    'kitchen': (_anim(art(PAN, 8, 16, 'pan'), [('y', 'r')]),
                _anim(art(POT, 12, 20, 'pot'), [('y', 'r'), ('r', 'y')])),
}
