# PeriR
<img width="2048" height="1152" alt="Adobe Express - file" src="https://github.com/user-attachments/assets/585b32f5-28f4-4f51-b9d1-292b330a54c2" />

A custom Software Defined Radio (SDR) HAT built around the **Xilinx Artix-7 XC7A50T FPGA** and **Analog Devices AD9364** RF transceiver. The board is designed to run **Kuiper Linux** (Analog Devices' Raspberry Pi OS-based distro).

---

## Overview

This project is inspired by the [FreeSRP](http://electronics.kitchen/misc/freesrp/) open-source SDR by Lukas Lao Beyer and design references from the **FMCOMMS4**, .

The goal is a powerful, Linux-capable SDR transceiver with a compact form factor and eventually, a handheld device like the HackRF Portapack.

---

## Key Specifications

| Feature | Detail |
|---|---|
| **SoM** |Compute Module 4 |
| **FPGA** | Xilinx Artix-7 XC7A50T FPGA (~50K LUTs) |
| **RF Transceiver** | Analog Devices AD9364 |
| **Frequency Range** | 70 MHz – 6.0 GHz |
| **Bandwidth** | 200 kHz – 56 MHz |
| **OS** | Kuiper Linux (Analog Devices / Raspberry Pi OS based) |
| **Primary Storage** | MicroSD card |

---

## Hardware Design

### RF Transceiver — AD9364
- **Signalling standard:** LVDS (chosen over CMOS for lower EMI and higher throughput)
- **Balun:** TCM1-63AX+ wideband RF transformer (≤1.8 dB insertion loss @ 6 GHz)
- **Clock:** 40 MHz, 10 pF load capacitance (tested reference from AD)
- **Power rail:** 1.3V via ADP1754ACPZ-1.3-R7 (AD-recommended for stability)
- **TX Power Amp:** PGA-102 (dedicated clean 3.3V supply)

### Xilinx Artix-7 XC7A50T FPGA
- **Configuration:** JTAG
- **PCIe interface:** Signal lines terminated at 40 Ω

### Power Architecture


| Rail | IC | Current | 
|---|---|---|---|
| 1.0V | TPS62130A | 3A | 
| 1.8V | TPS62130A | 3A | 
| 3.3V | TPS62130A | 3A | 
| 2.5V | TPS62130A | 3A | 
| 1.2V | TPS62130A | 3A | 
| 1.3V | ADP1754ACPZ-1.3-R7 
| 5V | External connector 

> Sequencing is managed using EN (Enable) and PG (Power Good) pins chained between power ICs.

### Interfaces
**CM4 INTERFACES**
| CM4 Interface | IC / Notes |
|---|---|
| **HDMI** | Standard HDMI |
| **USB** | Standard USB 2.0  |
| **DSI** | Display connector |
| **SD Card** | Level-shifted (1.8V MIO → 3.3V SD logic) |
| **PCIe** | Interface between the CM4 and FPGA |
**FPGA INTERFACES**
| FPGA Interface | IC / Notes |
|---|---|
| **USB 2.0** | via the FT2232HL |


## Software

- **OS:** [Kuiper Linux](https://wiki.analog.com/resources/tools-software/linux-software/kuiper-linux) by Analog Devices
- **SDR Applications:** GNU Radio, SDR++
- **FPGA toolchain:** Xilinx Vivado + Analog Devices HDL reference designs
- **Reference HDL:** [Analog Devices HDL](https://github.com/analogdevicesinc/hdl) (FMCOMMS4 / ADRV9364 compatible)

---

## Design References

- [FreeSRP](http://electronics.kitchen/misc/freesrp/) — Lukas Lao Beyer
- Analog Devices FMCOMMS4
- **Key Datasheets:** ARTIX-7 DATASHEETS, AD9364 Reference Manual, CM4 DATASHEETS

---

## Fallout Zine:
<img width="2644" height="3560" alt="periR (4)" src="https://github.com/user-attachments/assets/88433372-a68d-480f-afb8-ecb6dbec54ab" />


*Special Thanks to Hack Club and the fabulous people at Fallout 2026!*

