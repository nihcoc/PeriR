//-----------------------------------------------------------------------------
// PeriR — FPGA Standalone Loopback Register
// Phase 1 test: verify PCIe link + AXI register R/W from CM4
// No AD9364 involved. Flash this first, confirm lspci sees the FPGA,
// then read/write 0x0 and 0x4 from the CM4 using xdma_rw.
//
// BAR0 map:
//   0x0000 : scratch register (R/W) — write any value, read it back
//   0x0004 : version register (RO)  — always reads 0xPE010001
//   0x0008 : counter register (RO)  — free-running 32-bit counter @ axi_clk
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module loopback_reg #(
  parameter BASEADDR = 32'h0
) (
  input  wire        s_axi_aclk,
  input  wire        s_axi_aresetn,

  // AXI4-Lite slave (from PCIe BAR0)
  input  wire [31:0] s_axi_awaddr,
  input  wire        s_axi_awvalid,
  output reg         s_axi_awready,

  input  wire [31:0] s_axi_wdata,
  input  wire [3:0]  s_axi_wstrb,
  input  wire        s_axi_wvalid,
  output reg         s_axi_wready,

  output reg  [1:0]  s_axi_bresp,
  output reg         s_axi_bvalid,
  input  wire        s_axi_bready,

  input  wire [31:0] s_axi_araddr,
  input  wire        s_axi_arvalid,
  output reg         s_axi_arready,

  output reg  [31:0] s_axi_rdata,
  output reg  [1:0]  s_axi_rresp,
  output reg         s_axi_rvalid,
  input  wire        s_axi_rready,

  output wire [3:0]  led            // LED[0] = link up, LED[1] = blink
);

  // Registers
  reg [31:0] scratch = 32'hDEADBEEF;
  reg [31:0] counter = 32'h0;

  // Free-running counter
  always @(posedge s_axi_aclk)
    counter <= counter + 1'b1;

  // Write path
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_awready <= 1'b0;
      s_axi_wready  <= 1'b0;
      s_axi_bvalid  <= 1'b0;
      s_axi_bresp   <= 2'b00;
    end else begin
      s_axi_awready <= ~s_axi_awready & s_axi_awvalid;
      s_axi_wready  <= ~s_axi_wready  & s_axi_wvalid;

      if (s_axi_awvalid && s_axi_wvalid) begin
        case (s_axi_awaddr[3:0])
          4'h0: scratch <= s_axi_wdata;  // scratch — writable
          default: ;                      // 0x4, 0x8 are read-only
        endcase
        s_axi_bvalid <= 1'b1;
        s_axi_bresp  <= 2'b00;           // OKAY
      end

      if (s_axi_bvalid && s_axi_bready)
        s_axi_bvalid <= 1'b0;
    end
  end

  // Read path
  always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      s_axi_arready <= 1'b0;
      s_axi_rvalid  <= 1'b0;
      s_axi_rdata   <= 32'h0;
      s_axi_rresp   <= 2'b00;
    end else begin
      s_axi_arready <= ~s_axi_arready & s_axi_arvalid;

      if (s_axi_arvalid) begin
        s_axi_rvalid <= 1'b1;
        s_axi_rresp  <= 2'b00;
        case (s_axi_araddr[3:0])
          4'h0: s_axi_rdata <= scratch;         // scratch
          4'h4: s_axi_rdata <= 32'hPE010001;    // version: PE = PeriR, 01.0001
          4'h8: s_axi_rdata <= counter;          // free-running counter
          default: s_axi_rdata <= 32'hBADC0FFE;
        endcase
      end

      if (s_axi_rvalid && s_axi_rready)
        s_axi_rvalid <= 1'b0;
    end
  end

  // LEDs: [0] = always on (power/link), [1] = blink from counter
  assign led[0] = 1'b1;
  assign led[1] = counter[24];         // ~0.7 Hz blink @ 125 MHz axi_clk
  assign led[2] = scratch[0];          // reflects bit 0 of scratch — write 0/1 to toggle
  assign led[3] = 1'b0;

endmodule
