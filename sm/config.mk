export DESIGN_NAME = streaming_multiprocessor
export DESIGN_NICKNAME = sm
export PLATFORM = nangate45
HARDWARE_ROOT ?= $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../fpga-gpu-hardware)
SM_RTL_DIR := $(HARDWARE_ROOT)/rtl
include $(dir $(lastword $(MAKEFILE_LIST)))../config/gpu_arch.mk
DESIGN_ARGS = SRAM_ROOT=$(SRAM_ROOT)

SM_SOURCES := $(wildcard $(SM_RTL_DIR)/common/*.sv) \
    $(wildcard $(SM_RTL_DIR)/sm/*.sv) \
    $(wildcard $(SM_RTL_DIR)/sm/sp/*.sv) \
    $(wildcard $(SM_RTL_DIR)/sm/sp/unit/*.sv)
SM_SOURCES := $(filter-out \
    $(SM_RTL_DIR)/sm/sp/vector_regfile_ram.sv \
    $(SM_RTL_DIR)/sm/sp/instruction_ram.sv \
    $(SM_RTL_DIR)/common/cache_line_ram.sv,$(SM_SOURCES))
export VERILOG_INCLUDE_DIRS = /hardware/rtl/common
export VERILOG_FILES = $(GPU_HEADERS) \
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
export IO_CONSTRAINTS = /work/scripts/sm/io_default.tcl
export CORE_UTILIZATION = 35
export PLACE_DENSITY = 0.55
export TNS_END_PERCENT = 100

# Shared Nangate45/OpenRAM integration hooks, without GPC hierarchy assumptions.
include $(dir $(lastword $(MAKEFILE_LIST)))../config/nangate45_sram.mk
export POST_FINAL_REPORT_TCL = /work/scripts/reports/module_view.tcl

export SYNTH_HDL_FRONTEND = slang
export SYNTH_SLANG_ARGS = --allow-toplevel-iface-ports
export SYNTH_MEMORY_MAX_BITS = 4096
export SYNTH_MOCK_LARGE_MEMORIES = 0
