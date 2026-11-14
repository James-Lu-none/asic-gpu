# SP0/SP2 left, SP1/SP3 mirrored right. All SP signal pins face the center.
set block [ord::get_db_block]
set dbu [$block getDbUnitsPerMicron]
set edge $::env(COMPACT_EDGE)
set center $::env(SP_CENTER_SPACE)
set row_gap $::env(SP_ROW_GAP)
set sps {}
set l1s {}
foreach inst [$block getInsts] {
    if {![[$inst getMaster] isBlock]} {continue}
    switch -- [[$inst getMaster] getName] {
        sp_pd_top {lappend sps $inst}
        gpc_sram_1rw_64x70 {lappend l1s $inst}
        default {error "Unexpected macro: [$inst getName]"}
    }
}
if {[llength $sps] != 4 || [llength $l1s] != 4} {error "Expected four SPs and four L1 slices"}
set sm [[lindex $sps 0] getMaster]
set sw [expr {[$sm getWidth]/double($dbu)}]
set sh [expr {[$sm getHeight]/double($dbu)}]
set seen {}
foreach inst $sps {
    set path [string map {\\ {}} [$inst getName]]
    if {![regexp {gen_sub_partitions\[([0-3])\]} $path -> index] || $index in $seen} {error "Unexpected SP index: $path"}
    lappend seen $index
    set col [expr {$index%2}]
    set row [expr {$index/2}]
    set orientation [expr {$col ? "MY" : "R0"}]
    place_macro -macro_name [$inst getName] -orientation $orientation \
        -location [list [expr {$edge+$col*($sw+$center)}] [expr {$edge+$row*($sh+$row_gap)}]]
}
set lm [[lindex $l1s 0] getMaster]
set lw [expr {[$lm getHeight]/double($dbu)}]
set lh [expr {[$lm getWidth]/double($dbu)}]
set span [expr {4*$lh+3*$::env(L1_CLUSTER_GAP)}]
set die [$block getDieArea]
set height [expr {[$die dy]/double($dbu)}]
if {$center < $lw+16 || $span > $height-2*$edge} {error "L1 cluster does not fit center channel"}
set lx [expr {$edge+$sw+($center-$lw)/2}]
set ly [expr {($height-$span)/2}]
set seen {}
foreach inst $l1s {
    set path [string map {\\ {}} [$inst getName]]
    if {![regexp {bank\[([0-3])\]} $path -> index] || $index in $seen} {error "Unexpected L1 index: $path"}
    lappend seen $index
    place_macro -macro_name [$inst getName] -orientation R270 \
        -location [list $lx [expr {$ly+$index*($lh+$::env(L1_CLUSTER_GAP))}]]
}
# Validate actual snapped macro boxes, including mirrored origins.
set placed {}
set core [$block getCoreArea]
foreach inst [concat $sps $l1s] {
    set a [$inst getBBox]
    if {[$a xMin] < [$core xMin] || [$a yMin] < [$core yMin] || [$a xMax] > [$core xMax] || [$a yMax] > [$core yMax]} {error "Macro outside core: [$inst getName]"}
    foreach other $placed {
        set b [$other getBBox]
        if {[$a xMin] < [$b xMax] && [$b xMin] < [$a xMax] && [$a yMin] < [$b yMax] && [$b yMin] < [$a yMax]} {error "Macro overlap: [$inst getName] / [$other getName]"}
    }
    lappend placed $inst
}
puts "MIRRORED_SP_PLACEMENT_PASS: left R0, right MY, central L1"
