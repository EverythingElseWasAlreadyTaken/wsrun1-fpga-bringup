#!/usr/bin/env python3
"""Emit set_cell lines placing chain[i].lut.
Default: alternate fabric corners (longest route). With a seed: random unique LUT BELs.
LUT columns on this fabric: X1 X2 X3 X5 X7, rows Y1..Y12, BELs A..H per tile.
usage: place_chain.py STAGES [SEED]"""
import random
import sys

stages = int(sys.argv[1])
seed = sys.argv[2] if len(sys.argv) > 2 else ""
if seed:
    bels = [f"X{x}Y{y}/{b}" for x in (1, 2, 3, 5, 7) for y in range(1, 13) for b in "ABCDEFGH"]
    place = random.Random(int(seed)).sample(bels, stages)
else:
    corners = ["X1Y1", "X7Y12", "X7Y1", "X1Y12"]
    place = [f"{corners[i % 4]}/{'ABCDEFGH'[(i // 4) % 8]}" for i in range(stages)]
for i, bel in enumerate(place):
    print(f"set_cell chain[{i}].lut {bel}")
