# Reuse the same RTL package generation, technology and SRAM integration as SM.
SM_NUM_SPS := 1
SM_NUM_LANES ?= 16
include $(dir $(lastword $(MAKEFILE_LIST)))../sm/config.mk

export DESIGN_NAME = sp_pd_top
export DESIGN_NICKNAME = sp
export VERILOG_FILES := $(filter-out /work/sram/cache_line_ram.sv,$(VERILOG_FILES)) /work/sp/sp_pd_top.sv
SM_MACROS = $(VRF_MACRO) $(IRAM_MACRO)

export SDC_FILE = /work/sp/constraints.sdc
export IO_CONSTRAINTS = /work/scripts/sp/io_default.tcl
export CORE_UTILIZATION = 45
export CORE_ASPECT_RATIO = 1
