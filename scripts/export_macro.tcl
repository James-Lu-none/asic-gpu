# Export the completed block as a hard macro, using extracted timing.
source $::env(SCRIPTS_DIR)/load.tcl
load_design 6_final.odb 6_final.sdc
read_spef $::env(RESULTS_DIR)/6_final.spef
set_propagated_clock [all_clocks]
set_clock_latency -source 0 [all_clocks]
if {[info exists ::env(CORNERS)] && $::env(CORNERS) ne ""} {
    foreach corner $::env(CORNERS) {
        log_cmd write_timing_model -scene $corner $::env(RESULTS_DIR)/$::env(DESIGN_NAME)_$corner.lib
    }
} else {
    log_cmd write_timing_model $::env(RESULTS_DIR)/$::env(DESIGN_NAME)_typ.lib
}
# Keep geometry-based obstructions: blanket occupied-layer obstructions prevent
# the parent PDN from accessing M7 power pins through the upper metal layers.
if {[info exists ::env(MACRO_BLOCKED_LAYERS)]} {
    set block [ord::get_db_block]
    set area [$block getDieArea]
    foreach name $::env(MACRO_BLOCKED_LAYERS) {
        set layer [[ord::get_db_tech] findLayer $name]
        if {$layer eq "NULL"} {error "Unknown macro obstruction layer: $name"}
        odb::dbObstruction_create $block $layer \
            [$area xMin] [$area yMin] [$area xMax] [$area yMax]
    }
}
log_cmd write_abstract_lef -bloat_factor 0 $::env(RESULTS_DIR)/$::env(DESIGN_NAME).lef
