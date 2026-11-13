# Shared L1 width slices form one central cluster, independent of SP indices.
set block [ord::get_db_block]
set dbu [$block getDbUnitsPerMicron]
set edge $::env(COMPACT_EDGE)
set channel $::env(COMPACT_CHANNEL)
set orient $::env(L1_CLUSTER_ORIENT)
set slice_gap $::env(L1_CLUSTER_GAP)
set expected $::env(L1_CLUSTER_COUNT)
if {$orient ni {R90 R270}} {error "Expected quarter-turn L1 orientation"}
set sps {}
set l1s {}
foreach inst [$block getInsts] {
    set master [$inst getMaster]
    if {![$master isBlock]} {continue}
    if {[$master getName] eq "sp_pd_top"} {
        lappend sps $inst
    } elseif {[$master getName] eq $::env(L1_CLUSTER_MASTER)} {
        lappend l1s $inst
    } else {error "Unexpected macro [$inst getName]: [$master getName]"}
}
if {[llength $sps] != 4 || [llength $l1s] != $expected} {error "Unexpected SP/L1 count"}
set sm [[lindex $sps 0] getMaster]
set sw [expr {[$sm getWidth]/double($dbu)}]
set sh [expr {[$sm getHeight]/double($dbu)}]
set lm [[lindex $l1s 0] getMaster]
# A quarter-turn swaps width and height.
set lw [expr {[$lm getHeight]/double($dbu)}]
set lh [expr {[$lm getWidth]/double($dbu)}]
set span [expr {$expected*$lh+($expected-1)*$slice_gap}]
set die [$block getDieArea]
set dw [expr {[$die dx]/double($dbu)}]
set dh [expr {[$die dy]/double($dbu)}]
set lx [expr {$edge+$sw+$channel}]
set ly [expr {($dh-$span)/2}]
if {$lx+$lw+$edge > $dw || $ly < $edge} {error "L1 cluster outside reserved floorplan"}
set seen {}
foreach inst $sps {
    set path [string map {\\ {}} [$inst getName]]
    if {![regexp {gen_sub_partitions\[([0-3])\]} $path -> index]} {error "Unexpected SP $path"}
    if {$index in $seen} {error "Duplicate SP index"}
    lappend seen $index
    place_macro -macro_name [$inst getName] \
        -location [list $edge [expr {$edge+$index*($sh+$channel)}]] -orientation R0
}
set seen {}
foreach inst $l1s {
    set path [string map {\\ {}} [$inst getName]]
    if {$expected == 1} {
        set index 0
    } elseif {![regexp {bank\[([0-3])\]} $path -> index]} {error "Unexpected L1 $path"}
    if {$index in $seen} {error "Duplicate L1 slice"}
    lappend seen $index
    place_macro -macro_name [$inst getName] \
        -location [list $lx [expr {$ly+$index*($lh+$slice_gap)}]] -orientation $orient
}
