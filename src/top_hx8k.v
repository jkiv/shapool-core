module top_hx8k
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
  ready_n_ts_out,
  // Indicators
  status_led_n_out
);

    // Making pool smaller to test / fit on HX8K
    `define SHAPOOL_NO_NONCE_OFFSET // Required for POOL_SIZE = 1

    parameter POOL_SIZE       = 1;
    parameter POOL_SIZE_LOG2  = 0;
    parameter BASE_DIFFICULTY = 64;

/*  Original HX8K pool setup:
    parameter POOL_SIZE       = 2;
    parameter POOL_SIZE_LOG2  = 1;
    parameter BASE_DIFFICULTY = 64;
*/

    // 12 MHz ~ 56.25 MHz
    parameter PLL_DIVR = 4'b0000;
    parameter PLL_DIVF = 7'b1001010;
    parameter PLL_DIVQ = 3'b100;

    // Multiply input clock signal using SB_PLL40_CORE
    wire g_clk;

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

    output wire ready_n_ts_out;

    output wire status_led_n_out;

    top #(
      .POOL_SIZE(POOL_SIZE),
      .POOL_SIZE_LOG2(POOL_SIZE_LOG2),
      .BASE_DIFFICULTY(BASE_DIFFICULTY)
    )
    u (
      g_clk,
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
      ready_n_ts_out,
      // Indicators
      status_led_n_out
    );

endmodule
