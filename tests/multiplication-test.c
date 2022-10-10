#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>
#include <stdbool.h>
#include "test_helpers.h"

#include "multiplication.h"

#define ROUNDS 50000000

static inline bool compare64(size_t len, uint64_t* comp, uint64_t* exp) {
  bool ok = true;
  for (size_t i = 0; i < len; i++)
    ok = ok & (exp[i] == comp[i]);
  if (ok)
    printf("Success!\n");
  else
    printf("**FAILED**\n");
  return ok;
}

int main()
{
  cycles a,b;
  clock_t t1,t2;
  uint64_t count = ROUNDS;

  uint64_t arg_a[4U] =
    { 0x512ad3943babfd91U, 0xa0d57cafb483f95eU, 0x253e747af44ba033U, 0x719ca154e8f59ab1U };
  uint64_t arg_b[4U] =
    { 0xcc0d57376608ea8aU, 0x25731447e18a3f67U, 0x14ab93d4c2a7598bU, 0x1cc62c5e7c53e354U };
  uint64_t arg_t[8U] = { 0U };
  uint64_t arg_t2[8U] = { 0U };
  uint64_t arg_t3[8U] = { 0U };
  uint64_t arg_t4[8U] = { 0U };

  bench_multiplication_buffer(arg_a, arg_b, arg_t);
  bench_bignum_mul(arg_a, arg_b, arg_t2);
  new_bench_bignum_mul(arg_a, arg_b, arg_t3);
  bench_bignum_mul_unroll1(arg_a, arg_b, arg_t4);
  compare64(8, arg_t, arg_t2);
  compare64(8, arg_t, arg_t3);
  compare64(8, arg_t, arg_t4);

  bench_sq(arg_a, arg_t);
  bench_bignum_sqr(arg_a, arg_t2);
  new_bench_bignum_sqr(arg_a, arg_t3);
  compare64(8, arg_t, arg_t2);
  compare64(8, arg_t, arg_t3);

  /* for (int i = 0; i < 4; i++) */
  /*   printf("%" PRIu64" %" PRIu64"\n", arg_a[i], arg_b[i]); */
  /* bench_multiplication_buffer(arg_a, arg_b, arg_t); */
  /* for (int i = 0; i < 8; i++) */
  /*   printf("%" PRIu64 "\n", arg_t[i]); */
  /* for (int i = 0; i < 8; i++) */
  /*   printf("%" PRIu64 "\n", arg_t2[i]); */

  for (int j = 0; j < ROUNDS; j++) {
    bench_multiplication_buffer(arg_a, arg_b, arg_t);
  }

  t1 = clock();
  a = cpucycles_begin();
  for (int j = 0; j < ROUNDS; j++) {
    bench_multiplication_buffer(arg_a, arg_b, arg_t);
  }
  b = cpucycles_end();
  t2 = clock();
  clock_t tdiff1 = t2 - t1;
  cycles cdiff1 = b - a;

  printf("P256-mul\n");
  print_time(count,tdiff1,cdiff1);

//////////////////////////////////////

  for (int j = 0; j < ROUNDS; j++){
    bench_bignum_mul(arg_a, arg_b, arg_t);
  }

  t1 = clock();
  a = cpucycles_begin();
  for (int j = 0; j < ROUNDS; j++){
    bench_bignum_mul(arg_a, arg_b, arg_t);
  }
  b = cpucycles_end();
  t2 = clock();
  clock_t tdiff2 = t2 - t1;
  cycles cdiff2 = b - a;

  printf("bn-mul\n");
  print_time(count,tdiff2,cdiff2);

//////////////////////////////////////

  for (int j = 0; j < ROUNDS; j++){
    new_bench_bignum_mul(arg_a, arg_b, arg_t);
  }

  t1 = clock();
  a = cpucycles_begin();
  for (int j = 0; j < ROUNDS; j++){
    new_bench_bignum_mul(arg_a, arg_b, arg_t);
  }
  b = cpucycles_end();
  t2 = clock();
  clock_t tdiff6 = t2 - t1;
  cycles cdiff6 = b - a;

  printf("new-bn-mul\n");
  print_time(count,tdiff6,cdiff6);

//////////////////////////////////////

  for (int j = 0; j < ROUNDS; j++){
    bench_bignum_mul_unroll1(arg_a, arg_b, arg_t);
  }

  t1 = clock();
  a = cpucycles_begin();
  for (int j = 0; j < ROUNDS; j++){
    bench_bignum_mul_unroll1(arg_a, arg_b, arg_t);
  }
  b = cpucycles_end();
  t2 = clock();
  clock_t tdiff7 = t2 - t1;
  cycles cdiff7 = b - a;

  printf("new-bn-mul-unroll1\n");
  print_time(count,tdiff7,cdiff7);

//////////////////////////////////////

  for (int j = 0; j < ROUNDS; j++){
    bench_sq(arg_a, arg_t);
  }

  t1 = clock();
  a = cpucycles_begin();
  for (int j = 0; j < ROUNDS; j++){
    bench_sq(arg_a, arg_t);
  }
  b = cpucycles_end();
  t2 = clock();
  clock_t tdiff4 = t2 - t1;
  cycles cdiff4 = b - a;

  printf("P256-sqr\n");
  print_time(count,tdiff4,cdiff4);

//////////////////////////////////////

  for (int j = 0; j < ROUNDS; j++){
    bench_bignum_sqr(arg_a, arg_t);
  }

  t1 = clock();
  a = cpucycles_begin();
  for (int j = 0; j < ROUNDS; j++){
    bench_bignum_sqr(arg_a, arg_t);
  }
  b = cpucycles_end();
  t2 = clock();
  clock_t tdiff3 = t2 - t1;
  cycles cdiff3 = b - a;

  printf("bn-sqr\n");
  print_time(count,tdiff3,cdiff3);

//////////////////////////////////////

  for (int j = 0; j < ROUNDS; j++){
    new_bench_bignum_sqr(arg_a, arg_t);
  }

  t1 = clock();
  a = cpucycles_begin();
  for (int j = 0; j < ROUNDS; j++){
    new_bench_bignum_sqr(arg_a, arg_t);
  }
  b = cpucycles_end();
  t2 = clock();
  clock_t tdiff5 = t2 - t1;
  cycles cdiff5 = b - a;

  printf("new-bn-sqr\n");
  print_time(count,tdiff5,cdiff5);
}
