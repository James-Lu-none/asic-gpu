# Compress only the channel; preserve the passing four-region geometry and timing.
GPC_CHANNEL ?= 900
include $(dir $(lastword $(MAKEFILE_LIST)))hard_sm_pair_l2_valid_regions.mk
