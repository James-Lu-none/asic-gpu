# Placement, CTS and routing repair add cells after PDN creation.
# Bind their physical supplies and verify the saved stage has connected power.
global_connect

# No hierarchy names, macro count or placement coordinates are assumed here.
set supply_terminals 0
foreach inst [[ord::get_db_block] getInsts] {
    foreach term [$inst getITerms] {
        if {[[$term getMTerm] getSigType] ni {POWER GROUND}} {continue}
        incr supply_terminals
        if {[$term getNet] == "NULL"} {
            error "Unbound supply terminal: [$inst getName]/[[$term getMTerm] getName]"
        }
    }
}
puts "Bound instance supply terminals: $supply_terminals"
check_power_grid -net VDD -error_file "$::env(REPORTS_DIR)/placed_vdd.rpt"
check_power_grid -net VSS -error_file "$::env(REPORTS_DIR)/placed_vss.rpt"
