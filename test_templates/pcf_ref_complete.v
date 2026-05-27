Require Import Arith List Compare_dec Lia.
Import ListNotations.

(** * PCF with References — Template (all Admitted) *)

Inductive ty : Type :=
  | TyNat | TyBool | TyArrow : ty -> ty -> ty | TyRef : ty -> ty.

Inductive tm : Type :=
  | Var : nat -> tm | Num : nat -> tm | BOOL : bool -> tm
  | Succ : tm -> tm | Pred : tm -> tm | IsZero : tm -> tm
  | If : tm -> tm -> tm -> tm
  | Lam : ty -> tm -> tm | App : tm -> tm -> tm | Fix : tm -> tm
  | Ref : tm -> tm | Deref : tm -> tm | Assign : tm -> tm -> tm
  | Loc : nat -> tm.

Definition ctx := list ty.
Definition store_ty := list ty.

Inductive has_type : ctx -> store_ty -> tm -> ty -> Prop :=
  | T_Var : forall G S x T, nth_error G x = Some T -> has_type G S (Var x) T
  | T_Num : forall G S n, has_type G S (Num n) TyNat
  | T_Bool : forall G S b, has_type G S (BOOL b) TyBool
  | T_Succ : forall G S t, has_type G S t TyNat -> has_type G S (Succ t) TyNat
  | T_Pred : forall G S t, has_type G S t TyNat -> has_type G S (Pred t) TyNat
  | T_IsZero : forall G S t, has_type G S t TyNat -> has_type G S (IsZero t) TyBool
  | T_If : forall G S t1 t2 t3 T,
      has_type G S t1 TyBool -> has_type G S t2 T -> has_type G S t3 T -> has_type G S (If t1 t2 t3) T
  | T_Lam : forall G S T1 T2 t,
      has_type (T1 :: G) S t T2 -> has_type G S (Lam T1 t) (TyArrow T1 T2)
  | T_App : forall G S t1 t2 T1 T2,
      has_type G S t1 (TyArrow T1 T2) -> has_type G S t2 T1 -> has_type G S (App t1 t2) T2
  | T_Fix : forall G S t T,
      has_type (T :: G) S t T -> has_type G S (Fix t) T
  | T_Ref : forall G S t T, has_type G S t T -> has_type G S (Ref t) (TyRef T)
  | T_Deref : forall G S t T, has_type G S t (TyRef T) -> has_type G S (Deref t) T
  | T_Assign : forall G S t1 t2 T,
      has_type G S t1 (TyRef T) -> has_type G S t2 T -> has_type G S (Assign t1 t2) TyNat
  | T_Loc : forall G S l T, nth_error S l = Some T -> has_type G S (Loc l) (TyRef T).

Inductive value : tm -> Prop :=
  | V_Num : forall n, value (Num n) | V_Bool : forall b, value (BOOL b)
  | V_Lam : forall T t, value (Lam T t) | V_Loc : forall l, value (Loc l).

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
  | Ref t1 => Ref (subst j s t1) | Deref t1 => Deref (subst j s t1)
  | Assign t1 t2 => Assign (subst j s t1) (subst j s t2)
  | Loc l => Loc l
  end.

Definition heap := list (nat * tm).

Fixpoint heap_lookup (l : nat) (mu : heap) : option tm :=
  match mu with | [] => None | (l',v)::mu' => if Nat.eqb l l' then Some v else heap_lookup l mu' end.

Fixpoint heap_update (l : nat) (v : tm) (mu : heap) : heap :=
  match mu with | [] => [] | (l',v')::mu' => if Nat.eqb l l' then (l,v)::mu' else (l',v') :: heap_update l v mu' end.

Inductive heap_ok : heap -> store_ty -> Prop :=
  | heap_empty : forall S, heap_ok [] S
  | heap_cons : forall l v mu S T,
      heap_ok mu S -> has_type [] S v T -> nth_error S l = Some T ->
      heap_ok ((l, v) :: mu) S.

Inductive step : tm -> heap -> tm -> heap -> Prop :=
  | S_Succ : forall t mu t' mu', step t mu t' mu' -> step (Succ t) mu (Succ t') mu'
  | S_PredZero : forall mu, step (Pred (Num 0)) mu (Num 0) mu
  | S_PredSucc : forall n mu, step (Pred (Num (S n))) mu (Num n) mu
  | S_Pred : forall t mu t' mu', step t mu t' mu' -> step (Pred t) mu (Pred t') mu'
  | S_IsZeroZero : forall mu, step (IsZero (Num 0)) mu (BOOL true) mu
  | S_IsZeroSucc : forall n mu, step (IsZero (Num (S n))) mu (BOOL false) mu
  | S_IsZero : forall t mu t' mu', step t mu t' mu' -> step (IsZero t) mu (IsZero t') mu'
  | S_IfTrue : forall t1 t2 mu, step (If (BOOL true) t1 t2) mu t1 mu
  | S_IfFalse : forall t1 t2 mu, step (If (BOOL false) t1 t2) mu t2 mu
  | S_If : forall t1 mu t1' mu' t2 t3, step t1 mu t1' mu' -> step (If t1 t2 t3) mu (If t1' t2 t3) mu'
  | S_App1 : forall t1 mu t1' mu' t2, step t1 mu t1' mu' -> step (App t1 t2) mu (App t1' t2) mu'
  | S_App2 : forall v1 t2 mu t2' mu', value v1 -> step t2 mu t2' mu' -> step (App v1 t2) mu (App v1 t2') mu'
  | S_AppAbs : forall T t1 v2 mu, value v2 -> step (App (Lam T t1) v2) mu (subst 0 v2 t1) mu
  | S_Fix : forall t mu, step (Fix t) mu (subst 0 (Fix t) t) mu
  | S_Ref : forall t mu t' mu', step t mu t' mu' -> step (Ref t) mu (Ref t') mu'
  | S_RefV : forall v mu, value v -> step (Ref v) mu (Loc (length mu)) ((length mu, v) :: mu)
  | S_Deref : forall t mu t' mu', step t mu t' mu' -> step (Deref t) mu (Deref t') mu'
  | S_DerefLoc : forall l mu v, heap_lookup l mu = Some v -> step (Deref (Loc l)) mu v mu
  | S_Assign1 : forall t1 mu t1' mu' t2, step t1 mu t1' mu' -> step (Assign t1 t2) mu (Assign t1' t2) mu'
  | S_Assign2 : forall l t2 mu t2' mu', step t2 mu t2' mu' -> step (Assign (Loc l) t2) mu (Assign (Loc l) t2') mu'
  | S_AssignV : forall l v mu, value v -> step (Assign (Loc l) v) mu (Num 0) (heap_update l v mu).

Definition extends (S' S : store_ty) : Prop := exists S2, S' = S ++ S2.


Lemma extends_refl : forall S : store_ty, extends S S.
Proof.
  intro S. exists []. rewrite app_nil_r. reflexivity.
Qed.


Lemma nth_error_app_l : forall (A : Type) (l1 l2 : list A) (n : nat) (x : A), nth_error l1 n = Some x -> nth_error (l1 ++ l2) n = Some x.
Proof.
  intros A l1. induction l1 as [|h t IH]; intros l2 n x H. - destruct n; simpl in H; discriminate. - destruct n; simpl in H; simpl. + exact H. + apply IH. exact H.
Qed.


Lemma has_type_weaken : forall G S1 S2 t T, has_type G S1 t T -> extends S2 S1 -> has_type G S2 t T.
Proof.
  intros G S1 S2 t T Hty Hext. destruct Hext as [S3 Heq]. subst S2. induction Hty; try (econstructor; eauto). apply T_Loc. apply nth_error_app_l. exact H.
Qed.


Lemma extends_heap_ok : forall mu S S', heap_ok mu S -> extends S' S -> heap_ok mu S'.
Proof.
  intros mu S S' Hok Hext. induction Hok. - constructor. - apply heap_cons with (T := T). + apply IHHok. exact Hext. + apply has_type_weaken with (S1 := S). exact H. exact Hext. + apply nth_error_app_l. destruct Hext as [S2 Heq]. subst S'. apply nth_error_app_l. exact H0.
Qed.


Lemma heap_ok_lookup : forall mu S l v, heap_ok mu S -> heap_lookup l mu = Some v -> exists T, nth_error S l = Some T /\ has_type [] S v T.
Proof.
  intros mu S l v Hok Hlook. induction Hok as [|l' v' mu' S' T Hok' IH Hty' Hnth]. - simpl in Hlook. discriminate. - simpl in Hlook. destruct (Nat.eqb l l') eqn:Heq. + apply Nat.eqb_eq in Heq. subst l'. injection Hlook as Heqv. subst v'. exists T. split; exact Hty' + Hnth. + apply IH. exact Hlook.
Qed.


Lemma substitution_preserves_typing : forall G1 G2 S s t T Ts, has_type (G1 ++ G2) S s Ts -> has_type (G1 ++ Ts :: G2) S t T -> has_type (G1 ++ G2) S (subst (length G1) s t) T.
Proof.
  intros G1 G2 S s t T Ts Hs Ht. revert G1 G2 S s T Ts Hs. induction Ht; intros G1 G2 S' s Tty Ts Hs; simpl.
  - (* T_Var *) rename x into n. destruct (Nat.eqb n (length G1)) eqn:Heq. + apply Nat.eqb_eq in Heq. subst n. rewrite nth_error_app2 in H by auto. simpl in H. injection H as Htseq. subst Tty. exact Hs. + apply Nat.eqb_neq in Heq. apply T_Var. destruct (Nat.lt_or_ge n (length G1)) as [Hlt | Hge]. * rewrite nth_error_app1 in H by auto. rewrite nth_error_app1 by auto. exact H. * assert (n > length G1) by omega. destruct n as [|n']. { omega. } simpl. apply T_Var. rewrite nth_error_app2 in H by omega. rewrite nth_error_app2 by omega. simpl in H. simpl. replace (n' - length G1) with (S (n' - length G1 - 1)) by omega. rewrite <- H. f_equal. omega.
  - constructor. - constructor. - constructor. apply IHHt with (Ts := Ts). exact Hs. exact H. - constructor. apply IHHt with (Ts := Ts). exact Hs. exact H. - constructor. apply IHHt with (Ts := Ts). exact Hs. exact H. - constructor. + apply IHHt1 with (Ts := Ts). exact Hs. exact H. + apply IHHt2 with (Ts := Ts). exact Hs. exact H0. + apply IHHt3 with (Ts := Ts). exact Hs. exact H1.
Qed.


Lemma heap_ok_update : forall mu S l v T, heap_ok mu S -> nth_error S l = Some T -> has_type [] S v T -> heap_ok (heap_update l v mu) S.
Proof.
  intros mu S l v T Hok Hnth Hv. induction Hok as [|l' v' mu' S' T' Hok' IH Hv' Hnth']. - simpl. constructor. - simpl. destruct (Nat.eqb l l') eqn:Heq. + apply Nat.eqb_eq in Heq. subst l'. apply heap_cons with (T := T). * exact Hok'. * assert (T = T') as Heqt. { rewrite Hnth' in Hnth. injection Hnth as Heqt. exact Heqt. } subst T'. exact Hv. * exact Hnth'. + apply heap_cons with (T := T'). * apply IH. * exact Hv'. * exact Hnth'.
Qed.

Theorem preservation : forall t mu t' mu' T S,
  has_type [] S t T -> step t mu t' mu' ->
  heap_ok mu S -> length mu = length S ->
  exists S', extends S' S /\ heap_ok mu' S' /\ has_type [] S' t' T /\ length mu' = length S'.
Proof.
  intros t mu t' mu' Tty S Hty Hstep. revert Tty S Hty. induction Hstep; intros Tty S Hty Hok Hlen.
  - (* S_Succ *) inversion Hty; subst. destruct (IHHstep TyNat S H2 Hok Hlen) as [S' [Hext [Hok' [Hty' Hlen']]]]. exists S'. split. exact Hext. split. exact Hok'. split. constructor. exact Hty'. exact Hlen'.
    - (* S_PredZero *) inversion Hty; subst. exists S. split. apply extends_refl. split. exact Hok. split. constructor. exact Hlen.
    - (* S_PredSucc *) inversion Hty; subst. exists S. split. apply extends_refl. split. exact Hok. split. constructor. exact Hlen.
    - (* S_Pred *) inversion Hty; subst. destruct (IHHstep TyNat S H2 Hok Hlen) as [S' [Hext [Hok' [Hty' Hlen']]]]. exists S'. split. exact Hext. split. exact Hok'. split. constructor. exact Hty'. exact Hlen'.
    - (* S_IsZeroZero *) inversion Hty; subst. exists S. split. apply extends_refl. split. exact Hok. split. constructor. exact Hlen.
    - (* S_IsZeroSucc *) inversion Hty; subst. exists S. split. apply extends_refl. split. exact Hok. split. constructor. exact Hlen.
    - (* S_IsZero *) inversion Hty; subst. destruct (IHHstep TyNat S H2 Hok Hlen) as [S' [Hext [Hok' [Hty' Hlen']]]]. exists S'. split. exact Hext. split. exact Hok'. split. constructor. exact Hty'. exact Hlen'.
    - (* S_IfTrue *) inversion Hty; subst. exists S. split. apply extends_refl. split. exact Hok. split. exact H6. exact Hlen.
    - (* S_IfFalse *) inversion Hty; subst. exists S. split. apply extends_refl. split. exact Hok. split. exact H7. exact Hlen.
    - (* S_If *) inversion Hty; subst. destruct (IHHstep TyBool S H4 Hok Hlen) as [S' [Hext [Hok' [Hty1' Hlen']]]]. exists S'. split. exact Hext. split. exact Hok'. split. apply T_If. exact Hty1'. eapply has_type_weaken; eauto. eapply has_type_weaken; eauto. exact Hlen'.
    - (* S_App1 *) inversion Hty; subst. destruct (IHHstep (TyArrow T1 Tty) S H3 Hok Hlen) as [S' [Hext [Hok' [Hty1' Hlen']]]]. exists S'. split. exact Hext. split. exact Hok'. split. eapply T_App. exact Hty1'. eapply has_type_weaken; eauto. exact Hlen'.
    - (* S_App2 *) inversion Hty; subst. destruct (IHHstep T1 S H6 Hok Hlen) as [S' [Hext [Hok' [Hty2' Hlen']]]]. exists S'. split. exact Hext. split. exact Hok'. split. eapply T_App. eapply has_type_weaken; eauto. exact Hty2'. exact Hlen'.
    - (* S_AppAbs *) inversion Hty; subst. inversion H4; subst. exists S. split. apply extends_refl. split. exact Hok. split. apply (substitution_preserves_typing [] [] S v2 t1 Tty T1). exact H6. simpl. exact H3. exact Hlen.
    - (* S_Fix *) inversion Hty; subst. exists S. split. apply extends_refl. split. exact Hok. split. apply (substitution_preserves_typing [] [] S (Fix t) t Tty Tty). exact Hty. simpl. exact H2. exact Hlen.
    - (* S_Ref *) inversion Hty; subst. destruct (IHHstep T S H2 Hok Hlen) as [S' [Hext [Hok' [Hty' Hlen']]]]. exists S'. split. exact Hext. split. exact Hok'. split. constructor. exact Hty'. exact Hlen'.
    - (* S_RefV *) inversion Hty; subst. exists (S ++ [T]). split. exists [T]. reflexivity. split. eapply heap_cons. eapply extends_heap_ok. exact Hok. exists [T]. reflexivity. eapply has_type_weaken. exact H3. exists [T]. reflexivity. rewrite nth_error_app2 by lia. rewrite Hlen. rewrite Nat.sub_diag. reflexivity. split. apply T_Loc. rewrite nth_error_app2 by lia. rewrite Hlen. rewrite Nat.sub_diag. reflexivity. rewrite app_length. simpl. lia.
    - (* S_Deref *) inversion Hty; subst. destruct (IHHstep (TyRef Tty) S H2 Hok Hlen) as [S' [Hext [Hok' [Hty' Hlen']]]]. exists S'. split. exact Hext. split. exact Hok'. split. constructor. exact Hty'. exact Hlen'.
    - (* S_DerefLoc *) inversion Hty; subst. inversion H3; subst. destruct (heap_ok_lookup mu S l v Hok H) as [T [Hnth Htv]]. rewrite H5 in Hnth. injection Hnth as Heq. subst. exists S. split. apply extends_refl. split. exact Hok. split. exact Htv. exact Hlen.
    - (* S_Assign1 *) inversion Hty; subst. destruct (IHHstep (TyRef T) S H3 Hok Hlen) as [S' [Hext [Hok' [Hty1' Hlen']]]]. exists S'. split. exact Hext. split. exact Hok'. split. eapply T_Assign. exact Hty1'. eapply has_type_weaken; eauto. exact Hlen'.
    - (* S_Assign2 *) inversion Hty; subst. destruct (IHHstep T S H5 Hok Hlen) as [S' [Hext [Hok' [Hty2' Hlen']]]]. exists S'. split. exact Hext. split. exact Hok'. split. eapply T_Assign. eapply has_type_weaken; eauto. exact Hty2'. exact Hlen'.
    - (* S_AssignV *) inversion Hty; subst. inversion H3; subst. exists S. split. apply extends_refl. split. eapply heap_ok_update. exact Hok. exact H2. exact H5. split. constructor. assert (length (heap_update l v mu) = length mu) as Hupd. { induction mu as [|[l' v'] mu' IH]; simpl. reflexivity. destruct (Nat.eqb l l'); simpl; [reflexivity | f_equal; apply IH]. } rewrite Hupd. exact Hlen.
Qed.
