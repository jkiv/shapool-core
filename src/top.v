/*
 * TODO redo documentation
 */
module top
(
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
  // READY flags
  ready_n_od_out,
  // Indicator LED
  status_led_n_out
);

    localparam DEVICE_CONFIG_WIDTH = 8;            // nonce_start
    localparam JOB_CONFIG_WIDTH    = 256 + 96 + 8; // sha_state + message_head + difficulty
    localparam RESULT_DATA_WIDTH   = 32;           // nonce

    localparam NONCE_WIDTH = 32 - POOL_SIZE_LOG2;

    parameter POOL_SIZE      = 2;
    parameter POOL_SIZE_LOG2 = 1;

    // Minimum difficulty, in number of leading zeros
    // -- minimum 64, maximum 240
    /*
      DIFFICULTY example:

        BTC difficulty = 4022059196164

        FLOOR(LOG2(0x00000000ffffffff...ffff / 4022059196164))
          = 182

        Therefore, 2^182 is nearest power-2 target less than the actual
        target and 74 (=256-182) leading zeros are required to be <= 2^182.
    */
    parameter BASE_DIFFICULTY = 64;

    // Inputs and Outputs

    input wire clk_in;

    input wire reset_n_in;

    input wire sck0_in;
    input wire sdi0_in;
    input wire cs0_n_in;

    input wire sck1_in;
    input wire sdi1_in;
    output wire sdo1_out;
    input wire cs1_n_in;

    output wire ready_n_od_out;

    output wire status_led_n_out;

    // Global reset(s)
    wire g_reset_n;
    wire g_core_reset_n;

`ifdef VERILATOR
    assign g_reset_n = reset_n_in;
    assign g_core_reset_n = reset_n_in & ~ready;
`else
    // Buffered external `reset_n`
    SB_GB reset_gbuf (
      .USER_SIGNAL_TO_GLOBAL_BUFFER(reset_n_in),
      .GLOBAL_BUFFER_OUTPUT(g_reset_n)
    );

    // Hold the core in a reset state when either the
    // external `reset_n` is low or `ready` is high.
    SB_GB core_reset_gbuf (
      .USER_SIGNAL_TO_GLOBAL_BUFFER(reset_n_in & ~ready),
      .GLOBAL_BUFFER_OUTPUT(g_core_reset_n)
    );
`endif

    // Device parameters
    //    * 8'  nonce starting count
    wire [7:0] nonce_start;
    
    //  Job parameters
    //    * 256' initial SHA256 state
    //    *  96' start of first message block
    //    *   8' difficulty adjustment
    wire [255:0] sha_state;
    wire [95:0] message_head;
    /* verilator lint_off UNUSED */
    wire [7:0] difficulty;
    /* verilator lint_on UNUSED */

    // Whether any unit on this device was successful
    wire success;

    // Whether or not to drive `ready_n_od_out` low (1) or keep high-impedance (0).
    wire ready;

    // Nonce result
    wire [31:0] nonce;

    // External IO interface
    external_io #(
      .DEVICE_CONFIG_WIDTH(DEVICE_CONFIG_WIDTH),
      .JOB_CONFIG_WIDTH(JOB_CONFIG_WIDTH),
      .RESULT_DATA_WIDTH(RESULT_DATA_WIDTH)
    ) ext_io (
      clk_in,
      g_reset_n,
      // SPI(0)
      sck0_in,
      sdi0_in,
      cs0_n_in,
      // SPI(1)
      sck1_in,
      sdi1_in,
      sdo1_out,
      cs1_n_in,
      // Stored data
      { nonce_start },
      { sha_state, message_head, difficulty },
      // From shapool
      nonce,
      success,
      // READY signal
      ready
    );

    // Difficulty bitmask lookup
    // -- host-provided value is number of zeros to _add_ to BASE_DIFFICULTY
    // -- convert 4-bit difficulty to 16-bit zeros mask (0-15 bits)
    // TODO make difficulty_bitmask 15 bits?
    wire [15:0] difficulty_bitmask;
    difficulty_map dm (
      .clk(clk_in),
      .en(1'b1),
      .addr(difficulty[3:0]),
      .difficulty(difficulty_bitmask)
    );

    // Hasher pool
    shapool
    #(.POOL_SIZE(POOL_SIZE),
      .POOL_SIZE_LOG2(POOL_SIZE_LOG2),
      .BASE_DIFFICULTY(BASE_DIFFICULTY))
    pool (
      // Control
      .clk(clk_in),
      .reset_n(g_core_reset_n),
      // Parameters
      .sha_state(sha_state),
      .message_head(message_head),
      .difficulty_bm(difficulty_bitmask),
      .nonce_start_MSB(nonce_start),
      // Results
      .success_out(success),
      .nonce_out(nonce)
    );

    assign ready_n_od_out = ready ? 1'b0 : 1'bz;

    assign status_led_n_out = reset_n_in & ~ready;

endmodule
