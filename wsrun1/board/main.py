import time
from utils import set_clk, sweep_clk, upload_bitstream

# Keep the FPGA under reset
reset_n = machine.Pin(1, machine.Pin.OUT)
reset_n(0)

upload_bitstream("bitstreams/rgb_blink.bit", 100_000)
time.sleep(2)

#upload_bitstream("bitstreams/seven_seg.bit", 2**16)
#time.sleep(2)

#machine.freq(100_000_000)
#upload_bitstream("bitstreams/vga_test.bit", 10_000)

# LCD display example
#upload_bitstream(bitstreams/st7735_bounce.bit, 5_000_000)
