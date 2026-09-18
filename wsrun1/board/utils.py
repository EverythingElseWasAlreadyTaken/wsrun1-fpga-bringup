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

# FPGA gpio[47..42] are wired to Pico GPIO8..13 (pcf names pico0..pico5)
PICO_PINS = (8, 9, 10, 11, 12, 13)

def watch_pins(pins=PICO_PINS):
    """Print every edge on the FPGA->Pico lines with a timestamp and the delta
    since the previous edge on that pin (us). Ctrl-C to stop.
    ponytail: print() in the IRQ; fine up to a few hundred Hz per pin."""
    last = {}
    def edge(n, pin):
        now = time.ticks_us()
        dt = time.ticks_diff(now, last.get(n, now))
        last[n] = now
        print(f"{now:12d} us  GPIO{n} = {pin.value()}  (+{dt} us)")
    for n in pins:
        machine.Pin(n, machine.Pin.IN).irq(lambda pin, n=n: edge(n, pin),
                                           machine.Pin.IRQ_RISING | machine.Pin.IRQ_FALLING)
    print(f"watching GPIO {pins} (Ctrl-C to stop)")
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        for n in pins:
            machine.Pin(n).irq(None)

def find_fmax(bitstream, start, stop, step, dwell=1.0, err_pin=9, clr_pin=13):
    """Upload a clk_timing bitstream, then raise the clock from start to stop Hz.
    Per step: pulse the clear line (clr_pin -> FPGA pico5), wait dwell seconds,
    check the sticky error (err_pin <- FPGA pico1, rising-edge IRQ).
    Returns (last_pass_hz, fail_hz) as actual PWM frequencies; fail_hz is None
    if the design never failed."""
    upload_bitstream(bitstream, start)
    err = machine.Pin(err_pin, machine.Pin.IN)
    clr = machine.Pin(clr_pin, machine.Pin.OUT, value=0)
    hit = [False]
    err.irq(lambda p: hit.__setitem__(0, True), machine.Pin.IRQ_RISING)
    last_pass, fail, prev = None, None, None
    f = int(start)
    try:
        while f <= int(stop):
            actual = set_clk(f)
            if actual != prev:  # PWM is quantized: skip repeats
                prev = actual
                clr(1); time.sleep_ms(1); clr(0)
                hit[0] = False
                time.sleep(dwell)
                if hit[0] or err.value():
                    fail = actual
                    break
                last_pass = actual
            f += int(step)
    finally:
        err.irq(None)
        clr.init(machine.Pin.IN)
    print(f"RESULT last_pass={last_pass} fail={fail}")
    return last_pass, fail

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
