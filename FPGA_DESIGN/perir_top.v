//-----------------------------------------------------------------------------
// PeriR — Top-Level Wrapper
// Target : XC7A50T-CSG325 (Artix-7)
// Board  : PeriR SDR (Hack Club Fallout)
// Author : Alfred
//
// Block overview:
//   CM4 <--PCIe x1 Gen2--> [7-Series PCIe EP] <--AXI--> [axi_dmac] <-->
//   [axi_ad9361] <--LVDS 1R1T--> AD9364
//
//   AD9364 SPI config driven from CM4 via PCIe BAR0 register window
//   into an AXI SPI Engine block.
//
// Port naming follows ADI axi_ad9361 conventions so the XDC can be written
// directly from this file without renaming.
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module perir_top (

  //--------------------------------------------------------------------------
  // AD9364 LVDS Data Interface (1R1T mode, 6 data pairs each direction)
  //--------------------------------------------------------------------------

  // RX — AD9364 drives these
  input  wire        rx_clk_in_p,       // DATA_CLK_P  — LVDS source-sync clock from AD9364
  input  wire        rx_clk_in_n,       // DATA_CLK_N
  input  wire        rx_frame_in_p,     // RX_FRAME_P  — marks I/Q boundary
  input  wire        rx_frame_in_n,     // RX_FRAME_N
  input  wire [5:0]  rx_data_in_p,      // RX_D5..D0_P — 6 LVDS data pairs, DDR
  input  wire [5:0]  rx_data_in_n,      // RX_D5..D0_N

  // TX — FPGA drives these
  output wire        tx_clk_out_p,      // FB_CLK_P    — feedback clock to AD9364
  output wire        tx_clk_out_n,      // FB_CLK_N
  output wire        tx_frame_out_p,    // TX_FRAME_P
  output wire        tx_frame_out_n,    // TX_FRAME_N
  output wire [5:0]  tx_data_out_p,     // TX_D5..D0_P
  output wire [5:0]  tx_data_out_n,     // TX_D5..D0_N

  //--------------------------------------------------------------------------
  // AD9364 SPI (config, driven by SPI Engine from AXI register space)
  //--------------------------------------------------------------------------
  output wire        spi_sck,           // SPI_CLK
  output wire        spi_mosi,          // SPI_DI  (FPGA→AD9364)
  input  wire        spi_miso,          // SPI_DO  (AD9364→FPGA)
  output wire        spi_csn,           // SPI_ENB (active low)

  //--------------------------------------------------------------------------
  // AD9364 Control / Status GPIOs
  //--------------------------------------------------------------------------
  output wire        ad9364_enable,     // ENABLE  — RX/TX enable
  output wire        ad9364_txnrx,      // TXNRX   — TX=1 / RX=0 (1R1T FDD)
  input  wire        ad9364_ctrl_in,    // CTRL_IN — unused in 1R1T, tie low
  output wire        ad9364_rst_n,      // RESETB  — active low reset to AD9364

  //--------------------------------------------------------------------------
  // PCIe x1 — CM4 Root Complex <-> Artix-7 Endpoint
  // GTP transceiver differential pairs (AC-coupled on board)
  //--------------------------------------------------------------------------
  input  wire        pcie_refclk_p,     // 100 MHz REFCLK from CM4 (or onboard osc)
  input  wire        pcie_refclk_n,
  input  wire        pcie_rst_n,        // PERST# from CM4, active low

  input  wire        pcie_rx_p,         // CM4 TX -> FPGA RX (x1)
  input  wire        pcie_rx_n,
  output wire        pcie_tx_p,         // FPGA TX -> CM4 RX (x1)
  output wire        pcie_tx_n,

  //--------------------------------------------------------------------------
  // System / Misc
  //--------------------------------------------------------------------------
  input  wire        sys_clk_p,         // Optional: onboard 200 MHz LVDS osc
  input  wire        sys_clk_n,         //   (can remove if clocking from PCIe REFCLK)

  output wire [3:0]  led               // Debug LEDs — PCIe link, AD9364 lock, etc.
);

  //--------------------------------------------------------------------------
  // Internal clocks & resets
  //--------------------------------------------------------------------------
  wire        pcie_refclk;              // IBUFDS_GTE2 output (feeds PCIe IP)
  wire        sys_clk;                  // IBUFGDS output (200 MHz system clock)
  wire        sys_rst_n;                // Global synchronous reset (from PCIe IP)

  wire        axi_clk;                  // 125 MHz AXI bus clock (from PCIe IP)
  wire        axi_rst_n;                // AXI reset, active low

  //--------------------------------------------------------------------------
  // PCIe REFCLK buffer — mandatory IBUFDS_GTE2 for GTP reference clock
  //--------------------------------------------------------------------------
  IBUFDS_GTE2 #(
    .CLKCM_CFG    ("TRUE"),
    .CLKRCV_TRST  ("TRUE"),
    .CLKSWING_CFG (2'b11)
  ) u_pcie_refclk_buf (
    .O     (pcie_refclk),
    .ODIV2 (),                          // unused
    .I     (pcie_refclk_p),
    .IB    (pcie_refclk_n),
    .CEB   (1'b0)
  );

  //--------------------------------------------------------------------------
  // System clock buffer (200 MHz LVDS oscillator, if populated)
  //--------------------------------------------------------------------------
  IBUFGDS #(
    .DIFF_TERM  ("TRUE"),
    .IBUF_LOW_PWR ("FALSE")
  ) u_sys_clk_buf (
    .O  (sys_clk),
    .I  (sys_clk_p),
    .IB (sys_clk_n)
  );

  //--------------------------------------------------------------------------
  // AXI interconnect wires
  // All IPs hang off a single AXI4/AXI4-Lite interconnect clocked at axi_clk.
  // Actual interconnect is instantiated in the Vivado block design (bd.tcl).
  // Wires declared here for clarity — they will map to bd ports.
  //--------------------------------------------------------------------------

  // AXI4-Stream: axi_ad9361 RX -> axi_dmac (RX path, ADC data)
  wire [63:0]  adc_data;               // I[31:16] Q[15:0] per channel (1R1T = 2ch packed)
  wire         adc_valid;
  wire         adc_enable;
  wire         adc_dovf;               // overflow flag from DMA -> axi_ad9361

  // AXI4-Stream: axi_dmac -> axi_ad9361 TX (DAC data)
  wire [63:0]  dac_data;
  wire         dac_valid;
  wire         dac_enable;
  wire         dac_dunf;               // underflow flag

  // AXI4-Lite: PCIe BAR0 -> axi_ad9361 register map
  wire [31:0]  axil_ad9361_awaddr,  axil_ad9361_araddr,  axil_ad9361_wdata,  axil_ad9361_rdata;
  wire [3:0]   axil_ad9361_wstrb;
  wire         axil_ad9361_awvalid, axil_ad9361_awready;
  wire         axil_ad9361_wvalid,  axil_ad9361_wready;
  wire         axil_ad9361_bvalid,  axil_ad9361_bready;
  wire [1:0]   axil_ad9361_bresp,   axil_ad9361_rresp;
  wire         axil_ad9361_arvalid, axil_ad9361_arready;
  wire         axil_ad9361_rvalid,  axil_ad9361_rready;

  // AXI4-Lite: PCIe BAR0 -> axi_dmac register map (RX DMA)
  wire [31:0]  axil_dmac_rx_awaddr, axil_dmac_rx_araddr, axil_dmac_rx_wdata, axil_dmac_rx_rdata;
  wire [3:0]   axil_dmac_rx_wstrb;
  wire         axil_dmac_rx_awvalid, axil_dmac_rx_awready;
  wire         axil_dmac_rx_wvalid,  axil_dmac_rx_wready;
  wire         axil_dmac_rx_bvalid,  axil_dmac_rx_bready;
  wire [1:0]   axil_dmac_rx_bresp,   axil_dmac_rx_rresp;
  wire         axil_dmac_rx_arvalid, axil_dmac_rx_arready;
  wire         axil_dmac_rx_rvalid,  axil_dmac_rx_rready;

  //--------------------------------------------------------------------------
  // axi_ad9361 — AD9364 LVDS interface + IQ framer
  // Source: analogdevicesinc/hdl library/axi_ad9361
  // Parameters set for: 7-series, LVDS, 1R1T, no ext. DC filter
  //--------------------------------------------------------------------------
  axi_ad9361 #(
    .ID             (0),
    .DEVICE_TYPE    (0),                // 0 = 7-Series
    .DAC_IODELAY_ENABLE (0),
    .ADC_INIT_DELAY (21),               // initial IDELAY tap — tuned by ad9361_dig_tune()
    .DDS_DISABLE    (0),
    .TDD_DISABLE    (1),                // 1R1T FDD only for PeriR
    .MODE_1R1T      (1),                // AD9364 is always 1R1T
    .CMOS_OR_LVDS_N (0)                 // 0 = LVDS
  ) u_axi_ad9361 (
    // LVDS physical pins
    .rx_clk_in_p    (rx_clk_in_p),
    .rx_clk_in_n    (rx_clk_in_n),
    .rx_frame_in_p  (rx_frame_in_p),
    .rx_frame_in_n  (rx_frame_in_n),
    .rx_data_in_p   (rx_data_in_p),
    .rx_data_in_n   (rx_data_in_n),
    .tx_clk_out_p   (tx_clk_out_p),
    .tx_clk_out_n   (tx_clk_out_n),
    .tx_frame_out_p (tx_frame_out_p),
    .tx_frame_out_n (tx_frame_out_n),
    .tx_data_out_p  (tx_data_out_p),
    .tx_data_out_n  (tx_data_out_n),

    // ADC data out (to DMA)
    .adc_data_i0    (adc_data[15:0]),
    .adc_data_q0    (adc_data[31:16]),
    .adc_data_i1    (adc_data[47:32]), // unused in 1R1T — tie off in DMA config
    .adc_data_q1    (adc_data[63:48]),
    .adc_enable_i0  (adc_enable),
    .adc_valid_i0   (adc_valid),
    .adc_dovf       (adc_dovf),

    // DAC data in (from DMA)
    .dac_data_i0    (dac_data[15:0]),
    .dac_data_q0    (dac_data[31:16]),
    .dac_enable_i0  (dac_enable),
    .dac_valid_i0   (dac_valid),
    .dac_dunf       (dac_dunf),

    // Control
    .enable         (ad9364_enable),
    .txnrx          (ad9364_txnrx),
    .up_enable      (1'b1),
    .up_txnrx       (1'b0),            // RX mode default; CM4 overrides via register

    // AXI-Lite control port (from PCIe BAR0)
    .s_axi_aclk     (axi_clk),
    .s_axi_aresetn  (axi_rst_n),
    .s_axi_awvalid  (axil_ad9361_awvalid),
    .s_axi_awaddr   (axil_ad9361_awaddr),
    .s_axi_awready  (axil_ad9361_awready),
    .s_axi_wvalid   (axil_ad9361_wvalid),
    .s_axi_wdata    (axil_ad9361_wdata),
    .s_axi_wstrb    (axil_ad9361_wstrb),
    .s_axi_wready   (axil_ad9361_wready),
    .s_axi_bvalid   (axil_ad9361_bvalid),
    .s_axi_bresp    (axil_ad9361_bresp),
    .s_axi_bready   (axil_ad9361_bready),
    .s_axi_arvalid  (axil_ad9361_arvalid),
    .s_axi_araddr   (axil_ad9361_araddr),
    .s_axi_arready  (axil_ad9361_arready),
    .s_axi_rvalid   (axil_ad9361_rvalid),
    .s_axi_rdata    (axil_ad9361_rdata),
    .s_axi_rresp    (axil_ad9361_rresp),
    .s_axi_rready   (axil_ad9361_rready),

    // Device clock (l_clk) — driven internally by axi_ad9361 from rx_clk_in
    .l_clk          ()                 // internal — not connected at top level
  );

  //--------------------------------------------------------------------------
  // axi_dmac (RX path) — streams ADC data to PCIe host memory
  // DMA_TYPE_DEST = 0 (AXI MM), DMA_TYPE_SRC = 1 (AXI Stream)
  // axi_dmac source: analogdevicesinc/hdl library/axi_dmac
  //--------------------------------------------------------------------------
  axi_dmac #(
    .ID                 (0),
    .DMA_DATA_WIDTH_SRC (64),           // matches axi_ad9361 output width
    .DMA_DATA_WIDTH_DEST(64),
    .DMA_TYPE_DEST      (0),            // 0 = AXI MM (to PCIe host memory)
    .DMA_TYPE_SRC       (1),            // 1 = AXI Stream (from axi_ad9361)
    .CYCLIC             (0),
    .FIFO_SIZE          (8)             // 8 * 64b entries — tune based on PCIe latency
  ) u_axi_dmac_rx (
    .s_axi_aclk         (axi_clk),
    .s_axi_aresetn      (axi_rst_n),

    // AXI-Lite control (from PCIe BAR0)
    .s_axi_awvalid      (axil_dmac_rx_awvalid),
    .s_axi_awaddr       (axil_dmac_rx_awaddr),
    .s_axi_awready      (axil_dmac_rx_awready),
    .s_axi_wvalid       (axil_dmac_rx_wvalid),
    .s_axi_wdata        (axil_dmac_rx_wdata),
    .s_axi_wstrb        (axil_dmac_rx_wstrb),
    .s_axi_wready       (axil_dmac_rx_wready),
    .s_axi_bvalid       (axil_dmac_rx_bvalid),
    .s_axi_bresp        (axil_dmac_rx_bresp),
    .s_axi_bready       (axil_dmac_rx_bready),
    .s_axi_arvalid      (axil_dmac_rx_arvalid),
    .s_axi_araddr       (axil_dmac_rx_araddr),
    .s_axi_arready      (axil_dmac_rx_arready),
    .s_axi_rvalid       (axil_dmac_rx_rvalid),
    .s_axi_rdata        (axil_dmac_rx_rdata),
    .s_axi_rresp        (axil_dmac_rx_rresp),
    .s_axi_rready       (axil_dmac_rx_rready),

    // AXI-Stream source (from axi_ad9361)
    .s_axis_aclk        (axi_clk),
    .s_axis_valid       (adc_valid),
    .s_axis_data        (adc_data),
    .s_axis_ready       (),             // backpressure — connect if needed
    .s_axis_xfer_req    (adc_enable),

    // AXI-MM destination — connects to PCIe AXI bridge (m_axi port)
    // These connect to Xilinx PCIe IP's AXI slave in the block design
    .m_dest_axi_aclk    (axi_clk),
    .m_dest_axi_aresetn (axi_rst_n),
    .m_dest_axi_awaddr  (),            // to PCIe AXI interconnect
    .m_dest_axi_awlen   (),
    .m_dest_axi_awsize  (),
    .m_dest_axi_awburst (),
    .m_dest_axi_awprot  (),
    .m_dest_axi_awcache (),
    .m_dest_axi_awvalid (),
    .m_dest_axi_awready (1'b0),        // placeholder — connect in bd.tcl
    .m_dest_axi_wdata   (),
    .m_dest_axi_wstrb   (),
    .m_dest_axi_wready  (1'b0),
    .m_dest_axi_wvalid  (),
    .m_dest_axi_bvalid  (1'b0),
    .m_dest_axi_bresp   (2'b00),
    .m_dest_axi_bready  (),
    .m_dest_axi_arvalid (),
    .m_dest_axi_araddr  (),
    .m_dest_axi_arlen   (),
    .m_dest_axi_arsize  (),
    .m_dest_axi_arburst (),
    .m_dest_axi_arprot  (),
    .m_dest_axi_arcache (),
    .m_dest_axi_arready (1'b0),
    .m_dest_axi_rdata   (64'h0),
    .m_dest_axi_rresp   (2'b00),
    .m_dest_axi_rvalid  (1'b0),
    .m_dest_axi_rready  (),

    // Overflow flag back to axi_ad9361
    .fifo_wr_overflow   (adc_dovf),
    .irq                ()              // connect to PCIe MSI if needed later
  );

  //--------------------------------------------------------------------------
  // PCIe Endpoint (placeholder instantiation)
  // The full Xilinx 7-Series PCIe IP is generated by Vivado IP wizard and
  // wired up in bd.tcl. This comment marks where it lives in the hierarchy.
  //
  // Key connections from PCIe IP to the rest of this design:
  //   pcie_refclk        -> REFCLK input of PCIe IP
  //   pcie_rst_n         -> sys_rst_n input
  //   pcie_rx_p/n        -> pcie_7x_mgt rxp/rxn
  //   pcie_tx_p/n        -> pcie_7x_mgt txp/txn
  //   axi_clk            <- axi_aclk output of PCIe IP (125 or 250 MHz)
  //   axi_rst_n          <- axi_aresetn output of PCIe IP
  //   AXI master port    -> AXI interconnect -> axi_ad9361 + axi_dmac BAR0 slaves
  //   AXI slave port     <- axi_dmac m_dest_axi (for host memory writes)
  //--------------------------------------------------------------------------

  //--------------------------------------------------------------------------
  // AD9364 hard reset — deassert after PCIe link is up and clocks stable
  // Simple power-on reset stretcher: hold RESETB low for ~1 ms after sys_rst
  //--------------------------------------------------------------------------
  reg [19:0] rst_cnt = 20'h0;
  reg        ad9364_rst_reg = 1'b0;

  always @(posedge axi_clk or negedge axi_rst_n) begin
    if (!axi_rst_n) begin
      rst_cnt      <= 20'h0;
      ad9364_rst_reg <= 1'b0;
    end else begin
      if (rst_cnt != 20'hFFFFF) begin
        rst_cnt      <= rst_cnt + 1'b1;
        ad9364_rst_reg <= 1'b0;        // hold reset low during count
      end else begin
        ad9364_rst_reg <= 1'b1;        // release reset (RESETB high = normal operation)
      end
    end
  end

  assign ad9364_rst_n = ad9364_rst_reg;
  assign ad9364_ctrl_in = 1'b0;       // unused in 1R1T mode

  //--------------------------------------------------------------------------
  // Debug LEDs
  //   [0] = PCIe link up (from PCIe IP user_link_up signal)
  //   [1] = AD9364 reset released
  //   [2] = ADC data valid (heartbeat — blink if receiving samples)
  //   [3] = DMA overflow (sticky, indicates PCIe bandwidth issue)
  //--------------------------------------------------------------------------
  reg        adc_dovf_sticky = 1'b0;
  reg [25:0] led_blink_cnt   = 26'h0;

  always @(posedge axi_clk) begin
    led_blink_cnt <= led_blink_cnt + 1'b1;
    if (adc_dovf) adc_dovf_sticky <= 1'b1;
  end

  assign led[0] = 1'b0;               // wire to pcie_ip.user_link_up in bd.tcl
  assign led[1] = ad9364_rst_n;
  assign led[2] = adc_valid ? led_blink_cnt[25] : 1'b0;  // blink when streaming
  assign led[3] = adc_dovf_sticky;

endmodule
