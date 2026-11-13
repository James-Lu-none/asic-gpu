# CTS: extend the hold-buffer budget, then legalize and check placement timing.
# Global route: apply the same repair using routed RC, then reroute added buffers.
# ORFS source_env_var_if_exists supplies the hook name as env_var.
if {$env_var eq "PRE_GLOBAL_ROUTE_TCL"} {
    set_global_routing_layer_adjustment metal4-$::env(MAX_ROUTING_LAYER) 0.10
    return
}
set routed [grt::have_routes]
set_propagated_clock [all_clocks]
log_cmd estimate_parasitics
if {$routed} {
    log_cmd global_route -start_incremental
}
log_cmd repair_timing -hold -max_buffer_percent 100 \
    -hold_margin $::env(HOLD_SLACK_MARGIN) -verbose
detailed_placement_helper -quiet
log_cmd check_placement -placeable -verbose
if {$routed} {
    log_cmd global_route -end_incremental {*}$::env(GLOBAL_ROUTE_ARGS) \
        -congestion_report_file $::env(REPORTS_DIR)/congestion_post_hold100.rpt
}
log_cmd estimate_parasitics
if {$routed} {
    report_metrics 5 "global route hold repaired"
} else {
    report_metrics 4 "cts hold repaired"
}
source /work/scripts/common/check_power.tcl
