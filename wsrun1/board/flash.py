# Runs ON THE BOARD, sent there from the host:
#
#   python3 -m there run board/flash.py -t 60

from utils import upload_bitstream

BITSTREAM = "bitstreams/st7735_bounce.bit"
CLOCK_HZ = 5_000_000   # matches main.py and the RTL constants

upload_bitstream(BITSTREAM, CLOCK_HZ)
