"""Power-ups και τα κλεμμένα μυρμήγκια.

ΟΚΤΩ ΕΠΙ ΔΕΚΑΕΞΙ, ΔΗΛΑΔΗ ΤΕΤΡΑΓΩΝΟ

8x16 px = 16x16 μονάδες οθόνης. Ένα power-up πρέπει να διαβάζεται ΑΚΑΡΙΑΙΑ
μέσα σε μάχη, και το μόνο που διαβάζεται ακαριαία είναι το σχήμα — όχι το
γράμμα, όχι το χρώμα. Γι' αυτό κάθε ένα είναι ΑΝΤΙΚΕΙΜΕΝΟ (φλιτζάνι, μαγνήτης,
σπρέι) και όχι κάψουλα με γράμμα μέσα.

ΤΟ ΔΕΥΤΕΡΟ ΚΑΡΕ ΔΕΝ ΖΩΓΡΑΦΙΖΕΤΑΙ

Τα power-ups αναβοσβήνουν για να ξεχωρίζουν από τα σκουπίδια του φόντου. Το
καρέ «λάμψης» βγαίνει αυτόματα: το navy περίγραμμα γίνεται λευκό. Δύο καρέ
ανά power-up χωρίς δεύτερο σχέδιο να συντηρείς — και χωρίς να ξεχάσεις να
ενημερώσεις το ένα από τα δύο.

ΤΟ ΜΥΡΜΗΓΚΙ ΕΙΝΑΙ Ο ΠΟΝΤΟΣ ΤΟΥ ΠΑΙΧΝΙΔΙΟΥ

Όλη η πλοκή είναι ότι οι Katsarophobians κλέβουν τα μυρμήγκια της Γης. Κάθε
εχθρός που σκάει αφήνει ένα, και ο παίκτης το μαζεύει. Είναι 8x8 και σκούρο
καφέ — που πάνω στο μαύρο του διαστήματος θα χανόταν, γι' αυτό έχει
πορτοκαλί ράχη.
"""
from gfx import PEN, art, recolour

W, H = 8, 16
ANT_W, ANT_H = 8, 8

SHIELD = """
.KKKKKK.
KIIbIIbK
KccbccbK
KccbccbK
KbbbbbbK
KbIIbIIK
KbccbccK
KbccbccK
KbbbbbbK
KIIbIIbK
KccbccbK
KccbccbK
KbbbbbbK
KbIIbIIK
KbccbccK
.KKKKKK.
"""

ESPRESSO = """
.I..I...
..I.I...
KKKKKKK.
KIIIIIK.
KIdddIK.
KIdddIKK
KIdddIKI
KIIIIIKI
KIIIIIKK
KIIIIIK.
KIIIIIK.
KIIIIIK.
.KIIIK..
..KKK...
........
........
"""

MAGNET = """
KiiKKiiK
KiiKKiiK
KrrKKrrK
KrrKKrrK
KrrKKrrK
KrrKKrrK
KrrKKrrK
KrrKKrrK
KrrKKrrK
KrrKKrrK
KrrKKrrK
KrrrrrrK
KrrrrrrK
.KrrrrK.
..KKKK..
........
"""

ENGINE = """
..KiiK..
.KiiiiK.
.KiiiiK.
KiiiiiiK
KiiiiiiK
KiiiiiiK
KiIIIIiK
KIIIIIIK
.KyyyyK.
.KyyyyK.
KyrrrryK
KyrrrryK
.KrrrrK.
..KrrK..
...KK...
........
"""

DISCO = """
..KKKK..
.KmcmcK.
KcmcmcmK
KmcmcmcK
KcmImcmK
KmcmcmcK
KcmcmcmK
KmcmcmcK
KcmcmcmK
KmcmcmcK
KcmcmcmK
KmcmcmcK
KcmcmcmK
.KmcmcK.
..KKKK..
........
"""

BAGUETTE = """
...KK...
..KyyK..
..ySSy..
..ySSy..
..yDSy..
..ySSy..
..ySSy..
..ySDy..
..ySSy..
..ySSy..
..yDSy..
..ySSy..
..ySSy..
..KyyK..
...KK...
........
"""

SNEEZE = """
...KK...
..KggK..
.KgnngK.
KgnggngK
KggnngnK
KgnggngK
KggnggnK
KgnggngK
KggnngnK
KgnggngK
KggnggnK
.KgnngK.
..KggK..
...KK...
........
........
"""

SPRAY = """
...KK...
..KnnK..
.KnnnnK.
.KggggK.
KgIggIgK
KggggggK
KgIggIgK
KggggggK
KgIggIgK
KggggggK
KgIggIgK
KggggggK
KgnnnngK
.KnnnnK.
.KKKKKK.
........
"""

LIFE = """
........
...KK...
..KSSK..
..KSSK..
.KSccSK.
.KSccSK.
KDSSSSDK
KDSSSSDK
KDSSSSDK
.KSSSSK.
.KSSSSK.
.KiSSiK.
.KiSSiK.
..KKKK..
........
........
"""

# κλειδί, όνομα, τέχνη, τι κάνει
PICKUPS = [
    ('shield',   'Shield Bubble Wrap', SHIELD,
     'ασπίδα· σπάει με «ποπ»'),
    ('espresso', 'Espresso Boost',     ESPRESSO,
     'προσωρινή ταχύτητα· οι πιλότοι μιλάνε 3x πιο γρήγορα'),
    ('magnet',   'Ant-Magnet',         MAGNET,
     'τραβάει μόνο του τα μυρμήγκια'),
    ('engine',   'Engine upgrade',     ENGINE,
     'μόνιμη αύξηση ταχύτητας'),
    ('disco',    'Disco-Ray',          DISCO,
     'όπλο: δέσμη neon, οι εχθροί χορεύουν ώσπου να σκάσουν'),
    ('baguette', 'Mega-Baguette',      BAGUETTE,
     'όπλο: μπαγιάτικες μπαγκέτες που διαπερνούν ασπίδες'),
    ('sneeze',   'Sneeze Cannon',      SNEEZE,
     'όπλο: πράσινα σωματίδια με αντίκρουση'),
    ('spray',    'Insecticide',        SPRAY,
     'αυτόματος ψεκαστήρας εναντίον των μυρμηγκο-εχθρών'),
    ('life',     'Extra life',         LIFE,
     'μία ζωή ακόμα για το Wing C'),
]

# Το καρέ λάμψης: μόνο το περίγραμμα αλλάζει.
FLASH = {'K': 'I'}

ANT = ["""
.D....D.
..DDDD..
.DDddDD.
.DDddDD.
.DDddDD.
..DDDD..
.D.DD.D.
D......D
""", """
.D....D.
..DDDD..
.DDddDD.
.DDddDD.
.DDddDD.
..DDDD..
D..DD..D
.D....D.
"""]


def pickup(key, flash=False):
    a = dict((k, art_) for k, _, art_, _ in PICKUPS)[key]
    img = art(a, W, H, 'pickup/' + key)
    if flash:
        img = recolour(img, {PEN[x]: PEN[y] for x, y in FLASH.items()})
    return img


def ant(phase):
    return art(ANT[phase], ANT_W, ANT_H, 'ant%d' % phase)
