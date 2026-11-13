# Place 128 VRFs + 4 IRAMs + 4 shared L1 width slices directly in the SM.
# No SP abstracts, SP placement regions, or SP row exclusions are used.
set block [ord::get_db_block]
set dbu [$block getDbUnitsPerMicron]
set sw $::env(FLAT_SP_WIDTH)
set sh $::env(FLAT_SP_HEIGHT)
set edge $::env(FLAT_EDGE)
set channel $::env(FLAT_CHANNEL)
set seen [dict create]
set count 0
foreach inst [$block getInsts] {
    set master [$inst getMaster]
    if {![$master isBlock]} {continue}
    set path [string map {\\ {}} [$inst getName]]
    set mw [expr {[$master getWidth]/double($dbu)}]
    set mh [expr {[$master getHeight]/double($dbu)}]
    set orient R0
    switch -- [$master getName] {
        gpc_sram_1rw1r_128x32 - gpc_sram_1rw1r_1024x32 {
            if {![regexp {gen_sub_partitions\[([0-3])\]\.u_sp\.} $path -> sp]} {
                error "Unexpected flat SP SRAM path: $path"
            }
            set ox $edge
            set oy [expr {$edge+$sp*($sh+$channel)}]
            # Native SP bands: 10um core inset plus 8um macro edge/gap.
            set x [expr {$ox+18}]
            if {[$master getName] eq "gpc_sram_1rw1r_1024x32"} {
                set key iram:$sp
                set y [expr {$oy+($sh-$mh)/2}]
            } else {
                if {![regexp {gen_lane_ram\[([0-9]+)\]\.u_(even|odd)\.memory$} $path -> lane bank] || $lane > 15} {
                    error "Unexpected flat VRF path: $path"
                }
                set index [expr {2*$lane+($bank eq "odd")}]
                set key vrf:$sp:$index
                set row [expr {$index/8}]
                set x [expr {$x+($index%8)*($mw+8)}]
                if {$row < 2} {
                    set y [expr {$oy+18+$row*($mh+8)}]
                } else {
                    set y [expr {$oy+$sh-18-(2*$mh+8)+($row-2)*($mh+8)}]
                }
            }
        }
        gpc_sram_1rw_64x70 {
            if {![regexp {bank\[([0-3])\]} $path -> index]} {error "Unexpected L1 path: $path"}
            set key l1:$index
            set orient R270
            set x [expr {$edge+$sw+$channel}]
            set die [$block getDieArea]
            set dh [expr {[$die dy]/double($dbu)}]
            set y [expr {($dh-(4*$mw+3*12))/2+$index*($mw+12)}]
        }
        default {error "Flat SM must contain SRAM macros only: $path ([$master getName])"}
    }
    if {[dict exists $seen $key]} {error "Duplicate SRAM placement key $key"}
    dict set seen $key 1
    place_macro -macro_name [$inst getName] -location [list $x $y] -orientation $orient
    incr count
}
if {$count != 136} {error "Expected 136 SRAMs in flat 4x16 SM, found $count"}
# Check snapped coordinates, not just the requested locations.
set macros {}
set core [$block getCoreArea]
foreach inst [$block getInsts] {
    if {![[$inst getMaster] isBlock]} {continue}
    set box [$inst getBBox]
    if {[$box xMin] < [$core xMin] || [$box yMin] < [$core yMin] ||
        [$box xMax] > [$core xMax] || [$box yMax] > [$core yMax]} {
        error "SRAM outside core: [$inst getName]"
    }
    foreach other $macros {
        set b [$other getBBox]
        if {[$box xMin] < [$b xMax] && [$b xMin] < [$box xMax] &&
            [$box yMin] < [$b yMax] && [$b yMin] < [$box yMax]} {
            error "Overlapping SRAMs: [$inst getName], [$other getName]"
        }
    }
    lappend macros $inst
}
puts "FLAT_SM_MACROS_PASS: 128 VRF + 4 IRAM + 4 R270 L1; no hard SPs"
