module sha_unit_test();

  `define DEBUG_VERBOSE

  `define idx32(x) (32*((x)+1)-1):(32*(x));

  // SHA256 constants
  reg [255:0] SHA256_H0 = { 32'h6a09e667, 32'hbb67ae85,
                            32'h3c6ef372, 32'ha54ff53a,
                            32'h510e527f, 32'h9b05688c,
                            32'h1f83d9ab, 32'h5be0cd19 };

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

  // Test case #1 - FIPS single-block "abc"
  reg [511:0] M_fips1 =
    { 128'h61626380_00000000_00000000_00000000,
      128'h00000000_00000000_00000000_00000000, 
      128'h00000000_00000000_00000000_00000000, 
      128'h00000000_00000000_00000000_00000018 };

  reg[255:0] H_fips1 =
    { 128'hba7816bf_8f01cfea_414140de_5dae2223,
      128'hb00361a3_96177a9c_b410ff61_f20015ad };

  // Test case #2 - FIPS multi-block "abcdbcdecdefdefgefgh..."
  /*
  reg [511:0] M_fips2 [0:1];

  initial M_fips2[0] =
    { 128'h61626364_62636465_63646566_64656667,
      128'h65666768_66676869_6768696a_68696a6b,
      128'h696a6b6c_6a6b6c6d_6b6c6d6e_6c6d6e6f,
      128'h6d6e6f70_6e6f7071_80000000_00000000 };

  initial M_fips2[1] =
    { 128'h00000000_00000000_00000000_00000000,
      128'h00000000_00000000_00000000_00000000,
      128'h00000000_00000000_00000000_00000000,
      128'h00000000_00000000_00000000_000001c0 };

  reg [255:0] H_fips2[0:1];

  initial H_fips2[0] =
    { 128'h85e655d6_417a1795_3363376a_624cde5c,
      128'h76e09589_cac5f811_cc4b32c1_f20e533a };

  initial H_fips2[1] =
    { 128'h248d6a61_d20638b8_e5c02693_0c3e6039,
      128'ha33ce459_64ff2167_f6ecedd4_19db06c1 };
  */

  // Test case #3 - BTC example

  reg [511:0] M_btc[0:1];

  initial M_btc[0] =
    { 128'h02000000_17975b97_c18ed1f7_e255adf2,   // Start of data
      128'h97599b55_330edab8_7803c817_01000000,   // ...
      128'h00000000_8a97295a_2747b4f1_a0b3948d,   // ...
      128'hf3990344_c0e19fa6_b2b92b3a_19c8e6ba }; // ...

  initial M_btc[1] =
    { 96'hdc141787358b0553535f0119, 32'h00000000, // end of data, nonce
      128'h80000000_00000000_00000000_00000000,   // pading
      128'h00000000_00000000_00000000_00000000,   // ...
      128'h00000000_00000000_00000000_00000280 }; // ...padding, length

  reg [255:0] H_btc[0:2];

  initial H_btc[0] =
    { 128'hdc6a3b8d_0c69421a_cb1a5434_e536f7d5,
      128'hc3c1b9e4_4cbb9b8f_95f0172e_fc48d2df }; // after first block (job parameter)

  initial H_btc[1] =
    { 128'h0fc3bf25_9405a32f_d6d78a5e_6de88914,
      128'h8edd4088_cc46a2eb_c604c45a_15fe7d15 }; // intermediate hash

  initial H_btc[2] =
    { 128'h766f7950_56dd74d7_03b9173e_8d44223b,
      128'hdbe3e0b2_9fe6a0eb_8ab33534_88c2565c }; // expected result 

  reg [255:0] H0 = 0;
  reg [255:0] H = 0;
  reg [511:0] M = 0;

  reg clk = 0;
  reg reset = 0;
  reg feedback = 0;

  reg [5:0] round = 0;
  reg [31:0] Kt = 0;

  wire [255:0] H_u0;
  wire [255:0] H_u1;

  sha_unit u0 (
    clk,
    round,
    Kt,
    M,
    H0,
    H_u0
  );

  sha_unit u1 (
    clk,
    round,
    Kt,
    { H_u0[255:224], H[223:0], 1'b1, 191'd0, 64'h00000000_00000100 },
    SHA256_H0,
    H_u1
  );

  reg [15:0] i;

  initial
    begin
        #1 clk = 0;

        // Test case #1

        // Initialize inputs
        #1 M = M_fips1;
        #1 H0 = SHA256_H0;

        $display("Test #1 - Block #1:");
        $display("  M:");
        $display("    %h", M[511:384]);
        $display("    %h", M[383:256]);
        $display("    %h", M[255:128]);
        $display("    %h", M[127:  0]);
        $display("  H (in):");
        $display("    %h", H0[255:128]);
        $display("    %h", H0[127:  0]);

        #1 round = 0;
        #1 Kt = K[0];

        // Clock 64 times 
        for (i = 0; i < 64; i = i + 1)
          begin

            #1 clk = 1;
            #1 clk = 0;

            #1 Kt = K[round];
            #1 round = round + 1;

            `ifdef DEBUG_VERBOSE
              $display("[%2d] Kt %h, Wt %h", round, Kt, u0.Wt);
              $display("[%2d] S0: %h", round, u0.S0);
              $display("[%2d] S1: %h", round, u0.S1);
              $display("[%2d] H0: %h", round, u0.H0);
              $display("[%2d] H1: %h", round, u0.H1);
              /*
              $display("[%2d] W:  %h %h %h %h", round,           32{x}, u.W[`idx32(14)], u.W[`idx32(13)], u.W[`idx32(12)]);
              $display("[%2d]     %h %h %h %h", round, u.W[`idx32(11)], u.W[`idx32(10)], u.W[`idx32( 9)], u.W[`idx32( 8)]);
              $display("[%2d]     %h %h %h %h", round, u.W[`idx32( 7)], u.W[`idx32( 6)], u.W[`idx32( 5)], u.W[`idx32( 4)]);
              $display("[%2d]     %h %h %h %h", round, u.W[`idx32( 3)], u.W[`idx32( 2)], u.W[`idx32( 1)], u.W[`idx32( 0)]);
              */
            `endif
          end

        `ifdef DEBUG_VERBOSE
          $display("[%2d] H1: %h", round, u0.H1);
        `endif

        $display("  H (out):");
        $display("    %h", H_u0[255:128]);
        $display("    %h", H_u0[127:  0]);
        $display("  H (expected):");
        $display("    %h", H_fips1[255:128]);
        $display("    %h", H_fips1[127:  0]);
        $display("");

        /*
        // TEST #2

        // Initialize inputs
        M = M_fips2[0];
        Hin = SHA256_H0;

        $display("Test #2 - Block #1:");
        $display("  M:");
        $display("    %h", M[511:384]);
        $display("    %h", M[383:256]);
        $display("    %h", M[255:128]);
        $display("    %h", M[127:  0]);
        $display("  H (in):");
        $display("    %h", Hin[255:128]);
        $display("    %h", Hin[127:  0]);

        // ~> IDLE
        #1 reset = 1;
        #1 round = 0;
        #1 feedback = 0; // Disable feedback for this case

        #1 clk = 1;
        #1 clk = 0;
        #1 reset = 0;

        // Chew first block
        for (i = 0; i < 64; i = i + 1)
          begin
            //    0) IDLE ~> WORKING
            // 1-62) WORKING ~> WORKING
            //   63) WORKING ~> DONE
            #1 clk = 1;
            #1 clk = 0;

            #1 Kt = K[round];
            #1 round = round + 1;
          end

        // DONE ~> IDLE (required when feedback = 0)
        #1 reset = 1;
        #1 round = 0;

        #1 clk = 1;
        #1 clk = 0;
        #1 reset = 0;

        $display("  H (out):");
        $display("    %h", Hout[255:128]);
        $display("    %h", Hout[127:  0]);
        $display("  H (expected):");
        $display("    %h", H_fips2[0][255:128]);
        $display("    %h", H_fips2[0][127:  0]);
        $display("");

        // Prepare for second block
        M = M_fips2[1];
        Hin = Hout;

        // Chew second block
        $display("Test #2 - Block #2:");
        $display("  M:");
        $display("    %h", M[511:384]);
        $display("    %h", M[383:256]);
        $display("    %h", M[255:128]);
        $display("    %h", M[127:  0]);
        $display("  H (in):");
        $display("    %h", Hin[255:128]);
        $display("    %h", Hin[127:  0]);

        for (i = 0; i < 64; i = i + 1)
          begin
            //    0) IDLE ~> WORKING
            // 1-62) WORKING ~> WORKING
            //   63) WORKING ~> DONE
            #1 clk = 1;
            #1 clk = 0;
            #1 Kt = K[round];
               round = round + 1;
          end

        // Extra clock cycle for updating result 
        #1 clk = 1;
        #1 clk = 0;

        $display("  H (out):");
        $display("    %h", Hout[255:128]);
        $display("    %h", Hout[127:  0]);
        $display("  H (expected):");
        $display("    %h", H_fips2[1][255:128]);
        $display("    %h", H_fips2[1][127:  0]);
        $display("");
        */

        // TEST #3

        /*
        // Initialize inputs
        M = M_btc[0];
        Hin = SHA256_H0;

        // This block will be done on host, intermediate state provided as
        // parameter.

        $display("Test #3 - Block #1:");
        $display("  M:");
        $display("    %h", M[511:384]);
        $display("    %h", M[383:256]);
        $display("    %h", M[255:128]);
        $display("    %h", M[127:  0]);
        $display("  H (in):");
        $display("    %h", Hin[255:128]);
        $display("    %h", Hin[127:  0]);


        // ~> IDLE
        #1 reset = 1;
        #1 round = 0;
        #1 feedback = 0;

        #1 clk = 1;
        #1 clk = 0;
        #1 reset = 0;

        // Chew first block
        for (i = 0; i < 64; i = i + 1)
          begin
            #1 clk = 1;
            #1 clk = 0;
            #1 Kt = K[round];
               round = round + 1;
          end

        // DONE ~> IDLE (required when feedback = 0)
        #1 reset = 1;
        #1 round = 0;
        #1 feedback = 1; // exploit feedback for this case

        #1 clk = 1;
        #1 clk = 0;
        #1 reset = 0;

        $display("  H (out):");
        $display("    %h", Hout[255:128]);
        $display("    %h", Hout[127:  0]);
        $display("  H (expected):");
        $display("    %h", H_btc[0][255:128]);
        $display("    %h", H_btc[0][127:  0]);
        $display("");
        */

        // Prepare for second block -- where we normally start
        M = M_btc[1];
        H0 = H_btc[0];

        $display("Test #3 - Block #2:");
        $display("  M:");
        $display("    %h", M[511:384]);
        $display("    %h", M[383:256]);
        $display("    %h", M[255:128]);
        $display("    %h", M[127:  0]);
        $display("  H (in):");
        $display("    %h", H0[255:128]);
        $display("    %h", H0[127:  0]);

        // Chew second block
        for (i = 0; i < 64; i = i + 1)
          begin
            #1 clk = 1;
            #1 clk = 0;
            #1 Kt = K[round];
            #1 round = round + 1;
          end

        // Second verse same as the first
        $display("  H_u0 (actual):");
        $display("    %h", H_u0[255:128]);
        $display("    %h", H_u0[127:  0]);
        $display("  H_u0 (expected):");
        $display("    %h", H_btc[1][255:128]);
        $display("    %h", H_btc[1][127:  0]);
        $display("");


        $display("  M1:");
        $display("    %h", u1.M[511:384]);
        $display("    %h", u1.M[383:256]);
        $display("    %h", u1.M[255:128]);
        $display("    %h", u1.M[127:  0]);

        // Save H_u0 for use in M for second block 
        // -- only [223:0] needs to be stored, [255:32] used as wire for use on
        //    same cycle as round == 0.
        H[223:0] = H_u0[223:0];

        for (i = 0; i < 64; i = i + 1)
          begin
            #1 clk = 1;
            #1 clk = 0;
            #1 Kt = K[round];
            #1 round = round + 1;
          end

        $display("Test #3 - Block #3:");
        $display("  H_u1 (actual):");
        $display("    %h", H_u1[255:128]);
        $display("    %h", H_u1[127:  0]);
        $display("  H_u1 (expected):");
        $display("    %h", H_btc[2][255:128]);
        $display("    %h", H_btc[2][127:  0]);
        $display("");

    end

 
endmodule
