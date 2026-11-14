# Two columns/two rows; left SPs face right and right SPs mirror toward center.
# Reuse the hard-IP source, timing budget, right IO and PDN integration.
SM_RIGHT_SPACE ?= 200
include $(dir $(lastword $(MAKEFILE_LIST)))hard_sp_stack.mk
SM_CENTER_SPACE ?= 1000
SM_ROW_GAP ?= 80
export SP_CENTER_SPACE = $(SM_CENTER_SPACE)
export SP_ROW_GAP = $(SM_ROW_GAP)
MIRROR_DIMENSIONS := $(shell python3 $(HARD_SP_CONFIG_ROOT)/scripts/flow/stack_dimensions.py --sp-lef $(STACK_SP_LEF) --l1-lef $(STACK_L1_LEF) --layout mirror --center-space $(SM_CENTER_SPACE) --row-gap $(SM_ROW_GAP) --right-space $(SM_RIGHT_SPACE) --edge $(COMPACT_EDGE) --channel $(COMPACT_CHANNEL))
ifneq ($(words $(MIRROR_DIMENSIONS)),4)
$(error Cannot size mirrored SP layout; check exported LEFs and channel dimensions)
endif
export DIE_AREA = 0 0 $(word 1,$(MIRROR_DIMENSIONS)) $(word 2,$(MIRROR_DIMENSIONS))
export CORE_AREA = 20 20 $(word 3,$(MIRROR_DIMENSIONS)) $(word 4,$(MIRROR_DIMENSIONS))
export MACRO_PLACEMENT_TCL = /work/scripts/sm/place_hard_sp_mirrored.tcl
# The shorter right edge cannot hold 1223 signals at the stack's 2um spacing.
# Use 1um spacing (rounded up to legal tracks); preserve the all-right contract.
export PLACE_PINS_ARGS = -min_distance 1
DESIGN_ARGS += SM_CENTER_SPACE=$(SM_CENTER_SPACE) SM_ROW_GAP=$(SM_ROW_GAP)
