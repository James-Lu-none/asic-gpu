# External ports enter the central channel through side corridors, not across SMs.
set block [ord::get_db_block]
set units [$block getDbUnitsPerMicron]
set sm_height 0
foreach inst [$block getInsts] {
    if {[[$inst getMaster] getName] eq "streaming_multiprocessor"} {
        set sm_height [expr {[[$inst getMaster] getHeight]/double($units)}]
        break
    }
}
if {$sm_height <= 0} {error "GPC IO needs the SM master"}
set lo [expr {$::env(GPC_EDGE)+$sm_height+16}]
set hi [expr {$::env(GPC_EDGE)+$sm_height+$::env(GPC_CHANNEL)-16}]
set_io_pin_constraint -region [format "left:%.4f-%.4f" $lo $hi] -pin_names {s_axi_lite.* clk rst_n gpc_busy l2_act gpu_completion_irq}
set_io_pin_constraint -region [format "right:%.4f-%.4f" $lo $hi] -pin_names {m_axi_gmem.*}
puts "GPC_CHANNEL_IO: side regions $lo .. $hi um"
