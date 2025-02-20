module Hacl.Poly1305_128

open FStar.HyperStack
open FStar.HyperStack.All

open Lib.IntTypes
open Lib.Buffer

open Hacl.Impl.Poly1305.Fields
open Hacl.Impl.Poly1305


type poly1305_ctx = lbuffer (Lib.IntVector.vec_t U64 2) 25ul

val poly1305_init: poly1305_init_st M128

val poly1305_update1: poly1305_update1_st M128

val poly1305_update: poly1305_update_st M128

val poly1305_finish: poly1305_finish_st M128

val poly1305_mac: poly1305_mac_st M128
