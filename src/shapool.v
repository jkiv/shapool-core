/* shapool
 */
module shapool
(
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
    parameter POOL_SIZE = 1;
    parameter POOL_SIZE_LOG2 = 0;
    parameter BASE_DIFFICULTY = 64;
    
    // How big of a counter for `nonce` do we need?
    localparam NONCE_WIDTH = 32 - POOL_SIZE_LOG2;

    /* Inputs/Outputs
     */

    input wire clk;
    input wire reset_n;

    // Job parameters
    input wire [255:0] sha_state;
    input wire [95:0] message_head;
    input wire [15:0] difficulty_bm;
    input wire [7:0] nonce_start_MSB;

    // Job results
    output wire success;
    output reg [NONCE_WIDTH-1:0] nonce = 0;

    // Expand `nonce_start_MSB` to same size as `nonce`
    wire [NONCE_WIDTH-1:0] nonce_start;
    assign nonce_start = { nonce_start_MSB, {(NONCE_WIDTH-8){1'b0}} };

    // Per-unit match flags
    wire [POOL_SIZE-1:0] match_flags;

    /* State
     */

    reg [5:0] round = 0;

    // Supress some logic during first and second hash
    // - `first_hash_complete` allows us to supress logic before first hash completes.
    // - `second_hash_complete` allows us to supress logic before second hash completes.
    reg first_hash_complete = 0;
    reg second_hash_complete = 0;

    localparam[255:0] SHA256_H0 = 
    { 32'h6a09e667, 32'hbb67ae85,
      32'h3c6ef372, 32'ha54ff53a,
      32'h510e527f, 32'h9b05688c,
      32'h1f83d9ab, 32'h5be0cd19 };

    wire [31:0] Kt;

    SHA256_K K (
      clk,
      round,
      Kt
    );

    localparam [383:0] M0_tail = {
        128'h80000000_00000000_00000000_00000000,
        128'h00000000_00000000_00000000_00000000,
        128'h00000000_00000000_00000000_00000280
    };

    localparam [255:0] M1_tail = {
        128'h80000000_00000000_00000000_00000000,
        128'h00000000_00000000_00000000_00000100
    };

    genvar n;
    generate
      for (n = 0; n < POOL_SIZE; n = n + 1)
        begin : tracks 

        // Hash outputs
        wire [255:0] H_u0;
        wire [255:0] H_u1;

        // Saved bits from H_u0
        reg [223:0] M1_H1;

        // Byte-swapped H_u1 for testing
        /* verilator lint_off UNUSED */
        wire [255:0] H_u1_swap;
        /* verilator lint_on UNUSED */

        wire [BASE_DIFFICULTY+16-1:0] H_test_bits;

`ifndef SHAPOOL_NO_NONCE_OFFSET
        // Hard-coded unit offset
        // -- reduces size of nonce register and increment logic
        // -- POOL_SIZE must be a power of 2
        // -- POOL_SIZE_LOG2 must be > 0
        wire [POOL_SIZE_LOG2-1:0] nonce_offset; 
        assign nonce_offset = n;
`endif

        // Nonce space segmenting issues arise when not all devices
        // have the same `POOL_SIZE`/`POOL_SIZE_LOG2`.
        // TODO address later?
        // TODO currently, they will. (same bitstream)

        // 32-bit nonce:
        // [nonce_offset (POOL_SIZE_LOG 2)][nonce_start (NONCE_WIDTH)]

        // SHA256 unit for first hash
        sha_unit u0(
          clk,
          round,
          Kt,
          { message_head,
            // Byte-swap nonce
            nonce[ 7: 0],
            nonce[15: 8],
            nonce[23:16],
`ifndef SHAPOOL_NO_NONCE_OFFSET
            nonce_offset,
`endif
            nonce[NONCE_WIDTH-1:24],
            M0_tail
          },
          sha_state,
          H_u0
        );

        // Save `H_u0` (output of first stage) for use in `M1_H1`.
        // Bits `H_u0[255:224]` are used by `u1` at the same moment and sent directly to input,
        // so we don't need to store them in M1_H1.
        always @(posedge clk)
          begin
            if (round == 0)
              M1_H1 <= H_u0[223:0];
          end

        // SHA256 unit for second hash
        sha_unit u1(
          clk,
          round,
          Kt,
          // `H_u0[255:224]` is needed as soon as it is available, when `round`
          // goes from `0` to `1`. At the same instant, the rest of `H_u0` is stored
          // in `M1_H1` for use in subsequent rounds.
          { H_u0[255:224], M1_H1, M1_tail },
          SHA256_H0,
          H_u1
        );

        // Byte-swap hash result for valid comparison
        // -- Depending on difficulty, lower bits may not be used. Hopefully
        //    logic for generating superfluous bits are optimized out.
        assign H_u1_swap = { H_u1[  7:  0], H_u1[ 15:  8], H_u1[ 23: 16], H_u1[ 31: 24],
                             H_u1[ 39: 32], H_u1[ 47: 40], H_u1[ 55: 48], H_u1[ 63: 56],
                             H_u1[ 71: 64], H_u1[ 79: 72], H_u1[ 87: 80], H_u1[ 95: 88],
                             H_u1[103: 96], H_u1[111:104], H_u1[119:112], H_u1[127:120],
                             H_u1[135:128], H_u1[143:136], H_u1[151:144], H_u1[159:152],
                             H_u1[167:160], H_u1[175:168], H_u1[183:176], H_u1[191:184],
                             H_u1[199:192], H_u1[207:200], H_u1[215:208], H_u1[223:216],
                             H_u1[231:224], H_u1[239:232], H_u1[247:240], H_u1[255:248] };

        // Bits of result we care about
        assign H_test_bits = {
          // bits from BASE_DIFFICULTY
          H_u1_swap[255:256-BASE_DIFFICULTY],
          // bits from `difficulty` parameter
          H_u1_swap[256-BASE_DIFFICULTY-1:256-BASE_DIFFICULTY-16] & difficulty_bm
        };

        // Test leading zeros only
        // -- higher difficulty
        // -- simpler implementation
        assign match_flags[n] = ~(|H_test_bits);

      end
    endgenerate

    // Generate `success` flag from the set of `match_flag`s
    assign success = (|match_flags) & second_hash_complete & (round == 0);

    // Control `first_hash_complete` flag
    always @(posedge clk, negedge reset_n)
      begin
        if (!reset_n)
          first_hash_complete <= 0;
        else if (round == 63 && !first_hash_complete)
          first_hash_complete <= 1;
      end

    // Control `second_hash_complete` flag
    always @(posedge clk, negedge reset_n)
      begin
        if (!reset_n)
          second_hash_complete <= 0;
        else if (round == 63 && first_hash_complete)
          second_hash_complete <= 1;
      end

    // Control `round`
    always @(posedge clk, negedge reset_n)
      begin
        if (!reset_n)
          round <= 0;
        else
          round <= round + 1; // mod 63 
      end
  
    // Control `nonce`
    always @(posedge clk, negedge reset_n)
      begin
        if (!reset_n)
          nonce <= nonce_start;
        else if (round == 0)
          nonce <= nonce + 1;
      end
  
endmodule
