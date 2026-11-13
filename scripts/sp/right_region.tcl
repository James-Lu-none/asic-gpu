# All geometry uses DBU, including audits after repair and filler insertion.
proc right_region_geometry {} {
    set b [ord::get_db_block]
    set units [$b getDbUnitsPerMicron]
    set c [$b getCoreArea]
    set center [expr {([$c yMin]+[$c yMax])/2.0}]
    set lower_top [$c yMin]
    set upper_bottom [$c yMax]
    set bank_right [$c xMin]
    set iram_right 0
    set nvrf 0; set niram 0
    foreach inst [$b getInsts] {
        set m [$inst getMaster]
        if {![$m isBlock]} {continue}
        set box [$inst getBBox]
        if {[$m getName] eq "gpc_sram_1rw1r_128x32"} {
            incr nvrf
            set bank_right [expr {max($bank_right,[$box xMax])}]
            if {([$box yMin]+[$box yMax])/2.0 < $center} {
                set lower_top [expr {max($lower_top,[$box yMax])}]
            } else {set upper_bottom [expr {min($upper_bottom,[$box yMin])}]}
        } elseif {[$m getName] eq "gpc_sram_1rw1r_1024x32"} {
            incr niram
            set iram_right [$box xMax]
        } else {error "Unexpected macro [$m getName]"}
    }
    if {$nvrf != 32 || $niram != 1} {error "Unexpected SP macro counts"}
    set gap [expr {round($::env(SP_LOGIC_GAP)*$units)}]
    set halo [expr {round($::env(SP_KEEP_HALO)*$units)}]
    set strip [expr {max([$c xMax]-round($::env(SP_IO_CORRIDOR)*$units),$bank_right+$halo)}]
    if {[$c xMax]-$strip < 30*$units} {error "Insufficient IO corridor"}
    return [dict create main [list [expr {$iram_right+$gap}] [expr {$lower_top+$gap}] [$c xMax] [expr {$upper_bottom-$gap}]] \
        corridor [list $strip [$c yMin] [$c xMax] [$c yMax]]]
}
proc right_region_contains {rect box} {
    lassign $rect x0 y0 x1 y1
    return [expr {[$box xMin] >= $x0 && [$box yMin] >= $y0 && [$box xMax] <= $x1 && [$box yMax] <= $y1}]
}
proc right_region_check {check_pins} {
    set b [ord::get_db_block]
    set g [right_region_geometry]
    set count 0
    foreach inst [$b getInsts] {
        if {[[$inst getMaster] isBlock] || ![$inst isPlaced]} {continue}
        set box [$inst getBBox]
        if {![right_region_contains [dict get $g main] $box] && ![right_region_contains [dict get $g corridor] $box]} {
            error "Standard cell outside main/IO region: [$inst getName]"
        }
        incr count
    }
    set pin_count 0
    if {$check_pins} {
        set units [$b getDbUnitsPerMicron]
        set right [[$b getDieArea] xMax]
        foreach term [$b getBTerms] {
            if {[$term getSigType] in {POWER GROUND}} {continue}
            set boxes 0
            foreach pin [$term getBPins] {
                foreach box [$pin getBoxes] {
                    if {abs([$box xMax]-$right) > $units} {error "IO is not on right edge: [$term getName]"}
                    incr boxes
                }
            }
            if {$boxes == 0} {error "IO has no geometry: [$term getName]"}
            incr pin_count
        }
    }
    set f [open "$::env(REPORTS_DIR)/right_region_checks.json" w]
    puts $f [format {{"placed_standard_cells": %d, "right_signal_pins": %d, "region_violations": 0, "main_dbu": [%s], "corridor_dbu": [%s]}} $count $pin_count [join [dict get $g main] {, }] [join [dict get $g corridor] {, }]]
    close $f
    puts "RIGHT_REGION_PASS: $count standard cells; $pin_count right-side signal pins"
}
