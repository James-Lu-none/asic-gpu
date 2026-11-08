export DESIGN_NAME = alu_int32_mul
export DESIGN_NICKNAME = mul32
export PLATFORM = nangate45
export VERILOG_FILES = /work/rtl/sm/sp/unit/alu_int32_mul.sv
export SDC_FILE = /work/asic/mul32/constraints/mul32.sdc
export CORE_UTILIZATION = 35
export PLACE_DENSITY = 0.55
export TNS_END_PERCENT = 100

# disable dedicated FA/HA mapping to test whether WNS and TNS improves
# export ADDER_MAP_FILE =

# Local LVS deck for this Nangate45 exercise.
ORFS_ARGS = KLAYOUT_LVS_FILE=/work/asic/lvs/lvs_freepdk45.lylvs

# Optional gate simulation
TB_TOP = tb_mul32
TB_FILES = ../sim/unit/mul32/mul32_pattern.sv ../sim/unit/mul32/tb_mul32.sv
GATE_LIBERTY = /OpenROAD-flow-scripts/flow/platforms/nangate45/lib/NangateOpenCellLibrary_typical.lib
