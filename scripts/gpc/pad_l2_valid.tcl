# Leave routing space around the valid-bit cluster, including nearby mux/decode
# cells with synthesized names. Recompute its bounds at each placement stage.
set block [ord::get_db_block]
set units [$block getDbUnitsPerMicron]
set x0 1e30; set y0 1e30; set x1 -1e30; set y1 -1e30
set valid_count 0
foreach inst [$block getInsts] {
    if {![string match {*u_l2_cache.u_cache.valid_ram*} [$inst getName]]} {continue}
    set box [$inst getBBox]
    set x0 [expr {min($x0, [$box xMin])}]
    set y0 [expr {min($y0, [$box yMin])}]
    set x1 [expr {max($x1, [$box xMax])}]
    set y1 [expr {max($y1, [$box yMax])}]
    incr valid_count
}
if {!$valid_count} {error "L2 padding: no valid_ram cells found"}
set margin [expr {30*$units}]
set names {}
foreach inst [$block getInsts] {
    if {[[$inst getMaster] isBlock] || [$inst isPhysicalOnly]} {continue}
    set box [$inst getBBox]
    set x [expr {([$box xMin]+[$box xMax])/2.0}]
    set y [expr {([$box yMin]+[$box yMax])/2.0}]
    if {$x >= $x0-$margin && $x <= $x1+$margin && $y >= $y0-$margin && $y <= $y1+$margin} {
        lappend names [$inst getName]
    }
}
# OpenDB escapes brackets in instance names; STA returns unescaped names.
# Match exact names instead of interpreting bus indices as glob patterns.
set selected [dict create]
foreach name $names {dict set selected [string map {\\ {}} $name] 1}
set cells {}
foreach cell [get_cells -quiet *] {
    if {[dict exists $selected [get_full_name $cell]]} {lappend cells $cell}
}
if {[llength $cells] != [llength $names]} {error "L2 padding: cell selection mismatch"}
set_placement_padding -instances $cells -left 3 -right 3
puts "L2_VALID_PADDING: $valid_count valid cells; [llength $cells] nearby cells padded 2 sites per side"
