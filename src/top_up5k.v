module top_up5k
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
  ready_n_od_out,
  // Indicators
  status_led_n_out
);

    `define SHAPOOL_NO_NONCE_OFFSET // Required for POOL_SIZE = 1

    parameter POOL_SIZE       = 1;
    parameter POOL_SIZE_LOG2  = 0;
    parameter BASE_DIFFICULTY = 64;

    // 12 MHz ~ 56.25 MHz
    parameter PLL_DIVR = 4'b0000;
    parameter PLL_DIVF = 7'b1001010;
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

    output wire ready_n_od_out;

    output wire status_led_n_out;

    top #(
      .POOL_SIZE(POOL_SIZE),
      .POOL_SIZE_LOG2(POOL_SIZE_LOG2),
      .BASE_DIFFICULTY(BASE_DIFFICULTY),
      .PLL_DIVR(PLL_DIVR),
      .PLL_DIVF(PLL_DIVF),
      .PLL_DIVQ(PLL_DIVQ)
    )
    u (
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
      ready_n_od_out,
      // Indicators
      status_led_n_out
    );

endmodule