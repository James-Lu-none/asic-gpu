# SM PG pins are M9; native L2 rings are M3/M4. Parent access uses M10.
foreach {pin net kind} {VDD VDD power VSS VSS ground vdd VDD power gnd VSS ground} {
    add_global_connection -net $net -inst_pattern {.*} -pin_pattern ^${pin}$ -$kind
}
global_connect
set_voltage_domain -name CORE -power VDD -ground VSS
define_pdn_grid -name core -voltage_domains CORE -pins metal10
add_pdn_stripe -grid core -layer metal1 -width 0.17 -pitch 2.4 -offset 0 -followpins
add_pdn_stripe -grid core -layer metal4 -width 0.8 -pitch 20 -offset 2
foreach layer {metal7 metal8 metal9 metal10} {
    add_pdn_stripe -grid core -layer $layer -width 2 -pitch 40 -offset 2
}
foreach pair {{metal1 metal4} {metal4 metal7} {metal7 metal8} {metal8 metal9} {metal9 metal10}} {
    add_pdn_connect -grid core -layers $pair
}
define_pdn_grid -name sm -voltage_domains CORE -macro -cells {streaming_multiprocessor} \
    -grid_over_pg_pins -orient {R0 MX} -halo {4 4 4 4}
add_pdn_connect -grid sm -layers {metal9 metal10}
define_pdn_grid -name l2 -voltage_domains CORE -macro -cells {gpc_sram_1rw_512x69} \
    -orient {R0} -halo {4 4 4 4}
add_pdn_stripe -grid l2 -layer metal5 -width 1 -pitch 12 -offset 2
add_pdn_stripe -grid l2 -layer metal6 -width 1 -pitch 12 -offset 2
foreach pair {{metal4 metal5} {metal5 metal6} {metal6 metal7}} {add_pdn_connect -grid l2 -layers $pair}
