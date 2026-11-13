# Shared Nangate45/OpenRAM defaults. Design variants may override these hooks.
export FOOTPRINT_TCL = /work/scripts/sram/technology.tcl
export TAPCELL_TCL = /work/scripts/common/tapcell.tcl
export PDN_TCL = /work/scripts/common/pdn_sram.tcl
export POST_PDN_TCL = /work/scripts/common/check_floorplan.tcl
export POST_DETAIL_PLACE_TCL = /work/scripts/common/check_power.tcl
export POST_CTS_TCL = /work/scripts/common/check_power.tcl
export POST_GLOBAL_ROUTE_TCL = /work/scripts/common/check_power.tcl
export MACRO_ROWS_HALO_X = 4
export MACRO_ROWS_HALO_Y = 4
