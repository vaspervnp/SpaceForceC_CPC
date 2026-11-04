# Space Force C (Amstrad CPC)

Arcade multi-directional scrolling shooter για τον **Amstrad CPC 6128** σε **Mode 0** (160x200, 16 χρώματα), στα 25 FPS με double buffering.

Έτος 2442: οι καλύτεροι πιλότοι της Space Force έχουν δηλητηριαστεί από διαστημικό μουσακά, και η Γη μένει στα χέρια του **Wing C**, της χειρότερης ομάδας της ακαδημίας. Οι Katsarophobians κλέβουν όλα τα μυρμήγκια του πλανήτη για να φτιάξουν Mirmikochai, το τσάι που θα κοιμίσει επιτέλους τον Αυτοκράτορά τους. 8 levels (4 στο διάστημα, 4 στη Γη), το καθένα με τον δικό του boss.

## Κατάσταση

Σε φάση σχεδιασμού. Δεν υπάρχει ακόμα κώδικας.

- [design_document.md](design_document.md): το game design document
- [todo.md](todo.md): τα milestones της ανάπτυξης

## Εργαλεία

- [rasm](https://github.com/EdouardBerge/rasm): Z80 assembler
- [iDSK](https://github.com/cpcsdk/idsk): διαχείριση εικόνων δισκέτας (Extended DSK)
- [Caprice32](https://github.com/ColinPitrat/caprice32) και CPCemu: emulators για testing
- Aseprite και Blender: γραφικά (3D μοντέλα που αποδίδονται σε sprites με την παλέτα του CPC)

## Build

Θα προστεθεί με το milestone M0 (`Makefile`, παραγωγή του `build/SpaceForceC.dsk`).
