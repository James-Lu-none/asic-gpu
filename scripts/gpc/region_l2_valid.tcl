# Physical experiment only: four groups of 128 valid bits, not SRAM width banks.
# Trace each group's D-input cone through Nangate45 combinational cells. Cells
# shared by multiple groups, and upstream sequential/macro cells, stay unfenced.
set block [ord::get_db_block]
if {[$block findRegion l2_valid_0] ne "NULL"} {
    puts "L2_VALID_REGIONS: reusing existing region assignments"
    if {[info exists env_var] && $env_var in {PRE_GLOBAL_PLACE_TCL PRE_DETAIL_PLACE_TCL}} {
        # Once separated, one enclosing box would cover unrelated shared logic.
        # Keep the 3-site padding on the grouped cells instead of that large box.
        set selected [dict create]
        for {set bank 0} {$bank<4} {incr bank} {
            foreach inst [[$block findGroup l2_valid_$bank] getInsts] {
                dict set selected [string map {\\ {}} [$inst getName]] 1
            }
        }
        set cells {}
        foreach cell [get_cells -quiet *] {
            if {[dict exists $selected [get_full_name $cell]]} {lappend cells $cell}
        }
        if {[llength $cells] != [dict size $selected]} {error "Region padding selection mismatch"}
        set_placement_padding -instances $cells -left 3 -right 3
        puts "L2_VALID_REGION_PADDING: [llength $cells] grouped cells, 3 sites per side"
    }
    return
}
set seeds [dict create]
set ownership [dict create]
foreach inst [$block getInsts] {
    set name [string map {\\ {}} [$inst getName]]
    if {![regexp {u_l2_cache\.u_cache\.valid_ram\[([0-9]+)\]} $name -> bit]} {continue}
    if {$bit >= 512} {error "L2 valid regions require 512 bits"}
    set bank [expr {$bit/128}]
    dict lappend seeds $bank $inst
    dict set ownership $inst [expr {1<<$bank}]
}
for {set bank 0} {$bank<4} {incr bank} {
    if {![dict exists $seeds $bank] || [llength [dict get $seeds $bank]] != 128} {
        error "Expected 128 valid FFs in group $bank"
    }
    set pending {}
    foreach inst [dict get $seeds $bank] {
        set pin [$inst findITerm D]
        if {$pin eq "NULL"} {error "Valid cell has no D pin: [$inst getName]"}
        lappend pending [$pin getNet]
    }
    set seen [dict create]
    while {[llength $pending]} {
        set net [lindex $pending end]
        set pending [lreplace $pending end end]
        if {$net eq "NULL"} {continue}
        foreach term [$net getITerms] {
            if {[$term getIoType] ne "OUTPUT"} {continue}
            set inst [$term getInst]
            set master [$inst getMaster]
            if {[$master isBlock] || [regexp {^(S?DFF|DL[HL])} [$master getName]]} {continue}
            if {[dict exists $seen $inst]} {continue}
            dict set seen $inst 1
            set mask 0
            if {[dict exists $ownership $inst]} {set mask [dict get $ownership $inst]}
            dict set ownership $inst [expr {$mask | (1<<$bank)}]
            foreach pin [$inst getITerms] {
                if {[$pin getIoType] eq "INPUT" && [$pin getSigType] ni {POWER GROUND}} {
                    lappend pending [$pin getNet]
                }
            }
        }
    }
}
set units [$block getDbUnitsPerMicron]
set core [$block getCoreArea]
set sm_h 0
foreach inst [$block getInsts] {
    if {[[$inst getMaster] getName] eq "streaming_multiprocessor"} {
        set sm_h [expr {[[$inst getMaster] getHeight]/double($units)}]
        set sm_w [expr {[[$inst getMaster] getWidth]/double($units)}]
        break
    }
}
set l2_h 0
foreach inst [$block getInsts] {
    if {[[$inst getMaster] getName] eq "gpc_sram_1rw_512x69"} {
        set l2_h [expr {[[$inst getMaster] getHeight]/double($units)}]
        break
    }
}
# Keep 60um at each SM edge, 220um regions, and >=40um to the centered SRAM.
set min_channel [expr {2*(60+220+40)+$l2_h}]
if {!$sm_h || !$l2_h || $::env(GPC_CHANNEL)<$min_channel || $::env(GPC_L2_COLUMNS)!=4} {
    error "Valid regions require single-row L2 and channel >=${min_channel}um"
}
set center [expr {$::env(GPC_SIDE_MARGIN)+$sm_w/2}]
set channel_y [expr {$::env(GPC_EDGE)+$sm_h}]
# Two regions below and two above the SRAM row; a shared-control corridor remains.
for {set bank 0} {$bank<4} {incr bank} {
    set cx [expr {$center+($bank%2 ? 420 : -420)}]
    set y [expr {$channel_y+($bank<2 ? 60 : $::env(GPC_CHANNEL)-280)}]
    set rect [list [expr {round(($cx-350)*$units)}] [expr {round($y*$units)}] \
        [expr {round(($cx+350)*$units)}] [expr {round(($y+220)*$units)}]]
    lassign $rect x0 y0 x1 y1
    if {$x0<[$core xMin] || $x1>[$core xMax] || $y0<[$core yMin] || $y1>[$core yMax]} {
        error "Valid region outside core"
    }
    foreach inst [$block getInsts] {
        if {![[$inst getMaster] isBlock]} {continue}
        set box [$inst getBBox]
        if {$x0<[$box xMax] && [$box xMin]<$x1 && $y0<[$box yMax] && [$box yMin]<$y1} {
            error "Valid region intersects macro [$inst getName]"
        }
    }
    set region [odb::dbRegion_create $block l2_valid_$bank]
    $region setRegionType EXCLUSIVE
    odb::dbBox_create $region {*}$rect
    set group [odb::dbGroup_create $region l2_valid_$bank]
    $group setType PHYSICAL_CLUSTER
    set count 0
    set area 0
    dict for {inst mask} $ownership {
        if {$mask != (1<<$bank)} {continue}
        if {[$inst getGroup] ne "NULL"} {error "Cell already grouped: [$inst getName]"}
        $group addInst $inst
        $region addInst $inst
        incr count
        set m [$inst getMaster]
        set area [expr {$area+[$m getWidth]*double([$m getHeight])/$units/$units}]
    }
    puts "L2_VALID_REGION: group=$bank bits=[expr {$bank*128}]:[expr {$bank*128+127}] cells=$count cell_area_um2=$area box_dbu=$rect"
}
puts "L2_VALID_REGIONS_PASS: exclusive cones fenced; shared logic remains free"
