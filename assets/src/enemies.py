"""Οι Katsarophobians και τα σκουπίδια του διαστήματος.

ΟΙ ΕΧΘΡΟΙ ΔΕΝ ΕΧΟΥΝ ΟΚΤΩ ΟΨΕΙΣ

Το σκάφος του παίκτη στρίβει γιατί ο παίκτης το στρίβει. Οι εχθροί ακολουθούν
σχέδια — ευθεία, κύκλο, κυνηγητό — και στο Mode 0 σε 16x16 μονάδες η
κατεύθυνση ενός εχθρού ΔΕΝ διαβάζεται ούτως ή άλλως. Οκτώ όψεις ανά εχθρό θα
ήταν x8 μνήμη για πληροφορία που κανείς δεν βλέπει. Αντ' αυτού: δύο καρέ
κίνησης, που διαβάζονται αμέσως γιατί ΚΟΥΝΙΟΥΝΤΑΙ.

ΔΕΝ ΕΧΟΥΝ ΟΛΟΙ ΤΟ ΙΔΙΟ ΜΕΓΕΘΟΣ

Σε αντίθεση με τα βλήματα, εδώ χρειάζεται πίνακας: πλάτος σε bytes, ύψος σε
γραμμές, μετατόπιση. Είναι η ίδια δομή με τα κτίρια ενός παιχνιδιού
στρατηγικής, και υπάρχει γιατί ένα μικρό σκουπίδι δεν πρέπει να πληρώνει το
blit ενός διοικητή.

    grunt     8x16   16x16 μονάδες   η μάζα των Katsarophobians
    mine      8x16   16x16           νάρκη, δεν κινείται, σκάει
    sock      8x16   16x16           χαμένη κάλτσα (level 1)
    saucer   12x16   24x16           ιπτάμενος δίσκος, φαρδύς επίτηδες
    suitcase 12x20   24x20           χαμένη βαλίτσα (level 1)
    roach    12x24   24x24           Katsarophobian διοικητής
"""
from gfx import art

GRUNT = ["""
...KK...
..KggK..
.KggggK.
.KgccgK.
KggccggK
KgnggngK
KgnggngK
KggggggK
KggggggK
.KggggK.
KKggggKK
KnKggKnK
Kn.KK.nK
.K....K.
..K..K..
........
""", """
...KK...
..KggK..
.KggggK.
.KgccgK.
KggccggK
KgnggngK
KgnggngK
KggggggK
KggggggK
.KggggK.
KKggggKK
KnKggKnK
.KnKKnK.
..K..K..
.K....K.
........
"""]

MINE = ["""
..i..i..
...ii...
i.KiiK.i
.iKiiKi.
.KiiiiK.
KiirriiK
KirrrriK
KirrrriK
KiirriiK
.KiiiiK.
.iKiiKi.
i.KiiK.i
...ii...
..i..i..
........
........
""", """
.i....i.
..i..i..
.iKiiKi.
i.KiiK.i
.KiiiiK.
KiiIIiiK
KiIIIIiK
KiIIIIiK
KiiIIiiK
.KiiiiK.
i.KiiK.i
.iKiiKi.
..i..i..
.i....i.
........
........
"""]

SOCK = ["""
..KKKK..
.KIIIIK.
.KppppK.
.KppppK.
.KppppK.
.KppppK.
.KppppK.
.KppppK.
.KppppK.
.KppppK.
.KppppK.
KKppppK.
KpppppK.
KppppKK.
KKKKK...
........
""", """
..KKKK..
.KIIIIK.
.KppppK.
.KppppK.
.KppppK.
.KppppK.
.KppppK.
.KppppK.
.KppppK.
.KppppK.
.KppppK.
.KppppKK
.KpppppK
.KKppppK
...KKKKK
........
"""]

SAUCER = ["""
....KKKK....
...KccccK...
..KcIIIIcK..
..KccccccK..
.KiiiiiiiiK.
KiiIiiiiIiiK
KiiiiiiiiiiK
KIiiiiiiiiIK
KiiiiiiiiiiK
.KiiiiiiiiK.
..KKKKKKKK..
...KrrrrK...
....KrrK....
.....KK.....
............
............
""", """
....KKKK....
...KccccK...
..KcIIIIcK..
..KccccccK..
.KiiiiiiiiK.
KIiiiiiiiiIK
KiiiiiiiiiiK
KiiIiiiiIiiK
KiiiiiiiiiiK
.KiiiiiiiiK.
..KKKKKKKK..
...KyyyyK...
....KyyK....
.....KK.....
............
............
"""]

SUITCASE = ["""
............
....KKKK....
...KiiiiK...
...KK..KK...
KKKKKKKKKKKK
KddddddddddK
KdDDDDDDDDdK
KdDDDDDDDDdK
KdDDIIIIDDdK
KdDDDDDDDDdK
KdDDDDDDDDdK
KddddddddddK
KdDDDDDDDDdK
KdDDIIIIDDdK
KdDDDDDDDDdK
KddddddddddK
KKKKKKKKKKKK
............
............
............
""", """
............
............
....KKKK....
...KiiiiK...
...KK..KK...
KKKKKKKKKKKK
KddddddddddK
KdDDDDDDDDdK
KdDDIIIIDDdK
KdDDDDDDDDdK
KdDDDDDDDDdK
KddddddddddK
KdDDDDDDDDdK
KdDDIIIIDDdK
KdDDDDDDDDdK
KdDDDDDDDDdK
KddddddddddK
KKKKKKKKKKKK
............
............
"""]

ROACH = ["""
.....KK.....
..K..KK..K..
..K.KnnK.K..
...KnnnnK...
..KnrrrrnK..
..KnrrrrnK..
.KnnnnnnnnK.
KnngggggggnK
KngggggggggK
KnggnnnnnggK
KnggnnnnnggK
KngggggggggK
KnggnnnnnggK
KnggnnnnnggK
KngggggggggK
.KnnnnnnnnK.
..KnnnnnnK..
.K.KnnnnK.K.
K..KnnnnK..K
...KnnnnK...
..K.KKKK.K..
.K........K.
............
............
""", """
.....KK.....
.K...KK...K.
.K..KnnK..K.
...KnnnnK...
..KnrrrrnK..
..KnrrrrnK..
.KnnnnnnnnK.
KnngggggggnK
KngggggggggK
KnggnnnnnggK
KnggnnnnnggK
KngggggggggK
KnggnnnnnggK
KnggnnnnnggK
KngggggggggK
.KnnnnnnnnK.
..KnnnnnnK..
..KKnnnnKK..
.K.KnnnnK.K.
K...KnnK...K
...KKKKKK...
..K......K..
............
............
"""]

# κλειδί, όνομα, πλάτος, ύψος, καρέ, πού εμφανίζεται
# Οι τελευταίοι δύο αλλάζουν ανά πίστα (mobs.py, levels.py): κρατάμε τη σειρά.
ENEMIES = [
    ('grunt',    'Katsarophobian',  8, 16, GRUNT,
     'η μάζα του στρατού τους· πετάει σε σχηματισμούς'),
    ('mine',     'νάρκη',           8, 16, MINE,
     'δεν κινείται, σκάει στην επαφή'),
    ('saucer',   'ιπτάμενος δίσκος', 12, 16, SAUCER,
     'ρίχνει Laser Spaghetti σε τόξο'),
    ('roach',    'διοικητής',       12, 24, ROACH,
     'κυνηγάει το σκάφος· αφήνει δύο μυρμήγκια'),
    ('sock',     'χαμένη κάλτσα',   8, 16, SOCK,
     'αστεροειδής του level 1 — ό,τι έχασε η αποσκευή'),
    ('suitcase', 'χαμένη βαλίτσα',  12, 20, SUITCASE,
     'αστεροειδής του level 1 — αργός, αντέχει πολλά'),
]


def frames(key):
    k, name, w, h, arts, note = dict((e[0], e) for e in ENEMIES)[key]
    return [art(a, w, h, 'enemy/%s%d' % (key, i)) for i, a in enumerate(arts)]
