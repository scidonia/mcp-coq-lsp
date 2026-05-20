Require Import Arith.

Lemma add_comm : forall n m, n + m = m + n.
Proof.
  induction n; intros m; simpl; auto.
  induction n; intros m; simpl; auto.
  intros n m.
  intros n m.
  induction n.
Admitted.



