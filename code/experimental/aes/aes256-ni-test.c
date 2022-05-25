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

typedef uint64_t cycles;

static __inline__ cycles cpucycles_begin(void)
{
  uint64_t rax,rdx,aux;
  asm volatile ( "rdtscp\n" : "=a" (rax), "=d" (rdx), "=c" (aux) : : );
  return (rdx << 32) + rax;
  //  unsigned hi, lo;
  //__asm__ __volatile__ ("CPUID\n\t"  "RDTSC\n\t"  "mov %%edx, %0\n\t"  "mov %%eax, %1\n\t": "=r" (hi), "=r" (lo):: "%rax", "%rbx", "%rcx", "%rdx");
  //return ( (uint64_t)lo)|( ((uint64_t)hi)<<32 );
}

static __inline__ cycles cpucycles_end(void)
{
  uint64_t rax,rdx,aux;
  asm volatile ( "rdtscp\n" : "=a" (rax), "=d" (rdx), "=c" (aux) : : );
  return (rdx << 32) + rax;
  //  unsigned hi, lo;
  //__asm__ __volatile__ ("RDTSCP\n\t"  "mov %%edx, %0\n\t"  "mov %%eax, %1\n\t"  "CPUID\n\t": "=r" (hi), "=r" (lo)::     "%rax", "%rbx", "%rcx", "%rdx");
  //return ( (uint64_t)lo)|( ((uint64_t)hi)<<32 );
}

extern void Hacl_AES_256_NI_aes256_init(uint64_t* ctx, uint8_t* key, uint8_t* nonce);
extern void Hacl_AES_256_NI_aes256_encrypt_block(uint8_t* out, uint64_t* ctx, uint8_t* in);

#define ROUNDS 10240
#define SIZE   16384

int main() {
  int in_len = 16;

  uint8_t test1_input_key1[32] = {
  0x60, 0x3d, 0xeb, 0x10, 0x15, 0xca, 0x71, 0xbe,
  0x2b, 0x73, 0xae, 0xf0, 0x85, 0x7d, 0x77, 0x81,
  0x1f, 0x35, 0x2c, 0x07, 0x3b, 0x61, 0x08, 0xd7,
  0x2d, 0x98, 0x10, 0xa3, 0x09, 0x14, 0xdf, 0xf4};

  uint8_t test1_output_expanded[960] = {
  0x60, 0x3d, 0xeb, 0x10, 0x15, 0xca, 0x71, 0xbe,
  0x2b, 0x73, 0xae, 0xf0, 0x85, 0x7d, 0x77, 0x81,
  0x1f, 0x35, 0x2c, 0x07, 0x3b, 0x61, 0x08, 0xd7,
  0x2d, 0x98, 0x10, 0xa3, 0x09, 0x14, 0xdf, 0xf4,
  0x9b, 0xa3, 0x54, 0x11, 0x8e, 0x69, 0x25, 0xaf,
  0xa5, 0x1a, 0x8b, 0x5f, 0x20, 0x67, 0xfc, 0xde,
  0xa8, 0xb0, 0x9c, 0x1a, 0x93, 0xd1, 0x94, 0xcd,
  0xbe, 0x49, 0x84, 0x6e, 0xb7, 0x5d, 0x5b, 0x9a,
  0xd5, 0x9a, 0xec, 0xb8, 0x5b, 0xf3, 0xc9, 0x17,
  0xfe, 0xe9, 0x42, 0x48, 0xde, 0x8e, 0xbe, 0x96,
  0xb5, 0xa9, 0x32, 0x8a, 0x26, 0x78, 0xa6, 0x47,
  0x98, 0x31, 0x22, 0x29, 0x2f, 0x6c, 0x79, 0xb3,
  0x81, 0x2c, 0x81, 0xad, 0xda, 0xdf, 0x48, 0xba,
  0x24, 0x36, 0x0a, 0xf2, 0xfa, 0xb8, 0xb4, 0x64,
  0x98, 0xc5, 0xbf, 0xc9, 0xbe, 0xbd, 0x19, 0x8e,
  0x26, 0x8c, 0x3b, 0xa7, 0x09, 0xe0, 0x42, 0x14,
  0x68, 0x00, 0x7b, 0xac, 0xb2, 0xdf, 0x33, 0x16,
  0x96, 0xe9, 0x39, 0xe4, 0x6c, 0x51, 0x8d, 0x80,
  0xc8, 0x14, 0xe2, 0x04, 0x76, 0xa9, 0xfb, 0x8a,
  0x50, 0x25, 0xc0, 0x2d, 0x59, 0xc5, 0x82, 0x39,
  0xde, 0x13, 0x69, 0x67, 0x6c, 0xcc, 0x5a, 0x71,
  0xfa, 0x25, 0x63, 0x95, 0x96, 0x74, 0xee, 0x15,
  0x58, 0x86, 0xca, 0x5d, 0x2e, 0x2f, 0x31, 0xd7,
  0x7e, 0x0a, 0xf1, 0xfa, 0x27, 0xcf, 0x73, 0xc3,
  0x74, 0x9c, 0x47, 0xab, 0x18, 0x50, 0x1d, 0xda,
  0xe2, 0x75, 0x7e, 0x4f, 0x74, 0x01, 0x90, 0x5a,
  0xca, 0xfa, 0xaa, 0xe3, 0xe4, 0xd5, 0x9b, 0x34,
  0x9a, 0xdf, 0x6a, 0xce, 0xbd, 0x10, 0x19, 0x0d,
  0xfe, 0x48, 0x90, 0xd1, 0xe6, 0x18, 0x8d, 0x0b,
  0x04, 0x6d, 0xf3, 0x44, 0x70, 0x6c, 0x63, 0x1e};


  uint8_t in[16] = {
    0x00,0x11,0x22,0x33,0x44,0x55,0x66,0x77,
    0x88,0x99,0xaa,0xbb,0xcc,0xdd,0xee,0xff,
  };
  uint8_t k[32] = {
    0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,
    0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,
    0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,
    0x18,0x19,0x1a,0x1b,0x1c,0x1d,0x1e,0x1f
  };
  uint8_t exp[16] = {
    0x8e,0xa2,0xb7,0xca,0x51,0x67,0x45,0xbf,
    0xea,0xfc,0x49,0x90,0x4b,0x49,0x60,0x89
  };
  uint8_t comp[16] = {0};
  bool ok = true;

  uint64_t ctx[(uint32_t)8U + (uint32_t)15U * (uint32_t)8U] = {0};

  Hacl_AES_256_NI_aes256_init(ctx,k,comp);
  Hacl_AES_256_NI_aes256_encrypt_block(comp,ctx,in);

  printf("AES256-NI computed:");
  for (int i = 0; i < 16; i++)
    printf("%02x",comp[i]);
  printf("\n");
  printf("AES256-NI expected:");
  for (int i = 0; i < 16; i++)
    printf("%02x",exp[i]);
  printf("\n");
  ok = true;
  for (int i = 0; i < 16; i++)
    ok = ok & (exp[i] == comp[i]);
  if (ok) printf("Success!\n");

  /*uint64_t len = SIZE;
  uint8_t plain[SIZE];
  uint8_t key[16];
  uint8_t nonce[12];
  cycles a,b;
  clock_t t1,t2;
  uint64_t count = ROUNDS * SIZE;
  memset(plain,'P',SIZE);
  memset(key,'K',16);
  memset(nonce,'N',12);

  for (int j = 0; j < ROUNDS; j++) {
    Hacl_Aes_BitSlice_aes128_ctr_encrypt(SIZE,plain,plain,key,nonce,1);
  }

  t1 = clock();
  a = cpucycles_begin();
  for (int j = 0; j < ROUNDS; j++) {
   Hacl_Aes_BitSlice_aes128_ctr_encrypt(SIZE,plain,plain,key,nonce,1);
 //   Hacl_Aes_BitSlice_aes128_init(ctx,key,nonce);
 //   Hacl_Aes_BitSlice_aes_ctr(SIZE,plain,plain,ctx,1,10);

  }
  b = cpucycles_end();
  t2 = clock();
  clock_t tdiff2 = t2 - t1;
  cycles cdiff2 = b - a;

  printf("AES-BitSlice PERF:\n");
  printf("cycles for %" PRIu64 " bytes: %" PRIu64 " (%.2fcycles/byte)\n",count,(uint64_t)cdiff2,(double)cdiff2/count);
  printf("time for %" PRIu64 " bytes: %" PRIu64 " (%.2fus/byte)\n",count,(uint64_t)tdiff2,(double)tdiff2/count);
  printf("bw %8.2f MB/s\n",(double)count/(((double)tdiff2 / CLOCKS_PER_SEC) * 1000000.0));
  */

}
