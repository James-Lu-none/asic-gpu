# Place the complete external contract on the right, using disjoint bus bands.
set block [ord::get_db_block]
set units [$block getDbUnitsPerMicron]
set die [$block getDieArea]
set y0 [expr {[$die yMin]/double($units)}]
set height [expr {[$die dy]/double($units)}]
set midpoint [expr {$y0+$height/2}]
set margin 20.0
set guard 8.0
set role_patterns [dict create iram {iram_*} alloc {alloc_*} request {l1_req_*} clock {clk rst_n} response {l1_rsp_*} perf {perf_*}]
set counts {}
set assigned {}
foreach role [dict keys $role_patterns] {
    set pins [get_ports -quiet [dict get $role_patterns $role]]
    dict set counts $role [llength $pins]
    foreach pin $pins {
        set name [get_full_name $pin]
        if {$name in $assigned} {error "Duplicate IO role for $name"}
        lappend assigned $name
    }
}
foreach pin [get_ports *] {
    if {[get_full_name $pin] ni $assigned} {error "No right-side IO group: [get_full_name $pin]"}
}
set report [open "$::env(REPORTS_DIR)/right_io_groups.tsv" w]
puts $report "group\tcount\ty0_um\ty1_um"
foreach {roles lo hi} [list {iram alloc request} [expr {$y0+$margin}] [expr {$midpoint-8-$guard}] \
                           {clock} [expr {$midpoint-8}] [expr {$midpoint+8}] \
                           {response perf} [expr {$midpoint+8+$guard}] [expr {$y0+$height-$margin}]] {
    set active {}
    set total 0
    foreach role $roles {
        if {[dict get $counts $role] > 0} {
            lappend active $role
            incr total [dict get $counts $role]
        }
    }
    if {$total == 0} {continue}
    set budget [expr {$hi-$lo-([llength $active]-1)*$guard}]
    set cursor $lo
    foreach role $active {
        set n [dict get $counts $role]
        set span [expr {$budget*$n/double($total)}]
        if {$span < 0.56*$n} {error "Right IO band $role too small for $n pins"}
        set end [expr {$cursor+$span}]
        set_io_pin_constraint -group -region [format "right:%.4f-%.4f" $cursor $end] -pin_names [dict get $role_patterns $role]
        puts $report [join [list $role $n $cursor $end] "\t"]
        set cursor [expr {$end+$guard}]
    }
}
close $report
puts "Right-side IO contract: [llength $assigned] pins"
