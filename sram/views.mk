# Shared generated views. Keep existing cell names/artifacts compatible.
SRAM_ROOT ?= /work/artifacts/asic-gpc-audit/openram
VRF_MACRO = $(SRAM_ROOT)/vrf_128x32/gpc_sram_1rw1r_128x32
IRAM_MACRO = $(SRAM_ROOT)/iram_1024x32/gpc_sram_1rw1r_1024x32
L1_MACRO = $(SRAM_ROOT)/cache_l1_64x70/gpc_sram_1rw_64x70
L2_MACRO = $(SRAM_ROOT)/cache_l2_512x69/gpc_sram_1rw_512x69
