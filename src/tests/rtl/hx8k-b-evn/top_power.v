module top_power
(
  hwclk,
  LEDs
);

    // HX8K-B-EVN
    parameter POOL_SIZE = 2;
    parameter POOL_SIZE_LOG2 = 1;
    parameter BASE_DIFFICULTY = 240;

    localparam NONCE_WIDTH = 32 - POOL_SIZE_LOG2;

    /* Inputs and outputs
     */

    input wire hwclk;

    output wire [7:0] LEDs;
    
    assign LEDs[7] = success_here;
    assign LEDs[6:0] = nonce[31-:7];

    /* State
     */

    wire clk;

    pll shapool_pll (
      hwclk,
      clk
    );

    reg reset_b = 0;

    // Device parameters
    //    * 8'  nonce starting count
    reg [7:0] nonce_start = 0;
    
    //  Job parameters
    //    * 256' initial SHA256 state
    //    * 96'  start of first message block
    reg [255:0] sha_state = 0; 
    reg [95:0] message_head = 0;

    // Whether any unit on this device was successful
    wire success_here;

    // Nonce result
    wire [NONCE_WIDTH-1:0] nonce;

    // Hasher pool
    shapool
    #(.POOL_SIZE(POOL_SIZE),
      .POOL_SIZE_LOG2(POOL_SIZE_LOG2),
      .DIFFICULTY(DIFFICULTY))
    pool (
      // Control
      clk,
      ~reset_b,
      // Parameters
      sha_state,
      message_head,
      nonce_start,
      // Results
      success_here,
      nonce
    );

    /* Control
     */

    always @(posedge clk)
      begin
        reset_b <= 1;
      end

endmodule
