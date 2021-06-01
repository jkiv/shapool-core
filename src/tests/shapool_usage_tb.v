`timescale 10ns/100ps

module shapool_test();

  /*
    Tests basic usage of `shapool`.

    Uses only one sha_unit (POOL_SIZE = 1).
  */

  `define VERILATOR
  //`define DEBUG_VERBOSE

  `define SHAPOOL_NO_NONCE_OFFSET // Required for POOL_SIZE = 1

  localparam POOL_SIZE = 1;
  localparam POOL_SIZE_LOG2 = 0;
  localparam BASE_DIFFICULTY = 1;

  localparam [359:0] job_parameters = {
    128'hdc6a3b8d_0c69421a_cb1a5434_e536f7d5, // SHA starting state
    128'hc3c1b9e4_4cbb9b8f_95f0172e_fc48d2df, // ...
    96'hdc141787_358b0553_535f0119,           // Start of message block
    8'd3                                      // Difficulty offset (BASE_DIFFICULTY + 3 = 4 bits)
  };
  // NOTE: using TARGET_OFFSET to provide zero check

  localparam [7:0] device_parameters = {
    8'h00 // nonce start (MSB) 
  };

  reg clk = 0;
  reg reset_n = 1;

  reg [255:0] sha_state;
  reg [95:0] message_head;
  reg [7:0] difficulty;
  reg [7:0] nonce_start_MSB;

  wire success;
  wire [31:0] nonce;
  wire [7:0] match_flags;

  // TODO expected values
  localparam nonce_expected = 39;
  localparam [255:0] H_expected = { 256'hc7f3244e501edf780c420f63a4266d30ffe1bdb53f4fde3ccd688604f15ffd03 };

  reg [255:0] H_btc [0:2];

  // State (a,b,c,...) after first block of first hash
  initial H_btc[0] =
    { 128'hdc6a3b8d_0c69421a_cb1a5434_e536f7d5,
      128'hc3c1b9e4_4cbb9b8f_95f0172e_fc48d2df };

  // Expected result of first hash
  initial H_btc[1] =
    { 128'h0fc3bf25_9405a32f_d6d78a5e_6de88914,
      128'h8edd4088_cc46a2eb_c604c45a_15fe7d15 };

  // Expected result of second hash
  initial H_btc[2] =
    { 128'h766f7950_56dd74d7_03b9173e_8d44223b,
      128'hdbe3e0b2_9fe6a0eb_8ab33534_88c2565c };

  /*
    0	5c56c2883435b38aeba0e69fb2e0e3db3b22448d3e17b903d774dd5650796f76
    1	28902a23a194dee94141d1b70102accd85fc2c1ead0901ba0e41ade90d38a08e
    2	729577af82250aaf9e44f70a72814cf56c16d430a878bf52fdaceeb7b4bd37f4
    3	8491452381016cf80562ff489e492e00331de3553178c73c5169574000f1ed1c
   39	03fd5ff1048668cd3cde4f3fb5bde1ff306d26a4630f420c78df1e504e24f3c7
      c7f3244e501edf780c420f63a4266d30ffe1bdb53f4fde3ccd688604f15ffd03 (output of module)
  990	0001e3a4583f4c6d81251e8d9901dbe0df74d7144300d7c03cab15eca04bd4bb
  */

  wire [15:0] difficulty_bm;

  difficulty_map dm (
    clk,
    !reset_n,
    difficulty[3:0],
    difficulty_bm
  );

  shapool
  #(.POOL_SIZE(POOL_SIZE),
    .POOL_SIZE_LOG2(POOL_SIZE_LOG2),
    .BASE_DIFFICULTY(BASE_DIFFICULTY))
  uut (
    // Control
    clk,
    reset_n,
    // Job Params
    sha_state,
    message_head,
    difficulty_bm,
    nonce_start_MSB,
    // Result
    success,
    nonce,
    match_flags
  );

  always
    begin
      #1 clk = !clk;
    end

  reg [31:0] i = 0;
  reg [31:0] n = 0;

  initial
    begin

      $dumpfile("shapool_usage_tb.vcd");
      $dumpvars;

      // Initial values
      clk <= 0;
      reset_n <= 1;

      // Job parameters
      sha_state    <= job_parameters[360-1:360-256];
      message_head <= job_parameters[360-256-1:360-256-96];
      difficulty   <= job_parameters[360-256-96-1:0];

      // Device configuration
      nonce_start_MSB <= device_parameters[7:0];

      // Reset module
      #2 reset_n <= 0; // one clock cycle

      // (Normally job_parameters, device_parameters shifted in here.)

      #2 reset_n <= 1; // one clock cycle
      
      #2; // one clock cycle, RESET -> EXEC

      for (n = 0; n < 50 && !success; n = n)
        begin

          for (i = 0; i < 64 && !success; i = i + 1)
            begin
              #1; // rising edge
              #1; // falling edge

              `ifdef DEBUG_VERBOSE
                $display("  success: %b", uut.success);
                $display("  round: %d", uut.round);
                $display("  nonce: %d", nonce);
                $display("  u0:");
                $display("    M: %h", uut.pipelines[0].u0.M[511:384]);
                $display("       %h", uut.pipelines[0].u0.M[383:256]);
                $display("       %h", uut.pipelines[0].u0.M[255:128]);
                $display("       %h", uut.pipelines[0].u0.M[127:  0]);
                $display("    H: %h", uut.pipelines[0].H_u0[255:128]);
                $display("       %h", uut.pipelines[0].H_u0[127:  0]);
                $display("  u1:");
                $display("    M: %h", uut.pipelines[0].u1.M[511:384]);
                $display("       %h", uut.pipelines[0].u1.M[383:256]);
                $display("       %h", uut.pipelines[0].u1.M[255:128]);
                $display("       %h", uut.pipelines[0].u1.M[127:  0]);
                $display("    H: %h", uut.pipelines[0].H_u1[255:128]);
                $display("       %h", uut.pipelines[0].H_u1[127:  0]);
                $display("");
              `endif
            end

        end

        if (success == 1 && nonce - 2 == nonce_expected && uut.pipelines[0].H_u1 == H_expected)
          begin
            // TODO Success
            $display("\033\133\063\062\155[PASS]\033\133\060\155 `shapool`: single track, BTC four-zeroes");
            // TODO inputs
            $display("");
            $display("       success          = %0d", success);
            $display("       nonce            = %0d", nonce);
            $display("       nonce (adjusted) = %0d", nonce-2);
            $display("       H (actual)       = %h", uut.pipelines[0].H_u1[255:128]);
            $display("                          %h", uut.pipelines[0].H_u1[127:  0]);
            $display("       H (expected)     = %h", H_expected[255:128]);
            $display("                          %h", H_expected[127:  0]);
          end
        else
          begin
            $display("\033\133\063\061\155[FAIL]\033\133\060\155 `shapool`: single track, BTC four-zeroes");
            // TODO inputs
            $display("");
            $display("       success          = %0d", success);
            $display("       nonce            = %0d", nonce);
            $display("       nonce (adjusted) = %0d", nonce-2);
            $display("       H (actual)       = %h", uut.pipelines[0].H_u1[255:128]);
            $display("                          %h", uut.pipelines[0].H_u1[127:  0]);
            $display("       H (expected)     = %h", H_expected[255:128]);
            $display("                          %h", H_expected[127:  0]);
            $error("Test case failed.");
          end

      $finish;
    end

endmodule // shapool_test
