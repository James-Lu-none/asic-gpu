# Isolated shared VRF with the same macro implementation used by GPC.
include $(dir $(lastword $(MAKEFILE_LIST)))../config.mk
export DESIGN_NAME = vector_regfile
export DESIGN_NICKNAME = vrf
export VERILOG_FILES = /hardware/rtl/gpu_pkg.sv \
    /hardware/rtl/common/gpu_interfaces.sv /hardware/rtl/sm/sp/vector_regfile.sv \
    /work/gpc/sram/vector_regfile_ram.sv
export SDC_FILE = /work/gpc/sram/vrf.sdc
export ADDITIONAL_LIBS = $(VRF_MACRO)_TT_1p1V_25C.lib
export ADDITIONAL_LEFS = $(VRF_MACRO).lef
export ADDITIONAL_GDS = $(VRF_MACRO).gds
