# Same channel, IO, timing, padding and SRAM orientation; four L2 slices in one row.
GPC_L2_COLUMNS = 4
include $(dir $(lastword $(MAKEFILE_LIST)))hard_sm_pair_l2_padding.mk
# Reserve 100ps before detailed-route RC extraction; keep the SDC unchanged.
export HOLD_SLACK_MARGIN = 0.10
