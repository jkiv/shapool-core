/* top
 *
 * Manages input/output data for the device and sets up shapool.
 *
 * Data can be loaded into the device via both "data_in", a global MOSI with no
 * chip select, or "daisy_in", a FIFO buffer from device-to-device. Both are
 * stored on the positive edge of data_clk. Data will only be accepted into
 * these buffers while "reset" is high. The flag "daisy_sel" is used to select
 * whether "data_clk" shifts "data_in" into the job parameters buffer
 * ("daisy_sel" is low) or shifts "daisy_in" into the device configuration
 * buffer ("daisy_sel" is high).
 *
 * Since the ICE40 devices are programmed over SPI, the SPI infrustructure is
 * already present on the board and can be repurposed after programming.
 * The daisy-chained FIFO is included to allow devices to have unique
 * parameters without the need for per-device chip selects or unnecessary
 * addressing schemes.
 *
 * The global SPI interface provides all devices with the same frequently-
 * changing job data. Job data can be sent to each device quickly over the
 * global SPI line via "data_in" and "data_clk" while "reset" is high and
 * "daisy_sel" is low.
 *
 * The job parameters buffer is structured like so:
 *
 *   bit 359             103              7 
 *         | SHA-256 state | message head | difficulty offset |
 *
 * where "SHA-256 state" (256 bits) is the SHA-256 state after the  first block
 * of the first hash has been processed, "message head" (96 bits) is the start
 * of the second message block of the first hash up to and not including the
 * nonce value, and "difficulty offset" is the number of leading zeros to test
 * in addition to BASE_DIFFICULTY.
 *
 * The problem difficulty is defined here as the number of leading zeros to
 * test a hash against. BASE_DIFFICULTY specifies the minimum number of
 * leading zeros to test. The job parameter "difficulty offset" (0-15)
 * allows the host to add more zeros to test without having to change
 * BASE_DIFFICULTY, re-route/place, and reflash the device.
 *
 * Data can be read from the device via "data_out_ts", the global MISO, and
 * "data_clk". If and when a successful nonce is found, the device will pull
 * "success_inout_ts" high, and take control of the "data_out_ts" line.
 * The data can then be clocked out onto "data_out_ts" on the positive edge of
 * "data_clk". While a successful nonce has not been found, the device will
 * keep "success_inout_ts" in a high-impedence state.
 *
 * The data format for the result is as follows:
 *
 *   bit 31               0
 *        | winning nonce |
 *
 * In order to save resources, the "winning nonce" is not exactly the winning
 * nonce. First, it is the value of the nonce before any per-unit manipulation
 * has been applied, so the host application must check each potential nonce to
 * determine which was successful. Second, due to pipelining, the value
 * returned to the host is larger than the value that caused the successful
 * hash by a value of 1, so the host needs to subtract 1 from the returned
 * value. (NOTE: The byte-order here may differ than that on some host
 * platforms, so "nonce - 1" may require an initial byte-swap.)
 *
 * The daisy-chained FIFO is used for device configuration data, allowing each
 * device to be configured with unique parameters without the need for a chip 
 * select or an addressing scheme. The daisy-chain FIFO is read in via
 * "daisy_in" on the positive edge of "data_clk" while "reset" is high and
 * "daisy_sel" is high.
 *
 * The data format for the daisy-chained FIFO is as follows:
 *
 *   bit  7             0
 *        | nonce start |
 *
 * Nonce start is an 8-bit value that defines the most-significant 8-bits of
 * a 32-bit nonce starting value, for all units on the device. This allows the
 * host to partition the nonce search space across all devices into at most
 * 256 slices.
 *
 * TODO Allow host device to enumerate devices by sending 00...01 through
 *      daisy chain, until 1 appears back at host process. Dividing number of
 *      bits sent by the total size of the FIFO buffer on each device. Requires
 *      hardware support.
 *
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
  // Success flags
  ready_n_ts_inout,
  // Indicators
  status_led_n_out
);

    localparam DEVICE_CONFIG_WIDTH = 8; // nonce_start
    localparam JOB_CONFIG_WIDTH = 256 + 96 + 8; // sha_state + message_head + difficulty
    localparam RESULT_DATA_WIDTH = 32; // nonce

    localparam NONCE_WIDTH = 32 - POOL_SIZE_LOG2;

    parameter POOL_SIZE      = 2;
    parameter POOL_SIZE_LOG2 = 1;

    // Minimum difficulty, in number of leading zeros
    // -- minimum 64, maximum 240
    parameter BASE_DIFFICULTY = 64;

    /*
      DIFFICULTY example:

        BTC difficulty = 4022059196164

        FLOOR(LOG2(0x00000000ffffffff...ffff / 4022059196164))
          = 182

        Therefore, 2^182 is nearest power-2 target less than the actual
        target and 74 (=256-182) leading zeros are required to be <= 2^182.
    */

    // PLL parameters: 12MHz to 48MHz
    parameter PLL_DIVR = 4'b0000;
    parameter PLL_DIVF = 7'b0111111;
    parameter PLL_DIVQ = 3'b100;

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

    inout wire ready_n_ts_inout;

    output wire status_led_n_out;

    // Global clock signal

    wire g_clk;

`ifdef VERILATOR

    assign g_clk = clk_in;

`else

    /* verilator lint_off UNUSED */
    wire pll_locked;
    /* verilator lint_on UNUSED */

    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .DIVR(PLL_DIVR),
        .DIVF(PLL_DIVF),
        .DIVQ(PLL_DIVQ),
        .FILTER_RANGE(3'b001)
    ) uut (
        .LOCK(pll_locked),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(clk_in),
        //.PLLOUTCORE(g_clk)
        .PLLOUTGLOBAL(g_clk)
    );

    /*
    // Use ICE40 GBUF fabric
    SB_GB clk_gbuf (
      .USER_SIGNAL_TO_GLOBAL_BUFFER(clk_in),
      .GLOBAL_BUFFER_OUTPUT(g_clk)
    );
    */

`endif

    // Global reset
    wire g_reset_n;

`ifdef VERILATOR
    assign g_reset_n = reset_n_in;
`else
    // Use ICE40 GBUF fabric
    SB_GB reset_gbuf (
      .USER_SIGNAL_TO_GLOBAL_BUFFER(reset_n_in),
      .GLOBAL_BUFFER_OUTPUT(g_reset_n)
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
    wire [7:0] difficulty;

    // External IO interface
    external_io #(
      .DEVICE_CONFIG_WIDTH(DEVICE_CONFIG_WIDTH),
      .JOB_CONFIG_WIDTH(JOB_CONFIG_WIDTH),
      .RESULT_DATA_WIDTH(RESULT_DATA_WIDTH),
      .SHAPOOL_RESULT_WIDTH(NONCE_WIDTH)
    ) ext_io (
      .clk(g_clk),
      .reset_n(g_reset_n),
      // SPI(0)
      .sck0(sck0_in),
      .sdi0(sdi0_in),
      .cs0_n(cs0_n_in),
      // SPI(1)
      .sck1(sck1_in),
      .sdi1(sdi1_in),
      .sdo1(sdo1_out),
      .cs1_n(cs1_n_in),
      // Stored data
      .device_config({ nonce_start }),
      .job_config({ sha_state, message_head, difficulty }),
      // From shapool
      .shapool_result(nonce),
      .shapool_success(success) // .shapool_success(~ready_n_ts_inout | success)
    );

    // Difficulty bitmask lookup
    // -- host-provided value is no. of zeros to add to BASE_DIFFICULTY
    // -- convert 4-bit difficulty to 16-bit zeros mask
    wire [15:0] difficulty_bitmask;
    difficulty_map dm (
      g_clk,
      ~g_reset_n, // en
      difficulty[3:0],
      difficulty_bitmask
    );

    // Whether any unit on this device was successful
    wire success;

    // Nonce result
    wire [NONCE_WIDTH-1:0] nonce;

    // Hasher pool
    shapool
    #(.POOL_SIZE(POOL_SIZE),
      .POOL_SIZE_LOG2(POOL_SIZE_LOG2),
      .BASE_DIFFICULTY(BASE_DIFFICULTY))
    pool (
      // Control
      g_clk,
      g_reset_n,
      // Parameters
      sha_state,
      message_head,
      difficulty_bitmask,
      nonce_start,
      // Results
      success,
      nonce
    );

    assign ready_n_ts_inout = success ? 1'b0 : 1'bz;

    assign status_led_n_out = !((!cs0_n_in | !cs1_n_in) & (sck0_in | sck1_in)); // Blink on SPI(0) or SPI(1)

endmodule
