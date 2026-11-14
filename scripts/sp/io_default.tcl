set_io_pin_constraint -group -region left:* -pin_names {alloc_* block_dim_x*}
set_io_pin_constraint -group -region right:* -pin_names {mem_req_* mem_rsp_*}
set_io_pin_constraint -group -region top:* -pin_names {iram_*}
set_io_pin_constraint -group -region bottom:* -pin_names {clk rst_n}
if {[llength [get_ports -quiet {perf_*}]] > 0} {
    set_io_pin_constraint -group -region top:* -pin_names {perf_*}
}
