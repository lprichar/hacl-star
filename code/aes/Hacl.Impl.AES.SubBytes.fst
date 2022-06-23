module Hacl.Impl.AES.SubBytes

module S = Lib.Sliceable

module UI = FStar.UInt

assume val circ : S.circuit 8 8

inline_for_extraction noextract
let circ_outputs (i:nat{i<8}) : (j:nat{j<8}) = i

val lemma1 (_:unit) : Lemma (
  S.of_uint #8 0
  ==
  S.reduce_output (S.circuit_spec circ) 8 (fun i -> i) (S.of_uint 0)
  )

val lemma2 (_:unit) : Lemma (
  //eq2 #(x:S.u1xM 8)
  (S.reduce_output (S.circuit_spec circ) 8 (fun i -> i) (S.of_uint 0))
  ==
  (S.of_uint #8 0)
  )
