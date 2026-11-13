# Automatic placement may flip or quarter-turn any SRAM. Native orientations
# use the shared M5/M6 grid; quarter-turns need vertical M6 crossings of the
# rotated M4 supply rings. No macro positions or orientations are changed here.
source /work/scripts/common/pdn_sram.tcl
add_pdn_stripe -grid core -layer metal8 -width 2 -pitch 40 -offset 2
add_pdn_stripe -grid core -layer metal9 -width 2 -pitch 40 -offset 2
add_pdn_connect -grid core -layers {metal7 metal8}
add_pdn_connect -grid core -layers {metal8 metal9}
define_pdn_grid -name rotated_sram -voltage_domains CORE -macro \
    -cells {gpc_sram_1rw1r_128x32 gpc_sram_1rw1r_1024x32 gpc_sram_1rw_64x70} \
    -orient {R90 R270 MXR90 MYR90} -halo {4 4 4 4}
add_pdn_stripe -grid rotated_sram -layer metal6 -width 1 -pitch 12 -offset 2
add_pdn_connect -grid rotated_sram -layers {metal4 metal6}
add_pdn_connect -grid rotated_sram -layers {metal6 metal7}
