# Get the current OpenDB block object and database units per micron
set block [ord::get_db_block]
set units [$block getDbUnitsPerMicron]

# Open report file to export macro floorplan information in TSV format
set file [open "$::env(REPORTS_DIR)/floorplan_macros.tsv" w]
puts $file "instance\tmaster\tx_um\ty_um\twidth_um\theight_um"

# Initialize counter for verified power/ground pins
set supply_terminals 0

# Iterate through all instances in the current design block
foreach inst [$block getInsts] {
    # Step 1: Verify Power and Ground connectivity for each instance
    foreach term [$inst getITerms] {
        # Check the signal type of the master cell terminal (MTerm)
        set type [[$term getMTerm] getSigType]
        if {$type ni {POWER GROUND}} {continue}
        
        incr supply_terminals
        set net [$term getNet]
        set pin "[$inst getName]/[[$term getMTerm] getName]"
        
        # Error handling: Ensure the PG pin is actually connected to a net
        if {$net == "NULL"} {
            error "Unbound supply terminal: $pin"
        }
        
        # Error handling: Ensure the connected net type matches the pin type (e.g., VDD to POWER)
        if {[$net getSigType] ne $type} {
            error "Supply type mismatch: $pin on [$net getName]"
        }
    }
    
    # Step 2: Filter for Macros and log their placement/geometry data
    set master [$inst getMaster]
    
    # Skip standard cells; only process macro blocks
    if {![$master isBlock]} {continue}
    
    # Error handling: Floorplan stage requires all macros to be placed
    if {![$inst isPlaced]} {
        error "Macro is not placed: [$inst getName]"
    }
    
    # Retrieve bounding box and convert DB units to microns
    set bbox [$inst getBBox]
    puts $file [join [list [$inst getName] [$master getName] \
        [expr {[$bbox xMin]/double($units)}] [expr {[$bbox yMin]/double($units)}] \
        [expr {[$bbox getDX]/double($units)}] [expr {[$bbox getDY]/double($units)}]] "\t"]
}

close $file
puts "Bound instance supply terminals: $supply_terminals"

# Step 3: Run OpenROAD power grid checks at floorplan level
# POST_PDN has unplaced standard cells; later stages use check_power.tcl.
foreach net [$block getNets] {
    # Only verify nets defined as POWER or GROUND
    if {[$net getSigType] ni {POWER GROUND}} {continue}
    
    # Perform connectivity and routing check on the PG grid using OpenROAD built-in tool
    check_power_grid -net [$net getName] -floorplanning \
        -error_file "$::env(REPORTS_DIR)/floorplan_supply_[$net getId].rpt"
}
