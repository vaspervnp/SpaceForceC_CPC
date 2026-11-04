# Space Force C — TODO / Milestones

Πηγή: [design_document.md](design_document.md)
Στόχος: Amstrad CPC 6128 (128K), Mode 0 (160x200, 16 χρώματα), 25 FPS, double buffering, κίνηση ανά 2 pixel.

## Toolchain

| Εργαλείο | Χρήση |
|---|---|
| `rasm` (v3.2.5, `/usr/local/bin/rasm`) | Assembler Z80, crunchers (ZX0/Shrinkler κλπ), `BUILDSNA` για γρήγορο testing |
| `iDSK` (v0.20, `/usr/local/bin/iDSK`) | Δημιουργία/διαχείριση DSK, εισαγωγή αρχείων με AMSDOS header (`-n`, `-i`, `-t 1 -c -e`) |
| Extended DSK (EDSK) | Τελικό format δισκέτας (`SpaceForceC.dsk`) |
| Caprice32 (snap, `caprice32.launcher`) | Κύριος emulator για testing/debug |
| CPCemu | Δεύτερος emulator για cross-check (δεν βρέθηκε στο PATH — να επιβεβαιωθεί η εντολή εκκίνησης) |
| Aseprite MCP | Pixel art: sprites, tiles, fonts, HUD, οθόνες, με παλέτα CPC |
| Blender MCP | 3D μοντέλα (πλοίο, bosses, asteroids) → render σε πολλές γωνίες → βάση για τα sprites στο Aseprite |

---

## M0 — Υποδομή project & build pipeline
- [ ] Δομή φακέλων: `src/`, `gfx/` (πηγές Aseprite/Blender), `data/` (εξαγόμενα binaries), `tools/`, `build/`
- [ ] `.gitignore` (build/, `*:Zone.Identifier`, temp αρχεία)
- [ ] `Makefile`: `make` → rasm → binaries → iDSK → `build/SpaceForceC.dsk`
- [ ] Επιβεβαίωση ότι το παραγόμενο DSK είναι **Extended DSK** (header `EXTENDED CPC DSK File`); αν το iDSK γράφει standard, χρήση του rasm `SAVE ...,DSK,...` (γράφει EDSK) ή script μετατροπής
- [ ] `make run` → Caprice32 με autorun (`run"SFC`), `make snap` → rasm `BUILDSNA` για άμεσο load χωρίς δισκέτα
- [ ] `make run-cpcemu` για cross-check
- [ ] Hello world: Mode 0, ορισμός παλέτας, εμφάνιση ενός pixel/byte στην οθόνη, εκκίνηση από δισκέτα
- [ ] Βασικός BASIC loader (`SFC.BAS`) ή binary loader με `MEMORY` / `LOAD` / `CALL`

## M1 — Pipeline γραφικών (Aseprite / Blender → CPC)
- [ ] Παλέτα CPC 27 χρωμάτων στο Aseprite (preset) + επιλογή των 16 χρωμάτων του παιχνιδιού (ανά world μπορεί να αλλάζει)
- [ ] Converter (`tools/`, Python): PNG indexed → Mode 0 byte layout (2 pixels/byte, interleaved bits) + mask
- [ ] Format sprite: 24x24 = 12 bytes x 24 γραμμές (+ mask ή transparent color)
- [ ] Format tiles: π.χ. 8x8 ή 16x16 pixels, tileset + tilemap export
- [ ] Blender: setup σκηνής (ορθογραφική κάμερα, flat/toon shading, χαμηλή ανάλυση render, χωρίς antialiasing)
- [ ] Blender → render 8 γωνιών → Aseprite: quantize στην παλέτα CPC, χειροκίνητο cleanup
- [ ] Ενσωμάτωση converter στο Makefile (αλλαγή στο gfx → αυτόματο rebuild)

## M2 — Engine core
- [ ] Memory map 128K: δύο screen buffers (π.χ. `&C000` και `&4000`), code, bank switching (`&7Fxx`) για levels/γραφικά
- [ ] Interrupt handler (300Hz), συγχρονισμός με VSYNC, frame lock 25 FPS (κάθε 2 frames)
- [ ] Double buffering: swap visible/back buffer μέσω CRTC R12/R13 στο VSYNC
- [ ] Ρύθμιση CRTC για game area + HUD (πιθανή μείωση πλάτους οθόνης για ταχύτητα)
- [ ] Ανάγνωση πληκτρολογίου/joystick μέσω PPI/PSG (redefinable keys)
- [ ] Πίνακας διευθύνσεων γραμμών οθόνης (lookup table) για γρήγορη πρόσβαση
- [ ] Profiling: raster bars (αλλαγή border color) για μέτρηση χρόνου ανά υποσύστημα

## M3 — Multi-directional scrolling (τεχνική απόφαση + υλοποίηση)
- [ ] Spike: hardware scroll (CRTC R12/R13, βήμα 4 pixel οριζόντια / 8 γραμμές κάθετα) vs software tile redraw vs υβριδικό
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
