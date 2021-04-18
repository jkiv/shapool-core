`timescale 10ns/100ps

module sha_round_usage_tb();

  /*
    Tests basic usage of `sha_round`.

    * `sha_round` is a concurrent module.
    * Testing that the output is correct for known inputs.
  */
  
  `define VERILATOR
  `define DEBUG_VERBOSE

  localparam NUMBER_OF_CASES = 3;
  reg [255:0] S0_case [0:NUMBER_OF_CASES-1];
  reg [31:0] Kt_case [0:NUMBER_OF_CASES-1];
  reg [31:0] Wt_case [0:NUMBER_OF_CASES-1];
  reg [255:0] S1_expected [0:NUMBER_OF_CASES-1];

  reg [255:0] S0;
  reg [31:0] Kt;
  reg [31:0] Wt;
  wire [255:0] S1;

  sha_round uut (
    .in(S0),
    .Kt(Kt),
    .Wt(Wt),
    .out(S1)
  );

  reg [1:0] i = 0;

  initial
    begin
      // Set up case data

      // Case 0
      S0_case[0] <= 256'h6a09e667_bb67ae85_3c6ef372_a54ff53a_510e527f_9b05688c_1f83d9ab_5be0cd19;
      Kt_case[0] <= 32'h428a2f98;
      Wt_case[0] <= 32'h61626380;
      S1_expected[0] <= 256'h5d6aebcd_6a09e667_bb67ae85_3c6ef372_fa2a4622_510e527f_9b05688c_1f83d9ab;

      // Case 1
      S0_case[1] <= 256'h04d24d6c_b85e2ce9_b6ae8fff_ffb70472_948d25b6_961f4894_b21bad3d_6d83bfc6;
      Kt_case[1] <= 32'hbef9a3f7;
      Wt_case[1] <= 32'heeaba2cc;
      S1_expected[1] <= 256'hd39a2165_04d24d6c_b85e2ce9_b6ae8fff_fb121210_948d25b6_961f4894_b21bad3d;

      // Case 2
      S0_case[2] <= 256'b0;
      Kt_case[2] <= 256'b0;
      Wt_case[2] <= 256'b0;
      S1_expected[2] <= 256'b0;

      for (i = 0; i < NUMBER_OF_CASES; i = i + 1)
        begin
          S0 <= S0_case[i];
          Kt <= Kt_case[i];
          Wt <= Wt_case[i];
          #1;

          if (S1 == S1_expected[i])
            begin
              $display("\033\133\063\062\155[PASS]\033\133\060\155 `sha_round`, case %0d", i);
              $display("       S0            = %h", S0[255:128]);
              $display("                       %h", S0[127:  0]);
              $display("       Kt            = %h", Kt);
              $display("       Wt            = %h", Wt);
              $display("");
              $display("       S1 (actual)   = %h", S1[255:128]);
              $display("                       %h", S1[127:  0]);
              $display("       S1 (expected) = %h", S1_expected[i][255:128]);
              $display("                       %h", S1_expected[i][127:  0]);
              $display("");
            end
          else
            begin
              $display("\n\033\133\063\061\155[FAIL]\033\133\060\155 `sha_round`, case %0d", i);
              $display("       S0            = %h", S0[255:128]);
              $display("                       %h", S0[127:  0]);
              $display("       Kt            = %h", Kt);
              $display("       Wt            = %h", Wt);
              $display("");
              $display("       S1 (actual)   = %h", S1[255:128]);
              $display("                       %h", S1[127:  0]);
              $display("       S1 (expected) = %h", S1_expected[i][255:128]);
              $display("                       %h", S1_expected[i][127:  0]);
              $display("");

              $error("Test case failed.");
            end

        end
      
      $finish;
    end
 
endmodule
