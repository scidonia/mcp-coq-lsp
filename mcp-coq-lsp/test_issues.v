Require Import Arith List Compare_dec.
Import ListNotations.

Inductive ty : Type :=
  | TyNat : ty | TyBool : ty | TyArrow : ty -> ty -> ty.

Inductive tm : Type :=
  | Var : nat -> tm | Num : nat -> tm | BOOL : bool -> tm
  | Succ : tm -> tm | Pred : tm -> tm | IsZero : tm -> tm
  | If : tm -> tm -> tm -> tm
  | Lam : ty -> tm -> tm | App : tm -> tm -> tm | Fix : tm -> tm.

Definition ctx := list ty.

Inductive has_type : ctx -> tm -> ty -> Prop :=
  | T_Var : forall G x T, nth_error G x = Some T -> has_type G (Var x) T
  | T_Num : forall G n, has_type G (Num n) TyNat
  | T_Bool : forall G b, has_type G (BOOL b) TyBool
  | T_Succ : forall G t, has_type G t TyNat -> has_type G (Succ t) TyNat
  | T_Pred : forall G t, has_type G t TyNat -> has_type G (Pred t) TyNat
  | T_IsZero : forall G t, has_type G t TyNat -> has_type G (IsZero t) TyBool
  | T_If : forall G t1 t2 t3 T,
      has_type G t1 TyBool -> has_type G t2 T -> has_type G t3 T -> has_type G (If t1 t2 t3) T
  | T_Lam : forall G T1 T2 t,
      has_type (T1 :: G) t T2 -> has_type G (Lam T1 t) (TyArrow T1 T2)
  | T_App : forall G t1 t2 T1 T2,
      has_type G t1 (TyArrow T1 T2) -> has_type G t2 T1 -> has_type G (App t1 t2) T2
  | T_Fix : forall G t T,
      has_type (T :: G) t T -> has_type G (Fix t) T.

Inductive value : tm -> Prop :=
  | V_Num : forall n, value (Num n)
  | V_Bool : forall b, value (BOOL b)
  | V_Lam : forall T t, value (Lam T t).

Fixpoint subst (j : nat) (s : tm) (t : tm) : tm :=
  match t with
  | Var x => if Nat.eqb x j then s else Var x
  | Num n => Num n | BOOL b => BOOL b
  | Succ t1 => Succ (subst j s t1) | Pred t1 => Pred (subst j s t1)
  | IsZero t1 => IsZero (subst j s t1)
  | If t1 t2 t3 => If (subst j s t1) (subst j s t2) (subst j s t3)
  | Lam T t1 => Lam T (subst (S j) s t1)
  | App t1 t2 => App (subst j s t1) (subst j s t2)
  | Fix t1 => Fix (subst (S j) s t1)
  end.

Inductive step : tm -> tm -> Prop :=
  | S_Succ : forall t t', step t t' -> step (Succ t) (Succ t')
  | S_PredZero : step (Pred (Num 0)) (Num 0)
  | S_PredSucc : forall n, step (Pred (Num (S n))) (Num n)
  | S_Pred : forall t t', step t t' -> step (Pred t) (Pred t')
  | S_IsZeroZero : step (IsZero (Num 0)) (BOOL true)
  | S_IsZeroSucc : forall n, step (IsZero (Num (S n))) (BOOL false)
  | S_IsZero : forall t t', step t t' -> step (IsZero t) (IsZero t')
  | S_IfTrue : forall t1 t2, step (If (BOOL true) t1 t2) t1
  | S_IfFalse : forall t1 t2, step (If (BOOL false) t1 t2) t2
  | S_If : forall t1 t1' t2 t3, step t1 t1' -> step (If t1 t2 t3) (If t1' t2 t3)
  | S_App1 : forall t1 t1' t2, step t1 t1' -> step (App t1 t2) (App t1' t2)
  | S_App2 : forall v1 t2 t2', value v1 -> step t2 t2' -> step (App v1 t2) (App v1 t2')
  | S_AppAbs : forall T t1 v2, value v2 -> step (App (Lam T t1) v2) (subst 0 v2 t1)
  | S_Fix : forall t, step (Fix t) (subst 0 (Fix t) t).

Lemma ctx_lookup_app : forall G1 G2 x T,
  nth_error (G1 ++ G2) (length G1 + x) = Some T ->
  nth_error G2 x = Some T.
Proof.
  induction G1; simpl; intros H; [exact H | apply IHG1; exact H].
Qed.

Lemma ctx_lookup_skip : forall G1 G2 x T,
  nth_error (G1 ++ (T :: G2)) x = Some T ->
  x < length G1 ->
  nth_error G1 x = Some T.
Proof.
induction G1 as [| T1 G1' IH]; simpl; intros x T2 H Hlen; [exfalso; exact (Lt.lt_n_O _ Hlen) | ].
Qed.


Lemma substitution_preserves_typing : forall G1 G2 x s t T,
    has_type (G1 ++ (T :: G2)) t T ->
  has_type (G1 ++ G2) (subst (length G1) s t) T.
Proof.
intros G1 G2 x s t T Hs Ht. revert G1 G2 x s Hs. induction Ht; simpl; intros G1 G2 x s Hs.
Qed.


Theorem preservation : forall t t' T,
  has_type [] t T -> step t t' -> has_type [] t' T.
Proof.
intros t t' T Ht Hstep. revert T Ht. induction Hstep; intros T Ht; inversion Ht; subst; eauto; try (constructor; eauto).
Qed.

