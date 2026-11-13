# Entry point for the right_io SP variant; keep checks identical at each stage.
switch -- $env_var {
    POST_PDN_TCL {
        source /work/scripts/common/check_floorplan.tcl
        set check_pins 0
    }
    POST_DETAIL_PLACE_TCL - POST_FINAL_REPORT_TCL {
        source /work/scripts/common/audit.tcl
        set check_pins 1
    }
    POST_CTS_TCL - POST_GLOBAL_ROUTE_TCL {
        source /work/scripts/common/repair_hold.tcl
        set check_pins 1
    }
    default {error "Unsupported right_io SP hook: $env_var"}
}
source /work/scripts/sp/right_region.tcl
right_region_check $check_pins
