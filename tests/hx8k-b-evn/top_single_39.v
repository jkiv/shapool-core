module top_single_39
(
  hwclk,
  LEDs
);

    `define SHAPOOL_NO_NONCE_OFFSET

    parameter POOL_SIZE      = 1;
    parameter POOL_SIZE_LOG2 = 0;

    parameter BASE_DIFFICULTY = 1;

    localparam NONCE_WIDTH = 32 - POOL_SIZE_LOG2;

    /* Inputs and outputs
     */

    input wire hwclk;

    output wire [7:0] LEDs;

    assign LEDs = result[7:0];

    wire clk;

    pll shapool_pll(
      hwclk,
      clk
    );

    // Whether any unit on this device was successful
    wire success_here;

    reg reset_b = 0;
    reg success = 0;

    // Nonce result
    wire [NONCE_WIDTH-1:0] nonce;

    reg [NONCE_WIDTH-1:0] result;

    // Device parameters
    //    * 8'  nonce starting count

    localparam [7:0] nonce_start = 8'h00;
    
    //  Job parameters
    //    * 256' initial SHA256 state
    //    * 96'  start of first message block

    localparam [255:0] sha_state =
      { 128'hdc6a3b8d_0c69421a_cb1a5434_e536f7d5,
        128'hc3c1b9e4_4cbb9b8f_95f0172e_fc48d2df };

    localparam [95:0] message_head = 96'hdc141787_358b0553_535f0119;

    localparam [7:0] difficulty = 8'd3;

    difficulty_map dm (
      clk,
      reset,
      difficulty,
      difficulty_bm
    );

    // Hasher pool
    shapool
    #(.POOL_SIZE(POOL_SIZE),
      .POOL_SIZE_LOG2(POOL_SIZE_LOG2),
      .BASE_DIFFICULTY(BASE_DIFFICULTY))
    pool (
      // Control
      clk,
      ~reset_b | success,
      // Parameters
      sha_state,
      message_head,
      difficulty_bm,
      nonce_start,
      // Results
      success_here,
      nonce
    );

  always @(posedge clk)
    begin
      if (success_here)
        success <= 1'b1;
    end

  always @(posedge clk)
    begin
      reset_b <= 1;
    end

  always @(posedge clk)
    begin
      if (success_here)
        result <= nonce;
    end

endmodule
