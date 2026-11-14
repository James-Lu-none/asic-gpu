set block [ord::get_db_block]
set edge right
if {[info exists ::env(SM_IO_EDGE)]} {set edge $::env(SM_IO_EDGE)}
if {$edge ni {right bottom}} {error "Unsupported SM IO edge: $edge"}
set die [$block getDieArea]
set boundary [expr {$edge eq "right" ? [$die xMax] : [$die yMin]}]
set tolerance [expr {[$block getDbUnitsPerMicron] * 1.0}]
set count 0
foreach term [$block getBTerms] {
    if {[$term getSigType] in {POWER GROUND}} {continue}
    set shapes 0
    foreach pin [$term getBPins] {
        foreach box [$pin getBoxes] {
            incr shapes
            set coordinate [expr {$edge eq "right" ? [$box xMax] : [$box yMin]}]
            if {abs($coordinate-$boundary) > $tolerance} {
                error "SM signal pin is not on $edge edge: [$term getName]"
            }
        }
    }
    if {$shapes == 0} {error "SM signal pin has no placement: [$term getName]"}
    incr count
}
if {$count == 0} {error "SM has no signal pins"}
puts "SM_IO_EDGE_PASS: $count signal pins on $edge edge"
