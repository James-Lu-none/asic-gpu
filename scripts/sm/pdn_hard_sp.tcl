# SP exports VDD/VSS on M7; L1 exports vdd/gnd on M3/M4.
foreach {pin net kind} {VDD VDD power VSS VSS ground vdd VDD power gnd VSS ground} {
    add_global_connection -net $net -inst_pattern {.*} -pin_pattern ^${pin}$ -$kind
}
global_connect
set_voltage_domain -name CORE -power VDD -ground VSS
define_pdn_grid -name core -voltage_domains CORE -pins metal9
add_pdn_stripe -grid core -layer metal1 -width 0.17 -pitch 2.4 -offset 0 -followpins
add_pdn_stripe -grid core -layer metal4 -width 0.8 -pitch 20 -offset 2
add_pdn_stripe -grid core -layer metal7 -width 2 -pitch 40 -offset 2
add_pdn_stripe -grid core -layer metal8 -width 2 -pitch 40 -offset 2
add_pdn_stripe -grid core -layer metal9 -width 2 -pitch 40 -offset 2
add_pdn_connect -grid core -layers {metal1 metal4}
add_pdn_connect -grid core -layers {metal4 metal7}
add_pdn_connect -grid core -layers {metal7 metal8}
add_pdn_connect -grid core -layers {metal8 metal9}

define_pdn_grid -name sp -voltage_domains CORE -macro -cells {sp_pd_top} \
    -grid_over_pg_pins -orient {R0} -halo {4 4 4 4}
# Parent M8 straps avoid SP obstructions; this grid only connects SP PG pins.
add_pdn_connect -grid sp -layers {metal7 metal8}
add_pdn_connect -grid sp -layers {metal8 metal9}

# Rotated M4 PG ring segments are horizontal. Cross them using M6 vertical
# straps and stacked M4/M5/M6 vias, then reach the horizontal core M7 grid.
define_pdn_grid -name l1 -voltage_domains CORE -macro \
    -cells [list $::env(L1_CLUSTER_MASTER)] \
    -orient [list $::env(L1_CLUSTER_ORIENT)] -halo {4 4 4 4}
add_pdn_stripe -grid l1 -layer metal6 -width 1 -pitch 12 -offset 2
add_pdn_connect -grid l1 -layers {metal4 metal6}
add_pdn_connect -grid l1 -layers {metal6 metal7}
