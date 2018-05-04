module top_tri
(
  hwclk,
  LEDs
);

  input wire hwclk;
  output wire [7:0] LEDs;

  // Output counter or high-Z depending on counter state

  localparam LED_OFFSET = 8; // Increase value to slow down LED output

  reg [LED_OFFSET+8:0] counter = 0;

  wire en;

  assign en = counter[LED_OFFSET+8];

  genvar i;
  generate
    for (i = 0; i < 8; i++)
      begin
        SB_IO #(.PULLUP(1'b0),
                .PIN_TYPE(6'b101001))
        sbio_data_out (
           .OUTPUT_ENABLE(~en),
           .PACKAGE_PIN(LEDs[i]),
           .D_OUT_0(counter[i + LED_OFFSET]),
        );
      end

  always @(posedge hwclk)
    begin
      counter <= counter + 1;
    end

endmodule
