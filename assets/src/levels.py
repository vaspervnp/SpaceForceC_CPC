"""Οι 8 πίστες -> assets/data/levels.asm (bank 7) και assets/preview/levels/.

    python3 assets/src/levels.py

ΚΑΘΕ ΠΙΣΤΑ ΕΙΝΑΙ ΔΥΟ ΣΥΜΠΙΕΣΜΕΝΑ ΚΟΜΜΑΤΙΑ

    χάρτης   64x48 πλακίδια (3072 bytes)  -> bank 4, #4000 (bg_map)
    header   κόσμος, μουσική, boss, κείμενα, λίστα εχθρών  -> bank 4, #7C00
    boss     2 καρέ και 3 βλήματα (2496 bytes)  -> bank 5, #6000 (BOSS_GFX)

Όλες οι πίστες φορτώνονται μαζί από τη δισκέτα στο bank 7 (LEVELS.BIN) και
η αρχή μιας πίστας τις ξεσυμπιέζει από εκεί (src/level.asm). Με 8 πίστες
σε ~10 KB δεν χρειάζεται φόρτωμα από δισκέτα ανά πίστα· αν οι πίστες του
M12-M14 μεγαλώσουν πάνω από τα 16 KB του bank, μοιράζονται σε δύο αρχεία.

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

Οι πίστες 5-8 (Γη) χρησιμοποιούν προσωρινά τα πλακίδια του διαστήματος, ως
τα tilesets του M14.
"""
import os
import random

import bosses
import gfx
import preview as preview_mod
import tiles as TI

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
STAGE_SIZE = 2048               # src/level.asm
STATUS_LEN = 12                 # χαρακτήρες στη γραμμή μηνυμάτων του HUD
SHIP_START = (128 - 3, 180)     # (x σε bytes, y), όπως στο main.asm
SAFE_RADIUS = (40, 80)          # κανένας εχθρός τόσο κοντά στην αφετηρία

T = {key: i for i, (key, *_) in enumerate(TI.TILES)}
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
}
ENEMY = {'grunt': 0, 'mine': 2, 'sock': 4, 'saucer': 6, 'suitcase': 8, 'roach': 10}
EN_SIZE_PX = {'grunt': (8, 16), 'mine': (8, 16), 'sock': (8, 16),
              'saucer': (12, 16), 'suitcase': (12, 16), 'roach': (12, 16)}
MUS = {'space': 2, 'earth': 3}

# --------------------------------------------------------------------------
# Οι πίστες: όνομα, δύο γραμμές χιούμορ, κόσμος, φόντο, σφραγίδες, εχθροί.
# «mix»: (είδος, πλήθος). Τα grunts έρχονται σε σχηματισμούς των 3.

LEVELS = [
    dict(name='THE ASTEROID BELT OF LOST LUGGAGE',
         quip=('SOMEWHERE OUT HERE IS EVERY SOCK', 'YOU EVER LOST. AVOID THEM.'),
         world='space', bg='stars', stamps=['dust'] * 8, boss=1,
         mix=[('sock', 10), ('suitcase', 8), ('grunt', 6), ('mine', 2), ('roach', 1)]),
    dict(name='THE NEBULA OF BUREAUCRACY',
         quip=('PLEASE TAKE A NUMBER.', 'YOUR NUMBER IS 8,000,442.'),
         world='space', bg='nebula', stamps=['station'] * 10, boss=2, line=6,
         mix=[('grunt', 12), ('saucer', 6), ('mine', 4), ('sock', 4), ('roach', 2)]),
    dict(name='TRASHCAN CITY OF THE GALAXY',
         quip=('IT SMELLS LIKE A CPC 464 THAT', 'WAS LEFT IN THE RAIN SINCE 1986.'),
         world='space', bg='stars', stamps=['trash'] * 10 + ['pipes'] * 4 + ['station'] * 4, boss=3,
         mix=[('grunt', 12), ('saucer', 6), ('suitcase', 6), ('mine', 5), ('roach', 3)]),
    dict(name='THE LUNAR ANT-HILL',
         quip=('THE ANTS ARE HERE. SO ARE THE', 'KATSAROPHOBIANS. AWKWARD.'),
         world='space', bg='stars', stamps=['moon', 'tunnels'], boss=4,
         mix=[('grunt', 15), ('saucer', 6), ('mine', 6), ('roach', 4), ('sock', 4)]),
    dict(name='TRAFFIC ON ATTIKI ODOS',
         quip=('EVEN IN 2442 THE TOLL', 'IS STILL 2.80 EUROS.'),
         world='earth', bg='sky', stamps=['tower'] * 12,
         mix=[('grunt', 15), ('saucer', 8), ('suitcase', 6), ('roach', 4), ('mine', 4)]),
    dict(name='THE UNDERGROUND TUNNELS OF MEGARA',
         quip=('MIND THE ROOTS. MIND THE ANTS.', 'MIND YOUR HEAD.'),
         world='earth', bg='rock', stamps=['caves'],
         mix=[('grunt', 15), ('mine', 8), ('saucer', 6), ('roach', 5), ('sock', 4)]),
    dict(name='THE ACROPOLIS PARKING LOT',
         quip=('NO PARKING BETWEEN THE COLUMNS.', 'THE TOURISTS ARE FILMING YOU.'),
         world='earth', bg='sky', stamps=['tower'] * 6 + ['station'] * 6,
         mix=[('grunt', 18), ('saucer', 8), ('suitcase', 6), ('roach', 6), ('mine', 4)]),
    dict(name='THE KITCHEN OF THE MOTHERSHIP',
         quip=('SOMETHING IS BOILING.', 'IT SMELLS LIKE ANT TEA.'),
         world='earth', bg='plates', stamps=['pipes'] * 10 + ['trash'] * 6,
         mix=[('grunt', 18), ('saucer', 10), ('roach', 8), ('mine', 6), ('suitcase', 4)]),
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
            if kind in ('stars', 'sky'):
                t = 0 if r < 0.75 else rnd.choice(['star_s', 'star_s', 'star_m', 'stars_3'])
            elif kind == 'nebula':
                t = 0 if r < 0.45 else rnd.choice(['nebula_a', 'nebula_a', 'nebula_b',
                                                   'nebula_c', 'star_s'])
            elif kind == 'rock':
                t = 'moon' if r < 0.8 else 'moon_crater'
            elif kind == 'plates':
                t = 'plate' if r < 0.85 else 'plate_rivet'
            block[y][x] = T[t] if isinstance(t, str) else t
    return [[block[y % 16][x % 32] for x in range(MAP_W)] for y in range(MAP_H)]


def rect(m, x, y, w, h, t, border=None):
    for yy in range(y, min(MAP_H, y + h)):
        for xx in range(x, min(MAP_W, x + w)):
            edge = yy in (y, y + h - 1) or xx in (x, x + w - 1)
            m[yy][xx] = T[border if border and edge else t]


def stamp(m, kind, rnd):
    if kind == 'dust':
        x, y = rnd.randrange(MAP_W - 8), rnd.randrange(MAP_H - 6)
        for _ in range(14):
            m[y + rnd.randrange(6)][x + rnd.randrange(8)] = T['dust']
    elif kind == 'station':
        w, h = rnd.randrange(5, 10), rnd.randrange(3, 6)
        x, y = rnd.randrange(1, MAP_W - w - 1), rnd.randrange(2, MAP_H - h - 8)
        rect(m, x, y, w, h, 'plate', border='plate_rivet')
        if h > 3:
            rect(m, x + 1, y + h // 2, w - 2, 1, 'grate')
    elif kind == 'trash':
        x, y = rnd.randrange(MAP_W - 6), rnd.randrange(MAP_H - 5)
        for _ in range(12):
            m[y + rnd.randrange(5)][x + rnd.randrange(6)] = T['trash']
    elif kind == 'pipes':
        y = rnd.randrange(2, MAP_H - 4)
        x0 = rnd.randrange(0, MAP_W // 2)
        rect(m, x0, y, rnd.randrange(10, 30), 1, 'pipe')
    elif kind == 'tower':           # Γη: προσωρινά από ελάσματα, ως το M14
        w, h = rnd.randrange(3, 6), rnd.randrange(8, 20)
        x = rnd.randrange(1, MAP_W - w - 1)
        rect(m, x, MAP_H - h, w, h, 'grate', border='plate_rivet')
    elif kind == 'moon':
        for x in range(MAP_W):
            top = MAP_H - 8 + int(2 * ((x * 7) % 5 == 0)) - (x // 9) % 2
            for y in range(top, MAP_H):
                m[y][x] = T['moon_crater' if rnd.random() < 0.12 else 'moon']
    elif kind == 'tunnels':
        for _ in range(5):
            x, y = rnd.randrange(4, MAP_W - 10), MAP_H - 7
            for d in range(6):
                m[min(MAP_H - 1, y + d)][x + d] = T['tunnel']
                m[min(MAP_H - 1, y + d)][x + d + 1] = T['tunnel']
    elif kind == 'caves':
        for y in range(MAP_H):
            for x in range(MAP_W):
                if 6 < y < MAP_H - 6 and abs((x * 3 + y * 5) % 23 - 11) < 7:
                    m[y][x] = T['tunnel']


def make_map(lv, rnd):
    m = background(lv['bg'], rnd)
    for s in lv['stamps']:
        stamp(m, s, rnd)
    # σχάρα γύρω-γύρω: φαίνεται πού τελειώνει ο κόσμος
    for x in range(MAP_W):
        m[0][x] = m[MAP_H - 1][x] = T['grate']
    for y in range(MAP_H):
        m[y][0] = m[y][MAP_W - 1] = T['grate']
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
    h = [world, MUS[lv['world']], len(sp), lv.get('boss', 0)] + texts
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

def preview(path, m, sp, title):
    from PIL import Image, ImageDraw
    img = Image.new('RGB', (MAP_W * TILE_W * 2, MAP_H * TILE_H))
    px = img.load()
    cache = {}
    for ty in range(MAP_H):
        for tx in range(MAP_W):
            t = m[ty][tx]
            if t not in cache:
                cache[t] = TI.tile(TI.TILES[t][0])
            g = cache[t]
            for y in range(TILE_H):
                for x in range(TILE_W):
                    c = gfx.RGB[g[y][x]]
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


def main():
    os.makedirs(PREVIEW, exist_ok=True)
    lines = ['; levels.asm — ΠΑΡΑΓΕΤΑΙ ΑΥΤΟΜΑΤΑ από assets/src/levels.py.',
             '; Οι 8 πίστες συμπιεσμένες (bank 7): ανά πίστα dw χάρτης, header, boss.',
             '', 'LEVEL_COUNT     equ %d' % len(LEVELS), 'LV_SPAWNS       equ %d' % LV_SPAWNS,
             'LV_PARAMS       equ %d' % LV_PARAMS,
             '', 'level_table:']
    blobs = []
    total = 0
    for n, lv in enumerate(LEVELS, 1):
        rnd = random.Random(442 * n)
        m = make_map(lv, rnd)
        sp = spawns(lv, rnd)
        flat = [t for row in m for t in row]
        cm = compress(flat)
        ch = compress(header(lv, sp))
        blobs.append((n, cm, ch))
        total += len(cm) + len(ch)
        assert len(cm) <= STAGE_SIZE and len(ch) <= STAGE_SIZE
        bn = lv.get('boss')
        lines.append('        dw lv%d_map,lv%d_hdr,%s     ; %s'
                     % (n, n, 'boss%d_gfx' % bn if bn else 'no_boss', lv['name']))
        preview(os.path.join(PREVIEW, 'level%d.png' % n), m, sp, 'LEVEL %d  %s' % (n, lv['name']))
        print('level %d: χάρτης %d -> %d, header -> %d, %d εχθροί'
              % (n, len(flat), len(cm), len(ch), len(sp)))
    for n, cm, ch in blobs:
        lines.append('lv%d_map:' % n)
        lines += ['        db ' + ','.join('#%02X' % b for b in cm[i:i + 16])
                  for i in range(0, len(cm), 16)]
        lines.append('lv%d_hdr:' % n)
        lines += ['        db ' + ','.join('#%02X' % b for b in ch[i:i + 16])
                  for i in range(0, len(ch), 16)]
    lines += ['no_boss:', '        db 0']
    for bn in sorted(bosses.BOSSES):
        cb = compress(boss_blob(bn))
        assert len(cb) <= STAGE_SIZE, bn
        total += len(cb)
        print('boss %d: %d -> %d  %s' % (bn, 2496, len(cb), bosses.BOSSES[bn][0]))
        lines.append('boss%d_gfx:' % bn)
        lines += ['        db ' + ','.join('#%02X' % b for b in cb[i:i + 16])
                  for i in range(0, len(cb), 16)]
    with open(os.path.join(DATA, 'levels.asm'), 'w') as f:
        f.write('\n'.join(lines) + '\n')
    print('σύνολο %d bytes' % total)
    sheet = []
    shots = []
    for nm, frames, sh in bosses.BOSSES.values():
        sheet += [(nm[:15], frames[0]), ('επίθεση', frames[1])]
        shots += [(nm[:6], x) for x in sh]
    preview_mod.contact_sheet(os.path.join(HERE, '..', 'preview', 'bosses.png'), sheet,
                              zoom=5, cols=4, title='bosses', grid=False)
    preview_mod.contact_sheet(os.path.join(HERE, '..', 'preview', 'boss_shots.png'), shots,
                              zoom=6, cols=6, title='τι πετάνε', grid=False)


if __name__ == '__main__':
    main()
