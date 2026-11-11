include $(dir $(lastword $(MAKEFILE_LIST)))../config.mk
# ORFS uses height / width; width:height = 1.5:1.
export CORE_ASPECT_RATIO = 0.666666667
