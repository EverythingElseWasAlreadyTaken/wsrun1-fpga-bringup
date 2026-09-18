# gf180mcu FABulous FPGA

This folder contains resources and examples to bring up [gf180mcu FABulous FPGA](github.com/mole99/gf180mcu-fabulous-fpga).

The following board was used:

- https://github.com/mole99/waferspace-main-pcb

Important Pins:

| project_clk  | GPIO0  |                         |
|--------------|--------|-------------------------|
| project_rst  | GPIO1  | (active low)            |
| FPGA_MODE    | GPIO2  | (0=active SPI, 1=passive SPI) |
| FPGA_BUSY    | GPIO3  | Configuration module is busy |
| FPGA_MISO    | GPIO4  |                         |
| FPGA_CS_N    | GPIO5  |                         |
| FPGA_SCLK    | GPIO6  |                         |
| FPGA_MOSI    | GPIO7  |                         |
| fpga_pad_47  | GPIO8  |                         |
| fpga_pad_46  | GPIO9  |                         |
| fpga_pad_45  | GPIO10 |                         |
| fpga_pad_44  | GPIO11 |                         |
| fpga_pad_43  | GPIO12 |                         |
| fpga_pad_42  | GPIO13 |                         |

## Compiling Bitstreams

First, install Nix as described by librelane: https://librelane.readthedocs.io/en/stable/installation/nix_installation/index.html

Then, under `user_designs/` run `nix-shell`. The first time, Nix will build Yosys and nextpnr.

Afterwards run `make all` to build all bitstreams, or `make rgb` to build individual ones.

You can copy the final bitstreams under `user_designs/designs/<example>/<example.bit>` to the `board/bitstreams/` directory.

To copy the directory structure under `board/bitstreams/` to the waferspace-main-pcb, run:

```
python3 -m there mkdir bitstreams
python3 -m there push board/bitstreams/* /bitstreams/
python3 -m there push board/* /
```

After restarting the board `main.py` will automatically upload the default bitstream. Adjust `main.py` to your needs or send commands via the REPL:

```
upload_bitstream("bitstreams/rgb.bit")
```

You can alternatively run `main.py` using the commandline:
```
python3 -m there run board/main.py
```

To change the FPGA clock while a bitstream is running (via `board/utils.py`):

```
./clk.py 5M                 # set 5 MHz
./clk.py 1M 10M 500k 2      # sweep 1 -> 10 MHz, 500 kHz steps, 2 s each
```

The same via `there` directly (push `board/utils.py` to the board first):

```
python3 -m there -c "from utils import set_clk; set_clk(5_000_000)"
python3 -m there -c "from utils import sweep_clk; sweep_clk(1e6, 10e6, 500e3, 2)" --command-timeout 60
python3 -m there -i                # REPL: from utils import set_clk; set_clk(3_000_000)
```

To pick the clock when uploading a bitstream, pass it to `upload_bitstream`:

```
python3 -m there -c "from utils import upload_bitstream; upload_bitstream('bitstreams/st7735_bounce.bit', 5_000_000)"
```

FPGA `gpio[47..42]` are wired directly to Pico GPIO8..13 (pcf names `pico0..pico5`).
`watch_pins()` prints every edge with a timestamp and the time since the last edge, so a
design can report its state / actual clock to the console (`rgb_blink` outputs its fast and
slow blink on `pico0`/`pico1`):

```
python3 -m there -c "from utils import watch_pins; watch_pins((8, 9))" --command-timeout 3600
```

### Automated timing sweep

`timing_sweep.py` builds `clk_timing` with randomly placed LUT4 chains (one per seed),
records nextpnr's post-route max frequency, uploads each bitstream and raises the clock
until the sticky error fires (`utils.find_fmax`, err on Pico GPIO9, cleared per step via
GPIO13 -> `pico5`). Results go to `results/timing_<timestamp>.csv`:

```
./timing_sweep.py --seeds 1-10 --stages 8,16,32 --start 200k --stop 20M --step 100k --dwell 1
make -C user_designs/designs/clk_timing SEED=3 STAGES=32   # rebuild one variant by hand
```

Columns: seed, stages, nextpnr_fmax_mhz, last_pass_hz, fail_hz, measured_fmax_mhz (= fail
frequency, or the last passing one if it never failed). Frequencies are the actual PWM values.

The clock is a PWM on the Pico, so only frequencies of 125 MHz / integer are possible
(e.g. 10 MHz becomes 10.4 or 9.6 MHz; above ~10 MHz the gaps are >1 MHz). `set_clk`
prints the actual frequency — trust that, not the requested value.

To view VGA output, plug a [Tiny VGA](https://github.com/mole99/tiny-vga) into one of the GPIO banks.
