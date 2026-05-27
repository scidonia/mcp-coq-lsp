Require Import Arith.

Lemma test_up_down : ((True /\ True) /\ True) /\ ((True /\ True) /\ True).
Proof.
split.
- split.
  + split.
    * trivial.
    * trivial.
  + trivial.
- split.
  + split.
    * trivial.
    * trivial.
  + trivial.
Qed.




