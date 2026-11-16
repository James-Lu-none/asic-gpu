# Use one explicit ASIC architecture configuration for checks and synthesis.
include $(dir $(lastword $(MAKEFILE_LIST)))asic_defines.mk
export VERILOG_DEFINES += -DNUM_SMS=$(GPU_NUM_SMS) -DNUM_SPS=$(GPU_NUM_SPS) -DNUM_LANES=$(GPU_NUM_LANES)
ifeq ($(strip $(GPU_NUM_SMS)),)
$(error Set GPU_NUM_SMS in config/asic_defines.mk)
endif
ifeq ($(strip $(GPU_NUM_LANES)),)
$(error Set GPU_NUM_LANES in config/asic_defines.mk)
endif
ifeq ($(strip $(GPU_NUM_SPS)),)
$(error Set GPU_NUM_SPS in config/asic_defines.mk)
endif
# Include headers as source prerequisites so define changes trigger synthesis.
GPU_HEADERS = /hardware/rtl/common/gpu_defines.vh /hardware/rtl/common/gpu_debug.vh
