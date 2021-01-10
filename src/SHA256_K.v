/*
 * Two RO 256x16 RAM banks for 32-bit word access per clock cycle.
 */
module SHA256_K (
  clk,
  round,
  Kt
);

  input clk;
  input [5:0] round;

`ifdef ICE40

  wire [15:0] data_hi;
  wire [15:0] data_lo;

  output wire [31:0] Kt;
  assign Kt = { data_hi, data_lo };

  wire [7:0] address;
  assign address = { 2'b10, round }; // round (0x00 to 0x3F) + 0x80 (offset)
                                     // -- offset is to avoid lowest 

  // Read-only sysMEM block for upper 16'
  SB_RAM40_4K ram256x16_hi (
      .RDATA(data_hi),
      .RADDR(address),
      .RCLK(clk),
      .RCLKE(1),
      .RE(1),
      .WADDR(0),
      .WCLK(0),
      .WCLKE(0),
      .WDATA(0),
      .WE(0),
      .MASK(0)
  );

  defparam ram256x16_hi.READ_MODE = 0;  // 0 = 256x16 
  defparam ram256x16_hi.WRITE_MODE = 0; // 0 = 256x16

  defparam ram256x16_hi.INIT_0 =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_hi.INIT_1 =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_hi.INIT_2 =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_hi.INIT_3 =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_hi.INIT_4 =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_hi.INIT_5 =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_hi.INIT_6 =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_hi.INIT_7 =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_hi.INIT_8 =
      256'h428a_7137_b5c0_e9b5_3956_59f1_923f_ab1c_d807_1283_2431_550c_72be_80de_9bdc_c19b;
  defparam ram256x16_hi.INIT_9 =
      256'he49b_efbe_0fc1_240c_2de9_4a74_5cb0_76f9_983e_a831_b003_bf59_c6e0_d5a7_06ca_1429;
  defparam ram256x16_hi.INIT_A =
      256'h27b7_2e1b_4d2c_5338_650a_766a_81c2_9272_a2bf_a81a_c24b_c76c_d192_d699_f40e_106a;
  defparam ram256x16_hi.INIT_B =
      256'h19a4_1e37_2748_34b0_391c_4ed8_5b9c_682e_748f_78a5_84c8_8cc7_90be_a450_bef9_c671;
  defparam ram256x16_hi.INIT_C =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_hi.INIT_D =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_hi.INIT_E =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_hi.INIT_F =
      256'h0000000000000000000000000000000000000000000000000000000000000000;

  // Read-only sysMEM block for lower 16'
  SB_RAM40_4K ram256x16_lo (
      .RDATA(data_lo),
      .RADDR(address),
      .RCLK(clk),
      .RCLKE(1),
      .RE(1),
      .WADDR(0),
      .WCLK(0),
      .WCLKE(0),
      .WDATA(0),
      .WE(0),
      .MASK(0)
  );

  defparam ram256x16_lo.READ_MODE = 0;  // 0 = 256x16 
  defparam ram256x16_lo.WRITE_MODE = 0; // 0 = 256x16

  defparam ram256x16_lo.INIT_0 =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_lo.INIT_1 =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_lo.INIT_2 =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_lo.INIT_3 =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_lo.INIT_4 =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_lo.INIT_5 =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_lo.INIT_6 =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_lo.INIT_7 =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_lo.INIT_8 =
      256'h2f98_4491_fbcf_dba5_c25b_11f1_82a4_5ed5_aa98_5b01_85be_7dc3_5d74_b1fe_06a7_f174;
  defparam ram256x16_lo.INIT_9 =
      256'h69c1_4786_9dc6_a1cc_2c6f_84aa_a9dc_88da_5152_c66d_27c8_7fc7_0bf3_9147_6351_2967;
  defparam ram256x16_lo.INIT_A =
      256'h0a85_2138_6dfc_0d13_7354_0abb_c92e_2c85_e8a1_664b_8b70_51a3_e819_0624_3585_a070;
  defparam ram256x16_lo.INIT_B =
      256'hc116_6c08_774c_bcb5_0cb3_aa4a_ca4f_6ff3_82ee_636f_7814_0208_fffa_6ceb_a3f7_78f2;
  defparam ram256x16_lo.INIT_C =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_lo.INIT_D =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_lo.INIT_E =
      256'h0000000000000000000000000000000000000000000000000000000000000000;
  defparam ram256x16_lo.INIT_F =
      256'h0000000000000000000000000000000000000000000000000000000000000000;

//`elsif MACHXO3

`else

  output reg [31:0] Kt;
  
  always @(posedge clk)
  begin
	case(round)
		 0: Kt <= 32'h428a2f98;
		 1: Kt <= 32'h71374491;
		 2: Kt <= 32'hb5c0fbcf;
		 3: Kt <= 32'he9b5dba5;
		 4: Kt <= 32'h3956c25b;
		 5: Kt <= 32'h59f111f1;
		 6: Kt <= 32'h923f82a4;
		 7: Kt <= 32'hab1c5ed5;
		 8: Kt <= 32'hd807aa98;
		 9: Kt <= 32'h12835b01;
		10: Kt <= 32'h243185be;
		11: Kt <= 32'h550c7dc3;
		12: Kt <= 32'h72be5d74;
		13: Kt <= 32'h80deb1fe;
		14: Kt <= 32'h9bdc06a7;
		15: Kt <= 32'hc19bf174;
		16: Kt <= 32'he49b69c1;
		17: Kt <= 32'hefbe4786;
		18: Kt <= 32'h0fc19dc6;
		19: Kt <= 32'h240ca1cc;
		20: Kt <= 32'h2de92c6f;
		21: Kt <= 32'h4a7484aa;
		22: Kt <= 32'h5cb0a9dc;
		23: Kt <= 32'h76f988da;
		24: Kt <= 32'h983e5152;
		25: Kt <= 32'ha831c66d;
		26: Kt <= 32'hb00327c8;
		27: Kt <= 32'hbf597fc7;
		28: Kt <= 32'hc6e00bf3;
		29: Kt <= 32'hd5a79147;
		30: Kt <= 32'h06ca6351;
		31: Kt <= 32'h14292967;
		32: Kt <= 32'h27b70a85;
		33: Kt <= 32'h2e1b2138;
		34: Kt <= 32'h4d2c6dfc;
		35: Kt <= 32'h53380d13;
		36: Kt <= 32'h650a7354;
		37: Kt <= 32'h766a0abb;
		38: Kt <= 32'h81c2c92e;
		39: Kt <= 32'h92722c85;
		40: Kt <= 32'ha2bfe8a1;
		41: Kt <= 32'ha81a664b;
		42: Kt <= 32'hc24b8b70;
		43: Kt <= 32'hc76c51a3;
		44: Kt <= 32'hd192e819;
		45: Kt <= 32'hd6990624;
		46: Kt <= 32'hf40e3585;
		47: Kt <= 32'h106aa070;
		48: Kt <= 32'h19a4c116;
		49: Kt <= 32'h1e376c08;
		50: Kt <= 32'h2748774c;
		51: Kt <= 32'h34b0bcb5;
		52: Kt <= 32'h391c0cb3;
		53: Kt <= 32'h4ed8aa4a;
		54: Kt <= 32'h5b9cca4f;
		55: Kt <= 32'h682e6ff3;
		56: Kt <= 32'h748f82ee;
		57: Kt <= 32'h78a5636f;
		58: Kt <= 32'h84c87814;
		59: Kt <= 32'h8cc70208;
		60: Kt <= 32'h90befffa;
		61: Kt <= 32'ha4506ceb;
		62: Kt <= 32'hbef9a3f7;
		63: Kt <= 32'hc67178f2;
    endcase
  end
  
  /*
  wire [31:0] Ks[0:63];

  always @(posedge clk)
    begin
      Kt <= Ks[round];
    end

  assign Ks[ 0] = 32'h428a2f98;
  assign Ks[ 1] = 32'h71374491;
  assign Ks[ 2] = 32'hb5c0fbcf;
  assign Ks[ 3] = 32'he9b5dba5;
  assign Ks[ 4] = 32'h3956c25b;
  assign Ks[ 5] = 32'h59f111f1;
  assign Ks[ 6] = 32'h923f82a4;
  assign Ks[ 7] = 32'hab1c5ed5;
  assign Ks[ 8] = 32'hd807aa98;
  assign Ks[ 9] = 32'h12835b01;
  assign Ks[10] = 32'h243185be;
  assign Ks[11] = 32'h550c7dc3;
  assign Ks[12] = 32'h72be5d74;
  assign Ks[13] = 32'h80deb1fe;
  assign Ks[14] = 32'h9bdc06a7;
  assign Ks[15] = 32'hc19bf174;
  assign Ks[16] = 32'he49b69c1;
  assign Ks[17] = 32'hefbe4786;
  assign Ks[18] = 32'h0fc19dc6;
  assign Ks[19] = 32'h240ca1cc;
  assign Ks[20] = 32'h2de92c6f;
  assign Ks[21] = 32'h4a7484aa;
  assign Ks[22] = 32'h5cb0a9dc;
  assign Ks[23] = 32'h76f988da;
  assign Ks[24] = 32'h983e5152;
  assign Ks[25] = 32'ha831c66d;
  assign Ks[26] = 32'hb00327c8;
  assign Ks[27] = 32'hbf597fc7;
  assign Ks[28] = 32'hc6e00bf3;
  assign Ks[29] = 32'hd5a79147;
  assign Ks[30] = 32'h06ca6351;
  assign Ks[31] = 32'h14292967;
  assign Ks[32] = 32'h27b70a85;
  assign Ks[33] = 32'h2e1b2138;
  assign Ks[34] = 32'h4d2c6dfc;
  assign Ks[35] = 32'h53380d13;
  assign Ks[36] = 32'h650a7354;
  assign Ks[37] = 32'h766a0abb;
  assign Ks[38] = 32'h81c2c92e;
  assign Ks[39] = 32'h92722c85;
  assign Ks[40] = 32'ha2bfe8a1;
  assign Ks[41] = 32'ha81a664b;
  assign Ks[42] = 32'hc24b8b70;
  assign Ks[43] = 32'hc76c51a3;
  assign Ks[44] = 32'hd192e819;
  assign Ks[45] = 32'hd6990624;
  assign Ks[46] = 32'hf40e3585;
  assign Ks[47] = 32'h106aa070;
  assign Ks[48] = 32'h19a4c116;
  assign Ks[49] = 32'h1e376c08;
  assign Ks[50] = 32'h2748774c;
  assign Ks[51] = 32'h34b0bcb5;
  assign Ks[52] = 32'h391c0cb3;
  assign Ks[53] = 32'h4ed8aa4a;
  assign Ks[54] = 32'h5b9cca4f;
  assign Ks[55] = 32'h682e6ff3;
  assign Ks[56] = 32'h748f82ee;
  assign Ks[57] = 32'h78a5636f;
  assign Ks[58] = 32'h84c87814;
  assign Ks[59] = 32'h8cc70208;
  assign Ks[60] = 32'h90befffa;
  assign Ks[61] = 32'ha4506ceb;
  assign Ks[62] = 32'hbef9a3f7;
  assign Ks[63] = 32'hc67178f2;
  */

  /*
  localparam [2047:0] SHA256_K =
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
  */

  /*
  always @(posedge clk)
    begin
      case(round)
         0: Kt <= 32'h428a2f98;
         1: Kt <= 32'h71374491;
         2: Kt <= 32'hb5c0fbcf;
         3: Kt <= 32'he9b5dba5;
         4: Kt <= 32'h3956c25b;
         5: Kt <= 32'h59f111f1;
         6: Kt <= 32'h923f82a4;
         7: Kt <= 32'hab1c5ed5;
         8: Kt <= 32'hd807aa98;
         9: Kt <= 32'h12835b01;
        10: Kt <= 32'h243185be;
        11: Kt <= 32'h550c7dc3;
        12: Kt <= 32'h72be5d74;
        13: Kt <= 32'h80deb1fe;
        14: Kt <= 32'h9bdc06a7;
        15: Kt <= 32'hc19bf174;
        16: Kt <= 32'he49b69c1;
        17: Kt <= 32'hefbe4786;
        18: Kt <= 32'h0fc19dc6;
        19: Kt <= 32'h240ca1cc;
        20: Kt <= 32'h2de92c6f;
        21: Kt <= 32'h4a7484aa;
        22: Kt <= 32'h5cb0a9dc;
        23: Kt <= 32'h76f988da;
        24: Kt <= 32'h983e5152;
        25: Kt <= 32'ha831c66d;
        26: Kt <= 32'hb00327c8;
        27: Kt <= 32'hbf597fc7;
        28: Kt <= 32'hc6e00bf3;
        29: Kt <= 32'hd5a79147;
        30: Kt <= 32'h06ca6351;
        31: Kt <= 32'h14292967;
        32: Kt <= 32'h27b70a85;
        33: Kt <= 32'h2e1b2138;
        34: Kt <= 32'h4d2c6dfc;
        35: Kt <= 32'h53380d13;
        36: Kt <= 32'h650a7354;
        37: Kt <= 32'h766a0abb;
        38: Kt <= 32'h81c2c92e;
        39: Kt <= 32'h92722c85;
        40: Kt <= 32'ha2bfe8a1;
        41: Kt <= 32'ha81a664b;
        42: Kt <= 32'hc24b8b70;
        43: Kt <= 32'hc76c51a3;
        44: Kt <= 32'hd192e819;
        45: Kt <= 32'hd6990624;
        46: Kt <= 32'hf40e3585;
        47: Kt <= 32'h106aa070;
        48: Kt <= 32'h19a4c116;
        49: Kt <= 32'h1e376c08;
        50: Kt <= 32'h2748774c;
        51: Kt <= 32'h34b0bcb5;
        52: Kt <= 32'h391c0cb3;
        53: Kt <= 32'h4ed8aa4a;
        54: Kt <= 32'h5b9cca4f;
        55: Kt <= 32'h682e6ff3;
        56: Kt <= 32'h748f82ee;
        57: Kt <= 32'h78a5636f;
        58: Kt <= 32'h84c87814;
        59: Kt <= 32'h8cc70208;
        60: Kt <= 32'h90befffa;
        61: Kt <= 32'ha4506ceb;
        62: Kt <= 32'hbef9a3f7;
        63: Kt <= 32'hc67178f2;
      endcase
    end
    */
	
`endif

endmodule
