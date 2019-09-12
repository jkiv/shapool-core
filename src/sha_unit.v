module sha_unit(
  // Control
  clk,
  // Externally managed state
  round,
  Kt,
  // SHA256 parameters
  M,
  H0,
  // Result
  H1
);

  `define idx32(x) (32*(x+1)-1):(32*(x))

  input wire clk;

  input wire [5:0] round;
  input wire [31:0] Kt;

  input wire [511:0] M;
  input wire [255:0] H0;
  output wire [255:0] H1;

  reg [31:0] Wt = 0;
  reg [479:0] W = 0;
  wire [31:0] Wxt;

  // Message as 16x 32-bit blocks
  wire [31:0] Mt[0:15];

  reg [255:0] S0 = 0;
  wire [255:0] S1;

  w_expand wx(
    W[`idx32(16-2)],
    W[`idx32(16-7)],
    W[`idx32(16-15)],
    W[`idx32(16-16)],
    Wxt
  );

  sha_round sr(
    S0,
    Kt,
    Wt,
    S1
  );
 
  always @(posedge clk)
    begin
      if (round == 0)
        S0 <= H0;
      else
        S0 <= S1;
    end

  always @(posedge clk)
    begin
      Wt <= (round < 16) ? Mt[round[3:0]] : Wxt;
    end

  always @(posedge clk)
    begin
      W <= { Wt, W[479:32] };
    end

  assign H1[`idx32(7)] = S1[`idx32(7)] + H0[`idx32(7)];
  assign H1[`idx32(6)] = S1[`idx32(6)] + H0[`idx32(6)];
  assign H1[`idx32(5)] = S1[`idx32(5)] + H0[`idx32(5)];
  assign H1[`idx32(4)] = S1[`idx32(4)] + H0[`idx32(4)];
  assign H1[`idx32(3)] = S1[`idx32(3)] + H0[`idx32(3)];
  assign H1[`idx32(2)] = S1[`idx32(2)] + H0[`idx32(2)];
  assign H1[`idx32(1)] = S1[`idx32(1)] + H0[`idx32(1)];
  assign H1[`idx32(0)] = S1[`idx32(0)] + H0[`idx32(0)];

  assign Mt[ 0] = M[`idx32(15)];
  assign Mt[ 1] = M[`idx32(14)];
  assign Mt[ 2] = M[`idx32(13)];
  assign Mt[ 3] = M[`idx32(12)];
  assign Mt[ 4] = M[`idx32(11)];
  assign Mt[ 5] = M[`idx32(10)];
  assign Mt[ 6] = M[`idx32( 9)];
  assign Mt[ 7] = M[`idx32( 8)];
  assign Mt[ 8] = M[`idx32( 7)];
  assign Mt[ 9] = M[`idx32( 6)];
  assign Mt[10] = M[`idx32( 5)];
  assign Mt[11] = M[`idx32( 4)];
  assign Mt[12] = M[`idx32( 3)];
  assign Mt[13] = M[`idx32( 2)];
  assign Mt[14] = M[`idx32( 1)];
  assign Mt[15] = M[`idx32( 0)];

endmodule
