"""Αυτόματο test του Space Force C σε CPC 6128 χωρίς GUI.

Τρέχει τη δισκέτα στον headless emulator του ~/cpcemu (floooh/chips),
οδηγεί το σκάφος με το joystick σε σενάρια κίνησης και μετά από κάθε σενάριο:
  - διαβάζει από τη RAM τα frames / late_frames (μέσω build/sfc.sym):
    late = καρέ που δεν χώρεσαν στα 40 ms
  - ελέγχει ότι η σελίδα που εμφανίζεται είναι ακριβώς ο χάρτης κάτω από την
    κάμερά της, κελί-κελί (εκτός από τα κελιά κάτω από το σκάφος)
  - μετράει τον χρόνο εργασίας κάθε καρέ: από την έξοδο από το flip ως
    την είσοδο στο επόμενο (ανάλυση 100 µs)· > 40 ms = το καρέ δεν χωράει
  - γράφει screenshot στο build/test_<σενάριο>.png

    python3 tools/headless.py [build/SpaceForceC.dsk]

CPCHEADLESS=/path για άλλον φάκελο του emulator, CRTC=0/1/2 για τύπο CRTC
(το split screen του HUD είναι το σημείο όπου διαφέρουν). Βγαίνει με 1 αν
κάποιος έλεγχος αποτύχει.
"""

import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.environ.get("CPCHEADLESS", os.path.expanduser("~/cpcemu")))
import ctypes  # noqa: E402
import random  # noqa: E402
import cpc as cpcmod  # noqa: E402
sys.path.insert(0, os.path.join(ROOT, "assets", "src"))
import levels  # noqa: E402
from cpc import CPC, JOY_UP, JOY_DOWN, JOY_LEFT, JOY_RIGHT, JOY_FIRE  # noqa: E402

cpcmod._lib.cpcemu_ram_ptr.restype = ctypes.POINTER(ctypes.c_uint8)
cpcmod._lib.cpcemu_ram_ptr.argtypes = [ctypes.c_void_p, ctypes.c_int]

DSK = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "build/SpaceForceC.dsk")
SYM = os.path.join(ROOT, "build/sfc.sym")
TILES = open(os.path.join(ROOT, "assets/data/tiles.bin"), "rb").read()

MAP_W, MAP_H, VIEW_W, VIEW_H = 64, 48, 40, 21
BUF_SIZE = 7
REC_SIZE = 8

SCENARIOS = [
    ("right", JOY_RIGHT, 120),
    ("down_right", JOY_DOWN | JOY_RIGHT, 120),
    ("down", JOY_DOWN, 100),
    ("up_left", JOY_UP | JOY_LEFT, 200),
    ("left", JOY_LEFT, 150),
    ("up", JOY_UP, 150),
    ("down_left", JOY_DOWN | JOY_LEFT, 100),
    ("up_right", JOY_UP | JOY_RIGHT, 160),
    ("idle", 0, 50),
]


def symbols(path):
    sym = {}
    for line in open(path):
        parts = line.split()
        if len(parts) >= 2 and parts[1].startswith("#"):
            sym[parts[0].lower()] = int(parts[1][1:], 16)
    return sym


def word(c, addr):
    lo, hi = c.read_ram(addr, 2)
    return lo | hi << 8


def bank_read(c, bank, addr, size):
    """Ένα από τα 8 banks των 16K, όπως φαίνεται στο #4000 (C4-C7)."""
    p = cpcmod._lib.cpcemu_ram_ptr(c._h, bank)
    off = addr & 0x3FFF
    return bytes(p[off:off + size])


def check_view(c, s):
    """Η σελίδα που εμφανίζεται == ο χάρτης κάτω από την κάμερά της."""
    draw_page = c.peek(s["draw_page"])
    shown = 0xC0 if draw_page == 0x80 else 0x80
    buf = s["bufs"] + (BUF_SIZE if shown == 0xC0 else 0)
    cx, cy, nrec = c.read_ram(buf, 3)
    recs = word(c, buf + 3)
    covered = set()             # κελιά κάτω από sprites αυτής της σελίδας
    for i in range(nrec):
        x, ylo, yhi, w, h = c.read_ram(recs + i * REC_SIZE, 5)
        y = ylo | yhi << 8
        for wy in range(y // 8, (y + h - 1) // 8 + 1):
            for wx in range(x // 2, (x + w - 1) // 2 + 1):
                covered.add((wx, wy))
    bg_map = bank_read(c, 4, s["bg_map"], MAP_W * MAP_H)
    bad = []
    for wy in range(cy, cy + VIEW_H):
        for wx in range(cx, cx + VIEW_W):
            if (wx, wy) in covered:
                continue
            tile = bg_map[wy * MAP_W + wx // 2]
            src = tile * 32 + (wx & 1) * 2
            ma = (wy * 40 + wx) % 1024
            for line in range(8):
                addr = (shown << 8) | (line << 11) | (2 * ma)
                want = TILES[src + line * 4: src + line * 4 + 2]
                got = c.read_ram(addr, 2)
                if bytes(got) != want:
                    bad.append((wx, wy, line))
                    break
    return shown, cx, cy, nrec, bad


STEP_US = 100


def run_measured(c, s, frames):
    """Τρέχει frames καρέ των 50 Hz· επιστρέφει τους χρόνους εργασίας (ms)."""
    wait_lo, wait_hi = s["flip"], s["flip.swap"]
    times, busy, waiting = [], 0, False
    for _ in range(frames * 20000 // STEP_US):
        c.run_us(STEP_US)
        now_waiting = wait_lo <= c.pc < wait_hi
        if now_waiting and not waiting and busy:
            times.append(busy * STEP_US / 1000)
        if not now_waiting:
            busy = 0 if waiting else busy + 1
        waiting = now_waiting
    return times[1:]            # το πρώτο ξεκίνησε πριν από τη μέτρηση


def wait_title(c, s):
    """Φόρτωμα ως τον τίτλο (η μουσική του έχει ξεκινήσει)."""
    for _ in range(100):
        c.run_frames(20)
        if c.peek(s["music_now"]) == 1:     # mus_title
            c.run_frames(25)
            return
    raise SystemExit("ο τίτλος δεν εμφανίστηκε")


def fire(c, frames=10):
    c.joystick(JOY_FIRE)
    c.run_frames(frames)
    c.joystick(0)
    c.run_frames(frames)


def check_level(c, s, n):
    """Ο χάρτης στο bank 4 και ο κόσμος == ό,τι έβγαλε το levels.py."""
    lv = levels.LEVELS[n - 1]
    rnd = random.Random(442 * n)
    want = bytes(t for row in levels.make_map(lv, rnd) for t in row)
    got = bank_read(c, 4, 0x4000, len(want))
    world = c.peek(s["ship_world"])
    good = got == want and c.peek(s["level"]) == n - 1 \
        and world == (0 if lv["world"] == "space" else 8)
    print("πίστα %d: χάρτης %s, κόσμος %d, εχθροί στη λίστα %d  %s"
          % (n, "ίδιος" if got == want else "ΔΙΑΦΟΡΕΤΙΚΟΣ", world,
             c.peek(s["spawn_left"]), "OK" if good else "ΛΑΘΟΣ"))
    return good


EN_SIZE, EN_KIND, EN_STATE, EN_HP = 11, 5, 6, 8
KIND_BOSS = 12


def boss_flow(c, s):
    """Τέλος λίστας -> boss -> μάχη με fire προς τα πάνω -> Level Complete."""
    c.poke(s["spawn_left"], 0)
    for i in range(10):             # όλοι οι εχθροί: επόμενος της λίστας τώρα
        c.poke(s["enemies"] + i * EN_SIZE + EN_STATE, 3)
        c.poke(s["enemies"] + i * EN_SIZE + 7, 1)
    c.run_frames(10)
    slots = [i for i in range(10)
             if c.peek(s["enemies"] + i * EN_SIZE + EN_KIND) == KIND_BOSS
             and c.peek(s["enemies"] + i * EN_SIZE + EN_STATE) == 0]
    if not slots or c.peek(s["boss_on"]) == 0:
        print("boss: ΔΕΝ ΒΓΗΚΕ")
        return False
    boss = s["enemies"] + slots[0] * EN_SIZE
    c.poke(s["invuln"], 250)
    c.joystick(JOY_DOWN)            # χώρος από πάνω: ο boss στέκεται εκεί
    c.run_frames(120)               # (σταματάει στην κάτω άκρη της arena)
    c.joystick(0)
    c.run_frames(40)                # σταματάει
    c.poke(s["ship_dir"], 0)        # κοιτάει πάνω (n)
    c.poke(s["invuln"], 250)
    c.run_frames(150)               # ως να φτάσει ο boss
    c.screenshot(os.path.join(ROOT, "build/test_boss.png"))
    late0, f0 = word(c, s["late_frames"]), word(c, s["frames"])
    hp0 = c.peek(boss + EN_HP)
    c.joystick(JOY_FIRE)
    junk, n = 0, 0
    while c.peek(boss + EN_STATE) == 0 and n < 3000:
        c.poke(s["invuln"], 50)
        c.run_frames(1)
        n += 1
        for e in range(5):
            if c.peek(s["eshots"] + e * 6 + 2) and c.peek(s["eshots"] + e * 6 + 3) == 4:
                junk += 1
                break
        if n == 300:
            c.screenshot(os.path.join(ROOT, "build/test_boss_fight.png"))
    c.joystick(0)
    fr = word(c, s["frames"]) - f0
    late = word(c, s["late_frames"]) - late0
    print("boss: αντοχή %d -> %d σε %.1f s, hardware στον αέρα %d καρέ, late %d/%d, σκάφος %d,%d"
          % (hp0, c.peek(boss + EN_HP), n / 50, junk, late, fr,
             c.peek(s["ship_x"]), word(c, s["ship_y"])))
    good = n < 3000 and junk > 0
    c.run_frames(30)
    c.screenshot(os.path.join(ROOT, "build/test_boss_boom.png"))
    c.run_frames(350)               # εκρήξεις, χρόνος για τα μυρμήγκια
    c.screenshot(os.path.join(ROOT, "build/test_complete.png"))
    good = good and word(c, s["score"]) >= 5000
    print("boss: σκορ %d %s" % (word(c, s["score"]), "OK" if good else "ΛΑΘΟΣ"))
    return good


def level_complete_flow(c, s):
    """Μετά τον boss: Level Complete -> πίστα 2 -> (Γη) πίστα 5."""
    fire(c)
    c.run_frames(20)
    c.screenshot(os.path.join(ROOT, "build/test_level2.png"))
    fire(c)
    c.run_frames(30)
    good = check_level(c, s, 2)
    c.poke(s["level"], 3)           # μετά την 4η: η 5η, στη Γη
    c.poke(s["level_done"], 1)
    c.run_frames(30)
    fire(c)
    c.run_frames(20)
    fire(c)
    c.run_frames(30)
    good = check_level(c, s, 5) and good
    c.screenshot(os.path.join(ROOT, "build/test_level5_game.png"))
    return good


def game_over_flow(c, s):
    """Game over με ρεκόρ: όνομα (UP x2 = C), πίνακας, πίσω στον τίτλο."""
    c.poke(s["score"], 6000 & 255)
    c.poke(s["score"] + 1, 6000 >> 8)
    c.poke(s["gameover"], 2)
    c.run_frames(60)
    c.screenshot(os.path.join(ROOT, "build/test_name.png"))
    c.joystick(JOY_UP)
    c.run_frames(2)
    c.joystick(0)
    c.run_frames(4)
    c.joystick(JOY_UP)
    c.run_frames(2)
    c.joystick(0)
    c.run_frames(4)
    for _ in range(3):
        fire(c)
    c.run_frames(30)
    c.screenshot(os.path.join(ROOT, "build/test_hiscores.png"))
    top = bytes(c.read_ram(s["hiscores"], 5))
    good = top == b"CAA" + bytes([6000 & 255, 6000 >> 8])
    print("ρεκόρ: %r %s" % (top, "OK" if good else "ΛΑΘΟΣ"))
    return good


def main():
    s = symbols(SYM)
    c = CPC()
    if "CRTC" in os.environ:
        c.crtc_type = int(os.environ["CRTC"])
    print("CRTC τύπος %d" % c.crtc_type)
    c.run_frames(150)
    c.insert_disc(DSK)
    c.type_text('RUN"DISC\n')
    wait_title(c, s)
    c.set_joystick_type(1)
    c.screenshot(os.path.join(ROOT, "build/test_title.png"))
    fire(c)                     # title -> οθόνη της πίστας
    c.screenshot(os.path.join(ROOT, "build/test_level1.png"))
    fire(c)                     # -> παιχνίδι
    c.run_frames(30)
    ok_level = check_level(c, s, 1)
    ok = True
    for name, mask, frames in SCENARIOS:
        f0, l0 = word(c, s["frames"]), word(c, s["late_frames"])
        c.poke(s["invuln"], 250)    # οι δοκιμές κίνησης δεν πρέπει να χάσουν
        c.joystick(mask)
        times = run_measured(c, s, frames)
        c.joystick(0)
        c.run_frames(1)
        f1, l1 = word(c, s["frames"]), word(c, s["late_frames"])
        shown, cx, cy, nrec, bad = check_view(c, s)
        ship = (c.peek(s["ship_x"]), word(c, s["ship_y"]))
        status = "OK" if not bad else "ΛΑΘΟΣ %d κελιά, π.χ. %s" % (len(bad), bad[:3])
        work = "%4.1f/%4.1f ms" % (sum(times) / len(times), max(times)) if times else "   -"
        print("%-11s %3d καρέ  late %d  εργασία μέση/μέγ. %s  σκάφος %3d,%3d  κάμερα %2d,%2d  sprites %2d  %s"
              % (name, f1 - f0, l1 - l0, work, ship[0], ship[1], cx, cy, nrec, status))
        c.screenshot(os.path.join(ROOT, "build/test_%s.png" % name))
        if bad or f1 == f0:
            ok = False
    late = word(c, s["late_frames"])
    print("σύνολο: %d καρέ, %d άργησαν" % (word(c, s["frames"]), late))
    ok = ok_level and boss_flow(c, s) and level_complete_flow(c, s) and ok
    ok = game_over_flow(c, s) and ok
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
