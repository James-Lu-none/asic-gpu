set block [ord::get_db_block]
set right [[$block getDieArea] xMax]
set tolerance [expr {[$block getDbUnitsPerMicron] * 1.0}]
set count 0
foreach term [$block getBTerms] {
    if {[$term getSigType] in {POWER GROUND}} {continue}
    set shapes 0
    foreach pin [$term getBPins] {
        foreach box [$pin getBoxes] {
            incr shapes
            if {abs([$box xMax]-$right) > $tolerance} {
                error "SM signal pin is not on right edge: [$term getName]"
            }
        }
    }
    if {$shapes == 0} {error "SM signal pin has no placement: [$term getName]"}
    incr count
}
if {$count == 0} {error "Flat SM has no signal pins"}
puts "FLAT_SM_RIGHT_IO_PASS: $count signal pins on right edge"
