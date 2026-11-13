# 16-lane SP with fixed top/bottom VRF bands and left IRAM.
include $(dir $(lastword $(MAKEFILE_LIST)))../config.mk
# Repair beyond zero before detailed routing; the SDC limits are unchanged.
export HOLD_SLACK_MARGIN = 0.05
export POST_CTS_TCL = /work/scripts/common/repair_hold.tcl
export POST_GLOBAL_ROUTE_TCL = /work/scripts/common/repair_hold.tcl
# Routing capacity reservation used during hold repair.
export PRE_GLOBAL_ROUTE_TCL = /work/scripts/common/repair_hold.tcl
# Extra routing effort for the denser hold-buffered placement.
export GLOBAL_ROUTE_ARGS = -congestion_iterations 300 -verbose
export GRT_SEED = 1

# Reserve internal routing; keep upper metals accessible to the parent PDN.
export MACRO_BLOCKED_LAYERS = metal1 metal2 metal3 metal4 metal5 metal6
export CORE_UTILIZATION =
export CORE_ASPECT_RATIO = 0.71428571
export DIE_AREA = 0 0 1355.10 973.64
export CORE_AREA = 10 10 1345.10 963.64
export PLACE_DENSITY = 0.75
export SP_BANK_GAP = 8
export SP_EDGE = 8
export MACRO_PLACEMENT_TCL = /work/scripts/sp/place_sram_bands.tcl
export POST_FINAL_REPORT_TCL = /work/scripts/common/audit.tcl
export POST_DETAIL_PLACE_TCL = /work/scripts/common/audit.tcl
export LEC_CHECK = 1
export PRE_CTS_TCL = /work/scripts/common/repair_budget.tcl
export PRE_GLOBAL_ROUTE_TCL = /work/scripts/common/repair_budget.tcl
