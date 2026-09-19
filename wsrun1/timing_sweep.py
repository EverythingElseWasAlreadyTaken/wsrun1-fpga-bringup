#!/usr/bin/env python3
"""Build clk_timing with randomly placed LUT4 chains, run each on the board and
record nextpnr's predicted fmax next to the measured failure frequency.

  ./timing_sweep.py --seeds 1-10 --stages 8,16,32 --start 200k --stop 20M --step 100k --dwell 1

Ranges for --seeds/--stages: 1-10 or 4,8,16. One CSV row per (stages, seed) in
results/timing_<timestamp>.csv (also printed). --out FILE appends to an existing
CSV and skips pairs already in it. Build/board failures are recorded in the
'error' column and the sweep continues.
Needs board/utils.py on the Pico (pushed automatically). Extra `there` options via THERE_ARGS.
"""
import argparse
import csv
import datetime
import os
import pathlib
import re
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent
DESIGN = ROOT / "user_designs" / "designs" / "clk_timing"
THERE = ["there", *os.environ.get("THERE_ARGS", "").split()]
REMOTE_BIT = "/bitstreams/clk_timing_test.bit"  # one slot on the Pico; its flash is small
COLS = ["seed", "stages", "nextpnr_fmax_mhz", "last_pass_hz", "fail_hz", "measured_fmax_mhz", "error"]


class StepError(Exception):
    pass


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
    """Returns nextpnr's post-route max frequency in MHz. Unroutable placements
    get one retry with another nextpnr seed."""
    for pnr_seed in (43, 44):
        r = subprocess.run(["nix-shell", "--run",
                            f"cd designs/clk_timing && make clean && make SEED={seed} STAGES={stages} NEXTPNR_SEED={pnr_seed}"],
                           cwd=ROOT / "user_designs", capture_output=True, text=True)
        if r.returncode == 0:
            log = (DESIGN / "clk_timing_log.txt").read_text()
            return float(re.findall(r"Max frequency for clock 'clk': ([\d.]+) MHz", log)[-1])
        err = [l for l in (r.stdout + r.stderr).splitlines() if "ERROR" in l or "error" in l.lower()]
    raise StepError("build: " + (err[-1] if err else f"make exit {r.returncode}"))


def there(*args):
    r = subprocess.run([*THERE, *args], capture_output=True, text=True)
    if r.returncode:
        raise StepError(f"there {args[0]}: {(r.stderr or r.stdout).strip().splitlines()[-1:]}")
    return r.stdout


def measure(bit, a):
    slot = bit.with_name(pathlib.Path(REMOTE_BIT).name)
    shutil.copyfile(bit, slot)
    cmd = (f"from utils import find_fmax; find_fmax('{REMOTE_BIT}', "
           f"{hz(a.start)}, {hz(a.stop)}, {hz(a.step)}, {a.dwell})")
    timeout = (hz(a.stop) - hz(a.start)) // hz(a.step) * a.dwell + 60
    last = None
    for attempt in range(3):  # serial hiccups happen; the board state is rebuilt by upload anyway
        try:
            there("push", str(slot), str(pathlib.Path(REMOTE_BIT).parent))
            out = there("-c", cmd, "--command-timeout", str(timeout))
            m = re.search(r"RESULT last_pass=(\S+) fail=(\S+)", out)
            if not m:
                raise StepError("board: no RESULT line: " + out.strip().splitlines()[-1:].__str__())
            return [None if v == "None" else int(v) for v in m.groups()]
        except StepError as e:
            last = e
        finally:
            subprocess.run([*THERE, "rm", REMOTE_BIT], capture_output=True)
    raise last


def done_pairs(path):
    if not path.exists():
        return set()
    with open(path) as f:
        return {(int(r["stages"]), int(r["seed"])) for r in csv.DictReader(f) if not r.get("error")}


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--seeds", default="1-5", help="e.g. 1-10 or 3,7,9")
    p.add_argument("--stages", default="32", help="e.g. 8-32 or 4,8,16")
    p.add_argument("--start", default="200k")
    p.add_argument("--stop", default="20M")
    p.add_argument("--step", default="100k")
    p.add_argument("--dwell", type=float, default=1.0, help="seconds per frequency step")
    p.add_argument("--out", type=pathlib.Path, help="CSV to append to / resume (default: new file in results/)")
    a = p.parse_args()

    out = a.out or ROOT / "results" / f"timing_{datetime.datetime.now():%Y%m%d_%H%M%S}.csv"
    out.parent.mkdir(exist_ok=True)
    done = done_pairs(out)
    new = not out.exists()
    there("push", str(ROOT / "board" / "utils.py"), "/")  # keep the board's helpers current
    rows = []
    with open(out, "a", newline="") as f:
        w = csv.writer(f)
        if new:
            w.writerow(COLS)
        try:
            for stages in irange(a.stages):
                for seed in irange(a.seeds):
                    if (stages, seed) in done:
                        continue
                    print(f"stages {stages} seed {seed}: building...", end=" ", flush=True)
                    row = [seed, stages, None, None, None, None, ""]
                    try:
                        pred = build(seed, stages)
                        row[2] = pred
                        bit = (DESIGN / "clk_timing.bit").rename(DESIGN / f"clk_timing_n{stages}_s{seed}.bit")
                        print(f"nextpnr {pred:.2f} MHz, measuring...", end=" ", flush=True)
                        last_pass, fail = measure(bit, a)
                        row[3:6] = [last_pass, fail, round((fail or last_pass or 0) / 1e6, 3)]
                        print(f"pass {last_pass} Hz, fail {fail} Hz")
                    except StepError as e:
                        row[6] = str(e)
                        print(f"ERROR {e}")
                    rows.append(row); w.writerow(row); f.flush()
        except KeyboardInterrupt:
            print("\ninterrupted")

    print(f"\n{'seed':>4} {'stages':>6} {'nextpnr MHz':>11} {'last pass Hz':>12} {'fail Hz':>10} {'ratio':>6}  error")
    for seed, st, pred, lp, fl, meas, err in rows:
        ratio = f"{meas / pred:6.2f}" if pred and meas else "     -"
        print(f"{seed:>4} {st:>6} {pred if pred is None else f'{pred:.2f}':>11} {lp or '-':>12} {fl or '-':>10} {ratio}  {err}")
    print(f"\nwritten to {out.relative_to(ROOT) if out.is_relative_to(ROOT) else out}")


if __name__ == "__main__":
    main()
