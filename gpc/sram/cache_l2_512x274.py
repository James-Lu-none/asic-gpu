# Pack 256 data bits and 18 tag bits per L2 line. Valid bits remain FFs.
word_size = 274
num_words = 512
num_rw_ports = 1
num_r_ports = 0
num_w_ports = 0
tech_name = "freepdk45"
use_nix = False
process_corners = ["TT"]
supply_voltages = [1.1]
temperatures = [25]
nominal_corner_only = False
analytical_delay = True
check_lvsdrc = False
route_supplies = False
# Use native pin locations for this candidate; qualify pin access before P&R.
perimeter_pins = False
output_name = "gpc_sram_1rw_512x274"
output_path = "/out/cache_l2_512x274"
