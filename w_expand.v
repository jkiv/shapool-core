/* w_expand
 *
 * Asynchronously performs w_expand function given W[t] values.
 *
 * For SHA256,
 *
 *    W(t) = SSIG1(W(t-2)) + W(t-7) + SSIG0(W(t-15)) + W(t-16)
 *
 */
module w_expand(w2, w7, w15, w16, out);

  input  wire [31:0] w2;  // W[t-2]
  input  wire [31:0] w7;  // W[t-7]
  input  wire [31:0] w15; // W[t-15]
  input  wire [31:0] w16; // W[t-16]
  output wire [31:0] out;

  wire [31:0] ssig0_w15;
  wire [31:0] ssig1_w2;
  
  // For SHA256, SSIG0(X) = ROTR7(X) XOR ROTR18(X) XOR SHR3(X)
  assign ssig0_w15  =   { w15[ 6:0], w15[31: 7] }
                      ^ { w15[17:0], w15[31:18] }
                      ^ {      3'b0, w15[31: 3] };

  // For SHA256, SSIG1(X) = ROTR17(X) XOR ROTR19(X) XOR SHR10(X)
  assign ssig1_w2 =   { w2[16:0], w2[31:17] }
                    ^ { w2[18:0], w2[31:19] }
                    ^ {    10'b0, w2[31:10] };

  assign out = ssig0_w15 + ssig1_w2 + w7 + w16;

endmodule // w_expand
