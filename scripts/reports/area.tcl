set block [ord::get_db_block]
set dbu [$block getDbUnitsPerMicron]
set standard 0.0
set macro 0.0
set buffers 0.0
foreach inst [$block getInsts] {
    set m [$inst getMaster]
    set area [expr {[$m getWidth]*double([$m getHeight])/($dbu*$dbu)}]
    if {[$m isBlock]} {set macro [expr {$macro+$area}]; continue}
    if {[$m isFiller]} {continue}
    set standard [expr {$standard+$area}]
    if {[regexp {^(BUF|CLKBUF)} [$m getName]]} {set buffers [expr {$buffers+$area}]}
}
# Actual rows already exclude macro/halo; subtract soft band blockages by interval union.
set available 0.0
foreach row [$block getRows] {
    set box [$row getBBox]
    set intervals [list [list [$box xMin] [$box xMax]]]
    foreach blockage [$block getBlockages] {
        set b [$blockage getBBox]
        if {[$b yMin] >= [$box yMax] || [$b yMax] <= [$box yMin]} {continue}
        set next {}
        foreach interval $intervals {
            lassign $interval lo hi
            if {[$b xMax] <= $lo || [$b xMin] >= $hi} {lappend next $interval; continue}
            if {$lo < [$b xMin]} {lappend next [list $lo [$b xMin]]}
            if {$hi > [$b xMax]} {lappend next [list [$b xMax] $hi]}
        }
        set intervals $next
    }
    foreach interval $intervals {
        lassign $interval lo hi
        set available [expr {$available+($hi-$lo)*double([$box dy])/($dbu*$dbu)}]
    }
}
set c [$block getCoreArea]
set area [expr {[$c dx]*double([$c dy])/($dbu*$dbu)}]
set f [open "$::env(REPORTS_DIR)/area.json" w]
puts $f [format {{"standard_um2": %.6f, "macro_um2": %.6f, "buffer_um2": %.6f, "core_um2": %.6f, "available_rows_um2": %.6f, "total_utilization": %.8f, "standard_density": %.8f}} $standard $macro $buffers $area $available [expr {($standard+$macro)/$area}] [expr {$standard/$available}]]
close $f
