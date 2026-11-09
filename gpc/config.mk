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

# substitute fpga bram vrf with asic sram vrf implementation 
GPC_SOURCES := $(filter-out $(GPC_RTL_DIR)/sm/sp/vector_regfile_ram.sv,$(GPC_SOURCES))
export VERILOG_INCLUDE_DIRS = /hardware/rtl/common
export VERILOG_FILES = $(patsubst $(GPC_RTL_DIR)/%,/hardware/rtl/%,$(GPC_SOURCES)) \
    /work/gpc/sram/vector_regfile_ram.sv

# include asic sram vrf .gds/.lef/.lib file, make -C gpc/sram first
VRF_MACRO = /work/artifacts/asic-gpc-audit/openram/vrf_256x32/gpc_sram_1rw1r_256x32
export ADDITIONAL_LIBS = $(VRF_MACRO)_TT_1p1V_25C.lib
export ADDITIONAL_LEFS = $(VRF_MACRO).lef
export ADDITIONAL_GDS = $(VRF_MACRO).gds

export SDC_FILE = /work/gpc/constraints/gpc.sdc
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
