export DESIGN_NAME = gpc_top
export DESIGN_NICKNAME = gpc
export PLATFORM = nangate45
HARDWARE_ROOT ?= $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../fpga-gpu-hardware)
GPC_RTL_DIR := $(HARDWARE_ROOT)/rtl
GPC_SOURCES := $(GPC_RTL_DIR)/gpu_pkg.sv \
    $(wildcard $(GPC_RTL_DIR)/common/*.sv) \
    $(wildcard $(GPC_RTL_DIR)/sm/*.sv) \
    $(wildcard $(GPC_RTL_DIR)/sm/sp/*.sv) \
    $(wildcard $(GPC_RTL_DIR)/sm/sp/unit/*.sv) \
    $(wildcard $(GPC_RTL_DIR)/gpc/*.sv)

# Select ASIC SRAM implementations at the shared storage boundaries.
GPC_SOURCES := $(filter-out \
    $(GPC_RTL_DIR)/sm/sp/vector_regfile_ram.sv \
    $(GPC_RTL_DIR)/sm/sp/instruction_ram.sv \
    $(GPC_RTL_DIR)/common/cache_line_ram.sv \
    , $(GPC_SOURCES))
export VERILOG_INCLUDE_DIRS = /hardware/rtl/common
export VERILOG_FILES = $(patsubst $(GPC_RTL_DIR)/%,/hardware/rtl/%,$(GPC_SOURCES)) \
    /work/gpc/sram/vector_regfile_ram.sv \
    /work/gpc/sram/instruction_ram.sv \
    /work/gpc/sram/cache_line_ram.sv

# Generate each selected macro explicitly with make -C gpc/sram MACRO=...
VRF_MACRO = /work/artifacts/asic-gpc-audit/openram/vrf_256x32/gpc_sram_1rw1r_256x32
IRAM_MACRO = /work/artifacts/asic-gpc-audit/openram/iram_1024x32/gpc_sram_1rw1r_1024x32
L1_MACRO = /work/artifacts/asic-gpc-audit/openram/cache_l1_64x277/gpc_sram_1rw_64x277
L2_MACRO = /work/artifacts/asic-gpc-audit/openram/cache_l2_512x274/gpc_sram_1rw_512x274
GPC_MACROS = $(VRF_MACRO) $(IRAM_MACRO) $(L1_MACRO) $(L2_MACRO)

export ADDITIONAL_LIBS = $(addsuffix _TT_1p1V_25C.lib,$(GPC_MACROS))
export ADDITIONAL_LEFS = $(addsuffix .lef,$(GPC_MACROS))
export ADDITIONAL_GDS = $(addsuffix .gds,$(GPC_MACROS))

export SDC_FILE = /work/gpc/constraints/gpc.sdc
# Nangate45/OpenRAM platform integration, independent of macro placement.
export FOOTPRINT_TCL = /work/gpc/technology.tcl
export TAPCELL_TCL = /work/gpc/tapcell.tcl
export PDN_TCL = /work/gpc/pdn.tcl
export POST_PDN_TCL = /work/gpc/floorplan_checks.tcl
export POST_DETAIL_PLACE_TCL = /work/gpc/check_power.tcl
export POST_CTS_TCL = /work/gpc/check_power.tcl
export POST_GLOBAL_ROUTE_TCL = /work/gpc/check_power.tcl
export IO_CONSTRAINTS = /work/gpc/io.tcl
export MACRO_ROWS_HALO_X = 4
export MACRO_ROWS_HALO_Y = 4
export CORE_UTILIZATION = 35
export PLACE_DENSITY = 0.55
export TNS_END_PERCENT = 100

# for system verilog interface syntax support
export SYNTH_HDL_FRONTEND = slang
export SYNTH_SLANG_ARGS = --allow-toplevel-iface-ports

# max size of reg array inference as FF arrays: 4096
export SYNTH_MEMORY_MAX_BITS = 4096
# no mocking for memories
export SYNTH_MOCK_LARGE_MEMORIES = 0
