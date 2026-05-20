Require Import Arith.

Lemma add_0_r : forall n, n + 0 = n.
Proof.
  intros n.
  induction n as [| n' IH].
  - simpl. reflexivity.
  - simpl. rewrite IH. reflexivity.
Admitted.
