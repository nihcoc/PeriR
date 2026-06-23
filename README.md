# PeriR
<img width="2048" height="1152" alt="Adobe Express - file" src="https://github.com/user-attachments/assets/585b32f5-28f4-4f51-b9d1-292b330a54c2" />

A custom Software Defined Radio (SDR) HAT built around the **Xilinx Artix-7 XC7A50T FPGA** and **Analog Devices AD9364** RF transceiver. The board is designed to run **Kuiper Linux** (Analog Devices' Raspberry Pi OS-based distro).

---

## Overview

This project is inspired by the [FreeSRP](http://electronics.kitchen/misc/freesrp/) open-source SDR by Lukas Lao Beyer and design references from the **FMCOMMS4**.

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
- **SoM interface:** PCIe 2.0 x1 

### Power Architecture


| Rail | IC | Current | 
|---|---|---|
| 1.0V | TPS62130A | 3A | 
| 1.8V | TPS62130A | 3A | 
| 3.3V | TPS62130A | 3A | 
| 2.5V | TPS62130A | 3A | 
| 1.2V | TPS62130A | 3A | 
| 1.3V | ADP1754ACPZ-1.3-R7 | 3A |
| 5V | External connector | ~ 8A  |

> Sequencing is managed using EN (Enable) and PG (Power Good) pins chained between power ICs.

### Interfaces
**CM4 INTERFACES**
| CM4 Interface |
|---|
| **HDMI** | 
| **USB** | 
| **DSI** | 
| **SD Card** |  
| **PCIe 2.0 x1** | 


**FPGA INTERFACES**
| FPGA Interface | IC / Notes |
|---|---|
| **USB 2.0** | via the FT2232HL |
| **PCIe 2.0 x1** | MGT Bank |
---

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

## Fallout Zine

<img width="2552" height="3584" alt="periR (6)" src="https://github.com/user-attachments/assets/02370bb0-3d5a-4adb-98f5-ecb308c7c9a8" />


## Layers
<img width="1265" height="746" alt="Screenshot 2026-06-23 165112" src="https://github.com/user-attachments/assets/aad8353c-8c38-4183-840e-34fc1ee98b3a" />

*Layer 1(Top)*


<img width="1282" height="754" alt="Screenshot 2026-06-23 165122" src="https://github.com/user-attachments/assets/37b49cc8-02a7-40ee-b16f-10bcf0cd77f9" />

*Layer 2(GND)*


<img width="1224" height="741" alt="Screenshot 2026-06-23 165130" src="https://github.com/user-attachments/assets/c8930290-e2dc-429a-96c0-06285f54e87e" />

*Layer 3*


<img width="1239" height="746" alt="Screenshot 2026-06-23 165138" src="https://github.com/user-attachments/assets/d2326264-1f87-46fa-a07e-38b4f0e9431e" />

*Layer 4(Power)*


<img width="1235" height="735" alt="Screenshot 2026-06-23 165144" src="https://github.com/user-attachments/assets/e22e49de-feb1-4562-902b-2cdda438d79c" />

*Layer 5(GND)*


<img width="1239" height="733" alt="Screenshot 2026-06-23 165157" src="https://github.com/user-attachments/assets/bc858611-1d68-4fb7-9bfa-da9189a2653b" />

*Layer 6(Bottom)*

---

*Special Thanks to Hack Club and the fabulous people at Fallout 2026!*

