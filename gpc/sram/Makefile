.DEFAULT_GOAL := generate
ROOT := $(abspath ../..)
OPENRAM_ROOT ?= $(abspath $(ROOT)/../../OpenRAM)
BUILD ?= $(ROOT)/artifacts/asic-gpc-audit/openram
IMAGE := vlsida/openram-ubuntu@sha256:90ecae634f99fa9055a32e32f9d6af1acc9942b974916f114330e7b5b4b29f7c

.PHONY: generate test
generate:
	@test -f "$(OPENRAM_ROOT)/sram_compiler.py" || { echo "Set OPENRAM_ROOT to the OpenRAM checkout."; exit 1; }
	mkdir -p $(BUILD)
	docker run --rm --init --user $$(id -u):$$(id -g) \
	    -e OPENRAM_HOME=/openram/compiler -e OPENRAM_TECH=/openram/technology \
	    -e OPENRAM_TMP=/out/tmp -e PYTHONPATH=/ -e PYTHONDONTWRITEBYTECODE=1 \
	    -v $(OPENRAM_ROOT):/openram:ro -v $(ROOT):/work:ro -v $(BUILD):/out -w /out \
	    $(IMAGE) python3 /openram/sram_compiler.py /work/gpc/sram/vrf_256x32.py \
	    > $(BUILD)/generate.log 2>&1 || { cat $(BUILD)/generate.log; exit 1; }
	@echo "Candidate SRAM views: $(BUILD)/vrf_256x32 (unqualified; see ../README.md)"
