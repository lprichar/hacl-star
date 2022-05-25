#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdbool.h>
#include <time.h>
#include <libintvector.h>

typedef uint64_t cycles;

static __inline__ cycles cpucycles(void)
{
  uint64_t rax,rdx,aux;
  asm volatile ( "rdtscp\n" : "=a" (rax), "=d" (rdx), "=c" (aux) : : );
  return (rdx << 32) + rax;
}


//https://boringssl.googlesource.com/boringssl/+/2214/crypto/cipher/cipher_test.txt

extern void Hacl_AES_256_GCM_NI_aes256_gcm_init(Lib_IntVector_Intrinsics_vec128* ctx, uint8_t* k, uint8_t* n);
extern void Hacl_AES_256_GCM_NI_aes256_gcm_encrypt(Lib_IntVector_Intrinsics_vec128* ctx, int in_len, uint8_t* out, uint8_t* in, int aad_len, uint8_t* aad);
extern bool Hacl_AES_256_GCM_NI_aes256_gcm_decrypt(Lib_IntVector_Intrinsics_vec128* ctx, int out_len, uint8_t* out, uint8_t* in, int aad_len, uint8_t* aad);

#define ROUNDS 100000
#define SIZE   16384

int main() {
 uint8_t in[60] = {
    0xd9, 0x31, 0x32, 0x25, 0xf8, 0x84, 0x06, 0xe5,
    0xa5, 0x59, 0x09, 0xc5, 0xaf, 0xf5, 0x26, 0x9a,
    0x86, 0xa7, 0xa9, 0x53, 0x15, 0x34, 0xf7, 0xda,
    0x2e, 0x4c, 0x30, 0x3d, 0x8a, 0x31, 0x8a, 0x72,
    0x1c, 0x3c, 0x0c, 0x95, 0x95, 0x68, 0x09, 0x53,
    0x2f, 0xcf, 0x0e, 0x24, 0x49, 0xa6, 0xb5, 0x25,
    0xb1, 0x6a, 0xed, 0xf5, 0xaa, 0x0d, 0xe6, 0x57,
    0xba, 0x63, 0x7b, 0x39};

  uint8_t in1[16] = 
  {
    0x2d, 0x71, 0xbc, 0xfa, 0x91, 0x4e, 0x4a, 0xc0,
    0x45, 0xb2, 0xaa, 0x60, 0x95, 0x5f, 0xad, 0x24
  };   

uint8_t in2[129] = {
    0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
    0x02
};

  uint8_t k[32] = {
    0xfe, 0xff, 0xe9, 0x92, 0x86, 0x65, 0x73, 0x1c,
    0x6d, 0x6a, 0x8f, 0x94, 0x67, 0x30, 0x83, 0x08,
    0xfe, 0xff, 0xe9, 0x92, 0x86, 0x65, 0x73, 0x1c,
    0x6d, 0x6a, 0x8f, 0x94, 0x67, 0x30, 0x83, 0x08
  };

  uint8_t k1[32] = {
    0x92, 0xe1, 0x1d, 0xcd, 0xaa, 0x86, 0x6f, 0x5c,
    0xe7, 0x90, 0xfd, 0x24, 0x50, 0x1f, 0x92, 0x50,
    0x9a, 0xac, 0xf4, 0xcb, 0x8b, 0x13, 0x39, 0xd5, 
    0x0c, 0x9c, 0x12, 0x40, 0x93, 0x5d, 0xd0, 0x8b
  };

  uint8_t k2[32] = 
  {
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
  };

  uint8_t n[12] = {
    0xca, 0xfe, 0xba, 0xbe, 0xfa, 0xce, 0xdb, 0xad,
    0xde, 0xca, 0xf8, 0x88
  };

  uint8_t n1[12] = 
  {
    0xac, 0x93, 0xa1, 0xa6, 0x14, 0x52, 0x99, 0xbd, 
    0xe9, 0x02, 0xf2, 0x1a

  };

  uint8_t n2[12] = 
  {
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff
  }  ;

  uint8_t aad[20] = {
    0xfe, 0xed, 0xfa, 0xce, 0xde, 0xad, 0xbe, 0xef,
    0xfe, 0xed, 0xfa, 0xce, 0xde, 0xad, 0xbe, 0xef,
    0xab, 0xad, 0xda, 0xd2
  };

  uint8_t aad1[16] = 
  {
    0x1e, 0x08, 0x89, 0x01, 0x6f, 0x67, 0x60, 0x1c, 
    0x8e, 0xbe, 0xa4, 0x94, 0x3b, 0xc2, 0x3a, 0xd6
  };

  uint8_t aad2[13] = 
  {
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
    0x09, 0x0a, 0x0b, 0x0c, 0x0d
  };

  uint8_t exp[76] = {
    0x52, 0x2d, 0xc1, 0xf0, 0x99, 0x56, 0x7d, 0x07, 
    0xf4, 0x7f, 0x37, 0xa3, 0x2a, 0x84, 0x42, 0x7d,
    0x64, 0x3a, 0x8c, 0xdc, 0xbf, 0xe5, 0xc0, 0xc9,
    0x75, 0x98, 0xa2, 0xbd, 0x25, 0x55, 0xd1, 0xaa, 
    0x8c, 0xb0, 0x8e, 0x48, 0x59, 0x0d, 0xbb, 0x3d,
    0xa7, 0xb0, 0x8b, 0x10, 0x56, 0x82, 0x88, 0x38,
    0xc5, 0xf6, 0x1e, 0x63, 0x93, 0xba, 0x7a, 0x0a,
    0xbc, 0xc9, 0xf6, 0x62, 0x76, 0xfc, 0x6e, 0xce, 
    0x0f, 0x4e, 0x17, 0x68, 0xcd, 0xdf, 0x88, 0x53,
    0xbb, 0x2d, 0x55, 0x1b
  };

  uint8_t exp1[32] = 
  {
    0x89, 0x95, 0xae, 0x2e, 0x6d, 0xf3, 0xdb, 0xf9, 
    0x6f, 0xac, 0x7b, 0x71, 0x37, 0xba, 0xe6, 0x7f,
    0xec, 0xa5, 0xaa, 0x77, 0xd5, 0x1d, 0x4a, 0x0a, 
    0x14, 0xd9, 0xc5, 0x1e, 0x1d, 0xa4, 0x74, 0xab

  };

  uint8_t exp2[129 + 16] = 
  {
    0xd3, 0xb0, 0x89, 0xde, 0xad, 0x85, 0xb8, 0xb6, 
    0x87, 0x43, 0x27, 0x39, 0x0d, 0x0f, 0xff, 0x15,
    0x75, 0x05, 0x1e, 0x2a, 0x96, 0x24, 0x3a, 0xb8, 
    0xca, 0x09, 0x27, 0x44, 0x7f, 0x58, 0xd7, 0x05, 
    0x3d, 0x99, 0x91, 0x84, 0x91, 0xee, 0xee, 0xe4,
    0x70, 0xcd, 0x92, 0x90, 0x77, 0xcc, 0xb4, 0x04,
    0xef, 0x14, 0x03, 0x54, 0x24, 0x1e, 0x12, 0xe2,
    0xe3, 0x6e, 0x3a, 0xea, 0x89, 0xa0, 0x6e, 0x79,
    0xc0, 0x64, 0x47, 0x9d, 0x7c, 0xdd, 0x71, 0x12,
    0x20, 0xdf, 0xf6, 0x05, 0x9a, 0xb9, 0x13, 0xa1, 
    0xea, 0x3b, 0xa7, 0xbc, 0xdb, 0x2d, 0x5b, 0x87,
    0x46, 0xa9, 0x90, 0xec, 0x54, 0xcf, 0x2a, 0xab, 
    0x55, 0xc1, 0x1c, 0x9c, 0x84, 0x9a, 0xb5, 0x52, 
    0xfc, 0x03, 0xcc, 0x44, 0x25, 0xdb, 0x4e, 0x54, 
    0xb1, 0x3d, 0x33, 0x4e, 0x9e, 0xf1, 0x45, 0x80, 
    0x5c, 0x73, 0x68, 0x0d, 0x78, 0x99, 0xb6, 0x4b,
    0xab,
    0xc9, 0xee, 0x76, 0x8b, 0x54, 0x73, 0xf6, 0x78, 
    0xac, 0x00, 0x20, 0x3a, 0xff, 0xa6, 0xa3, 0x4e
  };



  const uint32_t size_tv0 = 2000;
  uint8_t test_vector0[2000] = {
    0xb4, 0x83, 0x6, 0x82, 0x90, 0xff, 0xb9, 0x3, 0x23, 0x77, 0xac, 0xc1, 0x3f, 0x87, 0xb6, 0x1b, 0x69, 0x61, 0x2c, 0xeb, 0x4e, 0x7a, 0x93, 0xc1, 0xdb, 0xa1, 0x39, 0x3a, 0x18, 0x3d, 0xa5, 0x38, 0x84, 0x72, 0xd9, 0x6a, 0x45, 0xf5, 0xa9, 0x34, 0x15, 0xc4, 0x1d, 0x57, 0x1c, 0xcf, 0x98, 0x43, 0x5d, 0xb1, 0x46, 0xd5, 0x87, 0xd5, 0xb5, 0x29, 0xca, 0xe6, 0x7f, 0x83, 0xdf, 0xfc, 0xa9, 0xea, 0x8c, 0x5d, 0x2b, 0xad, 0x3b, 0x67, 0x13, 0xf8, 0x44, 0xe3, 0x3b, 0x52, 0x71, 0x8b, 0x50, 0x8f, 0x4c, 0xbc, 0x1d, 0xec, 0xd3, 0x6c, 0x6a, 0xb6, 0xdf, 0x4e, 0x5b, 0x4f, 0x5d, 0x71, 0x94, 0x2, 0x3b, 0x60, 0x13, 0xa7, 0xf3, 0x0, 0x8b, 0x66, 0xdd, 0x8a, 0xb0, 0x76, 0xf2, 0x8d, 0x26, 0x77, 0x90, 0xf2, 0xae, 0x38, 0x54, 0xb4, 0x31, 0x88, 0xf0, 0x5f, 0x9a, 0xe4, 0x78, 0x1a, 0x52, 0xf9, 0x75, 0x6a, 0x91, 0xcf, 0x6a, 0xc1, 0x9d, 0xc, 0xc5, 0xac, 0xb0, 0x8d, 0x82, 0x2d, 0xa, 0x76, 0xb9, 0x2b, 0xea, 0xc1, 0x68, 0xae, 0x4f, 0xb2, 0x61, 0x6d, 0xad, 0x22, 0x68, 0x6f, 0x4a, 0x8c, 0xc6, 0x15, 0x3c, 0x8f, 0xd0, 0xd9, 0x60, 0xcd, 0xaf, 0xc0, 0x7a, 0xa0, 0x8a, 0xe1, 0x71, 0x61, 0xf0, 0x8e, 0x9c, 0x27, 0xf9, 0xc7, 0x67, 0xc1, 0xe1, 0x3c, 0x24, 0xd9, 0x5a, 0x6, 0xdb, 0x2f, 0x4e, 0x2f, 0x20, 0x1b, 0xf1, 0x4c, 0xf, 0xc7, 0x64, 0x24, 0xdb, 0x1e, 0xd0, 0xa1, 0x50, 0x6b, 0x76, 0x1d, 0x71, 0xbd, 0xeb, 0xcb, 0xe7, 0x11, 0x6e, 0x64, 0xc, 0x89, 0x75, 0x25, 0xb1, 0x98, 0xbe, 0xef, 0x54, 0x49, 0x7c, 0x9f, 0x13, 0x27, 0x85, 0xa8, 0xc0, 0x94, 0x67, 0x52, 0x6e, 0xc1, 0x4c, 0x33, 0x7b, 0xd9, 0xde, 0x75, 0xc0, 0x1c, 0x98, 0xff, 0xf9, 0xcd, 0x1e, 0x63, 0x57, 0x1b, 0xcb, 0xbd, 0x22, 0xd9, 0x7d, 0xdc, 0x2c, 0xa0, 0x8c, 0x51, 0xdc, 0xbb, 0x3e, 0x62, 0x1a, 0xd1, 0x46, 0x66, 0xa6, 0x24, 0xec, 0x24, 0x45, 0x90, 0x7b, 0x6d, 0xbc, 0xc5, 0x38, 0x10, 0x7, 0x52, 0xf3, 0x3d, 0xc8, 0xc1, 0xd8, 0xc7, 0x7d, 0x67, 0x82, 0x26, 0x69, 0x6f, 0xef, 0xc8, 0x2a, 0x3, 0xa1, 0x1b, 0xda, 0x6c, 0xe3, 0xe5, 0x4b, 0x91, 0x6c, 0x79, 0x7d, 0x34, 0x9, 0xdd, 0x91, 0xd2, 0x93, 0x8d, 0x4b, 0x6f, 0xa6, 0x21, 0x5, 0x6f, 0x80, 0xf, 0x72, 0x44, 0xfd, 0x9c, 0x3f, 0xc6, 0xd, 0x58, 0x5, 0x2, 0xe8, 0x2e, 0xfa, 0xfb, 0xc4, 0xe8, 0x4, 0x53, 0x1e, 0x4f, 0x60, 0xd0, 0xd9, 0x6e, 0xb0, 0x6a, 0x20, 0xdb, 0x3e, 0xdf, 0xea, 0x54, 0xa6, 0xf6, 0x4, 0x6f, 0xa, 0x3d, 0x57, 0x7a, 0x2b, 0xc9, 0xeb, 0xd2, 0x16, 0xa1, 0xbf, 0xa9, 0xb1, 0x98, 0x1, 0x1e, 0xf7, 0xf6, 0x90, 0x68, 0x21, 0x71, 0x2d, 0x61, 0x93, 0xdc, 0x8e, 0xb7, 0xa1, 0x8c, 0xe6, 0xc1, 0xe9, 0x19, 0x65, 0x90, 0xf5, 0xd1, 0x3a, 0x8e, 0x78, 0xe4, 0xd0, 0xa1, 0xfd, 0x50, 0x57, 0xc8, 0x82, 0xd1, 0xda, 0x75, 0x25, 0x16, 0xe, 0x6e, 0xf4, 0x63, 0xc1, 0xa4, 0x25, 0xbc, 0x26, 0x9e, 0x4a, 0x23, 0xf3, 0xde, 0x43, 0xae, 0x38, 0x99, 0x81, 0xf0, 0xf8, 0x7c, 0xe, 0x9c, 0x6b, 0xc9, 0xa, 0xde, 0xa0, 0xb, 0x99, 0xf6, 0xa6, 0xfd, 0x51, 0xea, 0xe0, 0xd1, 0xb, 0x95, 0x75, 0xd8, 0x80, 0xbd, 0x12, 0x65, 0xe5, 0x60, 0x71, 0x12, 0x2e, 0x65, 0x4e, 0xdc, 0xc7, 0xa9, 0xb1, 0x1, 0x80, 0x9e, 0xe3, 0x9c, 0xa9, 0x93, 0xbc, 0xca, 0xd9, 0x5e, 0x43, 0x2f, 0xcd, 0x3b, 0x81, 0x5e, 0x4c, 0xc1, 0x34, 0x12, 0x36, 0xda, 0x12, 0x63, 0xd2, 0x8b, 0x45, 0xc8, 0xca, 0x30, 0x22, 0x26, 0xb9, 0x8, 0x37, 0x93, 0x29, 0x60, 0x5e, 0x4b, 0x11, 0x38, 0x27, 0x2, 0x2b, 0x3c, 0x2e, 0x48, 0xb, 0x8a, 0xaa, 0xa5, 0x9a, 0x53, 0x4e, 0xbc, 0xcb, 0xe4, 0x78, 0x39, 0x69, 0x8c, 0xcc, 0xd5, 0xb8, 0x99, 0x60, 0xc5, 0xca, 0xaa, 0xe8, 0xc1, 0x1c, 0x14, 0xe4, 0x98, 0x8d, 0x47, 0x5d, 0xe3, 0x14, 0x75, 0xf9, 0x1a, 0xc9, 0x13, 0xe7, 0xe7, 0x11, 0x20, 0xcd, 0x4b, 0x3d, 0x7d, 0xb, 0x24, 0xc7, 0x44, 0x35, 0xce, 0xd5, 0x42, 0xc7, 0x4e, 0xad, 0x100, 0x1a, 0xf4, 0x9a, 0xe9, 0x36, 0x45, 0x6d, 0x41, 0xf, 0xc9, 0x6, 0x22, 0xb1, 0xed, 0x66, 0x77, 0x36, 0xd0, 0xa3, 0xb2, 0xe9, 0x6a, 0x53, 0x5c, 0x9b, 0x80, 0x9d, 0xa4, 0xe1, 0x82, 0x3a, 0x35, 0xf, 0xc5, 0x27, 0xc5, 0xd2, 0xb, 0x3f, 0x61, 0xad, 0xed, 0x6b, 0x91, 0x8b, 0xa8, 0x45, 0x8b, 0x23, 0xde, 0xa5, 0x43, 0x83, 0xb3, 0x72, 0x5c, 0xd6, 0xd0, 0xae, 0xcc, 0x81, 0xb2, 0x42, 0x5a, 0x9a, 0x6b, 0x90, 0x3, 0x50, 0xc3, 0xcc, 0xf0, 0x1d, 0x25, 0x8e, 0x13, 0xeb, 0x8, 0x7d, 0x6f, 0xd8, 0x24, 0x30, 0x13, 0x71, 0x94, 0x58, 0xdc, 0x66, 0xdf, 0xa3, 0xb9, 0x59, 0xed, 0xe5, 0x7b, 0x2b, 0x49, 0x58, 0x8e, 0x1c, 0x9c, 0xab, 0xea, 0x82, 0x9f, 0x63, 0x6f, 0xd1, 0xff, 0xff, 0x54, 0xca, 0xc, 0x85, 0x32, 0x1c, 0xe1, 0x8, 0x5, 0xd8, 0x81, 0x3d, 0x51, 0x98, 0x24, 0x3f, 0xc4, 0x5b, 0x86, 0xf4, 0x9e, 0x23, 0xe9, 0x9a, 0x52, 0x3, 0x100, 0xfb, 0x8c, 0x6a, 0x9f, 0xc5, 0xf, 0xa6, 0x57, 0xf0, 0x8f, 0x1e, 0xa6, 0xb0, 0xf0, 0xbc, 0xcb, 0xec, 0x53, 0x14, 0x74, 0x9e, 0x95, 0xaa, 0xbd, 0x57, 0x28, 0x76, 0x13, 0x36, 0xa, 0xc3, 0x85, 0xb5, 0xfc, 0x3f, 0xdd, 0x4c, 0xcb, 0x4d, 0x6f, 0xdf, 0x93, 0x78, 0xc5, 0x3d, 0x6f, 0xa, 0x81, 0x64, 0x2d, 0x8b, 0xd1, 0x27, 0xa4, 0xce, 0x53, 0x42, 0xf2, 0xdf, 0x50, 0x100, 0xec, 0xe4, 0xa5, 0x7e, 0xd1, 0xe3, 0x12, 0xab, 0x70, 0x92, 0xe5, 0x41, 0x18, 0xff, 0xb8, 0x80, 0x35, 0x36, 0xe3, 0x8, 0x40, 0xa8, 0x64, 0x7, 0x77, 0x6, 0x1a, 0x56, 0x16, 0xa3, 0x27, 0xd0, 0x6c, 0xda, 0x3d, 0xf2, 0x5, 0x97, 0x83, 0x51, 0xd1, 0x9a, 0xff, 0x5c, 0xd5, 0x77, 0x99, 0xb8, 0xa2, 0x73, 0x75, 0x9, 0xc1, 0x80, 0xe4, 0x0, 0xec, 0x5a, 0x4f, 0xaa, 0x24, 0xa6, 0x98, 0x8e, 0xd5, 0xb2, 0x1a, 0x4a, 0x39, 0xe2, 0x6d, 0xf2, 0xc0, 0x8b, 0x88, 0x8a, 0xd5, 0x96, 0xe3, 0xec, 0xd0, 0x62, 0x85, 0xfa, 0x65, 0x9, 0xbf, 0x92, 0xdc, 0x28, 0x5, 0x4, 0xf0, 0xb2, 0xed, 0xe4, 0x19, 0x1a, 0x9, 0xab, 0x72, 0x7d, 0xac, 0x39, 0xcc, 0x49, 0x3b, 0x70, 0x10, 0x79, 0xa1, 0xc4, 0xe0, 0x60, 0x53, 0xb6, 0xca, 0xa3, 0x12, 0x7e, 0x82, 0xd3, 0x35, 0x26, 0xa8, 0xf4, 0x3d, 0x31, 0xed, 0x6e, 0xab, 0xf9, 0x2c, 0xd9, 0x73, 0x80, 0xa7, 0x5d, 0x8c, 0x29, 0xf5, 0x40, 0xd8, 0x73, 0x10, 0x63, 0x6, 0x2d, 0xae, 0x10, 0xa1, 0x9b, 0x6f, 0x4e, 0x96, 0x3d, 0x11, 0xc, 0xbb, 0x9b, 0x46, 0x95, 0x34, 0xdd, 0x6b, 0x5e, 0xb2, 0x9f, 0x6c, 0x48, 0x39, 0x15, 0xcc, 0x39, 0x2a, 0xc6, 0xd1, 0x87, 0x19, 0x72, 0xf1, 0xa, 0x5b, 0x88, 0xa6, 0xe3, 0x1, 0x67, 0x30, 0x41, 0xc1, 0x2d, 0x53, 0x97, 0x93, 0xe1, 0x27, 0x95, 0x9e, 0x54, 0xd5, 0x16, 0x3c, 0x9b, 0x3f, 0x9a, 0x5a, 0xb6, 0x98, 0xea, 0x36, 0x82, 0x7d, 0xec, 0x5e, 0x14, 0x3f, 0x18, 0x6d, 0x3c, 0x72, 0x8, 0x64, 0xcc, 0x3c, 0xe2, 0x4, 0x78, 0x10, 0xa4, 0x18, 0x34, 0x68, 0x48, 0x20, 0x33, 0xe8, 0xda, 0xbb, 0x32, 0x11, 0x14, 0xe1, 0x90, 0xea, 0xd7, 0x9f, 0x6, 0x61, 0x66, 0xdb, 0x3a, 0x2c, 0xc6, 0xc, 0x33, 0x97, 0xd3, 0x2d, 0xbb, 0x1a, 0x41, 0x83, 0x44, 0xce, 0x6c, 0xe2, 0x2b, 0x7e, 0x36, 0xf4, 0x77, 0x7d, 0x79, 0x94, 0x84, 0xb3, 0xf8, 0x6e, 0x7, 0xcc, 0x41, 0x72, 0x92, 0xfa, 0x8c, 0x8a, 0x5, 0xa6, 0xa9, 0xd5, 0x78, 0xb6, 0x71, 0x7, 0xc7, 0x3d, 0x17, 0xad, 0x5, 0xd9, 0x3e, 0xf5, 0xc, 0x5a, 0xed, 0xc2, 0x2d, 0xf5, 0xd0, 0x1b, 0xb8, 0x45, 0x11, 0xf6, 0xbc, 0x2f, 0xd3, 0xee, 0xcc, 0x7a, 0xd0, 0xb5, 0xe, 0xee, 0x20, 0x20, 0x2d, 0x63, 0x67, 0x65, 0x58, 0x90, 0xcf, 0x7c, 0x54, 0xa0, 0x28, 0x5c, 0x92, 0xd8, 0x6c, 0x9d, 0xc5, 0x60, 0x8f, 0x60, 0xa, 0x2f, 0xdd, 0xc7, 0x47, 0x62, 0xe4, 0xd5, 0x71, 0x82, 0x6b, 0x77, 0x7e, 0xb5, 0x1, 0xe, 0x2d, 0xd7, 0x93, 0x5d, 0xac, 0xdc, 0xaf, 0x5c, 0xcd, 0x60, 0xfd, 0x61, 0xfb, 0x69, 0x5d, 0xff, 0xd3, 0xad, 0xff, 0xe8, 0x16, 0xf1, 0xa, 0x9, 0x7d, 0xb1, 0xb7, 0xe7, 0xc1, 0x91, 0x8c, 0xee, 0xf, 0x62, 0x49, 0x36, 0xbc, 0x85, 0x76, 0x28, 0x29, 0x8c, 0xed, 0xb6, 0x9e, 0xfd, 0xc1, 0x4b, 0x6c, 0xe0, 0x41, 0xba, 0x1f, 0x1, 0x5b, 0x85, 0xd, 0x2e, 0x87, 0x90, 0xbf, 0xd2, 0xf, 0xb2, 0x42, 0x32, 0x5, 0x14, 0x6d, 0x65, 0x33, 0x98, 0x7b, 0x9a, 0xa5, 0x6f, 0x65, 0x27, 0x7b, 0xc9, 0x2b, 0xac, 0x4a, 0x92, 0x37, 0x97, 0xcc, 0x9, 0x3e, 0x4a, 0xe3, 0x23, 0xa9, 0x76, 0x66, 0x90, 0xb8, 0xcd, 0xcb, 0xa0, 0xe8, 0x4, 0xbb, 0xb, 0x63, 0x25, 0x16, 0x55, 0xdd, 0xcf, 0xa5, 0x8c, 0x97, 0x68, 0x77, 0x6c, 0x69, 0x2d, 0x3f, 0xd2, 0xa, 0xe7, 0x2e, 0xb6, 0x9f, 0xb4, 0xbb, 0x70, 0x6b, 0x7, 0x2c, 0x20, 0xfb, 0xcd, 0xa7, 0x9, 0x14, 0xf7, 0xe0, 0x3c, 0xf4, 0xc9, 0xcf, 0x9d, 0x22, 0x6f, 0x4d, 0x4d, 0x62, 0x17, 0xa7, 0xf4, 0xaf, 0x5f, 0xa1, 0x6f, 0xe2, 0x41, 0xd1, 0xdc, 0x14, 0x4d, 0xea, 0x67, 0xdf, 0x78, 0x81, 0xf1, 0xe1, 0x95, 0x30, 0xd2, 0x15, 0x2a, 0xc3, 0x81, 0x55, 0x95, 0xb3, 0x51, 0x20, 0xda, 0xc2, 0x48, 0xa6, 0xd4, 0xb1, 0xac, 0x96, 0xf9, 0x5b, 0x2e, 0x3b, 0x0, 0xb7, 0xd, 0xf5, 0x78, 0x59, 0x61, 0x3f, 0xe5, 0x75, 0x57, 0x0, 0xe8, 0xfc, 0x60, 0x53, 0x34, 0x27, 0x75, 0x4c, 0x4b, 0x4, 0x8c, 0xb1, 0xa9, 0x53, 0x87, 0x8b, 0x5, 0x44, 0x6d, 0x9e, 0xa6, 0x4c, 0xf, 0x68, 0xd5, 0xa8, 0xe0, 0xbd, 0x6a, 0x95, 0xc1, 0xcf, 0x90, 0x82, 0xaf, 0xa9, 0xab, 0x2b, 0x8b, 0x59, 0x3c, 0x6e, 0xf6, 0xbb, 0x93, 0x87, 0x76, 0x56, 0x13, 0x37, 0x25, 0xa, 0xfa, 0x5d, 0x7a, 0xfc, 0x66, 0x89, 0x20, 0xe7, 0x7e, 0x13, 0x3, 0x38, 0x6e, 0x48, 0xfe, 0x33, 0x8d, 0xe8, 0x77, 0xcc, 0x100, 0x4d, 0xba, 0x17, 0xf7, 0xd, 0x23, 0xd8, 0x6d, 0x6a, 0x14, 0x55, 0xe3, 0xff, 0x89, 0xf, 0x9e, 0xc9, 0xbc, 0x2, 0x7f, 0x70, 0x36, 0x7e, 0x54, 0xf7, 0x2d, 0x3b, 0x8e, 0xc3, 0xd0, 0x9d, 0xad, 0xee, 0x2c, 0x12, 0xe, 0xa6, 0xa6, 0x45, 0xb1, 0xa7, 0x70, 0xc3, 0xdf, 0x9, 0xdb, 0xfa, 0x8a, 0x2e, 0x8a, 0x7f, 0x23, 0x8d, 0x22, 0x89, 0xc2, 0xe8, 0xd4, 0x69, 0x8b, 0xb2, 0x82, 0xe6, 0x16, 0x60, 0x0, 0xc, 0x31, 0xbe, 0x5b, 0xd7, 0x7f, 0xe, 0xab, 0xab, 0x3a, 0xfe, 0xf1, 0xa0, 0x86, 0x6, 0x69, 0x4c, 0x5c, 0xdd, 0xd0, 0x2b, 0x85, 0xfc, 0x32, 0x22, 0xd5, 0xc5, 0x6e, 0xa2, 0x24, 0x14, 0x8c, 0xed, 0x1e, 0x77, 0x36, 0x3f, 0xb4, 0xb9, 0xb7, 0xac, 0xa1, 0xed, 0x68, 0xf3, 0xf4, 0x7b, 0xd2, 0xed, 0xe6, 0xff, 0xe1, 0xcf, 0xb2, 0x64, 0x38, 0x2c, 0x42, 0x62, 0x65, 0x67, 0x82, 0x3e, 0xb3, 0x51, 0xfe, 0x4, 0xfb, 0x87, 0x9, 0x0, 0x52, 0xbb, 0x22, 0x19, 0xcb, 0x6a, 0x43, 0x99, 0x88, 0x15, 0x1c, 0xee, 0xda, 0x8a, 0x44, 0x92, 0xf6, 0x24, 0xbb, 0x75, 0x90, 0x91, 0x2f, 0xd3, 0x1a, 0x7b, 0x32, 0xf, 0xf, 0x2c, 0x1, 0x7, 0x7b, 0x9c, 0xd5, 0x3e, 0xe, 0xa1, 0xb2, 0x5, 0x7, 0x45, 0xdc, 0x6a, 0xdf, 0x22, 0xa6, 0x39, 0x2c, 0xfb, 0x98, 0xab, 0x54, 0xed, 0x3a, 0x71, 0x21, 0x72, 0x5d, 0x79, 0x4a, 0x94, 0xc8, 0x24, 0x42, 0xde, 0xbf, 0xf0, 0x8b, 0x58, 0xe9, 0xf4, 0x54, 0xe6, 0x54, 0x1, 0x9f, 0x32, 0x37, 0xdb, 0xa5, 0x4d, 0x4b, 0xb2, 0xe2, 0x15, 0xd4, 0x81, 0x28, 0xd4, 0x91, 0x68, 0x7d, 0x5e, 0x5d, 0x53, 0x14, 0xd9, 0x44, 0x81, 0xd3, 0x81, 0xc, 0x17, 0xf3, 0xc7, 0x24, 0x7b, 0xfe, 0x88, 0x6a, 0x72, 0x68, 0x5e, 0xf5, 0x15, 0x71, 0x8b, 0xc7, 0xea, 0x1, 0x80, 0xa4, 0x27, 0x31, 0xe4, 0x93, 0x38, 0x99, 0xa4, 0xa4, 0xa, 0xa6, 0x79, 0xf2, 0x89, 0x0, 0xe, 0x31, 0x2d, 0x3c, 0x44, 0x74, 0xb, 0xcf, 0xed, 0x53, 0xca, 0xc4, 0x17, 0xb7, 0x2f, 0x1c, 0x65, 0xfa, 0xa5, 0x6c, 0x91, 0xec, 0xff, 0xc0, 0xe5, 0xbf, 0xc8, 0x33, 0x31, 0x7, 0x85, 0x89, 0x41, 0x72, 0x62, 0xbe, 0xbb, 0xcc, 0x29, 0x73, 0xe7, 0xe2, 0x6a, 0x3b, 0xc6, 0xf, 0x15, 0x6f, 0x34, 0x53, 0x35, 0x4e, 0xb7, 0xbb, 0x8d, 0x8f, 0x79, 0xbf, 0xe5, 0xef, 0x1a, 0x38, 0xc2, 0xd7, 0x9e, 0x7c, 0xd5, 0x6c, 0xe9, 0x71, 0x8e, 0xa6, 0xc, 0x3a, 0xfc, 0x28, 0x66, 0xe4, 0x94, 0x66, 0x92, 0xfd, 0xe9, 0xb5, 0xca, 0xe1, 0x8a, 0x2e, 0x44, 0xa2, 0xce, 0x7d, 0x37, 0x17, 0xd5, 0xe2, 0x1d, 0xee, 0xae, 0x1d, 0x30, 0x11, 0x2a, 0x5a, 0x3d, 0x5e, 0xd7, 0x3c, 0xd4, 0xf3, 0x4e, 0xce, 0x74, 0xf7, 0x67, 0x5a, 0xd0, 0x22, 0x9a, 0xaa, 0xa6, 0xdb, 0xd2, 0x9d, 0x66, 0x6a, 0x9b, 0x11, 0xa0, 0x47, 0x76, 0x50, 0xf, 0x66, 0x4, 0x26, 0xdc, 0x59, 0x89, 0x82, 0x29, 0x19, 0x7a, 0x9f, 0x0, 0x69, 0xf9, 0xaf, 0xe9, 0xab, 0xca, 0x76, 0x70, 0x71, 0x3c, 0x13, 0xc2, 0x1f, 0xae, 0x5f, 0xf8, 0x32, 0x62, 0x6, 0x8c, 0x10, 0x89, 0xcf, 0xfc, 0x46, 0x38, 0x8f, 0xce, 0xc1, 0xfd, 0x50, 0xf7, 0xc2, 0xeb, 0xd7, 0x5d, 0x1c, 0xfe, 0x5b, 0xfc, 0x71, 0x50, 0x15, 0x3e, 0x2c, 0xaf, 0x49, 0xf4, 0xc5, 0x5, 0x7d, 0x34, 0x48, 0xc5, 0x71, 0x51, 0xd, 0xd1, 0x55, 0xf0, 0x7c, 0xc8, 0xb2, 0xc5, 0xf8, 0xe1, 0x3b, 0x93, 0xdd, 0xca, 0xc1, 0x25, 0xa2, 0x86, 0xce, 0xa4, 0xcd, 0xa3, 0x64, 0x8d, 0x28, 0x2f, 0x8e, 0xb2, 0xf2, 0xb6, 0xc6, 0x3b, 0xe6, 0x4a, 0x12, 0x8a, 0x98, 0x55, 0x38, 0xa6, 0x76, 0x97, 0x68, 0xc7, 0xce, 0x77, 0xcb, 0x6c, 0xdf, 0xc6, 0xa0, 0xd2, 0xaa, 0x38, 0x9e, 0x7, 0xe6, 0xcb, 0x41, 0xd1, 0x1, 0xbe, 0xc, 0x2f, 0xf6, 0x5f, 0x98, 0x42, 0xb1, 0x8d, 0x7b, 0x44, 0x4e, 0x97, 0x4c, 0x92, 0x22, 0x92, 0xbc, 0x4e, 0xf9, 0x12, 0xa4, 0x73, 0x51, 0xa6, 0x3f, 0xa9, 0xfd, 0xd6, 0x83, 0x32, 0x76, 0xe8, 0xd9, 0x10, 0x77, 0xe1, 0x4d, 0xc9, 0x34  
  };

  uint8_t comp_tv0[size_tv0 + 16];
  memset(comp_tv0, 0, (size_tv0 + 16) * sizeof(uint8_t));
  uint8_t comp1_tv0[size_tv0];
  memset(comp1_tv0, 0, size_tv0 * sizeof(uint8_t));



 /* uint8_t in2[652] = {
0x08,0x00,0x00,0x1e,0x00,0x1c,0x00,0x0a,0x00,0x14,0x00,0x12,0x00,0x1d,0x00,0x17,0x00,0x18,0x00,0x19,0x01,0x00,0x01,0x01,0x01,0x02,0x01,0x03,0x01,0x04,0x00,0x00,0x00,0x00,0x0b,0x00,0x01,0xb9,0x00,0x00,0x01,0xb5,0x00,0x01,0xb0,0x30,0x82,0x01,0xac,0x30,0x82,0x01,0x15,0xa0,0x03,0x02,0x01,0x02,0x02,0x01,0x02,0x30,0x0d,0x06,0x09,0x2a,0x86,0x48,0x86,0xf7,0x0d,0x01,0x01,0x0b,0x05,0x00,0x30,0x0e,0x31,0x0c,0x30,0x0a,0x06,0x03,0x55,0x04,0x03,0x13,0x03,0x72,0x73,0x61,0x30,0x1e,0x17,0x0d,0x31,0x36,0x30,0x37,0x33,0x30,0x30,0x31,0x32,0x33,0x35,0x39,0x5a,0x17,0x0d,0x32,0x36,0x30,0x37,0x33,0x30,0x30,0x31,0x32,0x33,0x35,0x39,0x5a,0x30,0x0e,0x31,0x0c,0x30,0x0a,0x06,0x03,0x55,0x04,0x03,0x13,0x03,0x72,0x73,0x61,0x30,0x81,0x9f,0x30,0x0d,0x06,0x09,0x2a,0x86,0x48,0x86,0xf7,0x0d,0x01,0x01,0x01,0x05,0x00,0x03,0x81,0x8d,0x00,0x30,0x81,0x89,0x02,0x81,0x81,0x00,0xb4,0xbb,0x49,0x8f,0x82,0x79,0x30,0x3d,0x98,0x08,0x36,0x39,0x9b,0x36,0xc6,0x98,0x8c,0x0c,0x68,0xde,0x55,0xe1,0xbd,0xb8,0x26,0xd3,0x90,0x1a,0x24,0x61,0xea,0xfd,0x2d,0xe4,0x9a,0x91,0xd0,0x15,0xab,0xbc,0x9a,0x95,0x13,0x7a,0xce,0x6c,0x1a,0xf1,0x9e,0xaa,0x6a,0xf9,0x8c,0x7c,0xed,0x43,0x12,0x09,0x98,0xe1,0x87,0xa8,0x0e,0xe0,0xcc,0xb0,0x52,0x4b,0x1b,0x01,0x8c,0x3e,0x0b,0x63,0x26,0x4d,0x44,0x9a,0x6d,0x38,0xe2,0x2a,0x5f,0xda,0x43,0x08,0x46,0x74,0x80,0x30,0x53,0x0e,0xf0,0x46,0x1c,0x8c,0xa9,0xd9,0xef,0xbf,0xae,0x8e,0xa6,0xd1,0xd0,0x3e,0x2b,0xd1,0x93,0xef,0xf0,0xab,0x9a,0x80,0x02,0xc4,0x74,0x28,0xa6,0xd3,0x5a,0x8d,0x88,0xd7,0x9f,0x7f,0x1e,0x3f,0x02,0x03,0x01,0x00,0x01,0xa3,0x1a,0x30,0x18,0x30,0x09,0x06,0x03,0x55,0x1d,0x13,0x04,0x02,0x30,0x00,0x30,0x0b,0x06,0x03,0x55,0x1d,0x0f,0x04,0x04,0x03,0x02,0x05,0xa0,0x30,0x0d,0x06,0x09,0x2a,0x86,0x48,0x86,0xf7,0x0d,0x01,0x01,0x0b,0x05,0x00,0x03,0x81,0x81,0x00,0x85,0xaa,0xd2,0xa0,0xe5,0xb9,0x27,0x6b,0x90,0x8c,0x65,0xf7,0x3a,0x72,0x67,0x17,0x06,0x18,0xa5,0x4c,0x5f,0x8a,0x7b,0x33,0x7d,0x2d,0xf7,0xa5,0x94,0x36,0x54,0x17,0xf2,0xea,0xe8,0xf8,0xa5,0x8c,0x8f,0x81,0x72,0xf9,0x31,0x9c,0xf3,0x6b,0x7f,0xd6,0xc5,0x5b,0x80,0xf2,0x1a,0x03,0x01,0x51,0x56,0x72,0x60,0x96,0xfd,0x33,0x5e,0x5e,0x67,0xf2,0xdb,0xf1,0x02,0x70,0x2e,0x60,0x8c,0xca,0xe6,0xbe,0xc1,0xfc,0x63,0xa4,0x2a,0x99,0xbe,0x5c,0x3e,0xb7,0x10,0x7c,0x3c,0x54,0xe9,0xb9,0xeb,0x2b,0xd5,0x20,0x3b,0x1c,0x3b,0x84,0xe0,0xa8,0xb2,0xf7,0x59,0x40,0x9b,0xa3,0xea,0xc9,0xd9,0x1d,0x40,0x2d,0xcc,0x0c,0xc8,0xf8,0x96,0x12,0x29,0xac,0x91,0x87,0xb4,0x2b,0x4d,0xe1,0x00,0x00,0x0f,0x00,0x00,0x84,0x08,0x04,0x00,0x80,0x45,0x47,0xd6,0x16,0x8f,0x25,0x10,0xc5,0x50,0xbd,0x94,0x9c,0xd2,0xbc,0x63,0x1f,0xf1,0x34,0xfa,0x10,0xa8,0x27,0xff,0x69,0xb1,0x66,0xa6,0xbd,0x95,0xe2,0x49,0xed,0x0d,0xaf,0x57,0x15,0x92,0xeb,0xbe,0x9f,0xf1,0x3d,0xe6,0xb0,0x3a,0xcc,0x21,0x81,0x46,0x78,0x1f,0x69,0x3b,0x5a,0x69,0x2b,0x73,0x19,0xd7,0x4f,0xd2,0xe5,0x3b,0x6a,0x2d,0xf0,0xf6,0x78,0x5d,0x62,0x4f,0x02,0x4a,0x44,0x03,0x0c,0xa0,0x0b,0x86,0x9a,0xe8,0x1a,0x53,0x2b,0x19,0xe4,0x7e,0x52,0x5f,0xf4,0xa6,0x2c,0x51,0xa5,0x88,0x9e,0xb5,0x65,0xfe,0xe2,0x68,0x59,0x0d,0x8a,0x3c,0xa3,0xc1,0xbc,0x3b,0xd5,0x40,0x4e,0x39,0x72,0x0c,0xa2,0xea,0xee,0x30,0x8f,0x4e,0x07,0x00,0x76,0x1e,0x98,0x63,0x89,0x14,0x00,0x00,0x20,0x9e,0xfe,0xe0,0x3e,0xbf,0xfb,0xc0,0xdc,0x23,0xd2,0x6d,0x95,0x87,0x44,0xc0,0x9e,0x30,0x00,0x47,0x7e,0xff,0x7a,0xe3,0x14,0x8a,0x50,0xe5,0x67,0x00,0x13,0xaa,0xaa,0x16       };
  uint8_t k2[16] = {
0xfd,0xa2,0xa4,0x40,0x46,0x70,0x80,0x8f,0x49,0x37,0x47,0x8b,0x8b,0x6e,0x3f,0xe1
	      };
  uint8_t n2[12] = {
0xb5,0xf3,0xa3,0xfa,0xe1,0xcb,0x25,0xc9,0xdc,0xd7,0x39,0x93
	      };
  uint8_t aad2[0] = {};
  uint8_t exp2[668] = {
0xc1,0xe6,0x31,0xf8,0x1d,0x2a,0xf2,0x21,0xeb,0xb6,0xa9,0x57,0xf5,0x8f,0x3e,0xe2,0x66,0x27,0x26,0x35,0xe6,0x7f,0x99,0xa7,0x52,0xf0,0xdf,0x08,0xad,0xeb,0x33,0xba,0xb8,0x61,0x1e,0x55,0xf3,0x3d,0x72,0xcf,0x84,0x38,0x24,0x61,0xa8,0xbf,0xe0,0xa6,0x59,0xba,0x2d,0xd1,0x87,0x3f,0x6f,0xcc,0x70,0x7a,0x98,0x41,0xce,0xfc,0x1f,0xb0,0x35,0x26,0xb9,0xca,0x4f,0xe3,0x43,0xe5,0x80,0x5e,0x95,0xa5,0xc0,0x1e,0x56,0x57,0x06,0x38,0xa7,0x6a,0x4b,0xc8,0xfe,0xb0,0x7b,0xe8,0x79,0xf9,0x05,0x68,0x61,0x7d,0x90,0x5f,0xec,0xd5,0xb1,0x61,0x9f,0xb8,0xec,0x4a,0x66,0x28,0xd1,0xbb,0x2b,0xb2,0x24,0xc4,0x90,0xff,0x97,0xa6,0xc0,0xe9,0xac,0xd0,0x36,0x04,0xbc,0x3a,0x59,0xd8,0x6b,0xda,0xb4,0xe0,0x84,0xc1,0xc1,0x45,0x0f,0x9c,0x9d,0x2a,0xfe,0xb1,0x72,0xc0,0x72,0x34,0xd7,0x39,0x86,0x8e,0xbd,0x62,0xde,0x20,0x60,0xa8,0xde,0x98,0x94,0x14,0xa8,0x29,0x20,0xda,0xcd,0x1c,0xac,0x0c,0x6e,0x72,0xec,0xd7,0xf4,0x01,0x85,0x74,0xce,0xac,0xa6,0xd2,0x9f,0x36,0x1b,0xc3,0x7e,0xe2,0x88,0x8b,0x8e,0x30,0x2c,0xa9,0x56,0x1a,0x9d,0xe9,0x16,0x3e,0xdf,0xa6,0x6b,0xad,0xd4,0x89,0x48,0x84,0xc7,0xb3,0x59,0xbc,0xac,0xae,0x59,0x08,0x05,0x1b,0x37,0x95,0x2e,0x10,0xa4,0x5f,0xe7,0x3f,0xda,0x12,0x6e,0xbd,0x67,0x57,0x5f,0x1b,0xed,0x8a,0x99,0x2a,0x89,0x47,0x4d,0x7d,0xec,0x1e,0xed,0x32,0x78,0x24,0x12,0x3a,0x41,0x4a,0xdb,0x66,0xd5,0xef,0x7d,0x08,0x36,0xff,0x98,0xc2,0xcd,0xd7,0xfb,0x07,0x81,0xe1,0x92,0xbf,0x0c,0x75,0x68,0xbf,0x7d,0x89,0x0a,0x51,0xc3,0x32,0x87,0x9b,0x50,0x37,0xb2,0x12,0xd6,0x22,0x41,0x2c,0xa4,0x8e,0x83,0x23,0x81,0x7b,0xd6,0xd7,0x46,0xee,0xf6,0x83,0x84,0x5c,0xec,0x4e,0x3e,0xf6,0x4b,0x3a,0x18,0xfc,0xce,0x51,0x3e,0xa9,0x51,0xf3,0x36,0x66,0x93,0xa7,0xff,0x49,0x0d,0x09,0xd0,0x8a,0xb1,0xf6,0x3e,0x13,0x62,0x5a,0x54,0x59,0x61,0x59,0x9c,0x0d,0x9c,0x7a,0x09,0x9d,0x11,0x63,0xca,0xd1,0xb9,0xbc,0xf8,0xe9,0x17,0xd7,0x66,0xb9,0x88,0x53,0xef,0x68,0x77,0x83,0x4f,0x89,0x1d,0xf1,0x6b,0xe1,0xfc,0xc9,0xc1,0x8e,0xa1,0x88,0x2e,0xa3,0xf1,0xf4,0xb6,0x43,0x58,0xe1,0xb1,0x46,0xce,0xbf,0xb3,0xe0,0x2e,0x15,0x3f,0xdb,0x73,0xaf,0x26,0x93,0xf2,0x2c,0x6f,0x59,0x3f,0xa4,0x75,0x38,0x0b,0xa6,0x61,0x17,0x40,0xad,0x20,0xe3,0x19,0xa6,0x54,0xac,0x56,0x84,0x77,0x52,0x36,0x16,0x2e,0x84,0x47,0xed,0x80,0x88,0x61,0xbf,0xbd,0xa6,0xe1,0x8e,0xc9,0x7a,0xe0,0x90,0xbf,0x70,0x34,0x75,0xcf,0xb9,0x0f,0xe2,0x0a,0x3c,0x55,0xbe,0xf6,0xf5,0xeb,0xa6,0xe6,0xa1,0xda,0x6a,0x19,0x96,0xb8,0xbd,0xe4,0x21,0x80,0x60,0x8c,0xa2,0x27,0x9d,0xef,0x8e,0x81,0x53,0x89,0x5c,0xc8,0x50,0xdb,0x64,0x20,0x56,0x1c,0x04,0xb5,0x72,0x9c,0xc6,0x88,0x34,0x36,0xea,0x02,0xee,0x07,0xeb,0x9b,0xae,0xe2,0xfb,0x3a,0x9e,0x1b,0xbd,0xa8,0x73,0x0d,0x6b,0x22,0x05,0x76,0xe2,0x4d,0xf7,0x0a,0xf6,0x92,0x8e,0xb8,0x65,0xfe,0xe8,0xa1,0xd1,0xc0,0xf1,0x81,0x8a,0xca,0x68,0xd5,0x00,0x2a,0xe4,0xc6,0x5b,0x2f,0x49,0xc9,0xe6,0xe2,0x1d,0xcf,0x76,0x78,0x4a,0xdb,0xd0,0xe8,0x87,0xa3,0x68,0x32,0xef,0x85,0xbe,0xb1,0x05,0x87,0xf1,0x6c,0x6f,0xfe,0x60,0xd7,0x45,0x10,0x59,0xec,0x7f,0x10,0x14,0xc3,0xef,0xe1,0x9e,0x56,0xae,0xdb,0x5a,0xd3,0x1a,0x9f,0x29,0xdc,0x44,0x58,0xcf,0xbf,0x0c,0x70,0x70,0xc1,0x75,0xdc,0xad,0x46,0xe1,0x67,0x52,0x26,0xb4,0x7c,0x07,0x1a,0xad,0x31,0x72,0xeb,0xd3,0x3e,0x45,0xd7,0x41,0xcb,0x91,0x25,0x3a,0x01,0xa6,0x9a,0xe3,0xcc,0x29,0x2b,0xce,0x9c,0x03,0x24,0x6a,0xc9,0x51,0xe4,0x5e,0x97,0xeb,0xf0,0x4a,0x9d,0x51,0xfa,0xb5,0xcf,0x06,0xd9,0x48,0x5c,0xce,0x74,0x6b,0x1c,0x07,0x7b,0xe6,0x9a,0xd1,0x53,0xf1,0x65,0x6e,0xf8,0x9f,0xc7,0xd1,0xed,0x8c,0x3e,0x2d,0xa7,0xa2
};
*/


  uint8_t comp[76] = {0};
  bool ok = true;

  uint8_t comp1[32] = {0};
  bool ok1 = true;
  uint8_t comp1_result[16] = {0};

  uint8_t comp2[129 + 16] = {0};
  bool ok2 = true;
  uint8_t comp2_result[129] = {0};

  Lib_IntVector_Intrinsics_vec128 ctx[396] = {0};
  


Hacl_AES_256_GCM_NI_aes256_gcm_init(ctx,k,n);
  Hacl_AES_256_GCM_NI_aes256_gcm_encrypt(ctx,60,comp,in,20,aad);
  printf("Test0: AESGCM-AES256-NI computed:");
  for (int i = 0; i < 76; i++)
    printf("%02x",comp[i]);
  printf("\n");
  printf("Test0: AESGCM-AES256-NI expected:");
  for (int i = 0; i < 76; i++)
    printf("%02x",exp[i]);
  printf("\n");
  ok = true;
  for (int i = 0; i < 76; i++) {
    ok = ok & (exp[i] == comp[i]);
    if (!ok) break;
  }
  if (ok) printf("Test0: Encrypt Success!\n");
  else printf("Test0: Encrypt FAILURE!\n");

  Hacl_AES_256_GCM_NI_aes256_gcm_init(ctx,k,n);
  bool res = Hacl_AES_256_GCM_NI_aes256_gcm_decrypt(ctx,60,comp,exp,20,aad);
  if (!res)
    printf("Test0: AESGCM-AES256-NI Decrypt failed!\n");
  else {
    printf("Test0: AESGCM-AES256-NI Decrypt computed:");
    for (int i = 0; i < 60; i++)
      printf("%02x",comp[i]);
    printf("\n");
    printf("Test0: AESGCM-AES256-NI Decrypt expected:");
    for (int i = 0; i < 60; i++)
      printf("%02x",in[i]);
    printf("\n");
    ok = true;
    for (int i = 0; i < 60; i++)
      ok = ok & (in[i] == comp[i]);
    if (ok) printf("Test0: Decrypt Success!\n");
    else printf("Test0: Decrypt FAILURE!\n");
  }

  printf("%s\n", "-----------------------------------------------------");


  Hacl_AES_256_GCM_NI_aes256_gcm_init(ctx,k1,n1);
  Hacl_AES_256_GCM_NI_aes256_gcm_encrypt(ctx,16,comp1,in1,16,aad1);
  printf("Test1: AESGCM-AES256-NI computed:");
  for (int i = 0; i < 32; i++)
    printf("%02x",comp1[i]);
  printf("\n");
  printf("Test1: AESGCM-AES256-NI expected:");
  for (int i = 0; i < 32; i++)
    printf("%02x",exp1[i]);
  printf("\n");
  ok = true;
  for (int i = 0; i < 32; i++) {
    ok = ok & (exp1[i] == comp1[i]);
    if (!ok) break;
  }
  if (ok) printf("Test1: Encrypt Success!\n");
  else printf("Test1: Encrypt FAILURE!\n");


  Hacl_AES_256_GCM_NI_aes256_gcm_init(ctx,k1,n1);
  bool res1 = Hacl_AES_256_GCM_NI_aes256_gcm_decrypt(ctx, 16, comp1_result, comp1, 16 , aad1);
  if (!res1)
    printf("Test1: AESGCM-AES256-NI Decrypt failed!\n");
  // else {
    printf("Test1: AESGCM-AES256-NI Decrypt computed:");
    for (int i = 0; i < 16; i++)
      printf("%02x",comp1_result[i]);
    printf("\n");
    printf("Test1: AESGCM-AES256-NI Decrypt expected:");
    for (int i = 0; i < 16; i++)
      printf("%02x",in1[i]);
    printf("\n");
    ok = true;
    for (int i = 0; i < 16; i++)
      ok = ok & (in1[i] == comp1_result[i]);
    if (ok) printf("Test1: Decrypt Success!\n");
    else printf("Test1: Decrypt FAILURE!\n");
  // }


  printf("%s\n", "-----------------------------------------------------");




  Hacl_AES_256_GCM_NI_aes256_gcm_init(ctx,k2,n2);
  Hacl_AES_256_GCM_NI_aes256_gcm_encrypt(ctx,129,comp2,in2,13,aad2);
  printf("Test2: AESGCM-AES256-NI computed:");
  for (int i = 0; i < 129 + 16; i++)
    printf("%02x",comp2[i]);
  printf("\n");
  printf("Test2: AESGCM-AES256-NI expected:");
  for (int i = 0; i < 129 + 16; i++)
    printf("%02x",exp2[i]);
  printf("\n");
  ok = true;
  for (int i = 0; i < 129 + 16; i++) {
    ok = ok & (exp2[i] == comp2[i]);
    if (!ok) break;
  }
  if (ok) printf("Test2: Encrypt Success!\n");
  else printf("Test2: Encrypt FAILURE!\n");



  Hacl_AES_256_GCM_NI_aes256_gcm_init(ctx,k2,n2);
  bool res2 = Hacl_AES_256_GCM_NI_aes256_gcm_decrypt(ctx, 129, comp2_result, comp2, 13 , aad2);
  if (!res2)
    printf("Test2: AESGCM-AES256-NI Decrypt failed!\n");
  // else {
    printf("Test2: AESGCM-AES256-NI Decrypt computed:");
    for (int i = 0; i < 129; i++)
      printf("%02x",comp2_result[i]);
    printf("\n");
    printf("Test2: AESGCM-AES256-NI Decrypt expected:");
    for (int i = 0; i < 129; i++)
      printf("%02x",in2[i]);
    printf("\n");
    ok = true;
    for (int i = 0; i < 129; i++)
      ok = ok & (in2[i] == comp2_result[i]);
    if (ok) printf("Test2: Decrypt Success!\n");
    else printf("Test2: Decrypt FAILURE!\n");
  // }


  printf("%s\n", "-----------------------------------------------------");


  Hacl_AES_256_GCM_NI_aes256_gcm_init(ctx, k, n);
  Hacl_AES_256_GCM_NI_aes256_gcm_encrypt(ctx, size_tv0, comp_tv0, test_vector0, 20, aad);
  Hacl_AES_256_GCM_NI_aes256_gcm_init(ctx,k,n);
  bool res_tv0 = Hacl_AES_256_GCM_NI_aes256_gcm_decrypt(ctx,size_tv0,comp1_tv0,comp_tv0,20,aad);  

   if (!res_tv0)
    printf("Test3: AESGCM-AES256-NI Decrypt failed!\n");
  else {
    printf("Test3: AESGCM-AES256-NI Decrypt computed:");
    for (int i = 0; i < size_tv0; i++)
      printf("%02x",comp1_tv0[i]);
    printf("\n");
    printf("Test3: AESGCM-AES256-NI Decrypt expected:");
    for (int i = 0; i < size_tv0; i++)
      printf("%02x",test_vector0[i]);
    printf("\n");
    ok = true;
    for (int i = 0; i < size_tv0; i++)
      ok = ok & (test_vector0[i] == comp1_tv0[i]);
    if (ok) printf("Test3: Decrypt Success!\n");
    else printf("Test3: Decrypt FAILURE!\n");
  }


    printf("%s\n", "-----------------------------------------------------");


  uint64_t len = SIZE;
  uint8_t plain[SIZE+16];
  uint8_t key[16];
  uint8_t nonce[12];
  cycles a,b;
  clock_t t1,t2;
  uint64_t count = ROUNDS * SIZE;
  memset(plain,'P',SIZE);
  memset(key,'K',16);
  memset(nonce,'N',12);

  Hacl_AES_256_GCM_NI_aes256_gcm_init(ctx,key,nonce);
  for (int j = 0; j < ROUNDS; j++) {
    Hacl_AES_256_GCM_NI_aes256_gcm_encrypt(ctx,SIZE,plain,plain,20,aad);
  }

  t1 = clock();
  a = cpucycles();
  for (int j = 0; j < ROUNDS; j++) {
    Hacl_AES_256_GCM_NI_aes256_gcm_encrypt(ctx,SIZE,plain,plain,20,aad);
  }
  b = cpucycles();
  t2 = clock();
  clock_t tdiff1 = t2 - t1;
  cycles cdiff1 = b - a;

  printf("AES-AES256-NI PERF:\n");
  printf("cycles for %" PRIu64 " bytes: %" PRIu64 " (%.2fcycles/byte)\n",count,(uint64_t)cdiff1,(double)cdiff1/count);
  printf("time for %" PRIu64 " bytes: %" PRIu64 " (%.2fus/byte)\n",count,(uint64_t)tdiff1,(double)tdiff1/count);
  printf("bw %8.2f MB/s\n",(double)count/(((double)tdiff1 / CLOCKS_PER_SEC) * 1000000.0));
}
