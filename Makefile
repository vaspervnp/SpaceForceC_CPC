# Space Force C — build
#
#   make            build/SpaceForceC.dsk (Extended DSK)
#   make snap       build/sfc.sna (ξεκινάει χωρίς δισκέτα)
#   make run        Caprice32 με τη δισκέτα και autorun
#   make run-snap   Caprice32 με το snapshot
#   make run-cpcemu CPCemu με τη δισκέτα
#   make shot       Caprice32 χωρίς παράθυρο -> build/screenshot.png
#   make assets     ξαναπαράγει τα assets/data από τα assets/src
#   make clean

RASM     ?= rasm
IDSK     ?= iDSK
PYTHON   ?= python3
CAP32    ?= tools/cap32.sh
CPCEMU   ?= cpcemu
# 2 = CPC 6128
CPCMODEL ?= 2

BUILD    := build
DSK      := $(BUILD)/SpaceForceC.dsk
SNA      := $(BUILD)/sfc.sna
LOADER   := $(BUILD)/disc.bas

SRC      := $(wildcard src/*.asm)
ASSET_PY := $(wildcard assets/src/*.py)
ASSET_DATA := $(wildcard assets/data/*.asm)

.PHONY: all snap run run-snap run-cpcemu shot assets clean

all: $(DSK)

# Το rasm γράφει το SFC.BIN σε νέα EDSK· το iDSK προσθέτει τον loader
# (που κρατάει το Extended format) και ελέγχουμε το header στο τέλος.
$(DSK): $(SRC) $(ASSET_DATA) | $(BUILD)
	rm -f $@
	$(RASM) -I src src/main.asm -o $(BUILD)/sfc
	printf '10 RUN"SFC.BIN"\r\n' > $(LOADER)
	$(IDSK) $@ -i $(LOADER) -t 0 > /dev/null 2>&1
	@head -c 21 $@ | grep -q 'EXTENDED CPC DSK File' || { echo "$@: δεν είναι Extended DSK"; exit 1; }
	@$(IDSK) $@ -l 2>/dev/null | grep -E '^[A-Z0-9 ]{8}\.'

snap: $(SNA)

$(SNA): $(SRC) $(ASSET_DATA) | $(BUILD)
	$(RASM) -I src -DSNAPSHOT=1 -v2 src/main.asm -o $(BUILD)/sfc

# Το autocmd θέλει πραγματικό newline για το Enter· το $(...) κόβει τα
# τελικά newlines, γι' αυτό η τελεία που αφαιρείται μετά.
run: $(DSK)
	cmd="$$(printf 'run"disc\n.')"; $(CAP32) -O system.model=$(CPCMODEL) -a "$${cmd%.}" $(abspath $(DSK))

run-snap: $(SNA)
	$(CAP32) -O system.model=$(CPCMODEL) $(abspath $(SNA))

shot: $(DSK)
	tools/cap32_shot.sh $(DSK) $(BUILD)/screenshot.png

run-cpcemu: $(DSK)
	@command -v $(CPCEMU) > /dev/null || { echo "Δεν βρέθηκε το '$(CPCEMU)'. Δώσε τη διαδρομή: make run-cpcemu CPCEMU=/path/to/cpcemu"; exit 1; }
	$(CPCEMU) $(abspath $(DSK))

assets: $(ASSET_PY)
	$(PYTHON) assets/src/make_assets.py

$(BUILD):
	mkdir -p $@

clean:
	rm -rf $(BUILD)
