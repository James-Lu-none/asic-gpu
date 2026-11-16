# Lower SM0 uses MX, upper SM1 uses R0: both bottom-IO edges face the channel.
set block [ord::get_db_block]
set units [$block getDbUnitsPerMicron]
set sms {}
set l2s {}
foreach inst [$block getInsts] {
    if {![[$inst getMaster] isBlock]} {continue}
    switch -- [[$inst getMaster] getName] {
        streaming_multiprocessor {lappend sms $inst}
        gpc_sram_1rw_512x69 {lappend l2s $inst}
        default {error "Unexpected GPC macro: [$inst getName]"}
    }
}
if {[llength $sms] != 2 || [llength $l2s] != 4} {error "Expected two SMs and four L2 width slices"}
set sm [[lindex $sms 0] getMaster]
if {![$sm getSymmetryX]} {error "SM abstract lacks X symmetry; export with MACRO_SYMMETRY=\"X Y\" after verifying leaf masters"}
set sw [expr {[$sm getWidth]/double($units)}]
set sh [expr {[$sm getHeight]/double($units)}]
set x $::env(GPC_SIDE_MARGIN)
set y $::env(GPC_EDGE)
set channel $::env(GPC_CHANNEL)
set seen {}
foreach inst $sms {
    set path [string map {\\ {}} [$inst getName]]
    if {![regexp {gen_sm_array\[([01])\]} $path -> index] || $index in $seen} {error "Unexpected SM index: $path"}
    lappend seen $index
    place_macro -macro_name [$inst getName] -orientation [expr {$index ? "R0" : "MX"}] \
        -location [list $x [expr {$y+$index*($sh+$channel)}]]
}
set lm [[lindex $l2s 0] getMaster]
set lw [expr {[$lm getWidth]/double($units)}]
set lh [expr {[$lm getHeight]/double($units)}]
set gap $::env(GPC_L2_GAP)
set columns $::env(GPC_L2_COLUMNS)
if {$columns ni {2 4}} {error "GPC_L2_COLUMNS must be 2 or 4"}
set rows [expr {4/$columns}]
set cluster_w [expr {$columns*$lw+($columns-1)*$gap}]
set cluster_h [expr {$rows*$lh+($rows-1)*$gap}]
if {$cluster_w+32 > $sw || $cluster_h+32 > $channel} {error "L2 cluster does not fit the central channel"}
set lx [expr {$x+($sw-$cluster_w)/2}]
set ly [expr {$y+$sh+($channel-$cluster_h)/2}]
set seen {}
foreach inst $l2s {
    set path [string map {\\ {}} [$inst getName]]
    if {![regexp {bank\[([0-3])\]} $path -> index] || $index in $seen} {error "Unexpected L2 slice: $path"}
    lappend seen $index
    place_macro -macro_name [$inst getName] -orientation R0 \
        -location [list [expr {$lx+($index%$columns)*($lw+$gap)}] [expr {$ly+($index/$columns)*($lh+$gap)}]]
}
set placed {}
set core [$block getCoreArea]
foreach inst [concat $sms $l2s] {
    set a [$inst getBBox]
    if {[$a xMin] < [$core xMin] || [$a yMin] < [$core yMin] || [$a xMax] > [$core xMax] || [$a yMax] > [$core yMax]} {error "Macro outside GPC core: [$inst getName]"}
    foreach other $placed {
        set b [$other getBBox]
        if {[$a xMin] < [$b xMax] && [$b xMin] < [$a xMax] && [$a yMin] < [$b yMax] && [$b yMin] < [$a yMax]} {error "Overlapping GPC macros"}
    }
    lappend placed $inst
}
puts "GPC_PAIR_PLACEMENT_PASS: lower SM MX, upper SM R0, central L2 $columns columns x $rows rows"
