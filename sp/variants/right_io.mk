# SP SRAM bands with all signal IO on the right and C-shaped row exclusions.
include $(dir $(lastword $(MAKEFILE_LIST)))sram_bands.mk
export MACRO_PLACEMENT_TCL = /work/scripts/sp/place_right_io.tcl
export IO_CONSTRAINTS = /work/scripts/sp/io_right.tcl
export SP_IO_CORRIDOR = 40
export SP_LOGIC_GAP = 8
export SP_KEEP_HALO = 4
export PRE_CTS_TCL = /work/scripts/common/pre_cts.tcl
export POST_PDN_TCL = /work/scripts/sp/checks.tcl
export POST_DETAIL_PLACE_TCL = /work/scripts/sp/checks.tcl
export POST_CTS_TCL = /work/scripts/sp/checks.tcl
export POST_GLOBAL_ROUTE_TCL = /work/scripts/sp/checks.tcl
export POST_FINAL_REPORT_TCL = /work/scripts/sp/checks.tcl
