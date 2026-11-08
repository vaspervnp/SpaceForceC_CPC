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
- Μνήμη: γέμισε εδώ (κώδικας + χάρτης ως `&4000`)· λύθηκε στο M4 με τα γραφικά του κόσμου στο bank 4

## M4 — Sprite engine
**Έγινε.** `src/sprites.asm`: λίστα 16 sprites σε συντεταγμένες κόσμου, clip στην κάμερα, save-under ανά σελίδα. Demo: 10 εχθροί που αναπηδούν στον κόσμο (`src/actors.asm`) + το σκάφος. Το `make test` ελέγχει ότι δεν μένουν ίχνη: κάθε κελί εκτός από αυτά κάτω από sprites πρέπει να είναι καθαρός χάρτης.
- [x] Μνήμη: **όλα τα γραφικά του κόσμου στο bank 4** (`OUT &7F00,&C4`): χάρτης, μισά πλακίδια, πλακίδια, σκάφος, εχθροί. Το `DISC.BAS` τα φορτώνει (`MEMORY &3FFF` πρώτα: το BASIC δεν κάνει `LOAD` κάτω από το HIMEM). Μόνο για το HUD γυρνάμε σε `&C0`. Η κύρια μνήμη ελευθερώθηκε: κώδικας ως `&22xx`, RAM ως `&34xx`
- [x] Masked blit byte-aligned, με `POP BC` (μάσκα+δεδομένα) και ξεδιπλωμένο βρόχο ανά πλάτος (ως 12 bytes = ο boss): **17 µs/byte μαζί με το save**
- [x] Save-under ανά σελίδα: στοίβα εγγραφών + 2K bytes· επαναφορά με `LDIR` (6 µs/byte) πριν από το scroll, με την κάμερα της σελίδας
- [x] Διεύθυνση και έλεγχος του ορίου των 2K **ανά σειρά χαρακτήρων**, όχι ανά γραμμή: κατέβασε το κόστος ανά γραμμή από ~80 σε ~30 µs
- [x] Clipping στις άκρες της κάμερας (οριζόντια και κάθετα), σειρά σχεδίασης = σειρά στη λίστα (το σκάφος τελευταίο, από πάνω)
- [x] **Budget (μετρημένο):** βάση ~4 ms (είσοδος, κίνηση 10 εχθρών ~2 ms, clip) + scroll 0-20 ms + **~25 µs ανά byte sprite** (blit + save + επαναφορά + γραμμές). Σε διαγώνιο scroll μένουν ~15 ms ≈ **500 bytes sprites**: σκάφος (144) + 3 εχθροί 8x16 (64) + 6 βλήματα 8x8 (32). Ακίνητη κάμερα: ~900 bytes. Με 10 εχθρούς μαζί στην οθόνη (~1000 bytes) το καρέ πάει στα 57 ms
- [ ] Μικρά sprites για σφαίρες/particles: τα `shots` (8x8 = 32 bytes) είναι έτοιμα στα assets, μπαίνουν με το M6
- [ ] Αν χρειαστεί περισσότερος χώρος: sprites πάνω σε κενό φόντο χωρίς save (επαναφορά με μαύρο), εχθροί που κινούνται ανά δύο καρέ, ή στενότερη κάμερα (λιγότερο scroll)

Ευρήματα:
- Το rasm, σε snapshot, ξεκινάει κάθε bank από το **πρώτο** `org` του, όχι από το `org & #3FFF`: το bank 4 θέλει `org #4000` + `ds` ως τα δεδομένα
- Το BASIC δεν κάνει `LOAD` binary κάτω από το HIMEM («Memory full»)· το `RUN"` δεν ελέγχει. Γι' αυτό ο loader ξεκινάει με `MEMORY &3FFF`
- Με το blit σε κατάσταση `POP` για ολόκληρη σειρά (< 1 ms DI), το R6 του HUD μετακινήθηκε στο interrupt της γραμμής 138 (από 190), για περιθώριο 62 γραμμών πριν από τη σειρά 4 του HUD
- Το `make test` μετράει πλέον το καρέ από την έξοδο ως την είσοδο στο `flip`: πριν, τα αργά καρέ (που δεν περνούν από τον βρόχο αναμονής) μετριούνταν μαζί

## M5 — Το πλοίο: The Flying Patates
**Έγινε** (`src/ship.asm`). Τα γραφικά ήταν έτοιμα από το M1 (12x24, 8 κατευθύνσεις x 2 κόσμοι, σε ASCII, όχι Blender).
- [x] ~~Blender / Aseprite για το σκάφος~~: ζωγραφίστηκε σε ASCII (assets/README.md: σε 12x24 κάθε pixel είναι απόφαση)
- [x] Κίνηση 8 κατευθύνσεων **με αδράνεια**: θέσεις σε fixed point (X*16, Y*4), ταχύτητα ως 16 = 1 byte ή 4 γραμμές ανά καρέ (2 pixels και στους δύο άξονες), επιτάχυνση 2. Στον τοίχο του κόσμου η ταχύτητα μηδενίζεται
- [x] Space/Earth: άλλο σετ sprites (+8) και **άλλη τριβή**: 1 στο διάστημα (γλιστράει), 3 στη Γη (η ατμόσφαιρα φρενάρει)
- [x] Φλόγα εξάτμισης: ξεχωριστό sprite 8x8 στο `FLAME_AT` της κατεύθυνσης, πριν από το σκάφος (χώνεται από κάτω), 3 φάσεις, μόνο όσο υπάρχει ώθηση
- [x] Earth: τολύπες καπνού από την ουρά κάθε 6 καρέ, 3 slots, σβήνουν σε 3 φάσεις (18 καρέ)
- [x] Κραυγές πιλότων: στροφή >= 135° γράφει «AAAAAAH!» / «MAMAAA!!» στο HUD για 1 s
- [ ] Ο καπνός είναι navy πάνω στο μαύρο: δεν φαίνεται στο διάστημα (ούτε χρειάζεται εκεί), θα κριθεί πάνω στα φόντα της Γης (M14)
- [ ] Ήχος για τις κραυγές (M10)

Ευρήματα:
- Το κουμπί ενός joystick δεν δίνει πάντα το ίδιο bit (γραμμή 9, bit 4 ή 5): και τα δύο είναι fire, το όπλο αλλάζει με το W
- Το rasm δεν ξεχωρίζει κεφαλαία/πεζά: `smoke_life` (μεταβλητή) και `SMOKE_LIFE` (σταθερά) συγκρούονται

## M6 — Όπλα παίκτη
**Έγινε** (`src/weapons.asm`). Fire = βολή, W = επόμενο όπλο, U = αναβάθμιση μπαγκέτας (δοκιμή ως το M8), E = διάστημα/Γη (δοκιμή). Σκορ και όπλο στο HUD, μόνο όταν αλλάξουν.
- [x] Projectiles: pool 6 βλημάτων 8x8 (slots 13-18), κίνηση σε 8 κατευθύνσεις, ζωή ανά όπλο, σβήνουν στα όρια του κόσμου· συγκρούσεις AABB με τους εχθρούς (X 8-bit με τελευταίο byte, Y 16-bit)
- [x] **Disco-Ray**: γρήγορη δέσμη (4 pixels/καρέ), βολή ανά 4 καρέ. Ο εχθρός χορεύει **Macarena** 1 s (κουνιέται ένα byte δεξιά-αριστερά, animation 4x πιο γρήγορο) και μετά σκάει
- [x] **Mega-Baguette**: διαπερνάει (σκάει τον εχθρό και συνεχίζει), βολή ανά 8 καρέ
- [x] **Sneeze Cannon**: spray κοντινής εμβέλειας σε ±45° τυχαία, βολή ανά 2 καρέ, 3 φάσεις που απλώνουν, **ανάκρουση** στο σκάφος
- [x] Εναλλαγή όπλων + όνομα στο HUD
- [x] Double/triple baguette: επίπεδο 2 = δύο σε ±45°, επίπεδο 3 = τρεις (βεντάλια)
- [x] Εχθροί με καταστάσεις: ζωντανός / χορεύει / σκάει (έκρηξη 8x16 από το ίδιο slot, bank 4) / νεκρός 3 s / ξαναβγαίνει. +100 ανά εχθρό
- [ ] Ήχοι για βολές και εκρήξεις (M10)
- [ ] Τα μυρμήγκια που αφήνουν οι εχθροί (M7/M8)

Ευρήματα:
- **Μνήμη:** οι εχθροί πήγαν στο bank 5 (`GFX5.BIN`), γιατί bank 4 + βλήματα = 31,7K. Κάθε sprite έχει πλέον πεδίο bank (`SPR_BANK`) και το engine το επιλέγει πριν από το blit. Bank 4 ως `&7BEC`, bank 5 ως `&48D0`, κύρια RAM ως `&3C27` (οι δύο στοίβες save-under των 2K είναι το μεγαλύτερο κομμάτι)
- **rasm:** το `save` διαβάζει από το bank που είναι ενεργό εκείνη τη στιγμή. Με `bank 4/5` και στο build της δισκέτας, κάθε `save` πρέπει να μπει αμέσως μετά το κομμάτι του· στο τέλος του αρχείου έγραφε το `SFC.BIN` από το bank 5
- Τα αργά καρέ (69-76 στα ~530 του `make test`) είναι στην αρχή, με όλους τους εχθρούς μαζεμένους γύρω από το σκάφος (~1000 bytes sprites + βλήματα)

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
