module Hacl.Impl.Sparkle

open FStar.HyperStack.All
open FStar.HyperStack
module ST = FStar.HyperStack.ST

open Lib.IntTypes
open Lib.ByteBuffer
open Lib.Buffer

open Spec.SPARKLE2
open FStar.Mul


#set-options " --z3rlimit 200"

inline_for_extraction
let size_word: size_t = 4ul

inline_for_extraction
let vsize_rcon: size_t = 8ul


let rcon: x: glbuffer uint32 vsize_rcon 
  {witnessed #uint32 #vsize_rcon x (Lib.Sequence.of_list rcon_list) /\ recallable x} =
  createL_global rcon_list


type branch_len =  n: size_t {v n = 1 \/ v n = 2 \/ v n = 3 \/ v n = 4 \/ v n = 6 \/ v n = 8}

inline_for_extraction noextract
type branch branch_len = lbuffer uint32 (2ul *! branch_len)


inline_for_extraction noextract
val getBranch: #n: branch_len -> b: branch n -> i: size_t{v i < v n} -> 
  Stack (tuple2 uint32 uint32)
  (requires fun h -> live h b)
  (ensures fun h0 r h1 -> modifies0 h0 h1 /\ r == Spec.SPARKLE2.getBranch #(v n) (v i) (as_seq h0 b))

let getBranch #l b i =  
  Lib.Buffer.index b (2ul *! i), Lib.Buffer.index b (2ul *! i +! 1ul)


inline_for_extraction noextract 
val setBranch: #n: branch_len -> i: size_t {v i < v n} -> b0: branch1 -> b: branch n -> 
  Stack unit 
  (requires fun h -> live h b)
  (ensures fun h0 _ h1 -> modifies (loc b) h0 h1 /\ 
    as_seq h1 b == Spec.SPARKLE2.setBranch #(v n) (v i) b0 (as_seq h0 b))

let setBranch #n i (x, y) b =
  upd #uint32 b (2ul *! i) x; upd #uint32 b (2ul *! i +! 1ul) y


val xor_step: #l: branch_len -> b: branch l
  -> tx: lbuffer uint32 (size 1) 
  -> ty: lbuffer uint32 (size 1) 
  -> i: size_t {v i <= v l / 2} ->
  Stack unit
  (requires fun h -> live h b /\ live h tx /\ live h ty /\ disjoint tx ty)
  (ensures fun h0 _ h1 -> modifies (loc tx |+| loc ty) h0 h1 /\ (
    let tx_0 = Lib.Sequence.index (as_seq h0 tx) 0 in 
    let ty_0 = Lib.Sequence.index (as_seq h0 ty) 0 in 
    let tx_1: uint32 = Lib.Sequence.index (as_seq h1 tx) 0 in 
    let ty_1: uint32 = Lib.Sequence.index (as_seq h1 ty) 0 in  
    (tx_1, ty_1) == Spec.SPARKLE2.xor_step #(v l) (as_seq h0 b) (v i) (tx_0, ty_0)))

let xor_step #l b tx ty i = 
  let xi, yi = getBranch b i in 
  let tx_0 = index tx (size 0) in 
  let ty_0 = index ty (size 0) in 
  upd tx (size 0) (xi ^. tx_0);
  upd ty (size 0) (yi ^. ty_0)


val xor: #l: branch_len -> b: branch l -> Stack (tuple2 uint32 uint32)
    (requires fun h -> live h b)
    (ensures fun h0 r h1 -> modifies0 h0 h1 /\ r == Spec.SPARKLE2.xor #(v l) (as_seq h0 b))

let xor #l b = 
  push_frame();
    let tx = create (size 1) (u32 0) in 
    let ty = create (size 1) (u32 0) in 
  let h0 = ST.get() in 
  let inv h (i: nat {i <= v l / 2})  = live h b /\ live h ty /\ live h tx /\ 
    disjoint tx ty /\ disjoint tx b /\ disjoint ty b /\
    modifies (loc tx |+| loc ty) h0 h /\ (
      let tx_0 = Lib.Sequence.index (as_seq h0 tx) 0 in 
      let ty_0 = Lib.Sequence.index (as_seq h0 ty) 0 in 
      let tx_1: uint32 = Lib.Sequence.index (as_seq h tx) 0 in 
      let ty_1: uint32 = Lib.Sequence.index (as_seq h ty) 0 in  
      (tx_1, ty_1) == 
	Lib.LoopCombinators.repeati #(tuple2 uint32 uint32) i (Spec.SPARKLE2.xor_step #(v l) (as_seq h0 b)) (tx_0, ty_0)) in 
  Lib.LoopCombinators.eq_repeati0 (v l / 2 + 1) (Spec.SPARKLE2.xor_step #(v l) (as_seq h0 b)) (
    Lib.Sequence.index (as_seq h0 tx) 0, Lib.Sequence.index (as_seq h0 ty) 0);
    
  Lib.Loops.for 0ul (l >>. 1ul) inv
    (fun (i: size_t {v i < v l / 2}) -> 
      xor_step b tx ty i;
      let f = Spec.SPARKLE2.xor_step #(v l) (as_seq h0 b) in 
      
      let tx_0 = Lib.Sequence.index (as_seq h0 tx) 0 in 
      let ty_0 = Lib.Sequence.index (as_seq h0 ty) 0 in 
      Lib.LoopCombinators.unfold_repeati (v l / 2 + 1) f (tx_0, ty_0) (v i));
  let r0, r1 = index tx (size 0), index ty (size 0) in 
  pop_frame();
  r0, r1



val m: #l: branch_len -> b: branch l ->  Stack (tuple2 uint32 uint32)
  (requires fun h -> live h b)
  (ensures fun h0 r h1 -> modifies (loc b) h0 h1)

let m #n b = 
  let ltx, lty = xor #n b in 
  (l1 ltx, l1 lty)


inline_for_extraction noextract
val xor_3: i0: tuple2 uint32 uint32  -> i1: tuple2 uint32 uint32  -> i2: tuple2 uint32 uint32 -> 
  Stack (tuple2 uint32 uint32) 
    (requires fun h -> true)
    (ensures fun h0 _ h1 -> modifies0 h0 h1)

let xor_3 (i0x, i0y) (i1x, i1y) (i2x, i2y)  = 
  let o0_x = i0x ^. i1x ^. i2x in 
  let o0_y = i0y ^. i1y ^. i2y in   
  o0_x, o0_y



inline_for_extraction
val l_step: #n: branch_len -> perm: branch n -> i: size_t {2 * v i <= v n} 
  -> rightBranch: branch n -> Stack unit 
  (requires fun h -> live h perm /\ live h rightBranch)
  (ensures fun h0 _ h1 -> modifies (loc perm) h0 h1)

let l_step #n perm i result = 
  let xi, yi = getBranch result i in 
  let p0i, p1i = getBranch perm i in
  let branchIUpd = xi ^. p0i, yi ^. p1i in
  setBranch #n i branchIUpd perm

inline_for_extraction noextract
val l: #n: branch_len {v n % 2 == 0} -> b: branch n -> Stack unit 
  (requires fun h -> live h b)
  (ensures fun h0 _ h1 -> modifies (loc b) h0 h1)


let l #n b = 
  let h0 = ST.get() in 
  let leftBranch = sub b (size 0) n in 
  let rightBranch = sub b n n in 

  let ltx, lty = m #n b in 

  push_frame(); 
  let x0 = create (size 1) (u32 0) in 
  let y0 = create (size 1) (u32 0) in

  upd x0 (size 0) (index b (size 0)); 
  upd y0 (size 0) (index b (size 1));

  Lib.Loops.for 0ul ((n -! 2ul) >>. 1ul)
    (fun h i -> live h b /\ modifies (loc b) h0 h)
    (fun (i: size_t) ->
      assert(v i < v ( n  >>. 2ul)) ;
      admit(); 
      assume (v (i +. 1ul +. (n >>. 1ul)) < v n);
      let branch_j_nb = getBranch #n b (i +. 1ul +. (n >>. 1ul)) in 
	admit(); 
      let branch_j = getBranch #n b (i +. 1ul) in 
      let b0 = xor_3 branch_j_nb branch_j (lty, ltx) in
      setBranch #n i b0 b;
      setBranch #n (i +. 1ul +. (n >>. 1ul)) (getBranch #n b (i +. 1ul)) b);
  admit();
  
    let x0 = index x0 (size 0) in 
    let y0 = index y0 (size 0) in 
    let last0 = xor_3 (getBranch #n b (n >>. 1ul)) (x0, y0) (lty, ltx) in 
    setBranch #n ((n >>. 1ul) -. 1ul) last0 b;
    setBranch #n (n >>. 1ul) (x0, y0) b;
  pop_frame()

inline_for_extraction noextract
val add2: #n: branch_len {v n >= 4} -> i: size_t -> b:branch n -> Stack unit 
  (requires fun h -> live h b) 
  (ensures fun h0 _ h1 -> modifies (loc b) h0 h1)

let add2 #n i b = 

  recall_contents rcon (Lib.Sequence.of_list rcon_list); 

  let (x0, y0) = getBranch #n b (size 0) in 
  let (x1, y1) = getBranch #n b (size 1) in 

  let i0 = logand i (size 7) in 
    logand_mask i (size 7) 3; 
  let y0 = y0 ^. index rcon i0 in
  let y1 = y1 ^. (to_u32 i) in
 
  setBranch (size 0) (x0, y0) b;
  setBranch #n (size 1) (x1, y1) b

inline_for_extraction noextract
val toBranch: #n: branch_len -> i: lbuffer uint8 (size 8 *! n) -> o: branch n -> 
  Stack unit 
  (requires fun h -> live h i /\ live h o /\ disjoint i o)
  (ensures fun h0 _ h1 -> True)

let toBranch #n i o = 
  uints_from_bytes_le o i 

inline_for_extraction noextract
val fromBranch: #n: branch_len -> i: branch n -> o: lbuffer uint8 (size 8 *! n) -> 
  Stack unit 
  (requires fun h -> live h i /\ live h o /\ disjoint i o)
  (ensures fun h0 _ h1 -> True)

let fromBranch #n i o = 
  uints_to_bytes_le (2ul *! n) o i


val arx_n_step: #n: branch_len -> i: size_t {v i < v n / 2} -> b: branch n -> 
  Stack unit 
  (requires fun h -> live h b)
  (ensures fun h0 _ h1 -> True)

let arx_n_step #n i b = 
  let branchI = getBranch b i in  
    recall_contents rcon (Lib.Sequence.of_list rcon_list); 
  let rcon_i = index rcon i in 
  let x, y = arx rcon_i branchI in 
  setBranch i (x, y) b

inline_for_extraction noextract
val arx_n: #n: branch_len -> branch n -> 
  Stack unit 
  (requires fun h -> True)
  (ensures fun h0 _ h1 -> True)

let arx_n #n b =
  Lib.Loops.for 0ul n
  (fun h i -> live h b)
  (fun (i: size_t {v i < v n / 2}) -> arx_n_step i b)

inline_for_extraction noextract
val mainLoop_step: #n: branch_len {v n >= 4 /\ v n % 2 == 0 } ->  i: size_t -> branch n ->
  Stack unit 
  (requires fun h -> True)
  (ensures fun h0 _ h1 -> True)


let mainLoop_step #n i b = 
  add2 i b;
  arx_n #n b;
  l #n b

inline_for_extraction noextract
val mainLoop: #n: branch_len {v n >= 4 /\ v n % 2 == 0} -> b: branch n -> steps: size_t -> 
  Stack unit 
  (requires fun h -> True)
  (ensures fun h0 _ h1 -> True)

let mainLoop #n b steps = 
  Lib.Loops.for 0ul steps
  (fun h i -> live h b)
  (fun (i: size_t) -> mainLoop_step i b)


val sparkle256: steps: size_t -> i: lbuffer (uint8) (size 32) -> o: lbuffer (uint8) (size 32) ->
  Stack unit 
  (requires fun h -> live h i /\ live h o)
  (ensures fun h0 _ h1 -> True)

let sparkle256 steps i o =
  push_frame();
    let temp = create (size 12) (u32 0) in 
    toBranch #(size 4) i temp;
    mainLoop #(size 4) temp steps;
    fromBranch #(size 4) temp o; 
  pop_frame()
