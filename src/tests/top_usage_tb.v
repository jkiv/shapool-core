`timescale 1us/10ns

module test_top();

  `define VERILATOR

  reg clk_in = 0;

  reg reset_n_in = 0;

  reg sck0_in;
  reg sdi0_in;
  reg cs0_n_in;

  reg sck1_in;
  reg sdi1_in;
  wire sdo1_out;
  reg cs1_n_in;

  wire ready_n_ts_inout;

  wire status_led_n_out;

  `define SHAPOOL_NO_NONCE_OFFSET // Required for POOL_SIZE = 1:

  localparam POOL_SIZE      = 1;
  localparam POOL_SIZE_LOG2 = 0;
  localparam BASE_TARGET    = 3;

  top
  #(.POOL_SIZE(POOL_SIZE),
    .POOL_SIZE_LOG2(POOL_SIZE_LOG2),
    .BASE_TARGET(BASE_TARGET))
  uut (
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
    ready_n_ts_inout,
    // Indicators
    status_led_n_out
  );

  // Test case

  reg [31:0] n = 0;
  reg [31:0] i = 0;

  localparam [359:0] test_spi0_data0 = {
    128'hdc6a3b8d_0c69421a_cb1a5434_e536f7d5, // SHA starting state
    128'hc3c1b9e4_4cbb9b8f_95f0172e_fc48d2df, // ...
    96'hdc141787_358b0553_535f0119            // Start of message block
  };

  localparam [7:0] test_spi1_data0 = {
    8'h00 // nonce start (MSB) 
  };

  reg [359:0] test_spi0_data;
  reg [7:0] test_spi1_data;
  reg [31:0] result;

  initial
    begin

      $dumpfile("test_top.vcd");
      $dumpvars;

      test_spi0_data = test_spi0_data0;
      test_spi1_data = test_spi1_data0;

      // Initial states
      clk_in = 0;
      reset_n_in = 1;
      sck0_in = 0;
      cs0_n_in = 1;
      sck1_in = 0;
      cs1_n_in = 1;

      // Deassert reset_n_in to enter STATE_IDLE
      // -- to read in data on SPI
      #1 reset_n_in = 0;

      ///////////////////////////////////
      // Clock-in device configuration //
      ///////////////////////////////////
 
      // Assert CS1
      #1 cs1_n_in = 0;

      for (i = 0; i < 8; i = i + 1)
        begin
          // Shift-in data msb-first
          #1 sdi1_in = test_spi1_data[7];
          test_spi1_data <= { test_spi1_data[6:0], 1'b0 };

          #1 sck1_in = 1;
          
          // Need 3 clock cycles to synchronize sck1_in
          #1 clk_in = 1;
          #1 clk_in = 0;
          #1 clk_in = 1;
          #1 clk_in = 0;
          #1 clk_in = 1;
          #1 clk_in = 0;

          #1 sck1_in = 0;
          
          // Need 3 clock cycles to synchronize sck1_in
          #1 clk_in = 1;
          #1 clk_in = 0;
          #1 clk_in = 1;
          #1 clk_in = 0;
          #1 clk_in = 1;
          #1 clk_in = 0;
        end

      #1 cs1_n_in = 1;

      /////////////////////////////
      // Clock-in job parameters //
      /////////////////////////////

      #1 cs0_n_in = 0;
     
      for (i = 0; i < 360; i = i + 1)
        begin
          // Simulate FIFO into device
          #1 sdi0_in = test_spi0_data[351];
          test_spi0_data <= { test_spi0_data[350:0], 1'b0 };

          #1 sck0_in = 1;
          
          // Need 3 clock cycles to synchronize sck1_in
          #1 clk_in = 1;
          #1 clk_in = 0;
          #1 clk_in = 1;
          #1 clk_in = 0;
          #1 clk_in = 1;
          #1 clk_in = 0;

          #1 sck0_in = 0;
          
          // Need 3 clock cycles to synchronize sck1_in
          #1 clk_in = 1;
          #1 clk_in = 0;
          #1 clk_in = 1;
          #1 clk_in = 0;
          #1 clk_in = 1;
          #1 clk_in = 0;
        end

      #1 cs0_n_in = 1;

      $display("Device configuration");
      $display("  nonce start MSB: %h", uut.nonce_start);

      $display("Job parameters:");
      $display("  SHA256 state:       %h", uut.sha_state[255:128]);
      $display("                      %h", uut.sha_state[127:0]);
      $display("  message head:       %h", uut.message_head);

      /////////////////////////////////
      // Reset and run until success //
      /////////////////////////////////
 
      // Deassert reset_n_in to enter STATE_EXEC
      #1 reset_n_in = 1;

      for (n = 0; n < 50 && !ready_n_ts_inout; n = n + 1)
        begin

          for (i = 0; i < 64; i = i + 1)
            begin
              $display("nonce: %d", uut.pool.nonce);
              $display("round: %d", uut.pool.round);
              $display("  Kt: %h", uut.pool.Kt);
              $display("  success:                %b", uut.pool.success);
              $display("    |match_flags:         %b", |uut.pool.match_flags);
              $display("    round == 0:           %b", uut.pool.round == 0);
              $display("    skip_first:           %b", uut.pool.skip_first);
              $display("    skip_second:          %b", uut.pool.skip_second);
              $display("  u0.M: %h", uut.pool.tracks[0].u0.M[511:384]);
              $display("  u0.M: %h", uut.pool.tracks[0].u0.M[383:256]);
              $display("  u0.M: %h", uut.pool.tracks[0].u0.M[255:128]);
              $display("  u0.M: %h", uut.pool.tracks[0].u0.M[127:0]);
              $display("  u0.Wt: %h", uut.pool.tracks[0].u0.Wt);
              $display("  H_u0: %h", uut.pool.tracks[0].H_u0);
              $display("  u1.M: %h", uut.pool.tracks[0].u1.M[511:384]);
              $display("  u1.M: %h", uut.pool.tracks[0].u1.M[383:256]);
              $display("  u1.M: %h", uut.pool.tracks[0].u1.M[255:128]);
              $display("  u1.M: %h", uut.pool.tracks[0].u1.M[127:0]);
              $display("  u1.Wt: %h", uut.pool.tracks[0].u1.Wt);
              $display("  H_u1 (bs): %h", uut.pool.tracks[0].H_bs);
              $display("  H: %h", uut.pool.tracks[0].H);
              $display("    test bits: %h", { uut.pool.tracks[0].H[BASE_TARGET+16-1:16], uut.pool.tracks[0].H[15:0] & uut.pool.difficulty_bm });
              $display("");

              #1 clk_in = 1;
              #1 clk_in = 0;
            end

        end

      // Extra clock to save output/result
      #1 clk_in = 1;
      #1 clk_in = 0;

      $display("nonce: %h", uut.nonce);
      $display("ext_io.result_data: %h", uut.ext_io.result_data);

      // Extra clock to save result to output buffer
      #1 clk_in = 1;
      #1 clk_in = 0;

      $display("nonce: %h", uut.nonce);
      $display("ext_io.result_data: %h", uut.ext_io.result_data);

      // Shift result out over SPI1
      #1 cs1_n_in = 0;
      
      for (i = 0; i < 32; i = i + 1)
        begin
          $display("[%d] (%b) %b", i, ready_n_ts_inout, sdo1_out);

          #1 sck1_in = 1;
          
          // Need 3 clock cycles to synchronize sck1_in
          #1 clk_in = 1;
          #1 clk_in = 0;
          #1 clk_in = 1;
          #1 clk_in = 0;
          #1 clk_in = 1;
          #1 clk_in = 0;

          result <= { result[30:0], sdo1_out };

          #1 sck1_in = 0;
          
          // Need 3 clock cycles to synchronize sck1_in
          #1 clk_in = 1;
          #1 clk_in = 0;
          #1 clk_in = 1;
          #1 clk_in = 0;
          #1 clk_in = 1;
          #1 clk_in = 0;
        end

      #1 cs1_n_in = 1;

      $display("top_test result: %h", result);

    end

endmodule
