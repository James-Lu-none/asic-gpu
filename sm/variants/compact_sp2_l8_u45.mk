SM_NUM_SPS ?= 2
SM_NUM_LANES ?= 8
include $(dir $(lastword $(MAKEFILE_LIST)))../config.mk
export CORE_UTILIZATION = 45
