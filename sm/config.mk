export DESIGN_NAME = streaming_multiprocessor
export DESIGN_NICKNAME = sm
export PLATFORM = nangate45
HARDWARE_ROOT ?= $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../fpga-gpu-hardware)
SM_RTL_DIR := $(HARDWARE_ROOT)/rtl
SM_CONFIG_FILE := $(lastword $(MAKEFILE_LIST))

# ASIC-only dimensions; do not edit the shared FPGA package.
SM_NUM_SPS ?= 2
SM_NUM_LANES ?= 4
DESIGN_ARGS = SM_NUM_SPS=$(SM_NUM_SPS) SM_NUM_LANES=$(SM_NUM_LANES) SRAM_ROOT=$(SRAM_ROOT)
SM_PACKAGE := $(or $(WORK_HOME),/work/artifacts/asic/sm/$(or $(FLOW_VARIANT),base))/generated/sp$(SM_NUM_SPS)-lanes$(SM_NUM_LANES)/gpu_pkg.sv

# ORFS builds this source prerequisite before elaboration. Preserve every other
# shared package definition; include the dimensions in the path to avoid stale
# package contents when switching configurations.
$(SM_PACKAGE): $(SM_RTL_DIR)/gpu_pkg.sv $(SM_CONFIG_FILE)
	@test "$(SM_NUM_SPS)" -ge 1 -a "$(SM_NUM_LANES)" -ge 1 || { echo "SM_NUM_SPS and SM_NUM_LANES must be positive integers."; exit 1; }
	mkdir -p $(dir $@)
	sed -E \
	    -e 's/parameter[[:space:]]+NUM_SMS[[:space:]]*=[^;]+;/parameter NUM_SMS = 1;/' \
	    -e 's/parameter[[:space:]]+NUM_SUB_PARTITIONS[[:space:]]*=[^;]+;/parameter NUM_SUB_PARTITIONS = $(SM_NUM_SPS);/' \
	    -e 's/parameter[[:space:]]+NUM_LANES[[:space:]]*=[^;]+;/parameter NUM_LANES = $(SM_NUM_LANES);/' \
	    $< > $@.tmp
	@for assignment in 'NUM_SMS = 1' 'NUM_SUB_PARTITIONS = $(SM_NUM_SPS)' 'NUM_LANES = $(SM_NUM_LANES)'; do \
	    grep -Fq "parameter $$assignment;" $@.tmp || { rm -f $@.tmp; echo "Unsupported shared gpu_pkg.sv parameter declarations."; exit 1; }; \
	done
	mv $@.tmp $@

SM_SOURCES := $(wildcard $(SM_RTL_DIR)/common/*.sv) \
    $(wildcard $(SM_RTL_DIR)/sm/*.sv) \
    $(wildcard $(SM_RTL_DIR)/sm/sp/*.sv) \
    $(wildcard $(SM_RTL_DIR)/sm/sp/unit/*.sv)
SM_SOURCES := $(filter-out \
    $(SM_RTL_DIR)/sm/sp/vector_regfile_ram.sv \
    $(SM_RTL_DIR)/sm/sp/instruction_ram.sv \
    $(SM_RTL_DIR)/common/cache_line_ram.sv,$(SM_SOURCES))
export VERILOG_INCLUDE_DIRS = /hardware/rtl/common
export VERILOG_FILES = $(SM_PACKAGE) \
    $(patsubst $(SM_RTL_DIR)/%,/hardware/rtl/%,$(SM_SOURCES)) \
    /work/sram/vector_regfile_ram.sv \
    /work/sram/instruction_ram.sv \
    /work/sram/cache_line_ram.sv

# Reuse the generated VRF, IRAM and L1 IP. L2 belongs to the parent partition.
include $(dir $(lastword $(MAKEFILE_LIST)))../sram/views.mk
SM_MACROS = $(VRF_MACRO) $(IRAM_MACRO) $(L1_MACRO)
export ADDITIONAL_LIBS = $(addsuffix _TT_1p1V_25C.lib,$(SM_MACROS))
export ADDITIONAL_LEFS = $(addsuffix .lef,$(SM_MACROS))
export ADDITIONAL_GDS = $(addsuffix .gds,$(SM_MACROS))

export SDC_FILE = /work/sm/constraints/sm.sdc
export IO_CONSTRAINTS = /work/sm/io.tcl
export CORE_UTILIZATION = 35
export PLACE_DENSITY = 0.55
export TNS_END_PERCENT = 100

# Shared Nangate45/OpenRAM integration hooks, without GPC hierarchy assumptions.
export FOOTPRINT_TCL = /work/sram/technology.tcl
export TAPCELL_TCL = /work/gpc/tapcell.tcl
export PDN_TCL = /work/gpc/pdn.tcl
export POST_PDN_TCL = /work/gpc/floorplan_checks.tcl
export POST_DETAIL_PLACE_TCL = /work/gpc/check_power.tcl
export POST_CTS_TCL = /work/gpc/check_power.tcl
export POST_GLOBAL_ROUTE_TCL = /work/gpc/check_power.tcl
export POST_FINAL_REPORT_TCL = /work/scripts/module_view.tcl
export MACRO_ROWS_HALO_X = 4
export MACRO_ROWS_HALO_Y = 4

export SYNTH_HDL_FRONTEND = slang
export SYNTH_SLANG_ARGS = --allow-toplevel-iface-ports
export SYNTH_MEMORY_MAX_BITS = 4096
export SYNTH_MOCK_LARGE_MEMORIES = 0
