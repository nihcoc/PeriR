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

<img width="2552" height="3584" alt="periR (7)" src="https://github.com/user-attachments/assets/a3692e8a-0c40-4a74-8f8e-e91de8aa9a11" />



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

## Bill of Materials



 Total = ~$425(excl. shipping)

| # | LCSC# | MPN | Manufacturer | Package | Board Ref | Description | Qty | MOQ | Unit Price ($) | Ext. Price ($) | Product Link |
|---|-------|-----|--------------|---------|-----------|-------------|-----|-----|---------------|----------------|--------------|
| 1 | C444946 | AD9364BBCZ | ADI | BGA-144 | U4 | -122dBm 70MHz~6GHz 1.2V~3.3V BGA-144 RF Transceiver ICs RoHS | 1 | 1 | 96.5166 | 96.52 | [Link](https://www.lcsc.com/product-detail/C444946.html) |
| 2 | C5199907 | SMA-J-P-H-ST-EM1 | Samtec | SMD | J12, J13, J14 | Connector Receptacle SMA 50Ω | 3 | 1 | 4.8959 | 14.69 | [Link](https://www.lcsc.com/product-detail/C5199907.html) |
| 3 | C337502 | TPS62130ARGTR | TI | QFN-16-EP(3x3) | U7, U8, U9, U10, U12 | 2.5MHz Step-down type Adjustable 900mV~6V 3A QFN-16-EP(3x3) Voltage Regulators - DC DC Switching Regulators RoHS | 5 | 1 | 0.7910 | 3.96 | [Link](https://www.lcsc.com/product-detail/C337502.html) |
| 4 | C9002 | X322512MSB4SI | YXC Crystal Oscillators | SMD3225-4P | Y4 | Crystal 12MHz ±10ppm 20pF SMD3225-4P | 5 | 5 | 0.1012 | 0.51 | [Link](https://www.lcsc.com/product-detail/C9002.html) |
| 5 | C55061480 | PUBFA-R23A-003 | YUWENFA | Through Hole | J7 | USB 2.0 Through Hole USB, DVI, HDMI Connector Adapters RoHS | 5 | 5 | 0.0583 | 0.29 | [Link](https://www.lcsc.com/product-detail/C55061480.html) |
| 6 | C720616 | HDMI-001S | XUNPU | SMD | J5 | HDMI-A Receptacle Connector 19 Position Surface Mount, Right Angle | 5 | 5 | 0.2424 | 1.21 | [Link](https://www.lcsc.com/product-detail/C720616.html) |
| 7 | C2765186 | TYPE-C 16PIN 2MD(073) | SHOU HAN | SMD | J9 | USB-C (USB TYPE-C) Receptacle Connector 16 Position Surface Mount, Right Angle | 20 | 20 | 0.0707 | 1.41 | [Link](https://www.lcsc.com/product-detail/C2765186.html) |
| 8 | C7529389 | TF-CARD H1.8 | SHOU HAN | SMD | J2 | Micro SD card (TF card) Connector and Ejector Push-Push Surface Mount | 10 | 10 | 0.0608 | 0.61 | [Link](https://www.lcsc.com/product-detail/C7529389.html) |
| 9 | C720557 | DC-005-A200 | XUNPU | Through Hole | J10 | Power Barrel Connector Jack 2mm ID 6.4mm OD Through Hole, Right Angle | 5 | 5 | 0.1294 | 0.65 | [Link](https://www.lcsc.com/product-detail/C720557.html) |
| 10 | C502010 | MLJ1608WR33JT000 | TDK | 0603 | L13, L14 | 500mA 330nH ±5% 320mΩ 650mA Multilayer inductor 0603 Fixed Inductors RoHS | 10 | 10 | 0.0744 | 0.74 | [Link](https://www.lcsc.com/product-detail/C502010.html) |
| 11 | C85837 | BLM21AG601SN1D | muRata | 0805 | FB4 | 600Ω@100MHz 1 Line Ferrite Bead 0805 700mA 210mΩ | 20 | 20 | 0.0618 | 1.24 | [Link](https://www.lcsc.com/product-detail/C85837.html) |
| 12 | C424649 | DF40HC(3.0)-100DS-0.4V(51) | HRS | SMD, P=0.4mm | H1 | High-Density Board-to-Board Connector 100-pos 0.4mm pitch | 2 | 1 | 1.8918 | 3.78 | [Link](https://www.lcsc.com/product-detail/C424649.html) |
| 13 | C25120 | 0402WGF499JTCE | UNI-ROYAL | 0402 | R33 | 49.9Ω ±1% 62.5mW 0402 Thick Film Resistor | 100 | 100 | 0.0011 | 0.11 | [Link](https://www.lcsc.com/product-detail/C25120.html) |
| 14 | C2906901 | FRC0402J1R0 TS | FOJAN | 0402 | R31, R32 | 1Ω ±5% 62.5mW 0402 Thick Film Resistor | 100 | 100 | 0.0016 | 0.16 | [Link](https://www.lcsc.com/product-detail/C2906901.html) |
| 15 | C852856 | RT0402BRD075K1L | YAGEO | 0402 | R27, R28 | 5.1kΩ 62.5mW 50V Thin Film Resistor ±25ppm/℃ ±0.1% 0402 Chip Resistor - Surface Mount RoHS | 50 | 50 | 0.0216 | 1.08 | [Link](https://www.lcsc.com/product-detail/C852856.html) |
| 16 | C2909316 | FRC0402F1202TS | FOJAN | 0402 | R25 | 12kΩ ±1% 62.5mW 0402 Thick Film Resistor | 100 | 100 | 0.0014 | 0.14 | [Link](https://www.lcsc.com/product-detail/C2909316.html) |
| 17 | C190095 | RT0402BRD0710KL | YAGEO | 0402 | R19, R20, R24, R30, R35 | 62.5mW 10kΩ 50V Thin Film Resistor ±25ppm/℃ ±0.1% 0402 Chip Resistor - Surface Mount RoHS | 50 | 50 | 0.0207 | 1.04 | [Link](https://www.lcsc.com/product-detail/C190095.html) |
| 18 | C2906865 | FRC0402F2201TS | FOJAN | 0402 | R17, R18 | 2.2kΩ ±1% 62.5mW 0402 Thick Film Resistor | 100 | 100 | 0.0016 | 0.16 | [Link](https://www.lcsc.com/product-detail/C2906865.html) |
| 19 | C106232 | RC0402FR-07100RL | YAGEO | 0402 | R8 | 100Ω 62.5mW 50V Thick Film Resistor ±100ppm/℃ ±1% 0402 Chip Resistor - Surface Mount RoHS | 100 | 100 | 0.0013 | 0.13 | [Link](https://www.lcsc.com/product-detail/C106232.html) |
| 20 | C242160 | ERJ2GE0R00X | PANASONIC | 0402 | R7 | 100mW 0Ω Thick Film Resistor -100ppm/℃~+600ppm/℃ 0402 Chip Resistor - Surface Mount RoHS | 100 | 100 | 0.0047 | 0.47 | [Link](https://www.lcsc.com/product-detail/C242160.html) |
| 21 | C71626 | CRCW0402330RFKED | VISHAY | 0402 | R5 | 63mW 330Ω Thick Film Resistor ±100ppm/℃ ±1% 0402 Chip Resistor - Surface Mount RoHS | 100 | 100 | 0.0037 | 0.37 | [Link](https://www.lcsc.com/product-detail/C71626.html) |
| 22 | C1884625 | MCS04020C4701FE000 | VISHAY | 0402 | R2, R3, R29 | 100mW 4.7kΩ 50V Thin Film Resistor ±50ppm/℃ ±1% 0402 Chip Resistor - Surface Mount RoHS | 20 | 20 | 0.0304 | 0.61 | [Link](https://www.lcsc.com/product-detail/C1884625.html) |
| 23 | C852624 | RT0402BRD071KL | YAGEO | 0402 | R1, R2(DNP), R3(DNP), R4, R5(DNP), R6, R26 | 1kΩ 62.5mW 50V Thin Film Resistor ±25ppm/℃ ±0.1% 0402 Chip Resistor - Surface Mount RoHS | 50 | 50 | 0.0199 | 1.00 | [Link](https://www.lcsc.com/product-detail/C852624.html) |
| 24 | C5633358 | ECS-TXO-32CSMV-400-BN-TR | ECS | SMD3225-4P | Y6 | 40MHz SMD3225-4P Oscillators RoHS | 1 | 1 | 2.6285 | 2.63 | [Link](https://www.lcsc.com/product-detail/C5633358.html) |
| 25 | C7522691 | LQW18AS43NJ00D | muRata | 0603 | L11 | 600mA 43nH ±5% 280mΩ Wire-wound chip inductor 0603 Fixed Inductors RoHS | 5 | 5 | 0.0895 | 0.45 | [Link](https://www.lcsc.com/product-detail/C7522691.html) |
| 26 | C51048295 | FRC0402F1432TS | FOJAN | 0402 | R34 | 62.5mW 14.3kΩ 50V Thick Film Resistor ±1% 0402 Chip Resistor - Surface Mount RoHS | 100 | 100 | 0.0008 | 0.08 | [Link](https://www.lcsc.com/product-detail/C51048295.html) |
| 27 | C2906952 | FRC0402J513 TS | FOJAN | 0402 | R84 | 51kΩ ±5% 62.5mW 0402 Thick Film Resistor | 100 | 100 | 0.0013 | 0.13 | [Link](https://www.lcsc.com/product-detail/C2906952.html) |
| 28 | C144785 | AC0402FR-07200KL | YAGEO | 0402 | R85, R125 | 62.5mW 200kΩ 50V Thick Film Resistor ±100ppm/℃ ±1% 0402 Chip Resistor - Surface Mount RoHS | 100 | 100 | 0.0018 | 0.18 | [Link](https://www.lcsc.com/product-detail/C144785.html) |
| 29 | C481918 | CRCW0402100KFKED | VISHAY | 0402 | R86, R87, R88, R89, R91, R127, R129, R133 | 100kΩ 63mW 50V Thick Film Resistor ±1% ±100ppm/℃ 0402 Chip Resistor - Surface Mount RoHS | 100 | 100 | 0.0038 | 0.38 | [Link](https://www.lcsc.com/product-detail/C481918.html) |
| 30 | C7467320 | FRC0402J164 TS | FOJAN | 0402 | R126 | 62.5mW 160kΩ 50V Thick Film Resistor ±5% ±100ppm/℃ 0402 Chip Resistor - Surface Mount RoHS | 100 | 100 | 0.0011 | 0.11 | [Link](https://www.lcsc.com/product-detail/C7467320.html) |
| 31 | C2906873 | FRC0402F4992TS | FOJAN | 0402 | R128 | 49.9kΩ ±1% 62.5mW 0402 Thick Film Resistor | 100 | 100 | 0.0015 | 0.15 | [Link](https://www.lcsc.com/product-detail/C2906873.html) |
| 32 | C2515044 | RN73H1ETTP2133D25 | KOA | 0402 | R130 | 62.5mW 213kΩ Metal Film Resistor ±0.5% ±25ppm/℃ 0402 Chip Resistor - Surface Mount RoHS | 1 | 1 | 0.0568 | 0.06 | [Link](https://www.lcsc.com/product-detail/C2515044.html) |
| 33 | C4180598 | RE0402BRE07309KL | YAGEO | 0402 | R134 | 309kΩ 62.5mW Thick Film Resistor ±50ppm/℃ ±0.1% 0402 Chip Resistor - Surface Mount RoHS | 20 | 20 | 0.0111 | 0.22 | [Link](https://www.lcsc.com/product-detail/C4180598.html) |
| 34 | C494678 | TCM1-63AX+ | Mini-Circuits | SMD-6P | T4, T6 | 9.42dB 8° 10MHz~6GHz 2.5dB 50Ω:50Ω SMD-6P Balun RoHS | 2 | 1 | 17.6099 | 35.22 | [Link](https://www.lcsc.com/product-detail/C494678.html) |
| 35 | C1521759 | XC7A50T-2CSG325I | AMD/XILINX | FPGA-325(15x15) | U2 | 52160 FPGA-325(15x15) FPGAs (Field Programmable Gate Array) RoHS | 1 | 1 | 52.4575 | 52.46 | [Link](https://www.lcsc.com/product-detail/C1521759.html) |
| 36 | C27882 | FT2232HL-REEL | FTDI | LQFP-64(10x10) | U3 | 480Mbps USB 2.0 LQFP-64(10x10) Interface Controllers RoHS | 1 | 1 | 12.4162 | 12.42 | [Link](https://www.lcsc.com/product-detail/C27882.html) |
| 37 | C3193264 | PGA-102+ | Mini-Circuits | SOT-89 | U11 | 10.4dB 50MHz~6GHz 3.1V~3.5V 3.9dB 17.5dBm 83mA SOT-89 RF Amplifiers RoHS | 1 | 1 | 2.3356 | 2.34 | [Link](https://www.lcsc.com/product-detail/C3193264.html) |
| 38 | C1997058 | SG-8018CA 100.0000M-TJHSA0 | EPSON | SMD7050-4P | Y2 | 100MHz SMD7050-4P Oscillators RoHS | 1 | 1 | 1.0742 | 1.07 | [Link](https://www.lcsc.com/product-detail/C1997058.html) |
| 39 | C76941 | GRM033R71A103KA01D | muRata | 0201 | C284, C292, C305 | 10nF ±10% 10V Ceramic Capacitor X7R 0201 | 100 | 100 | 0.0050 | 0.50 | [Link](https://www.lcsc.com/product-detail/C76941.html) |
| 40 | C368809 | CL05A475KP5NRNC | Samsung Electro-Mechanics | 0402 | C1, C2, C9, C12, C13, C18, C19, C24, C25, C30, C31, C46, C85, C86, C313 | 4.7uF ±10% 10V Ceramic Capacitor X5R 0402 | 50 | 50 | 0.0116 | 0.58 | [Link](https://www.lcsc.com/product-detail/C368809.html) |
| 41 | C6663208 | 298W107X0004M2T | VISHAY | 0603 | C3, C14 | 100uF ±20% 4V Tantalum Capacitors 0603 | 2 | 1 | 1.8719 | 3.74 | [Link](https://www.lcsc.com/product-detail/C6663208.html) |
| 42 | C92361 | CL05A474KA5NNNC | Samsung Electro-Mechanics | 0402 | C4, C5, C6, C11, C15, C16, C17, C20, C21, C22, C23, C26, C27, C28, C29, C32, C33, C34, C35 | 470nF ±10% 25V Ceramic Capacitor X5R 0402 | 20 | 10 | 0.0163 | 0.33 | [Link](https://www.lcsc.com/product-detail/C92361.html) |
| 43 | C60474 | CC0402KRX7R7BB104 | YAGEO | 0402 | C267, C271, C277, C287, C289, C291, C295, C296, C310, C320 | 100nF ±10% 16V Ceramic Capacitor X7R 0402 | 200 | 100 | 0.0072 | 1.44 | [Link](https://www.lcsc.com/product-detail/C60474.html) |
| 44 | C140782 | GRM188R60J476ME15D | muRata | 0603 | C10, C42, C43, C265, C269, C274, C281, C285, C288, C290, C293, C308 | 47uF ±20% 6.3V Ceramic Capacitor X5R 0603 | 20 | 10 | 0.1431 | 2.86 | [Link](https://www.lcsc.com/product-detail/C140782.html) |
| 45 | C51412 | CL10A335KP8NNNC | Samsung Electro-Mechanics | 0603 | C77 | 3.3uF ±10% 10V Ceramic Capacitor X5R 0603 | 10 | 10 | 0.0311 | 0.31 | [Link](https://www.lcsc.com/product-detail/C51412.html) |
| 46 | C384976 | GRM0335C1H270GA01D | muRata | 0201 | C89, C90 | 27pF ±2% 50V Ceramic Capacitor C0G 0201 | 100 | 100 | 0.0048 | 0.48 | [Link](https://www.lcsc.com/product-detail/C384976.html) |
| 47 | C29266 | CL05A105KO5NNNC | Samsung Electro-Mechanics | 0402 | C91, C97, C304, C306, C307, C314 | 1uF ±10% 16V Ceramic Capacitor X5R 0402 | 100 | 100 | 0.0072 | 0.72 | [Link](https://www.lcsc.com/product-detail/C29266.html) |
| 48 | C307380 | CL03A104KO3NNNC | Samsung Electro-Mechanics | 0201 | C99, C100, C101, C102, C103, C105, C106, C107, C108, C109, C111, C112, C113, C115, C117, C118, C119, C312 | 100nF ±10% 16V Ceramic Capacitor X5R 0201 | 200 | 100 | 0.0029 | 0.58 | [Link](https://www.lcsc.com/product-detail/C307380.html) |
| 49 | C19702 | CL10A106KP8NNNC | Samsung Electro-Mechanics | 0603 | C104, C110, C114, C116, C266, C270, C275, C283, C286, C294, C309, C321 | 10uF ±10% 10V Ceramic Capacitor X5R 0603 | 20 | 20 | 0.0822 | 1.64 | [Link](https://www.lcsc.com/product-detail/C19702.html) |
| 50 | C62164 | 0201CG180J500NT | FH | 0201 | C120, C121, C317, C318 | 18pF ±5% 50V Ceramic Capacitor C0G 0201 | 100 | 100 | 0.0029 | 0.29 | [Link](https://www.lcsc.com/product-detail/C62164.html) |
| 51 | C161488 | GRM033R71E222KA12D | muRata | 0201 | C262, C264, C272, C280, C303 | 2.2nF ±10% 25V Ceramic Capacitor X7R 0201 | 100 | 100 | 0.0052 | 0.52 | [Link](https://www.lcsc.com/product-detail/C161488.html) |
| 52 | C86295 | CL10A226MP8NUNE | Samsung Electro-Mechanics | 0603 | C263, C268, C278, C297 | 22uF ±20% 10V Ceramic Capacitor X5R 0603 | 10 | 10 | 0.0380 | 0.38 | [Link](https://www.lcsc.com/product-detail/C86295.html) |
| 53 | C122469 | XFL4020-222MEC | Coilcraft | SMD, 4x4mm | L7, L8, L9, L10, L12 | 8A 2.2uH ±20% 21.35mΩ 3.7A SMD 4x4mm Fixed Inductors RoHS | 5 | 1 | 1.3566 | 6.78 | [Link](https://www.lcsc.com/product-detail/C122469.html) |
| 54 | C602037 | CL21A226MAYNNNE | Samsung Electro-Mechanics | 0805 | C311 | 22uF ±20% 25V Ceramic Capacitor X5R 0805 | 10 | 10 | 0.1135 | 1.14 | [Link](https://www.lcsc.com/product-detail/C602037.html) |
| 55 | C17291088 | GCM033R71A122KA03D | muRata | 0201 | C315 | 1.2nF X7R ±10% 10V 0201 Ceramic Capacitors RoHS | 100 | 100 | 0.0094 | 0.94 | [Link](https://www.lcsc.com/product-detail/C17291088.html) |
| 56 | C88914 | GRM0335C1H680JA01D | muRata | 0201 | C316 | 68pF ±5% 50V Ceramic Capacitor C0G 0201 | 100 | 100 | 0.0017 | 0.17 | [Link](https://www.lcsc.com/product-detail/C88914.html) |
| 57 | C505464 | CC0201KRX7R9BB102 | YAGEO | 0201 | C319 | 1nF ±10% 50V Ceramic Capacitor X7R 0201 | 100 | 100 | 0.0018 | 0.18 | [Link](https://www.lcsc.com/product-detail/C505464.html) |
| 58 | C133346 | ESD8472MUT5G | onsemi | X3-DFN-2(0.3x0.6) | D5, D12 | 15V Clamp 20V Clamp 3A@8/20us Ipp ESD DIODE X3-DFN-2(0.3x0.6) | 5 | 5 | 0.0826 | 0.41 | [Link](https://www.lcsc.com/product-detail/C133346.html) |
| 59 | C598848 | MT25QU128ABA8ESF-0SIT | Micron | SOIC-16-300mil | IC1 | SOIC-16-300mil NOR Flash Memory RoHS | 1 | 1 | 10.2374 | 10.24 | [Link](https://www.lcsc.com/product-detail/C598848.html) |
| 60 | C613841 | 93C46B/P | MICROCHIP | PDIP-8 | IC3 | 1Kbit 4.5V~5.5V 2MHz SPI PDIP-8 Memory (ICs) RoHS | 1 | 1 | 1.0827 | 1.08 | [Link](https://www.lcsc.com/product-detail/C613841.html) |
| 61 | C3747719 | ADP1754ACPZ-1.3-R7 | ADI | LFCSP-16(4x4) | IC10, IC11 | 1.3V Positive Fixed LFCSP-16(4x4) Voltage Regulators - Linear, Low Drop Out (LDO) Regulators RoHS | 2 | 1 | 4.6333 | 9.27 | [Link](https://www.lcsc.com/product-detail/C3747719.html) |
| 62 | C892685 | NCP700BSN33T1G | onsemi | TSOP-5-1.5mm | IC13 | 3.3V Positive Fixed TSOP-5-1.5mm Voltage Regulators - Linear, Low Drop Out (LDO) Regulators RoHS | 1 | 1 | 1.2691 | 1.27 | [Link](https://www.lcsc.com/product-detail/C892685.html) |
| 63 | C658468 | ADM7160AUJZ-1.8-R7 | ADI | TSOT-5 | IC14 | Linear Voltage Regulator IC Positive Fixed 1 Output 200mA TSOT-5 | 1 | 1 | 2.7671 | 2.77 | [Link](https://www.lcsc.com/product-detail/C658468.html) |
| 64 | C5410688 | 69145-210LF | Amphenol | — | J1 | Open-Top 2.54mm Shunts, Jumpers RoHS | 1 | 1 | 1.0308 | 1.03 | [Link](https://www.lcsc.com/product-detail/C5410688.html) |
| 65 | C3168185 | FH19SC-22S-0.5SH(09) | HRS | SMD, P=0.5mm | J6 | FFC/FPC Connector 22 Position 0.5mm Pitch Bottom Contact Surface Mount, Right Angle | 1 | 1 | 1.7125 | 1.71 | [Link](https://www.lcsc.com/product-detail/C3168185.html) |
| 66 | --- | Compute Module 4 CM4101000 WIFI Lite | RPi | --- | --- | --- | 1 | 1 | 95 | 95 | [Link](https://ar.aliexpress.com/item/1005008557413104.html?spm=a2g0o.productlist.main.2.4574vHeWvHeWo5&algo_pvid=dbca0ea5-76ce-4cef-a374-f51fa96f5d17&algo_exp_id=dbca0ea5-76ce-4cef-a374-f51fa96f5d17-1&pdp_ext_f=%7B%22order%22%3A%2256%22%2C%22eval%22%3A%221%22%2C%22fromPage%22%3A%22search%22%7D&pdp_npi=6%40dis%21AED%21291.96%21291.96%21%21%21522.94%21522.94%21%40214100f417822410718697426e529a%2112000045700124987%21sea%21AE%210%21ABX%211%210%21n_tag%3A-29910%3Bd%3Ae64a854d%3Bm03_new_user%3A-29895&curPageLogUid=OTnqg2gbWbCW&utparam-url=scene%3Asearch%7Cquery_from%3A%7Cx_object_id%3A1005008557413104%7C_p_origin_prod%3A) |
| 67 | --- | PCB | JLCPCB | --- | --- | 6 - Layer | 1 | 1 | 40 | 40 | --- |


---
See my journal [here](https://fallout.hackclub.com/projects/317)
---
*Special Thanks to Hack Club and the fabulous people at Fallout 2026!*

