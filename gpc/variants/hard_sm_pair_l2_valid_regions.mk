# Controlled comparison against the passing 1000um, 100ps, single-row baseline.
include $(dir $(lastword $(MAKEFILE_LIST)))hard_sm_pair_l2_row.mk
# Keep 3-site padding on the four valid-bit groups and their exclusive cones.
export PRE_GLOBAL_PLACE_SKIP_IO_TCL = /work/scripts/gpc/region_l2_valid.tcl
export PRE_GLOBAL_PLACE_TCL = /work/scripts/gpc/region_l2_valid.tcl
export PRE_DETAIL_PLACE_TCL = /work/scripts/gpc/region_l2_valid.tcl
export POST_DETAIL_PLACE_TCL = /work/scripts/gpc/check_l2_regions.tcl
