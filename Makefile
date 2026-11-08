# Space Force C — build
#
#   make            build/SpaceForceC.dsk (Extended DSK)
#   make snap       build/sfc.sna (ξεκινάει χωρίς δισκέτα)
#   make run        Caprice32 με τη δισκέτα και autorun
#   make run-snap   Caprice32 με το snapshot
#   make run-cpcemu CPCEMU 2.5 με τη δισκέτα (tools/cpcemu.sh)
#   make shot       Caprice32 χωρίς παράθυρο -> build/screenshot.png
#   make test       headless CPC (~/cpcemu): σενάρια κίνησης, late frames,
#                   έλεγχος της οθόνης κελί-κελί
#   make sound      headless: οι registers του AY -> build/sound_*.wav
#   make assets     ξαναπαράγει τα assets/data από τα assets/src
#   make clean
#
#   PROFILE=1       raster bars στο border (χρόνος ανά φάση του καρέ)

RASM     ?= rasm
IDSK     ?= iDSK
PYTHON   ?= python3
CAP32    ?= tools/cap32.sh
# 2 = CPC 6128
CPCMODEL ?= 2

BUILD    := build
DSK      := $(BUILD)/SpaceForceC.dsk
SNA      := $(BUILD)/sfc.sna
LOADER   := $(BUILD)/disc.bas

SRC      := $(wildcard src/*.asm)
ASSET_PY := $(wildcard assets/src/*.py)
ASSET_DATA := $(wildcard assets/data/*.asm)

# Αλλαγή στα flags (π.χ. PROFILE) => ξαναχτίζεται ό,τι εξαρτάται από αυτά.
RASMFLAGS := -I src $(if $(PROFILE),-DPROFILE=1)
FLAGS_STAMP := $(BUILD)/flags

.PHONY: all snap run run-snap run-cpcemu shot test sound assets clean FORCE

all: $(DSK)

# Το rasm γράφει το SFC.BIN και το GFX4.BIN σε νέα EDSK· το iDSK προσθέτει
# τον loader (που κρατάει το Extended format) και ελέγχουμε το header στο
# τέλος. Ο loader φορτώνει το GFX4.BIN στο bank 4 (OUT &7F00,&C4), το
# GFX5.BIN στο 5 και τον ήχο (SND6.BIN) στο 6.
$(DSK): $(SRC) $(ASSET_DATA) $(FLAGS_STAMP) Makefile
	rm -f $@
	$(RASM) $(RASMFLAGS) src/main.asm -o $(BUILD)/sfc -s -sq -os $(BUILD)/sfc.sym
	printf '10 MEMORY &3FFF:OUT &7F00,&C4:LOAD"GFX4.BIN":OUT &7F00,&C5:LOAD"GFX5.BIN":OUT &7F00,&C6:LOAD"SND6.BIN":OUT &7F00,&C0:RUN"SFC.BIN"\r\n' > $(LOADER)
	$(IDSK) $@ -i $(LOADER) -t 0 > /dev/null 2>&1
	@head -c 21 $@ | grep -q 'EXTENDED CPC DSK File' || { echo "$@: δεν είναι Extended DSK"; exit 1; }
	@$(IDSK) $@ -l 2>/dev/null | grep -E '^[A-Z0-9 ]{8}\.'

snap: $(SNA)

$(SNA): $(SRC) $(ASSET_DATA) $(FLAGS_STAMP)
	$(RASM) $(RASMFLAGS) -DSNAPSHOT=1 -v2 src/main.asm -o $(BUILD)/sfc

# Το autocmd θέλει πραγματικό newline για το Enter· το $(...) κόβει τα
# τελικά newlines, γι' αυτό η τελεία που αφαιρείται μετά.
run: $(DSK)
	cmd="$$(printf 'run"disc\n.')"; $(CAP32) -O system.model=$(CPCMODEL) -a "$${cmd%.}" $(abspath $(DSK))

run-snap: $(SNA)
	$(CAP32) -O system.model=$(CPCMODEL) $(abspath $(SNA))

shot: $(DSK)
	tools/cap32_shot.sh $(DSK) $(BUILD)/screenshot.png

test: $(DSK)
	$(PYTHON) tools/headless.py $(DSK)

run-cpcemu: $(DSK)
	tools/cpcemu.sh $(DSK)

sound: $(DSK)
	$(PYTHON) tools/sound_wav.py

assets: $(ASSET_PY)
	$(PYTHON) assets/src/make_assets.py
	$(PYTHON) assets/src/music.py

$(FLAGS_STAMP): FORCE
	@mkdir -p $(BUILD)
	@echo '$(RASMFLAGS)' | cmp -s - $@ || echo '$(RASMFLAGS)' > $@

clean:
	rm -rf $(BUILD)
