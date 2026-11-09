# Nangate45 default insertion, with an explicit keepout around SRAM boundaries.
tapcell -distance 120 -tapcell_master $::env(TAP_CELL_NAME) \
    -endcap_master $::env(TAP_CELL_NAME) \
    -halo_width_x $::env(MACRO_ROWS_HALO_X) \
    -halo_width_y $::env(MACRO_ROWS_HALO_Y)
