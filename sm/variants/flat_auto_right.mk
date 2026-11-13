# Flat 4x16 SM, with automatic macro placement and right-edge signal IO.
# Share die/SDC/RTL/repair settings with the fixed-SRAM comparison, but do not
# source its placement script or force SRAM positions/orientations.
include $(dir $(lastword $(MAKEFILE_LIST)))flat_fixed_right.mk
export MACRO_PLACEMENT_TCL =
export FLAT_SP_WIDTH =
export FLAT_SP_HEIGHT =
export FLAT_EDGE =
export FLAT_CHANNEL =
export PDN_TCL = /work/scripts/sm/pdn_flat.tcl
