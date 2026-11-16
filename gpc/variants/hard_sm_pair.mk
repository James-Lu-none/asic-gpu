GPC_CONFIG_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../..)
include $(dir $(lastword $(MAKEFILE_LIST)))../config.mk
ifneq ($(GPU_NUM_SMS):$(GPU_NUM_SPS):$(GPU_NUM_LANES),2:4:16)
$(error hard_sm_pair requires NUM_SMS=2 NUM_SPS=4 NUM_LANES=16)
endif
SM_MACRO_DIR ?= /work/artifacts/asic/sm/hard_sp_mirrored_bottom_c600_freepins_h80/results
GPC_SHELL_SOURCES := $(filter-out $(GPC_RTL_DIR)/sm/%,$(GPC_SOURCES))
export VERILOG_FILES = $(GPU_HEADERS) $(patsubst $(GPC_RTL_DIR)/%,/hardware/rtl/%,$(GPC_SHELL_SOURCES)) /work/sram/cache_line_ram.sv /work/gpc/sm_macro.sv
export ADDITIONAL_LIBS = $(SM_MACRO_DIR)/streaming_multiprocessor_typ.lib $(L2_MACRO)_TT_1p1V_25C.lib
export ADDITIONAL_LEFS = $(SM_MACRO_DIR)/streaming_multiprocessor.lef $(L2_MACRO).lef
export ADDITIONAL_GDS = $(SM_MACRO_DIR)/6_final.gds $(L2_MACRO).gds
GPC_CHANNEL ?= 1000
GPC_SIDE_MARGIN ?= 200
GPC_EDGE ?= 40
GPC_L2_COLUMNS ?= 2
export GPC_CHANNEL GPC_SIDE_MARGIN GPC_EDGE GPC_L2_COLUMNS
export GPC_L2_GAP = 20
GPC_SM_LEF := $(if $(wildcard $(SM_MACRO_DIR)/streaming_multiprocessor.lef),$(SM_MACRO_DIR)/streaming_multiprocessor.lef,$(patsubst /work/%,$(GPC_CONFIG_ROOT)/%,$(SM_MACRO_DIR)/streaming_multiprocessor.lef))
GPC_L2_LEF := $(if $(wildcard $(L2_MACRO).lef),$(L2_MACRO).lef,$(patsubst /work/%,$(GPC_CONFIG_ROOT)/%,$(L2_MACRO).lef))
GPC_DIMS := $(shell python3 $(GPC_CONFIG_ROOT)/scripts/flow/gpc_dimensions.py --sm-lef $(GPC_SM_LEF) --l2-lef $(GPC_L2_LEF) --channel $(GPC_CHANNEL) --side $(GPC_SIDE_MARGIN) --edge $(GPC_EDGE) --l2-columns $(GPC_L2_COLUMNS))
ifneq ($(words $(GPC_DIMS)),4)
$(error Export qualified SM LEF/Liberty before building hard_sm_pair)
endif
export CORE_UTILIZATION =
export DIE_AREA = 0 0 $(word 1,$(GPC_DIMS)) $(word 2,$(GPC_DIMS))
export CORE_AREA = 20 20 $(word 3,$(GPC_DIMS)) $(word 4,$(GPC_DIMS))
export MACRO_PLACEMENT_TCL = /work/scripts/gpc/place_hard_sm_pair.tcl
export PDN_TCL = /work/scripts/gpc/pdn_hard_sm.tcl
export IO_CONSTRAINTS = /work/scripts/gpc/io_channel.tcl
export PLACE_PINS_ARGS = -min_distance 1
export LEC_CHECK = 1
DESIGN_ARGS += SM_MACRO_DIR=$(SM_MACRO_DIR) GPC_CHANNEL=$(GPC_CHANNEL) GPC_SIDE_MARGIN=$(GPC_SIDE_MARGIN) GPC_EDGE=$(GPC_EDGE) GPC_L2_COLUMNS=$(GPC_L2_COLUMNS)

# GUI only: expand SM geometry first, then the nested SP hard macros.
SP_MACRO_DIR ?= /work/artifacts/asic/sp/free_right_io_large/results
export DETAIL_BLOCKS = streaming_multiprocessor $(SM_MACRO_DIR)/6_final.odb sp_pd_top $(SP_MACRO_DIR)/6_final.odb
export DETAIL_LEFS = $(SP_MACRO_DIR)/sp_pd_top.lef $(L1_MACRO).lef $(VRF_MACRO).lef $(IRAM_MACRO).lef
DESIGN_ARGS += SP_MACRO_DIR=$(SP_MACRO_DIR)
