#!/usr/bin/env python3
"""
PeriR — CM4 + FPGA Integration Test
Phase 5: End-to-end IQ streaming verification

Tests the full chain:
  AD9364 -> LVDS -> Artix-7 -> PCIe DMA -> CM4 -> this script

Run on CM4 with Kuiper Linux:
  sudo python3 integration_test.py

What this checks:
  1. PCIe link and XDMA driver
  2. BAR0 register R/W
  3. AD9364 chip ID via SPI (confirms FPGA<->AD9364 link)
  4. IQ data streaming — confirms samples are flowing
  5. Signal sanity check — tunes to FM broadcast, checks for non-zero power
"""

import os
import sys
import struct
import numpy as np
import time

XDMA_USER = "/dev/xdma0_user"
XDMA_C2H  = "/dev/xdma0_c2h_0"
XDMA_H2C  = "/dev/xdma0_h2c_0"

# BAR0 register map — must match FPGA design
REG_VERSION     = 0x0004
REG_AD9364_ID   = 0x000C
REG_DMA_CTRL    = 0x0010
REG_CENTER_FREQ = 0x0018
REG_RX_GAIN     = 0x0020
REG_LINK_UP     = 0x0024   # PCIe link status from FPGA side

PASS = "\033[92m[PASS]\033[0m"
FAIL = "\033[91m[FAIL]\033[0m"
WARN = "\033[93m[WARN]\033[0m"
INFO = "\033[94m[INFO]\033[0m"


class XDMADevice:
    def __init__(self):
        self.fd_user = None
        self.fd_c2h  = None

    def open(self):
        try:
            self.fd_user = os.open(XDMA_USER, os.O_RDWR)
            self.fd_c2h  = os.open(XDMA_C2H,  os.O_RDONLY)
            return True
        except (FileNotFoundError, PermissionError) as e:
            print(f"  {FAIL} Cannot open XDMA: {e}")
            return False

    def close(self):
        for fd in [self.fd_user, self.fd_c2h]:
            if fd: os.close(fd)

    def read32(self, offset):
        os.lseek(self.fd_user, offset, os.SEEK_SET)
        return struct.unpack("<I", os.read(self.fd_user, 4))[0]

    def write32(self, offset, value):
        os.lseek(self.fd_user, offset, os.SEEK_SET)
        os.write(self.fd_user, struct.pack("<I", int(value)))

    def dma_read(self, n_bytes):
        return os.read(self.fd_c2h, n_bytes)


def header(title):
    print(f"\n{'='*50}")
    print(f"  {title}")
    print('='*50)


def test_pcie_link(dev):
    header("Test 1: PCIe Link + XDMA")

    # Version register sanity
    ver = dev.read32(REG_VERSION)
    if ver == 0xE010001:
        print(f"  {PASS} FPGA version register: 0x{ver:08X}")
    else:
        print(f"  {FAIL} Version mismatch: got 0x{ver:08X}, expected 0x0E010001")
        return False

    # PCIe link status from FPGA perspective
    link = dev.read32(REG_LINK_UP)
    if link & 0x1:
        print(f"  {PASS} PCIe link up (FPGA confirms)")
    else:
        print(f"  {WARN} FPGA link status register: 0x{link:08X} (may not be implemented yet)")

    return True


def test_ad9364_spi(dev):
    header("Test 2: AD9364 SPI Communication")

    chip_id = dev.read32(REG_AD9364_ID) & 0xFF

    if chip_id == 0x0A:
        print(f"  {PASS} AD9364 chip ID: 0x{chip_id:02X} — correct")
        return True
    elif chip_id == 0x0B:
        print(f"  {PASS} AD9361 chip ID: 0x{chip_id:02X} — compatible")
        return True
    elif chip_id == 0x00:
        print(f"  {FAIL} Chip ID is 0x00 — SPI not responding. Check:")
        print("         - AD9364 powered? (1.8V IO, 1.3V VDD)")
        print("         - SPI_CLK/DI/DO/ENB connected correctly?")
        print("         - FPGA SPI engine wired to this register?")
        return False
    else:
        print(f"  {FAIL} Unexpected chip ID: 0x{chip_id:02X}")
        return False


def test_iq_streaming(dev, n_samples=65536):
    header("Test 3: IQ Data Streaming")

    # Set a known frequency (FM broadcast band — 100 MHz)
    target_freq = int(100e6)
    dev.write32(REG_CENTER_FREQ,       target_freq & 0xFFFFFFFF)
    dev.write32(REG_CENTER_FREQ + 0x4, 0)
    dev.write32(REG_RX_GAIN, 40)       # 40 dB gain
    print(f"  {INFO} Tuned to 100.0 MHz, gain = 40 dB")

    # Start DMA
    dev.write32(REG_DMA_CTRL, 0x1)
    time.sleep(0.05)                   # let AD9364 settle

    # Read IQ samples
    n_bytes = n_samples * 4            # 2x int16 per sample
    print(f"  {INFO} Reading {n_samples} samples ({n_bytes} bytes)...")

    t0 = time.monotonic()
    raw = dev.dma_read(n_bytes)
    t1 = time.monotonic()

    dev.write32(REG_DMA_CTRL, 0x0)    # stop DMA

    if len(raw) < n_bytes:
        print(f"  {FAIL} Short read: got {len(raw)} bytes, expected {n_bytes}")
        return False

    elapsed = t1 - t0
    throughput_mbps = (n_bytes / elapsed) / 1e6
    print(f"  {PASS} Read {len(raw)} bytes in {elapsed*1000:.1f} ms "
          f"({throughput_mbps:.1f} MB/s)")

    # Unpack and analyse
    samples = np.frombuffer(raw, dtype=np.int16)
    i_vals  = samples[0::2].astype(np.float32)
    q_vals  = samples[1::2].astype(np.float32)
    iq      = i_vals + 1j * q_vals

    power_db = 10 * np.log10(np.mean(np.abs(iq)**2) + 1e-12)
    i_max    = np.max(np.abs(i_vals))
    q_max    = np.max(np.abs(q_vals))
    i_mean   = np.mean(i_vals)
    q_mean   = np.mean(q_vals)

    print(f"\n  IQ Statistics:")
    print(f"    Mean power     : {power_db:.1f} dBFS")
    print(f"    I peak         : {i_max:.0f} counts (max 2048 = full scale)")
    print(f"    Q peak         : {q_max:.0f} counts")
    print(f"    I DC offset    : {i_mean:.2f}  (should be near 0)")
    print(f"    Q DC offset    : {q_mean:.2f}  (should be near 0)")

    # Sanity checks
    if i_max < 1.0 and q_max < 1.0:
        print(f"\n  {FAIL} All samples are zero — data path not connected")
        return False

    if i_max > 2040 or q_max > 2040:
        print(f"\n  {WARN} Near saturation — reduce RX gain")
    else:
        print(f"\n  {PASS} Non-zero IQ data confirmed — AD9364 is streaming")

    if abs(i_mean) > 100 or abs(q_mean) > 100:
        print(f"  {WARN} Large DC offset — AD9364 DC correction may not be enabled")

    return True


def test_fm_signal(dev, n_samples=1048576):
    header("Test 4: FM Signal Detection (100 MHz)")

    dev.write32(REG_CENTER_FREQ, int(100e6))
    dev.write32(REG_RX_GAIN, 50)
    dev.write32(REG_DMA_CTRL, 0x1)
    time.sleep(0.1)

    raw = dev.dma_read(n_samples * 4)
    dev.write32(REG_DMA_CTRL, 0x0)

    samples = np.frombuffer(raw, dtype=np.int16)
    iq = (samples[0::2] + 1j * samples[1::2]).astype(np.complex64)

    # FFT — look for signal above noise floor
    fft  = np.abs(np.fft.fftshift(np.fft.fft(iq[:65536])))
    fft_db = 20 * np.log10(fft / np.max(fft) + 1e-12)

    noise_floor = np.median(fft_db)
    peak_db     = np.max(fft_db)
    snr         = peak_db - noise_floor

    print(f"  Noise floor    : {noise_floor:.1f} dBc")
    print(f"  Peak           : {peak_db:.1f} dBc")
    print(f"  Estimated SNR  : {snr:.1f} dB")

    if snr > 10:
        print(f"  {PASS} Signal detected at 100 MHz (SNR > 10 dB)")
        print("  You should see a peak in the spectrum at this frequency.")
        print("  Pipe into GNU Radio WBFM demodulator for audio.")
    elif snr > 3:
        print(f"  {WARN} Weak signal ({snr:.1f} dB SNR) — try increasing gain or moving antenna")
    else:
        print(f"  {WARN} No clear signal — may be normal if no FM station at 100 MHz")
        print("  Try: 87.5–108 MHz range for FM broadcast")

    return True


def main():
    print("\nPeriR Integration Test — CM4 + FPGA")
    print("=====================================")

    dev = XDMADevice()
    if not dev.open():
        print("\nCannot open XDMA devices. Checklist:")
        print("  sudo modprobe xdma")
        print("  ls /dev/xdma*")
        print("  lspci | grep -i xilinx")
        sys.exit(1)

    results = {}
    try:
        results["PCIe Link"]    = test_pcie_link(dev)
        results["AD9364 SPI"]   = test_ad9364_spi(dev)
        results["IQ Streaming"] = test_iq_streaming(dev)
        results["FM Signal"]    = test_fm_signal(dev)
    finally:
        dev.close()

    header("Summary")
    all_pass = True
    for name, passed in results.items():
        status = PASS if passed else FAIL
        print(f"  {status} {name}")
        if not passed:
            all_pass = False

    if all_pass:
        print(f"\n  All tests passed. PeriR integration is working.")
        print("  Next step: pipe IQ stream into GNU Radio via perir_source.py")
    else:
        print(f"\n  Some tests failed. Fix hardware/firmware issues above.")

    print()


if __name__ == "__main__":
    main()
