# Space Force C (Amstrad CPC)

Arcade multi-directional scrolling shooter για τον **Amstrad CPC 6128** σε **Mode 0** (160x200, 16 χρώματα), στα 25 FPS με double buffering.

Έτος 2442: οι καλύτεροι πιλότοι της Space Force έχουν δηλητηριαστεί από διαστημικό μουσακά, και η Γη μένει στα χέρια του **Wing C**, της χειρότερης ομάδας της ακαδημίας. Οι Katsarophobians κλέβουν όλα τα μυρμήγκια του πλανήτη για να φτιάξουν Mirmikochai, το τσάι που θα κοιμίσει επιτέλους τον Αυτοκράτορά τους. 8 levels (4 στο διάστημα, 4 στη Γη), το καθένα με τον δικό του boss.

## Κατάσταση

Σε φάση σχεδιασμού. Δεν υπάρχει ακόμα κώδικας — υπάρχουν όμως **τα γραφικά
του Level 1**, έτοιμα για `rasm`.

- [design_document.md](design_document.md): το game design document
- [todo.md](todo.md): τα milestones της ανάπτυξης
- [assets/README.md](assets/README.md): τα γραφικά, οι αποφάσεις και ο
  μετρημένος προϋπολογισμός του καρέ

## Γραφικά

19,7 KB σε Mode 0: το σκάφος (8 κατευθύνσεις × 2 κόσμοι), 6 εχθροί, 6 όπλα,
9 power-ups, εκρήξεις, 16 πλακίδια φόντου, ο Lord Garbage-Can και
γραμματοσειρά HUD. Όλα παράγονται από ASCII — δες
[assets/README.md](assets/README.md).

![Level 1](assets/preview/screen.png)

```bash
python3 assets/src/make_assets.py
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

Θα προστεθεί με το milestone M0 (`Makefile`, παραγωγή του `build/SpaceForceC.dsk`).
