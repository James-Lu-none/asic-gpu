# Architecture dimensions come only from the shared RTL header, never a copy.
GPU_DEFINES_FILE := $(HARDWARE_ROOT)/rtl/common/gpu_defines.vh
GPU_NUM_LANES := $(strip $(shell sed -nE 's/^[[:space:]]*.define[[:space:]]+NUM_LANES[[:space:]]+([0-9]+).*/\1/p' $(GPU_DEFINES_FILE)))
GPU_NUM_SPS := $(strip $(shell sed -nE 's/^[[:space:]]*.define[[:space:]]+NUM_SPS[[:space:]]+([0-9]+).*/\1/p' $(GPU_DEFINES_FILE)))
ifeq ($(GPU_NUM_LANES),)
$(error Cannot read numeric NUM_LANES from $(GPU_DEFINES_FILE))
endif
ifeq ($(GPU_NUM_SPS),)
$(error Cannot read numeric NUM_SPS from $(GPU_DEFINES_FILE))
endif
# Include headers as source prerequisites so define changes trigger synthesis.
GPU_HEADERS = /hardware/rtl/common/gpu_defines.vh /hardware/rtl/common/gpu_debug.vh
