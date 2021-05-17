module top
(
  clk_in,
  status_led_n_out
);

  input wire clk_in;
  output wire status_led_n_out;

  parameter counter_msb = 23;

  reg [counter_msb:0] counter = 0;

  always @(posedge clk_in)
    begin
        counter <= counter + 1;
    end

  assign status_led_n_out = counter[counter_msb];

endmodule
