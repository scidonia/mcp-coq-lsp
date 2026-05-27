Require Import Arith.

(* Simple theorem: addition is commutative *)
Theorem plus_comm : forall n m : nat,
  n + m = m + n.
Proof.
intros n m. induction n as [| n' IHn'].
- symmetry. apply Nat.add_0_r.
- simpl. rewrite IHn'. symmetry. apply Nat.add_succ_r.

Qed.


(* Slightly harder: associativity *)
Theorem plus_assoc : forall n m p : nat,
  n + (m + p) = (n + m) + p.
Proof.
Admitted.
