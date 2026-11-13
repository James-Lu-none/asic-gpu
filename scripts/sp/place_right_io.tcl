# Reuse qualified SRAM coordinates; replace guidance with hard, row-backed regions.
set initial_blockages {}
foreach b [[ord::get_db_block] getBlockages] {lappend initial_blockages [$b getId]}
source /work/scripts/sp/place_sram_bands.tcl
foreach b [$block getBlockages] {
    if {[$b getId] ni $initial_blockages && [$b isSoft]} {odb::dbBlockage_destroy $b}
}
source /work/scripts/sp/right_region.tcl
set geom [right_region_geometry]
lassign [dict get $geom main] main_left main_bottom core_right main_top
lassign [dict get $geom corridor] strip_left core_bottom unused core_top
set core_left [$core xMin]
set forbidden [list [list $core_left $core_bottom $strip_left $main_bottom] \
    [list $core_left $main_top $strip_left $core_top] \
    [list $core_left $main_bottom $main_left $main_top]]
# Avoid redundant blockage overlap with fixed macros/halos.
proc right_rect_subtract {rect cut} {
    lassign $rect x0 y0 x1 y1
    lassign $cut a b c d
    set a [expr {max($a,$x0)}]; set b [expr {max($b,$y0)}]
    set c [expr {min($c,$x1)}]; set d [expr {min($d,$y1)}]
    if {$a >= $c || $b >= $d} {return [list $rect]}
    set out {}
    foreach r [list [list $x0 $y0 $a $y1] [list $c $y0 $x1 $y1] \
                    [list $a $y0 $c $b] [list $a $d $c $y1]] {
        lassign $r p q s t
        if {$s > $p && $t > $q} {lappend out $r}
    }
    return $out
}
set halo [expr {round($::env(MACRO_ROWS_HALO_X)*$dbu)}]
foreach inst [concat $vrfs $irams] {
    set box [$inst getBBox]
    set cut [list [expr {[$box xMin]-$halo}] [expr {[$box yMin]-$halo}] \
                  [expr {[$box xMax]+$halo}] [expr {[$box yMax]+$halo}]]
    set next {}
    foreach rect $forbidden {lappend next {*}[right_rect_subtract $rect $cut]}
    set forbidden $next
}
foreach rect $forbidden {odb::dbBlockage_create $block {*}$rect}
# Clip actual rows too: taps, filler and late repair must obey the same region.
set sites_before 0
set sites_after 0
foreach row [$block getRows] {
    if {[$row getDirection] ne "HORIZONTAL"} {error "Unsupported vertical row"}
    set box [$row getBBox]
    lassign [$row getOrigin] rx ry
    set count [$row getSiteCount]
    set pitch [$row getSpacing]
    set site [$row getSite]
    set orient [$row getOrient]
    set name [$row getName]
    incr sites_before $count
    set limit $strip_left
    if {[$box yMin] >= $main_bottom && [$box yMax] <= $main_top} {set limit $main_left}
    set skip [expr {max(0,int(ceil(($limit-$rx)/double($pitch))))}]
    set kept [expr {max(0,$count-$skip)}]
    odb::dbRow_destroy $row
    if {$kept > 0} {
        odb::dbRow_create $block $name $site [expr {$rx+$skip*$pitch}] $ry $orient HORIZONTAL $kept $pitch
        incr sites_after $kept
    }
}
puts "Right-region rows: sites $sites_before -> $sites_after; hard blockages [llength $forbidden]"
right_region_check 0
