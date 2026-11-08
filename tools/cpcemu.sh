#!/bin/sh
# CPCEMU 2.5 για Linux (cpc-emu.org, freeware, (C) Marco Vieth & Rainer
# Loritz) ως CPC 6128 με τη δισκέτα στο A: και autostart (DISC.BAS).
# Ίδια μέθοδος με το V-OS-CPC (tools/mklinux.sh).
#   tools/cpcemu.sh build/SpaceForceC.dsk
# Την πρώτη φορά αποσυμπιέζει το CPCEMU στο build/cpcemu από το
# CPCEMU_TGZ (cpcemu-linux-x86_64-2.5.tar.gz από το cpc-emu.org/download.html).
# Θέλει SDL2. Το CPCEMU γράφει τις δισκέτες όταν κλείνει (F12), γι' αυτό
# τρέχει σε αντίγραφο της δισκέτας.
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DSK=$(realpath "${1:?usage: cpcemu.sh disk.dsk}")
TGZ=${CPCEMU_TGZ:-$HOME/repos/V-OS-CPC/build/dl/cpcemu-linux/cpcemu-linux-x86_64-2.5.tar.gz}
EMU=$ROOT/build/cpcemu

if [ ! -x "$EMU/cpcemu" ]; then
    [ -f "$TGZ" ] || { echo "Δεν βρέθηκε το CPCEMU: δώσε CPCEMU_TGZ=/path/to/cpcemu-linux-x86_64-2.5.tar.gz" >&2; exit 1; }
    rm -rf "$EMU" "$ROOT/build/cpcemu.untar"
    mkdir -p "$ROOT/build/cpcemu.untar"
    tar xzf "$TGZ" -C "$ROOT/build/cpcemu.untar"
    mv "$ROOT/build/cpcemu.untar/"cpcemu-* "$EMU"
    rm -rf "$ROOT/build/cpcemu.untar" "$EMU/DISC/"* "$EMU/DISC/".??*
fi

# CPC 6128 με 128K, χωρίς M4 και ποντίκι, χωρίς την ερώτηση για το
# εικονικό πληκτρολόγιο, η δισκέτα στο A: με autostart.
tr -d '\r' < "$EMU/cpcemu0.cfg" |
    sed -e 's|^DRIVE_A = .*|DRIVE_A = "./DISC/SFC.DSK"\t;Space Force C|' \
        -e 's|^DRIVE_A_AUTOSTART = .*|DRIVE_A_AUTOSTART = 1|' \
        -e 's|^M4_ENABLED = .*|M4_ENABLED = 0|' \
        -e 's|^MOUSE_ENABLED = .*|MOUSE_ENABLED = 0|' \
        -e 's|^\(KBD_LANGUAGE = .*\)|\1\nVKBD_LANGUAGE = 0|' |
    sed 's/$/\r/' > "$EMU/sfc.cfg"
cp "$DSK" "$EMU/DISC/SFC.DSK"

cd "$EMU"
exec ./cpcemu -c sfc.cfg -t 2
