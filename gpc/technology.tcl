# OpenRAM FreePDK45 tech.py specifies a 0.0025 um manufacturing grid.
# Nangate's 0.005 um cell geometry is a subset of this shared integration grid.
# Keep all GDS/LEF shapes unchanged; do not round away real SRAM pin geometry.
set tech [[ord::get_db] getTech]
set grid [expr {int(round(0.0025 * [$tech getDbUnitsPerMicron]))}]
if {$grid < 1} {error "Database units cannot represent the FreePDK45 grid"}
$tech setManufacturingGrid $grid
puts "GPC integration manufacturing grid: 0.0025 um ($grid DBU)"
