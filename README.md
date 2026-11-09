# Space Force C (Amstrad CPC)

Arcade multi-directional scrolling shooter για τον **Amstrad CPC 6128** σε **Mode 0** (160x200, 16 χρώματα), στα 25 FPS με double buffering.

Έτος 2442: οι καλύτεροι πιλότοι της Space Force έχουν δηλητηριαστεί από διαστημικό μουσακά, και η Γη μένει στα χέρια του **Wing C**, της χειρότερης ομάδας της ακαδημίας. Οι Katsarophobians κλέβουν όλα τα μυρμήγκια του πλανήτη για να φτιάξουν Mirmikochai, το τσάι που θα κοιμίσει επιτέλους τον Αυτοκράτορά τους. 8 levels (4 στο διάστημα, 4 στη Γη), το καθένα με τον δικό του boss.

## Κατάσταση

**Το παιχνίδι παίζεται ολόκληρο**: εισαγωγή, 8 πίστες με 8 bosses, τέλος, credits και πίνακας ρεκόρ, με μουσική και ηχητικά εφέ στο AY. Τρέχει σε CPC 6128, και σε 464/664 με 128K (ελεγμένο στο Caprice32, όχι ακόμα σε πραγματικό CPC).

Στις μάχες με τους bosses ο ρυθμός πέφτει ως τα ~23 FPS. Στις πίστες μένει σταθερά στα 25. Δες το [todo.md](todo.md).

## Πώς παίζεται

Στον CPC ή σε emulator, με τη δισκέτα `SpaceForceC.dsk`:

```
RUN"DISC
```

| πλήκτρο | ενέργεια |
|---|---|
| κέρσορες / joystick | κίνηση σε 8 κατευθύνσεις, με αδράνεια |
| Space / Fire | βολή |
| W | επόμενο όπλο (Disco-Ray, Mega-Baguette, Sneeze Cannon) |
| ESC | παύση (στις σκηνές: τις προσπερνά) |

Στον τίτλο: 1 ή Fire = παιχνίδι, 2 = αλλαγή πλήκτρων, 3 = ρεκόρ, 4 = δυσκολία.

Κάθε ζωή αντέχει 10 χτυπήματα στο Easy, 5 στο Medium και 2 στο Hard, και η μπαταρία γεμίζει ξανά την ενέργεια. Μάζεψε τα μυρμήγκια και τα power-ups που αφήνουν οι εχθροί. Κάθε 15.000 πόντοι δίνουν μια ζωή. Όταν τελειώσουν οι εχθροί μιας πίστας, έρχεται ο boss της.

- [design_document.md](design_document.md): το game design document
- [todo.md](todo.md): τα milestones της ανάπτυξης
- [assets/README.md](assets/README.md): τα γραφικά, οι αποφάσεις και ο
  μετρημένος προϋπολογισμός του καρέ

## Γραφικά

Όλα σε Mode 0, και όλα παράγονται από κώδικα ή ASCII: το σκάφος (8 κατευθύνσεις × 2 κόσμοι), 6 εχθροί και 2 ανά πίστα, 8 bosses, 7 σετ πλακιδίων, όπλα, power-ups, εκρήξεις, οι σκηνές της ιστορίας. Δες το [assets/README.md](assets/README.md).

![Level 1](assets/preview/screen.png)

```bash
make assets
```

Δύο ευρήματα από την τέχνη που αλλάζουν το σχέδιο της μηχανής:

* **Το «24x24 pixels» του σκάφους** βγάζει 48×24 ΜΟΝΑΔΕΣ οθόνης στο Mode 0.
  Ένα σκάφος που στρίβει πρέπει να είναι τετράγωνο στην οθόνη, άρα **12×24
  pixels** — που είναι και 4× φθηνότερο σε blit και σε μνήμη.
* **Ένα πλήρες ξαναζωγράφισμα του φόντου κοστίζει 57,6 ms**, δηλαδή 144 % του
  καρέ των 25 FPS, πριν μπει ένα μόνο sprite. Το M3 δεν είναι επιλογή
  ανάμεσα σε hardware scroll και software redraw: **το software redraw είναι
  ήδη εκτός**.

## Εργαλεία

- [rasm](https://github.com/EdouardBerge/rasm): Z80 assembler
- [iDSK](https://github.com/cpcsdk/idsk): διαχείριση εικόνων δισκέτας (Extended DSK)
- [Caprice32](https://github.com/ColinPitrat/caprice32) και CPCemu: emulators για testing
- Aseprite και Blender: γραφικά (3D μοντέλα που αποδίδονται σε sprites με την παλέτα του CPC)

## Build

```bash
make
```

Βγάζει το `build/SpaceForceC.dsk` (Extended DSK). Στον CPC ή σε emulator: `RUN"DISC`.

| στόχος | τι κάνει |
|---|---|
| `make run` | Caprice32 με τη δισκέτα και autorun |
| `make snap` / `make run-snap` | snapshot (`build/sfc.sna`) που ξεκινάει κατευθείαν |
| `make shot` | Caprice32 χωρίς παράθυρο, γράφει `build/screenshot.png` |
| `make sound` | headless: οι registers του AY γίνονται `build/sound_*.wav` (τίτλος, παιχνίδι, game over) |
| `make START=n` | το παιχνίδι ξεκινάει από την πίστα n, χωρίς την εισαγωγή (μετά ξανά `make` για κανονικό) |
| `make START=n BOSS=1` | κατευθείαν ο boss της πίστας n |
| `make test` | headless CPC (`~/cpcemu`): σενάρια κίνησης, χρόνος καρέ, έλεγχος οθόνης κελί-κελί (`CRTC=0/1/2` για τύπο CRTC) |
| `make run-cpcemu` | CPCEMU 2.5 για Linux (`CPCEMU_TGZ=` το tarball από το cpc-emu.org) |
| `make PROFILE=1 ...` | raster bars στο border, μετρητής αργών καρέ στο HUD, E = διάστημα/Γη |
| `make assets` | ξαναπαράγει τα `assets/data` από τα `assets/src` |

Το Caprice32 είναι το snap package. Καλείται μέσω του `tools/cap32.sh`, γιατί ο `caprice32.launcher` πετάει τις επιλογές της γραμμής εντολών.

## Credits

REVIVE8BIT - 2026 - VASPER. Κώδικας και γραφικά με το Claude. Για τον Amstrad CPC, με [rasm](https://github.com/EdouardBerge/rasm) και [iDSK](https://github.com/cpcsdk/idsk).
