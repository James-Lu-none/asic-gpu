# Preserve automatic macro placement and right-side IO; enlarge each die axis 15%.
include $(dir $(lastword $(MAKEFILE_LIST)))free_right_io.mk
export DIE_AREA = 0 0 1558.37 1119.69
export CORE_AREA = 10 10 1548.37 1109.69
# The larger physical core leaves room to spread standard cells around SRAMs.
export PLACE_DENSITY = 0.55
