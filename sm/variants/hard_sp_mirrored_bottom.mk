# Preserve the mirrored right-IO experiment; use a separate bottom-IO run.
include $(dir $(lastword $(MAKEFILE_LIST)))hard_sp_mirrored.mk
export IO_CONSTRAINTS = /work/scripts/common/io_bottom.tcl
export SM_IO_EDGE = bottom
# The long bottom edge fits the signal pins at the original 2um spacing.
export PLACE_PINS_ARGS = -min_distance 2

# 0 lets PPL optimize individual pins along the edge; 1 keeps the baseline group.
SM_BOTTOM_GROUP ?= 1
export SM_BOTTOM_GROUP
DESIGN_ARGS += SM_BOTTOM_GROUP=$(SM_BOTTOM_GROUP)
