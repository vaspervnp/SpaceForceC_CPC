"""Το παλιό Amstrad hardware που πετάει ο Lord Garbage-Can: 8x8, χωρίς κατεύθυνση."""
from gfx import art

W, H = 8, 8

JUNK = [
    ('floppy', 'δισκέτα 3"', """
.KKKKKK.
KbbIIbbK
KbbIIbbK
KbbbbbbK
KbIIIIbK
KbIIIIbK
KKKKKKKK
........
"""),
    ('tape', 'κασέτα', """
........
oooooooo
oIIIIIIo
oIKIIKIo
oIIIIIIo
oooooooo
.dddddd.
........
"""),
    ('monitor', 'οθόνη CTM644', """
.iiiiii.
iKccccKi
iKccccKi
iKccccKi
.iiiiii.
...ii...
.iiiiii.
........
"""),
]


def frame(k):
    return art(JUNK[k][2], W, H, JUNK[k][0])
