module Hacl.Impl.K256.PointMul

open FStar.HyperStack
open FStar.HyperStack.ST
open FStar.Mul

open Lib.IntTypes
open Lib.Buffer

module ST = FStar.HyperStack.ST
module LSeq = Lib.Sequence

module SE = Spec.Exponentiation
module BE = Hacl.Impl.Exponentiation
module ME = Hacl.Impl.MultiExponentiation
module PT = Hacl.Impl.PrecompTable
module BPT = Hacl.Spec.K256.PrecompTable

module S = Spec.K256
module SL = Spec.K256.Lemmas

open Hacl.K256.Field
open Hacl.K256.Scalar
open Hacl.Impl.K256.Point

#set-options "--z3rlimit 50 --fuel 0 --ifuel 0"

///////////////////////////////////////////

unfold
let linv_ctx (a:LSeq.lseq uint64 0) : Type0 = True

unfold
let refl (p:LSeq.lseq uint64 15{point_inv_lseq p}) : GTot S.aff_point =
  S.to_aff_point (point_eval_lseq p)

inline_for_extraction noextract
let mk_to_k256_comm_monoid : BE.to_comm_monoid U64 15ul 0ul = {
  BE.a_spec = S.aff_point;
  BE.comm_monoid = S.mk_k256_comm_monoid;
  BE.linv_ctx = linv_ctx;
  BE.linv = point_inv_lseq;
  BE.refl = refl;
  }


inline_for_extraction noextract
val point_add : BE.lmul_st U64 15ul 0ul mk_to_k256_comm_monoid
let point_add ctx x y xy =
  let h0 = ST.get () in
  SL.to_aff_point_add_lemma (point_eval h0 x) (point_eval h0 y);
  Hacl.Impl.K256.PointAdd.point_add xy x y


inline_for_extraction noextract
val point_double : BE.lsqr_st U64 15ul 0ul mk_to_k256_comm_monoid
let point_double ctx x xx =
  let h0 = ST.get () in
  SL.to_aff_point_double_lemma (point_eval h0 x);
  Hacl.Impl.K256.PointDouble.point_double xx x


val make_point_at_inf: p:point -> Stack unit
  (requires fun h -> live h p)
  (ensures  fun h0 _ h1 -> modifies (loc p) h0 h1 /\
    point_inv h1 p /\ S.to_aff_point (point_eval h1 p) == S.aff_point_at_inf)

let make_point_at_inf p =
  SL.to_aff_point_at_infinity_lemma ();
  let px, py, pz = getx p, gety p, getz p in
  set_zero px;
  set_one py;
  set_zero pz


inline_for_extraction noextract
val point_zero : BE.lone_st U64 15ul 0ul mk_to_k256_comm_monoid
let point_zero ctx one = make_point_at_inf one


inline_for_extraction noextract
let mk_k256_concrete_ops : BE.concrete_ops U64 15ul 0ul = {
  BE.to = mk_to_k256_comm_monoid;
  BE.lone = point_zero;
  BE.lmul = point_add;
  BE.lsqr = point_double;
}

//////////////////////////////////////////////////////

inline_for_extraction noextract
val make_g: g:point -> Stack unit
  (requires fun h -> live h g)
  (ensures  fun h0 _ h1 -> modifies (loc g) h0 h1 /\
    point_inv h1 g /\ point_eval h1 g == S.g)

let make_g g =
  let gx, gy, gz = getx g, gety g, getz g in

  [@inline_let]
  let x =
   (u64 0x2815b16f81798,
    u64 0xdb2dce28d959f,
    u64 0xe870b07029bfc,
    u64 0xbbac55a06295c,
    u64 0x79be667ef9dc) in

  assert_norm (0x79be667ef9dc < max48);
  assert_norm (0xe1108a8fd17b4 < max52);
  assert_norm (S.g_x == as_nat5 x);
  make_u52_5 gx x;

  [@inline_let]
  let y =
   (u64 0x7d08ffb10d4b8,
    u64 0x48a68554199c4,
    u64 0xe1108a8fd17b4,
    u64 0xc4655da4fbfc0,
    u64 0x483ada7726a3) in

  assert_norm (S.g_y == as_nat5 y);
  make_u52_5 gy y;

  set_one gz


val point_mul: out:point -> scalar:qelem -> q:point -> Stack unit
  (requires fun h ->
    live h out /\ live h scalar /\ live h q /\
    disjoint out q /\ disjoint out scalar /\ disjoint q scalar /\
    point_inv h q /\ qas_nat h scalar < S.q)
  (ensures  fun h0 _ h1 -> modifies (loc out) h0 h1 /\
    point_inv h1 out /\
    S.to_aff_point (point_eval h1 out) ==
    S.to_aff_point (S.point_mul (qas_nat h0 scalar) (point_eval h0 q)))

let point_mul out scalar q =
  let h0 = ST.get () in
  SE.exp_fw_lemma S.mk_k256_concrete_ops (point_eval h0 q) 256 (qas_nat h0 scalar) 4;
  BE.lexp_fw_consttime 15ul 0ul mk_k256_concrete_ops 4ul (null uint64) q 4ul 256ul scalar out


val point_mul_double_vartime:
  out:point -> scalar1:qelem -> q1:point -> scalar2:qelem -> q2:point -> Stack unit
  (requires fun h ->
    live h out /\ live h scalar1 /\ live h q1 /\ live h scalar2 /\ live h q2 /\
    disjoint q1 out /\ disjoint q2 out /\ disjoint q1 q2 /\
    disjoint scalar1 out /\ disjoint scalar2 out /\
    point_inv h q1 /\ point_inv h q2 /\
    qas_nat h scalar1 < S.q /\ qas_nat h scalar2 < S.q)
  (ensures fun h0 _ h1 -> modifies (loc out) h0 h1 /\
    point_inv h1 out /\
    S.to_aff_point (point_eval h1 out) ==
    S.to_aff_point (S.point_mul_double
      (qas_nat h0 scalar1) (point_eval h0 q1)
      (qas_nat h0 scalar2) (point_eval h0 q2)))

[@CInline]
let point_mul_double_vartime out scalar1 q1 scalar2 q2 =
  let h0 = ST.get () in
  SE.exp_double_fw_lemma S.mk_k256_concrete_ops
    (point_eval h0 q1) 256 (qas_nat h0 scalar1)
    (point_eval h0 q2) (qas_nat h0 scalar2) 4;
  ME.lexp_double_fw_vartime 15ul 0ul mk_k256_concrete_ops 4ul (null uint64) q1 4ul 256ul scalar1 q2 scalar2 out

////////////////////////////////////////

inline_for_extraction noextract
let table_inv : BE.table_inv_t U64 15ul 16ul =
  [@inline_let] let len = 15ul in
  [@inline_let] let ctx_len = 0ul in
  [@inline_let] let k = mk_k256_concrete_ops in
  [@inline_let] let l = 4ul in
  [@inline_let] let table_len = 16ul in
  BE.table_inv_precomp len ctx_len k l table_len


// Precomputed table for a base point [0Q, 1Q, 2Q, .., 15Q]
inline_for_extraction noextract
val mk_precomp_base_point_table: g:point ->
  StackInline (lbuffer uint64 240ul)
    (requires fun h ->
      live h g /\ point_inv h g /\ point_eval h g == S.g)
    (ensures  fun h0 table h1 -> live h1 table /\
      stack_allocated table h0 h1 BPT.precomp_basepoint_table_lseq /\
      table_inv (as_seq h0 g) (as_seq h1 table))

let mk_precomp_base_point_table g =
  assert_norm (List.Tot.length BPT.precomp_basepoint_table_list == 240);
  let h0 = ST.get () in
  let res = createL BPT.precomp_basepoint_table_list in
  let h1 = ST.get () in
  BPT.precomp_basepoint_table_lemma ();
  res


val point_mul_g: out:point -> scalar:qelem -> Stack unit
  (requires fun h ->
    live h scalar /\ live h out /\ disjoint out scalar /\
    qas_nat h scalar < S.q)
  (ensures  fun h0 _ h1 -> modifies (loc out) h0 h1 /\
    point_inv h1 out /\
    S.to_aff_point (point_eval h1 out) ==
    S.to_aff_point (S.point_mul_g (qas_nat h0 scalar)))

[@CInline]
let point_mul_g out scalar =
  push_frame ();
  [@inline_let] let len = 15ul in
  [@inline_let] let ctx_len = 0ul in
  [@inline_let] let k = mk_k256_concrete_ops in
  [@inline_let] let l = 4ul in
  [@inline_let] let table_len = 16ul in
  [@inline_let] let bLen = 4ul in
  [@inline_let] let bBits = 256ul in
  let g = create 15ul (u64 0) in
  make_g g;
  let h0 = ST.get () in
  assert (point_inv h0 g /\ point_eval h0 g == S.g);
  SE.exp_fw_lemma S.mk_k256_concrete_ops (point_eval h0 g) 256 (qas_nat h0 scalar) 4;

  // let table = create (table_len *! len) (u64 0) in
  // PT.lprecomp_table len ctx_len k (null uint64) g table_len table;
  let table = mk_precomp_base_point_table g in

  [@inline_let]
  let table_inv : BE.table_inv_t U64 len table_len =
    BE.table_inv_precomp len ctx_len k l table_len in
  let h1 = ST.get () in
  assert (table_inv (as_seq h1 g) (as_seq h1 table));
  assert (point_eval h1 g == S.g);

  BE.mk_lexp_fw_table len ctx_len k l table_len
    table_inv
    (BE.lprecomp_get_consttime len ctx_len k l table_len)
    (null uint64) g bLen bBits scalar table out;
  pop_frame ()


val point_mul_g_double_vartime: out:point -> scalar1:qelem -> scalar2:qelem -> q2:point ->
  Stack unit
  (requires fun h ->
    live h out /\ live h scalar1 /\ live h scalar2 /\ live h q2 /\
    disjoint q2 out /\ disjoint out scalar1 /\ disjoint out scalar2 /\
    point_inv h q2 /\ qas_nat h scalar1 < S.q /\ qas_nat h scalar2 < S.q)
  (ensures fun h0 _ h1 -> modifies (loc out) h0 h1 /\
    point_inv h1 out /\
    S.to_aff_point (point_eval h1 out) ==
    S.to_aff_point (S.point_mul_double_g
      (qas_nat h0 scalar1) (qas_nat h0 scalar2) (point_eval h0 q2)))

[@CInline]
let point_mul_g_double_vartime out scalar1 scalar2 q2 =
  push_frame ();
  let g = create 15ul (u64 0) in
  make_g g;
  point_mul_double_vartime out scalar1 g scalar2 q2;
  pop_frame ()
