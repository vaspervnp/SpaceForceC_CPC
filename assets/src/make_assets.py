"""Όλη η τέχνη -> δεδομένα Mode 0, προεπισκοπήσεις και assets.json.

    python3 assets/src/make_assets.py

ΕΝΑ ΑΡΧΕΙΟ ΑΝΑ ΟΜΑΔΑ, ΓΙΑΤΙ ΟΙ ΟΜΑΔΕΣ ΦΟΡΤΩΝΟΝΤΑΙ ΜΑΖΙ

Το σκάφος, η γραμματοσειρά και το HUD ζουν σε όλη τη διάρκεια του παιχνιδιού.
Τα πλακίδια και οι εχθροί αλλάζουν ανά πίστα. Χωρισμένα έτσι, μια αλλαγή
πίστας φορτώνει δύο αρχεία αντί για δεκαπέντε.

ΟΣΑ ΕΧΟΥΝ ΙΔΙΟ ΜΕΓΕΘΟΣ ΔΕΝ ΧΡΕΙΑΖΟΝΤΑΙ ΠΙΝΑΚΑ

    σταθερό μέγεθος   offset = index * SZ      ship, shots, tiles, font, ...
    μεικτό            πίνακας w,h,offset       enemies

Ο πίνακας μπαίνει ΜΟΝΟ εκεί που χρειάζεται. Ένας καθολικός πίνακας δεικτών
«για παν ενδεχόμενο» θα ήταν 4 bytes ανά καρέ για 300 καρέ — 1,2 KB για να
αποφύγεις έναν πολλαπλασιασμό.

ΚΑΘΕ BLOB ΕΠΑΛΗΘΕΥΕΤΑΙ

Κάθε καρέ ξεκωδικοποιείται πίσω σε pens και συγκρίνεται με αυτό που
ζωγραφίστηκε. Αν ο κωδικοποιητής λέει ψέματα, όλα τα υπόλοιπα νούμερα είναι
άχρηστα — και η σειρά των bits του Mode 0 είναι ακριβώς το είδος του
πράγματος που γράφεται λάθος σιωπηλά.
"""
import json
import os
import sys

import boss1
import cpcimg
import enemies as EN
import font as FO
import fx
import gfx
import pickups as PU
import preview
import shots as SH
import ship as SP
import tiles as TI

OUT = gfx.OUT
DATA = os.path.join(OUT, 'data')
PREVIEW = os.path.join(OUT, 'preview')

# ΤΑ ΝΟΥΜΕΡΑ ΕΙΝΑΙ ΤΟΥ CPC, ΟΧΙ ΤΟΥ Z80 ΣΤΑ ΧΑΡΤΙΑ
#
# Ο gate array κρατάει τον Z80 ώστε κάθε εντολή να στρογγυλοποιείται σε
# ακέραια µs. Το LDI δεν είναι 16 T αλλά 5 µs. Ένα masked blit θέλει ανά byte
# δεδομένων: φόρτωμα μάσκας, AND με την οθόνη, OR με τα δεδομένα, γράψιμο —
# ~11 µs ξετυλιγμένο.
US_MASKED_PER_BYTE = 11.0       # AND mask / OR data, ξετυλιγμένο
US_OPAQUE_PER_BYTE = 5.0        # LDI
FRAME_MS = 40.0                 # 25 FPS


def blit_ms(w, h, masked=True):
    data_bytes = w // 2 * h
    rate = US_MASKED_PER_BYTE if masked else US_OPAQUE_PER_BYTE
    return data_bytes * rate / 1000.0


class Group:
    """Ένα αρχείο δεδομένων: καρέ, ετικέτες και (αν χρειάζεται) πίνακας."""

    def __init__(self, stem, title, note):
        self.stem, self.title, self.note = stem, title, note
        self.items = []          # (label, comment, img, w, h, masked)

    def add(self, label, comment, img, masked=True):
        self.items.append((label, comment, img, len(img[0]), len(img), masked))

    def fixed(self):
        sizes = {(w, h, m) for _, _, _, w, h, m in self.items}
        return sizes.pop() if len(sizes) == 1 else None

    def encode(self):
        out, offsets = bytearray(), []
        for _, _, img, w, h, masked in self.items:
            offsets.append(len(out))
            blob = gfx.encode_masked(img) if masked else gfx.encode_opaque(img)
            dec = gfx.decode_masked if masked else gfx.decode_opaque
            assert dec(blob, w, h) == img, 'δεν γύρισε ίδιο'
            out += blob
        return bytes(out), offsets


def write_group(g):
    blob, offsets = g.encode()
    fixed = g.fixed()
    lines = ['; %s.asm — %s, Amstrad CPC Mode 0' % (g.stem, g.title),
             '; ΠΑΡΑΓΕΤΑΙ ΑΥΤΟΜΑΤΑ από assets/src/make_assets.py.',
             ';', '; %d καρέ, %d bytes.' % (len(g.items), len(blob))]
    for ln in g.note.strip().splitlines():
        lines.append('; ' + ln if ln else ';')
    lines.append(';')
    if fixed:
        w, h, masked = fixed
        lines += [
            '; Όλα ίδιο μέγεθος: offset = index * %s_SZ, χωρίς πίνακα.'
            % g.stem.upper(), '',
            '%-14s equ %-5d ; bytes %s ανά γραμμή'
            % (g.stem.upper() + '_W', w // 2,
               'ΔΕΔΟΜΕΝΩΝ (στη μνήμη το ΔΙΠΛΟ)' if masked else 'ανά γραμμή'),
            '%-14s equ %-5d ; γραμμές' % (g.stem.upper() + '_H', h),
            '%-14s equ %-5d ; bytes ανά καρέ'
            % (g.stem.upper() + '_SZ', len(blob) // len(g.items)),
        ]
    else:
        lines += ['; Μεικτά μεγέθη — ο πίνακας δίνει ανά καρέ:',
                  ';     db πλάτος_σε_bytes_ΔΕΔΟΜΕΝΩΝ, ύψος_σε_γραμμές',
                  ';     dw μετατόπιση από το %s_gfx' % g.stem, '']
    lines.append('')
    for k, (label, comment, _, _, _, _) in enumerate(g.items):
        lines.append('%-22s equ %-4d ; %s' % (label, k, comment))
    if not fixed:
        lines += ['', '%s_table:' % g.stem]
        for (label, _, _, w, h, _), off in zip(g.items, offsets):
            lines.append('  db %d,%d' % (w // 2, h))
            lines.append('  dw %d        ; %s' % (off, label))
    lines += ['', '%s_gfx:' % g.stem]
    pos = 0
    for (label, _, _, w, h, masked), off in zip(g.items, offsets):
        n = (w * h) if masked else (w // 2 * h)
        lines.append('  ; %s' % label)
        chunk = blob[pos:pos + n]
        for rr in range(0, len(chunk), 16):
            lines.append('  db ' + ','.join('#%02X' % b
                                            for b in chunk[rr:rr + 16]))
        pos += n
    lines.append('')
    with open(os.path.join(DATA, g.stem + '.bin'), 'wb') as f:
        f.write(blob)
    with open(os.path.join(DATA, g.stem + '.asm'), 'w') as f:
        f.write('\n'.join(lines))
    return len(blob)


def write_palette():
    lines = ['; palette.asm — τα 16 INK του Space Force C',
             '; ΠΑΡΑΓΕΤΑΙ ΑΥΤΟΜΑΤΑ από assets/src/make_assets.py.',
             ';',
             '; Μία παλέτα για τους δύο κόσμους: το σκάφος, τα βλήματα, οι',
             '; εκρήξεις, τα μυρμήγκια και το HUD εμφανίζονται και στις οκτώ',
             '; πίστες. Αν τα pens άλλαζαν νόημα στη μέση, καθένα από αυτά θα',
             '; χρειαζόταν δεύτερη έκδοση.',
             ';',
             '; Το pen 0 είναι ΔΙΑΦΑΝΟ στα sprites και μαύρο στα πλακίδια.',
             '', 'palette:']
    for k, (ch, name, fwn, use) in enumerate(gfx.PALETTE):
        lines.append('  db %-3d ; pen %-2d %-3s %-15s %s'
                     % (fwn, k, "'" + ch + "'", name, use))
    lines += ['', '; hardware values για OUT (#7F00), αν γράψεις δικό σου',
              '; set-ink αντί για το firmware #BC32:', 'palette_hw:']
    hw = [0x54, 0x44, 0x55, 0x5C, 0x58, 0x5D, 0x4C, 0x45, 0x4D, 0x56, 0x46,
          0x57, 0x5E, 0x40, 0x5F, 0x4E, 0x47, 0x4F, 0x52, 0x42, 0x53, 0x5A,
          0x59, 0x5B, 0x4A, 0x43, 0x4B]
    lines.append('  db ' + ','.join('#%02X' % hw[f] for f in gfx.FW))
    lines.append('')
    with open(os.path.join(DATA, 'palette.asm'), 'w') as f:
        f.write('\n'.join(lines))
    with open(os.path.join(OUT, 'palette.gpl'), 'w') as f:
        f.write('GIMP Palette\nName: Space Force C (CPC Mode 0)\nColumns: 16\n#\n')
        for k, ((ch, name, fwn, use), rgb) in enumerate(zip(gfx.PALETTE,
                                                            gfx.RGB)):
            f.write('%3d %3d %3d\tpen %d %s — %s\n'
                    % (rgb[0], rgb[1], rgb[2], k, name, use))


def sheet_mixed(path, items, title, zoom=5, cols=12):
    """Contact sheet για καρέ ΔΙΑΦΟΡΕΤΙΚΟΥ μεγέθους: το κελί παίρνει το
    μεγαλύτερο και τα μικρά στοιχίζονται στη βάση, όπως στον χάρτη."""
    from PIL import Image, ImageDraw
    mw = max(len(im[0]) for _, im in items)
    mh = max(len(im) for _, im in items)
    cw, ch = mw * 2 * zoom + 10, mh * zoom + 16
    rows = (len(items) + cols - 1) // cols
    im = Image.new('RGB', (cols * cw + 12, 26 + rows * ch), preview.BG)
    d = ImageDraw.Draw(im)
    d.text((8, 8), title, fill=(255, 206, 92))
    for k, (lab, img) in enumerate(items):
        ox = 6 + (k % cols) * cw
        oy = 24 + (k // cols) * ch
        w, h = len(img[0]), len(img)
        preview.draw(d, img, ox + (mw - w) * zoom, oy + (mh - h) * zoom,
                     zoom, True)
        d.text((ox, oy + mh * zoom + 2), lab[:16], fill=(190, 192, 205))
    im.save(path)
    return path


def build():
    os.makedirs(DATA, exist_ok=True)
    os.makedirs(PREVIEW, exist_ok=True)
    groups, doc = [], {}

    # ------------------------------------------------------------ σκάφος
    g = Group('ship', 'The Flying Patates',
              'Κάτοψη, 8 κατευθύνσεις x 2 κόσμοι. Τρεις όψεις ζωγραφίζονται\n'
              '(N, NE, E) και πέντε βγαίνουν με καθρέφτισμα στο build.\n'
              'Σειρά: όλος ο κόσμος «space» και μετά όλος ο «earth», ώστε η\n'
              'αλλαγή κόσμου να είναι +8 στον δείκτη.')
    for world in ('space', 'earth'):
        for d, img in SP.all_frames(world):
            g.add('ship_%s_%s' % (world, d), 'σκάφος %s, %s' % (world, d), img)
    groups.append(g)

    # --------------------------------------------------------------- fx
    g = Group('fx', 'φλόγες, καπνός, εκρήξεις',
              'Η φλόγα μπαίνει ΠΡΙΝ από το σκάφος, στη θέση FLAME_AT της\n'
              'κατεύθυνσης. Ο καπνός είναι μόνο για τη Γη. Η μεγάλη έκρηξη\n'
              'έχει ΤΟ ΙΔΙΟ πλαίσιο με το σκάφος ώστε να μπαίνει στη θέση του.')
    for d in fx.DIRS:
        for p in range(3):
            g.add('fx_flame_%s%d' % (d, p), 'φλόγα %s φάση %d' % (d, p),
                  fx.flame(d, p))
    for p in range(3):
        g.add('fx_smoke%d' % p, 'καπνός %d (μόνο Γη)' % p, fx.smoke(p))
    for p in range(3):
        g.add('fx_booms%d' % p, 'έκρηξη μικρή %d' % p, fx.boom_small(p))
    for p in range(5):
        g.add('fx_boomb%d' % p, 'έκρηξη μεγάλη %d' % p, fx.boom_big(p))
    groups.append(g)

    # ---------------------------------------------------------- βλήματα
    g = Group('shots', 'βλήματα παίκτη και εχθρών',
              'Τα κατευθυνόμενα έχουν 8 όψεις (3 ζωγραφισμένες), τα\n'
              'απλωτά 3 καρέ κίνησης. Όλα 8x8 — ένα μέγεθος, ένα blit.')
    for kind in ('disco', 'baguette', 'spaghetti', 'torpedo'):
        for d in SH.DIRS:
            for p in range(SH.phases(kind)):
                g.add('sh_%s_%s%d' % (kind, d, p),
                      '%s %s φάση %d' % (kind, d, p), SH.shot(kind, d, p))
    for kind in ('sneeze', 'e9'):
        for p in range(SH.phases(kind)):
            g.add('sh_%s%d' % (kind, p), '%s φάση %d' % (kind, p),
                  SH.shot(kind, phase=p))
    groups.append(g)

    # --------------------------------------------------------- power-ups
    g = Group('pickups', 'power-ups και μυρμήγκια',
              'Κάθε power-up έχει δύο καρέ: κανονικό και «λάμψης». Το δεύτερο\n'
              'δεν είναι δεύτερο σχέδιο — είναι το ίδιο με λευκό περίγραμμα,\n'
              'παραγόμενο στο build.')
    for key, name, _, what in PU.PICKUPS:
        g.add('pu_%s' % key, '%s — %s' % (name, what), PU.pickup(key))
        g.add('pu_%s_hi' % key, '%s, λάμψη' % name, PU.pickup(key, True))
    for p in range(2):
        g.add('ant%d' % p, 'κλεμμένο μυρμήγκι, καρέ %d' % p, PU.ant(p))
    groups.append(g)

    # ----------------------------------------------------------- εχθροί
    g = Group('enemies', 'Katsarophobians και σκουπίδια',
              'ΜΕΙΚΤΑ ΜΕΓΕΘΗ — εδώ υπάρχει πίνακας. Δύο καρέ ο καθένας, καμία\n'
              'κατεύθυνση: σε 16x16 μονάδες η κατεύθυνση ενός εχθρού δεν\n'
              'διαβάζεται, ενώ η κίνηση διαβάζεται αμέσως.')
    for key, name, w, h, _, note in EN.ENEMIES:
        for k, img in enumerate(EN.frames(key)):
            g.add('en_%s%d' % (key, k), '%s — %s' % (name, note), img)
    groups.append(g)

    # --------------------------------------------------------- πλακίδια
    g = Group('tiles', 'πλακίδια φόντου, κόσμος «διάστημα»',
              'ΑΔΙΑΦΑΝΑ: 32 bytes, μπαίνουν με LDI. Το φόντο ξαναζωγραφίζεται\n'
              'συνέχεια στο scrolling και είναι το πιο ακριβό πράγμα μετά τα\n'
              'sprites. Οι κουκκίδες μένουν μακριά από τις ακμές ώστε τα\n'
              'πλακίδια να ενώνονται χωρίς να φαίνεται το πλέγμα.')
    for key, name, _, lv in TI.TILES:
        g.add('ti_%s' % key, '%s (levels %s)' % (name, lv), TI.tile(key),
              masked=False)
    groups.append(g)

    # ------------------------------------------------------------- boss
    # (μόνο για τα νούμερα και την προεπισκόπηση: στο παιχνίδι οι bosses
    # μπαίνουν συμπιεσμένοι από το levels.py)
    g = Group('boss1', 'Lord Garbage-Can (Level 1)', boss1.NOTE)
    for k, (nm, _) in enumerate(boss1.FRAMES):
        g.add('boss1_%s' % nm, 'καπάκι %s' % nm, boss1.frame(k))
    groups.append(g)

    # ----------------------------------------------------- γραμματοσειρά
    g = Group('font', 'γραμματοσειρά 4x8',
              '4 px x 8 γραμμές = 8x8 μονάδες οθόνης: 40 χαρακτήρες στη\n'
              'γραμμή. Το γράμμα πιάνει 3 στήλες, η τέταρτη είναι το κενό.\n'
              'ΑΔΙΑΦΑΝΗ: το κείμενο γράφεται πάντα πάνω σε μαύρο, οπότε δεν\n'
              'κουβαλάει μάσκα (16 bytes ο χαρακτήρας, όχι 32).')
    for ch, img in FO.sheet():
        solid = [[0 if v is None else v for v in row] for row in img]
        g.add('ch_%d' % ord(ch), "'%s'" % (ch if ch != ' ' else 'κενό'), solid,
              masked=False)
    groups.append(g)

    # ------------------------------------------------------------ γράψε
    write_palette()
    total = 0
    print('%-9s %4s %7s  %s' % ('ομάδα', 'καρέ', 'bytes', 'μέγεθος'))
    for g in groups:
        n = write_group(g)
        total += n
        fixed = g.fixed()
        size = ('%dx%d %s' % (fixed[0], fixed[1],
                              'με μάσκα' if fixed[2] else 'αδιαφανή')) \
            if fixed else 'μεικτά (πίνακας)'
        print('%-9s %4d %7d  %s' % (g.stem, len(g.items), n, size))
        doc[g.stem] = {
            'title': g.title, 'frames': len(g.items), 'bytes': n,
            'fixed_size': None if not fixed else
            {'w': fixed[0], 'h': fixed[1], 'masked': fixed[2]},
            'items': [{'label': lab, 'what': c, 'w': w, 'h': h,
                       'masked': m, 'screen_units': [w * 2, h]}
                      for lab, c, _, w, h, m in g.items],
        }
    print('%-9s %4s %7d  (%.1f KB)' % ('ΣΥΝΟΛΟ', '', total, total / 1024.0))

    # --------------------------------------------------- προεπισκοπήσεις
    preview.contact_sheet(os.path.join(PREVIEW, 'ship.png'),
                          [(d, im) for d, im in SP.all_frames('space')] +
                          [(d + ' γη', im) for d, im in SP.all_frames('earth')],
                          zoom=7, cols=8,
                          title='The Flying Patates — 12x24 px = 24x24 μονάδες')
    preview.contact_sheet(
        os.path.join(PREVIEW, 'fx.png'),
        [(d, fx.flame(d, 2)) for d in fx.DIRS] +
        [('καπνός%d' % p, fx.smoke(p)) for p in range(3)] +
        [('μικρή%d' % p, fx.boom_small(p)) for p in range(3)],
        zoom=7, cols=8, title='φλόγες, καπνός, μικρή έκρηξη')
    preview.contact_sheet(os.path.join(PREVIEW, 'explosion.png'),
                          [('%d' % p, fx.boom_big(p)) for p in range(5)],
                          zoom=7, cols=5,
                          title='έκρηξη σκάφους — ίδιο πλαίσιο με το σκάφος')
    preview.contact_sheet(
        os.path.join(PREVIEW, 'shots.png'),
        [('%s %s' % (k[:5], d), SH.shot(k, d, 0))
         for k in ('disco', 'baguette', 'spaghetti', 'torpedo')
         for d in SH.DIRS] +
        [('sneeze%d' % p, SH.shot('sneeze', phase=p)) for p in range(3)] +
        [('e9 %d' % p, SH.shot('e9', phase=p)) for p in range(3)],
        zoom=7, cols=8, title='βλήματα — όλα 8x8')
    preview.contact_sheet(
        os.path.join(PREVIEW, 'pickups.png'),
        [(k, PU.pickup(k)) for k, _, _, _ in PU.PICKUPS],
        zoom=7, cols=9, title='power-ups — 8x16 px = 16x16 μονάδες')
    sheet_mixed(os.path.join(PREVIEW, 'enemies.png'),
                [('%s%d' % (k, j), im)
                 for k, _, _, _, _, _ in EN.ENEMIES
                 for j, im in enumerate(EN.frames(k))],
                'εχθροί — μεικτά μεγέθη, στοιχισμένοι στη βάση', zoom=6,
                cols=12)
    preview.contact_sheet(
        os.path.join(PREVIEW, 'tiles.png'),
        [(k, [[TI.tile(k)[yy % 8][xx % 8] for xx in range(24)]
              for yy in range(24)]) for k, _, _, _ in TI.TILES],
        zoom=4, cols=8, grid=False,
        title='πλακίδια 8x8, κάθε ένα 3x3 φορές — εκεί κρίνονται οι αρμοί')
    preview.contact_sheet(os.path.join(PREVIEW, 'boss1.png'),
                          [(nm, boss1.frame(k))
                           for k, (nm, _) in enumerate(boss1.FRAMES)],
                          zoom=6, cols=2, title='Lord Garbage-Can — 24x48 px')
    preview.contact_sheet(os.path.join(PREVIEW, 'font.png'), FO.sheet(),
                          zoom=8, cols=25,
                          title='γραμματοσειρά 4x8 px = 8x8 μονάδες')

    # -------------------------------------------------- κόστος ανά καρέ
    budget = []
    for lab, w, h, masked, what in (
            ('σκάφος', SP.W, SP.H, True, 'ένα, πάντα'),
            ('εχθρός 8x16', 8, 16, True, 'η μάζα'),
            ('εχθρός 12x24', 12, 24, True, 'διοικητής'),
            ('βλήμα 8x8', SH.W, SH.H, True, 'ώς 12 μαζί'),
            ('boss 24x48', boss1.W, boss1.H, True, 'ένα στο τέλος'),
            ('πλακίδιο 8x8', TI.W, TI.H, False, '20x18 ανά οθόνη')):
        ms = blit_ms(w, h, masked)
        budget.append({'what': lab, 'ms': round(ms, 2),
                       'pct_of_frame': round(100 * ms / FRAME_MS, 1),
                       'note': what})
    # ΤΟ ΝΟΥΜΕΡΑ ΠΟΥ ΟΡΙΖΕΙ ΤΗ ΜΗΧΑΝΗ
    full = blit_ms(TI.W, TI.H, False) * 20 * 18
    budget.append({'what': 'ΟΛΟ το φόντο', 'ms': round(full, 1),
                   'pct_of_frame': round(100 * full / FRAME_MS, 1),
                   'note': '20x18 πλακίδια — ΔΕΝ ΧΩΡΑΕΙ ΣΕ ΚΑΡΕ'})
    doc['_blit_budget_25fps'] = budget
    doc['_palette'] = [{'pen': k, 'char': c, 'firmware': f, 'name': n,
                        'rgb': '#%02X%02X%02X' % gfx.RGB[k], 'use': u}
                       for k, (c, n, f, u) in enumerate(gfx.PALETTE)]
    doc['_mode0'] = {
        'screen_px': [160, 200], 'screen_units': [320, 200],
        'pixel_aspect': '2:1 — ένα pixel είναι διπλάσια φαρδύ από ψηλό',
        'bytes_per_line': 80, 'pixels_per_byte': 2,
        'move_2px': 'κίνηση ανά 2 pixel = 1 byte, άρα ΟΛΑ τα blits είναι '
                    'byte-aligned και δεν χρειάζονται προ-μετατοπισμένα '
                    'αντίγραφα',
    }
    doc['_total_bytes'] = total
    with open(os.path.join(OUT, 'assets.json'), 'w') as f:
        json.dump(doc, f, indent=1, ensure_ascii=False)
        f.write('\n')
    print()
    for b in budget:
        print('  %-14s %5.2f ms  %4.1f%% του καρέ   %s'
              % (b['what'], b['ms'], b['pct_of_frame'], b['note']))
    return total


if __name__ == '__main__':
    build()
