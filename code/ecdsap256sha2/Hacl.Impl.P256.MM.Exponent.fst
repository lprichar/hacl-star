module Hacl.Impl.P256.MM.Exponent

open FStar.HyperStack.All
open FStar.HyperStack
module ST = FStar.HyperStack.ST

open Lib.IntTypes
open Lib.Buffer

open FStar.Math.Lemmas
open Hacl.Impl.P256.Math 

open Hacl.Impl.LowLevel
open FStar.Tactics
open FStar.Tactics.Canon 

open FStar.Mul

open Lib.Loops

open Hacl.Impl.P256.MontgomeryMultiplication
open Spec.P256.MontgomeryMultiplication

open Hacl.Impl.P256.LowLevel
open Hacl.Impl.P256.Arithmetics

open Spec.P256.Definitions
open Spec.P256.Lemmas
open Spec.P256.Ladder
open Spec.P256


#set-options "--z3rlimit 200 --fuel 0 --ifuel 0" 

(* This is a very very very very bad decision, but I don´t wanna do common spec right now *)

inline_for_extraction noextract
val scalar_bit:
    #buf_type: buftype -> 
    s:lbuffer_t buf_type uint8 (size 32)
  -> n:size_t{v n < 256}
  -> Stack uint64
    (requires fun h0 -> live h0 s)
    (ensures  fun h0 r h1 -> h0 == h1 /\
      r == Spec.P256.ith_bit (as_seq h0 s) (v n) /\ v r <= 1)
      
let scalar_bit #buf_type s n =
  let h0 = ST.get () in
  mod_mask_lemma ((Lib.Sequence.index (as_seq h0 s) (v n / 8)) >>. (n %. 8ul)) 1ul;
  assert_norm (1 = pow2 1 - 1);
  assert (v (mod_mask #U8 #SEC 1ul) == v (u8 1));
  to_u64 ((s.(n /. 8ul) >>. (n %. 8ul)) &. u8 1)


[@ CInline]
val cswap: bit:uint64{v bit <= 1} -> p:felem -> q:felem
  -> Stack unit
    (requires fun h ->
      as_nat h p < prime /\ as_nat h q < prime /\ 
      live h p /\ live h q /\ (disjoint p q \/ p == q))
    (ensures  fun h0 _ h1 ->
      modifies (loc p |+| loc q) h0 h1 /\
	(
	  let (r0, r1) = conditional_swap_exponent bit (as_nat h0 p) (as_nat h0 q) in 
	  let pBefore = as_seq h0 p in let qBefore = as_seq h0 q in 
	  let pAfter = as_seq h1 p in let qAfter = as_seq h1 q in 
	  if uint_v bit = 0 then r0 == as_nat h0 p /\ r1 == as_nat h0 q else r0 == as_nat h0 q /\ r1 == as_nat h0 p) /\
	  as_nat h1 p < prime /\ as_nat h1 q < prime /\
      (v bit == 1 ==> as_seq h1 p == as_seq h0 q /\ as_seq h1 q == as_seq h0 p) /\
      (v bit == 0 ==> as_seq h1 p == as_seq h0 p /\ as_seq h1 q == as_seq h0 q))


let cswap bit p1 p2 =
  let h0 = ST.get () in
  let mask = u64 0 -. bit in
  let open Lib.Sequence in 
  [@ inline_let]
  let inv h1 (i:nat{i <= 4}) =
    (forall (k:nat{k < i}).
      if v bit = 1
      then (as_seq h1 p1).[k] == (as_seq h0 p2).[k] /\ (as_seq h1 p2).[k] == (as_seq h0 p1).[k]
      else (as_seq h1 p1).[k] == (as_seq h0 p1).[k] /\ (as_seq h1 p2).[k] == (as_seq h0 p2).[k]) /\
    (forall (k:nat{i <= k /\ k < 4}).
      (as_seq h1 p1).[k] == (as_seq h0 p1).[k] /\ (as_seq h1 p2).[k] == (as_seq h0 p2).[k]) /\
    modifies (loc p1 |+| loc p2) h0 h1 in
 
  Lib.Loops.for 0ul 4ul inv
    (fun i ->
      let dummy = mask &. (p1.(i) ^. p2.(i)) in
      p1.(i) <- p1.(i) ^. dummy;
      p2.(i) <- p2.(i) ^. dummy;
      lemma_cswap2_step bit ((as_seq h0 p1).[v i]) ((as_seq h0 p2).[v i])
    );
  let h1 = ST.get () in
  Lib.Sequence.eq_intro (as_seq h1 p1) (if v bit = 1 then as_seq h0 p2 else as_seq h0 p1);
  Lib.Sequence.eq_intro (as_seq h1 p2) (if v bit = 1 then as_seq h0 p1 else as_seq h0 p2)


inline_for_extraction noextract 
val upload_one_montg_form: b: felem -> Stack unit
  (requires fun h -> live h b)
  (ensures fun h0 _ h1 -> modifies (loc b) h0 h1 /\ as_nat h1 b == toDomain_ (1))

let upload_one_montg_form b =
  upd b (size 0) (u64 1);
  upd b (size 1) (u64 18446744069414584320);
  upd b (size 2) (u64 18446744073709551615);
  upd b (size 3) (u64 4294967294);
  
  assert_norm (1 + 18446744069414584320 * pow2 64 + 18446744073709551615 * pow2 64 * pow2 64 + 4294967294 * pow2 64 * pow2 64 * pow2 64  == pow2 256 % prime256);
  lemmaToDomain 1


inline_for_extraction noextract
val montgomery_ladder_power_step0: a: felem -> b: felem -> Stack unit
  (requires fun h -> live h a /\ live h b /\ as_nat h a < prime /\ as_nat h b < prime /\ disjoint a b )
  (ensures fun h0 _ h1 -> modifies (loc a |+| loc b) h0 h1 /\ as_nat h1 a < prime /\ as_nat h1 b < prime /\
    (
      let (r0D, r1D) = _exp_step0 (fromDomain_ (as_nat h0 a)) (fromDomain_ (as_nat h0 b)) in 
      r0D == fromDomain_ (as_nat h1 a) /\ r1D == fromDomain_ (as_nat h1 b)  /\
      as_nat h1 a < prime /\ as_nat h1 b < prime
    )
)

let montgomery_ladder_power_step0 a b = 
    let h0 = ST.get() in 
    montgomery_multiplication_buffer a b b;
    lemmaToDomainAndBackIsTheSame (fromDomain_ (as_nat h0 a) * fromDomain_ (as_nat h0 b) % prime);
  montgomery_multiplication_buffer a a a ;
    lemmaToDomainAndBackIsTheSame (fromDomain_ (as_nat h0 a) * fromDomain_ (as_nat h0 a) % prime)


inline_for_extraction noextract
val montgomery_ladder_power_step: a: felem -> b: felem -> scalar: lbuffer uint8 (size 32) ->   i:size_t{v i < 256} ->  Stack unit
  (requires fun h -> live h a  /\ live h b /\ live h scalar /\ as_nat h a < prime /\ as_nat h b < prime /\ disjoint a b)
  (ensures fun h0 _ h1 -> modifies (loc a |+| loc b) h0 h1  /\
    (
      let a_ = fromDomain_ (as_nat h0 a) in 
      let b_ = fromDomain_ (as_nat h0 b) in 
      let (r0D, r1D) = _exp_step (as_seq h0 scalar) (uint_v i) (a_, b_) in 
      r0D == fromDomain_ (as_nat h1 a) /\ r1D == fromDomain_ (as_nat h1 b) /\ 
      as_nat h1 a < prime /\ as_nat h1 b < prime 
    ) 
  )  

let montgomery_ladder_power_step a b scalar i = 
    let h0 = ST.get() in 
  let bit0 = (size 255) -. i in 
  let bit = scalar_bit scalar bit0 in 
  cswap bit a b;
  montgomery_ladder_power_step0 a b;
  cswap bit a b;
  lemma_swaped_steps (fromDomain_ (as_nat h0 a)) (fromDomain_ (as_nat h0 b))


inline_for_extraction noextract 
val _montgomery_ladder_power: a: felem -> b: felem -> scalar: ilbuffer uint8 (size 32) -> Stack unit
  (requires fun h -> live h a /\ live h b /\ live h scalar /\ as_nat h a < prime /\ 
    as_nat h b < prime /\ disjoint a b /\disjoint a scalar /\ disjoint b scalar)
  (ensures fun h0 _ h1 -> modifies (loc a |+| loc b) h0 h1 /\ 
    (
      let a_ = fromDomain_ (as_nat h0 a) in 
      let b_ = fromDomain_ (as_nat h0 b) in 
      let (r0D, r1D) = _exponent_spec (as_seq h0 scalar) (a_, b_) in 
      r0D == fromDomain_ (as_nat h1 a) /\ r1D == fromDomain_ (as_nat h1 b) /\
      as_nat h1 a < prime /\ as_nat h1 b < prime )
  )

  
let _montgomery_ladder_power a b scalar = 
  let h0 = ST.get() in 
  [@inline_let]
  let spec_exp h0  = _exp_step (as_seq h0 scalar) in 
  [@inline_let]
  let acc (h: mem) : GTot (tuple2 nat_prime nat_prime) = (fromDomain_ (as_nat h a), fromDomain_ (as_nat h b)) in 
  Lib.LoopCombinators.eq_repeati0 256 (spec_exp h0) (acc h0);
  [@inline_let]
  let inv h (i: nat {i <= 256}) = 
    live h a /\ live h b /\ live h scalar /\ modifies (loc a |+| loc b) h0 h /\ as_nat h a < prime /\ as_nat h b < prime /\
    acc h == Lib.LoopCombinators.repeati i (spec_exp h0) (acc h0) in 
  for 0ul 256ul inv (
    fun i -> 
	  montgomery_ladder_power_step a b scalar i;
	  Lib.LoopCombinators.unfold_repeati 256 (spec_exp h0) (acc h0) (uint_v i))


val montgomery_ladder_power: a: felem -> scalar: ilbuffer uint8 (size 32) ->  Stack unit 
  (requires fun h -> live h a /\ as_nat h a < prime)
  (ensures fun h0 _ h1 -> modifies (loc a) h0 h1
)


let montgomery_ladder_power r scalar = 
  push_frame(); 
    let p = create (size 4) (u64 0) in 
    upload_one_montg_form p; 
    recall_contents prime256_buffer (Lib.Sequence.of_list p256_prime_list);
    _montgomery_ladder_power p r scalar;
      lemmaToDomainAndBackIsTheSame 1;
    copy r p;
  pop_frame()  


(* sqPower =  (prime + 1) // 4 *)
val uploadSQpower: a: felem -> Stack unit 
  (requires fun h -> live h a)
  (ensures fun h0 _ h1 -> modifies (loc a) h0 h1 /\ as_nat h1 a == 28948022302589062190674361737351893382521535853822578548883407827216774463488)

let uploadSQpower a = 
  upd a (size 0) (u64 0);
  upd a (size 1) (u64 1073741824);
  upd a (size 2) (u64 4611686018427387904);
  upd a (size 3) (u64 4611686017353646080)


val square_root: a: felem -> Stack unit 
  (requires fun h -> True)
  (ensures fun h0 _ h1 -> True)

let square_root a  = 
  push_frame();
    let sqPower = create (size 4) (u64 0) in 
    uploadSQpower sqPower;
    montgomery_ladder_power a sqPower;
  pop_frame()



val uploadA: a: felem -> Stack unit
  (requires fun h -> live h a)
  (ensures fun h0 _ h1 -> modifies (loc a) h0 h1 /\ as_nat h1 a == aCoordinateP256 % prime256)

let uploadA a = 
  upd a (size 0) (u64 18446744073709551612);
  upd a (size 1) (u64 4294967295);
  upd a (size 2) (u64 0);
  upd a (size 3) (u64 18446744069414584321);
  assert_norm(18446744073709551612 + 4294967295 * pow2 64 + 18446744069414584321 * pow2 64 * pow2 64 * pow2 64 = aCoordinateP256 % prime256)
  

val uploadB: b: felem -> Stack unit 
  (requires fun h -> live h b)
  (ensures fun h0 _ h1 -> modifies (loc b) h0 h1 /\ as_nat h1 b == bCoordinateP256)

let uploadB b = 
  upd b (size 0) (u64 4309448131093880907);
  upd b (size 1) (u64 7285987128567378166);
  upd b (size 2) (u64 12964664127075681980);
  upd b (size 3) (u64 6540974713487397863);
  assert_norm (4309448131093880907 + 7285987128567378166 * pow2 64 + 12964664127075681980 * pow2 64 * pow2 64 + 6540974713487397863 * pow2 64 * pow2 64 * pow2 64 == 41058363725152142129326129780047268409114441015993725554835256314039467401291)



val computeYFromX: x: felem ->  result: felem -> sign: uint64 -> Stack unit 
  (requires fun h -> live h x /\ live h result /\ as_nat h x < prime)
  (ensures fun h0 _ h1 -> True)


let computeYFromX x result sign = 
  push_frame();
    let aCoordinateBuffer = create (size 4) (u64 0) in 
    let bCoordinateBuffer = create (size 4) (u64 0) in 
   
    uploadA aCoordinateBuffer;
    uploadB bCoordinateBuffer;

    montgomery_multiplication_buffer aCoordinateBuffer x aCoordinateBuffer;

    cube x result;
    p256_add result aCoordinateBuffer result;
    p256_add result bCoordinateBuffer result;

    uploadZeroImpl aCoordinateBuffer;
    p256_sub aCoordinateBuffer result bCoordinateBuffer;

    cmovznz4 sign bCoordinateBuffer result result;

    square_root result;


    admit();
    


 pop_frame()   
    
    
