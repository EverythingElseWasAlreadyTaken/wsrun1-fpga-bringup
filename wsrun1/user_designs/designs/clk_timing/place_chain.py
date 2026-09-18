#!/usr/bin/env python3
"""Emit set_cell lines placing chain[i].lut at alternating fabric corners.
LUT columns on this fabric: X1 X2 X3 X5 X7, rows Y1..Y12, BELs A..H per tile."""
import sys
stages = int(sys.argv[1])
corners = ["X1Y1", "X7Y12", "X7Y1", "X1Y12"]
for i in range(stages):
    tile = corners[i % len(corners)]
    bel = "ABCDEFGH"[(i // len(corners)) % 8]
    print(f"set_cell chain[{i}].lut {tile}/{bel}")
