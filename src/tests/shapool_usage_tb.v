`timescale 10ns/100ps

module shapool_test();

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
    8'd3                                      // Difficulty offset 
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

  // TODO expected values
  localparam nonce_expected = 0;
  localparam [255:0] H_expected = { 256'b0 };

  reg [255:0] H_btc[0:2];

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
    nonce
  );

  reg [31:0] i = 0;
  reg [31:0] n = 0;

  initial
    begin

      // Job parameters
      sha_state    = job_parameters[360-1:360-256];
      message_head = job_parameters[360-256-1:360-256-96];
      difficulty   = job_parameters[360-256-96-1:0];

      // Device configuration
      nonce_start_MSB = device_parameters[7:0];

      #1 reset_n = 0;
      #1 clk = 1;
      #1 clk = 0;

      #1 reset_n = 1;
      #1 clk = 1;
      #1 clk = 0;

      for (n = 0; n < 100 && !success; n = n + 1)
        begin

          for (i = 0; i < 64; i = i + 1)
            begin

              `ifdef DEBUG_VERBOSE
                /*
                $display("== n: %d ==", n);
                $display("  success: %b", uut.success);
                $display("  round: %d", uut.round);
                $display("  nonce: %d", nonce);
                $display("  u0");
                $display("    M: %h", uut.tracks[0].u0.M[511:384]);
                $display("       %h", uut.tracks[0].u0.M[383:256]);
                $display("       %h", uut.tracks[0].u0.M[255:128]);
                $display("       %h", uut.tracks[0].u0.M[127:  0]);
                $display("    H: %h", uut.tracks[0].H_u0[255:128]);
                $display("       %h", uut.tracks[0].H_u0[127:  0]);
                $display("  u1");
                $display("    M: %h_%h", uut.tracks[0].u1.M[511:512-32],
                                        uut.tracks[0].u1.M[511-32:384]);
                $display("       %h", uut.tracks[0].u1.M[383:256]);
                $display("       %h", uut.tracks[0].u1.M[255:128]);
                $display("       %h", uut.tracks[0].u1.M[127:  0]);
                $display("    H: %h", uut.tracks[0].H_u1[255:128]);
                $display("       %h", uut.tracks[0].H_u1[127:  0]);
                $display("");
                */
              `endif

              #1 clk = 1;
              #1 clk = 0;
            end

          `ifdef DEBUG_VERBOSE
            $display("nonce: %2d, success: %d", n, success);
          `endif
        end

        // Print results

        $display("success: %d", success);

        if (success == 1)
          begin
            $display("nonce (found): %h", nonce);
            $display("hash (found): %h %h %h %h %h %h %h %h",
              uut.tracks[0].u0.H1[255:224], uut.tracks[0].u0.H1[223:192], uut.tracks[0].u0.H1[191:160], uut.tracks[0].u0.H1[159:128],
              uut.tracks[0].u0.H1[127:96], uut.tracks[0].u0.H1[95:64], uut.tracks[0].u0.H1[63:32], uut.tracks[0].u0.H1[31:0]);
          end
        else
          begin
            $display("nonce (found): (none)");
            $display("hash (found): (none)");
          end

        $display("nonce (expected): %h", nonce_expected);
        $display("hash (expected): %h %h %h %h %h %h %h %h",
          H_expected[255:224], H_expected[223:192], H_expected[191:160], H_expected[159:128],
          H_expected[127:96], H_expected[95:64], H_expected[63:32], H_expected[31:0]);
    end

endmodule // shapool_test
