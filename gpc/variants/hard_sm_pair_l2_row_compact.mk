# First compression step: preserve width, single-row L2, padding and 100ps hold margin.
# Shrink only the inter-SM channel from 1000um to 800um; use separate results.
GPC_CHANNEL ?= 800
include $(dir $(lastword $(MAKEFILE_LIST)))hard_sm_pair_l2_row.mk
