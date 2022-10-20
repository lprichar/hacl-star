#include <fcntl.h>
#include <inttypes.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

/**
   All the computations are done for the fixed-window method.
   `ec-operations-statistics.c` prints the number of `point_add` and
   `point_double` per alg. It helps to select the window size w and estimate the
   speed gain for optimizations. See `ff-operations-statistics.c` for a more
   precise estimate.
*/

// TODO: add `ff-operations-statistics.c` to compare formulas given in
// - projective coordinates
// - jacobian coordinates
// - mixed coordinates
// TODO: add another file `ec-operations-wnaf-statistics.c` to account for wNAF
// - it changes #point_add and _double for a precomputed table
static inline void print_end_line(bool is_print) {
  if (is_print) {
    printf("-----------------------------------------------------------\n");
  }
}

static inline void print_header_for_number_of_point_ops(bool is_print) {
  if (is_print) {
    print_end_line(true);
    printf("%-5s %-15s %-15s %-15s \n", "w", "#point_add", "#point_double",
           "~#point_add");
    print_end_line(true);
  }
}

static inline void print_number_of_point_ops(bool is_print, uint32_t ratio,
                                             uint32_t l, uint32_t total_add,
                                             uint32_t total_double,
                                             uint32_t total_appr) {

  if (is_print) {
    printf("%-5d %-15d %-15d %-15d \n", l, total_add, total_double, total_appr);
    /* printf(" w = %d \n", l);
       printf(" total_add = %d \n", total_add);
       printf(" total_double = %d \n", total_double);
       printf(" total_appr = %d \n", total_appr);
       printf("\n"); */
  }
}

static inline void print_header_for_number_of_point_ops_large(bool is_print) {
  if (is_print) {
    print_end_line(true);
    printf("%-5s %-5s %-15s %-15s %-15s \n", "w", "w_g", "#point_add",
           "#point_double", "~#point_add");
    print_end_line(true);
  }
}

static inline void
print_number_of_point_ops_large(bool is_print, uint32_t ratio, uint32_t l,
                                uint32_t l_g, uint32_t total_add,
                                uint32_t total_double, uint32_t total_appr) {

  if (is_print) {
    printf("%-5d %-5d %-15d %-15d %-15d \n", l, l_g, total_add, total_double,
           total_appr);
    /* printf(" w = %d \n", l);
       printf(" w_g = %d \n", l_g);
       printf(" total_add = %d \n", total_add);
       printf(" total_double = %d \n", total_double);
       printf(" total_appr = %d \n", total_appr);
       printf("\n"); */
  }
}

// [main] precomp_table_g is computed in 1 ECSM
uint32_t main_count_number_of_point_ops_1(bool is_print, uint32_t ratio,
                                          uint32_t l, uint32_t bBits) {

  // 1 precomp_table
  uint32_t table_len = (1U << l) - 2U;
  uint32_t precomp_double = table_len / 2U;
  uint32_t precomp_add = table_len / 2U;

  uint32_t rem_padd = 0U; // we skip mul by `one`

  // main loop
  uint32_t n = bBits / l;
  uint32_t pdouble = n * l;
  uint32_t padd = n;

  uint32_t total_add = precomp_add + padd + rem_padd;
  uint32_t total_double = precomp_double + pdouble;

  uint32_t total_appr = total_add + (total_double * ratio / 5U);
  print_number_of_point_ops(is_print, ratio, l, total_add, total_double,
                            total_appr);
  return total_appr;
}

// [precomp_g] precomp_table_g as constant in 1 ECSM
uint32_t precomp_g_count_number_of_point_ops_1(bool is_print, uint32_t ratio,
                                               uint32_t l, uint32_t bBits) {

  uint32_t rem_padd = 0U; // we skip mul by `one`

  // main loop
  uint32_t n = bBits / l;
  uint32_t pdouble = n * l;
  uint32_t padd = n;

  uint32_t total_add = padd + rem_padd;
  uint32_t total_double = pdouble;

  uint32_t total_appr = total_add + (total_double * ratio / 5U);
  print_number_of_point_ops(is_print, ratio, l, total_add, total_double,
                            total_appr);
  return total_appr;
}

// [main] precomp_table_g is computed in 2 ECSM
uint32_t main_count_number_of_point_ops(bool is_print, uint32_t ratio,
                                        uint32_t l, uint32_t bBits) {

  // 1 precomp_table
  uint32_t table_len = (1U << l) - 2U;
  uint32_t precomp_double = table_len / 2U;
  uint32_t precomp_add = table_len / 2U;

  uint32_t rem_padd = (bBits % l == 0U) ? 0U : 1U;

  // main loop
  uint32_t n = bBits / l;
  uint32_t pdouble = n * l;
  uint32_t padd = n + n;

  uint32_t total_add = precomp_add + precomp_add + padd + rem_padd;
  uint32_t total_double = precomp_double + precomp_double + pdouble;

  uint32_t total_appr = total_add + (total_double * ratio / 5U);
  print_number_of_point_ops(is_print, ratio, l, total_add, total_double,
                            total_appr);
  return total_appr;
}

// [precomp_g] precomp_table_g as constant in 2 ECSM
uint32_t precomp_g_count_number_of_point_ops(bool is_print, uint32_t ratio,
                                             uint32_t l, uint32_t bBits) {

  // 1 precomp_table
  uint32_t table_len = (1U << l) - 2U;
  uint32_t precomp_double = table_len / 2U;
  uint32_t precomp_add = table_len / 2U;

  uint32_t rem_padd = (bBits % l == 0U) ? 0U : 1U;

  // main loop
  uint32_t n = bBits / l;
  uint32_t pdouble = n * l;
  uint32_t padd = n + n;

  uint32_t total_add = precomp_add + padd + rem_padd;
  uint32_t total_double = precomp_double + pdouble;

  uint32_t total_appr = total_add + (total_double * ratio / 5U);
  print_number_of_point_ops(is_print, ratio, l, total_add, total_double,
                            total_appr);
  return total_appr;
}

// [precomp_g_large] precomp_table_g as constant in 2 ECSM
uint32_t precomp_g_large_count_number_of_point_ops(bool is_print,
                                                   uint32_t ratio, uint32_t l,
                                                   uint32_t l_g,
                                                   uint32_t bBits) {

  // 1 precomp_table
  uint32_t table_len = (1U << l) - 2U;
  uint32_t precomp_double = table_len / 2U;
  uint32_t precomp_add = table_len / 2U;

  uint32_t rem_l = bBits % l;
  uint32_t rem_l_g = bBits % l_g;
  uint32_t rem_padd = (rem_l != 0U && rem_l_g != 0U) ? 1U : 0U;
  uint32_t max_rem = (rem_l > rem_l_g) ? rem_l : rem_l_g;

  // main loop
  uint32_t pdouble = bBits - max_rem;
  uint32_t padd = bBits / l + bBits / l_g;

  uint32_t total_add = precomp_add + padd + rem_padd;
  uint32_t total_double = precomp_double + pdouble;

  uint32_t total_appr = total_add + (total_double * ratio / 5U);
  print_number_of_point_ops_large(is_print, ratio, l, l_g, total_add,
                                  total_double, total_appr);
  return total_appr;
}

// [glv] precomp_table_g is computed in 4 ECSM
uint32_t glv_count_number_of_point_ops(bool is_print, uint32_t ratio,
                                       uint32_t l, uint32_t bBits) {

  // 1 precomp_table
  uint32_t table_len = (1U << l) - 2U;
  uint32_t precomp_double = table_len / 2U;
  uint32_t precomp_add = table_len / 2U;

  uint32_t rem_padd = (bBits % l == 0U) ? 0U : 3U;

  // main loop
  uint32_t n = bBits / l;
  uint32_t pdouble = n * l;
  uint32_t padd = n + n + n + n; // four scalars + acc

  // we compute only 2 tables instead of 4
  // TODO: account for mul by beta = (n + n) M
  uint32_t total_add = precomp_add + precomp_add + padd + rem_padd;
  uint32_t total_double = precomp_double + precomp_double + pdouble;

  uint32_t total_appr = total_add + (total_double * ratio / 5U);
  print_number_of_point_ops(is_print, ratio, l, total_add, total_double,
                            total_appr);
  return total_appr;
}

// [glv_precomp_g] precomp_table_g as constant in 4 ECSM
uint32_t glv_precomp_g_count_number_of_point_ops(bool is_print, uint32_t ratio,
                                                 uint32_t l, uint32_t bBits) {

  // 1 precomp_table
  uint32_t table_len = (1U << l) - 2U;
  uint32_t precomp_double = table_len / 2U;
  uint32_t precomp_add = table_len / 2U;

  uint32_t rem_padd = (bBits % l == 0U) ? 0U : 3U;

  // main loop
  uint32_t n = bBits / l;
  uint32_t pdouble = n * l;
  uint32_t padd = n + n + n + n; // four scalars + acc

  // we compute only 1 table instead of 2
  // TODO: account for mul by beta = (n + n) M
  uint32_t total_add = precomp_add + padd + rem_padd;
  uint32_t total_double = precomp_double + pdouble;

  uint32_t total_appr = total_add + (total_double * ratio / 5U);
  print_number_of_point_ops(is_print, ratio, l, total_add, total_double,
                            total_appr);
  return total_appr;
}

// [glv_precomp_g_large] precomp_table_g as constant in 4 ECSM
uint32_t glv_precomp_g_large_count_number_of_point_ops(bool is_print,
                                                       uint32_t ratio,
                                                       uint32_t l, uint32_t l_g,
                                                       uint32_t bBits) {

  // 1 precomp_table
  uint32_t table_len = (1U << l) - 2U;
  uint32_t precomp_double = table_len / 2U;
  uint32_t precomp_add = table_len / 2U;

  uint32_t rem_l = bBits % l;
  uint32_t rem_l_g = bBits % l_g;
  uint32_t rem_padd = (rem_l == 0U && rem_l_g == 0U)
                          ? 0U
                          : ((rem_l != 0U && rem_l_g != 0U) ? 3U : 1U);
  uint32_t max_rem = (rem_l > rem_l_g) ? rem_l : rem_l_g;

  // main loop
  uint32_t pdouble = bBits - max_rem;
  uint32_t padd =
      bBits / l + bBits / l + bBits / l_g + bBits / l_g; // four scalars + acc

  // we compute only 1 table instead of 2
  // TODO: account for mul by beta = (n + n) M
  uint32_t total_add = precomp_add + padd + rem_padd;
  uint32_t total_double = precomp_double + pdouble;

  uint32_t total_appr = total_add + (total_double * ratio / 5U);
  print_number_of_point_ops_large(is_print, ratio, l, l_g, total_add,
                                  total_double, total_appr);
  return total_appr;
}

#define N_MIN 3 // included
#define N_MAX 9 // excluded
#define N_LEN (N_MAX - N_MIN)
#define N_MAX_G 16
#define N_LEN_G (N_LEN * (N_MAX_G - N_MIN))

void print_statistics_glv(bool is_print, uint32_t ratio,
                          uint32_t glv_appr[N_LEN],
                          uint32_t glv_precomp_g_appr[N_LEN]) {

  // NOTE: bBits = 128U for secp256k1 w/o using wNAF
  uint32_t bBits = 128U;
  printf("\n\n[glv] precomp_table_g is computed in 4 ECSM \n");

  print_header_for_number_of_point_ops(is_print);
  for (int i = N_MIN; i < N_MAX; i++) {
    glv_appr[i - N_MIN] =
        glv_count_number_of_point_ops(is_print, ratio, i, bBits);
  }
  print_end_line(is_print);

  printf("\n\n[glv_precomp_g] precomp_table_g as constant in 4 ECSM \n");

  print_header_for_number_of_point_ops(is_print);
  for (int i = N_MIN; i < N_MAX; i++) {
    glv_precomp_g_appr[i - N_MIN] =
        glv_precomp_g_count_number_of_point_ops(is_print, ratio, i, bBits);
  }
  print_end_line(is_print);
}

void print_statistics(uint32_t ratio, bool is_glv, bool is_print,
                      uint32_t bBits) {
  uint32_t main_appr[N_LEN] = {0};
  printf("\n[main] precomp_table_g is computed in 2 ECSM \n");

  print_header_for_number_of_point_ops(is_print);
  for (int i = N_MIN; i < N_MAX; i++) {
    main_appr[i - N_MIN] =
        main_count_number_of_point_ops(is_print, ratio, i, bBits);
  }
  print_end_line(is_print);

  uint32_t precomp_g_appr[N_LEN] = {0};
  printf("\n\n[precomp_g] precomp_table_g as constant in 2 ECSM\n");

  print_header_for_number_of_point_ops(is_print);
  for (int i = N_MIN; i < N_MAX; i++) {
    precomp_g_appr[i - N_MIN] =
        precomp_g_count_number_of_point_ops(is_print, ratio, i, bBits);
  }
  print_end_line(is_print);

  if (is_glv) {
    uint32_t glv_appr[N_LEN] = {0};
    uint32_t glv_precomp_g_appr[N_LEN] = {0};
    print_statistics_glv(is_print, ratio, glv_appr, glv_precomp_g_appr);

    printf("\n\n");
    printf("Aggregated table with ~#point_add, where point_double = %d / 5 * "
           "point_add \n",
           ratio);
    print_end_line(true);
    printf("%-5s %-10s %-10s %-10s %-10s \n", "w", "main", "precomp_g", "glv",
           "glv_precomp_g");
    print_end_line(true);
    for (int i = N_MIN; i < N_MAX; i++) {
      printf("%-5d %-10d %-10d %-10d %-10d\n", i, main_appr[i - N_MIN],
             precomp_g_appr[i - N_MIN], glv_appr[i - N_MIN],
             glv_precomp_g_appr[i - N_MIN]);
    }
    print_end_line(true);
  } else {
    printf("\n\n");
    printf("Aggregated table with ~#point_add, where point_double = %d / 5 * "
           "point_add \n",
           ratio);
    print_end_line(true);
    printf("%-5s %-10s %-15s \n", "w", "main", "precomp_g");
    print_end_line(true);
    for (int i = N_MIN; i < N_MAX; i++) {
      printf("%-5d %-15d %-15d \n", i, main_appr[i - N_MIN],
             precomp_g_appr[i - N_MIN]);
    }
    print_end_line(true);
  }
}

// for 1 ECSM
void print_statistics_1(uint32_t ratio, bool is_print, uint32_t bBits) {
  uint32_t main_appr[N_LEN] = {0};
  printf("\n[main] precomp_table_g is computed in 1 ECSM \n");

  print_header_for_number_of_point_ops(is_print);
  for (int i = N_MIN; i < N_MAX; i++) {
    main_appr[i - N_MIN] =
        main_count_number_of_point_ops_1(is_print, ratio, i, bBits);
  }
  print_end_line(is_print);

  uint32_t precomp_g_appr[N_LEN] = {0};
  printf("\n\n[precomp_g] precomp_table_g as constant in 1 ECSM\n");

  print_header_for_number_of_point_ops(is_print);
  for (int i = N_MIN; i < N_MAX; i++) {
    precomp_g_appr[i - N_MIN] =
        precomp_g_count_number_of_point_ops_1(is_print, ratio, i, bBits);
  }
  print_end_line(is_print);

  printf("\n\n");
  printf("Aggregated table with ~#point_add, where point_double = %d / 5 * "
         "point_add \n",
         ratio);
  print_end_line(true);
  printf("%-5s %-10s %-15s \n", "w", "main", "precomp_g");
  print_end_line(true);
  for (int i = N_MIN; i < N_MAX; i++) {
    printf("%-5d %-15d %-15d \n", i, main_appr[i - N_MIN],
           precomp_g_appr[i - N_MIN]);
  }
  print_end_line(true);
}

void print_statistics_l_g(uint32_t ratio, bool is_glv, bool is_print,
                          uint32_t bBits) {

  uint32_t len = N_MAX_G - N_MIN;
  uint32_t precomp_g_large_appr[N_LEN_G] = {0};

  printf("\n\n[precomp_g_large] precomp_table_g as constant in 2 ECSM\n");

  print_header_for_number_of_point_ops_large(is_print);
  for (int i = N_MIN; i < N_MAX; i++) {
    for (int j = i; j < N_MAX_G; j++) {
      precomp_g_large_appr[len * (i - N_MIN) + (j - N_MIN)] =
          precomp_g_large_count_number_of_point_ops(is_print, ratio, i, j,
                                                    bBits);
    }
    print_end_line(is_print);
  }
  print_end_line(is_print);

  if (is_glv) {
    // NOTE: bBits = 128U for secp256k1 w/o using wNAF
    bBits = 128U;
    uint32_t glv_precomp_g_large_appr[N_LEN_G] = {0};
    printf(
        "\n\n[glv_precomp_g_large] precomp_table_g as constant in 4 ECSM \n");

    print_header_for_number_of_point_ops_large(is_print);
    for (int i = N_MIN; i < N_MAX; i++) {
      for (int j = i; j < N_MAX_G; j++) {
        glv_precomp_g_large_appr[len * (i - N_MIN) + (j - N_MIN)] =
            glv_precomp_g_large_count_number_of_point_ops(is_print, ratio, i, j,
                                                          bBits);
      }
      print_end_line(is_print);
    }
    print_end_line(is_print);

    printf("\n\n");
    printf("Aggregated table with ~#point_add, where point_double = %d / 5 * "
           "point_add \n",
           ratio);
    print_end_line(true);
    printf("%-5s %-5s %-10s %-10s \n", "w", "w_g", "precomp_g_large",
           "glv_precomp_g_large");
    print_end_line(true);
    for (int i = N_MIN; i < N_MAX; i++) {
      for (int j = i; j < N_MAX_G; j++) {
        printf("%-5d %-5d %-10d %-10d \n", i, j,
               precomp_g_large_appr[len * (i - N_MIN) + (j - N_MIN)],
               glv_precomp_g_large_appr[len * (i - N_MIN) + (j - N_MIN)]);
      }
      print_end_line(true);
    }
    print_end_line(true);
  } else {
    printf("\n\n");
    printf("Aggregated table with ~#point_add, where point_double = %d / 5 * "
           "point_add \n",
           ratio);
    print_end_line(true);
    printf("%-5s %-5s %-10s \n", "w", "w_g", "precomp_g_large");
    print_end_line(true);
    for (int i = N_MIN; i < N_MAX; i++) {
      for (int j = i; j < N_MAX_G; j++) {
        printf("%-5d %-5d %-10d \n", i, j,
               precomp_g_large_appr[len * (i - N_MIN) + (j - N_MIN)]);
      }
      print_end_line(true);
    }
    print_end_line(true);
  }
}

int main() {
  bool is_glv;
  bool is_print;
  uint32_t ratio;
  uint32_t bBits;

  // for secp256k1, point_double = 0.6 * point_add in projective coordinates
  ratio = 3;
  is_glv = true;
  is_print = false;
  bBits = 256U;
  printf("\n\nHACL secp256k1-ecdsa-verify:\n");
  print_statistics(ratio, is_glv, is_print, bBits);

  // for secp256k1, point_double = 0.6 * point_add in projective coordinates
  ratio = 3;
  is_glv = true;
  is_print = false;
  bBits = 256U;
  printf("\n\nHACL secp256k1-ecdsa-verify:\n");
  print_statistics_l_g(ratio, is_glv, is_print, bBits);

  // for secp256k1, point_double = 0.6 * point_add in projective coordinates
  ratio = 3;
  is_print = false;
  bBits = 256U;
  printf("\n\nHACL secp256k1-ecdsa-sign:\n");
  print_statistics_1(ratio, is_print, bBits);

  // for ed25519, point_double = 0.8 * point_add
  ratio = 4;
  is_glv = false;
  is_print = false;
  bBits = 256U;
  printf("\n\nHACL ed25519-verify:\n");
  print_statistics(ratio, is_glv, is_print, bBits);

  // for ed25519, point_double = 0.8 * point_add
  ratio = 4;
  is_glv = false;
  is_print = false;
  bBits = 256U;
  printf("\n\nHACL ed25519-verify:\n");
  print_statistics_l_g(ratio, is_glv, is_print, bBits);

  // for ed25519, point_double = 0.8 * point_add
  ratio = 4;
  is_print = false;
  bBits = 256U;
  printf("\n\nHACL ed25519-sign:\n");
  print_statistics_1(ratio, is_print, bBits);

  return EXIT_SUCCESS;
}
