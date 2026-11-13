# Automatic placement may flip or quarter-turn any SRAM. Native orientations
# use the shared M5/M6 grid; quarter-turns need vertical M6 crossings of the
# rotated M4 supply rings. The shared grid handles both orientations; this
# entry adds SM upper-layer straps without changing macro placement.
source /work/scripts/common/pdn_sram.tcl
add_pdn_stripe -grid core -layer metal8 -width 2 -pitch 40 -offset 2
add_pdn_stripe -grid core -layer metal9 -width 2 -pitch 40 -offset 2
add_pdn_connect -grid core -layers {metal7 metal8}
add_pdn_connect -grid core -layers {metal8 metal9}
