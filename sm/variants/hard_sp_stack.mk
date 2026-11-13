SM_NUM_SPS := 4
SM_NUM_LANES := 16
include $(dir $(lastword $(MAKEFILE_LIST)))../config.mk

ifneq ($(SM_NUM_SPS):$(SM_NUM_LANES),4:16)
$(error hard_sp_stack requires four 16-lane SP macros; rebuild SP views for other dimensions)
endif

# SP is a fixed 16-lane hard macro; synthesize only the SM shell and shared L1.
SP_MACRO_DIR ?= /work/artifacts/asic/sp/sram_bands/results
SM_SHELL_SOURCES := $(filter-out $(SM_RTL_DIR)/sm/sp/%,$(SM_SOURCES))
export VERILOG_FILES := $(SM_PACKAGE) \
    $(patsubst $(SM_RTL_DIR)/%,/hardware/rtl/%,$(SM_SHELL_SOURCES)) \
    /work/sram/cache_line_ram.sv /work/sm/sp_macro.sv
export ADDITIONAL_LIBS = $(SP_MACRO_DIR)/sp_pd_top_typ.lib \
    $(L1_MACRO)_TT_1p1V_25C.lib
export ADDITIONAL_LEFS = $(SP_MACRO_DIR)/sp_pd_top.lef \
    $(L1_MACRO).lef
export ADDITIONAL_GDS = $(SP_MACRO_DIR)/6_final.gds \
    $(L1_MACRO).gds

# SP must be rebuilt and exported from the current RTL before SM assembly.
export CORE_UTILIZATION =
export HOLD_SLACK_MARGIN = 0.05
export POST_CTS_TCL = /work/scripts/common/repair_hold.tcl
export POST_GLOBAL_ROUTE_TCL = /work/scripts/common/repair_hold.tcl
export GLOBAL_ROUTE_ARGS = -congestion_iterations 300 -verbose
export GRT_SEED = 1

# GUI-only expansion of the hardened SP; not used during implementation.
export DETAIL_BLOCKS = sp_pd_top $(SP_MACRO_DIR)/6_final.odb
export DETAIL_LEFS = $(VRF_MACRO).lef \
    $(IRAM_MACRO).lef

DESIGN_ARGS += SP_MACRO_DIR=$(SP_MACRO_DIR)

# Four hard SPs in a vertical stack with a central, rotated shared L1 cluster.
export DIE_AREA = 0 0 1571 4095
export CORE_AREA = 20 20 1551 4075
export MACRO_PLACEMENT_TCL = /work/scripts/sm/place_hard_sp_stack.tcl
export PDN_TCL = /work/scripts/sm/pdn_hard_sp.tcl
export IO_CONSTRAINTS = /work/scripts/sm/io_right.tcl
export COMPACT_CHANNEL = 40
export COMPACT_EDGE = 40
export L1_CLUSTER_ORIENT = R270
export L1_CLUSTER_GAP = 12
export L1_CLUSTER_COUNT = 4
export L1_CLUSTER_MASTER = gpc_sram_1rw_64x70
export PLACE_PINS_ARGS = -min_distance 2
export LEC_CHECK = 1
export PRE_CTS_TCL = /work/scripts/common/pre_cts.tcl
export PRE_GLOBAL_ROUTE_TCL = /work/scripts/common/repair_budget.tcl
export POST_FINAL_REPORT_TCL = /work/scripts/sm/checks.tcl
