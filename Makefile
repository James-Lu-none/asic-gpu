.DEFAULT_GOAL := flow
ROOT := $(abspath ..)
BUILD ?= $(ROOT)/artifacts/asic
TB := ../sim/unit/mul32/mul32_pattern.sv ../sim/unit/mul32/tb_mul32.sv
IMAGE := openroad/orfs:latest
JOBS ?= 4

FLOW_ARGS = DESIGN_CONFIG=/work/asic/mul32/config.mk \
            WORK_HOME=/work/artifacts/asic NUM_CORES=$(JOBS) \
            KLAYOUT_LVS_FILE=/work/asic/lvs/lvs_freepdk45.lylvs
DOCKER = docker run --rm --init --user $$(id -u):$$(id -g) \
         -v $(ROOT):/work:ro -v $(BUILD):/work/artifacts/asic \
         -w /OpenROAD-flow-scripts/flow
RESULTS := $(BUILD)/results/nangate45/mul32/base
REPORTS := $(BUILD)/reports/nangate45/mul32/base

.PHONY: flow signoff drc lvs gate-test gui gui-web

# Require an explicit ORFS stage; no tool runs when STAGE is empty.
flow:
	@test -n "$(strip $(STAGE))" || { echo "Specify STAGE=synth|floorplan|place|cts|route|finish; use signoff for checks."; exit 1; }
	mkdir -p $(BUILD)
	$(DOCKER) $(IMAGE) make $(FLOW_ARGS) $(STAGE)

# Require an existing final design instead of silently implementing it here.
signoff:
	@for ext in odb sdc spef gds v; do \
	    test -s $(RESULTS)/6_final.$$ext || { echo "Missing final $$ext; run make -C asic flow STAGE=finish first."; exit 1; }; \
	done
	# Rerun ORFS final analysis: it produces STA and static IR together.
	rm -f $(BUILD)/logs/nangate45/mul32/base/6_report.log
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

# Zero-delay mapped-netlist simulation using the shared functional pattern.
gate-test:
	mkdir -p $(BUILD)/sim
	docker run --rm --user $$(id -u):$$(id -g) \
	    -v $(BUILD):/out $(IMAGE) bash -c ' \
	    source /OpenROAD-flow-scripts/env.sh; \
	    yosys -Q -T -p "read_liberty -ignore_miss_func /OpenROAD-flow-scripts/flow/platforms/nangate45/lib/NangateOpenCellLibrary_typical.lib; write_verilog -noattr /out/sim/nangate45.v"'
	iverilog -g2012 -s tb_mul32 -o $(BUILD)/sim/gate \
	    $(BUILD)/results/nangate45/mul32/base/1_2_yosys.v \
	    $(BUILD)/sim/nangate45.v $(TB)
	vvp $(BUILD)/sim/gate

WEB_BIND ?= 0.0.0.0
WEB_PORT ?= 8080
GUI_TARGET ?= web_final
WEB_TARGET ?= $(GUI_TARGET)
gui gui-web:
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
	    -p $(WEB_BIND):$(WEB_PORT):$(WEB_PORT) $(IMAGE) make $(FLOW_ARGS) \
	    OR_ARGS="-web_no_browser -web_bind 0.0.0.0 -web_port $(WEB_PORT)" $(WEB_TARGET) & \
	wait $$!
