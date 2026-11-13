# Connect standard-cell and SRAM supply names to the same block-level domain.
add_global_connection -net VDD -inst_pattern {.*} -pin_pattern {^VDD$} -power
add_global_connection -net VSS -inst_pattern {.*} -pin_pattern {^VSS$} -ground
add_global_connection -net VDD -inst_pattern {.*} -pin_pattern {^vdd$} -power
add_global_connection -net VSS -inst_pattern {.*} -pin_pattern {^gnd$} -ground
global_connect

# Reject abstracts that name a supply but provide no physical access shapes.
foreach inst [[ord::get_db_block] getInsts] {
    set master [$inst getMaster]
    if {![$master isBlock]} {continue}
    foreach pin_name {vdd gnd} {
        set term [$master findMTerm $pin_name]
        set shapes 0
        if {$term != "NULL"} {
            foreach pin [$term getMPins] {incr shapes [llength [$pin getGeometry]]}
        }
        if {$shapes == 0} {error "No physical $pin_name access on [$master getName]; regenerate SRAM supplies."}
    }
}

set_voltage_domain -name CORE -power VDD -ground VSS
define_pdn_grid -name core -voltage_domains CORE -pins metal7
add_pdn_stripe -grid core -layer metal1 -width 0.17 -pitch 2.4 -offset 0 -followpins
# Fine enough for both rails to enter the channels between VRF banks.
add_pdn_stripe -grid core -layer metal4 -width 0.8 -pitch 20 -offset 2
add_pdn_stripe -grid core -layer metal7 -width 2.0 -pitch 40 -offset 2
add_pdn_connect -grid core -layers {metal1 metal4}
add_pdn_connect -grid core -layers {metal4 metal7}

# SRAM supply rings are M3/M4. Reach their M4 sides from M5, then the core M7.
define_pdn_grid -name sram -voltage_domains CORE -macro -default \
    -orient {R0 R180 MX MY} -halo {4 4 4 4}
add_pdn_stripe -grid sram -layer metal5 -width 1.0 -pitch 12 -offset 2
add_pdn_stripe -grid sram -layer metal6 -width 1.0 -pitch 12 -offset 2
# PDNG prunes contacts blocked by macro OBS. Keep all legal via-array cuts;
# the post-PDN hook requires the surviving ring contacts to be connected.
add_pdn_connect -grid sram -layers {metal4 metal5}
add_pdn_connect -grid sram -layers {metal5 metal6}
add_pdn_connect -grid sram -layers {metal6 metal7}
