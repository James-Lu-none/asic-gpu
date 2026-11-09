# Initial block-level feasibility budget, not a measured parent/board contract.
create_clock -name core_clk -period 10.0 [get_ports clk]
set_clock_uncertainty 0.10 [get_clocks core_clk]
set_clock_transition 0.10 [get_clocks core_clk]
set data_inputs [get_ports {
    rst_n s_axi_lite.awaddr s_axi_lite.awprot s_axi_lite.awvalid
    s_axi_lite.wdata s_axi_lite.wstrb s_axi_lite.wvalid s_axi_lite.bready
    s_axi_lite.araddr s_axi_lite.arprot s_axi_lite.arvalid s_axi_lite.rready
    m_axi_gmem.awready m_axi_gmem.wready m_axi_gmem.bid m_axi_gmem.bresp
    m_axi_gmem.bvalid m_axi_gmem.arready m_axi_gmem.rid m_axi_gmem.rdata
    m_axi_gmem.rresp m_axi_gmem.rlast m_axi_gmem.rvalid
}]
set_input_delay -max 1.0 -clock core_clk $data_inputs
set_input_delay -min 0.2 -clock core_clk $data_inputs
set_output_delay -max 1.0 -clock core_clk [all_outputs]
set_output_delay -min 0.2 -clock core_clk [all_outputs]
set_driving_cell -lib_cell BUF_X1 $data_inputs
set_load 5.0 [all_outputs]
# No false-path/multicycle exceptions: validate reset and all interface modes
# before claiming timing coverage or closure on a parent-level implementation.
