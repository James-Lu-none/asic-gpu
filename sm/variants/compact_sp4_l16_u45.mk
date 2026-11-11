SM_NUM_SPS ?= 4
SM_NUM_LANES ?= 16
include $(dir $(lastword $(MAKEFILE_LIST)))../config.mk
export CORE_UTILIZATION = 45
