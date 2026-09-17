# ST7735 Bounce

"FABulous" in yellow bouncing on a blue background, on a 160x128 ST7735 SPI
display. `st7735_bounce.v` wires `video_generator_bounce.v` to
`st7735_controller.v`, which runs the panel init sequence and bit-bangs SPI
mode 3.

`sw0` restarts the design.
RGB0 is steady blue and RGB1 blinks yellow every ~1.2 s (8 frames).

## Wiring

The display goes on the **bank 3** header (gpio[34:41]). VCC, GND and LED come
from the same header (tie LED to 3V3):

| Display | pin    | gpio |
|---------|--------|------|
| SCL     | X0Y2/D | 40   |
| SDA     | X0Y2/C | 41   |
| CS      | X0Y4/A | 35   |
| DC      | X0Y3/A | 39   |
| RES     | X0Y3/C | 37   |

This is the pin order of the Pmod built for this header. gpio[38], gpio[36]
and gpio[34] are unused. (`constraints.pcf` also still names the bank 1 pins
as `tft_*`; these were used for handwiring the display for testing.)

The using the PMOD on bank 3, the panel is mounted upside down, so the generator
renders rotated 180 degrees via its `FLIP` parameter, you can set it to 0 in
`st7735_bounce.v` if the panel is ever turned round.
The rotation is done in logic rather than with the panel's MADCTL register
because MADCTL `8'hA8`, which should rotate 180 degree, just blanks this panel, so
`st7735_controller.v` keeps it at `8'h68`.

## Clock

Built for a 5 MHz project clock and 2.5 MHz SPI (divider 1). A frame is
368640 SPI clocks, so each FSM step gets one SPI period (400 ns) to settle;
5 MHz is the fastest the design can run on this chip, everything faster broke.
Init delays scale with `FREQ_MAIN_HZ` / `FREQ_SPI_HZ` constants.


## Testbench

Only needs iverilog. The generator check verifies the font renders
rotated at the start position, that a long `pixel_request` advances the
position exactly one step, and that it clamps and turns around at the walls:

```
iverilog -g2005 -o tb tb_bounce.v video_generator_bounce.v
```

The controller check decodes the SPI stream and compares it against the
expected ST7735 init sequence and the first pixels:

```
iverilog -g2005 -o tb tb_st7735.v st7735_controller.v video_generator_bounce.v
```
