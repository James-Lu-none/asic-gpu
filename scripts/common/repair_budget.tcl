# Apply the baseline's 100% hold-buffer budget to native repair too. Otherwise
# native CTS can abort at its 20% default before POST_CTS_TCL is reached.
if {[llength [info commands asic_original_repair_timing_helper]] == 0} {
    rename repair_timing_helper asic_original_repair_timing_helper
    proc repair_timing_helper {args} {
        asic_original_repair_timing_helper {*}$args -max_buffer_percent 100
    }
}
if {$env_var eq "PRE_GLOBAL_ROUTE_TCL"} {
    # Negotiation legalizer left repair-cell overlaps in the narrow central band.
    # Use the supported diamond legalizer and retain all native checks.
    set ::env(DETAIL_PLACEMENT_ARGS) {-use_diamond_legalizer -max_displacement {500 500}}
    source /work/scripts/common/repair_hold.tcl
}
