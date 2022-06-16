module Hacl.Impl.EC.ScalarMultiplication.WNAF

open FStar.HyperStack.All
open FStar.HyperStack

open FStar.HyperStack.All
open FStar.HyperStack
module ST = FStar.HyperStack.ST

open Lib.IntTypes

open Lib.Buffer

open Spec.ECC.Curves
open Spec.ECC
open Spec.ECC.WNAF

open Hacl.Impl.EC.LowLevel
open Hacl.Spec.EC.Definition

open Hacl.Spec.MontgomeryMultiplication

open FStar.Mul

open Hacl.Impl.EC.Masking
open Hacl.Impl.EC.Masking.ScalarAccess
open Lib.IntTypes.Intrinsics

open FStar.Math.Lemmas


#set-options "--z3rlimit 100 --max_fuel 0 --max_ifuel 0" 
(*  https://www.usenix.org/system/files/conference/usenixsecurity18/sec18-alam.pdf*)


inline_for_extraction noextract
let radix: (r: uint64 {v r == w}) = (u64 5)

inline_for_extraction noextract
let radix_shiftval: (r: shiftval U64 {v r == w /\ v r == v radix}) = (size 5)

inline_for_extraction noextract
let radix_u32: (r: size_t {v r == w /\ v r == v radix}) = (size 5)

inline_for_extraction noextract
let dradix : (r: uint64 {v r == m}) = assert_norm(pow2 5 == 32); (u64 32)

inline_for_extraction noextract
let dradix_wnaf : (r: uint64 {v r == 2 * m}) = 
  FStar.Math.Lemmas.pow2_double_sum 5; 
  assert_norm (pow2 6 == 64);
  (u64 64)


val scalar_rwnaf_step_compute_di: #c: curve -> w: uint64 -> out: lbuffer uint64 (size ((getPower c / Spec.ECC.WNAF.w + 1) * 2))
  -> mask: uint64 {v mask = pow2 (v radix + 1) - 1} 
  -> r: lbuffer uint64 (size 1) -> i: size_t {v i < getPower c / Spec.ECC.WNAF.w + 1} -> 
  Stack unit
  (requires fun h -> live h out /\ live h r)
  (ensures fun h0 _ h1 -> modifies (loc out |+| loc r) h0 h1 /\ (
    let sign = Lib.Sequence.index (as_seq h1 out) (2 * v i + 1) in 
    let abs =  Lib.Sequence.index (as_seq h1 out) (2 * v i) in 
    if v sign = 0 then v w - v dradix == v abs else - (v w - v dradix) == v abs))

let scalar_rwnaf_step_compute_di w out mask r i =
  let h0 = ST.get() in 
  let c = Lib.IntTypes.Intrinsics.sub_borrow_u64 (u64 0) w dradix r in 
  let r0 = index r (size 0) in 
    let h1 = ST.get() in 

  let r2 = u64 0 -. r0 in 
    
  let cAsFlag = eq1_u64 c in 
  let r3 = cmovznz2 r2 r0 cAsFlag in 

  upd out (size 2 *! i) r3;
  upd out (size 2 *! i +! size 1) cAsFlag

(*
val shift_left_bit: a: uint64 {v a <= 1} -> i: shiftval U64 {v i < 63} -> 
  Stack uint64 
  (requires fun h -> True)
  (ensures fun h0 r h1 -> v r <= pow2 (v i))

let shift_left_bit a i = shift_left a i 
*)

val scalar_compute_window_lemma: #c: curve ->  scalar: scalar_bytes #c
  -> i: size_t {v i < getPower c / Spec.ECC.WNAF.w - 1} ->
  Lemma (
    let t = (v i + 1) * w  in 
    let sh0 = v (ith_bit scalar (t + 1)) in 
    let sh1 = v (ith_bit scalar (t + 2)) in 
    let sh2 = v (ith_bit scalar (t + 3)) in 
    let sh3 = v (ith_bit scalar (t + 4)) in 
    let sh4 = v (ith_bit scalar (t + 5)) in 

    let i = sh0 * pow2 1 + 
      sh1 * pow2 2 +
      sh2 * pow2 3 +
      sh3 * pow2 4 +
      sh4 * pow2 5 in 
  scalar_as_nat_ scalar (v (getScalarLen c) - (t + 1)) % m * 2 == i /\
  scalar_as_nat scalar / pow2 (t + 1) % m * 2 == i)



#push-options "--z3rlimit 300"


let scalar_compute_window_lemma #c scalar k = 
  let t = (v k + 1) * w  in 
  let sh0 = v (ith_bit scalar (t + 1)) in 
  let sh1 = v (ith_bit scalar (t + 2)) in 
  let sh2 = v (ith_bit scalar (t + 3)) in 
  let sh3 = v (ith_bit scalar (t + 4)) in 
  let sh4 = v (ith_bit scalar (t + 5)) in 

  let i = sh0 * pow2 1 + 
    sh1 * pow2 2 +
    sh2 * pow2 3 +
    sh3 * pow2 4 +
    sh4 * pow2 5 in 
    
  scalar_as_nat_def #c  scalar (v (getScalarLen c) - (t + 1));
  scalar_as_nat_def #c  scalar (v (getScalarLen c) - (t + 2));
  scalar_as_nat_def #c  scalar (v (getScalarLen c) - (t + 3));
  scalar_as_nat_def #c  scalar (v (getScalarLen c) - (t + 4));
  scalar_as_nat_def #c  scalar (v (getScalarLen c) - (t + 5));

  assume (pow2 2 * 2 == pow2 3);
  assume (pow2 3 * 2 == pow2 4);
  assume (pow2 4 * 2 == pow2 5);
  assume (pow2 5 * 2 == pow2 6);

  assert(2 * scalar_as_nat_ scalar (v (getScalarLen c) - (t + 1)) == 
    pow2 6 * scalar_as_nat_ scalar (v (getScalarLen c) - (t + 6)) + i);

  assert(2 * scalar_as_nat_ scalar (v (getScalarLen c) - (t + 1)) % pow2 6 == 
    (pow2 6 * scalar_as_nat_ scalar (v (getScalarLen c) - (t + 6)) + i) % pow2 6); 

  pow2_multiplication_modulo_lemma_2 (scalar_as_nat_ scalar (v (getScalarLen c) - (t + 1))) 6 1;

  assert(scalar_as_nat_ scalar (v (getScalarLen c) - (t + 1)) * 2 % pow2 6 == 
    (pow2 6 * scalar_as_nat_ scalar (v (getScalarLen c) - (t + 6)) + i) % pow2 6);

  lemma_mod_plus i (scalar_as_nat_ scalar (v (getScalarLen c) - (t + 6))) (pow2 6);


  assert(scalar_as_nat_ scalar (v (getScalarLen c) - (t + 1)) % pow2 5 * 2 ==  i % pow2 6);


  assume (i < pow2 6);
  small_mod i (pow2 6);

  Hacl.Impl.EC.Masking.ScalarAccess.Lemmas.test #c scalar ((v (getScalarLen c) - (t + 1)));
  assert(scalar_as_nat_ scalar (v (getScalarLen c) - (t + 1)) % pow2 5 * 2 == i);
  
  assert(scalar_as_nat_ scalar (v (getScalarLen c) - (t + 1)) == scalar_as_nat scalar / pow2 (t + 1));
  assert(scalar_as_nat scalar / pow2 (t + 1) % m * 2 == i)


val scalar_rwnaf_step_compute_window_: #c: curve 
  -> wStart: uint64 {v wStart < pow2 (64 - 5)}
  -> scalar: scalar_t #MUT #c 
  -> k: size_t {v k < getPower c / Spec.ECC.WNAF.w - 1} -> 
  Stack uint64 
  (requires fun h -> live h scalar)
  (ensures fun h0 w0 h1 -> modifies0 h0 h1 /\ v w0 - v wStart = 
    v (ith_bit (as_seq h0 scalar) ((v k + 1) * w + 1)) * pow2 1 + 
    v (ith_bit (as_seq h0 scalar) ((v k + 1) * w + 2)) * pow2 2 +
    v (ith_bit (as_seq h0 scalar) ((v k + 1) * w + 3)) * pow2 3 +
    v (ith_bit (as_seq h0 scalar) ((v k + 1) * w + 4)) * pow2 4 +
    v (ith_bit (as_seq h0 scalar) ((v k + 1) * w + 5)) * pow2 5)

let scalar_rwnaf_step_compute_window_ #c wStart scalar k = 
  let h0 = ST.get() in 
    assert_norm (pow2 (64 - 5) + pow2 1 + pow2 2 + pow2 3 + pow2 4 + pow2 5 < pow2 64);
  
  let i = (size 1 +! k) *! radix_u32 in 
  let w0 = wStart +! (shift_left (getScalarBit_leftEndian #c scalar (i +! size 1)) (size 1)) in 
  let w0 = w0 +! (shift_left (getScalarBit_leftEndian #c scalar (i +! (size 2))) (size 2)) in 
  let w0 = w0 +! (shift_left (getScalarBit_leftEndian #c scalar (i +! (size 3))) (size 3)) in 
  let w0 = w0 +! (shift_left (getScalarBit_leftEndian #c scalar (i +! (size 4))) (size 4)) in 
  let w0 = w0 +! (shift_left (getScalarBit_leftEndian #c scalar (i +! (size 5))) (size 5)) in 

  w0


#pop-options


val scalar_rwnaf_step_compute_window: #c: curve 
  -> wStart: uint64 {v wStart < pow2 (64 - 5)}
  -> scalar: scalar_t #MUT #c 
  -> k: size_t {v k < getPower c / Spec.ECC.WNAF.w - 1} -> 
  Stack uint64 
  (requires fun h -> live h scalar)
  (ensures fun h0 w0 h1 -> modifies0 h0 h1 /\ (
    let t = (v k + 1) * w in 
    scalar_as_nat_ (as_seq h0 scalar) (v (getScalarLen c) - (t + 1)) % m * 2 == v w0 - v wStart /\
    scalar_as_nat (as_seq h0 scalar) / pow2 (t + 1) % m * 2 == v w0 - v wStart))

let scalar_rwnaf_step_compute_window #c wStart scalar k = 
  let h0 = ST.get() in 
  scalar_compute_window_lemma (as_seq h0 scalar) k;
  scalar_rwnaf_step_compute_window_ #c wStart scalar k  


val scalar_rwnaf_step: #c: curve -> out: lbuffer uint64 (size ((getPower c / Spec.ECC.WNAF.w + 1) * 2))
  -> scalar: scalar_t #MUT #c 
  -> window: lbuffer uint64 (size 1) 
  -> mask: uint64 {v mask = pow2 (v radix + 1) - 1}
  -> r: lbuffer uint64 (size 1) 
  -> i: size_t {v i < getPower c / Spec.ECC.WNAF.w - 1} ->  Stack unit 
  (requires fun h -> live h out /\ live h scalar /\ live h window /\ live h r /\ 
    LowStar.Monotonic.Buffer.all_disjoint [loc out; loc scalar; loc window; loc r] /\ (
    let w0 = v (Lib.Sequence.index (as_seq h window) 0) in 
    w0 == scalar_as_nat (as_seq h scalar) % pow2 (v i * w + w + 1) / pow2 (v i * w) / 2 * 2 + 1 /\
    w0 < 2 * m))
  (ensures fun h0 _ h1 -> modifies (loc out |+| loc window |+| loc r) h0 h1 /\ (
    let k = v i + 1 in 
    let w0 = v (Lib.Sequence.index (as_seq h0 window) 0) in
    let wUpd = v (Lib.Sequence.index (as_seq h1 window) 0) in
    let sign = Lib.Sequence.index (as_seq h1 out) (2 * v i + 1) in 
    let abs =  Lib.Sequence.index (as_seq h1 out) (2 * v i) in 
    (if v sign = 0 then (w0 % (2 * m) - m) == v abs else - (w0 % (2 * m) - m) == v abs) /\
    wUpd < 2 * m /\ 
    wUpd == scalar_as_nat (as_seq h0 scalar) % pow2 (k * w + w + 1) / pow2 (k * w) / 2 * 2 + 1))


let scalar_rwnaf_step #c out scalar window mask r i = 
    let h0 = ST.get() in 
  let wVar = to_u64 (index window (size 0)) in 
    assert(v wVar = v (Lib.Sequence.index (as_seq h0 window) 0));

  let wMask = logand wVar mask in 
    logand_mask wVar mask (v radix + 1); 
    FStar.Math.Lemmas.pow2_double_sum (v radix); 
  scalar_rwnaf_step_compute_di wMask out mask r i; 
    let h1 = ST.get() in 
  let d = wMask -. dradix in 
  let wStart = shift_right (wVar -. d) radix_shiftval in 
  
  FStar.Math.Lemmas.lemma_div_lt_nat (v (wVar -. d)) 64 (v radix_shiftval);

  let w0 = scalar_rwnaf_step_compute_window wStart scalar i in 
  upd window (size 0) w0;

  let h2 = ST.get() in 
  
  let d_i = v wVar % (2 * m) - m in 
  
  assert(
    let w0 = v (Lib.Sequence.index (as_seq h0 window) 0) in
    let sign = Lib.Sequence.index (as_seq h2 out) (2 * v i + 1) in 
    let abs =  Lib.Sequence.index (as_seq h2 out) (2 * v i) in 
    if v sign = 0 then (w0 % (2 * m) - m) == v abs else - (w0 % (2 * m) - m) == v abs);

    
    assert (v wStart = (v wVar - (d_i % pow2 64)) % pow2 64 / m);
    lemma_mod_sub_distr (v wVar)  (d_i) (pow2 64); 
    assert (v wStart = (v wVar - d_i) % pow2 64 / m);
     
    assert (v wStart =  (v wVar - v wVar % (2 * m) + m) % pow2 64  / m);

    small_mod ((v wVar / (2 * m) * (2 * m)) + m) (pow2 64);

    assert (v wStart =  v wVar / (2 * m) * 2 + 1);

    pow2_multiplication_modulo_lemma_2 (scalar_as_nat (as_seq h0 scalar) / pow2 ((v i + 1) * w  + 1)) (w + 1) 1;

    assert(scalar_as_nat (as_seq h0 scalar) / pow2 ((v i + 1) * w  + 1) % m * 2 + (v wVar / (2 * m) * 2 + 1) == v w0);
    assert(scalar_as_nat (as_seq h0 scalar) / pow2 ((v i + 1) * w  + 1) * 2 % pow2 (w + 1)  + (v wVar / (2 * m) * 2 + 1) == v w0);
    
    assert(v wVar < 2 * m);
      small_division_lemma_1 (v wVar) (2 * m);
    assert(v wVar / (2 * m) == 0);


  
 (** **)   assert(2 * (scalar_as_nat (as_seq h0 scalar) / pow2 ((v i + 1) * w  + 1)) % (2 * m) + 1 == v w0);

    pow2_plus (v i * w) (w + 1); 
    division_multiplication_lemma (scalar_as_nat (as_seq h0 scalar)) (pow2 (w + 1)) (pow2 (v i * w));



    division_multiplication_lemma (scalar_as_nat (as_seq h0 scalar)  / (pow2 w)) 2 (pow2 (v i * w));
    pow2_double_mult (v i * w);
    assert((scalar_as_nat (as_seq h0 scalar)  / (pow2 w) / (2 * pow2 (v i * w))) % (pow2 w) * 2 + 1 == v w0);
    
    assert ((scalar_as_nat (as_seq h0 scalar)  / (pow2 w) / (pow2 (v i * w + 1))) % (pow2 w) * 2 + 1 == v w0);


    pow2_modulo_division_lemma_1 (scalar_as_nat (as_seq h0 scalar)  / pow2 w) (v i * w + 1) (v i * w + 1 + w);

    pow2_double_mult (v i * w); 
    
    division_multiplication_lemma (scalar_as_nat (as_seq h0 scalar)  / (pow2 w)  % pow2 (v i * w + 1 + w)) (pow2 (v i * w)) (pow2 1);

   assert(scalar_as_nat (as_seq h0 scalar)  / (pow2 w)  % pow2 (v i * w + 1 + w) / pow2 (v i * w) / pow2 1  * 2 + 1 == v w0);

   let k = v i + 1 in 
   
   assert(2 * (scalar_as_nat (as_seq h0 scalar) / pow2 (k * w  + 1)) % (pow2 (w + 1)) + 1 == v w0);
   

   assert(scalar_as_nat (as_seq h0 scalar) / pow2 (k * w  + 1) % pow2 w * 2 + 1 == v w0);

   pow2_modulo_division_lemma_1 (scalar_as_nat (as_seq h0 scalar)) (k * w + 1) (k * w + 1 + w);
   pow2_double_mult (k * w);
   division_multiplication_lemma (scalar_as_nat (as_seq h0 scalar) % pow2 (k * w + w + 1)) (pow2 (k * w)) 2;
   
   assert(scalar_as_nat (as_seq h0 scalar) % pow2 (k * w + w + 1) / pow2 (k * w) / 2 * 2 + 1 == v w0);
   assert(v w0 < 2 * m)
    


val scalar_rwnaf_lemma0: #c: curve -> scalar: scalar_bytes #c 
  -> Lemma (scalar_as_nat scalar % pow2 8 = v (Lib.Sequence.index scalar (v (getScalarLenBytes c) - 1)))

let scalar_rwnaf_lemma0 #c scalar = 
  let len = v (getScalarLen c) in 

  let i0 = ith_bit scalar 0 in 
  let i1 = ith_bit scalar 1 in 
  let i2 = ith_bit scalar 2 in 
  let i3 = ith_bit scalar 3 in 
  let i4 = ith_bit scalar 4 in  
  let i5 = ith_bit scalar 5 in 
  let i6 = ith_bit scalar 6 in  
  let i7 = ith_bit scalar 7 in  

  let q = v (getScalarLenBytes c) - 1 in


  shift_right_lemma (Lib.Sequence.index scalar (v (getScalarLenBytes c) - 1)) (size 0);
  logand_mask (Lib.Sequence.index scalar  (v (getScalarLenBytes c) - 1)) (u8 1) 1; 

  assert(v i0 == v (Lib.Sequence.index scalar q) % 2);
  assume (v i0 + v i1 * pow2 1 + v i2 * pow2 2 + v i3 * pow2 3 + v i4 * pow2 4 + v i5 * pow2 5 + v i6 * pow2 6 + v i7  * pow2 7== v (Lib.Sequence.index scalar q));

  assert_norm (pow2 2 = 4);
  assert_norm (pow2 3 = 8);
  assert_norm (pow2 4 = 16);
  assert_norm (pow2 5 = 32);
  assert_norm (pow2 6 = 64);
  assert_norm (pow2 7 = 128);
  assert_norm (pow2 8 = 256);


  scalar_as_nat_def #c scalar len;
  scalar_as_nat_def #c scalar (len - 1);
  scalar_as_nat_def #c scalar (len - 2);
  scalar_as_nat_def #c scalar (len - 3);
  scalar_as_nat_def #c scalar (len - 4);
  scalar_as_nat_def #c scalar (len - 5);
  scalar_as_nat_def #c scalar (len - 6);
  scalar_as_nat_def #c scalar (len - 7);

  lemma_mod_plus (v (Lib.Sequence.index scalar q)) (scalar_as_nat_ scalar (len - 8)) (pow2 8);
  assert ( v (Lib.Sequence.index scalar q) < pow2 8);
  small_mod (v (Lib.Sequence.index scalar q)) (pow2 8);

  assert(scalar_as_nat scalar % pow2 8 = v (Lib.Sequence.index scalar q))



val logor_mask: a: uint64 -> Lemma (v (logor (u64 1) a) == v a / 2 * 2 + 1)

let logor_mask a = 
  if v a % 2 = 0 then 
    begin
      logor_disjoint (u64 1) a 1;
      assert(v a + 1 == v (logor (u64 1) a))
    end
  else
    begin
      assume (v (logor (u64 1) a) == v a)
    end


val scalar_rwnaf_loop: out: lbuffer uint64 (size 104) -> scalar: lbuffer uint8 (size 32) 
  -> mask: uint64 {v mask = pow2 (v radix + 1) - 1}
  -> window: lbuffer uint64 (size 1) -> 
  Stack unit 
  (requires fun h -> live h out /\ live h scalar /\ live h window /\ 
    LowStar.Monotonic.Buffer.all_disjoint [loc out; loc scalar; loc window] /\ (
    let w0 = v (Lib.Sequence.index (as_seq h window) 0) in 
    w0 == scalar_as_nat #P256 (as_seq h scalar) % pow2 (w + 1) / 2 * 2 + 1 /\
    w0 < 2 * m))
  (ensures fun h0 _ h1 -> modifies (loc out |+| loc window) h0 h1 /\ (
    forall (j: nat {j < 50}). 
      v (Lib.Sequence.index (as_seq h1 out) j) == (2 * (scalar_as_nat #P256 (as_seq h0 scalar) / 2) / pow2 (w * j) + 1) % (2 * m) - m) /\ (
    let w0 = v (Lib.Sequence.index (as_seq h1 window) 0) in 
    w0 == scalar_as_nat #P256 (as_seq h0 scalar) % pow2 (50 * w + w + 1) / pow2 (50 * w) / 2 * 2 + 1 /\
    w0 < 2 * m))


(* to check that the second is the out *)
let scalar_rwnaf_loop out scalar mask window = 
  push_frame(); 
  let r = create (size 1) (u64 0) in 
    let h0 = ST.get() in 
  
  let inv h (i:nat {i <= 50}) = 
    live h out /\ live h scalar /\ live h window /\ live h r /\
    modifies (loc out |+| loc window |+| loc r) h0 h /\ (
    let w0 = v (Lib.Sequence.index (as_seq h window) 0) in 
    w0 == scalar_as_nat #P256 (as_seq h0 scalar) % pow2 (i * w + w + 1) / pow2 (i * w) / 2 * 2 + 1 /\
    w0 < 2 * m /\ (
    forall (j: nat {j < i}). 
      v (Lib.Sequence.index (as_seq h out) j) == (2 * (scalar_as_nat #P256 (as_seq h0 scalar) / 2) / pow2 (w * j) + 1) % (2 * m) - m)) in  

  Lib.Loops.for 0ul 50ul inv (fun i -> 
    admit();
    let h0_ = ST.get() in 
    scalar_rwnaf_step #P256 out scalar window mask r i;
    let h1_ = ST.get() in 
    
    assert(
      let w0 = scalar_as_nat #P256 (as_seq h0 scalar) % pow2 (v i * w + w + 1) / pow2 (v i * w) / 2 * 2 + 1 in
      let wUpd = v (Lib.Sequence.index (as_seq h1_ window) 0) in
      let sign = Lib.Sequence.index (as_seq h1_ out) (2 * v i + 1) in 
      let abs =  Lib.Sequence.index (as_seq h1_ out) (2 * v i) in 
      if v sign = 0 then (w0 % (2 * m) - m) == v abs else - (w0 % (2 * m) - m) == v abs /\
      wUpd < 2 * m /\ 
      wUpd == scalar_as_nat #P256 (as_seq h0 scalar) % pow2 ((v i + 1) * w + w + 1) / pow2 ((v i + 1)  * w) / 2 * 2 + 1)

  );

  let h1 = ST.get() in 
  assert(inv h1 50);
  assert(forall (j: nat {j < 50}). 
      v (Lib.Sequence.index (as_seq h1 out) j) == (2 * (scalar_as_nat #P256 (as_seq h0 scalar) / 2) / pow2 (w * j) + 1) % (2 * m) - m);
  pop_frame()



val scalar_rwnaf : out: lbuffer uint64 (size 104) -> scalar: lbuffer uint8 (size 32) -> 
  Stack unit 
    (requires fun h -> live h out /\ live h scalar)
    (ensures fun h0 _ h1 -> True)


let scalar_rwnaf out scalar = 
  push_frame();

  let h0 = ST.get() in 
  let in0 = to_u64 (index scalar (size 31)) in 
  let mask = dradix_wnaf -! (u64 1) in 
  let windowStartValue = logor (u64 1) (logand in0 mask) in 

  assert_norm (pow2 6 == 64);
    logand_mask in0 mask 6;
    scalar_rwnaf_lemma0 #P256 (as_seq h0 scalar); 
    logor_mask (logand in0 mask); 
    pow2_modulo_modulo_lemma_1 (scalar_as_nat #P256 (as_seq h0 scalar)) 6 8;


  assert(v windowStartValue == scalar_as_nat #P256 (as_seq h0 scalar) % pow2 6 / 2 * 2 + 1);
  multiply_fractions (scalar_as_nat #P256 (as_seq h0 scalar) % pow2 6) 2;
  pow2_double_mult w;
  

  let window = create (size 1) windowStartValue in 

  let r = create (size 1) (u64 0) in 

  let h0 = ST.get() in 

  scalar_rwnaf_loop out scalar mask window; 



  admit();




  let i = size 50 in 
  
  let wVar = index window (size 0) in 
  let w = logand wVar mask in 
  let c = Lib.IntTypes.Intrinsics.sub_borrow_u64 (u64 0) w dradix r in 

  let r0 = index r (size 0) in 
  let r2 = (u64 0) -. index r (size 0) in 

  let cAsFlag = (u64 0) -. c in 
  let r3 = cmovznz2 r2 r0 cAsFlag in 

  upd out (size 2 *! i) r3;
  upd out (size 2 *! i +! size 1) cAsFlag;

  let d = w -! dradix in 

  let wStart = shift_right (wVar -! d) radix in 
  upd out (size 102) wStart; 

  pop_frame()



inline_for_extraction
type pointAffine = lbuffer uint64 (size 8)

assume val getUInt64: index: size_t {v index < 3456 - 4} -> Stack (lbuffer uint64 (size 4))
  (requires fun h -> True)
  (ensures fun h0 _ h1 -> modifies0 h0 h1)

[@CInline]
val copy_conditional: #c: curve -> out: felem c -> x: felem c -> mask: uint64{uint_v mask = 0 \/ uint_v mask = pow2 64 - 1} -> Stack unit 
  (requires fun h -> live h out /\ live h x)
  (ensures fun h0 _ h1 -> modifies (loc out) h0 h1 (* /\ 
    (if uint_v mask = 0 then as_seq h1 out == as_seq h0 out else as_seq h1 out == as_seq h0 x) /\
    (if uint_v mask = 0 then as_nat h1 out == as_nat h0 out else as_nat h1 out == as_nat h0 x)
  ) 
*))

let copy_conditional out x mask = 
    let h0 = ST.get() in 
  let out_0 = index out (size 0) in 
  let out_1 = index out (size 1) in 
  let out_2 = index out (size 2) in 
  let out_3 = index out (size 3) in 

  let x_0 = index x (size 0) in 
  let x_1 = index x (size 1) in 
  let x_2 = index x (size 2) in 
  let x_3 = index x (size 3) in 

  let r_0 = logxor out_0 (logand mask (logxor out_0 x_0)) in 
  let r_1 = logxor out_1 (logand mask (logxor out_1 x_1)) in 
  let r_2 = logxor out_2 (logand mask (logxor out_2 x_2)) in 
  let r_3 = logxor out_3 (logand mask (logxor out_3 x_3)) in 

  (* lemma_xor_copy_cond out_0 x_0 mask;
  lemma_xor_copy_cond out_1 x_1 mask;
  lemma_xor_copy_cond out_2 x_2 mask;
  lemma_xor_copy_cond out_3 x_3 mask; *)

  upd out (size 0) r_0;
  upd out (size 1) r_1;
  upd out (size 2) r_2;
  upd out (size 3) r_3 (*;
    let h1 = ST.get() in 

  lemma_eq_funct_ (as_seq h1 out) (as_seq h0 out);
  lemma_eq_funct_ (as_seq h1 out) (as_seq h0 x) *)



val loopK:  result: pointAffine -> d: uint64 -> point: pointAffine -> j: size_t -> Stack unit 
  (requires fun h -> True)
  (ensures fun h0 _ h1 -> True)

let loopK result d point j = 
  let invK h (k: nat) = True in 
  Lib.Loops.for 0ul 16ul invK (fun k -> 
 
    let mask = eq_mask d (to_u64 k) in 
    eq_mask_lemma d (to_u64 k); 
    

    let lut_cmb_x = getUInt64 ((j *! size 16 +! k) *! 8) in 
    let lut_cmb_y = getUInt64 ((j *! size 16 +! k) *! 8 +! (size 4))  in

    copy_conditional #P256 (sub point (size 0) (size 4)) lut_cmb_x mask;
    copy_conditional #P256 (sub point (size 4) (size 4)) lut_cmb_y mask)


inline_for_extraction noextract
val sub4_0: y:felem P256 -> result: felem P256 -> 
  Stack uint64
    (requires fun h -> live h y /\ live h result /\ eq_or_disjoint y result)
    (ensures fun h0 c h1 -> modifies1 result h0 h1 /\ v c <= 1 /\ as_nat P256 h1 result - v c * pow2 256 == 0 - as_nat P256 h0 y)

let sub4_0 y result = 
  let h0 = ST.get() in 
  
  let r0 = sub result (size 0) (size 1) in 
  let r1 = sub result (size 1) (size 1) in 
  let r2 = sub result (size 2) (size 1) in 
  let r3 = sub result (size 3) (size 1) in 
      
  let cc = sub_borrow_u64 (u64 0) (u64 0) y.(size 0) r0 in 
  let cc = sub_borrow_u64 cc (u64 0) y.(size 1) r1 in 
  let cc = sub_borrow_u64 cc (u64 0) y.(size 2) r2 in 
  let cc = sub_borrow_u64 cc (u64 0) y.(size 3) r3 in 
    
    assert(let r1_0 = as_seq h0 r1 in let r0_ = as_seq h0 result in Seq.index r0_ 1 == Seq.index r1_0 0);
    assert(let r2_0 = as_seq h0 r2 in let r0_ = as_seq h0 result in Seq.index r0_ 2 == Seq.index r2_0 0);
    assert(let r3_0 = as_seq h0 r3 in let r0_ = as_seq h0 result in Seq.index r0_ 3 == Seq.index r3_0 0);

    assert_norm (pow2 64 * pow2 64 = pow2 128);
    assert_norm (pow2 64 * pow2 64 * pow2 64 = pow2 192);
    assert_norm (pow2 64 * pow2 64 * pow2 64 * pow2 64 = pow2 256);
    
  cc


inline_for_extraction noextract
val add4_variables_void: x: felem P256 -> cin: uint64 {uint_v cin <=1} ->  y0: uint64 -> y1: uint64 -> y2: uint64 
  -> y3: uint64 -> 
  result: felem P256 -> 
  Stack unit
    (requires fun h -> live h x /\ live h result /\ eq_or_disjoint x result )
    (ensures fun h0 c h1 -> modifies (loc result) h0 h1  /\  
      as_nat P256 h1 result == (as_nat P256 h0 x + uint_v y0 + uint_v y1 * pow2 64 + uint_v y2 * pow2 128 + uint_v y3 * pow2 192 + uint_v cin) % pow2 256)   

let add4_variables_void x cin y0 y1 y2 y3 result = 
  let h0 = ST.get() in 
    
  let r0 = sub result (size 0) (size 1) in      
  let r1 = sub result (size 1) (size 1) in 
  let r2 = sub result (size 2) (size 1) in 
  let r3 = sub result (size 3) (size 1) in 

  let cc0 = add_carry_u64 cin x.(0ul) y0 r0 in 
  let cc1 = add_carry_u64 cc0 x.(1ul) y1 r1 in 
  let cc2 = add_carry_u64 cc1 x.(2ul) y2 r2 in 
  add_carry_u64 cc2 x.(3ul) y3 r3;
  
    assert_norm (pow2 64 * pow2 64 = pow2 128);
    assert_norm (pow2 64 * pow2 64 * pow2 64 = pow2 192);
    assert_norm (pow2 64 * pow2 64 * pow2 64 * pow2 64 = pow2 256);
    
    assert(let r1_0 = as_seq h0 r1 in let r0_ = as_seq h0 result in Seq.index r0_ 1 == Seq.index r1_0 0);
    assert(let r2_0 = as_seq h0 r2 in let r0_ = as_seq h0 result in Seq.index r0_ 2 == Seq.index r2_0 0);
    assert(let r3_0 = as_seq h0 r3 in let r0_ = as_seq h0 result in Seq.index r0_ 3 == Seq.index r3_0 0);

    let h1 = ST.get() in 

    let x0 = Lib.Sequence.index (as_seq h0 x) 0 in 
    let x1 = Lib.Sequence.index (as_seq h0 x) 1 in 
    let x2 = Lib.Sequence.index (as_seq h0 x) 2 in 
    let x3 = Lib.Sequence.index (as_seq h0 x) 3 in 


    let r0 = Lib.Sequence.index (as_seq h1 r0) 0 in 
    let r1 = Lib.Sequence.index (as_seq h1 r1) 0 in 
    let r2 = Lib.Sequence.index (as_seq h1 r2) 0 in 
    let r3 = Lib.Sequence.index (as_seq h1 r3) 0 in 
(*

  calc (==) {((v x3 + v y3 + v cc2) % pow2 64 * pow2 192) % pow2 256;
  (==) {lemma_mod_mul_distr_l ((v x3 + v y3 + v cc2) % pow2 64) (pow2 192) (pow2 256)}
  ((v x3 + v y3 + v cc2) % pow2 64 % pow2 256 * pow2 192) % pow2 256;
  (==) {pow2_modulo_modulo_lemma_2 (v x3 + v y3 + v cc2) 256 64}
  ((v x3 + v y3 + v cc2) % pow2 256 * pow2 192) % pow2 256;
  (==) {lemma_mod_mul_distr_l (v x3 + v y3 + v cc2) (pow2 192) (pow2 256)}
  ((v x3 + v y3 + v cc2) * pow2 192) % pow2 256;
  };


  calc (==) {
  (v x0 + v y0 + v cin +  v x1 * pow2 64 + v y1 * pow2 64 +  v x2 * pow2 128 + v y2 * pow2 128 + (v x3 + v y3 + v cc2) % pow2 64 * pow2 192 - v cc2 * pow2 192) % pow2 256;
  (==) {}
  (v x0 + v y0 + v cin +  v x1 * pow2 64 + v y1 * pow2 64 +  v x2 * pow2 128 + v y2 * pow2 128 - v cc2 * pow2 192 + (v x3 + v y3 + v cc2) % pow2 64 * pow2 192 ) % pow2 256;
  (==) {lemma_mod_add_distr (v x0 + v y0 + v cin +  v x1 * pow2 64 + v y1 * pow2 64 +  v x2 * pow2 128 + v y2 * pow2 128 - v cc2 * pow2 192) ((v x3 + v y3 + v cc2) % pow2 64 * pow2 192) (pow2 256)}
  (v x0 + v y0 + v cin +  v x1 * pow2 64 + v y1 * pow2 64 +  v x2 * pow2 128 + v y2 * pow2 128 + ((v x3 + v y3 + v cc2) % pow2 64 * pow2 192) % pow2 256 - v cc2 * pow2 192) % pow2 256;
  (==) {}
  (v x0 + v y0 + v cin +  v x1 * pow2 64 + v y1 * pow2 64 +  v x2 * pow2 128 + v y2 * pow2 128  - v cc2 * pow2 192 + ((v x3 + v y3 + v cc2) * pow2 192) % pow2 256) % pow2 256; 
  (==) {lemma_mod_add_distr (v x0 + v y0 + v cin + v x1 * pow2 64 + v y1 * pow2 64 +  v x2 * pow2 128 + v y2 * pow2 128 - v cc2 * pow2 192) ((v x3 + v y3 + v cc2) * pow2 192) (pow2 256)}
  (v x0 + v y0 + v cin +  v x1 * pow2 64 + v y1 * pow2 64 +  v x2 * pow2 128 + v y2 * pow2 128 - v cc2 * pow2 192 + (v x3 + v y3 + v cc2) * pow2 192 ) % pow2 256;
  (==) {}
  (v x0 + v y0 + v cin +  v x1 * pow2 64 + v y1 * pow2 64 +  v x2 * pow2 128 + v y2 * pow2 128 + v x3 * pow2 192 + v y3 * pow2 192) % pow2 256;
  (==) {}
  (as_nat h0 x +  uint_v y0 + uint_v y1 * pow2 64 + uint_v y2 * pow2 128 + uint_v y3 * pow2 192 + uint_v cin) % pow2 256; };

  
  small_mod (v r0 + v r1 * pow2 64 + v r2 * pow2 128  + v r3 * pow2 192) (pow2 256)

*) ()

val p256_neg: arg2: felem P256 -> out: felem P256 -> Stack unit 
  (requires fun h0 -> live h0 out /\ live h0 arg2 /\ eq_or_disjoint arg2 out /\ as_nat P256 h0 arg2 < prime256)
  (ensures (fun h0 _ h1 -> modifies (loc out) h0 h1 (* /\ 
	as_nat P256 h1 out == (0 - as_nat P256 h0 arg2) % prime256 /\
	as_nat P256 h1 out == toDomain_ ((fromDomain_ 0 - fromDomain_ (as_nat P256 h0 arg2)) % prime256) *)
    )
)    

let p256_neg arg2 out =     
  assert_norm (pow2 64 * pow2 64 * pow2 64 * pow2 64 = pow2 256);
    let h0 = ST.get() in 
  let t = sub4_0 arg2 out in 

    let h1 = ST.get() in 
    (* lemma_t_computation2 t; *)
  let t0 = (u64 0) -. t in 
  let t1 = ((u64 0) -. t) >>. (size 32) in 
  let t2 = u64 0 in 
  let t3 = t -. (t <<. (size 32)) in 
    (* modulo_addition_lemma  (0 - as_nat h0 arg2) prime256 1; *)
  add4_variables_void out (u64 0)  t0 t1 t2 t3 out;
    let h2 = ST.get() in 
  
  (* small_mod (as_nat h2 out) (pow2 256);
  small_mod (as_nat h1 out) (pow2 256);

    let h2 = ST.get() in 
      assert(
      if 0 - as_nat h0 arg2 >= 0 then 
	begin
	  modulo_lemma (0 - as_nat h0 arg2) prime256;
	  as_nat h2 out == (0 - as_nat h0 arg2) % prime256
	end
      else
          begin
	    modulo_lemma (as_nat h2 out) prime256;
            as_nat h2 out == (0 - as_nat h0 arg2) % prime256
	  end);
    substractionInDomain 0 (felem_seq_as_nat (as_seq h0 arg2));
    inDomain_mod_is_not_mod (fromDomain_ 0 - fromDomain_ (felem_seq_as_nat (as_seq h0 arg2))) *) ()


inline_for_extraction noextract
val copy_point_conditional_mask_u64_2:  result: point P256
  -> x: point P256 -> mask: uint64 {uint_v mask == 0 \/ uint_v mask == pow2 64 - 1}  
  -> Stack unit
  (requires fun h -> live h result /\ live h x /\ disjoint result x)
  (ensures fun h0 _ h1 -> modifies (loc result) h0 h1 ) (*  /\ (
    if uint_v mask = 0
    then 
      as_nat h1 (gsub result (size 0) (size 4)) == as_nat h0 (gsub result (size 0) (size 4)) /\
      as_nat h1 (gsub result (size 4) (size 4)) == as_nat h0 (gsub result (size 4) (size 4)) /\
      as_nat h1 (gsub result (size 8) (size 4)) == as_nat h0 (gsub result (size 8) (size 4)) 
    else
      as_nat h1 (gsub result (size 0) (size 4)) == as_nat h0 (gsub x (size 0) (size 4)) /\
      as_nat h1 (gsub result (size 4) (size 4)) == as_nat h0 (gsub x (size 4) (size 4)) /\
      as_nat h1 (gsub result (size 8) (size 4)) == as_nat h0 (gsub x (size 8) (size 4)))
  )

*)


let copy_point_conditional_mask_u64_2  result x mask = 
  let h0 = ST.get() in 

  let x_x = sub x (size 0) (size 4) in 
  let x_y = sub x (size 4) (size 4) in 
  let x_z = sub x (size 8) (size 4) in 

  let result_x = sub result (size 0) (size 4) in 
  let result_y = sub result (size 4) (size 4) in 
  let result_z = sub result (size 8) (size 4) in 

  copy_conditional #P256 result_x x_x mask;
  copy_conditional #P256 result_y x_y mask;
  copy_conditional #P256 result_z x_z mask


val conditional_substraction: result: point P256 -> p: point P256 -> scalar: lbuffer uint8 (size 32) -> 
  tempBuffer: lbuffer uint64 (size 88) ->
  Stack unit 
    (requires fun h -> live h result /\ live h p /\ live h scalar /\ live h tempBuffer)
    (ensures fun h0 _ h1 -> True)


let conditional_substraction result p scalar tempBuffer = 
  push_frame();

  let tempPoint = create (size 12) (u64 0) in 
  let bpMinus = create (size 8) (u64 0) in 
    let bpMinusX = sub bpMinus (size 0) (size 4) in 
    let bpMinusY = sub bpMinus (size 4) (size 4) in 

  (* mask == 0 <==> scalar last bit == 0 *)

  let i0 = index scalar (size 31) in 
  let mask = lognot((u64 0) -. to_u64 (logand i0 (u8 1))) in 

  let bpX = getUInt64 (size 0) in 
  let bpY = getUInt64 (size 4) in 

    copy bpMinusX bpX;
    p256_neg bpY bpMinusY;

  Hacl.Impl.EC.PointAddMixed.point_add_mixed p bpMinus tempPoint tempBuffer;

  copy_point_conditional_mask_u64_2 result tempPoint mask;
  pop_frame()


val scalar_multiplication_cmb:  #buf_type: buftype -> result: point P256 -> 
  scalar: lbuffer_t buf_type uint8 (size 32) -> 
  tempBuffer:  lbuffer uint64 (size 88)  -> 
  Stack unit
  (requires fun h -> True )
  (ensures fun h0 _ h1 -> modifies (loc result |+| loc tempBuffer) h0 h1)


let scalar_multiplication_cmb #buf_type result scalar tempBuffer = 
  push_frame();
    let rnaf2 = create (size 104) (u64 0) in 
    let lut:pointAffine = create (size 8) (u64 0) in 
    let temp4 = sub tempBuffer (size 0) (size 4) in 

    scalar_rwnaf rnaf2 scalar;

    let i = size 1 in 

    let invJ h1 (j:nat) = True in  

    Lib.Loops.for 0ul 26ul invJ (fun j ->
      let d = index rnaf2 (size 2 *! (j *! (size 2) +! i)) in
      let is_neg = index rnaf2 (size 2 *! (j *! (size 2) +! i) +! (size 1)) in 
      let d = shift_right (d -! size 1) (size 1) in 

      loopK lut d lut j;

      let yLut = sub lut (size 4) (size 4) in 
      p256_neg yLut temp4;

      copy_conditional #P256 yLut temp4 is_neg;
      Hacl.Impl.EC.PointAddMixed.point_add_mixed result lut result tempBuffer
    );
     
    let i = size 0 in 

    let invPointDouble h (j: nat) = True in 
    Lib.Loops.for 0ul radix invPointDouble 
    (fun j -> Hacl.Impl.EC.PointDouble.point_double result result tempBuffer);

    Lib.Loops.for 0ul 26ul invJ (fun j ->
      let d = index rnaf2 (size 2 *! (j *! (size 2) +! i)) in 
      let is_neg = index rnaf2 (size 2 *! (j *! (size 2) +! i) +! (size 1)) in 
      let d = shift_right (d -! size 1) (size 1) in 

      loopK lut d lut j;

    	let yLut = sub lut (size 4) (size 4) in 
    	p256_neg yLut temp4;

	
    	copy_conditional #P256 yLut temp4  is_neg;
    	Hacl.Impl.EC.PointAddMixed.point_add_mixed result lut result tempBuffer
    );


    conditional_substraction result result scalar tempBuffer;
  

  pop_frame()
