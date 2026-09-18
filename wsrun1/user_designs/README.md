## User Designs

| Name      | Description |
|-----------|-------------|
| `rgb` | Control rgb with buttons |
| `rgb_off`  | Turn off rgb |
| `rgb_on`   | Turn on rgb |
| `rgb_pwm`   | Display a rgb light pattern using pwm |
| `rgb_blink` | rgb0 blinks, rgb1 blinks 100x slower — for clock sweep tests (`./clk.py`) |
| `clk_timing` | Short vs. long (corner-placed LUT chain) path XOR — sweep the clock to find where timing fails (`STAGES=n`) |
| `seven_seg`   | Display text on a seven segment display |

To build individual user designs, go into one of the directories and run the commands:

```
Commands:
 synth           ... Synthesize the user design
 pnr             ... Run Place and Route
 bit             ... Generate the bitstream
 hex             ... Convert bitstream to hex
 copy            ... Copy bitstream to boards/ directory
 run             ... Push bitstream to the board via there and run it (FREQ=1_000_000)
 clean           ... Delete all generated files
 help            ... Show this help message
```

Or, inside this directory, prepend the design name:

```
Commands:
 <design>-synth           ... Synthesize the user design
 <design>-pnr             ... Run Place and Route
 <design>-bit             ... Generate the bitstream
 <design>-hex             ... Convert bitstream to hex
 <design>-copy            ... Copy bitstream to boards/ directory
 <design>-clean           ... Delete all generated files
 <design>-help            ... Show this help message
```

To build all of them, simply run:

```
make all
```

To copy all generated bitstreams to the `boards/` directory, run:

```
make copy
```

To delete all generated files, run:

```
make clean
```

To create a custom user design, simply copy an example. If you decide to rename a verilog file, remember to also rename it in the Makefile

## Test designs

| Name      | Description |
|-----------|-------------|
| `all_zeros` | all outputs set to zero |
| `all_ones`  | all outputs set to one |
| `counter`   | 32-bit counter |
| `counter_top`   | intended for top-level verification |
| `passthrough` | inputs connected to outputs |
| `sram` | all SRAMs muxed together for testing |
| `bram` | all BRAMs muxed together for testing |
| `peripheral` | simple peripheral (32x32 r/w registers) |
| `peripheral_sram` | all SRAMs/BRAMs available as peripheral |
| `custom_instruction` | custom instruction extension (32-bit addition) |
| `trigger_irq` | trigger an IRQ after a few cycles |
| `trigger_slot0` | trigger warmboot reconfiguration to slot 0 after a few cycles |
| `trigger_slot1` | trigger warmboot reconfiguration to slot 1 |
| `serv` | [SERV](https://github.com/olofk/serv) in 4-bit configuration with CSRs enabled on servant, 4 kByte memory |
| `fazyrv` | [FazyRV](https://github.com/meiniKi/FazyRV) in 1-bit configuration and default SoC, 4 kByte memory |

Test designs were used for simulations of the fabric, but can be a useful reference when making an actual user design to run on the FPGA board.

To build a test design, copy its folder into the `designs/` directory.
