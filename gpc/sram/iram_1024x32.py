# Native OpenRAM configuration for one instruction SRAM per SP.
word_size = 32
num_words = 1024
num_rw_ports = 1
num_r_ports = 1
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
output_name = "gpc_sram_1rw1r_1024x32"
output_path = "/out/iram_1024x32"
