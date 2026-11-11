include $(dir $(lastword $(MAKEFILE_LIST)))ar1.mk
# Repair beyond zero before detailed routing; the SDC limits are unchanged.
export HOLD_SLACK_MARGIN = 0.05
export POST_CTS_TCL = /work/sp/repair_hold.tcl
export POST_GLOBAL_ROUTE_TCL = /work/sp/repair_hold.tcl
# Reduce upper-layer capacity reservation after hold buffering (25% left 47 overflow; 13% left 2).
export PRE_GLOBAL_ROUTE_TCL = /work/sp/repair_hold.tcl
# Extra routing effort for the denser hold-buffered placement.
export GLOBAL_ROUTE_ARGS = -congestion_iterations 300 -verbose
export GRT_SEED = 1
