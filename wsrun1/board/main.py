from utils import upload_bitstream

# Keep the FPGA under reset
reset_n = machine.Pin(1, machine.Pin.OUT)
reset_n(0)

upload_bitstream("bitstreams/rgb_pwm.bit", 100_000)
