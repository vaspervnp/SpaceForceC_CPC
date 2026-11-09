#!/usr/bin/env python3
"""Βίντεο 2 λεπτών από τον headless CPC: build/SpaceForceC.mp4 (make video).

Παίζει ένα bot μέσα στο πραγματικό παιχνίδι της δισκέτας: διαλέγει τον
κοντινότερο στόχο, πάει κοντά του και ρίχνει. Για να μη χαθεί, του γεμίζουμε την
ενέργεια όταν πέσει, και οι bosses κλείνουν στον χρόνο της σκηνής. Η εικόνα είναι
το framebuffer ανά καρέ των 50 Hz, ο ήχος οι registers του AY (tools/sound_wav.py).
Οι μεταβάσεις ανάμεσα στις σκηνές δεν γράφονται (φόρτωμα, πίστες που πηδάμε).
"""
import math
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import headless as h  # noqa: E402
import sound_wav  # noqa: E402
from cpc import CPC, JOY_UP, JOY_DOWN, JOY_LEFT, JOY_RIGHT, JOY_FIRE  # noqa: E402

TOTAL = 120 * 50                # καρέ των 50 Hz
FADE = 12
ENDING_PRESS = (200, 400, 680)  # καρέ του τέλους με fire, όταν έχει γραφτεί η οθόνη
OUT = os.path.join(h.ROOT, "build/SpaceForceC.mp4")
WAV = os.path.join(h.ROOT, "build/video.wav")
SPR = 9
ENEMY_N = 10
FULL_ENERGY = 10                # Easy: energy_table στο hazards.asm
ITEM_SLOTS = range(24, 27)
SHIP_SLOT = 28


class Recorder:
    def __init__(self, c):
        self.c = c
        self.n = 0
        self.regs = []
        self.ff = subprocess.Popen(
            ["ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24",
             "-s", "768x272", "-r", "50", "-i", "-", "-vf",
             "scale=1536:1088:flags=neighbor,crop=1536:1080,pad=1920:1080:192:0",
             "-c:v", "libx264", "-crf", "17", "-preset", "medium", "-pix_fmt", "yuv420p",
             "-an", OUT + ".video.mp4"], stdin=subprocess.PIPE)

    def frame(self, gain=1.0):
        c = self.c
        c.run_frames(1)
        im = c.image()
        if gain < 1.0:
            im = im.point(lambda v: int(v * gain))
        self.ff.stdin.write(im.tobytes())
        r = list(c.psg_regs())
        for k in (8, 9, 10):
            r[k] = int((r[k] & 15) * gain)
        self.regs.append(r)
        self.n += 1

    def scene(self, frames, step=None):
        """frames καρέ με fade στην αρχή και στο τέλος· step(k) πριν από κάθε καρέ."""
        frames = min(frames, TOTAL - self.n)
        for k in range(frames):
            if step:
                step(k)
            self.frame(min(1.0, (k + 1) / FADE, (frames - k) / FADE))

    def close(self):
        self.ff.stdin.close()
        self.ff.wait()
        sound_wav.render(self.regs, WAV)
        subprocess.check_call(
            ["ffmpeg", "-y", "-loglevel", "error", "-i", OUT + ".video.mp4", "-i", WAV,
             "-c:v", "copy", "-af", "highpass=f=20", "-c:a", "aac", "-b:a", "192k", "-shortest",
             "-movflags", "+faststart", OUT])
        os.remove(OUT + ".video.mp4")
        os.remove(WAV)


class Bot:
    """Μόνο ό,τι μπορεί και ο παίκτης: joystick, και η φορά του σκάφους προς τον στόχο."""

    def __init__(self, c, s):
        self.c, self.s = c, s

    def sprite(self, slot):
        a = self.s["spr_table"] + slot * SPR
        fl, x, lo, hi, _, _, w, hh = self.c.read_ram(a, 8)
        return fl, x + w // 2, (lo | hi << 8) + hh // 2

    def target(self, sx, sy):
        best, bd = None, 1e9
        for i in range(ENEMY_N):
            base = self.s["enemies"] + i * h.EN_SIZE
            fl, x, y = self.sprite(i)
            if fl and self.c.peek(base + h.EN_STATE) == 0:
                d = math.hypot((x - sx) * 2, y - sy)
                if self.c.peek(base + h.EN_KIND) == h.KIND_BOSS:
                    d *= 0.5
                if d < bd:
                    best, bd = (x, y), d
        for i in ITEM_SLOTS:                    # μυρμήγκια, μπαταρίες: προτεραιότητα
            fl, x, y = self.sprite(i)
            d = math.hypot((x - sx) * 2, y - sy)
            if fl and d < 110:
                return (x, y), True
        return best, False

    def step(self, _k=0):
        c, s = self.c, self.s
        if c.peek(s["energy"]) <= 2:
            c.poke(s["energy"], FULL_ENERGY)
        _, sx, sy = self.sprite(SHIP_SLOT)
        t, grab = self.target(sx, sy)
        if not t:
            c.joystick(JOY_FIRE)
            return
        dx, dy = (t[0] - sx) * 2, t[1] - sy
        d = math.hypot(dx, dy)
        j = JOY_FIRE
        near, far = (0, 4) if grab else (34, 62)
        if d > far or d < near:
            sign = 1 if d > far else -1
            if dx * sign > 8:
                j |= JOY_RIGHT
            elif dx * sign < -8:
                j |= JOY_LEFT
            if dy * sign > 8:
                j |= JOY_DOWN
            elif dy * sign < -8:
                j |= JOY_UP
        c.joystick(j)
        # 0 = βόρεια, δεξιόστροφα
        c.poke(s["ship_dir"], int(round(math.atan2(dx, -dy) / (math.pi / 4))) & 7)


def boss_slot(c, s):
    for i in range(ENEMY_N):
        base = s["enemies"] + i * h.EN_SIZE
        if c.peek(base + h.EN_KIND) == h.KIND_BOSS and c.peek(base + h.EN_STATE) == 0:
            return base
    return None


def kill_boss(c, s, bot, base):
    """Χωρίς εγγραφή: αντοχή 1, ως να τον βρει μια βολή."""
    for _ in range(4000):
        if c.peek(base + h.EN_STATE):
            break
        c.poke(base + h.EN_HP, 1)
        bot.step()
        c.run_frames(1)
    c.joystick(0)


def boss_fight(rec, c, s, bot, frames):
    """Ο boss ζωντανός για frames καρέ, μετά πέφτει από μια τελευταία βολή."""
    h.clear_enemies(c, s)
    for _ in range(200):
        bot.step()
        c.run_frames(1)
        if boss_slot(c, s):
            break
    base = boss_slot(c, s)
    hp = c.peek(base + h.EN_HP)

    def step(k):
        bot.step()
        # η αντοχή πέφτει ώστε να τελειώσει περίπου στο τέλος της σκηνής
        left = max(1, hp * (frames - k) // frames)
        if c.peek(base + h.EN_HP) > left:
            c.poke(base + h.EN_HP, left)
    rec.scene(frames + 150, lambda k: step(k) if c.peek(base + h.EN_STATE) == 0 else c.joystick(0))
    print("boss πίστας %d: κατάσταση %d, αντοχή %d από %d, καρέ %d"
          % (c.peek(s["level"]) + 1, c.peek(base + h.EN_STATE), c.peek(base + h.EN_HP), hp, rec.n))
    kill_boss(c, s, bot, base)


def finish_level(c, s, bot):
    """Χωρίς εγγραφή: ο boss της πίστας πέφτει, ως το Level Complete."""
    h.clear_enemies(c, s)
    for _ in range(300):
        bot.step()
        c.run_frames(1)
        if boss_slot(c, s):
            break
    kill_boss(c, s, bot, boss_slot(c, s))
    c.run_frames(380)


def to_level(c, s, n, rec=None, card=150):
    """Από το Level Complete στην οθόνη της πίστας n και μετά στο παιχνίδι."""
    c.poke(s["level"], n - 2)
    h.fire(c)
    c.run_frames(20)
    if rec:
        rec.scene(card)
    h.fire(c)
    c.run_frames(30)


def main():
    s = h.symbols(h.SYM)
    c = CPC()
    c.run_frames(150)
    c.insert_disc(h.DSK)
    c.type_text('RUN"DISC\n')
    art = open(os.path.join(h.ROOT, "assets/revive8b.scr"), "rb").read()
    while bytes(c.read_ram(0xC000, len(art))) != art:
        c.run_frames(5)
    c.run_frames(5)
    c.set_joystick_type(1)
    rec = Recorder(c)
    bot = Bot(c, s)
    rec.scene(220)                      # η οθόνη REVIVE8BIT
    c.key_down(ord(" "))
    c.run_frames(10)
    c.key_up(ord(" "))
    h.wait_title(c, s)
    rec.scene(400)                      # ο τίτλος

    # η εισαγωγή: το fire πάει στην επόμενη οθόνη
    def press(k):
        c.joystick(JOY_FIRE if k % 220 in range(210, 216) else 0)
    h.fire(c)
    rec.scene(500, press)
    k = 0
    while c.peek(s["music_now"]) == 1 and k < 20:
        h.fire(c)
        k += 1
    rec.scene(120)                      # η οθόνη της πίστας 1
    n = 0
    while h.word(c, s["frames"]) == 0 and n < 5:
        h.fire(c)
        n += 1

    rec.scene(750, bot.step)           # πίστα 1: διάστημα
    boss_fight(rec, c, s, bot, 550)
    c.run_frames(230)
    to_level(c, s, 3, rec, 100)
    rec.scene(400, bot.step)            # πίστα 3
    finish_level(c, s, bot)
    to_level(c, s, 5, rec, 100)
    rec.scene(500, bot.step)            # πίστα 5: η Γη
    boss_fight(rec, c, s, bot, 500)
    c.run_frames(230)
    to_level(c, s, 7, rec, 100)
    rec.scene(300, bot.step)            # πίστα 7
    c.poke(s["level"], 7)               # η 8: ο τελευταίος boss οδηγεί στο τέλος
    finish_level(c, s, bot)
    h.fire(c)
    c.run_frames(30)

    def press2(k):
        # τρία πατήματα: η τελευταία οθόνη, τα credits, μένει ως το τέλος
        c.joystick(JOY_FIRE if any(p <= k < p + 6 for p in ENDING_PRESS) else 0)
    rec.scene(TOTAL - rec.n, press2)    # το τέλος της ιστορίας και τα credits
    rec.close()
    print("%s: %d καρέ, %.1f s" % (OUT, rec.n, rec.n / 50))


if __name__ == "__main__":
    main()
