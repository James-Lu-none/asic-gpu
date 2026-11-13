# Placement and final reports share power/area checks. Final adds the module view.
source /work/scripts/common/check_power.tcl
if {$env_var eq "POST_FINAL_REPORT_TCL"} {
    source /work/scripts/reports/module_view.tcl
} elseif {$env_var ne "POST_DETAIL_PLACE_TCL"} {
    error "Unsupported audit hook: $env_var"
}
source /work/scripts/reports/area.tcl
