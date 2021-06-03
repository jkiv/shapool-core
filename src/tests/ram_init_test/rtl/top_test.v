module top_test
(
  clk_in,
  reset_n_in,
  // Global data
  sck0_in,
  sdi0_in,
  cs0_n_in,
  // Daisy data
  sck1_in,
  sdi1_in,
  sdo1_out,
  cs1_n_in,
  // READY flags
  ready_n_od_out,
  // Indicator LED
  status_led_n_out
);
    // 12 MHz ~ 48 MHz
    parameter PLL_DIVR = 4'b0000;
    parameter PLL_DIVF = 7'b1111111;
    parameter PLL_DIVQ = 3'b100;

    // 12 MHz ~ 56.25 MHz
    // parameter PLL_DIVR = 4'b0000;
    // parameter PLL_DIVF = 7'b1001010;
    // parameter PLL_DIVQ = 3'b100;

    // Multiply input clock signal using SB_PLL40_CORE
    wire g_clk;

    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .DIVR(PLL_DIVR),
        .DIVF(PLL_DIVF),
        .DIVQ(PLL_DIVQ),
        .FILTER_RANGE(3'b001)
    )
    pll (
        .LOCK(pll_locked),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(clk_in),
        //.PLLOUTCORE(g_clk)
        .PLLOUTGLOBAL(g_clk)
    );

    // Inputs and Outputs

    input wire clk_in;

    input wire reset_n_in;

    input wire sck0_in;
    input wire sdi0_in;
    input wire cs0_n_in;

    input wire sck1_in;
    input wire sdi1_in;
    output wire sdo1_out;
    input wire cs1_n_in;

    output wire ready_n_od_out;

    output wire status_led_n_out;

    // Set up dummy external_io

    external_io #(
      .POOL_SIZE(1),
      .POOL_SIZE_LOG2(0),
      .JOB_CONFIG_WIDTH(8),    // smallest
      .DEVICE_CONFIG_WIDTH(8), // smallest
      .RESULT_DATA_WIDTH(64)
    )
    io (
      .clk(g_clk),
      .reset_n(reset_n_in),
      // SPI(0)
      .sck0(sck0_in),
      .sdi0(sdi0_in),
      .cs0_n(cs0_n_in),
      // SPI(1)
      .sck1(sck1_in),
      .sdi1(sdi1_in),
      .sdo1(sdo1_out),
      .cs1_n(cs1_n_in),
      // Stored data
      .device_config(),
      .job_config(),
      // Control signals
      .core_reset_n(),
      // From shapool
      .shapool_success(done),
      .shapool_result(dump),
      // READY signal
      .ready()
    );

    // Read all RAM values into register

    reg [63:0] dump; 
    reg [5:0] round = 0;

    reg done = 0;

    always @(posedge g_clk)
      begin
        if (!reset_n_in)
          begin
            round <= 0;
            done <= 0;
          end
        else if (done == 0)
          begin

            round <= round + 1;

            if (round == 0)
              begin
                dump <= { Kt, dump[63:32] };
              end

            if (round == 63)
              begin
                dump <= { Kt, dump[63:32] };
                done <= 1;
              end

          end
      end
    
    assign ready_n_od_out = (done == 1) ? 1'b0 : 1'bz;
    assign status_led_n_out  = !done;

    // RAM setup
    wire [15:0] data_hi;
    wire [15:0] data_lo;
  
    wire [31:0] Kt;
    assign Kt = { data_hi, data_lo };
  
    wire [7:0] address;
    assign address = { 2'b10, round };
  
    SB_RAM40_4K ram256x16_hi (
        .RDATA(data_hi),
        .RADDR(address),
        .RCLK(g_clk),
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
        .RCLK(g_clk),
        .RCLKE(1),
        .RE(1),
        .WADDR(0),
        .WCLK(0),
        .WCLKE(0),
        .WDATA(0),
        .WE(0),
        .MASK(0)
    );
  
    defparam ram256x16_hi.READ_MODE  = 0; // 0 = 256x16 
    defparam ram256x16_hi.WRITE_MODE = 0; // 0 = 256x16
  
    defparam ram256x16_lo.READ_MODE  = 0; // 0 = 256x16 
    defparam ram256x16_lo.WRITE_MODE = 0; // 0 = 256x16
  
    defparam ram256x16_hi.INIT_0 = 256'h0000_0001_0002_0003_0004_0005_0006_0007_0008_0009_000a_000b_000c_000d_000e_000f;
    defparam ram256x16_hi.INIT_1 = 256'h0010_0011_0012_0013_0014_0015_0016_0017_0018_0019_001a_001b_001c_001d_001e_001f;
    defparam ram256x16_hi.INIT_2 = 256'h0020_0021_0022_0023_0024_0025_0026_0027_0028_0029_002a_002b_002c_002d_002e_002f;
    defparam ram256x16_hi.INIT_3 = 256'h0030_0031_0032_0033_0034_0035_0036_0037_0038_0039_003a_003b_003c_003d_003e_003f;
    defparam ram256x16_hi.INIT_4 = 256'h0040_0041_0042_0043_0044_0045_0046_0047_0048_0049_004a_004b_004c_004d_004e_004f;
    defparam ram256x16_hi.INIT_5 = 256'h0050_0051_0052_0053_0054_0055_0056_0057_0058_0059_005a_005b_005c_005d_005e_005f;
    defparam ram256x16_hi.INIT_6 = 256'h0060_0061_0062_0063_0064_0065_0066_0067_0068_0069_006a_006b_006c_006d_006e_006f;
    defparam ram256x16_hi.INIT_7 = 256'h0070_0071_0072_0073_0074_0075_0076_0077_0078_0079_007a_007b_007c_007d_007e_007f;
    defparam ram256x16_hi.INIT_8 = 256'h0080_0081_0082_0083_0084_0085_0086_0087_0088_0089_008a_008b_008c_008d_008e_008f;
    defparam ram256x16_hi.INIT_9 = 256'h0090_0091_0092_0093_0094_0095_0096_0097_0098_0099_009a_009b_009c_009d_009e_009f;
    defparam ram256x16_hi.INIT_A = 256'h00a0_00a1_00a2_00a3_00a4_00a5_00a6_00a7_00a8_00a9_00aa_00ab_00ac_00ad_00ae_00af;
    defparam ram256x16_hi.INIT_B = 256'h00b0_00b1_00b2_00b3_00b4_00b5_00b6_00b7_00b8_00b9_00ba_00bb_00bc_00bd_00be_00bf;
    defparam ram256x16_hi.INIT_C = 256'h00c0_00c1_00c2_00c3_00c4_00c5_00c6_00c7_00c8_00c9_00ca_00cb_00cc_00cd_00ce_00cf;
    defparam ram256x16_hi.INIT_D = 256'h00d0_00d1_00d2_00d3_00d4_00d5_00d6_00d7_00d8_00d9_00da_00db_00dc_00dd_00de_00df;
    defparam ram256x16_hi.INIT_E = 256'h00e0_00e1_00e2_00e3_00e4_00e5_00e6_00e7_00e8_00e9_00ea_00eb_00ec_00ed_00ee_00ef;
    defparam ram256x16_hi.INIT_F = 256'h00f0_00f1_00f2_00f3_00f4_00f5_00f6_00f7_00f8_00f9_00fa_00fb_00fc_00fd_00fe_00ff;
  
    defparam ram256x16_lo.INIT_0 = 256'h0100_0101_0102_0103_0104_0105_0106_0107_0108_0109_010a_010b_010c_010d_010e_010f;
    defparam ram256x16_lo.INIT_1 = 256'h0110_0111_0112_0113_0114_0115_0116_0117_0118_0119_011a_011b_011c_011d_011e_011f;
    defparam ram256x16_lo.INIT_2 = 256'h0120_0121_0122_0123_0124_0125_0126_0127_0128_0129_012a_012b_012c_012d_012e_012f;
    defparam ram256x16_lo.INIT_3 = 256'h0130_0131_0132_0133_0134_0135_0136_0137_0138_0139_013a_013b_013c_013d_013e_013f;
    defparam ram256x16_lo.INIT_4 = 256'h0140_0141_0142_0143_0144_0145_0146_0147_0148_0149_014a_014b_014c_014d_014e_014f;
    defparam ram256x16_lo.INIT_5 = 256'h0150_0151_0152_0153_0154_0155_0156_0157_0158_0159_015a_015b_015c_015d_015e_015f;
    defparam ram256x16_lo.INIT_6 = 256'h0160_0161_0162_0163_0164_0165_0166_0167_0168_0169_016a_016b_016c_016d_016e_016f;
    defparam ram256x16_lo.INIT_7 = 256'h0170_0171_0172_0173_0174_0175_0176_0177_0178_0179_017a_017b_017c_017d_017e_017f;
    defparam ram256x16_lo.INIT_8 = 256'h0180_0181_0182_0183_0184_0185_0186_0187_0188_0189_018a_018b_018c_018d_018e_018f;
    defparam ram256x16_lo.INIT_9 = 256'h0190_0191_0192_0193_0194_0195_0196_0197_0198_0199_019a_019b_019c_019d_019e_019f;
    defparam ram256x16_lo.INIT_A = 256'h01a0_01a1_01a2_01a3_01a4_01a5_01a6_01a7_01a8_01a9_01aa_01ab_01ac_01ad_01ae_01af;
    defparam ram256x16_lo.INIT_B = 256'h01b0_01b1_01b2_01b3_01b4_01b5_01b6_01b7_01b8_01b9_01ba_01bb_01bc_01bd_01be_01bf;
    defparam ram256x16_lo.INIT_C = 256'h01c0_01c1_01c2_01c3_01c4_01c5_01c6_01c7_01c8_01c9_01ca_01cb_01cc_01cd_01ce_01cf;
    defparam ram256x16_lo.INIT_D = 256'h01d0_01d1_01d2_01d3_01d4_01d5_01d6_01d7_01d8_01d9_01da_01db_01dc_01dd_01de_01df;
    defparam ram256x16_lo.INIT_E = 256'h01e0_01e1_01e2_01e3_01e4_01e5_01e6_01e7_01e8_01e9_01ea_01eb_01ec_01ed_01ee_01ef;
    defparam ram256x16_lo.INIT_F = 256'h01f0_01f1_01f2_01f3_01f4_01f5_01f6_01f7_01f8_01f9_01fa_01fb_01fc_01fd_01fe_01ff;

endmodule
