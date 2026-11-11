SM_NUM_SPS ?= 4
SM_NUM_LANES ?= 32
include $(dir $(lastword $(MAKEFILE_LIST)))../config.mk
export CORE_UTILIZATION = 45
# Eight-entry LSU FIFO/writeback data arrays: 32 lanes x 32 bits x 8.
# Keep these queues as FFs; VRF/IRAM/cache remain real SRAM macros.
export SYNTH_MEMORY_MAX_BITS = 8192
