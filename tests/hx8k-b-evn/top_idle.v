module top_idle
(
  hwclk,
  LEDs
);

  input wire hwclk;

  output wire [7:0] LEDs;

  assign LEDs = 8'b1100_0000;
  // 8 bits of 32 = 2 bits of 8

endmodule
