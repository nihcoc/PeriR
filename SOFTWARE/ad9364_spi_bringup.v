//-----------------------------------------------------------------------------
// PeriR — AD9364 SPI Bringup
// Phase 2 test: read AD9364 chip ID over SPI
//
// On power-up this module automatically reads register 0x037 (Product ID).
// Expected response: 0x0A (AD9364) or 0x0B (AD9361).
// Result is exposed as a register at AXI offset 0x0 for the CM4 to read.
//
// SPI protocol: CPOL=0, CPHA=0, MSB first
// Frame format: [W/R=1bit][ADDR=14bits][DATA=8bits] = 24 bits total
// Max SPI clock: 10 MHz (set CLK_DIV to axi_clk / (2 * 10e6))
//-----------------------------------------------------------------------------

`timescale 1ns/1ps

module ad9364_spi_bringup #(
  parameter CLK_DIV = 6   // 125 MHz / (2*6) = ~10.4 MHz SPI clock
) (
  input  wire        clk,
  input  wire        rst_n,

  // SPI to AD9364
  output reg         spi_sck,
  output reg         spi_mosi,
  input  wire        spi_miso,
  output reg         spi_csn,

  // Result
  output reg  [7:0]  chip_id,          // latched after read completes
  output reg         done,             // pulses high for 1 cycle when chip_id valid
  output reg         id_match          // 1 if chip_id == 0x0A (AD9364)
);

  // AD9364 chip ID register address
  localparam CHIP_ID_ADDR = 14'h0037;
  localparam CHIP_ID_EXP  = 8'h0A;

  // 24-bit SPI frame: READ (1'b1) | ADDR[13:0] | DATA[7:0]
  // For a read, DATA bits are don't-care on MOSI, captured on MISO
  localparam [23:0] READ_FRAME = {1'b1, CHIP_ID_ADDR, 8'h00};

  // State machine
  localparam IDLE     = 3'd0;
  localparam CS_LOW   = 3'd1;
  localparam SHIFTING = 3'd2;
  localparam CS_HIGH  = 3'd3;
  localparam DONE     = 3'd4;

  reg [2:0]  state     = IDLE;
  reg [7:0]  clk_cnt   = 8'h0;
  reg [4:0]  bit_cnt   = 5'd0;        // counts 0..23
  reg [23:0] shift_out = READ_FRAME;
  reg [23:0] shift_in  = 24'h0;
  reg        sck_phase = 1'b0;

  // Small delay counter for CS setup/hold
  reg [3:0]  delay_cnt = 4'h0;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state      <= IDLE;
      spi_sck    <= 1'b0;
      spi_mosi   <= 1'b0;
      spi_csn    <= 1'b1;
      chip_id    <= 8'h00;
      done       <= 1'b0;
      id_match   <= 1'b0;
      clk_cnt    <= 8'h0;
      bit_cnt    <= 5'd0;
      shift_out  <= READ_FRAME;
      shift_in   <= 24'h0;
      delay_cnt  <= 4'h0;
    end else begin
      done <= 1'b0;                    // default: not done

      case (state)
        IDLE: begin
          spi_csn   <= 1'b1;
          spi_sck   <= 1'b0;
          delay_cnt <= 4'h0;
          bit_cnt   <= 5'd0;
          shift_out <= READ_FRAME;
          shift_in  <= 24'h0;
          state     <= CS_LOW;         // auto-start on reset release
        end

        CS_LOW: begin
          spi_csn <= 1'b0;             // assert CS
          // wait a few cycles for CS setup time (t_S = 2 ns min, very fast)
          if (delay_cnt == 4'd4) begin
            delay_cnt <= 4'h0;
            spi_mosi  <= shift_out[23]; // pre-load first bit
            state     <= SHIFTING;
          end else
            delay_cnt <= delay_cnt + 1'b1;
        end

        SHIFTING: begin
          // Generate SPI clock and shift data
          if (clk_cnt == CLK_DIV - 1) begin
            clk_cnt   <= 8'h0;
            sck_phase <= ~sck_phase;
            spi_sck   <= sck_phase;

            if (!sck_phase) begin
              // Rising edge: sample MISO
              shift_in <= {shift_in[22:0], spi_miso};
            end else begin
              // Falling edge: drive MOSI with next bit
              if (bit_cnt < 5'd23) begin
                bit_cnt  <= bit_cnt + 1'b1;
                spi_mosi <= shift_out[22 - bit_cnt];
              end else begin
                // All 24 bits done
                spi_sck <= 1'b0;
                state   <= CS_HIGH;
              end
            end
          end else
            clk_cnt <= clk_cnt + 1'b1;
        end

        CS_HIGH: begin
          spi_csn <= 1'b1;             // deassert CS
          if (delay_cnt == 4'd4) begin
            chip_id  <= shift_in[7:0]; // last 8 bits are the read data
            id_match <= (shift_in[7:0] == CHIP_ID_EXP);
            done     <= 1'b1;
            state    <= DONE;
          end else
            delay_cnt <= delay_cnt + 1'b1;
        end

        DONE: begin
          // Hold result — CM4 reads it via loopback_reg or direct AXI register
          done  <= 1'b0;
          state <= DONE;               // stay here until reset
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule
