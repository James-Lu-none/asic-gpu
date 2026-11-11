# Four completed SP blocks in a 2 x 2 arrangement; shared L1 in the centre.
set block [ord::get_db_block]
set sp_count 0
set l1_count 0
foreach inst [$block getInsts] {
    set master [[$inst getMaster] getName]
    set name [$inst getName]
    set path [string map {\\ {}} $name]
    if {$master eq "sp_pd_top"} {
        if {![regexp {gen_sub_partitions\[([0-3])\]} $path -> index]} {
            error "Unexpected SP instance: $name"
        }
        set x [expr {60 + ($index % 2) * 1840}]
        set y [expr {60 + ($index / 2) * 1840}]
        place_macro -macro_name $name -location [list $x $y] -orientation R0
        incr sp_count
    } elseif {$master eq "gpc_sram_1rw_64x70"} {
        if {![regexp {bank\[([0-3])\]} $path -> index]} {
            error "Unexpected L1 instance: $name"
        }
        place_macro -macro_name $name -location [list 1590 [expr {1550 + $index * 75}]] -orientation R0
        incr l1_count
    } elseif {[[$inst getMaster] isBlock]} {
        error "Unexpected macro in hardened SM: $name ($master)"
    }
}
if {$sp_count != 4 || $l1_count != 4} {
    error "Expected four SP macros and four L1 slices, got $sp_count / $l1_count"
}
