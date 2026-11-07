"""Η παλέτα του Space Force C, τα εργαλεία ζωγραφικής και τα σετ sprites.

ΤΟ PEN 0 ΕΙΝΑΙ ΤΟ ΔΙΑΦΑΝΟ

Σε sprite με μάσκα το pen 0 σημαίνει «μη ζωγραφίσεις εδώ». Άρα τα
περιγράμματα ΔΕΝ μπορούν να είναι pen 0 — θα γίνονταν τρύπες. Το pen 1 είναι
το μπλε της νύχτας (#000080): περνάει για μαύρο σε οθόνη και κρατάει το 0
ελεύθερο για τη μάσκα.

Στα ΠΛΑΚΙΔΙΑ, που είναι αδιαφανή, το pen 0 είναι κανονικό μαύρο — και είναι
ακριβώς το κενό διάστημα. Το ίδιο pen, δύο σημασίες, καμία σύγκρουση: τα δύο
δεν περνάνε ποτέ από την ίδια ρουτίνα.

ΜΙΑ ΠΑΛΕΤΑ ΓΙΑ ΤΟΥΣ ΔΥΟ ΚΟΣΜΟΥΣ

Το todo άφηνε ανοιχτό να αλλάζει η παλέτα ανά world. Δεν αλλάζει, και αυτό
είναι απόφαση, όχι παράλειψη. Το πλοίο, τα βλήματα, οι εκρήξεις, τα μυρμήγκια,
τα power-ups και το HUD εμφανίζονται και στους οκτώ πίστες· αν τα pens άλλαζαν
νόημα στη μέση, κάθε ένα από αυτά θα χρειαζόταν δεύτερη έκδοση. Τα 16 που
ακολουθούν καλύπτουν και το διάστημα και τη Γη:

    διάστημα   μαύρο, navy, γκρι, κυανό, ουρανί, ματζέντα
    Γη         καφέ, λαδί, δύο πράσινα, ροζ, κρεμ

ΤΟ PIXEL ΕΙΝΑΙ ΔΙΠΛΑΣΙΑ ΦΑΡΔΥ ΑΠΟ ΨΗΛΟ

Στο Mode 0 η οθόνη είναι 160x200 pixels αλλά 320x200 ΜΟΝΑΔΕΣ. Ένα sprite
24x24 pixels πιάνει 48x24 μονάδες — δηλαδή είναι ΔΙΠΛΑΣΙΑ ΦΑΡΔΥ από ψηλό στην
οθόνη, όχι τετράγωνο. Κάθε σχήμα που το θες τετράγωνο το ζωγραφίζεις
διπλάσια ψηλό εδώ. Δες το `assets/README.md`.
"""
import os

import cpcimg

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(HERE)

# χαρ, όνομα firmware, firmware number, ρόλος
PALETTE = [
    ('.', 'Black',           0, 'ΔΙΑΦΑΝΟ στα sprites, κενό διάστημα στα tiles'),
    ('K', 'Blue',            1, 'περίγραμμα και βαθιά σκιά (περνάει για μαύρο)'),
    ('i', 'White',          13, 'γκρι: μέταλλο, πέτρα, μάρμαρο σκιά'),
    ('I', 'Bright white',   26, 'ανταύγεια, αστέρια, κείμενο'),
    ('d', 'Red',             3, 'καφέ σκούρο: βαλίτσες, ρίζες, μυρμήγκια'),
    ('D', 'Orange',         15, 'καφέ/πορτοκαλί: πτερύγια, σκουριά, φλόγα'),
    ('r', 'Bright red',      6, 'κίνδυνος: εκρήξεις, σφραγίδα, boss'),
    ('y', 'Bright yellow',  24, 'πυρήνας φλόγας, χρυσό, μπαγκέτα'),
    ('S', 'Pastel yellow',  25, 'ΤΟ ΣΩΜΑ ΤΟΥ ΠΛΟΙΟΥ — πατάτα, κρεμ, μάρμαρο'),
    ('c', 'Bright cyan',    20, 'θόλος πιλοτηρίου, ενέργεια, πάγος'),
    ('b', 'Sky blue',       11, 'ψυχρό μέταλλο, ουρανός της Γης'),
    ('m', 'Bright magenta',  8, 'neon του Disco-Ray, λάμψη power-up'),
    ('p', 'Pink',           16, 'έντυπα Ε9, σάρκα, τουρίστες'),
    ('n', 'Green',           9, 'πράσινο σκούρο: εξωγήινοι σκιά, βλάστηση'),
    ('g', 'Bright green',   18, 'πράσινο φωτεινό: φτάρνισμα, εξωγήινοι'),
    ('o', 'Yellow',         12, 'λαδί: σκουπίδια, σπαγγέτι, βρόμικο μέταλλο'),
]

PEN = {p[0]: i for i, p in enumerate(PALETTE)}
FW = [p[2] for p in PALETTE]
NAMES = [p[1] for p in PALETTE]
CHARS = [p[0] for p in PALETTE]
USAGE = [p[3] for p in PALETTE]
RGB = [cpcimg.FW_RGB[f] for f in FW]

assert len(PALETTE) == 16 and len(set(CHARS)) == 16 and len(set(FW)) == 16
assert PEN['.'] == 0, 'το διάφανο πρέπει να είναι το pen 0'

PEN_MASK = PEN['.']
PEN_LINE = PEN['K']


# ------------------------------------------------------------ ζωγραφική

def blank(w, h, pen=None):
    return [[pen] * w for _ in range(h)]


def parse_art(text, transparent='-.'):
    """ASCII -> γραμμές pens. Το '-' ΚΑΙ το '.' είναι διάφανα.

    Δύο σύμβολα για το ίδιο πράγμα, επειδή λένε διαφορετικό πράγμα στο μάτι
    όταν διαβάζεις τον πίνακα: το '.' είναι «μέσα στο πλαίσιο αλλά κενό», το
    '-' είναι «έξω από τη φιγούρα». Στα δεδομένα είναι και τα δύο η μάσκα.
    """
    rows = []
    for line in text.strip('\n').splitlines():
        line = line.strip()
        if not line:
            continue
        rows.append([None if ch in transparent else PEN[ch] for ch in line])
    return rows


def art(text, w, h, what='sprite', transparent='-.'):
    """parse_art + έλεγχος μεγέθους. Ένα λάθος χαρακτήρα σε 24 στήλες δεν
    φαίνεται με το μάτι· εδώ σκάει αμέσως και λέει ποια γραμμή.

    Τα ΠΛΑΚΙΔΙΑ περνάνε `transparent=''`: εκεί το '.' δεν είναι μάσκα, είναι
    κανονικό μαύρο — το κενό διάστημα. Το ίδιο pen, άλλη σημασία, και το
    ξεκαθαρίζει η κλήση αντί για τον χαρακτήρα.
    """
    rows = parse_art(text, transparent)
    assert len(rows) == h, '%s: %d γραμμές, περίμενα %d' % (what, len(rows), h)
    for j, r in enumerate(rows):
        assert len(r) == w, '%s: γραμμή %d έχει %d στήλες, περίμενα %d' \
            % (what, j, len(r), w)
    return rows


def stamp(dst, src, x=0, y=0):
    """Ζωγραφίζει το `src` πάνω στο `dst`. Το διάφανο αφήνει ό,τι υπάρχει."""
    for j, row in enumerate(src):
        for i, pen in enumerate(row):
            if pen is None:
                continue
            yy, xx = y + j, x + i
            if 0 <= yy < len(dst) and 0 <= xx < len(dst[0]):
                dst[yy][xx] = pen
    return dst


def recolour(img, mapping):
    return [[mapping.get(p, p) for p in row] for row in img]


def tint(img, chars):
    """Αλλάζει χαρακτήρες παλέτας σε ολόκληρη εικόνα: {'S': 'g', ...}"""
    if not chars:
        return img
    return recolour(img, {PEN[a]: PEN[b] for a, b in chars.items()})


def mirror(img):
    return [list(reversed(row)) for row in img]


def flip(img):
    return [list(r) for r in reversed(img)]


def shift(img, dx=0, dy=0):
    h, w = len(img), len(img[0])
    out = blank(w, h, None)
    for y in range(h):
        for x in range(w):
            yy, xx = y + dy, x + dx
            if 0 <= yy < h and 0 <= xx < w:
                out[yy][xx] = img[y][x]
    return out


def pens_used(img):
    return sorted({p for row in img for p in row if p is not None})


def bbox(img):
    """Το πραγματικό πλαίσιο του σχεδίου — για να φανεί αν ένα sprite 24x24
    χρησιμοποιεί τελικά 14 στήλες και πληρώνεται για 24."""
    xs = [x for row in img for x, p in enumerate(row) if p is not None]
    ys = [y for y, row in enumerate(img) if any(p is not None for p in row)]
    if not xs:
        return (0, 0, 0, 0)
    return (min(xs), min(ys), max(xs) - min(xs) + 1, max(ys) - min(ys) + 1)


# ------------------------------------------------------- κωδικοποίηση

def encode_masked(img):
    """Εικόνα -> bytes Mode 0, πλεγμένα mask,data ανά ΖΕΥΓΑΡΙ pixels.

    Η μάσκα έχει όλα τα bits αναμμένα όπου το pixel είναι διάφανο: `AND mask`
    και μετά `OR data`. Το πλάτος σε bytes ΔΕΔΟΜΕΝΩΝ είναι w//2 — η γραμμή στη
    μνήμη είναι το ΔΙΠΛΟ.
    """
    out = bytearray()
    for row in img:
        assert len(row) % 2 == 0, 'το πλάτος πρέπει να είναι ζυγό'
        assert PEN_MASK not in row, \
            'pen 0 ως χρώμα σε sprite με μάσκα — το 0 σημαίνει ΔΙΑΦΑΝΟ'
        for i in range(0, len(row), 2):
            a, b = row[i], row[i + 1]
            out.append(cpcimg.mode0_byte(15 if a is None else 0,
                                         15 if b is None else 0))
            out.append(cpcimg.mode0_byte(0 if a is None else a,
                                         0 if b is None else b))
    return bytes(out)


def encode_opaque(img):
    out = bytearray()
    for row in img:
        assert len(row) % 2 == 0
        for i in range(0, len(row), 2):
            a, b = row[i], row[i + 1]
            out.append(cpcimg.mode0_byte(0 if a is None else a,
                                         0 if b is None else b))
    return bytes(out)


def decode_masked(data, w, h):
    img, k = [], 0
    for _ in range(h):
        row = []
        for _ in range(w // 2):
            ma, mb = cpcimg.mode0_pens(data[k])
            da, db = cpcimg.mode0_pens(data[k + 1])
            k += 2
            row.append(None if ma == 15 else da)
            row.append(None if mb == 15 else db)
        img.append(row)
    return img


def decode_opaque(data, w, h):
    img, k = [], 0
    for _ in range(h):
        row = []
        for _ in range(w // 2):
            row.extend(cpcimg.mode0_pens(data[k]))
            k += 1
        img.append(row)
    return img


# ----------------------------------------------------------- σετ sprites

class SpriteSet:
    """Καρέ ίδιου μεγέθους, με συνεχόμενα tags ώστε μια κίνηση να παίζει με
    «πρώτο καρέ + πλήθος», χωρίς πίνακα δεικτών."""

    def __init__(self, name, w, h, masked=True, note=''):
        self.name, self.w, self.h = name, w, h
        self.masked, self.note = masked, note
        self.frames, self.names, self.tags = [], [], []

    def add(self, img, name, tag=''):
        assert len(img) == self.h and all(len(r) == self.w for r in img), \
            '%s/%s: %dx%d, περίμενα %dx%d' % (self.name, name, len(img[0]),
                                              len(img), self.w, self.h)
        if self.tags and self.tags[-1] != tag and tag in self.tags:
            raise ValueError('%s: το tag %s δεν θα έμενε συνεχόμενο'
                             % (self.name, tag))
        self.frames.append([list(r) for r in img])
        self.names.append(name)
        self.tags.append(tag)
        return len(self.frames) - 1

    def tag_ranges(self):
        out, start = [], 0
        for i in range(1, len(self.tags) + 1):
            if i == len(self.tags) or self.tags[i] != self.tags[start]:
                out.append((self.tags[start], start, i - start))
                start = i
        return out

    def bytes_per_frame(self):
        return self.w * self.h if self.masked else self.w // 2 * self.h

    def total_bytes(self):
        return self.bytes_per_frame() * len(self.frames)

    def encode(self):
        enc = encode_masked if self.masked else encode_opaque
        return b''.join(enc(f) for f in self.frames)

    def verify(self):
        """Κάθε καρέ πίσω σε pens. Αν δεν γυρίσει ίδιο, ο κωδικοποιητής λέει
        ψέματα και όλα τα υπόλοιπα νούμερα είναι άχρηστα."""
        enc = encode_masked if self.masked else encode_opaque
        dec = decode_masked if self.masked else decode_opaque
        for name, f in zip(self.names, self.frames):
            assert dec(enc(f), self.w, self.h) == f, \
                '%s/%s: δεν γύρισε ίδιο' % (self.name, name)
        return True
