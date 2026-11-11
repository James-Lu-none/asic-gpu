SM_NUM_SPS := 4
SM_NUM_LANES := 16
include $(dir $(lastword $(MAKEFILE_LIST)))../config.mk

ifneq ($(SM_NUM_SPS):$(SM_NUM_LANES),4:16)
$(error sp4_hard_l16 requires four 16-lane SP macros; rebuild SP views for other dimensions)
endif

# SP is a fixed 16-lane hard macro; synthesize only the SM shell and shared L1.
SP_MACRO_DIR = /work/artifacts/asic/sp/ar1_hold100/results
SM_SHELL_SOURCES := $(filter-out $(SM_RTL_DIR)/sm/sp/%,$(SM_SOURCES))
export VERILOG_FILES := $(SM_PACKAGE) \
    $(patsubst $(SM_RTL_DIR)/%,/hardware/rtl/%,$(SM_SHELL_SOURCES)) \
    /work/gpc/sram/cache_line_ram.sv /work/sm/sp_macro.sv
export ADDITIONAL_LIBS = $(SP_MACRO_DIR)/sp_pd_top_typ.lib \
    $(SRAM_ROOT)/cache_l1_64x70/gpc_sram_1rw_64x70_TT_1p1V_25C.lib
export ADDITIONAL_LEFS = $(SP_MACRO_DIR)/sp_pd_top.lef \
    $(SRAM_ROOT)/cache_l1_64x70/gpc_sram_1rw_64x70.lef
export ADDITIONAL_GDS = $(SP_MACRO_DIR)/6_final.gds \
    $(SRAM_ROOT)/cache_l1_64x70/gpc_sram_1rw_64x70.gds

# 2 x 2 completed 1478.175 um SPs, with outer and central integration channels.
export CORE_UTILIZATION =
export DIE_AREA = 0 0 3440 3440
export CORE_AREA = 20 20 3420 3420
export MACRO_PLACEMENT_TCL = /work/sm/macro_placement.tcl
export PDN_TCL = /work/sm/pdn.tcl
export HOLD_SLACK_MARGIN = 0.05
export POST_CTS_TCL = /work/scripts/repair_hold.tcl
export PRE_GLOBAL_ROUTE_TCL = /work/scripts/repair_hold.tcl
export POST_GLOBAL_ROUTE_TCL = /work/scripts/repair_hold.tcl
export GLOBAL_ROUTE_ARGS = -congestion_iterations 300 -verbose
export GRT_SEED = 1

# GUI-only expansion of the hardened SP; not used during implementation.
export DETAIL_BLOCKS = sp_pd_top $(SP_MACRO_DIR)/6_final.odb
export DETAIL_LEFS = $(SRAM_ROOT)/vrf_128x32/gpc_sram_1rw1r_128x32.lef \
    $(SRAM_ROOT)/iram_1024x32/gpc_sram_1rw1r_1024x32.lef
