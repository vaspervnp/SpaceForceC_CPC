"""Οι 8 πίστες -> assets/data/levels.asm (bank 7) και assets/preview/levels/.

    python3 assets/src/levels.py

ΚΑΘΕ ΠΙΣΤΑ ΕΙΝΑΙ ΠΕΝΤΕ ΣΥΜΠΙΕΣΜΕΝΑ ΚΟΜΜΑΤΙΑ

    χάρτης   64x48 πλακίδια (3072 bytes)  -> bank 4, #4000 (bg_map)
    header   κόσμος, μουσική, boss, κείμενα, λίστα εχθρών  -> bank 4, #7C00
    boss     2 καρέ και 3 βλήματα (2496 bytes)  -> bank 5, #6000 (BOSS_GFX)
    πλακίδια 16 x 32 bytes                       -> bank 4, tiles_gfx
    εχθροί   κάλτσα + βαλίτσα του enemies.py     -> bank 5, enemies_gfx+MOBS_OFF

Όλα φορτώνονται μαζί από τη δισκέτα: χάρτες και headers στο bank 7
(LEVELS.BIN), όσα μοιράζονται οι πίστες στο bank 6, μετά τον ήχο (SND6.BIN).
Η αρχή μιας πίστας τα ξεσυμπιέζει από εκεί (src/level.asm), οπότε δεν
χρειάζεται φόρτωμα από δισκέτα ανά πίστα.

ΟΙ ΧΑΡΤΕΣ ΦΤΙΑΧΝΟΝΤΑΙ ΑΠΟ ΣΥΝΤΑΓΗ

Αντί για editor: ένα φόντο (αστέρια, νεφέλωμα, ...) που επαναλαμβάνεται
ανά 32x16 πλακίδια, ώστε να συμπιέζεται, και από πάνω «σφραγίδες» ανά θέμα
(σταθμοί, σωλήνες, σκουπίδια, σεληνιακό έδαφος, σήραγγες). Όλα με σταθερό
seed: η ίδια πίστα βγαίνει πάντα ίδια. Η προεπισκόπηση κάθε χάρτη, με τους
εχθρούς πάνω του, βγαίνει στο assets/preview/levels/.

ΣΥΜΠΙΕΣΗ (LZ, δική μας, ~40 bytes για την αποσυμπίεση στον Z80)

    #00          τέλος
    #01-#7F n    n bytes όπως είναι
    #80+k o16    αντιγραφή k+3 bytes (3-130) από απόσταση o πίσω
"""
import os
import random

import bosses
import cutscenes
import enemies as EN
import gfx
import mobs
import preview as preview_mod
import tilesets

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, '..', 'data')
PREVIEW = os.path.join(HERE, '..', 'preview', 'levels')

MAP_W, MAP_H = 64, 48
TILE_W, TILE_H = 8, 8           # pixels (4 bytes x 8 γραμμές)
WORLD_W_BYTES = MAP_W * 4       # 256
WORLD_H = MAP_H * 8             # 384
HEADER_MAX = 1024               # #7C00-#7FFF
LV_PARAMS = 128                 # θέση των παραμέτρων του boss στο header
LV_SPAWNS = 164                 # θέση της λίστας εχθρών
STAGE_SIZE = 4096               # src/level.asm
CUT_MAX = 0xC000 - 0x9000       # το σενάριο ανοίγει στο #9000 (CUT_BUF)
STATUS_LEN = 12                 # χαρακτήρες στη γραμμή μηνυμάτων του HUD
SHIP_START = (128 - 3, 180)     # (x σε bytes, y), όπως στο main.asm
SAFE_RADIUS = (40, 80)          # κανένας εχθρός τόσο κοντά στην αφετηρία

T = {}                          # το σετ της πίστας που φτιάχνεται (make_map)
# Η συμπεριφορά κάθε boss: hp ως 240 (ένα κελί στη μπάρα = 16), cool/fan =
# καρέ ανάμεσα στις βολές και βλήματα ανά βολή (1, 3 ή 5), το ίδιο κάτω από
# τη μισή αντοχή, dive = μάσκα του μετρητή βολών για την κάθοδο (1 = κάθε
# 2η, 3 = κάθε 4η, 255 = ποτέ), vy = γραμμές/καρέ (2 ή 4), xmask = κίνηση x
# όταν (καρέ & xmask) == 0, και τα δύο μηνύματα.
BOSS_PARAMS = {
    1: dict(hp=120, cool=75, fan=3, rcool=50, rfan=5, dive=3, vy=2, xmask=1,
            hello='TRASH DAY!', bye='RECYCLED!'),
    2: dict(hp=140, cool=60, fan=1, rcool=45, rfan=3, dive=1, vy=4, xmask=1,
            hello='REJECTED!', bye='APPROVED!'),
    3: dict(hp=170, cool=55, fan=5, rcool=40, rfan=5, dive=255, vy=2, xmask=1,
            hello='DISK ERROR!', bye='REFORMATTED'),
    4: dict(hp=200, cool=50, fan=3, rcool=35, rfan=5, dive=3, vy=4, xmask=0,
            hello='ATTENTION!', bye='AT EASE.'),
    5: dict(hp=150, cool=55, fan=3, rcool=40, rfan=5, dive=3, vy=2, xmask=1,
            hello='PAY THE TOLL', bye='NO CHANGE!'),
    6: dict(hp=180, cool=50, fan=3, rcool=35, rfan=5, dive=1, vy=4, xmask=1,
            hello='MY BABIES!', bye='ANTS FREE!'),
    7: dict(hp=210, cool=50, fan=5, rcool=40, rfan=5, dive=3, vy=2, xmask=0,
            hello='NO FLASH!', bye='IN RUINS.'),
    8: dict(hp=240, cool=40, fan=3, rcool=30, rfan=5, dive=3, vy=4, xmask=0,
            hello='SOUP TIME!', bye='IT BURNT!'),
}
ENEMY = {'grunt': 0, 'mine': 2, 'saucer': 4, 'roach': 6, 'sock': 8, 'suitcase': 10}
EN_SIZE_PX = {'grunt': (8, 16), 'mine': (8, 16), 'sock': (8, 16),
              'saucer': (12, 16), 'suitcase': (12, 20), 'roach': (12, 24)}
MOBS_SIZE = 2 * (4 * 16 * 2) + 2 * (6 * 20 * 2)   # κάλτσα και βαλίτσα, 2 καρέ η κάθε μία
# Το pen 0 της πίστας: η τιμή για τον gate array και το χρώμα της προεπισκόπησης.
SKY_HW = {'black': 0x54, 'purple': 0x58, 'blue': 0x55}
SKY_RGB = {'black': (0, 0, 0), 'purple': (128, 0, 128), 'blue': (0, 0, 255)}
MUS = {'space': 2, 'earth': 3}

# --------------------------------------------------------------------------
# Οι πίστες: όνομα, δύο γραμμές χιούμορ, κόσμος, φόντο, σφραγίδες, εχθροί.
# «mix»: (είδος, πλήθος). Τα grunts έρχονται σε σχηματισμούς των 3.

LEVELS = [
    dict(name='THE ASTEROID BELT OF LOST LUGGAGE',
         quip=('SOMEWHERE OUT HERE IS EVERY SOCK', 'YOU EVER LOST. AVOID THEM.'),
         world='space', tiles='space', mobs='space', sky='black', edge='grate',
         bg='stars', stamps=['dust'] * 8, boss=1,
         mix=[('sock', 10), ('suitcase', 8), ('grunt', 6), ('mine', 2), ('roach', 1)]),
    dict(name='THE NEBULA OF BUREAUCRACY',
         quip=('PLEASE TAKE A NUMBER.', 'YOUR NUMBER IS 8,000,442.'),
         world='space', tiles='bureau', mobs='space', sky='black', edge='grate',
         bg='nebula', stamps=['desk'] * 10, boss=2, line=6,
         mix=[('grunt', 12), ('saucer', 6), ('mine', 4), ('sock', 4), ('roach', 2)]),
    dict(name='TRASHCAN CITY OF THE GALAXY',
         quip=('IT SMELLS LIKE A CPC 464 THAT', 'WAS LEFT IN THE RAIN SINCE 1986.'),
         world='space', tiles='trash', mobs='space', sky='black', edge='grate',
         bg='stars', stamps=['trash'] * 10 + ['pipes'] * 4 + ['consoles'] * 6, boss=3,
         mix=[('grunt', 12), ('saucer', 6), ('suitcase', 6), ('mine', 5), ('roach', 3)]),
    dict(name='THE LUNAR ANT-HILL',
         quip=('THE ANTS ARE HERE. SO ARE THE', 'KATSAROPHOBIANS. AWKWARD.'),
         world='space', tiles='space', mobs='space', sky='black', edge='grate',
         bg='stars', stamps=['moon', 'tunnels'], boss=4,
         mix=[('grunt', 15), ('saucer', 6), ('mine', 6), ('roach', 4), ('sock', 4)]),
    dict(name='TRAFFIC ON ATTIKI ODOS',
         quip=('EVEN IN 2442 THE TOLL', 'IS STILL 2.80 EUROS.'),
         world='earth', tiles='attiki', mobs='attiki', sky='purple', edge='rail',
         bg='clouds', stamps=['road'] + ['building'] * 12, boss=5,
         mix=[('suitcase', 12), ('sock', 8), ('grunt', 9), ('saucer', 4), ('roach', 4)]),
    dict(name='THE UNDERGROUND TUNNELS OF MEGARA',
         quip=('MIND THE ROOTS. MIND THE ANTS.', 'MIND YOUR HEAD.'),
         world='earth', tiles='megara', mobs='megara', sky='black', edge='rock_b',
         bg='rock', stamps=['caves'] + ['roots'] * 20, boss=6,
         mix=[('suitcase', 14), ('sock', 8), ('mine', 8), ('grunt', 6), ('roach', 5)]),
    dict(name='THE ACROPOLIS PARKING LOT',
         quip=('NO PARKING BETWEEN THE COLUMNS.', 'THE TOURISTS ARE FILMING YOU.'),
         world='earth', tiles='acropolis', mobs='acropolis', sky='blue', edge='marble',
         bg='clouds', stamps=['parking'] + ['temple'] * 5 + ['tree'] * 10, boss=7,
         mix=[('sock', 16), ('suitcase', 8), ('grunt', 9), ('saucer', 4), ('roach', 6)]),
    dict(name='THE KITCHEN OF THE MOTHERSHIP',
         quip=('SOMETHING IS BOILING.', 'IT SMELLS LIKE ANT TEA.'),
         world='earth', tiles='kitchen', mobs='kitchen', sky='black', edge='k_grate',
         bg='floor', stamps=['burner'] * 8 + ['k_pipes'] * 6, boss=8,
         mix=[('sock', 12), ('suitcase', 10), ('grunt', 9), ('saucer', 8), ('roach', 8), ('mine', 4)]),
]

FONT_CHARS = set(" !%()*+,-./0123456789:?ABCDEFGHIJKLMNOPQRSTUVWXYZ")


# --------------------------------------------------------------------------
# Χάρτες

def background(kind, rnd):
    """Ένα κομμάτι 32x16 πλακιδίων, επαναλαμβανόμενο σε όλο τον χάρτη."""
    block = [[0] * 32 for _ in range(16)]
    for y in range(16):
        for x in range(32):
            r = rnd.random()
            if kind == 'stars':
                t = 'void' if r < 0.75 else rnd.choice(['star_s', 'star_s', 'star_m', 'stars_3'])
            elif kind == 'nebula':
                t = 'void' if r < 0.45 else rnd.choice(['nebula_a', 'nebula_a', 'nebula_b',
                                                        'nebula_c', 'star_s'])
            elif kind == 'clouds':
                t = 'void' if r < 0.93 else rnd.choice(['cloud_a', 'cloud_b'])
            elif kind == 'rock':
                t = 'rock' if r < 0.7 else rnd.choice(['rock_b', 'soil'])
            elif kind == 'floor':
                t = 'floor_a' if r < 0.9 else 'k_wall'
            block[y][x] = T[t]
    return [[block[y % 16][x % 32] for x in range(MAP_W)] for y in range(MAP_H)]


def rect(m, x, y, w, h, t, border=None):
    for yy in range(y, min(MAP_H, y + h)):
        for xx in range(x, min(MAP_W, x + w)):
            edge = yy in (y, y + h - 1) or xx in (x, x + w - 1)
            m[yy][xx] = T[border if border and edge else t]


def put(m, x, y, t):
    if 0 <= x < MAP_W and 0 <= y < MAP_H:
        m[y][x] = T[t]


def stamp(m, kind, rnd):
    if kind == 'dust':
        x, y = rnd.randrange(MAP_W - 8), rnd.randrange(MAP_H - 6)
        for _ in range(14):
            put(m, x + rnd.randrange(8), y + rnd.randrange(6), 'dust')
    elif kind == 'desk':            # γκισές: σταθμός με αιτήσεις, σφραγίδα, ουρά
        w, h = rnd.randrange(6, 11), rnd.randrange(4, 6)
        x, y = rnd.randrange(1, MAP_W - w - 1), rnd.randrange(3, MAP_H - h - 4)
        rect(m, x, y, w, h, 'plate', border='plate_rivet')
        for k in range(1, w - 1):
            put(m, x + k, y + 1, 'form' if k % 2 else 'plate')
        put(m, x + w // 2, y + h - 2, 'stamp')
        for k in range(rnd.randrange(3, 8)):
            put(m, x + w + k, y + h - 1, 'queue')
    elif kind == 'consoles':
        w, h = rnd.randrange(4, 9), rnd.randrange(2, 4)
        x, y = rnd.randrange(1, MAP_W - w - 1), rnd.randrange(2, MAP_H - h - 2)
        rect(m, x - 1, y - 1, w + 2, h + 2, 'plate', border='plate_rivet')
        for yy in range(h):
            for xx in range(w):
                put(m, x + xx, y + yy, rnd.choice(['console_a', 'console_b', 'console_c']))
    elif kind == 'trash':
        x, y = rnd.randrange(MAP_W - 6), rnd.randrange(MAP_H - 5)
        for _ in range(12):
            put(m, x + rnd.randrange(6), y + rnd.randrange(5), 'trash')
    elif kind == 'pipes':
        y = rnd.randrange(2, MAP_H - 4)
        rect(m, rnd.randrange(0, MAP_W // 2), y, rnd.randrange(10, 30), 1, 'pipe')
    elif kind == 'moon':
        for x in range(MAP_W):
            top = MAP_H - 8 + int(2 * ((x * 7) % 5 == 0)) - (x // 9) % 2
            for y in range(top, MAP_H):
                m[y][x] = T['moon_crater' if rnd.random() < 0.12 else 'moon']
    elif kind == 'tunnels':
        for _ in range(5):
            x, y = rnd.randrange(4, MAP_W - 10), MAP_H - 7
            for d in range(6):
                put(m, x + d, min(MAP_H - 1, y + d), 'tunnel')
                put(m, x + d + 1, min(MAP_H - 1, y + d), 'tunnel')
    # ---------------------------------------------------- Αττική Οδός
    elif kind == 'road':
        rect(m, 0, MAP_H - 5, MAP_W, 1, 'rail')
        rect(m, 0, MAP_H - 4, MAP_W, 4, 'road')
        rect(m, 0, MAP_H - 3, MAP_W, 1, 'road_l')
    elif kind == 'building':
        w, h = rnd.randrange(4, 8), rnd.randrange(10, 30)
        x, top = rnd.randrange(1, MAP_W - w - 1), MAP_H - 5 - h
        rect(m, x, top, w, h, 'wall')
        rect(m, x, top, w, 1, 'roof')
        for yy in range(top + 2, MAP_H - 6, 2):
            for xx in range(x + 1, x + w - 1):
                put(m, xx, yy, 'win_lit' if rnd.random() < 0.45 else 'win_off')
        if h > 16:
            put(m, x + w // 2, top + 2, rnd.choice(['neon_m', 'neon_c']))
            put(m, x + w // 2 - 1, top + 2, rnd.choice(['neon_m', 'neon_c']))
    # --------------------------------------------------------- Μέγαρα
    elif kind == 'caves':           # στοές: οριζόντιες και κάθετες, με κενό
        for _ in range(9):
            y, h = rnd.randrange(3, MAP_H - 8), rnd.randrange(4, 8)
            rect(m, rnd.randrange(1, 24), y, rnd.randrange(24, 40), h, 'cave')
        for _ in range(8):
            x, w = rnd.randrange(3, MAP_W - 8), rnd.randrange(4, 8)
            rect(m, x, rnd.randrange(1, 18), w, rnd.randrange(16, 28), 'cave')
    elif kind == 'roots':           # ρίζες από την οροφή μιας στοάς, κρύσταλλοι
        for _ in range(60):
            x, y = rnd.randrange(1, MAP_W - 1), rnd.randrange(2, MAP_H - 5)
            if m[y][x] == T['cave'] and m[y - 1][x] != T['cave']:
                put(m, x, y - 1, 'moss')
                for k in range(rnd.randrange(1, 4)):
                    if m[y + k][x] == T['cave']:
                        put(m, x, y + k, 'root_v')
                return
    # ------------------------------------------------------- Ακρόπολη
    elif kind == 'parking':
        rect(m, 0, MAP_H - 6, MAP_W, 6, 'ground')
        for x in range(2, MAP_W, 4):
            rect(m, x, MAP_H - 3, 1, 2, 'parking')
    elif kind == 'temple':
        w = rnd.randrange(9, 15) | 1
        x, base = rnd.randrange(1, MAP_W - w - 1), MAP_H - 7
        h = rnd.randrange(5, 9)
        rect(m, x - 1, base, w + 2, 1, 'marble')
        for xx in range(x, x + w, 2):
            for yy in range(base - h, base):
                put(m, xx, yy, 'column')
            put(m, xx, base - h, 'capital')
        rect(m, x - 1, base - h - 1, w + 2, 1, 'marble')
        for k in range((w + 2) // 2):
            put(m, x - 1 + k, base - h - 2 - min(k, 1), 'ped_l')
            put(m, x + w - k, base - h - 2 - min(k, 1), 'ped_r')
    elif kind == 'tree':
        put(m, rnd.randrange(1, MAP_W - 1), MAP_H - 7, 'tree')
    # -------------------------------------------------------- κουζίνα
    elif kind == 'burner':          # κατσαρόλα με Mirmikochai πάνω στη φωτιά
        w, h = rnd.randrange(8, 14), rnd.randrange(5, 9)
        x, y = rnd.randrange(1, MAP_W - w - 1), rnd.randrange(4, MAP_H - h - 3)
        rect(m, x, y, w, 1, 'soup')
        rect(m, x, y + 1, w, 1, 'pot_rim')
        rect(m, x, y + 2, w, h - 2, 'pot')
        rect(m, x, y + h, w, 1, 'flame')
        for _ in range(4):
            put(m, x + rnd.randrange(w), y - 1 - rnd.randrange(2), 'steam')
    elif kind == 'k_pipes':
        rect(m, rnd.randrange(0, MAP_W // 2), rnd.randrange(2, MAP_H - 3),
             rnd.randrange(12, 30), 1, 'k_pipe')


def make_map(lv, rnd):
    global T
    T = tilesets.index(lv['tiles'])
    m = background(lv['bg'], rnd)
    for s in lv['stamps']:
        stamp(m, s, rnd)
    # γύρω-γύρω: φαίνεται πού τελειώνει ο κόσμος
    for x in range(MAP_W):
        m[0][x] = m[MAP_H - 1][x] = T[lv['edge']]
    for y in range(MAP_H):
        m[y][0] = m[y][MAP_W - 1] = T[lv['edge']]
    return m


# --------------------------------------------------------------------------
# Εχθροί: θέση στον κόσμο (x σε bytes, y σε γραμμές), ταχύτητα, είδος

def free_spot(rnd):
    """Μια θέση μακριά από την αφετηρία του σκάφους."""
    while True:
        x = rnd.randrange(8, WORLD_W_BYTES - 16)
        y = rnd.randrange(16, WORLD_H - 40)
        if abs(x - SHIP_START[0]) > SAFE_RADIUS[0] or abs(y - SHIP_START[1]) > SAFE_RADIUS[1]:
            return x, y


def spawns(lv, rnd):
    """Οι εχθροί, σε τυχαία σειρά. Τα grunts μπαίνουν ως ομάδες (σχηματισμοί,
    lv['line'] στη σειρά), ώστε να βγαίνουν ο ένας δίπλα στον άλλο."""
    groups = []
    for kind, n in lv['mix']:
        size = lv.get('line', 3) if kind == 'grunt' else 1
        for k in range(0, n, size):
            groups.append((kind, min(size, n - k)))
    rnd.shuffle(groups)
    out = []
    for kind, size in groups:
        x, y = free_spot(rnd)
        if size > 1:
            x = min(x, WORLD_W_BYTES - 16 - (size - 1) * 12)
            vx = rnd.choice([1, -1])
            out += [(x + k * 12, y, vx, 0, ENEMY[kind]) for k in range(size)]
            continue
        if kind == 'sock':
            vx, vy = rnd.choice([1, -1]), rnd.choice([2, -2, 1])
        elif kind == 'suitcase':
            vx, vy = rnd.choice([1, -1]), 0
        elif kind == 'grunt':
            vx, vy = rnd.choice([1, -1]), 0
        else:
            vx, vy = 0, 0
        out.append((x, y, vx, vy, ENEMY[kind]))
    return out


def header(lv, sp):
    world = 0 if lv['world'] == 'space' else 8
    texts = []
    for t in (lv['name'],) + lv['quip']:
        assert set(t) <= FONT_CHARS, t
        assert len(t) <= 40, t
        texts += list(t.encode()) + [0]
    h = [world, MUS[lv['world']], len(sp), lv.get('boss', 0), SKY_HW[lv['sky']]] + texts
    assert len(h) <= LV_PARAMS, lv['name']
    h += [0] * (LV_PARAMS - len(h))
    b = BOSS_PARAMS.get(lv.get('boss'))
    if b:
        assert b['hp'] <= 240 and b['vy'] in (2, 4)
        h += [b['hp'], b['hp'] // 2, b['cool'], b['fan'], b['rcool'], b['rfan'],
              b['dive'], b['vy'], b['xmask']]
        for t in (b['hello'], b['bye']):
            assert len(t) <= STATUS_LEN and set(t) <= FONT_CHARS, t
            h += list(t.ljust(STATUS_LEN).encode()) + [0]
    h += [0] * (LV_SPAWNS - len(h))
    for x, y, vx, vy, kind in sp:
        h += [x, 0, y & 255, y >> 8, vx & 255, vy & 255, kind]
    assert len(h) <= HEADER_MAX
    return h


def mobs_offset():
    """Πού αρχίζουν στα enemies_gfx τα γραφικά της κάλτσας και της βαλίτσας."""
    off = 0
    for key, *_ in EN.ENEMIES:
        if key == 'sock':
            return off
        off += sum(len(gfx.encode_masked(img)) for img in EN.frames(key))
    raise ValueError


def boss_blob(n):
    _, frames, shots = bosses.BOSSES[n]
    blob = []
    for img in frames + shots:
        blob += list(gfx.encode_masked(img))
    return blob


# --------------------------------------------------------------------------
# LZ

def compress(data):
    out, lit = [], []
    i, n = 0, len(data)

    def flush():
        while lit:
            chunk = lit[:127]
            del lit[:127]
            out.append(len(chunk))
            out.extend(chunk)
    while i < n:
        best_len, best_off = 0, 0
        for j in range(max(0, i - 4096), i):
            k = 0
            while i + k < n and k < 130 and data[j + k] == data[i + k]:
                k += 1
            if k > best_len:
                best_len, best_off = k, i - j
        if best_len >= 3:
            flush()
            out += [0x80 + best_len - 3, best_off & 255, best_off >> 8]
            i += best_len
        else:
            lit.append(data[i])
            i += 1
    flush()
    out.append(0)
    assert decompress(out) == list(data)
    return out


def decompress(src):
    out, i = [], 0
    while src[i]:
        b = src[i]
        i += 1
        if b < 0x80:
            out += src[i:i + b]
            i += b
        else:
            off = src[i] | src[i + 1] << 8
            i += 2
            for _ in range(b - 0x80 + 3):
                out.append(out[-off])
    return out


# --------------------------------------------------------------------------

def preview(path, m, sp, title, lv):
    from PIL import Image, ImageDraw
    sky = SKY_RGB[lv['sky']]
    imgs = tilesets.images(lv['tiles'])
    img = Image.new('RGB', (MAP_W * TILE_W * 2, MAP_H * TILE_H))
    px = img.load()
    for ty in range(MAP_H):
        for tx in range(MAP_W):
            g = imgs[m[ty][tx]]
            for y in range(TILE_H):
                for x in range(TILE_W):
                    c = sky if g[y][x] == 0 else gfx.RGB[g[y][x]]
                    px[(tx * TILE_W + x) * 2, ty * TILE_H + y] = c
                    px[(tx * TILE_W + x) * 2 + 1, ty * TILE_H + y] = c
    d = ImageDraw.Draw(img)
    names = {v: k for k, v in ENEMY.items()}
    for x, y, vx, vy, kind in sp:
        w, h = EN_SIZE_PX[names[kind]]
        d.rectangle([x * 4, y, x * 4 + w * 2 - 1, y + h - 1], outline=(255, 80, 80))
    sx, sy = SHIP_START
    d.rectangle([sx * 4, sy, sx * 4 + 23, sy + 23], outline=(80, 255, 80))
    d.text((6, 4), title, fill=(255, 255, 255))
    img.save(path)


def db_lines(data):
    return ['        db ' + ','.join('#%02X' % b for b in data[i:i + 16])
            for i in range(0, len(data), 16)]


def main():
    os.makedirs(PREVIEW, exist_ok=True)
    lines = ['; levels.asm — ΠΑΡΑΓΕΤΑΙ ΑΥΤΟΜΑΤΑ από assets/src/levels.py.',
             '; Οι 8 πίστες (bank 7): ανά πίστα dw χάρτης, header, boss, πλακίδια,',
             '; εχθροί. Τα τρία τελευταία είναι στο bank 6 (levels2.asm): bit 15.',
             '', 'LEVEL_COUNT     equ %d' % len(LEVELS), 'LV_SPAWNS       equ %d' % LV_SPAWNS,
             'LV_PARAMS       equ %d' % LV_PARAMS,
             'MOBS_OFF        equ %d' % mobs_offset(),
             '', 'cut_table:',
             '        dw ' + ','.join('cut_%s+#8000' % n for n, _ in cutscenes.SCENES),
             '', 'level_table:']
    blobs = []
    total7 = 0
    for n, lv in enumerate(LEVELS, 1):
        rnd = random.Random(442 * n)
        m = make_map(lv, rnd)
        sp = spawns(lv, rnd)
        flat = [t for row in m for t in row]
        cm = compress(flat)
        ch = compress(header(lv, sp))
        assert len(cm) <= STAGE_SIZE and len(ch) <= STAGE_SIZE
        blobs.append((n, cm, ch))
        total7 += len(cm) + len(ch)
        bn = lv.get('boss')
        lines.append('        dw lv%d_map,lv%d_hdr,%s+#8000,tileset_%s+#8000,mobset_%s+#8000  ; %s'
                     % (n, n, 'boss%d_gfx' % bn if bn else 'no_boss',
                        lv['tiles'], lv['mobs'], lv['name']))
        preview(os.path.join(PREVIEW, 'level%d.png' % n), m, sp,
                'LEVEL %d  %s' % (n, lv['name']), lv)
        print('level %d: χάρτης %d -> %d, header -> %d, %d εχθροί'
              % (n, len(flat), len(cm), len(ch), len(sp)))
    for n, cm, ch in blobs:
        lines.append('lv%d_map:' % n)
        lines += db_lines(cm)
        lines.append('lv%d_hdr:' % n)
        lines += db_lines(ch)
    with open(os.path.join(DATA, 'levels.asm'), 'w') as f:
        f.write('\n'.join(lines) + '\n')
    # ---------------------------------------------------------- bank 6
    out = ['; levels2.asm — ΠΑΡΑΓΕΤΑΙ ΑΥΤΟΜΑΤΑ από assets/src/levels.py.',
           '; Όσα μοιράζονται οι πίστες (bank 6): bosses, πλακίδια, εχθροί.',
           '', 'no_boss:', '        db 0']
    total6 = 0
    for bn in sorted(bosses.BOSSES):
        cb = compress(boss_blob(bn))
        assert len(cb) <= STAGE_SIZE, bn
        total6 += len(cb)
        print('boss %d: %d -> %d  %s' % (bn, 2496, len(cb), bosses.BOSSES[bn][0]))
        out.append('boss%d_gfx:' % bn)
        out += db_lines(cb)
    for name in tilesets.SETS:
        blob = []
        for img in tilesets.images(name):
            blob += list(gfx.encode_opaque(img))
        assert len(blob) == 512
        cb = compress(blob)
        total6 += len(cb)
        print('πλακίδια %-10s 512 -> %d' % (name, len(cb)))
        out.append('tileset_%s:' % name)
        out += db_lines(cb)
    for name, (small, big) in mobs.SETS.items():
        blob = []
        for img in list(small) + list(big):
            blob += list(gfx.encode_masked(img))
        assert len(blob) == MOBS_SIZE, name
        cb = compress(blob)
        total6 += len(cb)
        print('εχθροί   %-10s %d -> %d' % (name, MOBS_SIZE, len(cb)))
        out.append('mobset_%s:' % name)
        out += db_lines(cb)
    for name, fn in cutscenes.SCENES:
        raw = fn()
        assert len(raw) <= CUT_MAX, name
        cb = compress(raw)
        assert len(cb) <= STAGE_SIZE, (name, len(cb))
        total6 += len(cb)
        print('σκηνή    %-10s %d -> %d' % (name, len(raw), len(cb)))
        out.append('cut_%s:' % name)
        out += db_lines(cb)
    with open(os.path.join(DATA, 'levels2.asm'), 'w') as f:
        f.write('\n'.join(out) + '\n')
    print('σύνολο: bank 7 %d bytes, bank 6 %d bytes' % (total7, total6))
    sheet, shots = [], []
    for nm, frames, sh in bosses.BOSSES.values():
        sheet += [(nm[:15], frames[0]), ('επίθεση', frames[1])]
        shots += [(nm[:6], x) for x in sh]
    preview_mod.contact_sheet(os.path.join(HERE, '..', 'preview', 'bosses.png'), sheet,
                              zoom=5, cols=4, title='bosses', grid=False)
    preview_mod.contact_sheet(os.path.join(HERE, '..', 'preview', 'boss_shots.png'), shots,
                              zoom=6, cols=6, title='τι πετάνε', grid=False)


if __name__ == '__main__':
    main()
