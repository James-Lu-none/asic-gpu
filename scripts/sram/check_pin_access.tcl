# Physical qualification of one generated macro, using the integration tracks.
# This checks access points, not completed routes or transistor-level DRC/LVS.
set platform /OpenROAD-flow-scripts/flow/platforms/nangate45
read_lef $platform/lef/NangateOpenCellLibrary.tech.lef
read_lef $::env(MACRO_LEF)
source /work/scripts/sram/technology.tcl

set db [ord::get_db]
set tech [$db getTech]
set masters {}
foreach lib [$db getLibs] {
    foreach master [$lib getMasters] {
        if {[$master isBlock]} {lappend masters $master}
    }
}
if {[llength $masters] != 1} {error "Expected one SRAM master in MACRO_LEF"}
set master [lindex $masters 0]
set units [$tech getDbUnitsPerMicron]
set margin [expr {50 * $units}]
set chip [odb::dbChip_create $db $tech]
set block [odb::dbBlock_create $chip macro_access]
$block setDefUnits $units
$block setDieArea [odb::Rect -args 0 0 \
    [expr {[$master getWidth] + 2 * $margin}] \
    [expr {[$master getHeight] + 2 * $margin}]]
set inst [odb::dbInst_create $block $master sram]
$inst setLocation $margin $margin
$inst setPlacementStatus FIRM
set count 0
foreach iterm [$inst getITerms] {
    set mterm [$iterm getMTerm]
    if {[$mterm getSigType] in {POWER GROUND}} {continue}
    $iterm connect [odb::dbNet_create $block [$mterm getName]]
    incr count
}
source $platform/make_tracks.tcl
set_thread_count 4
set_routing_layers -signal metal2-metal10 -clock metal4-metal10
puts "Checking $count signal pins on [$master getName]"
pin_access -min_access_points 1
puts "MACRO_PIN_ACCESS_PASS"
exit
