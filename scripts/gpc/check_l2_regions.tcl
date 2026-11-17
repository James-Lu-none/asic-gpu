# Verify actual post-legalization positions, not just the existence of groups.
set block [ord::get_db_block]
set total 0
for {set bank 0} {$bank<4} {incr bank} {
    set group [$block findGroup l2_valid_$bank]
    if {$group eq "NULL"} {error "Missing L2 valid group $bank"}
    set box [lindex [[$group getRegion] getBoundaries] 0]
    set count 0
    set bits 0
    foreach inst [$group getInsts] {
        set b [$inst getBBox]
        if {[$b xMin]<[$box xMin] || [$b yMin]<[$box yMin] || [$b xMax]>[$box xMax] || [$b yMax]>[$box yMax]} {
            error "Cell escaped valid region $bank: [$inst getName]"
        }
        if {[string match *valid_ram* [$inst getName]]} {incr bits}
        incr count
    }
    if {$bits!=128} {error "Group $bank has $bits valid FFs instead of 128"}
    incr total $count
    puts "L2_VALID_REGION_PLACED: group=$bank cells=$count valid_bits=$bits"
}
puts "L2_VALID_REGION_PLACEMENT_PASS: $total grouped cells inside their regions"
