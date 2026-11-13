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
    /work/sram/vector_regfile_ram.sv \
    /work/sram/instruction_ram.sv \
    /work/sram/cache_line_ram.sv

# Shared SRAM IP views, generated with make -C sram MACRO=...
include $(dir $(lastword $(MAKEFILE_LIST)))../sram/views.mk
DESIGN_ARGS = SRAM_ROOT=$(SRAM_ROOT)
GPC_MACROS = $(VRF_MACRO) $(IRAM_MACRO) $(L1_MACRO) $(L2_MACRO)

export ADDITIONAL_LIBS = $(addsuffix _TT_1p1V_25C.lib,$(GPC_MACROS))
export ADDITIONAL_LEFS = $(addsuffix .lef,$(GPC_MACROS))
export ADDITIONAL_GDS = $(addsuffix .gds,$(GPC_MACROS))

export SDC_FILE = /work/gpc/constraints/gpc.sdc
# Nangate45/OpenRAM platform integration, independent of macro placement.
include $(dir $(lastword $(MAKEFILE_LIST)))../config/nangate45_sram.mk
export POST_FINAL_REPORT_TCL = /work/scripts/reports/module_view.tcl
export IO_CONSTRAINTS = /work/scripts/gpc/io.tcl
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
