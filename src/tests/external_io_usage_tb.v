`timescale 10ns/100ps

module external_io_usage_tb();

  /*
    Tests basic usage of `external_io` module.
  */

  `define VERILATOR
  `define DEBUG_VERBOSE

  localparam spi_bit_half_period = 6; // 3 clock cycles
  localparam reset_hold_period = 2;   // 1 clock cycle

  localparam JOB_CONFIG_WIDTH = 8;
  localparam DEVICE_CONFIG_WIDTH = 8;

  reg clk;
  reg reset_n;
  // SPI(0)
  reg sck0;
  reg sdi0;
  reg cs0_n;
  // SPI(1)
  reg sck1;
  reg sdi1;
  wire sdo1;
  reg cs1_n;
  // Stored data
  wire [DEVICE_CONFIG_WIDTH-1:0] device_config;
  wire [JOB_CONFIG_WIDTH-1:0] job_config;
  // Control flag
  wire core_reset_n;
  // From shapool
  reg [7:0] shapool_match_flags;
  reg [31:0] shapool_result;
  reg shapool_success;
  // READY signal
  wire ready;

  external_io
  #(.JOB_CONFIG_WIDTH(DEVICE_CONFIG_WIDTH),
    .DEVICE_CONFIG_WIDTH(JOB_CONFIG_WIDTH))
  uut (
    clk,
    reset_n,
    // SPI(0)
    sck0,
    sdi0,
    cs0_n,
    // SPI(1)
    sck1,
    sdi1,
    sdo1,
    cs1_n,
    // Stored data
    device_config,
    job_config,
    // Control flags
    core_reset_n,
    // From shapool
    shapool_match_flags,
    shapool_result,
    shapool_success,
    // READY signal
    ready
  );

  reg [31:0] i;

  localparam [39:0] expected_result = 40'hEEDDCCBB_AA;
  localparam [DEVICE_CONFIG_WIDTH-1:0] expected_device_config = 8'b10101010;
  localparam [JOB_CONFIG_WIDTH-1:0] expected_job_config = 8'b10101010;

  reg [JOB_CONFIG_WIDTH-1:0] test_job_config = expected_job_config;
  reg [DEVICE_CONFIG_WIDTH-1:0] test_device_config = expected_device_config;
  reg [39:0] test_result = 0;

  // Generate clock
  always
  begin
      clk <= 0;
      #1;
      clk <= 1;
      #1;
  end

  initial
    begin

      $dumpfile("external_io_usage_tb.vcd");
      $dumpvars;

      // Initial states
      reset_n <= 0;
      sck0 <= 0;
      sdi0 <= 0;
      cs0_n <= 1;

      sck1 <= 0;
      sdi1 <= 0;
      cs1_n <= 1;
      shapool_result <= 32'hEEDDCCBB;
      shapool_match_flags <= 8'hAA;
      shapool_success <= 0;

      #10;

      ////////////////////////////////////////////
      // Test SPI0 (clock in job configuration) //
      ////////////////////////////////////////////

      if (core_reset_n == 0)
        begin
          $display("\033\133\063\062\155[PASS]\033\133\060\155 `external_io`: core_reset_n");
        end
      else
        begin
          $display("\033\133\063\061\155[FAIL]\033\133\060\155 `external_io`: core_reset_n");
          $error("Test case failed: core_reset_n should be low after reset_n goes low and reset_hold_period elapsed.");
        end

      // (SPI Mode 0,0)
      cs0_n <= 0;
      #reset_hold_period;

      for (i = 0; i < JOB_CONFIG_WIDTH; i = i + 1)
        begin
          // Data out before rising edge
          sdi0 <= test_job_config[JOB_CONFIG_WIDTH-1];
          test_job_config <= { test_job_config[JOB_CONFIG_WIDTH-2:0], 1'b0 };
          #spi_bit_half_period;

          // Rising edge (uut samples)
          sck0 <= 1;
          #spi_bit_half_period;

          // Falling edge (next bit out)
          sck0 <= 0;
        end

      cs0_n <= 1;
      #10;

      if (uut.job_config == expected_job_config)
        begin
          $display("\033\133\063\062\155[PASS]\033\133\060\155 `external_io`: shift in job configuration");
        end
      else
        begin
          $display("\033\133\063\061\155[FAIL]\033\133\060\155 `external_io`: shift in job configuration");
          $display("uut.job_config: %h", uut.job_config);
          $error("Test case failed: SPI0 did not properly load uut.job_config.");
        end

      ///////////////////////////////////////////////
      // Test SPI1 (clock in device configuration) //
      ///////////////////////////////////////////////

      // (SPI Mode 0,0)
      cs1_n <= 0;

      for (i = 0; i < DEVICE_CONFIG_WIDTH; i = i + 1)
        begin
          // Data out before rising edge
          sdi1 <= test_device_config[DEVICE_CONFIG_WIDTH-1];
          test_device_config <= { test_device_config[DEVICE_CONFIG_WIDTH-2:0], 1'b0 };
          #spi_bit_half_period;

          // Rising edge (uut samples)
          sck1 <= 1;
          #spi_bit_half_period;

          // Falling edge (next bit out)
          sck1 <= 0;
        end

      cs1_n <= 1;
      reset_n <= 1;

      if (uut.device_config == expected_device_config)
        begin
          $display("\033\133\063\062\155[PASS]\033\133\060\155 `external_io`: shift in device configuration");
        end
      else
        begin
          $display("\033\133\063\061\155[FAIL]\033\133\060\155 `external_io`: shift in device configuration");
          $display("uut.device_config: %h", uut.device_config);
          $error("Test case failed: SPI1 did not properly load uut.device_config");
        end

      // TODO test shifting out sdo1

      /////////////////////////////////////////////
      // Test SPI1 on success (clock out result) //
      /////////////////////////////////////////////

      shapool_success <= 1;

      // (SPI Mode 0,0)
      cs1_n <= 0;
      sdi1 <= 0;

      for (i = 0; i < 40; i = i + 1)
        begin
          // data out
          #spi_bit_half_period;

          // Rising edge (sample)
          test_result <= { test_result[38:0], sdo1 };
          sck1 <= 1;
          #spi_bit_half_period;

          // Falling edge (next bit out)
          sck1 <= 0;
        end

      cs1_n <= 1;
      #reset_hold_period;

      if (test_result == expected_result)
        begin
          $display("\033\133\063\062\155[PASS]\033\133\060\155 `external_io`: shift out result");
        end
      else
        begin
          $display("\033\133\063\061\155[FAIL]\033\133\060\155 `external_io`: shift out result");
          $display("test_result: %h", test_result);
          $error("Test case failed: SPI1 failed to shift out result properly.");
        end

      #100;
      $finish;
    end

endmodule