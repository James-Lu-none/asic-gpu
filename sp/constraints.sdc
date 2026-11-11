# Provisional block budget, ns / fF; replace with SM integration contracts.
create_clock -name core_clk -period 10.0 [get_ports clk]
set_clock_uncertainty 0.10 [get_clocks core_clk]
set_clock_transition 0.10 [get_clocks core_clk]
set data_inputs [lsearch -all -inline -not -exact [all_inputs] [lindex [get_ports clk] 0]]
set_input_delay -max 1.0 -clock core_clk $data_inputs
set_input_delay -min 0.2 -clock core_clk $data_inputs
set_output_delay -max 1.0 -clock core_clk [all_outputs]
set_output_delay -min 0.2 -clock core_clk [all_outputs]
set_driving_cell -lib_cell BUF_X1 $data_inputs
set_load 5.0 [all_outputs]
