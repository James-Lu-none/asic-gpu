# Reuse the successful larger SP/SM IP; change only placement around L2 valid bits.
SM_MACRO_DIR ?= /work/artifacts/asic/sm/hard_sp_mirrored_bottom_sp15/results
include $(dir $(lastword $(MAKEFILE_LIST)))hard_sm_pair.mk
export PLACE_DENSITY = 0.45
export GRT_SEED = 2
# Extra effort had diminishing returns; inspect this run before increasing it.
export GLOBAL_ROUTE_ARGS = -congestion_iterations 60 -verbose
export PRE_GLOBAL_PLACE_TCL = /work/scripts/gpc/pad_l2_valid.tcl
export PRE_DETAIL_PLACE_TCL = /work/scripts/gpc/pad_l2_valid.tcl
