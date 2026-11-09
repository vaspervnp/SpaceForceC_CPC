#!/usr/bin/env python3
"""Ηχογράφηση από τον headless CPC: οι registers του AY ανά καρέ -> WAV.

    python3 tools/sound_wav.py build/SpaceForceC.dsk

Ο headless emulator δεν βγάζει ήχο, αλλά δείχνει τους registers του AY.
Τους διαβάζουμε 50 φορές το δευτερόλεπτο (όσο συχνά τους αλλάζει και ο
player) και τους παίζουμε με έναν απλό συνθεσάιζερ AY: τετράγωνα κύματα,
θόρυβος με LFSR 17 bits, λογαριθμικές εντάσεις. Βγάζει:

    build/sound_title.wav   η μουσική του τίτλου
    build/sound_game.wav    το παιχνίδι: μουσική διαστήματος, βολές, Γη
    build/sound_over.wav    game over
"""
import os
import struct
import sys
import wave

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import headless as h  # noqa: E402
from cpc import CPC, JOY_FIRE, JOY_LEFT  # noqa: E402

RATE = 22050
AY_CLOCK = 1000000
# Οι 16 εντάσεις του AY (περίπου 3 dB το βήμα)
VOL = [0.0] + [10 ** ((v - 15) * 1.5 / 10) for v in range(1, 16)]


def render(frames, path):
    """frames: λίστα από 16 registers ανά 1/50 s -> WAV mono 16 bits."""
    per_frame = RATE // 50
    step = AY_CLOCK / 8 / RATE          # ο AY μετράει σε 1/8 του ρολογιού
    phase = [0.0, 0.0, 0.0]
    out = [0, 0, 0]
    nphase, lfsr, nbit = 0.0, 1, 1
    samples = bytearray()
    for r in frames:
        tp = [max(1, r[2 * c] | (r[2 * c + 1] & 15) << 8) for c in range(3)]
        npd = max(1, r[6] & 31)
        mix = r[7]
        vols = [VOL[r[8 + c] & 15] for c in range(3)]
        for _ in range(per_frame):
            for c in range(3):
                phase[c] += step
                half = tp[c]            # η έξοδος αλλάζει κάθε period x 8 ρολόγια
                while phase[c] >= half:
                    phase[c] -= half
                    out[c] ^= 1
            nphase += step / 2
            while nphase >= npd:
                nphase -= npd
                nbit = lfsr & 1
                lfsr = (lfsr >> 1) | (((lfsr ^ (lfsr >> 3)) & 1) << 16)
            s = 0.0
            for c in range(3):
                tone = out[c] | (mix >> c & 1)
                noise = nbit | (mix >> (c + 3) & 1)
                if tone & noise:
                    s += vols[c]
            samples += struct.pack('<h', int((s / 3 - 0.25) * 30000))
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(bytes(samples))


def record(c, n, log):
    for _ in range(n):
        c.run_frames(1)
        log.append(c.psg_regs())


def main():
    s = h.symbols(h.SYM)
    c = CPC()
    c.run_frames(150)
    c.insert_disc(h.DSK)
    c.type_text('RUN"DISC\n')
    h.wait_title(c, s)
    c.set_joystick_type(1)
    title = []
    record(c, 50 * 16, title)
    render(title, os.path.join(h.ROOT, 'build/sound_title.wav'))
    game = []
    h.start_game(c, s)                  # title -> ιστορία -> παιχνίδι
    record(c, 50 * 4, game)
    c.poke(s["invuln"], 250)
    for w in range(3):                  # τα τρία όπλα (W = επόμενο)
        c.joystick(JOY_FIRE | JOY_LEFT)
        record(c, 50, game)
        c.joystick(0)
        c.tap_key('w')
        record(c, 10, game)
    c.poke(s["music_req"], 3)           # η μουσική της Γης (mus_earth)
    record(c, 50 * 6, game)
    render(game, os.path.join(h.ROOT, 'build/sound_game.wav'))
    over = []
    c.poke(s["lives"], 1)
    c.poke(s["invuln"], 0)
    # ένα χτύπημα: η κατάσταση game over όπως τη στήνει το ship_hit
    c.poke(s["gameover"], 75)
    c.poke(s["music_now"], 0)
    c.poke(s["music_req"], 6)          # mus_gameover
    record(c, 50 * 4, over)
    render(over, os.path.join(h.ROOT, 'build/sound_over.wav'))
    loud = sum(1 for r in title if any(r[8 + i] & 15 for i in range(3)))
    print('τίτλος: %d/%d καρέ με ήχο' % (loud, len(title)))
    sys.exit(0 if loud > len(title) // 2 else 1)


if __name__ == '__main__':
    main()
