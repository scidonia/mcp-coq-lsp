From Stdlib Require Import Arith.

(* ((True /\ True) /\ True) /\ (True /\ True) *)
Lemma triple_conj : ((True /\ True) /\ True) /\ (True /\ True).
Proof.
split.
- split.
Admitted.

