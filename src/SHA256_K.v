/*
 * Two read-only 256x16 RAM banks for 32-bit word access per clock cycle, addressed by `round`.
 */
module SHA256_K (
  clk,
  round,
  Kt
);

  input clk;
  input [5:0] round;

`ifndef VERILATOR

  wire [15:0] data_hi;
  wire [15:0] data_lo;

  output wire [31:0] Kt;
  assign Kt = { data_hi, data_lo };

  wire [7:0] address;
  assign address = { 2'b10, round }; 

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

  defparam ram256x16_hi.READ_MODE = 0;  // 0 = 256x16 
  defparam ram256x16_hi.WRITE_MODE = 0; // 0 = 256x16

  defparam ram256x16_lo.READ_MODE = 0;  // 0 = 256x16 
  defparam ram256x16_lo.WRITE_MODE = 0; // 0 = 256x16

  defparam ram256x16_hi.INIT_0 = 0;
  defparam ram256x16_hi.INIT_1 = 0;
  defparam ram256x16_hi.INIT_2 = 0;
  defparam ram256x16_hi.INIT_3 = 0;
  defparam ram256x16_hi.INIT_4 = 0;
  defparam ram256x16_hi.INIT_5 = 0;
  defparam ram256x16_hi.INIT_6 = 0;
  defparam ram256x16_hi.INIT_7 = 0;
  defparam ram256x16_hi.INIT_8 = 256'hc19b_9bdc_80de_72be_550c_2431_1283_d807_ab1c_923f_59f1_3956_e9b5_b5c0_7137_428a;
  defparam ram256x16_hi.INIT_9 = 256'h1429_06ca_d5a7_c6e0_bf59_b003_a831_983e_76f9_5cb0_4a74_2de9_240c_0fc1_efbe_e49b;
  defparam ram256x16_hi.INIT_A = 256'h106a_f40e_d699_d192_c76c_c24b_a81a_a2bf_9272_81c2_766a_650a_5338_4d2c_2e1b_27b7;
  defparam ram256x16_hi.INIT_B = 256'hc671_bef9_a450_90be_8cc7_84c8_78a5_748f_682e_5b9c_4ed8_391c_34b0_2748_1e37_19a4;
  defparam ram256x16_hi.INIT_C = 0;
  defparam ram256x16_hi.INIT_D = 0;
  defparam ram256x16_hi.INIT_E = 0;
  defparam ram256x16_hi.INIT_F = 0;

  defparam ram256x16_lo.INIT_0 = 0;
  defparam ram256x16_lo.INIT_1 = 0;
  defparam ram256x16_lo.INIT_2 = 0;
  defparam ram256x16_lo.INIT_3 = 0;
  defparam ram256x16_lo.INIT_4 = 0;
  defparam ram256x16_lo.INIT_5 = 0;
  defparam ram256x16_lo.INIT_6 = 0;
  defparam ram256x16_lo.INIT_7 = 0;
  defparam ram256x16_lo.INIT_8 = 256'hf174_06a7_b1fe_5d74_7dc3_85be_5b01_aa98_5ed5_82a4_11f1_c25b_dba5_fbcf_4491_2f98;
  defparam ram256x16_lo.INIT_9 = 256'h2967_6351_9147_0bf3_7fc7_27c8_c66d_5152_88da_a9dc_84aa_2c6f_a1cc_9dc6_4786_69c1;
  defparam ram256x16_lo.INIT_A = 256'ha070_3585_0624_e819_51a3_8b70_664b_e8a1_2c85_c92e_0abb_7354_0d13_6dfc_2138_0a85;
  defparam ram256x16_lo.INIT_B = 256'h78f2_a3f7_6ceb_fffa_0208_7814_636f_82ee_6ff3_ca4f_aa4a_0cb3_bcb5_774c_6c08_c116;
  defparam ram256x16_lo.INIT_C = 0;
  defparam ram256x16_lo.INIT_D = 0;
  defparam ram256x16_lo.INIT_E = 0;
  defparam ram256x16_lo.INIT_F = 0;

`else

  // Simulate RAM lookup for testing

  output reg [31:0] Kt;
  
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

`endif
endmodule
