# Flat 4 x 16-lane SM control: SRAM macros only, no hardened SP views.
SM_NUM_SPS := 4
SM_NUM_LANES := 16
include $(dir $(lastword $(MAKEFILE_LIST)))../config.mk
ifneq ($(SM_NUM_SPS):$(SM_NUM_LANES),4:16)
$(error flat_fixed_right requires four 16-lane SPs)
endif

# Same nominal envelope as hard_sp_stack. SP logic is placed globally;
# the four SRAM bands are placement anchors, not hard SP boundaries.
export CORE_UTILIZATION =
export DIE_AREA = 0 0 1571 4095
export CORE_AREA = 20 20 1551 4075
export FLAT_SP_WIDTH = 1355.10
export FLAT_SP_HEIGHT = 973.64
export FLAT_EDGE = 40
export FLAT_CHANNEL = 40
export MACRO_PLACEMENT_TCL = /work/scripts/sm/place_flat_sram.tcl
export IO_CONSTRAINTS = /work/scripts/sm/io_right.tcl
export PLACE_PINS_ARGS = -min_distance 2
export PDN_TCL = /work/scripts/sm/pdn_flat.tcl

export HOLD_SLACK_MARGIN = 0.05
export LEC_CHECK = 1
export PRE_CTS_TCL = /work/scripts/common/pre_cts.tcl
export POST_CTS_TCL = /work/scripts/common/repair_hold.tcl
export PRE_GLOBAL_ROUTE_TCL = /work/scripts/common/repair_budget.tcl
export POST_GLOBAL_ROUTE_TCL = /work/scripts/common/repair_hold.tcl
export GLOBAL_ROUTE_ARGS = -congestion_iterations 300 -verbose
export GRT_SEED = 1
export POST_DETAIL_PLACE_TCL = /work/scripts/sm/checks.tcl
export POST_FINAL_REPORT_TCL = /work/scripts/sm/checks.tcl
