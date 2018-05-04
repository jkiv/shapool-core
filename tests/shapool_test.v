module shapool_test();

  `define VERILATOR // for testing

  `define SHAPOOL_NO_NONCE_OFFSET // Required for POOL_SIZE = 1

  localparam POOL_SIZE = 1;
  localparam POOL_SIZE_LOG2 = 0;

  localparam BASE_DIFFICULTY = 1;

  localparam [359:0] test_data0 = {
    128'hdc6a3b8d_0c69421a_cb1a5434_e536f7d5, // SHA starting state
    128'hc3c1b9e4_4cbb9b8f_95f0172e_fc48d2df, // ...
    96'hdc141787_358b0553_535f0119,           // Start of message block
    8'd3                                      // Difficulty offset 
  };
  // NOTE: using TARGET_OFFSET to provide zero check

  localparam [7:0] test_daisy_data0 = {
    8'h00 // nonce start (MSB) 
  };

  reg clk = 0;
  reg reset = 0;

  reg [255:0] sha_state;
  reg [95:0] message_head;
  reg [7:0] difficulty;
  reg [7:0] nonce_start_MSB;

  wire success;
  wire [31:0] nonce;

  reg [255:0] H_btc[0:2];

  // State (a,b,c,...) after first block of first hash
  initial H_btc[0] =
    { 128'hdc6a3b8d_0c69421a_cb1a5434_e536f7d5,
      128'hc3c1b9e4_4cbb9b8f_95f0172e_fc48d2df };

  // First (intermediate) hash value 
  initial H_btc[1] =
    { 128'h0fc3bf25_9405a32f_d6d78a5e_6de88914,
      128'h8edd4088_cc46a2eb_c604c45a_15fe7d15 };

  // Second (final) hash value 
  initial H_btc[2] =
    { 128'h766f7950_56dd74d7_03b9173e_8d44223b,
      128'hdbe3e0b2_9fe6a0eb_8ab33534_88c2565c };


  wire [15:0] difficulty_bm;

  difficulty_map dm (
    clk,
    reset,
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
    reset,
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
      sha_state = test_data0[360-1:360-256];
      message_head = test_data0[360-256-1:360-256-96];
      difficulty = test_data0[360-256-96-1:0];

      // Device configuration
      nonce_start_MSB = test_daisy_data0[7:0];

      #1 reset = 1;
      #1 clk = 1;
      #1 clk = 0;

      #1 reset = 0;
      #1 clk = 1;
      #1 clk = 0;

      for (n = 0; n < 50 && !success; n = n + 1)
        begin

          for (i = 0; i < 64; i = i + 1)
            begin

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

              #1 clk = 1;
              #1 clk = 0;
            end

        end

    end

endmodule // shapool_test
