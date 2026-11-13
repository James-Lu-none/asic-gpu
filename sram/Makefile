.DEFAULT_GOAL := generate
SRAM_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ROOT := $(abspath $(SRAM_DIR)/..)
include $(SRAM_DIR)/views.mk
OPENRAM_ROOT ?= $(abspath $(ROOT)/../../OpenRAM)
BUILD ?= $(patsubst /work/%,$(ROOT)/%,$(SRAM_ROOT))
MACRO ?= vrf_128x32
# Active configs live here; optional comparison configs live under alternatives/.
MACRO_CONFIG := $(firstword $(wildcard $(SRAM_DIR)/$(MACRO).py $(SRAM_DIR)/alternatives/$(MACRO).py))
CONFIG_IN_CONTAINER := $(patsubst $(ROOT)/%,/work/%,$(MACRO_CONFIG))
IMAGE := vlsida/openram-ubuntu@sha256:90ecae634f99fa9055a32e32f9d6af1acc9942b974916f114330e7b5b4b29f7c
ORFS_IMAGE ?= openroad/orfs:latest

.PHONY: generate
generate:
	@test -f "$(OPENRAM_ROOT)/sram_compiler.py" || { echo "Set OPENRAM_ROOT to the OpenRAM checkout."; exit 1; }
	@test -f "$(MACRO_CONFIG)" || { echo "Missing native OpenRAM config: $(MACRO).py"; exit 1; }
	mkdir -p $(BUILD)
	docker run --rm --init --user $$(id -u):$$(id -g) \
	    -e OPENRAM_HOME=/openram/compiler -e OPENRAM_TECH=/openram/technology \
	    -e OPENRAM_TMP=/out/tmp/$(MACRO) -e PYTHONPATH=/ -e PYTHONDONTWRITEBYTECODE=1 \
	    -v $(OPENRAM_ROOT):/openram:ro -v $(ROOT):/work:ro -v $(BUILD):/out -w /out \
	    $(IMAGE) python3 /openram/sram_compiler.py $(CONFIG_IN_CONTAINER) \
	    > $(BUILD)/$(MACRO).log 2>&1 || { cat $(BUILD)/$(MACRO).log; exit 1; }
	@echo "Candidate SRAM views: $(BUILD)/$(MACRO) (unqualified; see sram/README.md)"

# OpenROAD can return success after a Tcl error; require the completion marker.
.PHONY: pin-access
pin-access:
	@test "$$(find $(BUILD)/$(MACRO) -maxdepth 1 -name '*.lef' | wc -l)" -eq 1 || { echo "Generate exactly one macro LEF first."; exit 1; }
	docker run --rm --user $$(id -u):$$(id -g) \
	    -v $(ROOT):/work:ro -v $(BUILD):/out:ro \
	    -e MACRO_LEF=/out/$(MACRO)/$$(basename $(BUILD)/$(MACRO)/*.lef) \
	    $(ORFS_IMAGE) bash -c 'source /OpenROAD-flow-scripts/env.sh; openroad -exit /work/scripts/sram/check_pin_access.tcl' \
	    > $(BUILD)/$(MACRO).pin_access.log 2>&1 || { cat $(BUILD)/$(MACRO).pin_access.log; exit 1; }
	@grep -qx MACRO_PIN_ACCESS_PASS $(BUILD)/$(MACRO).pin_access.log || { cat $(BUILD)/$(MACRO).pin_access.log; exit 1; }
	@echo "SRAM pin access passed: $(BUILD)/$(MACRO).pin_access.log"
