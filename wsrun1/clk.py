#!/usr/bin/env python3
"""Change the FPGA clock of the running bitstream via the Pico (uses board/utils.py).

  ./clk.py 5M                 set clock to 5 MHz
  ./clk.py 1M 10M 500k 2      sweep 1 MHz -> 10 MHz in 500 kHz steps, 2 s per step

Frequencies accept k/M suffixes. Extra `there` options go in THERE_ARGS (e.g. "-p /dev/ttyACM0").
"""
import os
import subprocess
import sys


def hz(s):
    s = s.strip().lower().replace("hz", "")
    mult = {"k": 1e3, "m": 1e6}.get(s[-1], 1)
    return int(float(s.rstrip("km")) * mult)


def main(args):
    if len(args) == 1:
        cmd = f"from utils import set_clk; set_clk({hz(args[0])})"
        timeout = 5
    elif len(args) == 4:
        start, stop, step = map(hz, args[:3])
        dwell = float(args[3])
        cmd = f"from utils import sweep_clk; sweep_clk({start}, {stop}, {step}, {dwell})"
        timeout = (abs(stop - start) // max(abs(step), 1) + 1) * dwell + 5
    else:
        sys.exit(__doc__)
    return subprocess.call(
        [sys.executable, "-m", "there", *os.environ.get("THERE_ARGS", "").split(),
         "-c", cmd, "--command-timeout", str(timeout)])


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
