import os
import time
import machine

def set_clk(freq):
    """Set FPGA clock (PWM on GPIO0) to freq Hz; bitstream keeps running."""
    pwm = machine.PWM(machine.Pin(0, machine.Pin.OUT), freq=int(freq), duty_u16=32768) # 50% duty
    print(f"fpga clock: {pwm.freq()}")
    return pwm.freq()

def sweep_clk(start, stop, step, dwell):
    """Step FPGA clock from start to stop Hz by step Hz, holding each for dwell seconds."""
    start, stop, step = int(start), int(stop), int(step)
    if step == 0 or (stop - start) * step < 0:
        raise ValueError("step must be non-zero and point from start to stop")
    f = start
    while (f <= stop) if step > 0 else (f >= stop):
        set_clk(f)
        time.sleep(dwell)
        f += step

def upload_bitstream(bitstream, freq=10_000_000):

    print(f"machine freq: {machine.freq()}")

    # Setup
    reset_n = machine.Pin(1, machine.Pin.OUT)

    # SPI
    fpga_miso = machine.Pin(4, machine.Pin.IN)
    fpga_cs_n = machine.Pin(5, machine.Pin.OUT)
    fpga_sclk = machine.Pin(6, machine.Pin.OUT)
    fpga_mosi = machine.Pin(7, machine.Pin.OUT)

    fpga_spi = machine.SPI(
        mosi=fpga_mosi,
        sck=fpga_sclk,
        miso=fpga_miso,
        polarity=0,
        phase=1,
        baudrate=1_000_000, # Let's try 1 MBaud/s
        bits=8,
        firstbit=machine.SPI.MSB,
    )


    fpga_mode = machine.Pin(2, machine.Pin.OUT)
    fpga_mode(1) # Passive SPI mode

    fpga_busy = machine.Pin(3, machine.Pin.IN)

    print(f"fpga_mode: {fpga_mode.value()}")
    print(f"fpga_busy: {fpga_busy.value()}")

    fpga_pad_47 = machine.Pin(8, machine.Pin.IN)
    fpga_pad_46 = machine.Pin(9, machine.Pin.IN)
    fpga_pad_45 = machine.Pin(10, machine.Pin.IN)
    fpga_pad_44 = machine.Pin(11, machine.Pin.IN)
    fpga_pad_43 = machine.Pin(12, machine.Pin.IN)
    fpga_pad_42 = machine.Pin(13, machine.Pin.IN)

    print(f"Starting the 10MHz clock for bitstream write!")

    set_clk(10_000_000)

    print(f"Reset!")

    reset_n(0)
    time.sleep_ms(10)
    reset_n(1)

    def write_bitstream_spi(filename, spi_master, cs, active_low=True):
        with open(filename, 'br') as f:
            data = f.read(4)
            while data:
                try:
                    cs(not active_low)
                    spi_master.write(data)
                finally:
                    cs(active_low)

                # Next word
                data = f.read(4)

    print(f"Writing the bitstream {bitstream} !")
    write_bitstream_spi(bitstream, fpga_spi, fpga_cs_n)

    print(f"Set desing clk to {freq} !")
    set_clk(freq)
