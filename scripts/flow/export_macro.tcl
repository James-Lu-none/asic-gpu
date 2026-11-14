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

# SP keeps its qualified Y symmetry by default. Other mirror axes may be
# requested only after checking the physical symmetry of all nested leaf masters.
set abstract_symmetry {}
if {$::env(DESIGN_NAME) eq "sp_pd_top"} {set abstract_symmetry {Y}}
if {[info exists ::env(MACRO_SYMMETRY)]} {
    set abstract_symmetry $::env(MACRO_SYMMETRY)
    foreach axis $abstract_symmetry {
        if {$axis ni {X Y}} {error "Unsupported abstract symmetry $axis"}
    }
}
if {[llength $abstract_symmetry]} {
    set symmetry_line "SYMMETRY [join $abstract_symmetry { }] ;"
    set lef_path "$::env(RESULTS_DIR)/$::env(DESIGN_NAME).lef"
    set lef_file [open $lef_path r]
    set lef_text [read $lef_file]
    close $lef_file
    if {![regexp {SYMMETRY[^;]*;} $lef_text]} {
        set lef_text [string map [list "  CLASS BLOCK ;" "  CLASS BLOCK ;\n  $symmetry_line"] $lef_text]
    } else {
        regsub {SYMMETRY[^;]*;} $lef_text $symmetry_line lef_text
    }
    if {[string first $symmetry_line $lef_text] < 0} {error "Could not declare macro mirror symmetry"}
    set lef_file [open $lef_path w]
    puts -nonewline $lef_file $lef_text
    close $lef_file
}
