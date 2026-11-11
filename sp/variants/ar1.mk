include $(dir $(lastword $(MAKEFILE_LIST)))../config.mk
# ORFS uses height / width; width:height = 1:1.
export CORE_ASPECT_RATIO = 1
# 30 iterations left two M6 overflows near IRAM inputs; 100 cleared them.
export GLOBAL_ROUTE_ARGS = -congestion_iterations 100 -verbose
