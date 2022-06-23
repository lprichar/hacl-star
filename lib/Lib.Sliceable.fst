module Lib.Sliceable

module UI = FStar.UInt
module Seq = Lib.Sequence
module B = Lib.Buffer
module IT = Lib.IntTypes


noeq type sig (n:IT.size_nat) =
{ t:Type0 }

val xNxM (#n:IT.size_nat) (xN:sig n) (m:IT.size_nat) : Type0
let xNxM xN m = (l:Seq.lseq xN.t m)

val index (#n:IT.size_nat) (#xN:sig n) (#m:IT.size_nat) (x:xNxM xN m) (i:nat{i<m}) : xN.t
let index #n #xN #m x i = Seq.index x i

assume val u1 : sig 1


let u1xM (m:IT.size_nat) : Type = xNxM u1 m

assume val u1xM_mk (m:IT.size_nat) (f:(i:nat{i<m} -> bool)) : u1xM m


assume val reduce_output
  (#m #m':IT.size_nat)
  (f:(#n:IT.size_nat -> #xN:sig n -> xNxM xN m -> xNxM xN m'))
  (m'':IT.size_nat) (r:(i:nat{i<m''} -> j:nat{j<m'}))
  : #n:IT.size_nat -> #xN:sig n -> xNxM xN m -> xNxM xN m''

assume type gate (m:nat) (c:nat)

inline_for_extraction noextract
type circuit (m p:nat) = (i:nat{i<p}) -> gate m i

assume val circuit_def (#m #m':IT.size_nat) (circ:circuit m m') (#n:IT.size_nat) (#xN:sig n) (x:xNxM xN m) (i:nat{i<m'}) : xN.t


assume val circuit_spec (#m #m':IT.size_nat) (circ:circuit m m') (#n:IT.size_nat) (#xN:sig n) (x:xNxM xN m) :
    (y:xNxM xN m'{forall (i:nat{i<m'}). index y i == circuit_def circ x i})


assume val of_uint (#m:IT.size_nat{m>0}) (p:UI.uint_t m) : (x:u1xM m{x == u1xM_mk _ (UI.nth p)})
