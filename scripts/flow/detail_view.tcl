# GUI-only expansion of completed physical geometry. Implementation/STA ODBs are untouched.
source $::env(SCRIPTS_DIR)/load.tcl
load_design 6_final.odb 6_final.sdc
if {![info exists ::env(DETAIL_BLOCKS)] || $::env(DETAIL_BLOCKS) eq ""} {
    error "This design has no DETAIL_BLOCKS configured"
}
foreach lef $::env(DETAIL_LEFS) {read_lef $lef}

namespace eval detail_view {
    variable decoder [odb::dbWireDecoder]
    variable encoder [odb::dbWireEncoder]
    variable verifier [odb::dbWireDecoder]
}
proc detail_view::layer {tech original} {
    set result [$tech findLayer [$original getName]]
    if {$result eq "NULL"} {error "Missing layer: [$original getName]"}
    return $result
}
proc detail_view::tech_via {tech original} {
    set result [$tech findVia [$original getName]]
    if {$result eq "NULL"} {error "Missing tech via: [$original getName]"}
    return $result
}
# Decode physical paths independently of database object/junction IDs.
proc detail_view::wire_signature {wire {dx 0} {dy 0}} {
    variable verifier
    set decoder $verifier
    $decoder begin $wire
    set signature {}
    while {1} {
        set op [$decoder next]
        switch $op {
            0 {set value [list [[$decoder getLayer] getName] [$decoder getWireType]]}
            1 - 2 - 3 {
                lassign [$wire getCoord [$decoder getJunctionValue]] x y
                set value [list [expr {$x-$dx}] [expr {$y-$dy}] [[$decoder getLayer] getName] [$decoder getWireType]]
            }
            4 {
                lassign [$decoder getPoint] x y
                set value [list [expr {$x-$dx}] [expr {$y-$dy}]]
            }
            5 {
                lassign [$decoder getPoint_ext] x y ext
                set value [list [expr {$x-$dx}] [expr {$y-$dy}] $ext]
            }
            6 {
                set via [$decoder getVia]
                set box [$via getBBox]
                set value [list [$box xMin] [$box yMin] [$box xMax] [$box yMax] [[$via getBottomLayer] getName] [[$via getTopLayer] getName]]
            }
            7 {set value [[$decoder getTechVia] getName]}
            8 {set value [$decoder getRect]}
            9 - 10 {continue}
            11 {
                set rule [$decoder getRule]
                set value [list [[$rule getLayer] getName] [$rule getWidth]]
            }
            12 {break}
            default {error "Unsupported wire opcode $op"}
        }
        lappend signature $op $value
    }
    return $signature
}
proc detail_view::wire {source target child tech prefix dx dy vias} {
    variable decoder
    variable encoder
    $decoder begin $source
    $encoder begin $target
    set junctions [dict create]
    set pending {}
    set rule NULL
    while {1} {
        set op [$decoder next]
        if {$op == 12} {break}
        if {$op in {0 1 2 3}} {
            set pending [list $op [$decoder getLayer] [$decoder getWireType]]
            if {$op != 0} {lappend pending [$decoder getJunctionValue]}
            set rule NULL
            continue
        }
        if {$op == 11} {
            set old_rule [$decoder getRule]
            set ndr [$child findNonDefaultRule "${prefix}[[$old_rule getNonDefaultRule] getName]"]
            set rule [$ndr getLayerRule [layer $tech [$old_rule getLayer]]]
            continue
        }
        if {[llength $pending]} {
            lassign $pending path old_layer type old_junction
            set args {}
            if {$rule ne "NULL"} {lappend args $rule}
            switch $path {
                0 {$encoder newPath [layer $tech $old_layer] $type {*}$args}
                1 {$encoder newPath [dict get $junctions $old_junction] $type {*}$args}
                2 {$encoder newPathShort [dict get $junctions $old_junction] [layer $tech $old_layer] $type {*}$args}
                3 {$encoder newPathVirtualWire [dict get $junctions $old_junction] [layer $tech $old_layer] $type {*}$args}
            }
            set pending {}
        }
        switch $op {
            4 {
                lassign [$decoder getPoint] x y
                set junction [$encoder addPoint [expr {$x+$dx}] [expr {$y+$dy}]]
            }
            5 {
                lassign [$decoder getPoint_ext] x y ext
                set junction [$encoder addPoint [expr {$x+$dx}] [expr {$y+$dy}] $ext]
            }
            6 {set junction [$encoder addVia [dict get $vias [[$decoder getVia] getName]] ]}
            7 {set junction [$encoder addTechVia [tech_via $tech [$decoder getTechVia]]]}
            8 {$encoder addRect {*}[$decoder getRect]}
            9 {
                set term [$decoder getITerm]
                $encoder addITerm [[$child findInst "${prefix}[[$term getInst] getName]"] findITerm [[$term getMTerm] getName]]
            }
            10 {} ;# Child ports are stitched to parent nets, not new chip ports.
            default {error "Unsupported wire opcode $op"}
        }
        if {$op in {4 5 6 7}} {dict set junctions [$decoder getJunctionId] $junction}
    }
    $encoder end
    if {[$source count] != [$target count] || [wire_signature $source] ne [wire_signature $target $dx $dy]} {
        error "Wire geometry changed while copying [[$source getNet] getName]: counts [$source count]/[$target count]"
    }
}
# Join parent nets aliased by multiple ports of the physical block.
proc detail_view::merge_net {target other} {
    if {$target eq $other} {return}
    if {[llength [$other getSWires]]} {error "Unexpected aliased special net"}
    foreach term [$other getITerms] {$term connect $target}
    foreach term [$other getBTerms] {$term connect $target}
    if {[$other getWire] ne "NULL"} {
        set wire [$target getWire]
        if {$wire eq "NULL"} {set wire [odb::dbWire_create $target]}
        $wire append [$other getWire]
    }
    odb::dbNet_destroy $other
}
proc detail_view::expand {parent source macro} {
    set database [ord::get_db]
    set tech [$parent getTech]
    set prefix "[$macro getName]/"
    if {[$macro getOrient] ne "R0"} {error "Detail expansion currently requires R0: $prefix"}
    lassign [$macro getOrigin] dx dy
    # Resolve port aliases before retaining any parent-net handles.
    foreach old_net [$source getNets] {
        set target NULL
        foreach port [$old_net getBTerms] {
            set term [$macro findITerm [$port getName]]
            if {$term eq "NULL"} {error "Missing macro port: [$port getName]"}
            set net [$term getNet]
            if {$net eq "NULL"} {continue}
            if {$target eq "NULL"} {set target $net} else {merge_net $target $net}
        }
    }
    set nets [dict create]
    foreach old_net [$source getNets] {
        set net NULL
        foreach port [$old_net getBTerms] {
            set candidate [[$macro findITerm [$port getName]] getNet]
            if {$candidate ne "NULL"} {set net $candidate; break}
        }
        if {$net eq "NULL"} {set net [odb::dbNet_create $parent "${prefix}[$old_net getName]"]}
        $net setSigType [$old_net getSigType]
        if {[$old_net isSpecial]} {$net setSpecial}
        dict set nets [$old_net getName] $net
    }
    foreach original [$source getNonDefaultRules] {
        set ndr [odb::dbTechNonDefaultRule_create $parent "${prefix}[$original getName]"]
        $ndr setHardSpacing [$original getHardSpacing]
        foreach old_layer [[$source getTech] getLayers] {
            set old_rule [$original getLayerRule $old_layer]
            if {$old_rule eq "NULL"} {continue}
            set rule [odb::dbTechLayerRule_create $ndr [layer $tech $old_layer]]
            foreach property {Width Spacing WireExtension Resistance Capacitance EdgeCapacitance} {
                $rule set$property [$old_rule get$property]
            }
        }
    }
    set vias [dict create]
    foreach original [$source getVias] {
        if {[$original isViaRotated]} {error "Rotated block via requires explicit support"}
        set name "detail/[$source getName]/[$original getName]"
        set via [$parent findVia $name]
        if {$via eq "NULL"} {
            set via [odb::dbVia_create $parent $name]
            foreach box [$original getBoxes] {
                odb::dbBox_create $via [layer $tech [$box getTechLayer]] \
                    [$box xMin] [$box yMin] [$box xMax] [$box yMax]
            }
        }
        dict set vias [$original getName] $via
    }
    set count 0
    foreach original [$source getInsts] {
        set master [$database findMaster [[$original getMaster] getName]]
        if {$master eq "NULL"} {error "Missing master: [[$original getMaster] getName]"}
        set inst [odb::dbInst_create $parent $master "${prefix}[$original getName]" [$original isPhysicalOnly]]
        $inst setOrient [$original getOrient]
        lassign [$original getOrigin] x y
        $inst setOrigin [expr {$x+$dx}] [expr {$y+$dy}]
        $inst setPlacementStatus [$original getPlacementStatus]
        foreach old_term [$original getITerms] {
            set old_net [$old_term getNet]
            if {$old_net ne "NULL"} {
                [$inst findITerm [[$old_term getMTerm] getName]] connect [dict get $nets [$old_net getName]]
            }
        }
        incr count
    }
    puts "Detail $prefix: copied $count instances at offset $dx $dy"
    set scratch [odb::dbNet_create $parent "${prefix}__detail_wire_tmp__"]
    if {$scratch eq "NULL"} {error "Temporary detail net name is occupied"}
    set wires 0
    set specials 0
    foreach original [$source getNets] {
        set net [dict get $nets [$original getName]]
        if {[$original getWire] ne "NULL"} {
            set temporary [odb::dbWire_create $scratch]
            wire [$original getWire] $temporary $parent $tech $prefix $dx $dy $vias
            if {[$net getWire] eq "NULL"} {
                $temporary attach $net
            } else {
                [$net getWire] append $temporary
                odb::dbWire_destroy $temporary
            }
            incr wires
        }
        foreach old_wire [$original getSWires] {
            set shield NULL
            if {[$old_wire getShield] ne "NULL"} {set shield [dict get $nets [[$old_wire getShield] getName]]}
            set special [odb::dbSWire_create $net [$old_wire getWireType] $shield]
            foreach box [$old_wire getWires] {
                if {[$box isVia]} {
                    set via [$box getTechVia]
                    if {$via ne "NULL"} {set via [tech_via $tech $via]} else {
                        set via [dict get $vias [[$box getBlockVia] getName]]
                    }
                    lassign [$box getViaXY] x y
                    set added [odb::dbSBox_create $special $via [expr {$x+$dx}] [expr {$y+$dy}] [$box getWireShapeType]]
                } else {
                    set added [odb::dbSBox_create $special [layer $tech [$box getTechLayer]] \
                        [expr {[$box xMin]+$dx}] [expr {[$box yMin]+$dy}] \
                        [expr {[$box xMax]+$dx}] [expr {[$box yMax]+$dy}] \
                        [$box getWireShapeType] [$box getDirection]]
                }
                if {$added eq "NULL"} {error "Failed to copy PG geometry"}
                incr specials
            }
        }
    }
    odb::dbNet_destroy $scratch
    puts "Detail $prefix: verified $wires signal wires; copied $specials PG shapes/vias"
    odb::dbInst_destroy $macro
}
set parent [ord::get_db_block]
foreach {name path} $::env(DETAIL_BLOCKS) {
    set input [odb::dbDatabase_create]
    if {![file isfile $path]} {error "Missing detailed macro ODB: $path"}
    odb::read_db $input $path
    set source [[$input getChip] getBlock]
    if {[$source getDbUnitsPerMicron] != [$parent getDbUnitsPerMicron]} {error "Database units differ"}
    set macros {}
    foreach inst [$parent getInsts] {
        if {[[$inst getMaster] getName] eq $name} {lappend macros $inst}
    }
    if {![llength $macros]} {error "No $name macros to expand"}
    foreach macro $macros {detail_view::expand $parent $source $macro}
    odb::dbDatabase_destroy $input
}
set output $::env(RESULTS_DIR)/6_final_detailed.odb
write_db ${output}.tmp
file rename -force ${output}.tmp $output
puts "GUI detail database: $output (expanded fixed geometry; not an implementation/STA checkpoint)"
