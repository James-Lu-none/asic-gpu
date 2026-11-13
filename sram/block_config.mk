# Standalone SRAM-boundary blocks; no GPC RTL, IO or constraints are imported.
export PLATFORM = nangate45
HARDWARE_ROOT ?= $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../../fpga-gpu-hardware)
include $(dir $(lastword $(MAKEFILE_LIST)))views.mk
DESIGN_ARGS = SRAM_ROOT=$(SRAM_ROOT)
export VERILOG_INCLUDE_DIRS = /hardware/rtl/common
export SYNTH_HDL_FRONTEND = slang
export SYNTH_SLANG_ARGS = --allow-toplevel-iface-ports
export SYNTH_MEMORY_MAX_BITS = 4096
export SYNTH_MOCK_LARGE_MEMORIES = 0
export CORE_UTILIZATION = 35
export PLACE_DENSITY = 0.55
export TNS_END_PERCENT = 100
# Reuse the existing hierarchy-independent physical integration hooks.
include $(dir $(lastword $(MAKEFILE_LIST)))../config/nangate45_sram.mk
