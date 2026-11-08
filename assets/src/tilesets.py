"""Τα πλακίδια ανά πίστα: 16 ανά σετ, ανοίγουν πάνω στα tiles_gfx (bank 4).

Το σετ του διαστήματος είναι το tiles.py. Τα bureau και trash το αλλάζουν σε
λίγες θέσεις, της Γης είναι δικά τους. Ένα πλακίδιο εδώ είναι 8 ομάδες των 8
χαρακτήρων· το '.' είναι το pen 0, δηλαδή ο ουρανός της πίστας (LV_SKY).
"""
import tiles as TI
from gfx import art

BLANK = '........ ' * 8


def _t(text):
    return art('\n'.join(text.split()), 8, 8, 'tile', transparent='')


ART = {
    # ------------------------------------------------- γραφειοκρατία (πίστα 2)
    'stamp':   'rrrrrrrr rIrrrrIr rrIrrIrr rrrIIrrr rrrIIrrr rrIrrIrr rIrrrrIr rrrrrrrr',
    'form':    'IIIIIIII IKKKKIII IIIIIIII IKKKKKKI IIIIIIII IKKKIIII IIIIIIII iiiiiiii',
    'queue':   '........ ...yy... ...yy... ...KK... ...KK... ..iiii.. ...KK... ..KKKK..',
    # ------------------------------------------------ κονσόλες (πίστα 3)
    'console_a': 'KKKKKKKK KccccccK KcKccccK KccccKcK KccccccK KKKKKKKK iiiiiiii iKrKyKgi',
    'console_b': 'KKKKKKKK KgggggKK KgKKggKK KgggggKK KgKgKgKK KKKKKKKK iiiiiiii irKyKgKi',
    'console_c': 'iiiiiiii iKKiiKKi iKKiiKKi iiiiiiii iyiririi iiiiiiii iKKKKKKi iiiiiiii',
    # ------------------------------------------------ Αττική Οδός (πίστα 5)
    'cloud_a': '........ ..III... .IIIII.. IIIIIIII .iiiiii. ........ ........ ........',
    'cloud_b': '........ ........ ...II... ..IIII.. .IIIIII. ..iiii.. ........ ........',
    'wall':    'iiiKiiii iiiKiiii iiiKiiii KKKKKKKK iiiiiiKi iiiiiiKi iiiiiiKi KKKKKKKK',
    'win_lit': 'KKKKKKKK KyyyyyyK KySyyyyK KyyyyyyK KyyyyyyK KyyyyyyK KyyyyyyK KKKKKKKK',
    'win_off': 'KKKKKKKK KbKKKKKK KKbKKKKK KKKKKKKK KKKKKKKK KKKKKKKK KKKKKKKK KKKKKKKK',
    'neon_m':  'mmmmmmmm m......m m.mmmm.m m.m....m m.m....m m.mmmm.m m......m mmmmmmmm',
    'neon_c':  'cccccccc c......c c.c..c.c c.cc.c.c c.c.cc.c c.c..c.c c......c cccccccc',
    'roof':    'rrrrrrrr DDDDDDDD KKKKKKKK iiiiiiii iiiiiiii iiiiiiii iiiiiiii KKKKKKKK',
    'road':    'KKKKKKKK KKKKKKKK KKKKKKKK KKKKKKKK KKKKKKKK KKKKKKKK KKKKKKKK KKKKKKKK',
    'road_l':  'KKKKKKKK KKKKKKKK KKKKKKKK yyyyKKKK yyyyKKKK KKKKKKKK KKKKKKKK KKKKKKKK',
    'rail':    'iiiiiiii IIIIIIII rrrIIrrr rrrIIrrr KKKKKKKK ...KK... ...KK... ...KK...',
    # ---------------------------------------------------- Μέγαρα (πίστα 6)
    'rock':    'dddddddd dKddddKd dddddddd ddddKddd dDdddddd dddddddd dddKdddd dddddddD',
    'rock_b':  'dddKdddd ddddddDd dKdddddd dddddddd ddddddKd dDdddddd dddddddd KddddDdd',
    'soil':    'DdDdDdDd dDdDdDdD DdKdDdDd dDdDdDdD DdDdDdKd dDdDdDdD DdDdDdDd dKdDdDdD',
    'cave':    '........ ........ ........ ........ ........ ........ ........ ........',
    'root_v':  '...DD... ...DD... ..DDd... ..Dd.... ..DD.... ...DD... ...Dd... ...DD...',
    'root_h':  '........ ...D.... DDDDdDDD dDDDDDdD ....DD.. ......D. ........ ........',
    'crystal': '...g.... ..ggg... ..gIg... .ggggg.. .ngggn.. ..nnn... ........ ........',
    'moss':    'dndddndd nnndnnnd dddddddd dddddddd dKdddddd dddddKdd dddddddd dddddddd',
    # ------------------------------------------------ Ακρόπολη (πίστα 7)
    'marble':  'SSSSSSSS SSSSiSSS SSSSSSSS SiSSSSSS SSSSSSSS SSSSSSiS SSSSSSSS iiiiiiii',
    'column':  '.SSiSSi. .SSiSSi. .SSiSSi. .SSiSSi. .SSiSSi. .SSiSSi. .SSiSSi. .SSiSSi.',
    'capital': 'SSSSSSSS iiiiiiii .SSSSSS. ..SSSS.. .SSiSSi. .SSiSSi. .SSiSSi. .SSiSSi.',
    'ped_l':   '......SS .....SSS ....SSSS ...SSSSS ..SSSSSS .SSSSSSS SSSSSSSS iiiiiiii',
    'ped_r':   'SS...... SSS..... SSSS.... SSSSS... SSSSSS.. SSSSSSS. SSSSSSSS iiiiiiii',
    'ground':  'oooooooo oDoooooo ooooooDo oooooooo ooDooooo oooooooo ooooDooo oooooooo',
    'parking': 'oooooooI ooDooooI oooooooI oooooooI ooooDooI oooooooI oooooooI oooooooI',
    'tree':    '..nggn.. .nggggn. nggnggnn nnggnnnn .nnnnnn. ...dd... ...dd... ...dd...',
    # ---------------------------------------------------- κουζίνα (πίστα 8)
    'floor_a': 'IIIIiiii IIIIiiii IIIIiiii IIIIiiii iiiiIIII iiiiIIII iiiiIIII iiiiIIII',
    'k_wall':  'iiiiiiii iKiiiiKi iiiiiiii iiiiiiii iiiiiiii iiiiiiii iKiiiiKi iiiiiiii',
    'pot':     'iiKiiiii iiKiiiii iiKiiiii iiKiiiii iiKiiiii iiKiiiii iiKiiiii iiKiiiii',
    'pot_rim': 'KKKKKKKK IIIIIIII iiiiiiii KKKKKKKK iiKiiiii iiKiiiii iiKiiiii iiKiiiii',
    'soup':    'gggggggg gygggggg ggggyggg gggggggg ggyggggg ggggggyg gggggggg gggyggng',
    'steam':   '...I.... ..I..... ...I.... ....I... ...I.... ..I..... ...I.... ....I...',
    'k_pipe':  'KKKKKKKK DDDDDDDD yyyyyyyy DDDDDDDD DDDDDDDD dddddddd KKKKKKKK ........',
    'flame':   '........ ...y.... ..yy..y. .yrry.yy .yrrryry yrDDrrry rDDDDDrr DDDDDDDD',
    'k_grate': 'KiiKiiKi iKiiKiiK KiiKiiKi iKiiKiiK KiiKiiKi iKiiKiiK KiiKiiKi iKiiKiiK',
}


def _space_set(**replace):
    """Το σετ του διαστήματος, με κάποιες θέσεις αλλαγμένες."""
    keys = [k for k, *_ in TI.TILES]
    for old, new in replace.items():
        keys[keys.index(old)] = new
    return keys


def _set(*keys):
    """Σετ της Γης: όσα χρειάζεται, τα υπόλοιπα κενά ως τα 16."""
    assert len(keys) <= 16
    return list(keys) + ['_%d' % k for k in range(16 - len(keys))]


SETS = {
    'space': _space_set(),
    'bureau': _space_set(moon='stamp', moon_crater='form', tunnel='queue'),
    'trash': _space_set(nebula_a='console_a', nebula_b='console_b', nebula_c='console_c'),
    'attiki': _set('void', 'cloud_a', 'cloud_b', 'wall', 'win_lit', 'win_off', 'neon_m',
                   'neon_c', 'roof', 'road', 'road_l', 'rail'),
    'megara': _set('cave', 'rock', 'rock_b', 'soil', 'root_v', 'root_h', 'crystal', 'moss'),
    'acropolis': _set('void', 'cloud_a', 'cloud_b', 'marble', 'column', 'capital', 'ped_l',
                      'ped_r', 'ground', 'parking', 'tree'),
    'kitchen': _set('floor_a', 'k_wall', 'pot', 'pot_rim', 'soup', 'steam', 'k_pipe', 'flame',
                    'k_grate'),
}


def tile(key):
    if key.startswith('_') or key == 'void':
        return _t(BLANK)
    if key in ART:
        return _t(ART[key])
    return TI.tile(key)


def index(name):
    return {k: i for i, k in enumerate(SETS[name])}


def images(name):
    return [tile(k) for k in SETS[name]]
