#!/usr/bin/env python3
"""Build clk_timing with randomly placed LUT4 chains, run each on the board and
record nextpnr's predicted fmax next to the measured failure frequency.

  ./timing_sweep.py --seeds 1-10 --stages 8,16,32 --start 200k --stop 20M --step 100k --dwell 1

Ranges for --seeds/--stages: 1-10 or 4,8,16. One CSV row per (stages, seed) in results/timing_<timestamp>.csv (also printed).
Needs board/utils.py on the Pico. Extra `there` options via THERE_ARGS.
"""
import argparse
import csv
import datetime
import os
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent
DESIGN = ROOT / "user_designs" / "designs" / "clk_timing"
THERE = ["there", *os.environ.get("THERE_ARGS", "").split()]


def hz(s):
    s = s.strip().lower().replace("hz", "")
    return int(float(s.rstrip("km")) * {"k": 1e3, "m": 1e6}.get(s[-1], 1))


def irange(spec):
    out = []
    for part in spec.split(","):
        a, _, b = part.partition("-")
        out += range(int(a), int(b or a) + 1)
    return out


def build(seed, stages):
    """Returns nextpnr's post-route max frequency in MHz."""
    subprocess.run(["nix-shell", "--run", f"cd designs/clk_timing && make clean && make SEED={seed} STAGES={stages}"],
                   cwd=ROOT / "user_designs", check=True, capture_output=True)
    log = (DESIGN / "clk_timing_log.txt").read_text()
    return float(re.findall(r"Max frequency for clock 'clk': ([\d.]+) MHz", log)[-1])


def there(*args):
    r = subprocess.run([*THERE, *args], capture_output=True, text=True)
    if r.returncode:
        sys.exit(f"there {' '.join(args)} failed:\n{r.stdout}{r.stderr}")
    return r.stdout


def measure(bit, a):
    there("push", str(bit), "/bitstreams/")
    cmd = (f"from utils import find_fmax; find_fmax('bitstreams/{bit.name}', "
           f"{hz(a.start)}, {hz(a.stop)}, {hz(a.step)}, {a.dwell})")
    timeout = (hz(a.stop) - hz(a.start)) // hz(a.step) * a.dwell + 60
    out = there("-c", cmd, "--command-timeout", str(timeout))
    m = re.search(r"RESULT last_pass=(\S+) fail=(\S+)", out)
    if not m:
        sys.exit(f"no RESULT line from the board:\n{out}")
    return [None if v == "None" else int(v) for v in m.groups()]


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--seeds", default="1-5", help="e.g. 1-10 or 3,7,9")
    p.add_argument("--stages", default="32", help="e.g. 8-32 or 4,8,16")
    p.add_argument("--start", default="200k")
    p.add_argument("--stop", default="20M")
    p.add_argument("--step", default="100k")
    p.add_argument("--dwell", type=float, default=1.0, help="seconds per frequency step")
    a = p.parse_args()

    there("push", str(ROOT / "board" / "utils.py"), "/")  # keep the board's helpers current
    out = ROOT / "results" / f"timing_{datetime.datetime.now():%Y%m%d_%H%M%S}.csv"
    out.parent.mkdir(exist_ok=True)
    rows = []
    with open(out, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["seed", "stages", "nextpnr_fmax_mhz", "last_pass_hz", "fail_hz", "measured_fmax_mhz"])
        for stages in irange(a.stages):
            for seed in irange(a.seeds):
                print(f"stages {stages} seed {seed}: building...", end=" ", flush=True)
                pred = build(seed, stages)
                bit = DESIGN / "clk_timing.bit"
                bit = bit.rename(bit.with_name(f"clk_timing_n{stages}_s{seed}.bit"))
                print(f"nextpnr {pred:.2f} MHz, measuring...", end=" ", flush=True)
                last_pass, fail = measure(bit, a)
                meas = (fail or last_pass or 0) / 1e6
                print(f"pass {last_pass} Hz, fail {fail} Hz")
                row = [seed, stages, pred, last_pass, fail, round(meas, 3)]
                rows.append(row); w.writerow(row); f.flush()

    print(f"\n{'seed':>4} {'stages':>6} {'nextpnr MHz':>11} {'last pass Hz':>12} {'fail Hz':>10} {'ratio':>6}")
    for seed, st, pred, lp, fl, meas in rows:
        print(f"{seed:>4} {st:>6} {pred:>11.2f} {lp or '-':>12} {fl or '-':>10} {meas / pred if pred else 0:>6.2f}")
    print(f"\nwritten to {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
