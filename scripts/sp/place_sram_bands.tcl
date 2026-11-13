# Parameterized deterministic bands: guidance alone cannot enforce lane pairing.
set block [ord::get_db_block]
set dbu [$block getDbUnitsPerMicron]
set core [$block getCoreArea]
set x0 [expr {[$core xMin]/double($dbu)}]
set y0 [expr {[$core yMin]/double($dbu)}]
set w [expr {[$core dx]/double($dbu)}]
set h [expr {[$core dy]/double($dbu)}]
set gap $::env(SP_BANK_GAP)
set edge $::env(SP_EDGE)
set vrfs {}
set irams {}
foreach inst [$block getInsts] {
    set master [$inst getMaster]
    if {![$master isBlock]} {continue}
    switch -- [$master getName] {
        gpc_sram_1rw1r_128x32 {lappend vrfs $inst}
        gpc_sram_1rw1r_1024x32 {lappend irams $inst}
        default {error "Unexpected SP macro: [$inst getName]"}
    }
}
if {[llength $vrfs] != 32 || [llength $irams] != 1} {error "Expected 32 VRF and one IRAM"}
set vm [[lindex $vrfs 0] getMaster]
set vw [expr {[$vm getWidth]/double($dbu)}]
set vh [expr {[$vm getHeight]/double($dbu)}]
set im [[lindex $irams 0] getMaster]
set iw [expr {[$im getWidth]/double($dbu)}]
set ih [expr {[$im getHeight]/double($dbu)}]
set band [expr {2*$vh+$gap}]
set bottom [expr {$y0+$edge+$band+$gap}]
set top [expr {$y0+$h-$edge-$band-$gap}]
if {$w < 8*$vw+7*$gap+2*$edge || $top-$bottom < $ih+8} {error "Infeasible SP bands"}
set seen {}
foreach inst $vrfs {
    set path [string map {\\ {}} [$inst getName]]
    if {![regexp {gen_lane_ram\[([0-9]+)\]\.u_(even|odd)\.memory$} $path -> lane bank]} {error "Unexpected VRF path: $path"}
    set index [expr {2*$lane+($bank eq "odd")}]
    if {$index in $seen} {error "Duplicate VRF index"}
    lappend seen $index
    set row [expr {$index/8}]
    set col [expr {$index%8}]
    set x [expr {$x0+$edge+$col*($vw+$gap)}]
    if {$row < 2} {
        set y [expr {$y0+$edge+$row*($vh+$gap)}]
    } else {
        set y [expr {$y0+$h-$edge-$band+($row-2)*($vh+$gap)}]
    }
    place_macro -macro_name [$inst getName] -location [list $x $y] -orientation R0
}
place_macro -macro_name [[lindex $irams 0] getName] \
    -location [list [expr {$x0+$edge}] [expr {($bottom+$top-$ih)/2}]] -orientation R0
# Soft blockages reserve the bank bands for macros, CTS and repair spillover.
foreach rect [list [list $x0 $y0 [expr {$x0+$w}] $bottom] \
                   [list $x0 $top [expr {$x0+$w}] [expr {$y0+$h}]]] {
    set coords {}
    foreach v $rect {lappend coords [expr {round($v*$dbu)}]}
    set b [odb::dbBlockage_create $block {*}$coords]
    $b setSoft
}
