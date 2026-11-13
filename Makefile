.DEFAULT_GOAL := all
ROOT := $(CURDIR)
HARDWARE_ROOT ?= $(abspath $(ROOT)/../fpga-gpu-hardware)
BUILD ?= $(ROOT)/artifacts/asic
IMAGE := openroad/orfs:latest
JOBS ?= 8
DOCKER_ARGS ?=
STAGE ?= finish

# Read the selected design once; ORFS receives the same file in the container.
DESIGN ?= gpc
FLOW_VARIANT ?= base
DESIGN_CONFIG ?= $(if $(filter base,$(FLOW_VARIANT)),$(DESIGN)/config.mk,$(DESIGN)/variants/$(FLOW_VARIANT).mk)
ifeq ($(wildcard $(DESIGN_CONFIG)),)
$(error Missing design config/preset: $(DESIGN_CONFIG). Use FLOW_VARIANT=base or an existing preset; set DESIGN_CONFIG explicitly for a custom run)
endif
include $(DESIGN_CONFIG)
DESIGN_NICKNAME ?= $(DESIGN_NAME)
CONFIG_IN_CONTAINER := $(patsubst $(ROOT)/%,/work/%,$(abspath $(DESIGN_CONFIG)))

RUN_PATH := $(DESIGN)/$(FLOW_VARIANT)
RUN_DIR := /work/artifacts/asic/$(RUN_PATH)

FLOW_ARGS = DESIGN_CONFIG=$(CONFIG_IN_CONTAINER) \
            HARDWARE_ROOT=/hardware \
            WORK_HOME=$(RUN_DIR) NUM_CORES=$(JOBS) \
            RESULTS_DIR=$(RUN_DIR)/results REPORTS_DIR=$(RUN_DIR)/reports \
            LOG_DIR=$(RUN_DIR)/logs OBJECTS_DIR=$(RUN_DIR)/objects \
            FLOW_VARIANT=$(FLOW_VARIANT) $(DESIGN_ARGS) $(ORFS_ARGS)
DOCKER = docker run --rm --init $(DOCKER_ARGS) --user $$(id -u):$$(id -g) \
         -v $(ROOT):/work:ro -v $(BUILD):/work/artifacts/asic \
         -v $(HARDWARE_ROOT):/hardware:ro \
         -w /OpenROAD-flow-scripts/flow
RESULTS := $(BUILD)/$(RUN_PATH)/results
REPORTS := $(BUILD)/$(RUN_PATH)/reports
LOGS := $(BUILD)/$(RUN_PATH)/logs
SIM_BUILD := $(BUILD)/$(RUN_PATH)/sim

.PHONY: all elaborate flow abstract signoff drc lvs gate-test gui gui-web images

all:
	$(MAKE) flow STAGE=finish
	$(MAKE) drc
	$(MAKE) lvs

# Canonical RTLIL checkpoint plus a memory-preserving elaboration report.
elaborate:
	mkdir -p $(REPORTS)
	$(DOCKER) $(IMAGE) make $(FLOW_ARGS) \
	    $(RUN_DIR)/results/1_1_yosys_canonicalize.rtlil
	$(DOCKER) $(IMAGE) bash -c 'source /OpenROAD-flow-scripts/env.sh; \
	    yosys -Q -T -p "read_rtlil $(RUN_DIR)/results/1_1_yosys_canonicalize.rtlil; hierarchy -check -top $(DESIGN_NAME); proc; memory_dff; memory_collect; opt_clean; check -assert; stat; write_json $(RUN_DIR)/reports/elaborated.json"' \
	    > $(REPORTS)/elaborate.rpt 2>&1 || { cat $(REPORTS)/elaborate.rpt; exit 1; }
	@echo "Elaboration report: $(REPORTS)/elaborate.rpt"
	@echo "Memory-preserving design: $(REPORTS)/elaborated.json"

# Default to the complete RTL-to-GDS flow; STAGE selects a partial/native run.
flow:
	@test -n "$(strip $(STAGE))" || { echo "Specify STAGE=synth|floorplan|place|cts|route|finish; use signoff for checks."; exit 1; }
	mkdir -p $(BUILD)
	$(DOCKER) $(IMAGE) make $(FLOW_ARGS) $(STAGE)

# Package an existing routed block for use as a hard macro in its parent.
abstract:
	@for ext in odb sdc spef gds v; do \
	    test -s $(RESULTS)/6_final.$$ext || { echo "Missing final $$ext; complete this block first."; exit 1; }; \
	done
	$(DOCKER) $(IMAGE) make $(FLOW_ARGS) run \
	    RUN_SCRIPT=/work/scripts/flow/export_macro.tcl RUN_LOG_NAME_STEM=export_macro

# Expand completed macro geometry in a separate GUI database; no P&R is rerun.
.PHONY: details gui-detail web-gui-detail
details:
	@test -n "$(strip $(DETAIL_BLOCKS))" || { echo "Select a hierarchical preset with DETAIL_BLOCKS (SM: FLOW_VARIANT=hard_sp_stack)."; exit 1; }
	@test -s $(RESULTS)/6_final.odb || { echo "Complete the parent flow first."; exit 1; }
	$(DOCKER) $(IMAGE) make $(FLOW_ARGS) run \
	    RUN_SCRIPT=/work/scripts/flow/detail_view.tcl RUN_LOG_NAME_STEM=detail_view

gui-detail:
	@test -s $(RESULTS)/6_final_detailed.odb || { echo "Run make details DESIGN=$(DESIGN) first."; exit 1; }
	$(MAKE) gui GUI_TARGET=gui_6_final_detailed.odb ORFS_ARGS="$(ORFS_ARGS) GUI_TIMING=0"

gui-web-detail:
	@test -s $(RESULTS)/6_final_detailed.odb || { echo "Run make details DESIGN=$(DESIGN) FLOW_VARIANT=$(FLOW_VARIANT) first."; exit 1; }
	$(MAKE) gui-web WEB_TARGET=web_6_final_detailed.odb ORFS_ARGS="$(ORFS_ARGS) GUI_TIMING=0"

# Render an existing checkpoint without rerunning implementation or signoff.
IMAGE_STAGE ?= 6_final
IMAGE_PREFIX = $(if $(filter 6_final,$(IMAGE_STAGE)),final,$(IMAGE_STAGE))
images:
	@test -s $(RESULTS)/$(IMAGE_STAGE).odb || { echo "Missing $(RESULTS)/$(IMAGE_STAGE).odb"; exit 1; }
	mkdir -p $(REPORTS) $(LOGS)
	$(DOCKER) -e QT_QPA_PLATFORM=offscreen -e RESULTS_DIR=$(RUN_DIR)/results \
	    -e REPORTS_DIR=$(RUN_DIR)/reports -e IMAGE_DB=$(RUN_DIR)/results/$(IMAGE_STAGE).odb \
	    -e IMAGE_PREFIX=$(IMAGE_PREFIX) $(IMAGE) bash -c \
	    'source /OpenROAD-flow-scripts/env.sh; openroad -exit /work/scripts/reports/module_view.tcl' \
	    > $(LOGS)/module_view.log 2>&1 || { tail -30 $(LOGS)/module_view.log; exit 1; }
	@echo "Module view: $(REPORTS)/$(IMAGE_PREFIX)_modules.webp"

# Require an existing final design instead of silently implementing it here.
signoff:
	@for ext in odb sdc spef gds v; do \
	    test -s $(RESULTS)/6_final.$$ext || { echo "Missing final $$ext; run make flow STAGE=finish first."; exit 1; }; \
	done
	# Rerun ORFS final analysis: it produces STA and static IR together.
	rm -f $(LOGS)/6_report.log
	$(MAKE) flow STAGE=finish
	$(MAKE) drc
	$(MAKE) lvs

# Remove cached comparison reports so each signoff request reruns the checks.
drc:
	rm -f $(REPORTS)/6_drc.lyrdb $(REPORTS)/6_drc_count.rpt
	$(DOCKER) $(IMAGE) make $(FLOW_ARGS) drc
	@test "$$(cat $(REPORTS)/6_drc_count.rpt)" -eq 0 || { echo "DRC violations found; inspect $(REPORTS)/6_drc.lyrdb"; exit 1; }

lvs:
	rm -f $(RESULTS)/6_lvs.lvsdb
	$(DOCKER) $(IMAGE) make $(FLOW_ARGS) lvs

# Optional per-design simulation settings are defined in the design config.
gate-test:
	@test -n "$(TB_TOP)" -a -n "$(TB_FILES)" -a -n "$(GATE_LIBERTY)" || { echo "Define TB_TOP, TB_FILES and GATE_LIBERTY in $(DESIGN_CONFIG) for gate-test."; exit 1; }
	mkdir -p $(SIM_BUILD)
	docker run --rm --user $$(id -u):$$(id -g) \
	    -v $(SIM_BUILD):/out $(IMAGE) bash -c ' \
	    source /OpenROAD-flow-scripts/env.sh; \
	    yosys -Q -T -p "read_liberty -ignore_miss_func $(GATE_LIBERTY); write_verilog -noattr /out/cells.v"'
	iverilog -g2012 -s $(TB_TOP) -o $(SIM_BUILD)/gate \
	    $(RESULTS)/1_2_yosys.v $(SIM_BUILD)/cells.v $(TB_FILES)
	vvp $(SIM_BUILD)/gate

# SSH X11 forwarding for XQuartz.
XAUTHORITY ?= $(HOME)/.Xauthority
GUI_TARGET ?= gui_final
gui:
	@test -n "$(DISPLAY)" || { echo "Connect with ssh -Y and check DISPLAY first."; exit 1; }
	@test -r "$(XAUTHORITY)" || { echo "Set XAUTHORITY to your readable X11 cookie file."; exit 1; }
	mkdir -p $(BUILD)
	@cidfile=$$(mktemp); rm -f "$$cidfile"; \
	cleanup() { \
	    if test -s "$$cidfile"; then docker rm -f "$$(cat "$$cidfile")" >/dev/null 2>&1 || :; fi; \
	    rm -f "$$cidfile"; \
	}; \
	trap cleanup EXIT; \
	trap 'exit 130' INT; \
	trap 'exit 143' TERM; \
	$(DOCKER) --cidfile "$$cidfile" --network host \
	    -e DISPLAY -e XAUTHORITY=/tmp/asic.xauthority -e QT_X11_NO_MITSHM=1 \
	    -v "$(XAUTHORITY):/tmp/asic.xauthority:ro" \
	    $(IMAGE) make $(FLOW_ARGS) $(GUI_TARGET) & \
	wait $$!

# Set WEB_BIND to the server's Tailscale IP for direct tailnet access.
WEB_BIND ?= 0.0.0.0
WEB_PORT ?= 8080
WEB_TARGET ?= web_final
WEB_HOSTNAME ?= vivado.tail7f7a0f.ts.net
gui-web:
	mkdir -p $(BUILD)
	@cidfile=$$(mktemp); rm -f "$$cidfile"; \
	cleanup() { \
	    if test -s "$$cidfile"; then docker rm -f "$$(cat "$$cidfile")" >/dev/null 2>&1 || :; fi; \
	    rm -f "$$cidfile"; \
	}; \
	trap cleanup EXIT; \
	trap 'exit 130' INT; \
	trap 'exit 143' TERM; \
	$(DOCKER) --cidfile "$$cidfile" \
		--hostname $(WEB_HOSTNAME) \
	    -p $(WEB_BIND):$(WEB_PORT):$(WEB_PORT) $(IMAGE) make $(FLOW_ARGS) \
	    OR_ARGS="-web_no_browser -web_bind 0.0.0.0 -web_port $(WEB_PORT)" $(WEB_TARGET) & \
	wait $$!
