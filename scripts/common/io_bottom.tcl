# All SM signal ports, including clock/reset and debug, along the bottom edge.
set signal_ports [get_ports -quiet *]
if {[llength $signal_ports] == 0} {error "Bottom IO: no signal ports"}
set group_args {-group}
if {[info exists ::env(SM_BOTTOM_GROUP)] && !$::env(SM_BOTTOM_GROUP)} {set group_args {}}
set_io_pin_constraint {*}$group_args -region bottom:* -pin_names {*}
puts "BOTTOM_IO: constrained [llength $signal_ports] signal ports to bottom"
