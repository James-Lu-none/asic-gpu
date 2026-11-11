# Standalone instruction memory with the shared macro view.
include $(dir $(lastword $(MAKEFILE_LIST)))block_config.mk
export DESIGN_NAME = instruction_ram
export DESIGN_NICKNAME = iram
export VERILOG_FILES = /hardware/rtl/gpu_pkg.sv /work/sram/instruction_ram.sv
export SDC_FILE = /work/sram/iram.sdc
export ADDITIONAL_LIBS = $(IRAM_MACRO)_TT_1p1V_25C.lib
export ADDITIONAL_LEFS = $(IRAM_MACRO).lef
export ADDITIONAL_GDS = $(IRAM_MACRO).gds
