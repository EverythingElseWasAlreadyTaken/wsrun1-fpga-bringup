## User Designs
| Name      | Description |
|-----------|-------------|
| `rgb` | Control rgb with buttons |
| `rgb_off`  | Turn off rgb |
| `rgb_on`   | Turn on rgb |
| `rgb_pwm`   | Display a rgb light pattern using pwm |
| `seven_seg`   | Display text on a seven segment display |

To build user designs follow the instructions in wsrun1/user_designs/README.md.

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

To build a test design, copy its folder into the designs directory.
