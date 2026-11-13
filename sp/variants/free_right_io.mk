# Same die/core, density, timing and IO as right_io; all macros placed by RTLMP.
# Start from the shared band preset, then disable its fixed macro placement.
include $(dir $(lastword $(MAKEFILE_LIST)))sram_bands.mk
export MACRO_PLACEMENT_TCL =
# Nangate45 defaults to 44.8 x 30.24um channels, which over-inflate the
# movable macro area for this compact die. Match the existing 8um SRAM gap.
export RTLMP_MIN_CHANNEL_SIZE = 8 8
export IO_CONSTRAINTS = /work/scripts/sp/io_right.tcl
export SP_BANK_GAP =
export SP_EDGE =
export PRE_CTS_TCL = /work/scripts/common/pre_cts.tcl
# No C-shaped blockages, row clipping, or fixed-region checks.
export POST_PDN_TCL = /work/scripts/common/check_floorplan.tcl
export POST_DETAIL_PLACE_TCL = /work/scripts/common/audit.tcl
export POST_CTS_TCL = /work/scripts/common/repair_hold.tcl
export POST_GLOBAL_ROUTE_TCL = /work/scripts/common/repair_hold.tcl
export POST_FINAL_REPORT_TCL = /work/scripts/common/audit.tcl
