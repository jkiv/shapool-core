`timescale 10ns/100ps

module sha_unit_usage_tb();

  /*
    Tests basic usage of `sha_unit`.

     Uses "FIPS single-block" example: "abc".
  */
  
  reg [511:0] M_fips1 =
    { 128'h61626380_00000000_00000000_00000000,
      128'h00000000_00000000_00000000_00000000, 
      128'h00000000_00000000_00000000_00000000, 
      128'h00000000_00000000_00000000_00000018 };

  reg[255:0] H_fips1 =
    { 128'hba7816bf_8f01cfea_414140de_5dae2223,
      128'hb00361a3_96177a9c_b410ff61_f20015ad };

  `define VERILATOR
  `define DEBUG_VERBOSE

  // SHA256 constants
  // TODO was reg[0:255]
  reg [255:0] SHA256_H0 = { 32'h6a09e667, 32'hbb67ae85,
                            32'h3c6ef372, 32'ha54ff53a,
                            32'h510e527f, 32'h9b05688c,
                            32'h1f83d9ab, 32'h5be0cd19 };

  // TODO use SHA256_K.v
  localparam[2047:0] SHA256_K =
    { 32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5,
      32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
      32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3,
      32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
      32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc,
      32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,
      32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7,
      32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,
      32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13,
      32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,
      32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3,
      32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,
      32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5,
      32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,
      32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208,
      32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2 }; 

  wire [31:0] K[0:63];

  assign K[ 0] = SHA256_K[2047:2016];
  assign K[ 1] = SHA256_K[2015:1984];
  assign K[ 2] = SHA256_K[1983:1952];
  assign K[ 3] = SHA256_K[1951:1920];
  assign K[ 4] = SHA256_K[1919:1888];
  assign K[ 5] = SHA256_K[1887:1856];
  assign K[ 6] = SHA256_K[1855:1824];
  assign K[ 7] = SHA256_K[1823:1792];
  assign K[ 8] = SHA256_K[1791:1760];
  assign K[ 9] = SHA256_K[1759:1728];
  assign K[10] = SHA256_K[1727:1696];
  assign K[11] = SHA256_K[1695:1664];
  assign K[12] = SHA256_K[1663:1632];
  assign K[13] = SHA256_K[1631:1600];
  assign K[14] = SHA256_K[1599:1568];
  assign K[15] = SHA256_K[1567:1536];
  assign K[16] = SHA256_K[1535:1504];
  assign K[17] = SHA256_K[1503:1472];
  assign K[18] = SHA256_K[1471:1440];
  assign K[19] = SHA256_K[1439:1408];
  assign K[20] = SHA256_K[1407:1376];
  assign K[21] = SHA256_K[1375:1344];
  assign K[22] = SHA256_K[1343:1312];
  assign K[23] = SHA256_K[1311:1280];
  assign K[24] = SHA256_K[1279:1248];
  assign K[25] = SHA256_K[1247:1216];
  assign K[26] = SHA256_K[1215:1184];
  assign K[27] = SHA256_K[1183:1152];
  assign K[28] = SHA256_K[1151:1120];
  assign K[29] = SHA256_K[1119:1088];
  assign K[30] = SHA256_K[1087:1056];
  assign K[31] = SHA256_K[1055:1024];
  assign K[32] = SHA256_K[1023: 992];
  assign K[33] = SHA256_K[ 991: 960];
  assign K[34] = SHA256_K[ 959: 928];
  assign K[35] = SHA256_K[ 927: 896];
  assign K[36] = SHA256_K[ 895: 864];
  assign K[37] = SHA256_K[ 863: 832];
  assign K[38] = SHA256_K[ 831: 800];
  assign K[39] = SHA256_K[ 799: 768];
  assign K[40] = SHA256_K[ 767: 736];
  assign K[41] = SHA256_K[ 735: 704];
  assign K[42] = SHA256_K[ 703: 672];
  assign K[43] = SHA256_K[ 671: 640];
  assign K[44] = SHA256_K[ 639: 608];
  assign K[45] = SHA256_K[ 607: 576];
  assign K[46] = SHA256_K[ 575: 544];
  assign K[47] = SHA256_K[ 543: 512];
  assign K[48] = SHA256_K[ 511: 480];
  assign K[49] = SHA256_K[ 479: 448];
  assign K[50] = SHA256_K[ 447: 416];
  assign K[51] = SHA256_K[ 415: 384];
  assign K[52] = SHA256_K[ 383: 352];
  assign K[53] = SHA256_K[ 351: 320];
  assign K[54] = SHA256_K[ 319: 288];
  assign K[55] = SHA256_K[ 287: 256];
  assign K[56] = SHA256_K[ 255: 224];
  assign K[57] = SHA256_K[ 223: 192];
  assign K[58] = SHA256_K[ 191: 160];
  assign K[59] = SHA256_K[ 159: 128];
  assign K[60] = SHA256_K[ 127:  96];
  assign K[61] = SHA256_K[  95:  64];
  assign K[62] = SHA256_K[  63:  32];
  assign K[63] = SHA256_K[  31:   0];

  reg clk = 0;
  reg [5:0] round = 0;
  reg [31:0] Kt = SHA256_K[2047:2016];

  wire [255:0] H;

  sha_unit uut (
    // Control
    .clk(clk),
    // Externally managed/shared state
    .round(round),
    .Kt(Kt),
    // SHA256 parameters
    .M(M_fips1),
    .H0(SHA256_H0),
    // Result
    .H1(H)
  );

  always
    begin
      #1 clk <= !clk;
    end

  always @(posedge clk)
    begin
      if (round == 63)
        round <= 0;
      else
        round <= round + 1;
    end

  always @(posedge clk)
    begin
      Kt <= K[round];
    end

  reg [15:0] i;

  initial
    begin

      $dumpfile("sha_unit_usage_tb.vcd");
      $dumpvars;

      // Initialize inputs
      round <= 0;
      Kt <= K[0];
      clk <= 0;

      $display("Test #1 - Block #1:");
      $display("  M:");
      $display("    %h", M_fips1[511:384]);
      $display("    %h", M_fips1[383:256]);
      $display("    %h", M_fips1[255:128]);
      $display("    %h", M_fips1[127:  0]);
      $display("  H (in):");
      $display("    %h", SHA256_H0[255:128]);
      $display("    %h", SHA256_H0[127:  0]);
      $display("");

      // Clock 64 times 
      for (i = 0; i < 64; i = i + 1)
        begin
          
          #1; // rising edge

          `ifdef DEBUG_VERBOSE
            $display("[%2d] Kt %h, Wt %h", round, Kt, uut.Wt);
            $display("[%2d] S0: %h %h %h %h %h %h %h %h", round, uut.S0[255:224], uut.S0[223:192], uut.S0[191:160], uut.S0[159:128], uut.S0[127:96], uut.S0[95:64], uut.S0[63:32], uut.S0[31:0]);
            $display("[%2d] S1: %h %h %h %h %h %h %h %h", round, uut.S1[255:224], uut.S1[223:192], uut.S1[191:160], uut.S1[159:128], uut.S1[127:96], uut.S1[95:64], uut.S1[63:32], uut.S1[31:0]);
            $display("[%2d] H0: %h %h %h %h %h %h %h %h", round, uut.H0[255:224], uut.H0[223:192], uut.H0[191:160], uut.H0[159:128], uut.H0[127:96], uut.H0[95:64], uut.H0[63:32], uut.H0[31:0]);
            $display("[%2d] H1: %h %h %h %h %h %h %h %h", round, uut.H1[255:224], uut.H1[223:192], uut.H1[191:160], uut.H1[159:128], uut.H1[127:96], uut.H1[95:64], uut.H1[63:32], uut.H1[31:0]);
          `endif

          #1; // falling edge
          
        end

      $display("");
      $display("  H (out):");
      $display("    %h", H[255:128]);
      $display("    %h", H[127:  0]);
      $display("  H (expected):");
      $display("    %h", H_fips1[255:128]);
      $display("    %h", H_fips1[127:  0]);
      $display("");

      $finish;
    end

 
endmodule
