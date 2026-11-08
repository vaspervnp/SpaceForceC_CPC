# Space Force C — TODO / Milestones

Πηγή: [design_document.md](design_document.md)
Στόχος: Amstrad CPC 6128 (128K), Mode 0 (160x200, 16 χρώματα), 25 FPS, double buffering, κίνηση ανά 2 pixel.

## Toolchain

| Εργαλείο | Χρήση |
|---|---|
| `rasm` (v3.2.5, `/usr/local/bin/rasm`) | Assembler Z80, crunchers (ZX0/Shrinkler κλπ), `BUILDSNA` για γρήγορο testing |
| `iDSK` (v0.20, `/usr/local/bin/iDSK`) | Προσθήκη αρχείων και έλεγχος της δισκέτας (η δισκέτα δημιουργείται από το rasm, δες M0) |
| Extended DSK (EDSK) | Τελικό format δισκέτας (`SpaceForceC.dsk`) |
| Caprice32 (snap, μέσω `tools/cap32.sh`) | Κύριος emulator για testing/debug |
| CPCemu | Δεύτερος emulator για cross-check (δεν βρέθηκε στο PATH — να επιβεβαιωθεί η εντολή εκκίνησης) |
| Aseprite MCP | Pixel art: sprites, tiles, fonts, HUD, οθόνες, με παλέτα CPC |
| Blender MCP | 3D μοντέλα (πλοίο, bosses, asteroids) → render σε πολλές γωνίες → βάση για τα sprites στο Aseprite |

---

## M0 — Υποδομή project & build pipeline
**Έγινε.** `make` → `build/SpaceForceC.dsk`, `make shot` → screenshot από Caprice32.
- [x] Δομή φακέλων: `src/` (Z80), `assets/` (τέχνη και δεδομένα, από το M1), `tools/` (scripts), `build/` (εκτός git)
- [x] `.gitignore` (build/, `*:Zone.Identifier`)
- [x] `Makefile`: `make` → rasm → EDSK → iDSK (loader + έλεγχος)
- [x] **Extended DSK**: το iDSK v0.20 γράφει μόνο standard (`MV - CPCEMU`) σε νέα δισκέτα. Τη δισκέτα τη δημιουργεί το rasm (`save ...,DSK,...`) σε EDSK με AMSDOS header· το iDSK προσθέτει αρχεία **κρατώντας** το EDSK. Το Makefile ελέγχει το header σε κάθε build
- [x] `make run` → Caprice32 με autorun (`run"disc`), `make snap` / `make run-snap` → snapshot. Το rasm θέλει `-v2`: το Caprice32 4.6 απορρίπτει το v3 snapshot του rasm («zero size»)
- [x] `make shot` → Caprice32 χωρίς παράθυρο, `build/screenshot.png` (`tools/cap32_shot.sh`)
- [x] Hello world (`src/main.asm`): Mode 0, παλέτα μέσω gate array, φόντο από πλακίδια, οι 16 όψεις του σκάφους, κείμενο με τη γραμματοσειρά, περιστρεφόμενο σκάφος πάνω από το φόντο στα 25 FPS
- [x] Loader: `DISC.BAS` (`RUN"SFC.BIN"`)· το `SFC.BIN` φορτώνει και ξεκινάει στο `&1000`
- [ ] `make run-cpcemu`: ο στόχος υπάρχει, αλλά το CPCemu δεν βρέθηκε στο PATH (`make run-cpcemu CPCEMU=/path/to/cpcemu`)

Ευρήματα για το Caprice32 του snap:
- Ο `caprice32.launcher` περνάει μόνο τα δύο πρώτα ορίσματα ως δισκέτες και **πετάει** τα `-O`/`-a`. Το `tools/cap32.sh` καλεί το `cap32` απευθείας μέσα στο snap
- Το autotype (`-a`) περιμένει να **διαβαστεί** το πληκτρολόγιο. Ένα πρόγραμμα που κλείνει το firmware και δεν διαβάζει πλήκτρα το παγώνει, άρα και το screenshot. Γι' αυτό το `read_keys` τρέχει σε κάθε καρέ από τώρα

## M1 — Pipeline γραφικών (Aseprite / Blender → CPC)
**Σε μεγάλο βαθμό έτοιμο: δες [assets/README.md](assets/README.md).**
19,7 KB τέχνης για το Level 1, με επαληθευμένα δεδομένα και μακέτα οθόνης.
- [x] Παλέτα 16 pens — **μία για τους δύο κόσμους**, όχι ανά world: το σκάφος, τα βλήματα, οι εκρήξεις και το HUD εμφανίζονται και στις οκτώ πίστες (`assets/palette.gpl`, `assets/data/palette.asm`)
- [x] Κωδικοποιητής Mode 0 με αντίστροφο και ισχυρισμό σε όλες τις 256 τιμές (`assets/src/cpcimg.py`), μάσκα πλεγμένη `mask,data`
- [x] Format sprite — **12x24 και όχι 24x24**: στο Mode 0 το pixel είναι διπλάσια φαρδύ, άρα 24x24 pixels = 48x24 μονάδες και ένα σκάφος που στρίβει δεν χωράει. Δες το σκεπτικό στο assets/README.md
- [x] Format tiles: 8x8 **αδιαφανή** (32 bytes, `LDI`), 16 τύποι = ένα nibble
- [ ] Αν θέλεις Aseprite/Blender για μεγάλα αντικείμενα (bosses 64x64+): το `palette.gpl` είναι έτοιμο preset
- [ ] Ενσωμάτωση στο Makefile (αλλαγή στο `assets/src` → αυτόματο rebuild)
- [ ] Blender: setup σκηνής μόνο για μεγάλα αντικείμενα — σε 12x24 pixels δεν υπάρχει τίποτα να μοντελοποιήσεις, κάθε pixel είναι απόφαση

## M2 — Engine core
- [ ] Memory map 128K: δύο screen buffers (π.χ. `&C000` και `&4000`), code, bank switching (`&7Fxx`) για levels/γραφικά
- [ ] Interrupt handler (300Hz), συγχρονισμός με VSYNC, frame lock 25 FPS (κάθε 2 frames)
- [ ] Double buffering: swap visible/back buffer μέσω CRTC R12/R13 στο VSYNC
- [ ] Ρύθμιση CRTC για game area + HUD (πιθανή μείωση πλάτους οθόνης για ταχύτητα)
- [ ] Ανάγνωση πληκτρολογίου/joystick μέσω PPI/PSG (redefinable keys)
- [ ] Πίνακας διευθύνσεων γραμμών οθόνης (lookup table) για γρήγορη πρόσβαση
- [ ] Profiling: raster bars (αλλαγή border color) για μέτρηση χρόνου ανά υποσύστημα

## M3 — Multi-directional scrolling (τεχνική απόφαση + υλοποίηση)
**ΜΕΤΡΗΜΕΝΟ: το software redraw είναι ήδη εκτός.** Πλήρες ξαναζωγράφισμα
20x18 πλακιδίων = 57,6 ms, δηλαδή **144 % του καρέ** στα 25 FPS, πριν μπει
ένα μόνο sprite (`LDI` = 5 µs/byte στον CPC). Δες τον πίνακα στο
[assets/README.md](assets/README.md).
- [x] ~~Spike: hardware scroll vs software tile redraw~~ — το δεύτερο δεν χωράει· μένει hardware scroll με ξαναζωγράφισμα μόνο της νέας στήλης/γραμμής (20 πλακίδια = 3,2 ms) συν dirty tiles
- [ ] Απόφαση για ομαλό scroll ανά 2 pixel (π.χ. δύο εκδόσεις tiles με offset, ή R3/R5 tricks για fine scroll)
- [ ] Tilemap engine: σχεδίαση μόνο των νέων στηλών/γραμμών που εμφανίζονται
- [ ] Διαχείριση wrap-around της video memory (όριο 16K / 2K CRTC)
- [ ] Συνδυασμός scroll + double buffering χωρίς flicker και tearing
- [ ] Camera που ακολουθεί το πλοίο, όρια level

## M4 — Sprite engine
- [ ] Masked sprite blit 24x24 (byte-aligned λόγω κίνησης ανά 2 pixel = 1 byte Mode 0)
- [ ] Erase/restore background (save-under ή redraw από tilemap) ανά buffer
- [ ] Sprite list με προτεραιότητες, clipping στα άκρα
- [ ] Budget: μέγιστος αριθμός sprites ανά frame στα 25 FPS
- [ ] Μικρά sprites για σφαίρες/particles (π.χ. 4x4, 8x8)

## M5 — Το πλοίο: The Flying Patates
- [ ] Blender: μοντέλο πλοίου, δύο παραλλαγές πτερυγίων (Space / Earth)
- [ ] Render 8 κατευθύνσεων + tilted frames για απότομες στροφές → Aseprite cleanup → 24x24 sprites
- [ ] Κίνηση 8 κατευθύνσεων με αδράνεια, ταχύτητα 2 pixel/frame
- [ ] Εναλλαγή Space/Earth sprite set ανά world
- [ ] Earth: particles μαύρου καπνού από την εξάτμιση
- [ ] Animation "κραυγής" πιλότων στις απότομες στροφές (μήνυμα στο HUD/ήχος)

## M6 — Όπλα παίκτη
- [ ] Σύστημα projectiles (pool, κίνηση, collision, lifetime)
- [ ] **Disco-Ray**: δέσμη neon, εχθροί "χορεύουν Macarena" (animation) πριν σκάσουν
- [ ] **Mega-Baguette Launcher**: διαπεραστικά βλήματα (pierce shields)
- [ ] **Sneeze Cannon**: spray πράσινων particles με recoil στο πλοίο
- [ ] Εναλλαγή όπλων + ένδειξη στο HUD
- [ ] Upgrades: double/triple baguette gun

## M7 — Εχθροί & εχθρικά όπλα
- [ ] Σύστημα εχθρών: spawn από δεδομένα level, AI patterns (ευθεία, κύκλος, κυνηγητό, formation)
- [ ] Collision detection (bounding box, ενδεχομένως grid partitioning)
- [ ] **Laser Spaghetti**: τυλίγει το πλοίο → προσωρινή μείωση ταχύτητας
- [ ] **Bureaucracy Beam**: έντυπα Ε9 στο παρμπρίζ → τύφλωση (μερική κάλυψη οθόνης)
- [ ] **Bad Breath Torpedoes**: zigzag κίνηση υψηλής ταχύτητας
- [ ] Εκρήξεις, ζημιά, ζωές, invulnerability μετά από hit
- [ ] Εχθροί αφήνουν "κλεμμένα μυρμήγκια" (collectibles)

## M8 — Power-ups & upgrades
- [ ] **Shield Bubble Wrap**: ασπίδα + ήχος "pop" όταν σπάει
- [ ] **Espresso Boost**: προσωρινή αύξηση ταχύτητας (+ γρήγορα μηνύματα πιλότων)
- [ ] **Ant-Magnet**: αυτόματη έλξη μυρμηγκιών για bonus
- [ ] Engine upgrade, αυτόματος ψεκαστήρας εντομοκτόνου
- [ ] Drop tables και ισορροπία

## M9 — HUD & UI
- [ ] HUD: score, ζωές, όπλο, power-ups, μετρητής μυρμηγκιών, boss health
- [ ] Bitmap font Mode 0 (Aseprite)
- [ ] Title screen, μενού (start, redefine keys, high scores)
- [ ] Pause, Game Over, Level Complete
- [ ] High score table (αποθήκευση στη δισκέτα — προαιρετικό)

## M10 — Ήχος & μουσική (AY-3-8912)
- [ ] Επιλογή player (π.χ. Arkos Tracker 2 / AKG ή AKY player, συμβατός με rasm)
- [ ] SFX engine: πυροβολισμοί, εκρήξεις, "pop" bubble wrap, φτάρνισμα, power-up
- [ ] Μουσική: title, Space world, Earth world, boss, ending
- [ ] Μίξη SFX πάνω σε μουσική χωρίς να ξεπερνιέται το frame budget

## M11 — Level system & loading
- [ ] Format δεδομένων level: tilemap, tileset, παλέτα, spawn list, boss
- [ ] Συμπίεση (ZX0 ή άλλο cruncher του rasm) + decrunch στη μνήμη
- [ ] Loader από δισκέτα ανά level (AMSDOS/firmware ή custom loader), χρήση των 64K επιπλέον RAM
- [ ] Οθόνη μετάβασης level με χιουμοριστικό κείμενο
- [ ] Level editor ή χρήση Tiled/Aseprite tilemap + converter

## M12 — Vertical slice: Level 1
- [ ] **Level 1: The Asteroid Belt of Lost Luggage** — βαλίτσες/κάλτσες asteroids (Blender → sprites/tiles)
- [ ] Πλήρες gameplay loop: start → level → boss → level complete
- [ ] **Boss: Lord Garbage-Can** — πετάει παλιό Amstrad hardware, patterns επίθεσης, health bar
- [ ] Playtest, μέτρηση performance (σταθερά 25 FPS), διορθώσεις
- [ ] Έλεγχος σε Caprice32 **και** CPCemu

## M13 — World A: Space (Levels 2–4)
- [ ] **Level 2: The Nebula of Bureaucracy** — σταθμοί με ουρές και σφραγίδες · Boss: **The Grand Inspector** (σφραγίδα "REJECTED")
- [ ] **Level 3: Galaxy's Trashcan City** — διαστημικά σκουπίδια, παλιές κονσόλες · Boss: **Mecha-Trashcan 3000** (ρομπότ από δισκέτες)
- [ ] **Level 4: The Lunar Ant-Hill** — σήραγγες μυρμηγκιών στη Σελήνη · Boss: **General Formix** (μυρμήγκι με κράνος και γυαλιά)

## M14 — World B: Earth (Levels 5–8)
- [ ] Earth mode: ατμόσφαιρα, πτερύγια, καπνός, νέα παλέτα/tilesets
- [ ] **Level 5: Traffic on Attiki Odos** — ουρανοξύστες, neon, ιπτάμενα αυτοκίνητα · Boss: **The Undefeated Toll Booth** (κέρματα, μπάρες)
- [ ] **Level 6: The Underground Tunnels (Megara)** — σπηλιές, ρίζες, γιγάντια μυρμήγκια · Boss: **Queen Ant-Zilla**
- [ ] **Level 7: The Acropolis Parking Lot** — μνημεία, τουρίστες με κάμερες · Boss: **Parthenon-Bot 2.0** (ναός → Transformer)
- [ ] **Level 8: The Mothership's Kitchen** — κατσαρόλες Mirmikochai · Boss: **Chef Xylokorinthos** (6 χέρια, σούπες, τηγάνια)

## M15 — Ιστορία & cutscenes
- [ ] Intro: Space Force, δηλητηρίαση από διαστημικό μουσακά, Wing C
- [ ] Εξήγηση πλοκής: Katsarophobians, Mirmikochai, αυπνία Αυτοκράτορα
- [ ] Ending: μυρμήγκια σχηματίζουν "THANK YOU WING C (YOU ALMOST MESSED IT UP)", "προαγωγή" στις τουαλέτες
- [ ] Credits

## M16 — Polish, balancing & release
- [ ] Καμπύλη δυσκολίας, scoring, extra lives
- [ ] Βελτιστοποιήσεις (σταθερά 25 FPS σε όλα τα levels με το μέγιστο πλήθος sprites)
- [ ] Έλεγχος σε CPC 6128 (και αν γίνεται 464 + 64K expansion)
- [ ] Τελικό `SpaceForceC.dsk` σε Extended DSK format, έλεγχος σε Caprice32 και CPCemu
- [ ] README: build οδηγίες, χειρισμός, credits
- [ ] (Προαιρετικό) Loading screen, cassette version, έκδοση με 2 δισκέτες αν δεν χωράει σε μία
