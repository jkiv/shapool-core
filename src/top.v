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
  hwclk,
  reset_in,
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

    parameter POOL_SIZE      = 2;
    parameter POOL_SIZE_LOG2 = 1;

    localparam NONCE_WIDTH = 32 - POOL_SIZE_LOG2;

    // Minimum difficulty, in number of leading zeros
    // -- minimum 64, maximum 240
    parameter BASE_DIFFICULTY = 64; // TODO set from yosys
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

    /* Inputs and outputs
     */

    input wire hwclk;
    input wire reset_in;

    input wire data_clk;
    input wire data_in;
    output wire data_out_ts;

    input wire daisy_sel;
    input wire daisy_in;
    output wire daisy_out;

    input wire done_in;
    output wire done_out;

    inout wire success_inout_ts;

    output reg status_led = 0;
    output wire success_led;

    // Support for done/out of work in pinout
    reg done = 0;
    assign done_out = done & done_in;

    reg success = 0;
    assign success_led = success;

    wire data_out;

    /* verilator lint_off UNUSED */
    wire success_in;
    /* verilator lint_on UNUSED */

    // Global clock signal

    //wire clk;
    wire g_clk;

`ifdef ICE40

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
        .REFERENCECLK(hwclk),
        //.PLLOUTCORE(g_clk)
        .PLLOUTGLOBAL(g_clk)
    );

`elsif MACHX03

	// TODO PLL
    assign g_clk = hwclk;

`else

	// No clock scaling
    assign g_clk = hwclk;

`endif

    // Global reset
    reg reset = 0;
    wire g_reset;

`ifdef ICE40

    // Use ICE40 GBUF fabric
    SB_GB reset_gbuf (
      .USER_SIGNAL_TO_GLOBAL_BUFFER(reset | success),
      .GLOBAL_BUFFER_OUTPUT(g_reset)
    );

`else

    assign g_reset = reset | success;

`endif

    // Result buffer (32 bits)
    // * 32' winning nonce
    localparam RESULT_BUFFER_WIDTH = 32;
    reg[RESULT_BUFFER_WIDTH-1:0] result_buffer = 0;

    assign data_out = result_buffer[0];

    // Prevent extra writes to data_out_ts on clk while data_clk is high
    reg lock_tx = 0;

    // Device parameters
    //    * 8'  nonce starting count
    reg [7:0] nonce_start = 0;
    
    //  Job parameters
    //    * 256' initial SHA256 state
    //    * 96'  start of first message block
    //    *  8'  difficulty adjustment
    reg [255:0] sha_state = 0;
    reg [95:0] message_head = 0;
    reg [7:0] difficulty = 0;

    wire [15:0] difficulty_bm;

    // Difficulty bitmask lookup
    // -- host-provided value is no. of zeros to add to BASE_DIFFICULTY
    // -- convert 4-bit difficulty to 16-bit zeros mask
    difficulty_map dm (
      g_clk,
      g_reset,
      difficulty[3:0],
      difficulty_bm
    );

    assign daisy_out = difficulty[0];

    // Whether any unit on this device was successful
    wire success_here;

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
      g_reset,
      // Parameters
      sha_state,
      message_head,
      difficulty_bm,
      nonce_start,
      // Results
      success_here,
      nonce
    );

    /* Tri-state pin setup
     */

`ifdef ICE40
    // SB_IO for tri-stated data_out_ts

	SB_IO #(.PULLUP(1'b0),
            .PIN_TYPE(6'b101001))
    sbio_data_out (
       .OUTPUT_ENABLE(~success),
       .PACKAGE_PIN(data_out_ts),
       .D_OUT_0(data_out)
    );

`else 

    assign data_out_ts = (success) ? data_out : 1'bz;    

`endif

`ifdef ICE40

    // SB_IO for tri-stated success_inout_ts / success_in
    SB_IO #(.PULLUP(1'b0),
            .PIN_TYPE(6'b101001))
    sbio_success_out (
       .OUTPUT_ENABLE(~success),
       .PACKAGE_PIN(success_inout_ts),
       .D_OUT_0(success),
       .D_IN_0(success_in)
    );

`else

    assign success_inout_ts = (success) ? 1'b1 : 1'bz;
    assign success_in = 0;

`endif

    /* Control
     */

    always @(posedge g_clk)
      begin
        // Synchronize reset with clk
        reset <= reset_in;
      end

    always @(posedge data_clk)
      begin
        if (reset && !daisy_sel)
          begin
            // Shift in job parameters
            sha_state <= { data_in, sha_state[255:1] };
            message_head <= { sha_state[0], message_head[95:1] };
            difficulty <= { message_head[0], difficulty[7:1] };
          end
      end

    always @(posedge data_clk)
      begin
        if (reset && daisy_sel)
          begin
            // Shift in device configuration
            nonce_start <= { daisy_in, nonce_start[7:1] };
          end
      end

    always @(posedge g_clk)
      begin
        if (!success && success_here)
          begin
            // Load result buffer when success_here goes high
            /* verilator lint_off WIDTHCONCAT */
            result_buffer <= {
              // NOTE: The top POOL_SIZE_LOG2 bits are zeroed.
              //       Host needs to perform check on all possible combination
              //       of these bits.
              {(32-NONCE_WIDTH){1'b0}},
              // NOTE: Success occurred a previous nonce.
              //       By the time nonce is saved, the hash is for the value
              //       of nonce - 1. In order to save resources, the host is
              //       responsible for correcting this offset. 
              nonce
            };
            /* verilator lint_on WIDTHCONCAT */
          end
        else if (success && data_clk && !lock_tx)
          begin
            // Shift out LSB of result
            result_buffer <= { 1'b0, result_buffer[RESULT_BUFFER_WIDTH-1:1] };
          end
      end

    always @(posedge g_clk)
      begin
        if (reset)
          success <= 0;
        else if (success_here && !success_in)
          success <= 1;
      end

    always @(posedge g_clk)
      begin
        // Avoid shifting on clk more than once when data_clk goes high
        if (success)
          lock_tx <= data_clk;
      end

endmodule
