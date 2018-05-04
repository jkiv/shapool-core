/* sha_round
 *
 * Asynchronously performs a single SHA256 round given an input state and
 * values for Kt and Wt for the current round.
 *
 * For SHA-256,
 *
 *    T1 = h + BSIG1(e) + CH(e,f,g) + Kt + Wt
 *    T2 = BSIG0(a) + MAJ(a,b,c)
 *    h' = g
 *    g' = f
 *    f' = e
 *    e' = d + T1
 *    d' = c
 *    c' = b
 *    b' = a
 *    a' = T1 + T2
 *
 *  where Kt is a constant for loop iteration t
 *        Wt is the message scheudle value for iteration t
 *        a -> h are input working words
 *        a' -> h' are output working words
 */
module sha_round(in, Kt, Wt, out);

  `define SHA_ROUND_USE_OPTIMIZED_EXPRESSIONS

  input  wire [ 31:0] Kt;  // constant word (iteration t)
  input  wire [ 31:0] Wt;  // message schedule word (iteration t)
  input  wire [255:0] in;  // working words, a -> h
  output wire [255:0] out; // resultant working words a' -> h'

  wire [31:0] a, b, c, d, e, f, g, h; // working word aliases
  wire [31:0] bsig0_a;                // result of BSIG0(a)
  wire [31:0] bsig1_e;                // result of BSIG1(e)
  wire [31:0] ch_e_f_g;               // result of CH(e,f,g)
  wire [31:0] maj_a_b_c;              // result of MAJ(a,b,c)
  wire [31:0] t1, t2;                 // temporary values

  // Break up input bus into working variables
  assign a = in[255:224];
  assign b = in[223:192];
  assign c = in[191:160];
  assign d = in[159:128];
  assign e = in[127: 96];
  assign f = in[ 95: 64];
  assign g = in[ 63: 32];
  assign h = in[ 31:  0];

  // For SHA256, BSIG0(X) = ROTR2(X) XOR ROTR13(X) XOR ROTR22(X)
  assign bsig0_a =   { a[ 1:0], a[31: 2] }
                   ^ { a[12:0], a[31:13] }
                   ^ { a[21:0], a[31:22] };

  // For SHA256, BSIG1(X) = ROTR6(X) XOR ROTR11(X) XOR ROTR25(X) 
  assign bsig1_e =   { e[ 5:0], e[31: 6] }
                   ^ { e[10:0], e[31:11] }
                   ^ { e[24:0], e[31:25] };

  // For SHA256, CH(X,Y,Z) = (X AND Y) XOR ((NOT X) AND Z)
  `ifdef SHA_ROUND_USE_OPTIMIZED_EXPRESSIONS
  assign ch_e_f_g = g ^ (e & (g ^ f));
  `else
  assign ch_e_f_g = (e & f) ^ ((~e) & g);
  `endif

  // For SHA256, MAJ(X,Y,Z) = (X AND Y) XOR (X AND Z) XOR (Y AND Z)
  `ifdef SHA_ROUND_USE_OPTIMIZED_EXPRESSIONS
  assign maj_a_b_c = ((b & c) | (a & (b | c)));
  `else
  assign maj_a_b_c = (a & b) ^ (a & c) ^ (b & c);
  `endif

  // Update temporary values
  assign t1 = h + bsig1_e + ch_e_f_g + Kt + Wt;
  assign t2 = bsig0_a + maj_a_b_c;

  // Update working words for next stage/iteration
  assign out[255:224] = t1 + t2; // a' = T1 + T2
  assign out[223:192] = a;       // b' = a
  assign out[191:160] = b;       // c' = b
  assign out[159:128] = c;       // d' = c
  assign out[127: 96] = d + t1;  // e' = d + T1
  assign out[ 95: 64] = e;       // f' = e
  assign out[ 63: 32] = f;       // g' = f
  assign out[ 31:  0] = g;       // h' = g

endmodule // sha_iter
