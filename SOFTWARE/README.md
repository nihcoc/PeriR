# PeriR — Barebones Bringup Code

## Structure

```
perir/
├── fpga/
│   ├── loopback_reg.v        # Phase 1: AXI register loopback (no AD9364)
│   └── ad9364_spi_bringup.v  # Phase 2: SPI chip ID read
├── cm4/
│   ├── cm4_xdma_test.py      # Phase 3: PCIe + BAR0 register test from CM4
│   └── integration_test.py   # Phase 5: End-to-end IQ streaming test
└── gnuradio/
    └── perir_source.py       # Phase 4+: GNU Radio source block
```

## Build Order

| Phase | File | What it proves |
|-------|------|----------------|
| 1 | `loopback_reg.v` + `cm4_xdma_test.py` | PCIe link up, AXI R/W works |
| 2 | `ad9364_spi_bringup.v` + `cm4_xdma_test.py` | AD9364 alive on SPI |
| 3 | `integration_test.py` | IQ samples flowing end-to-end |
| 4 | `perir_source.py` | GNU Radio can receive IQ |

## FPGA Setup

1. Build ADI HDL library (`axi_ad9361`, `axi_dmac`)
2. Create Vivado project targeting `xc7a50tcsg325`
3. Add `loopback_reg.v` as top module for Phase 1
4. Add `ad9364_spi_bringup.v` for Phase 2
5. Gradually replace with `perir_top.v` (full design)

## CM4 Setup (Kuiper Linux)

```bash
# Load XDMA driver
sudo modprobe xdma

# Verify PCIe
lspci

# Run tests
sudo python3 cm4/cm4_xdma_test.py
sudo python3 cm4/integration_test.py
```

## Notes

- All register offsets in CM4 code must match FPGA design exactly
- Run CM4 scripts with `sudo` (XDMA devices need root by default)
- Add udev rules later to avoid sudo requirement
