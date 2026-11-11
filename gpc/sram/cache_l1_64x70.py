# One of four cache-line width slices; valid bits remain FFs.
word_size = 70
# Four parallel width slices; keep the array as wide as the input-FF row.
words_per_row = 4
num_words = 64
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
route_supplies = True
supply_pin_type = "ring"
# Use native pin locations for this candidate; qualify pin access before P&R.
perimeter_pins = False
detailed_lef = True
output_name = "gpc_sram_1rw_64x70"
output_path = "/out/cache_l1_64x70"
