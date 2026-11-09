"""Η ιστορία: οι σκηνές της αρχής και του τέλους, ως «σενάριο» για το src/ui.asm.

Το σενάριο είναι bytes που μπαίνουν συμπιεσμένα στο bank 6 και ανοίγουν στη
σελίδα #9000 της οθόνης που δεν φαίνεται. Τα γραφικά είναι μέσα στο ίδιο το
σενάριο, οπότε δεν κοστίζουν τίποτα όσο παίζεται το παιχνίδι:

    γραμμή (<#F0) κείμενο 0   τυπώνεται γράμμα-γράμμα, στο κέντρο
    #FD γραμμή κείμενο 0      μεγάλα γράμματα, στο κέντρο
    #FC γραμμή x ύψος πλάτος  sprite (mask,data), με τα bytes του από πίσω
    #FB χρώμα                 το pen 0 (ο ουρανός)
    #FA                       ένα καρέ αναμονή
    #FE                       περιμένει fire, και καθαρή οθόνη
    #FF                       τέλος

Το μήνυμα των μυρμηγκιών είναι γράμματα της γραμματοσειράς σε διπλό μέγεθος,
φτιαγμένα από κουκκίδες-μυρμήγκια, που μπαίνουν ανά στήλη: σχηματίζεται αργά.
"""
import enemies as EN
import font as FO
import gfx
import mobs
import pickups as PU
import ship as SP
from gfx import PEN, art, blank, stamp

FONT = dict(FO.sheet())
BLUE_SKY = 0x55

MOUSSAKA = """
....g.....g.....g.......
...g.....g.....g........
....g.....g.....g.......
...g.....g.....g........
.KKKKKKKKKKKKKKKKKKKKKK.
KDDyDDDyDDDDyDDDyDDyDDDK
KDyDDDDDDyDDDDDyDDDDDyDK
KSSSSSSSSSSSSSSSSSSSSSSK
KddddddddddddddddddddddK
KyyyyyyyyyyyyyyyyyyyyyyK
KddddddddddddddddddddddK
KyyyyyyyyyyyyyyyyyyyyyyK
KiiiiiiiiiiiiiiiiiiiiiiK
.KKKKKKKKKKKKKKKKKKKKKK.
"""
PILOT = """
...KKKKKK...
..KiiiiiiK..
.KiiiiiiiiK.
.KigggggIiK.
.KgKgggKggK.
.KggKgKgggK.
.KgKgggKggK.
.KggggggggK.
.KgggKKgggK.
..KgKggKgK..
...KggggK...
..KKKKKKKK..
.KbbbbbbbbK.
KbbbbyybbbbK
KbbbbbbbbbbK
.KKKKKKKKKK.
"""
TEAPOT = """
.....KKKK.......
....KyyyyK......
...KKKKKKKK.....
..KddddddddK...K
.KddddddddddK.Kd
KddIdddddddddKdK
KddIdddddddddddK
KddddddddddddKK.
KddddddddddddK..
.KddddddddddK...
..KddddddddK....
...KKKKKKKK.....
"""
TOILET = """
.KKKKKKKKKKKKK..
.KIIIIIIIIIIIK..
.KIIIIIIIIIIIK..
.KIIIIIIyIIIIK..
.KIIIIIIIIIIIK..
.KKKKKKKKKKKKK..
....KIIIIIK.....
KKKKKKKKKKKKKKKK
KIIIIIIIIIIIIIIK
KiiiiiiiiiiiiiiK
.KIIcccccccIIK..
.KIIcccccccIIK..
..KIIcccccIIK...
...KIIIIIIIK....
....KIIIIIK.....
....KIIIIIK.....
...KIIIIIIIK....
...KKKKKKKKK....
"""
BRUSH = """
.ii.
.ii.
.ii.
.ii.
.ii.
.ii.
.ii.
.ii.
.ii.
.ii.
yyyy
yIyI
yyyy
"""


def emperor():
    """Ο διοικητής, με κορώνα και κόκκινα μάτια: δεν έχει κοιμηθεί ποτέ."""
    img = [row[:] for row in EN.frames('roach')[0]]
    for x in range(2, 10):
        img[1][x] = PEN['y']
        img[2][x] = PEN['y']
    for x in (2, 5, 6, 9):
        img[0][x] = PEN['y']
    img[1][5] = PEN['r']
    return img


def _pad_even(img):
    """Το πλάτος σε bytes: 2 pixels ανά byte."""
    if len(img[0]) % 2:
        return [row + [None] for row in img]
    return img


def _ant_message(text):
    """Το κείμενο σε διπλό μέγεθος, από κουκκίδες-μυρμήγκια."""
    w, h = len(text) * 8, 16
    img = blank(w, h, None)
    for k, ch in enumerate(text):
        g = FONT[ch]
        for y in range(8):
            for x in range(4):
                if g[y][x] is None or g[y][x] == 0:
                    continue
                for yy in range(2):
                    for xx in range(2):
                        px = k * 8 + x * 2 + xx
                        pen = 'y' if (px + y * 2 + yy) % 2 else 'D'
                        img[y * 2 + yy][px] = PEN[pen]
    return img


class Script:
    def __init__(self):
        self.b = []

    def _text(self, text):
        assert len(text) <= 40, text
        for ch in text:
            assert ch in FONT, repr(ch)
        self.b += list(text.encode()) + [0]

    def line(self, row, text):
        self.b.append(row * 8)
        self._text(text)

    def big(self, row, text):
        assert len(text) <= 40
        self.b += [0xFD, row * 8]
        self._text(text)

    def sprite(self, img, line, x):
        img = _pad_even(img)
        w, h = len(img[0]) // 2, len(img)
        assert 0 <= x and x + w <= 80 and line + h <= 168, (line, x, w, h)
        self.b += [0xFC, line, x, h, w] + list(gfx.encode_masked(img))

    def wait(self):
        self.b.append(0xFE)

    def sky(self, hw):
        self.b += [0xFB, hw]

    def reveal(self, text, line):
        """Το μήνυμα, στήλη-στήλη (4 pixels), με ένα καρέ ανάμεσα."""
        img = _ant_message(text)
        x0 = (160 - len(img[0])) // 4
        for k in range(0, len(img[0]), 4):
            col = [row[k:k + 4] for row in img]
            if all(p is None for row in col for p in row):
                continue
            self.sprite(col, line, x0 + k // 2)
            self.b.append(0xFA)

    def end(self):
        return self.b + [0xFE, 0xFF]    # και η τελευταία οθόνη περιμένει


def intro():
    s = Script()
    s.big(1, 'THE YEAR IS 2442')
    s.sprite(_pad_even(art(MOUSSAKA, 24, 14, 'moussaka')), 36, 28)
    s.sprite(art(PILOT, 12, 16, 'pilot'), 34, 18)
    s.sprite(art(PILOT, 12, 16, 'pilot'), 34, 56)
    s.line(9, 'THE SPACE FORCE DEFENDS HUMANITY.')
    s.line(11, 'BUT ITS BEST PILOTS ARE ON LEAVE:')
    s.line(13, 'MASS FOOD POISONING.')
    s.line(15, 'THE CAUSE: SPACE MOUSSAKA.')
    s.wait()
    s.big(1, 'THIS IS WING C')
    s.sprite(SP.frame('n'), 32, 37)
    s.line(9, 'LOWEST SCORE AT THE SPACE ACADEMY.')
    s.line(11, 'NAVIGATION: 5 OUT OF 10.')
    s.line(13, 'THEY STILL CONFUSE THE WARP DRIVE')
    s.line(15, 'WITH THE COFFEE MAKER.')
    s.wait()
    s.big(1, 'THE INVADERS')
    s.sprite(emperor(), 32, 37)
    s.line(9, 'THE KATSAROPHOBIANS HAVE COME')
    s.line(11, 'TO STEAL ALL THE ANTS ON EARTH.')
    s.line(13, 'WHY? THEIR EMPEROR CANNOT SLEEP.')
    s.wait()
    s.big(1, 'MIRMIKOCHAI')
    s.sprite(art(TEAPOT, 16, 12, 'teapot'), 36, 36)
    for k, x in enumerate((20, 26, 50, 56)):
        s.sprite(PU.ant(k % 2), 40, x)
    s.line(9, 'ANTS AND GALACTIC COCOA MAKE A TEA')
    s.line(10, 'THAT PUTS HIM TO SLEEP.')
    s.line(12, 'WITHOUT IT HE WILL END THE UNIVERSE')
    s.line(13, 'BECAUSE HIS NERVES ARE ACTING UP.')
    s.wait()
    s.big(1, 'YOUR MISSION')
    for k in range(7):
        s.sprite(PU.ant(k % 2), 36, 22 + k * 6)
    s.line(8, 'SAVE THE ANTS.')
    s.line(11, 'THE TEAM LEADER HATES ANTS:')
    s.line(12, 'THEY STUNG HIM AT A SCHOOL PICNIC.')
    s.line(15, 'GOOD LUCK, WING C.')
    return s.end()


def ending():
    s = Script()
    s.big(1, 'THE CHEF IS DEFEATED')
    s.sprite(SP.frame('n'), 30, 37)
    for k, (x, y) in enumerate(((16, 34), (24, 44), (52, 36), (60, 46), (30, 56), (46, 58))):
        s.sprite(PU.ant(k % 2), y, x)
    s.line(10, 'MILLIONS OF ANTS ARE FREE.')
    s.line(12, 'THEY FLY BACK TO EARTH')
    s.line(14, 'AND GATHER IN THE SKY...')
    s.wait()
    s.sky(BLUE_SKY)
    s.reveal('THANK YOU', 16)
    s.reveal('WING C', 44)
    s.reveal('(YOU ALMOST', 88)
    s.reveal('MESSED IT UP)', 116)
    s.wait()
    s.big(1, 'PROMOTION!')
    s.sprite(art(TOILET, 16, 18, 'toilet'), 32, 36)
    s.sprite(_pad_even(art(BRUSH, 4, 13, 'brush')), 37, 48)
    s.line(9, 'FOR SAVING THE PLANET')
    s.line(10, 'WING C GETS A NEW POST:')
    s.line(13, 'THEY WILL CLEAN THE TOILETS')
    s.line(14, 'OF THE SPACE STATION.')
    s.wait()
    s.big(1, 'SPACE FORCE C')
    s.line(5, 'REVIVE8BIT - 2026 - VASPER')
    s.line(7, 'CODE AND ART WITH CLAUDE')
    s.line(9, 'BUILT WITH RASM AND IDSK')
    s.line(11, 'FOR THE AMSTRAD CPC 6128')
    for k in range(9):
        s.sprite(PU.ant(k % 2), 112, 16 + k * 6)
    s.line(16, 'THANK YOU FOR PLAYING.')
    return s.end()


SCENES = [('intro', intro), ('ending', ending)]
