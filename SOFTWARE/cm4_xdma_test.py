#!/usr/bin/env python3
"""
PeriR CM4 — PCIe / XDMA Bringup Test
Phase 3: Verify CM4 can see FPGA over PCIe and talk to BAR0 registers.

Prerequisites on CM4 (Kuiper Linux):
  1. XDMA driver loaded:
       sudo modprobe xdma
     or if built from source:
       sudo insmod /path/to/xdma.ko

  2. Check PCIe enumeration first:
       lspci
     You should see something like:
       00:00.0 Memory controller: Xilinx Corporation Device 7021

  3. Run this script:
       sudo python3 cm4_xdma_test.py

BAR0 register map (matches loopback_reg.v):
  0x0000 : scratch (R/W)  — write any value, read back
  0x0004 : version (RO)   — should read 0xPE010001... well, 0x0E010001 in hex
  0x0008 : counter (RO)   — free-running, proves clock is running
"""

import os
import sys
import struct
import subprocess
import time

# XDMA device nodes — adjust index if multiple XDMA devices
XDMA_USER   = "/dev/xdma0_user"    # BAR0 register access (mmap)
XDMA_H2C    = "/dev/xdma0_h2c_0"  # host-to-card DMA (TX path)
XDMA_C2H    = "/dev/xdma0_c2h_0"  # card-to-host DMA (RX path)

# BAR0 register offsets
REG_SCRATCH = 0x0000
REG_VERSION = 0x0004
REG_COUNTER = 0x0008

# AD9364 chip ID result register (add this in your loopback_reg.v if wanted)
REG_AD9364_ID = 0x000C


def check_pcie():
    """Confirm FPGA is visible on PCIe bus."""
    print("--- PCIe Enumeration ---")
    result = subprocess.run(["lspci"], capture_output=True, text=True)
    print(result.stdout)
    # Xilinx/ADI devices show up as 10ee:**** vendor ID
    if "10ee" in result.stdout.lower() or "Xilinx" in result.stdout:
        print("[OK] Xilinx PCIe device found\n")
        return True
    else:
        print("[WARN] No Xilinx device found. Check:")
        print("  - Is the FPGA powered and programmed?")
        print("  - Is PERST# deasserted?")
        print("  - Run: sudo dmesg | grep pci")
        return False


def check_xdma_nodes():
    """Confirm XDMA driver created device nodes."""
    print("--- XDMA Device Nodes ---")
    nodes = [XDMA_USER, XDMA_H2C, XDMA_C2H]
    all_ok = True
    for node in nodes:
        exists = os.path.exists(node)
        status = "[OK]" if exists else "[MISSING]"
        print(f"  {status} {node}")
        if not exists:
            all_ok = False
    if not all_ok:
        print("\n  If nodes are missing, load the XDMA driver:")
        print("    sudo modprobe xdma  (or sudo insmod xdma.ko)")
        print("  Then check: ls /dev/xdma*")
    print()
    return all_ok


def bar0_read(fd, offset):
    """Read a 32-bit register from BAR0 at given byte offset."""
    os.lseek(fd, offset, os.SEEK_SET)
    data = os.read(fd, 4)
    return struct.unpack("<I", data)[0]   # little-endian


def bar0_write(fd, offset, value):
    """Write a 32-bit value to BAR0 at given byte offset."""
    os.lseek(fd, offset, os.SEEK_SET)
    os.write(fd, struct.pack("<I", value))


def test_registers():
    """Test BAR0 register read/write via XDMA user device."""
    print("--- BAR0 Register Test ---")

    try:
        fd = os.open(XDMA_USER, os.O_RDWR)
    except PermissionError:
        print("  [ERROR] Permission denied. Run with sudo.")
        return False
    except FileNotFoundError:
        print(f"  [ERROR] {XDMA_USER} not found. Is XDMA driver loaded?")
        return False

    # 1. Read version register — should be 0xPE010001
    version = bar0_read(fd, REG_VERSION)
    print(f"  Version register : 0x{version:08X}", end="")
    print("  [OK]" if version == 0xE010001 else "  [UNEXPECTED — check loopback_reg.v]")

    # 2. Read counter twice — confirm it's incrementing
    c1 = bar0_read(fd, REG_COUNTER)
    time.sleep(0.01)
    c2 = bar0_read(fd, REG_COUNTER)
    print(f"  Counter t0       : 0x{c1:08X}")
    print(f"  Counter t1       : 0x{c2:08X}", end="")
    print("  [OK — clock running]" if c2 > c1 else "  [FAIL — counter not incrementing]")

    # 3. Scratch register R/W
    test_val = 0xCAFEBABE
    bar0_write(fd, REG_SCRATCH, test_val)
    readback = bar0_read(fd, REG_SCRATCH)
    print(f"  Scratch write    : 0x{test_val:08X}")
    print(f"  Scratch readback : 0x{readback:08X}", end="")
    print("  [OK]" if readback == test_val else "  [FAIL — write/read mismatch]")

    # 4. AD9364 chip ID (if SPI bringup module is wired in)
    ad_id = bar0_read(fd, REG_AD9364_ID)
    print(f"  AD9364 chip ID   : 0x{ad_id:02X}", end="")
    if ad_id == 0x0A:
        print("  [OK — AD9364 detected]")
    elif ad_id == 0x0B:
        print("  [OK — AD9361 detected (compatible)]")
    else:
        print("  [FAIL or not yet wired — expected 0x0A]")

    os.close(fd)
    print()
    return True


def test_dma_loopback(size_bytes=4096):
    """
    DMA loopback test: write a pattern to H2C, read it back via C2H.
    Requires FPGA to have a loopback path wired (H2C FIFO -> C2H FIFO).
    Skip this test in Phase 1 — enable once DMA is wired in FPGA design.
    """
    print("--- DMA Loopback Test ---")
    print(f"  Transfer size: {size_bytes} bytes")

    pattern = bytes(range(256)) * (size_bytes // 256)

    try:
        # Write to FPGA
        with open(XDMA_H2C, "wb") as h2c:
            h2c.write(pattern)

        # Read back from FPGA
        with open(XDMA_C2H, "rb") as c2h:
            result = c2h.read(size_bytes)

        if result == pattern:
            print("  [OK] DMA loopback passed — data matches")
        else:
            mismatches = sum(a != b for a, b in zip(pattern, result))
            print(f"  [FAIL] {mismatches} byte mismatches")
            print(f"  First mismatch at byte {next(i for i,(a,b) in enumerate(zip(pattern,result)) if a!=b)}")

    except FileNotFoundError as e:
        print(f"  [SKIP] {e} — DMA nodes not present yet")
    except Exception as e:
        print(f"  [ERROR] {e}")
    print()


def main():
    print("=" * 50)
    print("PeriR PCIe / XDMA Bringup Test")
    print("=" * 50 + "\n")

    pcie_ok = check_pcie()
    nodes_ok = check_xdma_nodes()

    if not pcie_ok or not nodes_ok:
        print("Fix PCIe/driver issues before proceeding.")
        sys.exit(1)

    test_registers()
    test_dma_loopback()

    print("Done. If all tests passed, PCIe integration is working.")
    print("Next step: wire axi_ad9361 + axi_dmac into the FPGA design.")


if __name__ == "__main__":
    main()
