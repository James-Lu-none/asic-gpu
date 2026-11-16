#!/usr/bin/env python3
"""Size a two-SM facing-IO GPC from physical LEFs."""
import argparse
import math
from stack_dimensions import size

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--sm-lef', required=True)
p.add_argument('--l2-lef', required=True)
p.add_argument('--channel', type=float, default=1000)
p.add_argument('--side', type=float, default=200)
p.add_argument('--edge', type=float, default=40)
p.add_argument('--l2-columns', type=int, choices=[2, 4], default=2)
a = p.parse_args()
w, h = size(a.sm_lef)
lw, lh = size(a.l2_lef)
if not all(math.isfinite(v) and v >= 0 for v in [a.channel, a.side, a.edge]):
    p.error('dimensions must be finite and nonnegative')
rows = 4 // a.l2_columns
cluster_w = a.l2_columns*lw + (a.l2_columns-1)*20
cluster_h = rows*lh + (rows-1)*20
if a.edge < 24 or a.side < 24 or a.channel < cluster_h+32 or w < cluster_w+32:
    p.error('SM/L2 cluster or core/halo margin does not fit')
dw = math.ceil(w+2*a.side)
dh = math.ceil(2*h+a.channel+2*a.edge)
print(dw, dh, dw-20, dh-20)
