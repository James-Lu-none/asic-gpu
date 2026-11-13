# Shared SRAM IP

OpenRAM configs (`*.py`), ASIC storage adapters (`*.sv`), standalone VRF/IRAM
configs, and pin-access checks shared by SP, SM and GPC.

```sh
make -C sram MACRO=vrf_128x32
make -C sram MACRO=iram_1024x32
make -C sram MACRO=cache_l1_64x70
make -C sram MACRO=cache_l2_512x69
make -C sram pin-access MACRO=vrf_128x32
```

`views.mk` selects generated views through `SRAM_ROOT`. Existing artifacts remain
under `artifacts/asic-gpc-audit/openram/`; `gpc_sram_*` cell names are preserved
for compatibility with the existing Liberty/LEF/GDS and completed blocks.
Generation can use another output directory with `BUILD=...`.
Timing models remain analytical; generation is not SRAM qualification.

All executable Tcl is centralized in `../scripts/sram/`; common PDN and power
checks live in `../scripts/common/`

Current variants compile only `cache_line_ram.sv` (four L1 width slices),
`instruction_ram.sv` and `vector_regfile_ram.sv`. Optional monolithic L1 wrappers
and older shape configs live in `alternatives/`. The wrappers define the same
module name and must never be added alongside the active adapter.
The generator also resolves optional configs there, for example:

```sh
make -C sram MACRO=cache_l1_64x277_wpr4
```
