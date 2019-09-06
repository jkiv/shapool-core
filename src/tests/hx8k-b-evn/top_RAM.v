module top_RAM
(
  hwclk,
  LEDs
);

  input wire hwclk;
  output wire [7:0] LEDs;

  /* Very slow clock */

  localparam CLK_DIV_WIDTH = 16;

  reg [CLK_DIV_WIDTH-1:0] clk_cnt;

  wire clk;
  assign clk = clk_cnt[CLK_DIV_WIDTH-1];

  always @(posedge hwclk)
    begin
      clk_cnt <= clk_cnt + 1;
    end

  
  /* Read MSB of Kt and output to on-board LEDs */

  reg [5:0] round = 0;
  wire [31:0] Kt;

  SHA256_K_mem uut (
    clk,
    round,
    Kt
  );

  always @(posedge clk)
    begin
      round <= round + 1;
    end

  assign LEDs = Kt[31:24];

endmodule
