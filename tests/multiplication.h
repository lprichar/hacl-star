#include "Hacl_Spec.h"
#include "lib_intrinsics.h"

void bench_bignum_mul(uint64_t *a, uint64_t *b, uint64_t *res);

void bench_multiplication_buffer(uint64_t *a, uint64_t *b, uint64_t *t);

void bench_bignum_sqr(uint64_t *a, uint64_t *res);

void bench_sq(uint64_t *f, uint64_t *out);

void new_bench_bignum_mul(uint64_t *a, uint64_t *b, uint64_t *res);

void new_bench_bignum_sqr(uint64_t *a, uint64_t *res);

void bench_bignum_mul_unroll1(uint64_t *a, uint64_t *b, uint64_t *res);
