import time
from utils import upload_bitstream

# Keep the FPGA under reset
reset_n = machine.Pin(1, machine.Pin.OUT)
reset_n(0)

upload_bitstream("bitstreams/rgb_pwm.bit", 100_000)
time.sleep(2)

#upload_bitstream("bitstreams/seven_seg.bit", 2**16)
#time.sleep(2)

#machine.freq(100_000_000)
#upload_bitstream("bitstreams/vga_test.bit", 10_000)
