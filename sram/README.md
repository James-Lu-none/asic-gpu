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
