#!/usr/bin/env python3
"""Compute an SM envelope from hard SP/L1 LEFs without changing macro placement."""
import argparse
import math
import re
from pathlib import Path


def size(path):
    match = re.search(r'\bSIZE\s+([\d.]+)\s+BY\s+([\d.]+)\s*;', Path(path).read_text())
    if not match:
        raise ValueError(f'No macro SIZE in {path}')
    return tuple(map(float, match.groups()))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sp-lef', required=True)
    parser.add_argument('--l1-lef', required=True)
    parser.add_argument('--right-space', type=float, default=80)
    parser.add_argument('--layout', choices=['stack', 'mirror'], default='stack')
    parser.add_argument('--center-space', type=float, default=1000)
    parser.add_argument('--row-gap', type=float, default=80)
    parser.add_argument('--edge', type=float, default=40)
    parser.add_argument('--channel', type=float, default=40)
    args = parser.parse_args()
    if not all(math.isfinite(v) and v >= 0 for v in (args.right_space, args.edge, args.channel, args.center_space, args.row_gap)):
        parser.error('spacing values must be finite and nonnegative')
    sw, sh = size(args.sp_lef)
    _, rotated_l1_width = size(args.l1_lef)
    # Four SPs at x=edge; L1 is to their right and rotated R270.
    width = math.ceil(args.edge + sw + args.channel + rotated_l1_width + args.right_space)
    height = math.ceil(2*args.edge + 4*sh + 3*args.channel)
    if args.layout == 'mirror':
        if args.center_space < rotated_l1_width + 16 or args.row_gap < 8:
            parser.error('mirror layout needs space for L1/halos and row-gap >=8um')
        width = math.ceil(args.edge + 2*sw + args.center_space + args.right_space)
        height = math.ceil(2*args.edge + 2*sh + args.row_gap)
    # Core inset is 20um. Keep macros/halos away from the core edge.
    if args.edge < 24 or args.right_space < 24 or args.channel < 8:
        parser.error('need edge/right-space >=24um and channel >=8um for core inset and halos')
    print(width, height, width-20, height-20)


if __name__ == '__main__':
    main()
