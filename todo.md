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
| CPCEMU 2.5 (Linux, μέσω `tools/cpcemu.sh`) | Δεύτερος emulator για cross-check |
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
- [x] `make run-cpcemu`: CPCEMU 2.5 για Linux όπως στο V-OS-CPC (`tools/cpcemu.sh`): αποσυμπιέζεται από το tarball στο `build/cpcemu`, CPC 6128 με τη δισκέτα στο A: και autostart. Ξεκινάει, αλλά το παράθυρό του δεν πιάνεται σε screenshot, οπότε η εικόνα ελέγχεται με το μάτι

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
**Έγινε.** Demo: το σκάφος οδηγείται πάνω από το φόντο στα 25 FPS, με double buffering, και το HUD δείχνει τα καρέ και πόσα άργησαν.
- [x] Memory map 128K: **οθόνες στα `&8000` και `&C000`**, όχι `&4000`. Το `&4000-&7FFF` είναι το μόνο παράθυρο όπου μπαίνουν τα επιπλέον 64K (`&7FC4-&7FC7`), άρα μένει για τα δεδομένα των levels. Κώδικας + μόνιμα δεδομένα `&1000-&3FFF` (12K, με assert), stack κάτω από το `&1000`. Δες την κεφαλίδα του `src/main.asm`
- [x] Interrupt handler IM 1 (300Hz) που μετράει μόνο τα VSYNC· frame lock 25 FPS (`FRAME_VBLS`)
- [x] Double buffering: το `flip` γράφει τη σελίδα στο R12 αμέσως μετά το VSYNC (το R12 κλειδώνει στην αρχή του καρέ, ~8 σειρές αργότερα). Αν το καρέ αργήσει, περιμένει το επόμενο VSYNC αντί να γράψει σε ό,τι εμφανίζεται, και μετράει `late_frames`
- [x] Πληκτρολόγιο/joystick μέσω PPI/PSG σε ενέργειες (`IN_UP`...`IN_PAUSE`), με κρατημένα και «μόλις πατήθηκαν». Κέρσορες/QAOP/Space, W όπλο, ESC παύση, joystick 0. Οι αντιστοιχίσεις είναι στη RAM (`key_bindings`) για το μενού του M9
- [x] Πίνακας διευθύνσεων γραμμών με offsets ως προς τη σελίδα: H = offset OR σελίδα, ίδια ρουτίνα για τις δύο
- [x] Profiling: `make PROFILE=1` αλλάζει το border ανά φάση (πράσινο είσοδος/λογική, μπλε σβήσιμο, κόκκινο sprites, κίτρινο HUD, μαύρο αναμονή)
- [x] Σβήσιμο sprite με επαναφορά των πλακιδίων κάτω του (`restore_rect`), ξεχωριστή θέση ανά σελίδα
- [ ] Ρύθμιση CRTC για game area + HUD: μένει η standard 80x25. Το πλάτος και το R12/R13 offset αποφασίζονται στο M3 μαζί με το hardware scroll
- [ ] Ο χρόνος κάθε φάσης σε αριθμούς: τα raster bars δείχνουν μόνο ό,τι πέφτει στο ορατό border. Η δουλειά αρχίζει στο VSYNC, άρα οι πρώτες ~40 γραμμές του καρέ δεν φαίνονται

Ευρήματα:
- Η ταχύτητα του σκάφους είναι 1 byte (2 pixels) οριζόντια και **4 γραμμές** κάθετα. Στο Mode 0 το pixel είναι 2:1, άρα 2 pixels οριζόντια = 4 μονάδες = 4 γραμμές, και η διαγώνιος βγαίνει στις 45 μοίρες στην οθόνη
- Το HUD με 10 ψηφία ανά καρέ (`print_u16`: σβήσιμο + masked γλύφος) είναι η πιο αργή φάση στα raster bars. Στο M9 το HUD πρέπει να ξαναγράφει μόνο ό,τι άλλαξε, και μόνο στις δύο σελίδες τη φορά
- Τα πλήκτρα διαβάζονται στο main loop. Όταν μπει ο music player στο interrupt (M10), η ανάγνωση πρέπει να πάει κι αυτή εκεί, γιατί μοιράζονται το PSG

## M3 — Multi-directional scrolling
**Έγινε.** Hardware scroll σε χάρτη 64x48 πλακιδίων, με την κάμερα να ακολουθεί το σκάφος, και HUD σε split screen από κάτω. Ελέγχεται από το `make test` (headless CPC, `CRTC=0/1/2`): 9 σενάρια κίνησης, η οθόνη συγκρίνεται κελί-κελί με τον χάρτη, 0 καρέ αργά. **Χειρότερο καρέ 27 ms** από τα 40 (διαγώνια κίνηση + HUD).
- [x] ~~Spike: hardware scroll vs software tile redraw~~: το δεύτερο δεν χωράει (57,6 ms)
- [x] **Βήμα scroll: 1 word οριζόντια (4 pixels) και 1 σειρά κάθετα (8 γραμμές)**. Στο Mode 0 και τα δύο είναι 8 μονάδες οθόνης, άρα το βήμα είναι ίδιο στους δύο άξονες. Το σκάφος κινείται ανά 2 pixels πάνω στη σκηνή, ομαλά· μόνο το φόντο πηγαίνει ανά βήμα. Το fine scroll (R3 για μισό word οριζόντια, rupture/R5 για γραμμές κάθετα) εξαρτάται από τον τύπο του CRTC και μένει ανοιχτό
- [x] Σταθερή διεύθυνση ανά κελί κόσμου: `MA = (wy*40 + wx) mod 1024`. Σε κάθε βήμα ζωγραφίζεται μόνο η νέα στήλη (25 μισά πλακίδια) ή σειρά (40) (`src/scroll.asm`)
- [x] Wrap-around: κάθε γραμμή raster είναι δαχτυλίδι 2K· οι στήλες/σειρές και τα sprites διορθώνουν τη διεύθυνση όταν περνάνε το `#x7FF`
- [x] Scroll + double buffering: κάθε σελίδα έχει τη δική της κάμερα και καλύπτει τη διαφορά των δύο καρέ όταν έρθει η σειρά της (πρώτα στήλες, μετά σειρές)
- [x] Κάμερα με νεκρή ζώνη (24 bytes / 64 γραμμές), ένα βήμα το πολύ ανά άξονα, όρια χάρτη
- [x] Ταχύτητα: μισά πλακίδια προ-αναδιαταγμένα σε 16 συνεχόμενα bytes και αντιγραφή με `POP` (13 µs/γραμμή αντί για 22)· στήλες και σειρές προχωράνε σταδιακά αντί να ξαναϋπολογίζουν διεύθυνση. Χειρότερο καρέ: 32 → 24 ms
- [x] **HUD με split screen** (`src/hw.asm`): δύο «καρέ» του CRTC ανά καρέ των 50 Hz. Το παιχνίδι είναι 21 σειρές με το R12/R13 της κάμερας, το HUD 4 σειρές με σταθερή διεύθυνση. Τα R4/R6/R7/R12/R13 γράφονται από τα interrupts 0, 2 και 5 του καρέ (γραμμές 242, 34, 190) και το VSYNC μένει στη γραμμή 240. Ελεγμένο σε CRTC 0/1/2 (headless) και στο Caprice32
- [x] Το HUD ζει στη φυσική σελίδα `&4000` (MA 864-1023, τα τελευταία 320 bytes κάθε block): το video διαβάζει πάντα την κύρια μνήμη, άρα φαίνεται και όταν η CPU έχει άλλο bank στο `&4000`. Δεν κυλάει, δεν έχει double buffer
- [ ] Ο CRTC 3/4 (6128 Plus) δεν έχει δοκιμαστεί
- [ ] Πραγματικοί χάρτες ανά πίστα (M11)· τώρα ένας δοκιμαστικός από `src/map.asm`

Ευρήματα:
- Στο χειρότερο καρέ ζωγραφίζονται 81 μισά πλακίδια: στήλη 25 + σειρά 40 + **16 μόνο για να σβηστεί το σκάφος**. Το save-under στο M4 γλιτώνει τα 16 (~4 ms)
- Το `copy_half` κάνει `EI`: ο interrupt handler πρέπει να έχει μπει πριν από την πρώτη ζωγραφική
- **Το R6 του καρέ A γράφεται μέσα στο B** (στο VSYNC): ο CRTC σβήνει την εικόνα όταν ο μετρητής σειρών συναντήσει το R6, και δεν την ξανανάβει ως το επόμενο καρέ. Γραμμένο στη γραμμή 34 του A, ερχόταν αφού είχε περάσει η σειρά 4 (το R6 του HUD) και έδειχνε μόνο 4 σειρές παιχνιδιού
- Το HUD γράφεται αδιαφανές (μόνο τα bytes δεδομένων του γλύφου, πάνω σε μαύρο) σε όρια σειράς: ~0,3 ms ο χαρακτήρας. Ανανεώνεται μία φορά ανά 16 καρέ (~10 ms τότε). Στο M9 πρέπει να γράφει μόνο ό,τι αλλάζει
- **Μνήμη: γεμάτη.** Κώδικας έως `&330A`, χάρτης 3K έως `&4000`: μένουν ~140 bytes για κώδικα πριν μετακινηθεί ο χάρτης. Τα μισά πλακίδια μπήκαν στο `&4000`. Επόμενο βήμα: ο χάρτης στο `&4000-&7FFF` (εκτός HUD) ή σε bank, και τα γραφικά των εχθρών/βλημάτων θα χρειαστούν δικό τους χώρο

## M4 — Sprite engine
- [ ] Masked sprite blit 24x24 (byte-aligned λόγω κίνησης ανά 2 pixel = 1 byte Mode 0)
- [ ] Erase/restore background ανά buffer: τώρα με redraw από τον χάρτη (`restore_world_rect`, ως 16 μισά πλακίδια για το σκάφος ≈ 4 ms). **Save-under** (144 bytes για το σκάφος) θα το έριχνε κάτω από 1 ms
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
