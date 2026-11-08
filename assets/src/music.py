"""Μουσική και ηχητικά εφέ -> assets/data/sound.asm (bank 6, src/sound.asm).

    python3 assets/src/music.py

ΕΝΑ ΜΙΚΡΟ MML ΑΝΤΙ ΓΙΑ TRACKER

Κάθε κανάλι γράφεται ως κείμενο:

    o4        οκτάβα (c4 = το μεσαίο ντο)        > <   οκτάβα πάνω / κάτω
    l12       προεπιλεγμένη διάρκεια σε ticks (50 Hz)
    @2        όργανο
    c d+ e-   νότες (+/# δίεση, - ύφεση), με προαιρετική διάρκεια: g24
    r24       παύση          &24   κράτημα της προηγούμενης νότας
    [ ... ]3  επανάληψη      |     διαχωριστικό μέτρου (αγνοείται)

Τα τρία κανάλια ενός κομματιού πρέπει να έχουν ακριβώς την ίδια διάρκεια,
αλλιώς ξεσυγχρονίζονται στο loop: ελέγχεται εδώ. Στο AY το κανάλι C είναι
και των ηχητικών εφέ: όσο παίζει ένα εφέ, κρύβει τα ντραμς.

ΜΟΡΦΗ ΣΤΗ ΜΝΗΜΗ (ένα byte ανά γεγονός)

    #00-#5F  νότα (ημιτόνιο από το c1), περιμένει τη διάρκεια
    #60      παύση           #61  κράτημα
    #80+d    διάρκεια d ticks (1-63) για τις επόμενες
    #C0+i    όργανο i
    #FE      τέλος (το κανάλι σωπαίνει)    #FF  ξανά από την αρχή

Όργανο: db flags (bit 0 θόρυβος, bit 1 χωρίς τόνο), db περίοδος θορύβου,
και η ένταση ανά tick ως το #FF (μένει η τελευταία).
"""
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, '..', 'data')

AY_CLOCK = 1000000              # CPC: 1 MHz
NOTE_BASE_OCTAVE = 1            # η νότα 0 = c1
N_NOTES = 96

# --------------------------------------------------------------------------
# Όργανα: (όνομα, θόρυβος, χωρίς τόνο, περίοδος θορύβου, εντάσεις)
INSTRUMENTS = [
    ('lead',  False, False, 0, [13, 14, 13, 12, 12, 11, 11, 10, 10, 10, 9]),
    ('bass',  False, False, 0, [15, 14, 13, 12, 12, 11]),
    ('kick',  False, False, 0, [15, 13, 10, 6, 2, 0]),
    ('snare', True,  True,  6, [15, 13, 11, 8, 5, 2, 0]),
    ('hat',   True,  True,  1, [10, 6, 2, 0]),
    ('pluck', False, False, 0, [12, 10, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    ('pad',   False, False, 0, [6, 8, 9, 10, 10, 9]),
]
INS = {name: i for i, (name, *_) in enumerate(INSTRUMENTS)}

DRUMS_4_4 = '@2 o2 c24 @4 c12 c12 @3 c24 @4 c12 c12'

# --------------------------------------------------------------------------
# Κομμάτια. Όλα πρωτότυπα. Τα ονόματα γίνονται mus_<όνομα> (1, 2, ...).

SONGS = [
    # Τίτλος: εμβατήριο σε ντο, ηρωικό αλλά λίγο αστείο. Μέτρο = 96 ticks.
    ('title', True, [
        '@0 o4 l12 | c e g e >c24< g24 | a f a >c< a24 f24 | g b >d< b g24 d24'
        ' | e g >c< g e24 r24 | a >c e c< a24 e24 | f a >c< a f24 >c24<'
        ' | d g b >d< g24 b24 | >c48< r24 g24',
        '@1 o2 l24 | c g c g | f >c< f >c< | g >d< g >d< | c g c g'
        ' | a >e< a >e< | f >c< f >c< | g >d< g >d< | c g c r',
        '[' + DRUMS_4_4 + ']8',
    ]),
    # Διάστημα (πίστες 1-4): λα ελάσσονα, 150 bpm, μέτρο = 80 ticks.
    ('space', True, [
        '@0 o4 l20 | e a >c< b10 a10 | e r e10 g10 a | f a >c d10 c10< | b40 g d'
        ' | a >c e d10 c10< | b a e40 | d f a g10 f10 | e g+ b40',
        '@1 o2 l10 | [a a >a< a a a >a< a]2 | f f >f< f f f >f< f'
        ' | g g >g< g g g >g< g | [a a >a< a a a >a< a]2'
        ' | d d >d< d d d >d< d | e e >e< e e e >e< e',
        '[@2 o2 c20 @4 c10 c10 @3 c20 @4 c10 c10]8',
    ]),
    # Γη (πίστες 5-8): ρε, με φρυγική χροιά και ρυθμό ταβέρνας. Μέτρο = 96.
    ('earth', True, [
        '@5 o4 l12 | d e- f+ g a24 g f+ | e-24 d24 r24 a24 | b-24 a g b-24 >d24<'
        ' | a g f+ e- d48 | e- g b- g e-24 g24 | f+ a >d< a f+48'
        ' | g f+ e- d c24 e-24 | d72 r24',
        '@1 o2 l24 | d a d a | d a d a | g >d< g >d< | d a d a'
        ' | e- b- e- b- | d a d a | c g c g | d a d r',
        '[@2 o2 c24 @3 c24 @2 c24 @3 c24]8',
    ]),
    # Boss: μι ελάσσονα, χρωματικό riff, μέτρο = 64.
    ('boss', True, [
        '@6 o4 l64 | b | >c< | b32 >c32< | b | g | a | b32 a32 | d+',
        '@1 o2 l8 | [e e >e< e f e >e< e]2 | f f >f< f f+ f >f< f'
        ' | e e >e< e f e >e< e | [c c >c< c c+ c >c< c]2'
        ' | [<b b >b< b >c< b >b< b>]2',
        '[@2 o2 c8 @4 c8 @3 c8 @4 c8 @2 c8 @2 c8 @3 c8 @4 c8]8',
    ]),
    # Τέλος του παιχνιδιού (M13): αργό, «θριαμβευτικό».
    ('ending', True, [
        '@0 o4 l48 | c e | g >c< | a f | g96 | e g | >c e< | f d | c96',
        '@1 o2 l48 | c c | e e | f f | g g | c c | a a | f g | c96',
        '@6 o3 l96 | e | g | a | b | g | e | a | g',
    ]),
    # Game over: τρεις λυπημένες νότες και μία ακόμα πιο λυπημένη. Μία φορά.
    ('gameover', False, [
        '@0 o4 l20 | g f+ f e60',
        '@1 o2 l20 | c <b a+ a60>',
        '@0 o3 l20 | r r r r60',
    ]),
]

# --------------------------------------------------------------------------
# Ηχητικά εφέ (κανάλι C). Η σειρά είναι και η προτεραιότητα: ένα εφέ
# διακόπτει μόνο ίσης ή χαμηλότερης προτεραιότητας.
#   περίοδος, μεταβολή ανά tick, ένταση, ticks ανά -1 ένταση,
#   θόρυβος (0 = όχι, 1-31 = τόνος + θόρυβος, +128 = μόνο θόρυβος), διάρκεια
SFX = [
    ('eshot',    200,  12, 10, 2, 0,       8),   # εχθρικό βλήμα
    ('disco',     80,  25, 13, 1, 0,      10),   # «πιου» που πέφτει
    ('baguette', 400,  30, 13, 2, 10,      8),   # βαρύ «φουπ»
    ('sneeze',     0,   0, 15, 1, 128 + 12, 12), # «α-τσου!»
    ('ant',      120,  -8, 12, 2, 0,       6),   # μυρμήγκι: «μπιπ» που ανεβαίνει
    ('menu',     150,   0, 12, 3, 0,       5),
    ('pickup',   320, -18, 13, 3, 0,      16),   # power-up: σκάλα προς τα πάνω
    ('pop',       40,   6, 15, 1, 128 + 2,  5),  # Bubble Wrap
    ('explode',    0,   0, 15, 2, 128 + 24, 30),
    ('hit',      700,  40, 15, 2, 8,      20),   # το σκάφος χτυπήθηκε
]


def periods():
    out = []
    for n in range(N_NOTES):
        midi = 12 * (NOTE_BASE_OCTAVE + 1) + n          # c1 = midi 24
        f = 440.0 * 2 ** ((midi - 69) / 12)
        out.append(min(4095, round(AY_CLOCK / (16 * f))))
    return out


TOKEN = re.compile(r'\s*(?:(\|)|(\[)|(\])(\d*)|([<>])|o(\d)|l(\d+)|@(\d+)'
                   r'|([a-g])([+#-]?)(\d*)|r(\d*)|&(\d*))')
NOTE = {'c': 0, 'd': 2, 'e': 4, 'f': 5, 'g': 7, 'a': 9, 'b': 11}


def expand(text):
    """Ξεδιπλώνει τις επαναλήψεις [ ... ]n."""
    while '[' in text:
        m = re.search(r'\[([^\[\]]*)\](\d*)', text)
        n = int(m.group(2) or 2)
        text = text[:m.start()] + ' '.join([m.group(1)] * n) + text[m.end():]
    return text


def compile_channel(text, loop):
    """MML -> (bytes, ticks)."""
    text = expand(text)
    octave, length = 4, 12
    events = []                 # (είδος, τιμή, διάρκεια)
    pos = 0
    while pos < len(text):
        if text[pos:].strip() == '':
            break
        m = TOKEN.match(text, pos)
        if not m or m.end() == pos:
            raise ValueError('MML: %r' % text[pos:pos + 20])
        pos = m.end()
        bar, _, _, _, octch, o, ln, ins, note, acc, nd, rest, tie = m.groups()
        if octch:
            octave += 1 if octch == '>' else -1
        elif o:
            octave = int(o)
        elif ln:
            length = int(ln)
        elif ins:
            events.append(('ins', int(ins), 0))
        elif note:
            n = NOTE[note] + {'+': 1, '#': 1, '-': -1, '': 0}[acc]
            idx = (octave - NOTE_BASE_OCTAVE) * 12 + n
            assert 0 <= idx < N_NOTES, (note, octave)
            events.append(('note', idx, int(nd) if nd else length))
        elif rest is not None:
            events.append(('rest', 0, int(rest) if rest else length))
        elif tie is not None:
            events.append(('tie', 0, int(tie) if tie else length))
    out, dur, ticks = [], None, 0
    for kind, val, d in events:
        if kind == 'ins':
            out.append(0xC0 + val)
            continue
        ticks += d
        first = True
        while d > 0:            # πάνω από 63 ticks: συνέχεια με κράτημα
            part = min(d, 63)
            if part != dur:
                out.append(0x80 + part)
                dur = part
            if kind == 'note' and first:
                out.append(val)
            elif kind == 'rest' and first:
                out.append(0x60)
            else:
                out.append(0x60 if kind == 'rest' else 0x61)
            first = False
            d -= part
    out.append(0xFF if loop else 0xFE)
    return out, ticks


def db(data, per_line=16):
    return ['        db ' + ','.join('#%02X' % b for b in data[i:i + per_line])
            for i in range(0, len(data), per_line)]


def main():
    lines = ['; sound.asm — ΠΑΡΑΓΕΤΑΙ ΑΥΤΟΜΑΤΑ από assets/src/music.py.',
             '; Μουσική και ηχητικά εφέ για τον player του src/sound.asm (bank 6).',
             '']
    for i, (name, *_) in enumerate(SONGS):
        lines.append('mus_%-14s equ %d' % (name, i + 1))
    lines.append('MUS_COUNT          equ %d' % len(SONGS))
    lines.append('')
    for i, (name, *_) in enumerate(SFX):
        lines.append('sfx_%-14s equ %d' % (name, i + 1))
    lines.append('SFX_COUNT          equ %d' % len(SFX))
    lines += ['', 'note_periods:']
    p = periods()
    for i in range(0, N_NOTES, 12):
        lines.append('        dw ' + ','.join('%d' % v for v in p[i:i + 12])
                     + '    ; c%d' % (NOTE_BASE_OCTAVE + i // 12))
    lines += ['', 'instruments:']
    lines.append('        dw ' + ','.join('ins_' + n for n, *_ in INSTRUMENTS))
    for name, noise, notone, nper, vols in INSTRUMENTS:
        flags = (1 if noise else 0) | (2 if notone else 0)
        lines.append('ins_%s:' % name)
        lines += db([flags, nper] + vols + [0xFF])
    lines += ['', '; ανά κομμάτι: τα τρία κανάλια', 'songs:']
    total = 0
    for name, loop, chans in SONGS:
        lines.append('        dw ' + ','.join('%s_%s' % (name, c) for c in 'abc'))
    for name, loop, chans in SONGS:
        lengths = []
        for c, text in zip('abc', chans):
            data, ticks = compile_channel(text, loop)
            lengths.append(ticks)
            total += len(data)
            lines.append('%s_%s:          ; %d ticks' % (name, c, ticks))
            lines += db(data)
        if len(set(lengths)) != 1:
            raise SystemExit('%s: κανάλια με διαφορετική διάρκεια %s' % (name, lengths))
    lines += ['', '; ανά εφέ: dw περίοδος, dw μεταβολή, db ένταση, ticks ανά -1,'
              ' θόρυβος, διάρκεια', 'sfx_table:']
    for name, per, dper, vol, dec, noise, ln in SFX:
        lines.append('        dw %d,%d' % (per, dper))
        lines.append('        db %d,%d,%d,%d       ; %s' % (vol, dec, noise, ln, name))
    path = os.path.join(DATA, 'sound.asm')
    with open(path, 'w') as f:
        f.write('\n'.join(lines) + '\n')
    print('%s: %d κομμάτια (%d bytes), %d εφέ' % (path, len(SONGS), total, len(SFX)))


if __name__ == '__main__':
    main()
