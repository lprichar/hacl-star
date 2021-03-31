module Hacl.Impl.Ed25519.PointEqual

module ST = FStar.HyperStack.ST
open FStar.HyperStack
open FStar.HyperStack.All
open FStar.Mul

open Lib.IntTypes
open Lib.Buffer

open Hacl.Bignum25519

module F51 = Hacl.Impl.Ed25519.Field51
module S51 = Hacl.Spec.Curve25519.Field51.Definition

module SC = Spec.Curve25519

module BD = Hacl.Bignum.Definitions
module BN = Hacl.Bignum
module SD = Hacl.Spec.Bignum.Definitions
module SN = Hacl.Spec.Bignum

#reset-options "--z3rlimit 20 --max_fuel 0 --max_ifuel 0"

val gte_q: s:lbuffer uint64 4ul ->
  Stack bool
  (requires fun h -> live h s)
  (ensures  fun h0 b h1 -> modifies0 h0 h1 /\
    (b <==> BD.bn_v h0 s >= Spec.Ed25519.q))

[@CInline]
let gte_q s =
  push_frame ();
  let q = create 4ul (u64 0) in
  Hacl.Impl.BignumQ.make_q q;
  let b = BN.bn_lt_mask 4ul s q in
  let h = ST.get () in
  SN.bn_lt_mask_lemma (as_seq h s) (as_seq h q);
  assert (if v b = 0 then BD.bn_v h s >= BD.bn_v h q else BD.bn_v h s < BD.bn_v h q);
  pop_frame ();
  Hacl.Spec.Bignum.Base.unsafe_bool_of_limb0 b


let u51 = n:nat{n < 0x8000000000000}

val lemma_equality1:
  a:u51 -> b:u51 -> c:u51 -> d:u51 -> e:u51 ->
  a':u51 -> b':u51 -> c':u51 -> d':u51 -> e':u51 ->
  Lemma (requires a < pow2 51 /\ b < pow2 51 /\ c < pow2 51 /\ d < pow2 51 /\ e < pow2 51 /\
                  a' < pow2 51 /\ b' < pow2 51 /\ c' < pow2 51 /\ d' < pow2 51 /\ e' < pow2 51)
        (ensures (a + pow2 51 * b + pow2 102 * c + pow2 153 * d + pow2 204 * e ==
                  a' + pow2 51 * b' + pow2 102 * c' + pow2 153 * d' + pow2 204 * e') <==>
          (a == a' /\ b == b' /\ c == c' /\ d == d' /\ e == e'))


open FStar.Calc

#push-options "--z3rlimit 100"

let lemma_equality1 a b c d e a' b' c' d' e' =
  assert_norm(pow2 51 = 0x8000000000000);
  assert_norm(pow2 102 = 0x40000000000000000000000000);
  assert_norm(pow2 153 = 0x200000000000000000000000000000000000000);
  assert_norm(pow2 204 = 0x1000000000000000000000000000000000000000000000000000);
  let lemma_l_imp () : Lemma
    (requires a + pow2 51 * b + pow2 102 * c + pow2 153 * d + pow2 204 * e ==
                  a' + pow2 51 * b' + pow2 102 * c' + pow2 153 * d' + pow2 204 * e')
    (ensures a == a' /\ b == b' /\ c == c' /\ d == d' /\ e == e')
    =
    FStar.Math.Lemmas.lemma_mult_le_left (pow2 51) b (pow2 51 - 1);
    FStar.Math.Lemmas.lemma_mult_le_left (pow2 102) c (pow2 51 - 1);
    FStar.Math.Lemmas.lemma_mult_le_left (pow2 153) d (pow2 51 - 1);
    FStar.Math.Lemmas.lemma_mult_le_left (pow2 51) b' (pow2 51 - 1);
    FStar.Math.Lemmas.lemma_mult_le_left (pow2 102) c' (pow2 51 - 1);
    FStar.Math.Lemmas.lemma_mult_le_left (pow2 153) d' (pow2 51 - 1);
    assert_norm (pow2 51 - 1 + pow2 51 * (pow2 51 - 1) < pow2 102);
    assert_norm (pow2 51 - 1 + pow2 51 * (pow2 51 - 1) + pow2 102 * (pow2 51 - 1) < pow2 153);

    assert_norm (pow2 51 - 1 + pow2 51 * (pow2 51 - 1) + pow2 102 * (pow2 51 - 1) + pow2 153 * (pow2 51 - 1) < pow2 204);

    calc (==) {
      (a + pow2 51 * b + pow2 102 * c + pow2 153 * d + pow2 204 * e) % (pow2 204);
      (==) { FStar.Math.Lemmas.lemma_mod_plus_distr_r
         (a + pow2 51 * b + pow2 102 * c + pow2 153 * d)
         (pow2 204 * e)
         (pow2 204);
           FStar.Math.Lemmas.cancel_mul_mod e (pow2 204)
        }
      (a + pow2 51 * b + pow2 102 * c + pow2 153 * d) % (pow2 204);
    };
    calc (==) {
      (a' + pow2 51 * b' + pow2 102 * c' + pow2 153 * d' + pow2 204 * e') % (pow2 204);
      (==) { FStar.Math.Lemmas.lemma_mod_plus_distr_r
         (a' + pow2 51 * b' + pow2 102 * c' + pow2 153 * d')
         (pow2 204 * e')
         (pow2 204);
           FStar.Math.Lemmas.cancel_mul_mod e' (pow2 204)
        }
      (a' + pow2 51 * b' + pow2 102 * c' + pow2 153 * d') % (pow2 204);
    };
    FStar.Math.Lemmas.lemma_mod_injective (pow2 204)
      (a + pow2 51 * b + pow2 102 * c + pow2 153 * d)
      (a' + pow2 51 * b' + pow2 102 * c' + pow2 153 * d');

    calc (==) {
      (a + pow2 51 * b + pow2 102 * c + pow2 153 * d) % (pow2 153);
      (==) { FStar.Math.Lemmas.lemma_mod_plus_distr_r
         (a + pow2 51 * b + pow2 102 * c)
         (pow2 153 * d)
         (pow2 153);
           FStar.Math.Lemmas.cancel_mul_mod d (pow2 153)
        }
      (a + pow2 51 * b + pow2 102 * c) % (pow2 153);
    };
    calc (==) {
      (a' + pow2 51 * b' + pow2 102 * c' + pow2 153 * d') % (pow2 153);
      (==) { FStar.Math.Lemmas.lemma_mod_plus_distr_r
         (a' + pow2 51 * b' + pow2 102 * c')
         (pow2 153 * d')
         (pow2 153);
           FStar.Math.Lemmas.cancel_mul_mod d' (pow2 153)
        }
      (a' + pow2 51 * b' + pow2 102 * c') % (pow2 153);
    };
    FStar.Math.Lemmas.lemma_mod_injective (pow2 153)
      (a + pow2 51 * b + pow2 102 * c)
      (a' + pow2 51 * b' + pow2 102 * c');


    calc (==) {
      (a + pow2 51 * b + pow2 102 * c) % (pow2 102);
      (==) { FStar.Math.Lemmas.lemma_mod_plus_distr_r
         (a + pow2 51 * b)
         (pow2 102 * c)
         (pow2 102);
           FStar.Math.Lemmas.cancel_mul_mod c (pow2 102)
        }
      (a + pow2 51 * b) % (pow2 102);
    };
    calc (==) {
      (a' + pow2 51 * b' + pow2 102 * c') % (pow2 102);
      (==) { FStar.Math.Lemmas.lemma_mod_plus_distr_r
         (a' + pow2 51 * b')
         (pow2 102 * c')
         (pow2 102);
           FStar.Math.Lemmas.cancel_mul_mod c' (pow2 102)
        }
      (a' + pow2 51 * b') % (pow2 102);
    };
    FStar.Math.Lemmas.lemma_mod_injective (pow2 102)
      (a + pow2 51 * b)
      (a' + pow2 51 * b');

    FStar.Math.Lemmas.cancel_mul_mod b (pow2 51);
    FStar.Math.Lemmas.cancel_mul_mod b' (pow2 51);
    FStar.Math.Lemmas.lemma_mod_injective (pow2 51) a a'

  in
  let lemma_r_imp () : Lemma
    (requires a == a' /\ b == b' /\ c == c' /\ d == d' /\ e == e')
    (ensures a + pow2 51 * b + pow2 102 * c + pow2 153 * d + pow2 204 * e ==
                  a' + pow2 51 * b' + pow2 102 * c' + pow2 153 * d' + pow2 204 * e')
    = ()
  in
  Classical.move_requires lemma_l_imp ();
  Classical.move_requires lemma_r_imp ()


val eq:
    a:felem
  -> b:felem ->
  Stack bool
    (requires fun h -> live h a /\ live h b /\
      F51.fevalh h a == F51.as_nat h a /\
      F51.fevalh h b == F51.as_nat h b /\
      F51.felem_fits h a (1, 1, 1, 1, 1) /\
      F51.felem_fits h b (1, 1, 1, 1, 1)
    )
    (ensures  fun h0 r h1 -> h0 == h1 /\
      (r <==> F51.fevalh h0 a == F51.fevalh h0 b)
    )

[@CInline]
let eq a b =
  let a0 = a.(0ul) in
  let a1 = a.(1ul) in
  let a2 = a.(2ul) in
  let a3 = a.(3ul) in
  let a4 = a.(4ul) in
  let b0 = b.(0ul) in
  let b1 = b.(1ul) in
  let b2 = b.(2ul) in
  let b3 = b.(3ul) in
  let b4 = b.(4ul) in
  assert_norm(pow2 51 = 0x8000000000000);
  assert_norm(pow2 102 = 0x40000000000000000000000000);
  assert_norm(pow2 153 = 0x200000000000000000000000000000000000000);
  assert_norm(pow2 204 = 0x1000000000000000000000000000000000000000000000000000);
  assert_norm(pow2 255 - 19 = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed);
  let h0 = get() in
  lemma_equality1 (v a0) (v a1) (v a2) (v a3) (v a4) (v b0) (v b1) (v b2) (v b3) (v b4);
  let open Lib.RawIntTypes in
  let open FStar.UInt64 in
  (u64_to_UInt64 a0 =^ u64_to_UInt64 b0 &&
   u64_to_UInt64 a1 =^ u64_to_UInt64 b1 &&
   u64_to_UInt64 a2 =^ u64_to_UInt64 b2 &&
   u64_to_UInt64 a3 =^ u64_to_UInt64 b3 &&
   u64_to_UInt64 a4 =^ u64_to_UInt64 b4)


inline_for_extraction noextract
val point_equal_1:
    p:point
  -> q:point
  -> tmp:lbuffer uint64 20ul ->
  Stack bool
    (requires fun h ->
      live h p /\ live h q /\ live h tmp /\
      disjoint tmp p /\ disjoint tmp q /\
      F51.point_inv_t h p /\ F51.point_inv_t h q
    )
    (ensures  fun h0 z h1 -> modifies (loc tmp) h0 h1 /\
      (let px, py, pz, pt = F51.point_eval h0 p in
      let qx, qy, qz, qt = F51.point_eval h0 q in
      z <==> ((px `SC.fmul` qz) == (qx `SC.fmul` pz))
      )
    )

let point_equal_1 p q tmp =
  let pxqz = sub tmp 0ul 5ul in
  let qxpz = sub tmp 5ul 5ul in
  let pyqz = sub tmp 10ul 5ul in
  let qypz = sub tmp 15ul 5ul in
  let h0 = get() in
  fmul pxqz (getx p) (getz q);
  reduce pxqz;
  fmul qxpz (getx q) (getz p);
  reduce qxpz;
  eq pxqz qxpz


inline_for_extraction noextract
val point_equal_2:
    p:point
  -> q:point
  -> tmp:lbuffer uint64 20ul ->
  Stack bool
    (requires fun h ->
      live h p /\ live h q /\live h tmp /\
      disjoint tmp p /\ disjoint tmp q /\
      F51.point_inv_t h p /\ F51.point_inv_t h q
    )
    (ensures  fun h0 z h1 -> modifies (loc tmp) h0 h1 /\
      (let px, py, pz, pt = F51.point_eval h0 p in
      let qx, qy, qz, qt = F51.point_eval h0 q in
      z == (if ((py `SC.fmul` qz) <> (qy `SC.fmul` pz)) then false else true))
    )

let point_equal_2 p q tmp =
  let pxqz = sub tmp 0ul 5ul in
  let qxpz = sub tmp 5ul 5ul in
  let pyqz = sub tmp 10ul 5ul in
  let qypz = sub tmp 15ul 5ul in
  fmul pyqz (gety p) (getz q);
  reduce pyqz;
  fmul qypz (gety q) (getz p);
  reduce qypz;
  eq pyqz qypz


val point_equal:
    p:point
  -> q:point ->
  Stack bool
    (requires fun h -> live h p /\ live h q /\
      F51.point_inv_t h p /\ F51.point_inv_t h q
    )
    (ensures  fun h0 z h1 -> modifies0 h0 h1 /\
      (z <==> Spec.Ed25519.point_equal (F51.point_eval h0 p) (F51.point_eval h0 q))
    )

let point_equal p q =
  push_frame();
  let tmp = create 20ul (u64 0) in
  let b = point_equal_1 p q tmp in
  let res = if b then point_equal_2 p q tmp else false in
  pop_frame();
  res
