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

To view VGA output, plug a [Tiny VGA](https://github.com/mole99/tiny-vga) into one of the GPIO banks.
