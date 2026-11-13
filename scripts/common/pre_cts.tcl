source /work/scripts/common/repair_budget.tcl
# Padding experiments can require moving repair cells beyond the default window.
set ::env(DETAIL_PLACEMENT_ARGS) {-use_diamond_legalizer -max_displacement {500 500}}
