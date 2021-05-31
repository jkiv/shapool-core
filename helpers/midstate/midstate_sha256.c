#include <stdint.h>
#include <stdlib.h>
#include <string.h>

static const uint32_t SHA256_K[64] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

static const uint32_t SHA256_H0[8] = {
    0x6a09e667, 0xbb67ae85,
    0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c,
    0x1f83d9ab, 0x5be0cd19
};

static uint32_t ror32(uint32_t x, uint32_t b) {
  return (x>>b)|(x<<(32-b));
}

static uint32_t maj(uint32_t x, uint32_t y, uint32_t z) {
  //return (x & y) ^ (x & z) ^ (y & z);
  return ((y & z) | (x & (y | z)));
}

static uint32_t ch(uint32_t x, uint32_t y, uint32_t z) {
  //return (x & y) ^ ((~x) & z);
  return z ^ (x & (z ^ y));
}

static uint32_t bsig0(uint32_t x) {
  return ror32(x,2) ^ ror32(x,13) ^ ror32(x,22);
}

static uint32_t bsig1(uint32_t x) {
  return ror32(x,6) ^ ror32(x,11) ^ ror32(x,25);
}

static uint32_t ssig0(uint32_t x) {
  return ror32(x,7) ^ ror32(x,18) ^ (x>>3);
}

static uint32_t ssig1(uint32_t x) {
  return ror32(x,17) ^ ror32(x,19) ^ (x>>10);
}

static uint32_t w_expand(uint32_t w2, uint32_t w7, uint32_t w15, uint32_t w16) {
  return ssig1(w2) + w7 + ssig0(w15) + w16;
}

static uint32_t byte_swap_32(uint32_t x)
{
  return ((x & 0x000000ff) << 24) |
         ((x & 0x0000ff00) <<  8) |
         ((x & 0x00ff0000) >>  8) |
         ((x & 0xff000000) >> 24);
}

static void sha256_update(uint32_t* H, const uint32_t* m) {
  uint32_t w[64] = {0}; // message schedule
  
  uint32_t a,b,c,d,e,f,g,h = 0; // working variables
  uint32_t t1,t2 = 0;           // temporary values

  // Initialize working variables
  a = H[0];
  b = H[1];
  c = H[2];
  d = H[3];
  e = H[4];
  f = H[5];
  g = H[6];
  h = H[7];
  
  // Mangle a-h using m
  for (uint8_t t = 0; t < 64; t++) {
    // Compute w[t]
    if (t < 16) {
      // 32-bit input is considered big-endian by spec
      // whereas x86 is little endian. Swap byte order.
      w[t] = byte_swap_32(m[t]);
    }
    else {
      w[t] = w_expand(w[t-2], w[t-7], w[t-15], w[t-16]);
    }
    
    // Compute t1, t2
    t1 = h;
    t1 += bsig1(e);
    t1 += ch(e,f,g);
    t1 += SHA256_K[t];
    t1 += w[t];

    t2 = bsig0(a);
    t2 += maj(a,b,c);

    // Update working variables (order here matters)
    h = g;
    g = f;
    f = e;
    e = d+t1;
    d = c;
    c = b;
    b = a;
    a = t1+t2;
  }
  
  // Update H
  H[0] += a;
  H[1] += b;
  H[2] += c;
  H[3] += d;
  H[4] += e;
  H[5] += f;
  H[6] += g;
  H[7] += h;
}

void init_state(uint32_t* state) {
  for (size_t i = 0; i < 8; i++) {
    state[i] = SHA256_H0[i];
  }
}

void update_state(uint32_t* state, const uint32_t* block) {
  sha256_update(state, block);
}