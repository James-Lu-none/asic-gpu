set_io_pin_constraint -group -region left:* -pin_names {s_axi_lite.*}
set_io_pin_constraint -group -region right:* -pin_names {m_axi_gmem.*}
set_io_pin_constraint -group -region bottom:* -pin_names {clk rst_n}
set_io_pin_constraint -group -region top:* -pin_names {gpc_busy l2_act gpu_completion_irq}
