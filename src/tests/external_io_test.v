`timescale 10ns/100ps

module test_top();

  `define VERILATOR

  localparam spi_bit_half_period = 3;
  localparam reset_hold_period = 2;

  localparam JOB_CONFIG_WIDTH = 8;
  localparam DEVICE_CONFIG_WIDTH = 8;
  localparam RESULT_DATA_WIDTH = 16;

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
  // From shapool
  reg [RESULT_DATA_WIDTH-1:0] shapool_result;
  reg shapool_success;

  external_io
  #(.JOB_CONFIG_WIDTH(DEVICE_CONFIG_WIDTH),
    .DEVICE_CONFIG_WIDTH(JOB_CONFIG_WIDTH),
    .RESULT_DATA_WIDTH(RESULT_DATA_WIDTH))
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
    // From shapool
    shapool_result,
    shapool_success
  );

  // Test case
  // * input signals are double-registered (2 cycle delay)
  // * device_config (SPI1) works properly
  // * job_config (SPI0) works properly
  // * shapool_succes + SPI1 works properly

  reg [31:0] i;

  reg [JOB_CONFIG_WIDTH-1:0] test_job_config = 8'b10101010;
  reg [DEVICE_CONFIG_WIDTH-1:0] test_device_config = 8'b10101010;
  reg [RESULT_DATA_WIDTH-1:0] test_result = 16'h0000;

  // Generate clock
  always
  begin
      clk = 0;
      #1;
      clk = 1;
      #1;
  end

  initial
    begin

      $dumpfile("test_external_io.vcd");
      $dumpvars;

      // Initial states
      reset_n = 1;
      sck0 = 0;
      sdi0 = 0;
      cs0_n = 1;

      sck1 = 0;
      sdi1 = 0;
      cs1_n = 1;
      shapool_result = 16'h4141; // ASCII "AA"
      shapool_success = 0;

      #10;

      ////////////////////////////////////////////
      // Test SPI0 (clock in job configuration) //
      ////////////////////////////////////////////
 
      reset_n = 0;
      #reset_hold_period;

      // (SPI Mode 0,0)
      cs0_n = 0;

      for (i = 0; i < JOB_CONFIG_WIDTH; i = i + 1)
        begin
          // Data out before rising edge
          sdi0 = test_job_config[JOB_CONFIG_WIDTH-1];
          test_job_config <= { test_job_config[JOB_CONFIG_WIDTH-2:0], 1'b0 };
          #spi_bit_half_period;

          // Rising edge (uut samples)
          sck0 = 1;
          #spi_bit_half_period;

          // Falling edge (next bit out)
          sck0 = 0;
        end

      cs0_n = 1;
      reset_n = 1;
      #10;

      // TODO assert

      ///////////////////////////////////////////////
      // Test SPI1 (clock in device configuration) //
      ///////////////////////////////////////////////

      reset_n = 0;
      #reset_hold_period;

      // (SPI Mode 0,0)
      cs1_n = 0;

      for (i = 0; i < DEVICE_CONFIG_WIDTH; i = i + 1)
        begin
          // Data out before rising edge
          sdi1 = test_device_config[DEVICE_CONFIG_WIDTH-1];
          test_device_config <= { test_device_config[DEVICE_CONFIG_WIDTH-2:0], 1'b0 };
          #spi_bit_half_period;

          // Rising edge (uut samples)
          sck1 = 1;
          #spi_bit_half_period;

          // Falling edge (next bit out)
          sck1 = 0;
        end

      cs1_n = 1;
      reset_n = 1;
      #reset_hold_period;

      // TODO assert

      // TODO test shifting out sdo1

      //////////////////////////////////////////////////////////
      // Test SPI1 on success (clock in device configuration) //
      //////////////////////////////////////////////////////////

      shapool_success = 1;

      // (SPI Mode 0,0)
      cs1_n = 0;
      sdi1 = 0;

      for (i = 0; i < RESULT_DATA_WIDTH; i = i + 1)
        begin
          // data out on 
          #spi_bit_half_period;

          // Rising edge (sample)
          test_result <= { test_result[RESULT_DATA_WIDTH-2:0], sdo1 };
          sck1 = 1;
          #spi_bit_half_period;

          // Falling edge (next bit out)
          sck1 = 0;
        end

      cs1_n = 1;
      #reset_hold_period;

      // TODO assert

      #100;
      $finish;
    end

endmodule