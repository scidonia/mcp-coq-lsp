Require Import Arith.


Lemma nested_bullets : forall n : nat, n + 0 = n.
Proof.
induction n.
- simpl. reflexivity.
- destruct n.
  - reflexivity.
    - simpl. rewrite IHn. reflexivity.
Admitted.

Lemma test_run : forall n : nat, n + 0 = n.
Proof.
induction n.
- simpl. reflexivity.
- simpl. rewrite IHn. reflexivity.
Qed.




Lemma test_insert : forall a b : nat, a + b = b + a.
Proof.
intros. apply Nat.add_comm.
Qed.

