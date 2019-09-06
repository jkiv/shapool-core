module multitop_test();

  `define VERILATOR
  `define SHAPOOL_USE_NONCE_OFFSET

  reg clk = 0;
  reg reset = 0;

  reg data_clk = 0;
  reg data_in = 0;
  wire data_out_ts;

  reg daisy_sel = 0;
  reg daisy_in = 0;
  wire daisy_out;

  reg done_in = 0;
  wire done_out;
  wire success_inout_ts;

  wire status_led;
  wire success_led;

  localparam POOL_SIZE = 2;
  localparam POOL_SIZE_LOG2 = 1;

  localparam BASE_DIFFICULTY = 3;

  top
  #(.POOL_SIZE(POOL_SIZE),
    .POOL_SIZE_LOG2(POOL_SIZE_LOG2),
    .BASE_DIFFICULTY(BASE_DIFFICULTY))
  uut (
    clk,
    reset,
    // Global data
    data_clk,
    data_in,
    data_out_ts,
    // Daisy data
    daisy_sel,
    daisy_in,
    daisy_out,
    // Done flags
    done_in,
    done_out,
    // Success flags
    success_inout_ts,
    // Indicators
    status_led,
    success_led
  );

  // Test case

  reg [31:0] n = 0;
  reg [31:0] i = 0;

  localparam [359:0] test_data0 = {
    128'hdc6a3b8d_0c69421a_cb1a5434_e536f7d5, // SHA starting state
    128'hc3c1b9e4_4cbb9b8f_95f0172e_fc48d2df, // ...
    96'hdc141787_358b0553_535f0119,           // Start of message block
    8'd1                                      // Difficulty offset 
  };

  localparam [7:0] test_daisy_data0 = {
    8'h00 // nonce start (MSB) 
  };

  reg [7:0] test_daisy_data;
  reg [359:0] test_data;
  reg [31:0] result;

  initial
    begin

      test_daisy_data = test_daisy_data0;
      test_data = test_data0;

      #1 clk = 0;

      #1 reset = 1;
      #1 clk = 1;
      #1 clk = 0;

      ///////////////////////////////////
      // Clock-in device configuration //
      ///////////////////////////////////
 
      #1 reset = 1;
      #1 daisy_sel = 1;

      #1 clk = 1; // reset is synchronized with clk
      #1 clk = 0;

      for (i = 0; i < 8; i = i + 1)
        begin
          // Simulate shift-out FIFO 
          #1 daisy_in = test_daisy_data[0];
          #1 test_daisy_data = { 1'b0, test_daisy_data[7:1] };

          #1 data_clk = 1;
          // clk's not needed for transfer, but they'll be occurring
          #1 clk = 1;
          #1 clk = 0;
          #1 clk = 1;
          #1 clk = 0;
          // ...

          #1 data_clk = 0;
          // clk's not needed for transfer, but they'll be occurring
          #1 clk = 1;
          #1 clk = 0;
          #1 clk = 1;
          #1 clk = 0;
          // ...
        end

      /////////////////////////////
      // Clock-in job parameters //
      /////////////////////////////

      #1 reset = 1;
      #1 daisy_sel = 0;

      #1 clk = 1;
      #1 clk = 0;
     
      for (i = 0; i < 360; i = i + 1)
        begin
          // Simulate FIFO into device
          #1 data_in = test_data[0];
          #1 test_data = { 1'b0, test_data[359:1] };

          #1 data_clk = 1;
          // clk's not needed for transfer, but they'll be occurring
          #1 clk = 1;
          #1 clk = 0;
          #1 clk = 1;
          #1 clk = 0;
          // ...

          #1 data_clk = 0;
          // clk's not needed for transfer, but they'll be occurring
          #1 clk = 1;
          #1 clk = 0;
          #1 clk = 1;
          #1 clk = 0;
          // ...
        end

      $display("Device configuration");
      $display("  nonce start MSB: %h", uut.nonce_start);

      $display("Job parameters:");
      $display("  SHA256 state:  %h", uut.sha_state[255:128]);
      $display("                 %h", uut.sha_state[127:0]);
      $display("  message head:  %h", uut.message_head);
      $display("  difficulty:    %h", uut.difficulty);
      $display("  difficulty_bm: %h", uut.difficulty_bm);

      /////////////////////////////////
      // Reset and run until success //
      /////////////////////////////////

      #1 reset = 0;
      // Reset is synchronized with clock
      #1 clk = 1;
      #1 clk = 0;

      for (n = 0; n < 50 && !success_led; n = n + 1)
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
              $display("    test bits: %h", { uut.pool.tracks[0].H[BASE_DIFFICULTY+16-1:16], uut.pool.tracks[0].H[15:0] & uut.pool.difficulty_bm });
              $display("");

              #1 clk = 1;
              #1 clk = 0;
            end

        end

     // Extra clock to save output/result
     #1 clk = 1;
     #1 clk = 0;

     $display("top_test result_buffer:");
     $display("  nonce: %h", uut.result_buffer[31:0]);

     // Pull result
     for (i = 0; i < 32; i = i + 1)
       begin
         $display("[%d] (%b) %b", i, success_inout_ts, data_out_ts);

         // Simulate shift-in FIFO
         #1 result = { data_out_ts, result[31:1] };

         #1 data_clk = 1;
         #1 clk = 1;
         #1 clk = 0;
         #1 clk = 1;
         #1 clk = 0;
         // ...

         #1 data_clk = 0;
         #1 clk = 1;
         #1 clk = 0;
         #1 clk = 1;
         #1 clk = 0;
         // ...

       end

     $display("top_test result:");
     $display("  nonce: %d", result);

    end

endmodule
