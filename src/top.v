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

    wire core_reset_n;
    wire g_core_reset_n;

`ifdef VERILATOR
    assign g_reset_n = reset_n_in;
    assign g_core_reset_n = core_reset_n;
`else
    // Buffered external `reset_n`
    SB_GB reset_gbuf (
      .USER_SIGNAL_TO_GLOBAL_BUFFER(reset_n_in),
      .GLOBAL_BUFFER_OUTPUT(g_reset_n)
    );

    // Hold the core in a reset state when either the
    // external `reset_n` is low or `ready` is high.
    SB_GB core_reset_gbuf (
      .USER_SIGNAL_TO_GLOBAL_BUFFER(core_reset_n),
      .GLOBAL_BUFFER_OUTPUT(g_core_reset_n)
    );
`endif

    // Device parameters
    //    * 8'  nonce starting count
    wire [7:0] device_config;
    wire [7:0] nonce_start;

    assign nonce_start = device_config[7:0];
    
    //  Job parameters
    wire [351:0] job_config;
    //    * 256' initial SHA256 state
    //    *  96' start of first message block
    wire [255:0] sha_state;
    wire [95:0] message_head;

    assign sha_state    = job_config[351:96];
    assign message_head = job_config[ 95: 0];

    // `shapool` results
    wire success;
    wire [31:0] nonce;
    wire [7:0] match_flags;

    // External READY flag (drives open-drain `ready_n_od_out`)
    wire ready;

    assign ready_n_od_out = ready ? 1'b0 : 1'bz;

    // External IO interface
    external_io #(
      .POOL_SIZE(POOL_SIZE),
      .POOL_SIZE_LOG2(POOL_SIZE_LOG2)
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
      device_config,
      job_config,
      // Control signals
      core_reset_n,
      // From shapool
      success,
      { match_flags, nonce },
      // READY signal
      ready
    );

    // Hasher pool
    shapool #(
      .POOL_SIZE(POOL_SIZE),
      .POOL_SIZE_LOG2(POOL_SIZE_LOG2),
      .BASE_DIFFICULTY(BASE_DIFFICULTY)
    )
    pool (
      // Control
      .clk(clk_in),
      .reset_n(g_core_reset_n),
      // Parameters
      .sha_state(sha_state),
      .message_head(message_head),
      .nonce_start_MSB(nonce_start),
      // Results
      .success(success),
      .nonce(nonce),
      .match_flags(match_flags)
    );

    assign status_led_n_out = ~(success | ready);

endmodule
