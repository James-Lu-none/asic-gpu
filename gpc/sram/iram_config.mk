# Standalone instruction memory with the same macro view used by GPC.
include $(dir $(lastword $(MAKEFILE_LIST)))../config.mk
export DESIGN_NAME = instruction_ram
export DESIGN_NICKNAME = iram
export VERILOG_FILES = /hardware/rtl/gpu_pkg.sv /work/gpc/sram/instruction_ram.sv
export SDC_FILE = /work/gpc/sram/iram.sdc
export ADDITIONAL_LIBS = $(IRAM_MACRO)_TT_1p1V_25C.lib
export ADDITIONAL_LEFS = $(IRAM_MACRO).lef
export ADDITIONAL_GDS = $(IRAM_MACRO).gds
