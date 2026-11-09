#!/usr/bin/env python3
"""Τα εγχειρίδια: docs/img/*.png, docs/manual-en.md -> .pdf, docs/manual-el.md -> .pdf.

    python3 tools/mkmanual.py           (make manual)

Οι εικόνες των αντικειμένων βγαίνουν από τα γραφικά του assets/src, με τα
pixels του Mode 0 (διπλά φαρδιά), και οι οθόνες από τα build/test_*.png του
make test. Το fpdf2 γράφει το PDF, με DejaVu, που έχει ελληνικά. Διαβάζει ό,τι
χρησιμοποιούν τα εγχειρίδια: #/##/###, παραγράφους, λίστες με -, πίνακες με |
(και εικόνες μέσα τους), κώδικα με 4 κενά, εικόνες σε δική τους γραμμή, και
μέσα στο κείμενο **έντονα**, *πλάγια*, `κώδικα` και [συνδέσμους](...).
"""
import os
import re
import sys

from fpdf import FPDF
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "assets", "src"))
DOCS = os.path.join(ROOT, "docs")
IMG = os.path.join(DOCS, "img")
FONTS = "/usr/share/fonts/truetype/dejavu"
MARGIN = 18.0
TEXT_W = 210.0 - 2 * MARGIN
INK, HEAD, SUB, RULE, TINT = (32, 32, 36), (176, 48, 16), (92, 92, 100), (208, 208, 214), (238, 238, 234)
SHOTS = {"title": "t_a", "hud": "test_energy", "play": "test_right", "boss": "test_fight7"}


# ------------------------------------------------------------------ εικόνες

def sprite_png(img, name):
    import gfx
    h, w = len(img), len(img[0])
    out = Image.new("RGB", (w, h))
    for y, row in enumerate(img):
        for x, pen in enumerate(row):
            out.putpixel((x, y), (0, 0, 0) if pen is None else tuple(gfx.RGB[pen]))
    out.resize((w * 8, h * 4), Image.NEAREST).save(os.path.join(IMG, name + ".png"))


def make_images():
    import bosses
    import enemies
    import pickups
    import shots
    os.makedirs(IMG, exist_ok=True)
    for key in ("shield", "espresso", "magnet", "engine", "disco", "baguette", "sneeze", "spray", "life", "energy"):
        sprite_png(pickups.pickup(key), "p_" + key)
    sprite_png(pickups.ant(0), "p_ant")
    for key in ("grunt", "mine", "saucer", "roach", "sock", "suitcase"):
        sprite_png(enemies.frames(key)[0], "e_" + key)
    for kind in ("disco", "baguette"):
        sprite_png(shots.shot(kind, "e", 0), "w_" + kind)
    sprite_png(shots.shot("sneeze", "n", 0), "w_sneeze")
    sprite_png(shots.shot("e9", "n", 0), "s_e9")
    for kind in ("spaghetti", "torpedo"):
        sprite_png(shots.shot(kind, "e", 0), "s_" + kind)
    for n in range(1, 9):
        sprite_png(bosses.BOSSES[n][1][0], "b%d" % n)
    for name, src in SHOTS.items():
        path = os.path.join(ROOT, "build", src + ".png")
        if os.path.exists(path):
            im = Image.open(path).convert("RGB")
            if im.height < 400:         # το screenshot του make test: μία γραμμή ανά scanline
                im = im.resize((im.width, im.height * 2), Image.NEAREST)
            im.save(os.path.join(IMG, name + ".png"))


# --------------------------------------------------------------------- PDF

TOKEN = re.compile(r"\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`")
LINK = re.compile(r"\[([^\]]*)\]\(([^)]*)\)")
PICTURE = re.compile(r"^!\[([^\]]*)\]\(([^)]*)\)$")


class Manual(FPDF):
    def __init__(self, footer_text):
        super().__init__(format="A4")
        self.footer_text = footer_text
        self.set_margins(MARGIN, MARGIN, MARGIN)
        self.set_auto_page_break(True, MARGIN + 6)
        for style, file in (("", "DejaVuSans"), ("B", "DejaVuSans-Bold"), ("I", "DejaVuSans-Oblique")):
            self.add_font("dv", style, os.path.join(FONTS, file + ".ttf"))
        self.add_font("dvm", "", os.path.join(FONTS, "DejaVuSansMono.ttf"))

    def footer(self):
        self.set_y(-14)
        self.set_font("dv", "", 8)
        self.set_text_color(*SUB)
        self.cell(0, 6, "%s   ·   %d" % (self.footer_text, self.page_no()), align="C")


def runs(text):
    text = LINK.sub(r"\1", text)
    out, at = [], 0
    for m in TOKEN.finditer(text):
        if m.start() > at:
            out.append((text[at:m.start()], ""))
        if m.group(1) is not None:
            out.append((m.group(1), "B"))
        elif m.group(2) is not None:
            out.append((m.group(2), "I"))
        else:
            out.append((m.group(3), "C"))
        at = m.end()
    if at < len(text):
        out.append((text[at:], ""))
    return out


def set_run(pdf, style, size):
    if style == "C":
        pdf.set_font("dvm", "", size * 0.92)
    else:
        pdf.set_font("dv", style, size)


def lay_out(pdf, text, size, width):
    """Οι λέξεις σε γραμμές: λίστα γραμμών, η καθεμία λίστα (λέξη, στυλ, x)."""
    set_run(pdf, "", size)
    space = pdf.get_string_width(" ")
    lines, line, used = [], [], 0.0
    pending = False
    for run_text, style in runs(text):
        parts = run_text.split(" ")
        for i, word in enumerate(parts):
            if i:
                pending = True
            if not word:
                continue
            set_run(pdf, style, size)
            w = pdf.get_string_width(word)
            gap = space if pending and line else 0.0
            if line and used + gap + w > width:
                lines.append(line)
                line, used, gap = [], 0.0, 0.0
            line.append((word, style, used + gap))
            used += gap + w
            pending = False
    if line:
        lines.append(line)
    return lines or [[]]


def draw_lines(pdf, lines, x, y, size, leading):
    for k, line in enumerate(lines):
        for word, style, dx in line:
            set_run(pdf, style, size)
            pdf.set_xy(x + dx, y + k * leading)
            pdf.cell(pdf.get_string_width(word), leading, word)


def flow(pdf, text, size=10.0, leading=5.0, x=MARGIN, width=TEXT_W, color=INK):
    lines = lay_out(pdf, text, size, width)
    pdf.set_text_color(*color)
    for line in lines:
        if pdf.get_y() + leading > pdf.h - MARGIN - 6:
            pdf.add_page()
        draw_lines(pdf, [line], x, pdf.get_y(), size, leading)
        pdf.set_y(pdf.get_y() + leading)


def heading(pdf, level, text):
    size = {1: 30.0, 2: 15.0, 3: 11.5}[level]
    if level > 1:
        pdf.ln(5)
        if pdf.get_y() > 235:           # όχι επικεφαλίδα μόνη της στο τέλος της σελίδας
            pdf.add_page()
    pdf.set_font("dv", "B", size)
    pdf.set_text_color(*(HEAD if level < 3 else INK))
    pdf.set_x(MARGIN)
    pdf.multi_cell(TEXT_W, size * 0.5, text, new_x="LMARGIN", new_y="NEXT")
    pdf.ln(2)


def picture(pdf, alt, path, width=125.0):
    with Image.open(path) as im:
        h = width * im.height / im.width
    if pdf.get_y() + h + 10 > pdf.h - MARGIN - 6:
        pdf.add_page()
    pdf.image(path, MARGIN + (TEXT_W - width) / 2, pdf.get_y(), width, h)
    pdf.set_y(pdf.get_y() + h + 1.5)
    pdf.set_font("dv", "I", 8.5)
    pdf.set_text_color(*SUB)
    pdf.cell(TEXT_W, 4.5, alt, align="C")
    pdf.ln(7)


def code_block(pdf, lines):
    pdf.set_font("dvm", "", 10)
    pdf.set_fill_color(*TINT)
    pdf.set_text_color(*INK)
    for line in lines:
        pdf.set_x(MARGIN)
        pdf.cell(TEXT_W, 6, "   " + line, fill=True)
        pdf.ln(6)
    pdf.ln(3)


def table(pdf, rows, base):
    size, leading = 9.0, 4.5
    n = len(rows[0])
    plain = [[LINK.sub(r"\1", re.sub(r"\*\*|\*|`", "", c)) for c in r] for r in rows]
    want = []
    for c in range(n):
        if all(PICTURE.match(r[c]) or not r[c] for r in rows):
            want.append(None)           # εικόνα: το πλάτος της από το μεγαλύτερο
            continue
        pdf.set_font("dv", "B", size)
        full = max(pdf.get_string_width(r[c]) for r in plain)
        longest = max(pdf.get_string_width(word) for r in plain for word in r[c].split() or [""])
        want.append((full + 5, longest + 5))
    icon_k = {}
    for c in range(n):
        if want[c] is None:
            sizes = [Image.open(os.path.join(base, PICTURE.match(r[c]).group(2))).size
                     for r in rows if PICTURE.match(r[c])]
            icon_k[c] = min(0.09, 13.0 / max(max(z) for z in sizes))    # mm ανά pixel του PNG
            want[c] = max(z[0] for z in sizes) * icon_k[c] + 4
    fixed = sum(w for w in want if not isinstance(w, tuple))
    free = TEXT_W - fixed
    tuples = [w for w in want if isinstance(w, tuple)]
    total = sum(t[0] for t in tuples)
    if total <= free:
        spare = free - total
        widths = [w if not isinstance(w, tuple) else w[0] + spare * w[0] / total for w in want]
    else:
        floor = sum(t[1] for t in tuples)
        extra = max(0.0, free - floor)
        room = sum(t[0] - t[1] for t in tuples) or 1.0
        widths = [w if not isinstance(w, tuple) else w[1] + extra * (w[0] - w[1]) / room for w in want]
    for i, row in enumerate(rows):
        cells, height = [], 0.0
        for c, cell in enumerate(row):
            m = PICTURE.match(cell)
            if m:
                path = os.path.join(base, m.group(2))
                with Image.open(path) as im:
                    w, h = im.width * icon_k[c], im.height * icon_k[c]
                cells.append(("img", path, w, h))
                height = max(height, h + 2)
            else:
                text = "**%s**" % cell if i == 0 and cell else cell
                lines = lay_out(pdf, text, size, widths[c] - 4)
                cells.append(("text", lines))
                height = max(height, len(lines) * leading + 2.4)
        if pdf.get_y() + height > pdf.h - MARGIN - 6:
            pdf.add_page()
        top, x = pdf.get_y(), MARGIN
        if i == 0:
            pdf.set_fill_color(*TINT)
            pdf.rect(MARGIN, top, TEXT_W, height, "F")
        pdf.set_text_color(*INK)
        for c, cell in enumerate(cells):
            if cell[0] == "img":
                pdf.image(cell[1], x + (widths[c] - cell[2]) / 2, top + (height - cell[3]) / 2, cell[2], cell[3])
            else:
                draw_lines(pdf, cell[1], x + 2, top + 1.2, size, leading)
            x += widths[c]
        pdf.set_draw_color(*RULE)
        pdf.set_line_width(0.2)
        pdf.line(MARGIN, top + height, MARGIN + TEXT_W, top + height)
        pdf.set_y(top + height)
    pdf.ln(4)


def render(src, dst):
    base = os.path.dirname(src)
    lines = open(src, encoding="utf-8").read().split("\n")
    pdf = Manual(lines[0].lstrip("# ").strip())
    pdf.add_page()
    i = 0
    while i < len(lines):
        line = lines[i]
        s = line.strip()
        if not s:
            i += 1
        elif s.startswith("#"):
            level = len(s) - len(s.lstrip("#"))
            heading(pdf, level, s[level:].strip())
            i += 1
        elif PICTURE.match(s):
            m = PICTURE.match(s)
            picture(pdf, m.group(1), os.path.join(base, m.group(2)))
            i += 1
        elif line.startswith("    "):
            block = []
            while i < len(lines) and lines[i].startswith("    "):
                block.append(lines[i][4:])
                i += 1
            code_block(pdf, block)
        elif s.startswith("|"):
            rows = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                cells = [c.strip() for c in lines[i].strip().strip("|").split("|")]
                if not all(c and set(c) <= set("-: ") for c in cells):
                    rows.append(cells)
                i += 1
            table(pdf, rows, base)
        elif s.startswith("- "):
            while i < len(lines) and lines[i].strip().startswith("- "):
                y = pdf.get_y()
                pdf.set_font("dv", "", 10)
                pdf.set_text_color(*INK)
                pdf.set_xy(MARGIN + 2, y)
                pdf.cell(4, 5, "•")
                pdf.set_y(y)
                flow(pdf, lines[i].strip()[2:], x=MARGIN + 6, width=TEXT_W - 6)
                pdf.ln(0.8)
                i += 1
            pdf.ln(2)
        else:
            flow(pdf, s)
            pdf.ln(2.5)
            i += 1
    pdf.output(dst)
    print("%s: %d σελίδες" % (os.path.relpath(dst, ROOT), pdf.page_no()))


def main():
    make_images()
    for name in ("manual-en", "manual-el"):
        render(os.path.join(DOCS, name + ".md"), os.path.join(DOCS, name + ".pdf"))


if __name__ == "__main__":
    main()
