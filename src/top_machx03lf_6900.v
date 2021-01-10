`define MACHXO3

module top_machx03lf_6900
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

    parameter POOL_SIZE       = 2;
    parameter POOL_SIZE_LOG2  = 1;
    parameter BASE_DIFFICULTY = 64;

    // 12 MHz ~ 56.25 MHz
    parameter PLL_DIVR = 4'b0000;
    parameter PLL_DIVF = 7'b1001010;
    parameter PLL_DIVQ = 3'b100;

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

    output wire status_led;
    output wire success_led;

    top #(
      .POOL_SIZE(POOL_SIZE),
      .POOL_SIZE_LOG2(POOL_SIZE_LOG2),
      .BASE_DIFFICULTY(BASE_DIFFICULTY),
      .PLL_DIVR(PLL_DIVR),
      .PLL_DIVF(PLL_DIVF),
      .PLL_DIVQ(PLL_DIVQ)
    )
    u (
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

endmodule
