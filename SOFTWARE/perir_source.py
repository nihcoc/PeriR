"""
PeriR GNU Radio OOT Source Block
Streams IQ samples from the AD9364 via FPGA PCIe/XDMA into GNU Radio.

Install GNU Radio OOT module:
  mkdir build && cd build
  cmake ..
  make
  sudo make install

Then in GNU Radio Companion, search for "PeriR Source".

IQ format from FPGA (matches axi_ad9361 output):
  16-bit signed I, 16-bit signed Q, interleaved, little-endian
  i.e. [I0_15:0][Q0_15:0][I1_15:0]... packed as int32 per sample pair
  Output to GRC: complex float (gr.sizeof_gr_complex)
"""

import numpy as np
import os
import struct
import threading
import queue
import gnuradio.gr as gr


class perir_source(gr.sync_block):
    """
    PeriR SDR Source Block

    Streams IQ samples from the AD9364 via XDMA PCIe DMA.
    Output: complex float (normalized to +/-1.0)
    """

    # XDMA card-to-host DMA node
    XDMA_C2H   = "/dev/xdma0_c2h_0"
    XDMA_USER  = "/dev/xdma0_user"

    # BAR0 register offsets (must match your FPGA register map)
    REG_SCRATCH     = 0x0000
    REG_VERSION     = 0x0004
    REG_DMA_CTRL    = 0x0010   # DMA start/stop control
    REG_SAMPLE_RATE = 0x0014   # sample rate divider
    REG_CENTER_FREQ = 0x0018   # tuning frequency (Hz, 64-bit: 0x18 low, 0x1C high)
    REG_RX_GAIN     = 0x0020   # RX gain index (0-73 dB)

    # DMA control bits
    DMA_START = 0x1
    DMA_STOP  = 0x0

    # AD9364 full-scale: 12-bit ADC, so max value is 2048
    ADC_FULLSCALE = 2048.0

    def __init__(self, sample_rate=2.4e6, center_freq=100e6, gain=40):
        gr.sync_block.__init__(
            self,
            name="PeriR Source",
            in_sig=None,                          # no input — this is a source
            out_sig=[np.complex64]                # output: complex IQ
        )

        self.sample_rate  = sample_rate
        self.center_freq  = center_freq
        self.gain         = gain
        self.running      = False
        self._buf_queue   = queue.Queue(maxsize=8)
        self._dma_thread  = None
        self._fd_c2h      = None
        self._fd_user     = None

        # DMA read chunk: 4096 samples * 4 bytes/sample (2x int16)
        self.chunk_samples = 4096
        self.chunk_bytes   = self.chunk_samples * 4

    # ------------------------------------------------------------------
    # GNU Radio lifecycle
    # ------------------------------------------------------------------

    def start(self):
        """Called by GRC when the flowgraph starts."""
        self._open_devices()
        self._configure_ad9364()
        self._start_dma()
        self.running = True
        self._dma_thread = threading.Thread(target=self._dma_reader, daemon=True)
        self._dma_thread.start()
        return True

    def stop(self):
        """Called by GRC when the flowgraph stops."""
        self.running = False
        self._stop_dma()
        if self._dma_thread:
            self._dma_thread.join(timeout=2.0)
        self._close_devices()
        return True

    # ------------------------------------------------------------------
    # Work function — called by GNU Radio scheduler
    # ------------------------------------------------------------------

    def work(self, input_items, output_items):
        out = output_items[0]
        noutput = len(out)

        samples_written = 0
        while samples_written < noutput:
            try:
                chunk = self._buf_queue.get(timeout=0.1)
            except queue.Empty:
                break

            n = min(len(chunk), noutput - samples_written)
            out[samples_written:samples_written + n] = chunk[:n]
            samples_written += n

            # If chunk had leftovers, put them back (simple approach)
            if n < len(chunk):
                self._buf_queue.put(chunk[n:])
                break

        return samples_written if samples_written > 0 else -1  # -1 = WORK_DONE

    # ------------------------------------------------------------------
    # DMA reader thread — fills buffer queue from XDMA C2H node
    # ------------------------------------------------------------------

    def _dma_reader(self):
        while self.running:
            try:
                raw = os.read(self._fd_c2h, self.chunk_bytes)
            except OSError as e:
                print(f"[PeriR] DMA read error: {e}")
                break

            if len(raw) < 4:
                continue

            # Unpack int16 pairs -> complex float
            samples = np.frombuffer(raw, dtype=np.int16).astype(np.float32)
            # Even indices = I, odd indices = Q
            i_samples = samples[0::2] / self.ADC_FULLSCALE
            q_samples = samples[1::2] / self.ADC_FULLSCALE
            iq = (i_samples + 1j * q_samples).astype(np.complex64)

            try:
                self._buf_queue.put(iq, timeout=0.1)
            except queue.Full:
                pass  # drop chunk — consumer too slow

    # ------------------------------------------------------------------
    # Device open/close
    # ------------------------------------------------------------------

    def _open_devices(self):
        try:
            self._fd_c2h  = os.open(self.XDMA_C2H,  os.O_RDONLY)
            self._fd_user = os.open(self.XDMA_USER, os.O_RDWR)
        except FileNotFoundError as e:
            raise RuntimeError(f"[PeriR] XDMA device not found: {e}. "
                               "Is the FPGA programmed and XDMA driver loaded?")
        except PermissionError:
            raise RuntimeError("[PeriR] Permission denied. Run GRC with sudo "
                               "or add udev rules for /dev/xdma*")

    def _close_devices(self):
        for fd in [self._fd_c2h, self._fd_user]:
            if fd is not None:
                try:
                    os.close(fd)
                except OSError:
                    pass
        self._fd_c2h  = None
        self._fd_user = None

    # ------------------------------------------------------------------
    # FPGA register access
    # ------------------------------------------------------------------

    def _reg_read(self, offset):
        os.lseek(self._fd_user, offset, os.SEEK_SET)
        return struct.unpack("<I", os.read(self._fd_user, 4))[0]

    def _reg_write(self, offset, value):
        os.lseek(self._fd_user, offset, os.SEEK_SET)
        os.write(self._fd_user, struct.pack("<I", int(value)))

    # ------------------------------------------------------------------
    # AD9364 configuration via BAR0 register window
    # (FPGA SPI engine executes these — matches ad9364_spi_bringup.v)
    # ------------------------------------------------------------------

    def _configure_ad9364(self):
        print(f"[PeriR] Configuring AD9364:")
        print(f"  Sample rate : {self.sample_rate/1e6:.3f} MSPS")
        print(f"  Center freq : {self.center_freq/1e6:.3f} MHz")
        print(f"  RX gain     : {self.gain} dB")

        # Write tuning parameters to FPGA register window
        # FPGA SPI engine picks these up and programs the AD9364 via SPI
        freq_int = int(self.center_freq)
        self._reg_write(self.REG_CENTER_FREQ,       freq_int & 0xFFFFFFFF)
        self._reg_write(self.REG_CENTER_FREQ + 0x4, (freq_int >> 32) & 0xFFFFFFFF)
        self._reg_write(self.REG_RX_GAIN,           int(self.gain))

        # Verify version register as a sanity check
        ver = self._reg_read(self.REG_VERSION)
        print(f"  FPGA version: 0x{ver:08X}", end="")
        print(" [OK]" if ver == 0xE010001 else " [unexpected]")

    def _start_dma(self):
        self._reg_write(self.REG_DMA_CTRL, self.DMA_START)
        print("[PeriR] DMA started")

    def _stop_dma(self):
        if self._fd_user is not None:
            self._reg_write(self.REG_DMA_CTRL, self.DMA_STOP)
            print("[PeriR] DMA stopped")

    # ------------------------------------------------------------------
    # Runtime parameter setters (callable from GRC callbacks)
    # ------------------------------------------------------------------

    def set_center_freq(self, freq):
        self.center_freq = freq
        if self._fd_user is not None:
            freq_int = int(freq)
            self._reg_write(self.REG_CENTER_FREQ,       freq_int & 0xFFFFFFFF)
            self._reg_write(self.REG_CENTER_FREQ + 0x4, (freq_int >> 32) & 0xFFFFFFFF)

    def set_gain(self, gain):
        self.gain = gain
        if self._fd_user is not None:
            self._reg_write(self.REG_RX_GAIN, int(gain))

    def set_sample_rate(self, rate):
        self.sample_rate = rate
        # Sample rate changes require AD9364 filter reconfiguration
        # — implement via no-OS driver call when CM4-side driver is ready
        print(f"[PeriR] Sample rate change to {rate/1e6:.3f} MSPS "
              "(requires AD9364 reinit — not yet implemented in barebones)")
