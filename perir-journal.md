# PeriR — Journal Export

- Exported at: 2026-08-25T12:12:30Z
- Project ID: 317
- Entries: 12

## Entry 1
- ID: 121
- Author: alfder
- Created At: 2026-03-17T08:27:40Z

### Content

Now this is a really hard project and tons of time will go into the design and firmware process. Along with that I need to learn the various complex signal processing concepts and HDL code that goes into this project. But nowadays theres more and more references and support on the internet. I am hoping to learn a looot from this project. Wish me luck!

So what am I doing?
I am making a carrier board that has an SDR on it with the Compute Module 4 acting as the Computer. SDRs need a computer for running apps such as GNU Radio or SDR++. 

Now what is an SDR?
A software defined radio is a device that moves signal processing from traditionally implemented analog circuits to software after the radio signal has been converted into digital samples.

An SDR can do :

- FM radio receiver
- ADS-B aircraft tracking
- satellite communication
- GSM or LTE research
- GPS receivers
- spectrum analyzers

SDR can be a transmitter, receiver, or transceiver. I'm hoping to make a transceiver. 

A Transceiver SDR is an SDR with both a transmitter and a reciever hence the name Transceiver. 

A Transceiver SDR has the following paths:
Receive path:
Antenna → RF front end → ADC → FPGA/CPU DSP → Software

Transmit path:
Software → DSP → DAC → RF upconverter → Power amplifier → Antenna

Now I need to do research on implementing these paths. Now, it is made easy cus theres lots of SDRs on the internet and some of them provide schematics.

So while looking for reference designs and guides I stumbled up on FreeSRP an Open Source SDR project by Lukas Lao Beyer. His work is incredible and I will be using his project as the primary reference for this project. (Link to hsi website: http://electronics.kitchen/misc/freesrp/ ) 

So after some research I have understood that for building my SDR there are some major groups of components


I'm starting off with hunting for the major components for each group according to:

- affordability
- availability
- routing 
- complexity 
- community and support.
![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MjkxLCJwdXIiOiJibG9iX2lkIn19--e49a4ad1dd903c4f8ba310b252e04e692d198a08/image.png)


TRANSCEIVER:
The Transceiver converts radio-frequency signals to and from digital I/Q samples by performing RF tuning, mixing, filtering, and ADC/DAC conversion between the antenna side and the digital processing system.

I've decided on the AD9364 as it is widely used and documented and has a fairly large Frequency Band  (70 MHz to 6.0 GHz) and Bandwidth (200 kHz to 56 MHz).

FPGA:
The FPGA is what does the Digital Signal Processing in order to make the data usable for software and the interface b/w the Transceiver and the CM4.

So what i need for the FPGA is a chip with a decent amount of LUTs (Look Up tables).  45k+ LUTs is enough for an SDR.

I've got some options like the  
- XC7A50T-2FTG256C (50K LUTs)
- XC7A100T-2FTG256C (100K LUTs)
- ECP5 LFE5U-45F (45K LUTs)

I've decided on XC7A50T-2FTG256C for my FPGA as is cheaper and has good documentation on the internet with this use case as opposed to the Lattice ECP5 and also I have some experience with Vivado.
 
POWER: There is quite a few power rails they
include 5V , 3.3V ,1.8V ,1.3V, 1.0V .
This is the IC list:

- 5V USB-C input
- 1.0V TPS62130
- 1.8V TPS62130 
- 3.3V TPS563201
- 1.3V TLV743P
Power Tree: 


Interfaces:
Onbaord the CM4, There are two major data transfer protocols the USB-2 and PCIe Gen-2 . USB-2 is very slow for throughput of the SDR (AD9363 at 61.44 MSPS, 2x 16-bit = ~245 MB/s)

Since the CM4 has a PCIe Gen - 2 with a throughput of around 350MB/s which is more than enough for the the throughput of the SDR. 


So this is my mind map of this project.

### Recording Links

- https://www.youtube.com/watch?v=TJHox4jQnp0

## Entry 2
- ID: 139
- Author: alfder
- Created At: 2026-03-17T19:52:55Z

### Content


There is a major change to the choice of  the FPGA to be used. Instead of using the XC7A50T-2FTG256C I will be using either the XC7A50T-2CSG325C or XC7A35T-2CSG325C( both same share the same pinouts but require different amouts and values of decoupling capacitors). I will explain this change in the PCIe section.
 ![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6Mjk2LCJwdXIiOiJibG9iX2lkIn19--58f9ae59a55b7b3ed169c740102f8153eb86de0a/image.png)


---
FPGA Power & Power Decoupling:
---
- ***FPGA Power***:
Now there are different voltage inputs into the fpga for different parts of the FPGA. Now the DS181 provides a good explaination on what these different pins do and the reequired voltages.So ill try to give a brief explaination of each power input. 
![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6Mjk3LCJwdXIiOiJibG9iX2lkIn19--d978acf47ba914596ccc8583c71e252dc3dd3c7f/image.png)

    - ***VCCO***:
VCCO is voltage that powers the I/O buffers in the FPGA and sets the signaling standard of the "bank". For example in the XC7A35T-2CSG325C, there is no High Performance bank that is required for LVDS that is used as a standard for the communication between the transceiver. So we can introduce the LVDS standard by supplying a bank VCCO with in this case 2.5V instead of 1.8V that is used for the CMOS standard. Ill explain what are the different standards later. (In the transceiver jorunal entry)
In the XC7A35T-2CSG325C there are 4 banks and their inputs are VCCO_0(config), VCCO_14, VCCO_15,VCCO_34 (I chose bank 34 for LVDS).
    - ***VCCBRAM***:
VCCBRAM provides 1V for powering the on chip Block RAM. 
    - ***VCCADC***:
It is the voltage(1.8V) used to power up the analog to digital converter. It powers the analog circuits in chip that measure temp voltage (XADC) and external analog inputs.
    - ***VCCINT***:
It provides 1V to the LUTs, Flip Flops etc. 
    - ***VCCAUX***:
It provides 1.8V to the Clock management blocks (PLL/MMCM), JTAG. 
    - ***MGTVCC & MGTVTT***:
MGTVCC provides 1V to gigabit transceiver analog cirucits present on the chip. MGTVTT provides the termination ref voltage to the CML termination network inside the chip so the high speed signals transmitted wont relfect back.

- ***Decoupling:***
Now this varies from FPGA to FPGA as their pin layouts and no. of LUTs change. AMD has provided a handy datasheet (UG483) in which they tell us recommended PCB design practices and Infomation on the amount of Decoupling Capacitors for each power input. For the XC7A35T-2CSG325C the capacitors and their amounts is shown the below table from the datasheet.

![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6Mjk5LCJwdXIiOiJibG9iX2lkIn19--9394bd42fb3541080e2ae9f18de4d142798475ea/image.png)


![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6Mjk4LCJwdXIiOiJibG9iX2lkIn19--4db6cec5b5088f0b075168df1382d4026633170d/image.png)
this is the schematics for decoupling. 


---
FPGA CONFIG & SPI FLASH
---
FPGA configuration was pretty straightforward. Datasheet UG470 provided info on wiring almost every pin and the wiring for the pins like DXP/N was solved using datasheets and forums.

![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MzAxLCJwdXIiOiJibG9iX2lkIn19--5f77afcb44a06dd2dafd4ae6651e1b0f07c1e3aa/image.png)

***Config Mode***: 
We select the configuration mode using MODE pins. They form a 3-bit bus. The following table shows different combinations that are used to select the mode:
![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MzAyLCJwdXIiOiJibG9iX2lkIn19--7aa17e5d87636756c73dbf01fa6c00fa14f39854/image.png)




- ***Master SPI***:
Master SPI mode allows the FPGA to read the bitstream generated using HDL to do various tasks from the SPI Flash. 

***SPI Flash***:
MT25QU128ABA8ESF-0SIT is the flash that used here. It has 16MB(128Mb) of Flash. The connections are pretty standard even if you use a different manufacturer.
SPI Flash stores the Bitstream file produced in Vivado (xilinx) so you dont have to flash the same bitstream every time you boot.

Connections were done with reference to the flash's datasheet and FreeSRP's and other reference designs.

![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MzAwLCJwdXIiOiJibG9iX2lkIn19--4933c3e199d9400c16c69574016def85007d2d39/image.png)

---
FPGA Clock
---
A clock is essential for the sequential logic inside the FPGA like Flip Flops. Flip Flops change their state every rising edge or beginning of a wave crest.  

PLLs(Phase-Locked Loop) also need a reference clock to make new stable clocks by locking one clock signal to another. PLLs help to dissipate jitters for high speed signals.  

Oscillator ive gone ahead with is the EPSON SG-8018CA 100.0000M-TJHSA0.  There is no special reason for the selection any 100MHz 1.8V oscillator will do.

![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MzA0LCJwdXIiOiJibG9iX2lkIn19--10b325b7f1dfba67f923aa30ccb5d7b1133a93c4/image.png)

---
PCIe
---
For PCIe implementation I went thru some reference designs and found a group of pins in anew bank called MGTAxxx pins. I couldn't find them in the FTG256 fpga because it seems they didn't bond that part to the I/O. I spent hours on find the reason. And it was right in front of my eyes btw. In the main 7 series FPGAs datasheet they mentioned something about GTP transceivers. Turns out these MGTAxxx pins were the I/O for them and they are 
used to transmit high speed signals like PCIe etc. 
So, I quickly found a suitable fpga with the pinout that includes GTP  which is the CSG325 with 4 GTP transceivers.

CM4 which has PCIe Gen2 with one lane. I have followed the UG482 datasheet and reference designs on the internet for the wiring. 

Speed is around 4Gbps (400MB/s) after after 8b/10b encoding.  
There is a Reference Clock incoming from the CM4 for the PLL inside GTP block.

The RX, TX and the REFCLK are diffrential pairs with an diffrential impedance of 85ohms for the TX AND RX and 100ohms for REFCLK.


 Oop i found some connections I missed.
nRST and nREQ. These were some important pins too. nRST intializes the PCIe and nREQ tells the CM4 to output the refclk. 


![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MzA1LCJwdXIiOiJibG9iX2lkIn19--80cdd28d3d4f8f7ada1d57200a13389484b7a5cf/image.png)

---
FPGA I/O
---
This is the place the fpga interfaces with other ICs and signals. VCCO_14,VCCO_15,VCCO_34 all power the banks here. 

***Bank 14 and Bank 15***:
Bank 14 and Bank 15 use the LVCMOS18 standard. Hence they handle the single ended signals. They act as an interface b/w the Gigabit Ethernet,  Some PCIe Signals, SPI flash etc. Later on i will be using some of them to drive Status LEDs and remaining ones will be probably used as GPIO. 

Your supposed to drive the Clocking I/O to pins with the name MRCC or SRCC they are special pins.

***Bank 34***:

This bank is powered with 2.5V and uses the LVDS_25 signalling standard. It has a different signalling standard because LVDS allows for double ended signals therefore maximizing the the throughput from the AD9364. This bank is connected to AD9364 LVDS differential pair signals and its SPI and other pins. 
I went thru tons and tons of datasheets and forums and reference designs(I couldn't find any that uses LVDS for ad9364). The datasheets and people on reddit mentioned LVDS implementation on this fpga required 2.5V to its VCCO banks(This is because my selection only has High Range banks out therefore the i/o buffers need a higher voltage to produce the LVDS signals).  But the thing is I asked claude to help me find references but it started talking about termination resistors and all that. I'm still not sure about the LVDS part but I did find a person with almost the same components and questions on LVDS implementation as me. The person who answered was a analog circuits employee so I think my doubts on the transceiver side are kinda cleared but my FPGA side still is doubtful.  


![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MzA2LCJwdXIiOiJibG9iX2lkIn19--7c17d3c461c9526de9a20ee16c0b381798ac68c7/image.png)
FPGA I/O

---

**Role of AI in this project:**
Not using AI in this day and age is just straight up inefficient. It helps you retrieve info very fast, helps you organize, basically just speed up R&D. It helped me with finding respective datasheets, reference designs and clearing my doubts on some concepts. I also used AI to help me keep check of essential parts of the design process by uploading different reference schematics for it's reference. Never trust AI to help you with connections or design and always ask for references to the information they output.
___

---







### Recording Links

- https://www.youtube.com/watch?v=OnGQM5hx2SY
- https://www.youtube.com/watch?v=5Uldx5--G7g
- https://www.youtube.com/watch?v=YmUaideF6rw
- https://www.youtube.com/watch?v=ljv5lHSSsYQ
- https://www.youtube.com/watch?v=UXiI6siYtjU
- https://www.youtube.com/watch?v=Kb2GCJdru1c
- https://www.youtube.com/watch?v=kMbWr43iKdQ

## Entry 3
- ID: 519
- Author: alfder
- Created At: 2026-03-27T04:30:58Z

### Content

---
TRANSCIEVER
---
Its been a slow week. I've procrastinated a lot and my school started this week. On top of that reference materials and datasheet like the ones provided by AMD for the FPGA were REAL scarce for the AD9364. The ones they provided were more vague and had a real steep learning curve. So I had to resort to help from AI for understanding what's going on and help with choosing parts. But as I've said before AI should be used cautiously especially here because there's less information to work on. 
I've mainly stuck to two reference designs the FMCOMMS4 and FreeSRP both using the AD9364. The FMCOMMS4 from Analog Devices(AD9364 OEM) uses the LVDS signalling standard so this design was my primary.

---
POWER AND POWER DECOUPLING:
---
I used the AD9364 reference manual pg. 111, FreeSRP and FMCOMMS4 for wiring and choosing the values and quantity of decoupling caps. The Power side was pretty straightforward with almost all the pinouts described in the datasheets but the amount and quantity of power decoupling was more vague so I used the FMCOMMS4 and mainly the FreeSRP for reference. 
![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MTE3MSwicHVyIjoiYmxvYl9pZCJ9fQ==--cde60417e53e1a0786c016a1d62e1a1bb59e68f5/image.png)

---
INTERFACE TO FPGA:
---
So this part had me running around in circles. I had to choose a signalling standard to interface with the FPGA. Now what is a signalling standard? Signalling standards in electronics define voltage levels, current loops, or differential pairs used to transmit data, control systems, and ensure compatibility between components. Now in the AD9364 you have two options CMOS(Complementary Metal Oxide Semiconductor?) and LVDS(Low Voltage Differential Signalling). The difference between them is that LVDS uses the differential mode of transmission and CMOS uses the single ended mode. Using differential signals offer wayyy lower EMI production as the pair of wires (N and P) cancel each other out. LVDS also offers faster data transfer as there's double the amount of wires for transmission. But it comes at cost of harder routing as you have to take care of impedance and the pair should have the same length. 
![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MTE5NiwicHVyIjoiYmxvYl9pZCJ9fQ==--accbc710aef95f8e993da762441d6f3a77ef6b27/image.png)
![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MTE5NywicHVyIjoiYmxvYl9pZCJ9fQ==--427bebf9131ab33ad61d510f0977e1024e2bc386/image.png)
As you can see you get max use of the ad9364 by using LVDS. Hence I went for it. Hopefully it wont come back and bite me while routing. 

Now the Artix-7 FPGAs need 2.5V as a VCCO input to a whole bank to implement LVDS. Due to incorrect info from AI I spent quite a bit of time on figuring this part. This why you never trust AI. It said 1.8V LVDS is possible but really it was only possible for other models. Finally after come help from a forum. I had confirmed this part of the transceiver. 
![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MTIwMywicHVyIjoiYmxvYl9pZCJ9fQ==--85377d44f55ee4cb50bb5ffc3cb20a872d45999f/image.png)

---
MISCELLANEOUS 
---
This part also was done mostly thru reference designs mostly the FMCOMMS4 and the 2 datasheets. 
Clock used here is 40MHz with a load capacitance of 10pF. Now the datasheet specifies a range b/w  19MHz and 50MHz but they've already tested with the 40MHz clock so, I've gone ahead with it. 
I still have confirm that the CTRL I/O can be used with a 1.8V bank because I've run out of pins on the BANK 34. Rn its js a global bus. 
According the forum mentioned before SPI pins and other interface pins should also be connected to the 2.5V Bank. 

![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MTE5OCwicHVyIjoiYmxvYl9pZCJ9fQ==--e124ecfee5114702b85e08fd4a464d0d7e67a295/image.png)
---
TX AND RX
---
This is the infamous Black Magic section of the board. I am still yet to fully understand what's going on. Theres a lot of complex concepts and maths involved in the mechanics of this part. But I've been going thru some materials to understand whats going on and how to implement it. Since its my first time designing anything with RF (Ik its a stupid thing to do) I've decided to be "heavily inspired" by the FMCOMMS4 design and implement an identical design on my board except the 2.4GHz RX AND TX to keep complexity and costs low. Hence I'm using a wideband balun (RF Transformer) the TCM1-63AX+. It has a very low insertion loss throughout the band and
is readily available and relatively cheaper. 

Now what is a balun? As the schematic shows the AD9364 RX AND TX ports are differential(balanced) so the balun (BALanced and UNbalanced) basically convert the differential signals to unbalanced signals toward or from the antenna. But what is Insertion Loss. Insertion loss is the reduction in signal power caused by inserting a component, here a balun into a transmission line. It is measured in decibels (dB). At its peak the TCM1-63AX+ has a insertion loss of 1.8dB @ 6GHz which is really good for a wideband RF Transformer. 

![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MTIwMiwicHVyIjoiYmxvYl9pZCJ9fQ==--bf826e256946b22ace1aa763f9439b801360e9c9/image.png)
_____________________________________________________________
This design is not final and I may make changes to it if I find something stupid I did. Also ill submit my design on the ANALOG DEVICES ENGINEER ZONE FORUM to get another set of eyes on it. 

I'm dreading the day I have to route this 😭🙏.



### Recording Links

- https://www.youtube.com/watch?v=NvBK0wFQPmI
- https://www.youtube.com/watch?v=Hv3sPzH87ws
- https://www.youtube.com/watch?v=9K3Qde5C_ho
- https://www.youtube.com/watch?v=zVtxisBByR8
- https://www.youtube.com/watch?v=yYPSr4PqSw8
- https://www.youtube.com/watch?v=Om-Wifa1wxA
- https://www.youtube.com/watch?v=vnmhE4KmVkg

## Entry 4
- ID: 973
- Author: alfder
- Created At: 2026-04-02T21:37:20Z

### Content

So I have specified before that I will use a 1G Ethernet port for standalone interface. But the thing is its way harder than USB to implement in the FPGA. This session was basically tons of research into USB2 vs Ethernet vs USB3.  

I wasn't pretty sure about using USB3 or ethernet or USB2. I just needed something that is simple and easy to route. Initially I wanted the board to be capable of standalone operation but since USB3 AND ETHERNET has more wiring and routing which just increases more possibilities of errors. I decided to keep this interface just to test the connection between the AD9364 and the FPGA before heading deep into writing firmware for the PCIe interface.

 
![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MjE1NiwicHVyIjoiYmxvYl9pZCJ9fQ==--72c4914f0c7c7aada5c4bbe683ddfc7afa347394/image.png)
USB 2 Ref Schematics.
---
![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MjE1NywicHVyIjoiYmxvYl9pZCJ9fQ==--54d29841bc20275d88122b23c592d24db7f8a490/image.png)
USB3 ref schematics
---

### Recording Links

- https://www.youtube.com/watch?v=dZanAVErYew
- https://www.youtube.com/watch?v=IHejjJGaHLU

## Entry 5
- ID: 1005
- Author: alfder
- Created At: 2026-04-03T08:30:38Z

### Content

So in these sessions I left the Direct FPGA interface for a bit. I decided to move onto the CM4 interface to the FPGA and peripherals. 

It was soo hard to find a good kicad CM4 symbol. I spent quite some time looking for it.  

CM4 datasheet provided by RPI was enough for drawing the schematics. I also used the Pincushion board and MirkoPC as my reference drawings. Everything was smooth sailing till I reached the USB interface for the CM4. I didn't want the CM4 to act as a slave. I didn't need a switch. I didn't want to draw and route a USB hub So I decided to only have one USB-A port. When I need to add peripherals like a keyboard and a mouse ill just use a hub or something. 
![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MjE2MCwicHVyIjoiYmxvYl9pZCJ9fQ==--902858c0ce80ed8b91bee6034ffd980ff8c84922/image.png)


### Recording Links

- https://www.youtube.com/watch?v=ONy4QQIOlIA
- https://www.youtube.com/watch?v=YVME6g7f7fs

## Entry 6
- ID: 1007
- Author: alfder
- Created At: 2026-04-03T08:36:07Z

### Content

Okay so for the Direct FPGA interface after a lot of back and forth I have decided to go ahead with USB2 with the FT2232HL. For USB 3 I knew I wasn’t gonna use the FX3 since it was too complex. I found another easier USB3 controller (WCH CH347) but it was Chinese and without any good datasheets and reference designs it would be a gamble using it. Ethernet was too hard for me to implement so I gave up on sticking to it. USB 2 seemed the best option at the cost of incomplete utilization of the speed that the transceiver offers. It really didn’t matter anyway because it was connected to a computer via PCIe.  

The FT2232HL offers 480Mb/s when it is in SYNC fifo mode. So I quickly found the datasheets. There were two of them. The main datasheet had the power and EEPROM wirings and the second datasheet provided a pinout map for a SYNC FIFO. 

Clocking crystals are notoriously hard to find. Its not that they are scarce but its hard to find ones in stock in LCSC.

 ![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MjIwNywicHVyIjoiYmxvYl9pZCJ9fQ==--e007bdb69e9ba7f795d55fa5b7aa96f7667fddb0/image.png)

----

Now the FT2232HL uses 3.3V for signalling and the available banks were both 1.8V so I decided to change bank 15 to 3.3V LVCMOS. That’s when it struck me that even the CM4 PCIe RST and REQ might use 3.3 v signalling. So I doubled checked with the datasheet. I had nothing so I checked the PinCushion schematics and sure was I correct. So changed the BANK VCCO to 3.3V. Crisis averted. 
![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MjIwOSwicHVyIjoiYmxvYl9pZCJ9fQ==--4646121b36498afb22311d11416422739af20e20/image.png)
![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MjIxMCwicHVyIjoiYmxvYl9pZCJ9fQ==--a6ade8d57e236f4d67c9058ce6e8f6cd9a5b7eea/image.png) 

---

I also started adding notes to the places I still have doubts about. 

![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MjIxMSwicHVyIjoiYmxvYl9pZCJ9fQ==--696560b3f30a8d96ef682edad6742ce3c29d72e8/image.png)
![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MjIxMiwicHVyIjoiYmxvYl9pZCJ9fQ==--644ee6568710caa4b75ace455724aac9c2d29ae2/image.png)
![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MjIxMywicHVyIjoiYmxvYl9pZCJ9fQ==--651194eb862a8e7b46c995fba20de94e86800a68/image.png)
---

I did not know we could submit journaling time 💔 Imma start recording journaling from now on.




### Recording Links

- https://www.youtube.com/watch?v=m53aE6QPPwM
- https://www.youtube.com/watch?v=B3OFvt6Nt-0
- https://www.youtube.com/watch?v=LDokv9RmtOM
- https://www.youtube.com/watch?v=06v2nr9xiR0
- https://www.youtube.com/watch?v=KyGLp88eso8

## Entry 7
- ID: 2601
- Author: alfder
- Created At: 2026-04-17T19:12:47Z

### Content

Ok so this week has some massive changes to the project. Initially I wanted to create an SDR that is much like the HackRF Portapack but more powerful and can run Linux. That was my intended goal. So when I started researching into this project back in January, I initially wanted to use the Zynq7020. This chip is a combination of an ARM Cortex A9 and an Artix-7 FPGA with 85K LUTs. Now after weeks of research I decided to move away from this chip because I couldn't find any sources or projects or Linux distros that could run a GUI. That meant I had to make my own Linux distro. I wasn't too confident in doing this. I didn’t even know Linux properly, how was I gonna create a whole new distro? So I decided to split the work into a CM4 and an Artix-7.
Now here's the twist. While I was researching into the firmware development of the HAT, I stumbled upon Kuiper Linux by Analog Devices. It's based off Raspberry Pi OS and has kinda native support for its product. "Kinda" because it's actually support for the dev boards, but I could work with that. Otherwise I had to make my own drivers and write custom Verilog for the HAT board. On top of that it has its own HDL and has support for Zynq7020 (Zedboard). So since I wasn't that confident in my programming skills I decided to basically redesign the FPGA part of the board.
FPGA:
So quickly I placed all the components and started with the design. Since I already had worked on the Artix-7, I didn’t need to research every pin again. I knew what they were and what I should do. I copy-pasted the decoupling and the config and just added or changed the values of the components according to the UG585 and UG933.
•	Clock: Now I need two separate clocks, one for the PS (Processing System) (33.33 MHz) and PL (Programmable Logic) (100 MHz). Wiring is standard crystal wiring and connected to the FPGA using UG585. 
•	QSPI flash: I don’t think it’s needed since I’m booting from the SD card anyway, but I added it just in case. This time all the data lines are in use. It is wired according to UG585. 
•	Configuration: There are some changes. The CFGBVS pin is pulled up to 3.3V now since the VCCO_0 bank is now 3.3V. Due to this change the VREF on the JTAG header and VCCO_0 decoupling should also be changed to 3.3V. RSVDVCC should be tied to VCCO_0 according to UG585. 
•	Boot Config: I followed the UG585, Zedboard and ADRV9364 schematics for this. Its simple, just choosing boot device. I just got confused because the FLASH and the Switches share some pins but it doesn't matter cus they only gonna be used initially.
•	I/O banks: 35 and 34 use 2.5V LVDS and banks 33 and 13 use 3.3V (I might change one of them to 1.8V because I plan on making an accessory for the board). The AD9364 I/O is wired according to the FMCOMMS4 and Zedboard connections so setup will be easier.
![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6NTQzOSwicHVyIjoiYmxvYl9pZCJ9fQ==--348f58f2a61ae3b6968a5c356d7e83a8db936d8f/image.png)
 
•	RAM: I’m using 128MB ×2 DDR3 chips for RAM. Same configuration as the Zedboard (might upgrade to 1GB). Wiring is straightforward. Signal lines need 40 ohm termination.

![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6NTQ0MSwicHVyIjoiYmxvYl9pZCJ9fQ==--0bc870932028280d59f853fc6333d06fda4af960/image.png)


### Recording Links

- https://www.youtube.com/watch?v=IkE0x3leGws
- https://www.youtube.com/watch?v=nfOYPGpUw8M
- https://www.youtube.com/watch?v=_9JnU3TCBzA
- https://www.youtube.com/watch?v=8SminApInEQ
- https://www.youtube.com/watch?v=GTfsHB5MKPQ
- https://www.youtube.com/watch?v=lzsiiVnWBGs

## Entry 8
- ID: 3105
- Author: alfder
- Created At: 2026-04-20T20:44:08Z

### Content

Interfaces:
Display:
For display I decided to follow the zedboard’s HDMI design because its natively supported by Kuiper Linux so ill have an easy time seting up the display. ADV7511 is an HDMI transmitter from Analog Devices.
Now the thing is I eventually wanted to make my board handheld like the Portapack but I’d need a HDMI to DSI or RGB convertor for it to work on a panel screen. I initially decided to follow the ADAFRUIT’s TFP401 design for this but then i changed my mind and decided to make a separate HAT board with the TFP and maybe a keyboard after the main board and  firmware is over. The design was getting to large and I was scared that I’d mess up something cus its so big. 
USB-OTG:
USB On The Go interfaces the PS with peripherals like a keyboard or mouse. I’m to lazy to wire a hub on the board so I’ll probably get an off the shelf hub. The design was done according to the Zedboard, ADRV9364-Z7020 and the UG585 datasheet.
Ethernet:
So its back again. I needed the ethernet as a back up for the display and OTG. Ill probably use this for setup and testing. The design was done according to the Zedboard and the UG585 datasheet.
SD card: 
SD card is the primary storage and boot up option for the board. It stores the boot up files, FPGA bitstream files and Kuiper linux. So it is really important I get this part correct. Since the SD card works on 3.3v LOGIC AND THE MIO1 bank works on the 1.8V logic (cus majority of the other interfaces work on 1.8v) we need the level shifter. The design was done according to the Zedboard and the UG585 datasheet.

Power: 
This is also a really crucial part of the board.  
There are mainly 8 power rails on the board.
1.8V  
3.3V  3,3VTX
2.5V
1.0V
1.3V,1V3TX
1.5V
0.75V
5V


0.75V, 1.0V, 1.5V, 1.8V, 2.5v, 3.3V:
These rails are mainly used by the Zynq and interfaces.
According to the DS187 DATASHEET( PS Power‐On/Off Power Supply Sequencing PG.8) requires that the powering sequence be  VCCPINT(1.0V), then VCCPAUX and VCCPLL (1.8V )together, then the PS VCCO supplies (VCCO_MIO0, VCCO_MIO1, and VCCO_DDR)(3.3V,1.5V, 0.75V).
(PL follows the same scheme)

This is sequencing is done by making use of the EN(ENABLE) and PG(POWER GOOD) pins on the POWER ICs

Choosing the Power ICs:
I’ve chosen the Power ICs according to Availability, Cost, Routing Difficulty, Support, Current and Power Switching Frequency (EMI reduction)(1.25MHz).
1.0V, 1.8V:
I needed a buck that can provide up to 3A of current as these pins take most of the heavy load by the board. In FreeSRP’s design he uses TPS62130A to provide the required current. You set the voltage with a Resistor divider circuit at FB pin. The selection of the resistor value is done by this equation. 
![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6NjQyOSwicHVyIjoiYmxvYl9pZCJ9fQ==--87f994e27d4671f212e78e359cf4b556ec61190e/image.png)

Inductor selection was done with reference to the FreeSRP and the  TPS62130A datasheet. 

![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6NjQzMCwicHVyIjoiYmxvYl9pZCJ9fQ==--3f66dc05dc4e1531a3d69c11cfd89f50a63f19eb/image.png)

3.3V, 2.5V, 1.5V:
I wanted to deal with the least amount of wiring so I was looking for a buck with 3 outputs. I eventually found the TPS65251-3RHAR. It provides 3A-2A-2A current output. Since the 3.3 rail is used more I decieded to give it the 3A output. The voltage is selected using the FB resistor divider circuit using the same equation as before. 
Inductor was chosen using the following equations.
 ![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6NjQzMiwicHVyIjoiYmxvYl9pZCJ9fQ==--bb8958bf20a8601777eca640d786eb004a78ffbc/image.png)

0.75V
This voltage is the termination voltage for the DDR. It is supplied by the MAX1510ETB+. 
1.3V,1.3V_TX
It is the primary voltage rail of the AD9364. I have used the ADP1754ACPZ-1.3-R7 as it is recommended by Analog Devices for its stability. 
5V:
It is supplied by external power source thru a power connector(TBD)
GPIO:
I am using the DF40C-100DS-0.4V_51 found on the CM4 as my gpio header as it has a small form factor.  I want to eventually make a HAT with a screen and other peripherals.
I am also routing the HDMI and OTG signals to it. 
Miscellaneous:
PS_POR_B:  A crucial reset pin for stable operation as it waits for all power system to be up and running before starting the PS.  
PS_SRST_B: Reset button
PS_VREF: 0.9V rail refer below 
![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6NjQzMywicHVyIjoiYmxvYl9pZCJ9fQ==--be5cdedc011c2914479656782af756728f34c9e4/image.png)

Boot up headers to buttons
QSPI Flash from 3.3V to 1.8V 
Power Amp for TX:
PGA-102 is a power amp that works on 3.3v hence a separate power ic for it for clean power. TX output from the AD9364 is kinda weak.  


### Recording Links

- https://www.youtube.com/watch?v=ZoyeQua38GY
- https://www.youtube.com/watch?v=LApXd7OLbGI
- https://www.youtube.com/watch?v=Jo44Lv3l1FI
- https://www.youtube.com/watch?v=aQgmeYO2SZY
- https://www.youtube.com/watch?v=x6juVCaHEsU
- https://www.youtube.com/watch?v=xqSQYhX0v9s
- https://www.youtube.com/watch?v=4CxgTthxZf8
- https://www.youtube.com/watch?v=HKIHF6WvBSk
- https://www.youtube.com/watch?v=mK2b_OkVO_A
- https://www.youtube.com/watch?v=o3R0KbsihcE
- https://www.youtube.com/watch?v=Bdep1bviY-k
- https://www.youtube.com/watch?v=o3By00YozLs
- https://www.youtube.com/watch?v=O8eKWQ806ms
- https://www.youtube.com/watch?v=X0KCtDnTdiU

## Entry 9
- ID: 4064
- Author: alfder
- Created At: 2026-04-26T15:49:47Z

### Content

Im finally done with component selection, drawing the schematics and assigning the footprints. 
GPIO:
I decided to place two DF40C-100DS-0.4V_51 cus it would make the connection with the hat more stable. 
MISCELLANEOUS;
I made some changes and essential missing connections (PUDC_B and SD card DETECT AND WP)
I added the AD7291BCPZ also in the FMCOMMS4 and ADRV9364. It provides power statistics of the whole board.
![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6ODI5MywicHVyIjoiYmxvYl9pZCJ9fQ==--84f249b9948a411d88199e777331968b6f94ae10/image.png)
Verification:
Verification is an important thing to do especially when the board is this complex and big.  
I found some massive errors and missing connections:
•	PS boot up config: Idk what happened the variable pins were connected wrong. I fixed them according to UG585 again.
•	Some resistor values in power section (COMP pins for the TPS65251-3RHAR)
•	CEC clock for HDMI was missing and ESD protection for CEC. 
•	3V3 net were mislabeled as 3.3V in some places
•	ESD protection was missing for USB-OTG
•	Some OTG were left unconnected. 
I hope to do another Verification next week. 
Assigning Footprints
Assignment of the footprint were done according to the UG933 datasheet and BOMs of PlutoSDR, FMCOMMS4, Zedboard, FreeSRP.  



### Recording Links

- https://www.youtube.com/watch?v=bY7aJ7XnGC0
- https://www.youtube.com/watch?v=_Kiju906hfU
- https://www.youtube.com/watch?v=bm7DiiWbsPk
- https://www.youtube.com/watch?v=Ccw_OYd3NGk
- https://www.youtube.com/watch?v=g1MPIJSFosk
- https://www.youtube.com/watch?v=nf1j7d8-XA4

## Entry 10
- ID: 10349
- Author: alfder
- Created At: 2026-05-30T08:43:30Z

### Content

So after a long break due to exams and a holiday im finally back.
After verification I started with general placement, power planes and via placement
I also entered the impedance values for the traces on each signal layer and delay units. 
I’ve decided to make it a 8 layer board atleast due to the density of signal and power traces present.
Via placement is important for routing and component placement. I followed the dog-bone method instead of the via in pad because of the space it gives for routing and placement. 


![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MjM0NDksInB1ciI6ImJsb2JfaWQifX0=--6efa55c168506153178be85b19126a1e80c30a9d/image.png)


### Recording Links

- https://www.youtube.com/watch?v=10gsAFUqDF4
- https://www.youtube.com/watch?v=UkJlRLl4Tro
- https://www.youtube.com/watch?v=Uvpqn_mjOvE
- https://www.youtube.com/watch?v=7jGfMwrIXD8
- https://www.youtube.com/watch?v=OwRprZUsEHw
- https://www.youtube.com/watch?v=5xcBoU6tMyc
- https://www.youtube.com/watch?v=UB98xOdd0dk
- https://www.youtube.com/watch?v=fQEguXu7LuQ
- https://www.youtube.com/watch?v=rWCEdCNkBhk
- https://www.youtube.com/watch?v=pk2SxVGYq2k
- https://www.youtube.com/watch?v=KeT1FOpSYd0
- https://www.youtube.com/watch?v=J1YXMxbBGEc
- https://www.youtube.com/watch?v=QMl1tkEnfWI

## Entry 11
- ID: 10354
- Author: alfder
- Created At: 2026-05-30T10:03:56Z

### Content

I forgot to submit these videos. 
They show the final general component placement.
Wish me luck for routing this!
![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MjM0NTEsInB1ciI6ImJsb2JfaWQifX0=--45c25e7bf5ad1a2140b8379b91061efcd8dcef8c/image.png)


### Recording Links

- https://www.youtube.com/watch?v=-bWUE7-RFLM
- https://www.youtube.com/watch?v=URoZFXsCmVg
- https://www.youtube.com/watch?v=IuD2v4Mgs3g

## Entry 12
- ID: 16079
- Author: alfder
- Created At: 2026-06-23T12:15:34Z

### Content

So, I’ve decided to make PeriR an MVP and returned to my original plan on making CM4 SDR HAT. This is because I wanted to qualify for the event and DDR routing seems out my level, especially routing two of em. 
So, I got started right away with power schematics cus it was the only thing I didn’t complete on the HAT before Zynq. I used the TPS62130A separately for each rail instead of the 3 in 1 buck cus it would make drawing planes easier and less constraint. 
Then I got started with the general placement of the major components, then the bypass and decoupling and then resistors. It went fast cus I practiced with the previous design. 
Power Planes were also a breeze cus of the practice.
I was intimidated by the ratsnest in the first design. Bro, what was that!? This one was tamer but still complex. 
I started routing the TPS62130A chips. I just followed the example given in the datasheet and my wiring diagram.
Next, was the USB 2.0 interface the FT2232HL.
After that I started with the connections b/w the AD9364 and FPGA. Here I made a small mistake by not doing the dogbones first but according to my research it’ll be alright. 
(Before I submit to a fab, I’ll probably reroute it again.)
 FPGA and AD9364 Power delivery was done through Power Planes and Thicker Traces wherever possible. 
CM4 and its interface’s routing was done according to the CM4 datasheet. PCIe needs proper impedance control and length matching but it’s laxer cus it’s only PCIe 2.0. 
RF routing was done according to examples from the FreeSRP and FMCOMMS4. It is a coplanar arc with no solder mask on top. All the layers below the RF section are ground planes. 
I decided to keep the ref values for only the main components and some logos on the silkscreen.


![image.png](/user-attachments/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6Mzg1MjIsInB1ciI6ImJsb2JfaWQifX0=--ea1bd6a6bea02426280681cda8dbcad684f6a039/image.png)


### Recording Links

- https://www.youtube.com/watch?v=QOjy-xeKWOM
- https://www.youtube.com/watch?v=KX0_TyagnQ4
- https://www.youtube.com/watch?v=sq312k_K0cA
- https://www.youtube.com/watch?v=9CMUil3-TLw
- https://www.youtube.com/watch?v=E2RAGUNgbH8
- https://www.youtube.com/watch?v=AwUKXpqDrTw
- https://www.youtube.com/watch?v=tMLclXklSSs
- https://www.youtube.com/watch?v=K7RCws3XndE
- https://www.youtube.com/watch?v=KVBkVN54vN8
- https://www.youtube.com/watch?v=ln8Zk-9Xfxo
- https://www.youtube.com/watch?v=xQvRE2JUEbM
- https://www.youtube.com/watch?v=y9_g-WkQgWU
- https://www.youtube.com/watch?v=_hF0sZb-mIM
- https://www.youtube.com/watch?v=WS8lGpnOEnA
- https://www.youtube.com/watch?v=04tepWEY1TU
- https://www.youtube.com/watch?v=vx6_bkyNiBs
- https://www.youtube.com/watch?v=BC715uGVJ1g
- https://www.youtube.com/watch?v=Z-N89I6z3xo
- https://www.youtube.com/watch?v=fudO6M7lvkU
- https://www.youtube.com/watch?v=qBprEguQdMI
- https://www.youtube.com/watch?v=sriJZpKvgRI
- https://www.youtube.com/watch?v=pKTFVFPYRbY
- https://www.youtube.com/watch?v=ryHLZIhWXMQ
