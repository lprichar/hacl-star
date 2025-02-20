module EverCrypt.Hash

#set-options "--max_fuel 0 --max_ifuel 0 --z3rlimit 100"

open FStar.HyperStack.ST

module B = LowStar.Buffer
module IB = LowStar.ImmutableBuffer
module HS = FStar.HyperStack
module ST = FStar.HyperStack.ST

module AC = EverCrypt.AutoConfig2

open LowStar.BufferOps
open FStar.Integers
open C.Failure

module U64 = FStar.UInt64
module U32 = FStar.UInt32

// Allow *just* the alg type to be inverted, so that the entire module can run
// with ifuel 0
let _: squash (inversion alg) = allow_inversion alg

let string_of_alg =
  let open C.String in function
  | MD5 -> !$"MD5"
  | SHA1 -> !$"SHA1"
  | SHA2_224 -> !$"SHA2_224"
  | SHA2_256 -> !$"SHA2_256"
  | SHA2_384 -> !$"SHA2_384"
  | SHA2_512 -> !$"SHA2_512"
  | SHA3_256 -> !$"SHA3_256"
  | Blake2S -> !$"Blake2S"
  | Blake2B -> !$"Blake2B"

let uint32_p = B.buffer uint_32
let uint64_p = B.buffer uint_64

let is_valid_impl (i: impl) =
  let open Hacl.Impl.Blake2.Core in
  match i with
  | (| MD5, () |)
  | (| SHA1, () |)
  | (| SHA2_224, () |)
  | (| SHA2_256, () |)
  | (| SHA2_384, () |)
  | (| SHA2_512, () |)
  | (| SHA3_256, () |)
  | (| Blake2S, M32 |)
  | (| Blake2S, M128 |)
  | (| Blake2B, M32 |)
  | (| Blake2B, M256 |) -> true
  | _ -> false

let impl = i:impl { is_valid_impl i }

inline_for_extraction noextract
let md5: impl = (| MD5, () |)
inline_for_extraction noextract
let sha1: impl = (| SHA1, () |)
inline_for_extraction noextract
let sha2_224: impl = (| SHA2_224, () |)
inline_for_extraction noextract
let sha2_256: impl = (| SHA2_256, () |)
inline_for_extraction noextract
let sha2_384: impl = (| SHA2_384, () |)
inline_for_extraction noextract
let sha2_512: impl = (| SHA2_512, () |)
inline_for_extraction noextract
let sha3_256: impl = (| SHA3_256, () |)
inline_for_extraction noextract
let blake2s_32: impl = (| Blake2S, Hacl.Impl.Blake2.Core.M32 |)
inline_for_extraction noextract
let blake2s_128: impl = (| Blake2S, Hacl.Impl.Blake2.Core.M128 |)
inline_for_extraction noextract
let blake2b_32: impl = (| Blake2B, Hacl.Impl.Blake2.Core.M32 |)
inline_for_extraction noextract
let blake2b_256: impl = (| Blake2B, Hacl.Impl.Blake2.Core.M256 |)

inline_for_extraction noextract
let alg_of_impl (i: impl): alg = dfst i

// JP: This is a slightly more complicated case than for AEAD... for AEAD,
//   `state_s a = i & kv a & buffer uint8`
// because no matter the /implementation/, the resulting C type for the key is
// always a pointer to bytes. Here, that's no longer true because of Blake2, so
// we need to be a little more verbose.
noeq
type state_s: alg -> Type0 =
| MD5_s: p:Hacl.Hash.Definitions.state (|MD5, ()|) -> state_s MD5
| SHA1_s: p:Hacl.Hash.Definitions.state (|SHA1, ()|) -> state_s SHA1
| SHA2_224_s: p:Hacl.Hash.Definitions.state (|SHA2_224, ()|) -> state_s SHA2_224
| SHA2_256_s: p:Hacl.Hash.Definitions.state (|SHA2_256, ()|) -> state_s SHA2_256
| SHA2_384_s: p:Hacl.Hash.Definitions.state (|SHA2_384, ()|) -> state_s SHA2_384
| SHA2_512_s: p:Hacl.Hash.Definitions.state (|SHA2_512, ()|) -> state_s SHA2_512
| SHA3_256_s: p:Hacl.Hash.Definitions.state (|SHA3_256, ()|) -> state_s SHA3_256
| Blake2S_s: p:Hacl.Hash.Definitions.state (|Blake2S, Hacl.Impl.Blake2.Core.M32|) -> state_s Blake2S
| Blake2S_128_s:
  _:squash (EverCrypt.TargetConfig.hacl_can_compile_vec128 /\
    EverCrypt.AutoConfig2.vec128_enabled) ->
  p:Hacl.Hash.Definitions.state (|Blake2S, Hacl.Impl.Blake2.Core.M128|) ->
  state_s Blake2S
| Blake2B_s: p:Hacl.Hash.Definitions.state (|Blake2B, Hacl.Impl.Blake2.Core.M32|) -> state_s Blake2B
| Blake2B_256_s:
  _:squash (EverCrypt.TargetConfig.hacl_can_compile_vec256 /\
    EverCrypt.AutoConfig2.vec256_enabled) ->
  p:Hacl.Hash.Definitions.state (|Blake2B, Hacl.Impl.Blake2.Core.M256|) -> state_s Blake2B

let invert_state_s (a: alg): Lemma
  (requires True)
  (ensures (inversion (state_s a)))
  [ SMTPat (state_s a) ]
=
  allow_inversion (state_s a)

inline_for_extraction
let impl_of_state #a (s: state_s a): i:impl { alg_of_impl i == a } =
  match s with
  | MD5_s _ -> md5
  | SHA1_s _ -> sha1
  | SHA2_224_s _ -> sha2_224
  | SHA2_256_s _ -> sha2_256
  | SHA2_384_s _ -> sha2_384
  | SHA2_512_s _ -> sha2_512
  | SHA3_256_s _ -> sha3_256
  | Blake2S_s _ -> blake2s_32
  | Blake2S_128_s _ _ -> blake2s_128
  | Blake2B_s _ -> blake2b_32
  | Blake2B_256_s _ _ -> blake2b_256

// In state_s, the data type already captures what implementation we have... three
// design choices here:
// - turn state_s into a dependent pair of G.erased impl & (SHA2_s | SHA3_s |
//   ...) so as not to repeat redundant information at run-time
// - hope that we can get away with returning dependent pairs only when needed.
// We're going for a third one in this module, which is more lightweight.
inline_for_extraction
let p #a (s: state_s a): Hacl.Hash.Definitions.state (impl_of_state s) =
  match s with
  | MD5_s p -> p
  | SHA1_s p -> p
  | SHA2_224_s p -> p
  | SHA2_256_s p -> p
  | SHA2_384_s p -> p
  | SHA2_512_s p -> p
  | SHA3_256_s p -> p
  | Blake2S_s p -> p
  | Blake2S_128_s _ p -> p
  | Blake2B_s p -> p
  | Blake2B_256_s _ p -> p

let freeable_s #a s = B.freeable (p #a s)

let footprint_s #a (s: state_s a) =
  B.loc_addr_of_buffer (p s)

let invariant_s #a (s: state_s a) h =
  B.live h (p s)

let repr #a s h: GTot _ =
  let s = B.get h s 0 in
  as_seq h (p s)

let alg_of_state a s =
  let open LowStar.BufferOps in
  match !*s with
  | MD5_s _ -> MD5
  | SHA1_s _ -> SHA1
  | SHA2_224_s _ -> SHA2_224
  | SHA2_256_s _ -> SHA2_256
  | SHA2_384_s _ -> SHA2_384
  | SHA2_512_s _ -> SHA2_512
  | SHA3_256_s _ -> SHA3_256
  | Blake2S_s _ -> Blake2S
  | Blake2S_128_s _ _ -> Blake2S
  | Blake2B_s _ -> Blake2B
  | Blake2B_256_s _ _ -> Blake2B

let repr_eq (#a:alg) (r1 r2: Spec.Hash.Definitions.words_state' a) =
  Seq.equal r1 r2

let fresh_is_disjoint l1 l2 h0 h1 = ()

let invariant_loc_in_footprint #a s m = ()

let frame_invariant #a l s h0 h1 =
  let state = B.deref h0 s in
  assert (repr_eq (repr s h0) (repr s h1))

inline_for_extraction noextract
let alloca a =
  let s: state_s a =
    match a with
    | MD5 -> MD5_s (B.alloca 0ul 4ul)
    | SHA1 -> SHA1_s (B.alloca 0ul 5ul)
    | SHA2_224 -> SHA2_224_s (B.alloca 0ul 8ul)
    | SHA2_256 -> SHA2_256_s (B.alloca 0ul 8ul)
    | SHA2_384 -> SHA2_384_s (B.alloca 0UL 8ul)
    | SHA2_512 -> SHA2_512_s (B.alloca 0UL 8ul)
    | SHA3_256 -> SHA3_256_s (B.alloca 0UL 25ul)
    | Blake2S ->
        let vec128 = EverCrypt.AutoConfig2.has_vec128 () in
        if EverCrypt.TargetConfig.hacl_can_compile_vec128 then
          if vec128 then
            let open Hacl.Impl.Blake2.Core in
            [@inline_let] let i: impl = (| Blake2S , M128 |) in
            Blake2S_128_s () (B.alloca (zero_element Spec.Blake2.Blake2S M128) (impl_state_len i))
          else
            Blake2S_s (B.alloca 0ul 16ul)
        else
          Blake2S_s (B.alloca 0ul 16ul)
    | Blake2B ->
        let vec256 = EverCrypt.AutoConfig2.has_vec256 () in
        if EverCrypt.TargetConfig.hacl_can_compile_vec256 then
          if vec256 then
            let open Hacl.Impl.Blake2.Core in
            [@inline_let] let i: impl = (| Blake2B , M256 |) in
            Blake2B_256_s () (B.alloca (zero_element Spec.Blake2.Blake2B M256) (impl_state_len i))
          else
            Blake2B_s (B.alloca 0uL 16ul)
        else
          Blake2B_s (B.alloca 0uL 16ul)
  in
  B.alloca s 1ul

let create_in a r =
  let h0 = ST.get () in
  let s: state_s a =
    match a with
    | MD5 -> MD5_s (B.malloc r 0ul 4ul)
    | SHA1 -> SHA1_s (B.malloc r 0ul 5ul)
    | SHA2_224 -> SHA2_224_s (B.malloc r 0ul 8ul)
    | SHA2_256 -> SHA2_256_s (B.malloc r 0ul 8ul)
    | SHA2_384 -> SHA2_384_s (B.malloc r 0UL 8ul)
    | SHA2_512 -> SHA2_512_s (B.malloc r 0UL 8ul)
    | SHA3_256 -> SHA3_256_s (B.malloc r 0UL 25ul)
    | Blake2S ->
        let vec128 = EverCrypt.AutoConfig2.has_vec128 () in
        if EverCrypt.TargetConfig.hacl_can_compile_vec128 then
          // Slightly frustrating duplication of the else-branch because we
          // can't compile this using the if-and return optimization of krml.
          if vec128 then
            Blake2S_128_s () (Hacl.Hash.Blake2s_128.malloc_blake2s_128 r)
          else
            Blake2S_s (B.malloc r 0ul 16ul)
        else
          Blake2S_s (B.malloc r 0ul 16ul)
    | Blake2B ->
        let vec256 = EverCrypt.AutoConfig2.has_vec256 () in
        if EverCrypt.TargetConfig.hacl_can_compile_vec256 then
          if vec256 then
            Blake2B_256_s () (Hacl.Hash.Blake2b_256.malloc_blake2b_256 r)
          else
            Blake2B_s (B.malloc r 0uL 16ul)
        else
          Blake2B_s (B.malloc r 0uL 16ul)
  in
  B.malloc r s 1ul

let create a =
  create_in a HS.root

#push-options "--ifuel 1"

// NOTE: HACL* does not require suitable preconditions so the squashed proofs
// that we have the right CPU flags are useless. But it's good to demonstrate
// how to do it for future reference and/or future other implementations.
let init #a s =
  match !*s with
  | MD5_s p -> Hacl.Hash.MD5.legacy_init p
  | SHA1_s p -> Hacl.Hash.SHA1.legacy_init p
  | SHA2_224_s p -> Hacl.Hash.SHA2.init_224 p
  | SHA2_256_s p -> Hacl.Hash.SHA2.init_256 p
  | SHA2_384_s p -> Hacl.Hash.SHA2.init_384 p
  | SHA2_512_s p -> Hacl.Hash.SHA2.init_512 p
  | SHA3_256_s p -> Hacl.Hash.SHA3.init_256 p
  | Blake2S_s p -> let _ = Hacl.Hash.Blake2.init_blake2s_32 p in ()
  | Blake2S_128_s _ p ->
      if EverCrypt.TargetConfig.hacl_can_compile_vec128 then
        let _ = Hacl.Hash.Blake2s_128.init_blake2s_128 p in ()
  | Blake2B_s p -> let _ = Hacl.Hash.Blake2.init_blake2b_32 p in ()
  | Blake2B_256_s _ p ->
      if EverCrypt.TargetConfig.hacl_can_compile_vec256 then
        let _ = Hacl.Hash.Blake2b_256.init_blake2b_256 p in ()
#pop-options

friend Vale.SHA.SHA_helpers

// Avoid a cross-compilation unit symbol visibility... duplicate locally.
let k224_256 =
  LowStar.ImmutableBuffer.igcmalloc_of_list HS.root Spec.SHA2.Constants.k224_256_l

#push-options "--ifuel 1"

// A new switch between HACL and Vale; can be used in place of Hacl.Hash.SHA2.update_256
// NOTE: this is an old-style switch where the CPU check is done on every call
// to update_multi... this is SUBOPTIMAL. I (JP) ported this module to use a
// proper concept of /implementation/, and for the Blake2 optimized variants,
// the state is now capable of keeping a squashed proof that the CPU supports
// what is needed...
// TODO: introduce SHA2_256_Vale in the state and test for CPU instructions only
// once, at state-creation time!
let update_multi_256 s ev blocks n =
  let has_shaext = AC.has_shaext () in
  let has_sse = AC.has_sse () in
  if EverCrypt.TargetConfig.hacl_can_compile_vale && (has_shaext && has_sse) then begin
    let n = Int.Cast.Full.uint32_to_uint64 n in
    B.recall k224_256;
    IB.recall_contents k224_256 Spec.SHA2.Constants.k224_256;
    let h1 = ST.get () in
    IB.buffer_immutable_buffer_disjoint s k224_256 h1;
    let h2 = ST.get () in
    IB.buffer_immutable_buffer_disjoint blocks k224_256 h2;
    Vale.Wrapper.X64.Sha.sha256_update s blocks n k224_256
  end else
    Hacl.Hash.SHA2.update_multi_256 s () blocks n

#pop-options

inline_for_extraction noextract
let update_multi_224 s ev blocks n =
  assert_norm (words_state SHA2_224 == words_state SHA2_256);
  let h0 = ST.get () in
  Spec.SHA2.Lemmas.update_multi_224_256 (B.as_seq h0 s, ()) (B.as_seq h0 blocks);
  update_multi_256 s ev blocks n

// Need to unroll the definition of update_multi once to prove that it's update
#push-options "--fuel 1 --ifuel 1"
let update2 #a s prevlen block =
  match !*s with
  | MD5_s p -> Hacl.Hash.MD5.legacy_update p () block
  | SHA1_s p -> Hacl.Hash.SHA1.legacy_update p () block
  | SHA2_224_s p -> update_multi_224 p () block 1ul
  | SHA2_256_s p -> update_multi_256 p () block 1ul
  | SHA2_384_s p -> Hacl.Hash.SHA2.update_384 p () block
  | SHA2_512_s p -> Hacl.Hash.SHA2.update_512 p () block
  | SHA3_256_s p -> Hacl.Hash.SHA3.update_256 p () block
  | Blake2S_s p ->
      let _ = Hacl.Hash.Blake2.update_blake2s_32 p prevlen block in
      ()
  | Blake2S_128_s _ p ->
      if EverCrypt.TargetConfig.hacl_can_compile_vec128 then
        let _ = Hacl.Hash.Blake2s_128.update_blake2s_128 p prevlen block in
        ()
  | Blake2B_s p ->
      [@inline_let] let prevlen = Int.Cast.Full.uint64_to_uint128 prevlen in
      let _ = Hacl.Hash.Blake2.update_blake2b_32 p prevlen block in
      ()
  | Blake2B_256_s _ p ->
      if EverCrypt.TargetConfig.hacl_can_compile_vec256 then
        [@inline_let] let prevlen = Int.Cast.Full.uint64_to_uint128 prevlen in
        let _ = Hacl.Hash.Blake2b_256.update_blake2b_256 p prevlen block in
        ()
#pop-options

// The deprecated update just calls the new update
let update #a s block =
  update2 #a s 0UL block

#push-options "--ifuel 1"

let update_multi2 #a s prevlen blocks len =
  match !*s with
  | MD5_s p ->
      let n = len / block_len MD5 in
      Hacl.Hash.MD5.legacy_update_multi p () blocks n
  | SHA1_s p ->
      let n = len / block_len SHA1 in
      Hacl.Hash.SHA1.legacy_update_multi p () blocks n
  | SHA2_224_s p ->
      let n = len / block_len SHA2_224 in
      update_multi_224 p () blocks n
  | SHA2_256_s p ->
      let n = len / block_len SHA2_256 in
      update_multi_256 p () blocks n
  | SHA2_384_s p ->
      let n = len / block_len SHA2_384 in
      Hacl.Hash.SHA2.update_multi_384 p () blocks n
  | SHA2_512_s p ->
      let n = len / block_len SHA2_512 in
      Hacl.Hash.SHA2.update_multi_512 p () blocks n
  | SHA3_256_s p ->
      let n = len / block_len SHA3_256 in
      Hacl.Hash.SHA3.update_multi_256 p () blocks n
  | Blake2S_s p ->
      let n = len / block_len Blake2S in
      let _ = Hacl.Hash.Blake2.update_multi_blake2s_32 p prevlen blocks n in
      ()
  | Blake2S_128_s _ p ->
      if EverCrypt.TargetConfig.hacl_can_compile_vec128 then
        let n = len / block_len Blake2S in
        let _ = Hacl.Hash.Blake2s_128.update_multi_blake2s_128 p prevlen blocks n in
        ()
  | Blake2B_s p ->
      [@inline_let] let prevlen = Int.Cast.Full.uint64_to_uint128 prevlen in
      let n = len / block_len Blake2B in
      let _ = Hacl.Hash.Blake2.update_multi_blake2b_32 p prevlen blocks n in
      ()
  | Blake2B_256_s _ p ->
      if EverCrypt.TargetConfig.hacl_can_compile_vec256 then
        [@inline_let] let prevlen = Int.Cast.Full.uint64_to_uint128 prevlen in
        let n = len / block_len Blake2B in
        let _ = Hacl.Hash.Blake2b_256.update_multi_blake2b_256 p prevlen blocks n in
        ()

#pop-options

// The deprecated update_multi just calls the new update_multi
let update_multi #a s blocks len =
  update_multi2 #a s 0UL blocks len

// Re-using the higher-order stateful combinator to get an instance of
// update_last that is capable of calling Vale under the hood
let update_last_256 s prev_len input input_len =
  Hacl.Hash.MD.mk_update_last SHA2_256 update_multi_256 Hacl.Hash.SHA2.pad_256 s prev_len input input_len

let update_last_224 s prev_len input input_len =
  assert_norm (words_state SHA2_224 == words_state SHA2_256);
  [@inline_let]
  let l x y:
    Lemma
      (ensures (Spec.Agile.Hash.update_multi SHA2_224 x y == Spec.Agile.Hash.update_multi SHA2_256 x y))
    [ SMTPat (Spec.Agile.Hash.update_multi SHA2_224 x y); SMTPat (Spec.Agile.Hash.update_multi SHA2_256 x y) ]
  =
    Spec.SHA2.Lemmas.update_multi_224_256 x y
  in
  update_last_256 s prev_len input input_len

// Splitting out these proof bits; the proof is highly unreliable when all six
// cases are done together in a single match
inline_for_extraction
let update_last_st (#i:G.erased impl) =
  let i = Ghost.reveal i in
  let a = alg_of_impl i in
  p:Hacl.Hash.Definitions.state i ->
  ev:extra_state a ->
  prev_len:uint64_t ->
  last:uint8_p { B.length last <= block_length a } ->
  last_len:uint32_t {
    v last_len = B.length last /\
    (v prev_len + v last_len) `less_than_max_input_length` a /\
    v prev_len % block_length a = 0 /\
    (extra_state_v ev + B.length last) `less_than_max_input_length` a
    } ->
  Stack (extra_state a)
  (requires fun h0 ->
    B.live h0 p /\
    B.live h0 last /\
    B.(loc_disjoint (loc_buffer p) (loc_buffer last)))
  (ensures fun h0 ev' h1 ->
    B.(modifies (loc_buffer p) h0 h1) /\
    (Hacl.Hash.Definitions.as_seq h1 p, ev') ==
      Spec.Hash.Incremental.update_last a (Hacl.Hash.Definitions.as_seq h0 p, ev)
                                        (v prev_len) (B.as_seq h0 last))

inline_for_extraction
val update_last_64 (i: G.erased impl{ G.reveal i <> sha2_384 /\
                                      G.reveal i <> sha2_512 /\
                                      G.reveal i <> blake2b_32 /\
                                      G.reveal i <> blake2b_256 /\ not (is_sha3 (dfst i)) })
  (update_last: Hacl.Hash.Definitions.update_last_st i):
  update_last_st #i

inline_for_extraction
let update_last_64 i update_last p ev prev_len last last_len =
  update_last p ev prev_len last last_len

inline_for_extraction
val update_last_128 (i: G.erased impl{ G.reveal i = sha2_384 \/
                                       G.reveal i = sha2_512 \/
                                       G.reveal i = blake2b_32 \/
                                       G.reveal i = blake2b_256})
  (update_last: Hacl.Hash.Definitions.update_last_st i):
  update_last_st #i

inline_for_extraction
let update_last_128 i update_last p ev prev_len last last_len =
  [@inline_let] let prev_len : UInt128.t = Int.Cast.Full.uint64_to_uint128 prev_len in
  update_last p ev prev_len last last_len

let state_s_to_words_state (#i:impl) (s:Hacl.Hash.Definitions.state i)
  (h:HS.mem) (counter:uint64_t) :
  GTot (words_state (alg_of_impl i)) =
  let a = alg_of_impl i in
  if is_blake a then
    let ev : extra_state a = Lib.IntTypes.cast (extra_state_int_type a) Lib.IntTypes.SEC counter in
    as_seq h s, ev
  else (as_seq h s, ())

/// Before defining ``update_last`` we introduce auxiliary functions for Blake2S
/// and Blake2B, because trying to define it completely at once leads to a proof loop.
/// Besides, even with this the Blake functions tend to loop.
inline_for_extraction noextract
let update_last_with_internal_st (i : impl) =
  let a = alg_of_impl i in (
  p:Hacl.Hash.Definitions.state i ->
  prev_len:uint64_t ->
  last:B.buffer Lib.IntTypes.uint8 { B.length last <= block_length a } ->
  last_len:uint32_t {
    v last_len = B.length last /\
    (v prev_len + v last_len) `less_than_max_input_length` a /\
    v prev_len % block_length a = 0
    } ->
  Stack unit
  (requires fun h0 ->
    B.live h0 p /\
    B.live h0 last /\
    B.(loc_disjoint (loc_addr_of_buffer p) (loc_buffer last)))
  (ensures fun h0 _ h1 ->
    B.live h1 p /\
    as_seq h1 p ==
      fst (Spec.Hash.Incremental.update_last a (state_s_to_words_state p h0 prev_len) (v prev_len)
                                             (B.as_seq h0 last)) /\
    B.(modifies (B.loc_addr_of_buffer p) h0 h1)))


inline_for_extraction noextract
val update_last_blake2s_32 : update_last_with_internal_st blake2s_32

#push-options "--fuel 0 --ifuel 1"
let update_last_blake2s_32 p prev_len last last_len =
  [@inline_let] let ev = prev_len in
  let x:Lib.IntTypes.uint_t Lib.IntTypes.U64 Lib.IntTypes.SEC =
    update_last_64 blake2s_32 Hacl.Hash.Blake2.update_last_blake2s_32 p ev
                   prev_len last last_len in
  ()
#pop-options

inline_for_extraction noextract
val update_last_blake2s_128 : update_last_with_internal_st blake2s_128

#push-options "--fuel 0 --ifuel 1"
let update_last_blake2s_128 p prev_len last last_len =
  [@inline_let] let ev = prev_len in
  let x:Lib.IntTypes.uint_t Lib.IntTypes.U64 Lib.IntTypes.SEC =
    update_last_64 blake2s_128 Hacl.Hash.Blake2s_128.update_last_blake2s_128 p ev
                   prev_len last last_len in
  ()
#pop-options

inline_for_extraction noextract
val update_last_blake2b_32 : update_last_with_internal_st blake2b_32

let update_last_blake2b_32 p prev_len last last_len =
  [@inline_let] let ev = Int.Cast.Full.uint64_to_uint128 prev_len in
  let x:Lib.IntTypes.uint_t Lib.IntTypes.U128 Lib.IntTypes.SEC =
    update_last_128 blake2b_32 Hacl.Hash.Blake2.update_last_blake2b_32 p ev
                    prev_len last last_len in
  ()

inline_for_extraction noextract
val update_last_blake2b_256 : update_last_with_internal_st blake2b_256

let update_last_blake2b_256 p prev_len last last_len =
  [@inline_let] let ev = Int.Cast.Full.uint64_to_uint128 prev_len in
  let x:Lib.IntTypes.uint_t Lib.IntTypes.U128 Lib.IntTypes.SEC =
    update_last_128 blake2b_256 Hacl.Hash.Blake2b_256.update_last_blake2b_256 p ev
                    prev_len last last_len in
  ()

let update_last2 #a s prev_len last last_len =
  match !*s with
  | MD5_s p ->
      update_last_64 md5 Hacl.Hash.MD5.legacy_update_last p () prev_len last last_len
  | SHA1_s p ->
      update_last_64 sha1 Hacl.Hash.SHA1.legacy_update_last p () prev_len last last_len
  | SHA2_224_s p ->
      update_last_64 sha2_224 update_last_224 p () prev_len last last_len
  | SHA2_256_s p ->
      update_last_64 sha2_256 update_last_256 p () prev_len last last_len
  | SHA2_384_s p ->
      update_last_128 sha2_384 Hacl.Hash.SHA2.update_last_384 p () prev_len last last_len
  | SHA2_512_s p ->
      update_last_128 sha2_512 Hacl.Hash.SHA2.update_last_512 p () prev_len last last_len
  | SHA3_256_s p ->
      Hacl.Hash.SHA3.update_last_256 p () () last last_len
  | Blake2S_s p ->
      update_last_blake2s_32 p prev_len last last_len
  | Blake2S_128_s _ p ->
      if EverCrypt.TargetConfig.hacl_can_compile_vec128 then
        update_last_blake2s_128 p prev_len last last_len
  | Blake2B_s p ->
      update_last_blake2b_32 p prev_len last last_len
  | Blake2B_256_s _ p ->
      if EverCrypt.TargetConfig.hacl_can_compile_vec256 then
        update_last_blake2b_256 p prev_len last last_len

// TODO: move to FStar.Math.Lemmas
val modulo_sub_lemma (a : int) (b : nat) (c : pos) :
  Lemma
  (requires (b < c /\ (a - b) % c = 0))
  (ensures (b = a % c))
let modulo_sub_lemma a b c =
  calc(==) {
    (a - b) % c;
  (==) { Math.Lemmas.lemma_mod_add_distr (-b) a c }
    ((a % c) - b) % c;
  };
  assert(- c < (a % c) - b);
  assert((a % c) - b < c);
  Math.Lemmas.euclidean_division_definition ((a % c) - b) c;
  assert(a % c - b = ((a % c - b) / c) * c);
  assert(1 * c = c);
  assert((-1) * c = - c);
  let d = (a % c - b) / c in
  if 1 <= d then
    begin
    Math.Lemmas.lemma_mult_le_right c 1 d;
    assert(d * c >= 1 * c);
    assert(False)
    end;
  if d <= -1 then
    begin
    Math.Lemmas.lemma_mult_le_right c d (-1);
    assert(d * c <= (-1) * c);
    assert(d * c <= - c);
    assert(False)
    end;
  assert(d = 0);
  assert(d * c = 0);
  assert(a % c - b = 0);
  assert(a % c = b)

// The deprecated update_last just calls the new update_last.
// This one is a bit trickier than the others because we need to recompute
// the length of the data seen so far.
#push-options "--z3rlimit 800"
let update_last #ga s last total_len =
  let a = alg_of_state ga s in
  (**) assert_norm(v (block_len a) > 0);
  let last_len = U64.(total_len %^ Int.Cast.uint32_to_uint64 (block_len a)) in
  (**) Math.Lemmas.euclidean_division_definition (U64.v total_len) (block_length a);
  (**) Math.Lemmas.nat_over_pos_is_nat (U64.v total_len) (block_length a);
  (**) Math.Lemmas.nat_times_nat_is_nat (U64.v total_len / block_length a) (block_length a);
  (**) Math.Lemmas.modulo_range_lemma (U64.v total_len) (block_length a);
  (**) assert(U64.v last_len = U64.v total_len % block_length a);
  (**) assert(UInt64.v last_len <= UInt64.v total_len);
  let prev_len = U64.(total_len -^ last_len) in
  (**) assert(block_length a < pow2 32);
  (**) Math.Lemmas.modulo_lemma (U64.v last_len) (pow2 32);
  (**) assert(U64.v last_len = U32.v (Int.Cast.uint64_to_uint32 last_len));
  [@inline_let]
  let last_len = Int.Cast.uint64_to_uint32 last_len in
  (**) assert(U32.v last_len < Spec.Hash.Definitions.block_length a);
  (**) assert((v prev_len + v last_len) `less_than_max_input_length` a);
  (**) assert(v prev_len = v total_len - v last_len);
  (**) Math.Lemmas.cancel_mul_mod (v total_len / block_length a) (block_length a);
  (**) assert(v prev_len % block_length a = 0);
  (**) let h0 = ST.get () in
  (**) modulo_sub_lemma (v total_len) (B.length last) (block_length a);
  (**) assert(v last_len = B.length last);
  update_last2 #ga s prev_len last last_len;
  (**) let h1 = ST.get () in
  // The following assertions need non-linear arithmetic.
  // Note that for now, the proof is stable as it is.
  (**) assert(
  (**)   (B.length last + Seq.length (Spec.Hash.PadFinish.pad a (v total_len)))
  (**)     % block_length a = 0);
  (**) assert(
  (**)   repr s h1 ==
  (**)   fst (Spec.Agile.Hash.update_multi a (repr s h0, ())
  (**)         (Seq.append (B.as_seq h0 last) (Spec.Hash.PadFinish.pad a (v total_len)))))
#pop-options

#push-options "--ifuel 1"

let finish #a s dst =
  match !*s with
  | MD5_s p -> Hacl.Hash.MD5.legacy_finish p () dst
  | SHA1_s p -> Hacl.Hash.SHA1.legacy_finish p () dst
  | SHA2_224_s p -> Hacl.Hash.SHA2.finish_224 p () dst
  | SHA2_256_s p -> Hacl.Hash.SHA2.finish_256 p () dst
  | SHA2_384_s p -> Hacl.Hash.SHA2.finish_384 p () dst
  | SHA2_512_s p -> Hacl.Hash.SHA2.finish_512 p () dst
  | SHA3_256_s p -> Hacl.Hash.SHA3.finish_256 p () dst
  | Blake2S_s p -> Hacl.Hash.Blake2.finish_blake2s_32 p 0UL dst
  | Blake2S_128_s _ p ->
      if EverCrypt.TargetConfig.hacl_can_compile_vec128 then
        Hacl.Hash.Blake2s_128.finish_blake2s_128 p 0UL dst
  | Blake2B_s p ->
      Hacl.Hash.Blake2.finish_blake2b_32 p
        (Int.Cast.Full.uint64_to_uint128 (UInt64.uint_to_t 0)) dst
  | Blake2B_256_s _ p ->
      if EverCrypt.TargetConfig.hacl_can_compile_vec256 then
        Hacl.Hash.Blake2b_256.finish_blake2b_256 p
          (Int.Cast.Full.uint64_to_uint128 (UInt64.uint_to_t 0)) dst

#pop-options

let free #ea s =
  begin match !*s with
  | MD5_s p -> B.free p
  | SHA1_s p -> B.free p
  | SHA2_224_s p -> B.free p
  | SHA2_256_s p -> B.free p
  | SHA2_384_s p -> B.free p
  | SHA2_512_s p -> B.free p
  | SHA3_256_s p -> B.free p
  | Blake2S_s p -> B.free p
  | Blake2S_128_s _ p -> B.free p
  | Blake2B_s p -> B.free p
  | Blake2B_256_s _ p -> B.free p
  end;
  B.free s

#push-options "--ifuel 1"

let copy #a s_src s_dst =
  match !*s_src with
  | MD5_s p_src ->
      [@inline_let]
      let s_dst: state MD5 = s_dst in
      let p_dst = MD5_s?.p !*s_dst in
      B.blit p_src 0ul p_dst 0ul 4ul
  | SHA1_s p_src ->
      [@inline_let]
      let s_dst: state SHA1 = s_dst in
      let p_dst = SHA1_s?.p !*s_dst in
      B.blit p_src 0ul p_dst 0ul 5ul
  | SHA2_224_s p_src ->
      [@inline_let]
      let s_dst: state SHA2_224 = s_dst in
      let p_dst = SHA2_224_s?.p !*s_dst in
      B.blit p_src 0ul p_dst 0ul 8ul
  | SHA2_256_s p_src ->
      [@inline_let]
      let s_dst: state SHA2_256 = s_dst in
      let p_dst = SHA2_256_s?.p !*s_dst in
      B.blit p_src 0ul p_dst 0ul 8ul
  | SHA2_384_s p_src ->
      [@inline_let]
      let s_dst: state SHA2_384 = s_dst in
      let p_dst = SHA2_384_s?.p !*s_dst in
      B.blit p_src 0ul p_dst 0ul 8ul
  | SHA2_512_s p_src ->
      [@inline_let]
      let s_dst: state SHA2_512 = s_dst in
      let p_dst = SHA2_512_s?.p !*s_dst in
      B.blit p_src 0ul p_dst 0ul 8ul
  | SHA3_256_s p_src ->
      [@inline_let]
      let s_dst: state SHA3_256 = s_dst in
      let p_dst = SHA3_256_s?.p !*s_dst in
      B.blit p_src 0ul p_dst 0ul 25ul
  | Blake2S_s p_src ->
      begin match !*s_dst with
      | Blake2S_s p_dst ->
          [@inline_let]
          let s_dst: state Blake2S = s_dst in
          B.blit p_src 0ul p_dst 0ul 16ul
      | Blake2S_128_s _ p_dst ->
          if EverCrypt.TargetConfig.hacl_can_compile_vec128 then
            [@inline_let]
            let s_dst: state Blake2S = s_dst in
            Hacl.Blake2s_128.load_state128s_from_state32 p_dst p_src
      end
  | Blake2B_s p_src ->
      begin match !*s_dst with
      | Blake2B_s p_dst ->
          [@inline_let]
          let s_dst: state Blake2B = s_dst in
          B.blit p_src 0ul p_dst 0ul 16ul
      | Blake2B_256_s _ p_dst ->
          if EverCrypt.TargetConfig.hacl_can_compile_vec256 then
            [@inline_let]
            let s_dst: state Blake2B = s_dst in
            Hacl.Blake2b_256.load_state256b_from_state32 p_dst p_src
      end
  | Blake2S_128_s _ p_src ->
      begin match !*s_dst with
      | Blake2S_128_s _ p_dst ->
          [@inline_let]
          let s_dst: state Blake2S = s_dst in
          B.blit p_src 0ul p_dst 0ul 4ul
      | Blake2S_s p_dst ->
          if EverCrypt.TargetConfig.hacl_can_compile_vec128 then
            [@inline_let]
            let s_dst: state Blake2S = s_dst in
            Hacl.Blake2s_128.store_state128s_to_state32 p_dst p_src
      end
  | Blake2B_256_s _ p_src ->
      begin match !*s_dst with
      | Blake2B_256_s _ p_dst ->
          [@inline_let]
          let s_dst: state Blake2B = s_dst in
          B.blit p_src 0ul p_dst 0ul 4ul
      | Blake2B_s p_dst ->
          if EverCrypt.TargetConfig.hacl_can_compile_vec256 then
            [@inline_let]
            let s_dst: state Blake2B = s_dst in
            Hacl.Blake2b_256.store_state256b_to_state32 p_dst p_src
      end

#pop-options

// A full one-shot hash that relies on vale at each multiplexing point
let hash_256 input input_len dst =
  Hacl.Hash.MD.mk_hash SHA2_256 Hacl.Hash.SHA2.alloca_256 update_multi_256
    update_last_256 Hacl.Hash.SHA2.finish_256 input input_len dst

let hash_224 input input_len dst =
  Hacl.Hash.MD.mk_hash SHA2_224 Hacl.Hash.SHA2.alloca_224 update_multi_224
    update_last_224 Hacl.Hash.SHA2.finish_224 input input_len dst

let hash a dst input len =
  match a with
  | MD5 -> Hacl.Hash.MD5.legacy_hash input len dst
  | SHA1 -> Hacl.Hash.SHA1.legacy_hash input len dst
  | SHA2_224 -> hash_224 input len dst
  | SHA2_256 -> hash_256 input len dst
  | SHA2_384 -> Hacl.Hash.SHA2.hash_384 input len dst
  | SHA2_512 -> Hacl.Hash.SHA2.hash_512 input len dst
  | SHA3_256 -> Hacl.SHA3.sha3_256 len input dst
  | Blake2S ->
      let vec128 = EverCrypt.AutoConfig2.has_vec128 () in
      if EverCrypt.TargetConfig.hacl_can_compile_vec128 && vec128 then
        Hacl.Hash.Blake2s_128.hash_blake2s_128 input len dst
      else
        Hacl.Hash.Blake2.hash_blake2s_32 input len dst
  | Blake2B ->
      let vec256 = EverCrypt.AutoConfig2.has_vec256 () in
      if EverCrypt.TargetConfig.hacl_can_compile_vec256 && vec256 then
        Hacl.Hash.Blake2b_256.hash_blake2b_256 input len dst
      else
        Hacl.Hash.Blake2.hash_blake2b_32 input len dst
