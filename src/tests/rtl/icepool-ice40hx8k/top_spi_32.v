// Two SPI interfaces, plus buffer, plus READY

module top
(
  clk_in,
  reset_n_in,
  // Global data
  sck0_in,
  sdi0_in,
  cs0_n_in,
  // Daisy data
  sck1_in,
  sdi1_in,
  sdo1_out,
  cs1_n_in,
  // Success flags
  ready_n_ts_out,
  // Indicators
  status_led_n_out
);

    input wire clk_in;
    input wire reset_n_in;
    input wire sck0_in;
    input wire sdi0_in;
    input wire cs0_n_in;
    input wire sck1_in;
    input wire sdi1_in;
    output wire sdo1_out;
    input wire cs1_n_in;
    output wire ready_n_ts_out;
    output wire status_led_n_out;

    reg[2:0] sck0;
    reg[2:0] sck1;
    
    // TODO triple register all SPI values

    wire sck0_rising_edge;
    wire sck1_rising_edge;

    assign sck0_rising_edge = ~sck0[2] & sck0[1];
    assign sck1_rising_edge = ~sck1[2] & sck1[1];

    reg[31:0] spi0_buffer;
    reg[31:0] spi1_buffer;

    // Synchronzing data clocks
    always @(posedge clk_in)
      begin
        sck0 <= {sck0[1], sck0[0], sck0_in};
        sck1 <= {sck1[1], sck1[1], sck1_in};
      end

    // SPI0 logic
    always @(posedge clk_in)
      begin
          if (~reset_n_in)
            spi0_buffer <= {(31){1'b0}};
          else if (~cs0_n_in && sck0_rising_edge)
            begin
                spi0_buffer <= { spi0_buffer[30:0], sdi0_in };
            end
      end

    // SPI1 logic
    always @(posedge clk_in)
      begin
          if (~reset_n_in)
            spi1_buffer <= {(31){1'b0}};
          else if (~cs1_n_in && sck1_rising_edge)
            begin
                spi1_buffer <= { spi1_buffer[30:0], sdi1_in };
            end
      end

    assign sdo1_out = spi1_buffer[31];
    assign ready_n_ts_out = (spi0_buffer[31]) ? 1'b0 : 1'bz;

    assign status_led_n_out = ~((sck0_in & ~cs0_n) | (sck1_in & ~cs1_n));


endmodule