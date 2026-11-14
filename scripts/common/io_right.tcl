# All top-level signal bits, including clock/reset and optional performance IO.
# A single full-height group lets PPL order connected pins by wirelength.
set signal_ports [get_ports -quiet *]
if {[llength $signal_ports] == 0} {error "Right IO: no signal ports"}
set_io_pin_constraint -group -region right:* -pin_names {*}
puts "RIGHT_IO: constrained [llength $signal_ports] signal ports to right"
