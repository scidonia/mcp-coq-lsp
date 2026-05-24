# Coq Proof Skill via MCP coq-lsp Tools

This document provides guidance for completing Coq/Rocq proofs using the `coq-lsp` MCP tools.

## Tool Reference

### Proof Navigation

| Tool | Purpose |
|------|---------|
| `coq_focus` | Get the current proof tree: goals, bullet depth, proof script up to cursor. Sets file cursor for subsequent `coq_insert_tactic`. Accepts proof name or explicit position. |
| `coq_open_goals` | Get current open goals for a named proof (Prev mode by default). |
| `coq_proof_state` | Get richer proof context including proof name and statement. |
| `coq_check` | Force full document checking and return completion status. |
| `coq_check_range` | Check a specific line range and return diagnostics. |

### Tactic Insertion

| Tool | Purpose |
|------|---------|
| `coq_insert_tactic` | Insert a tactic into a proof and return updated goals. **Auto-prepends bullet prefix** (-, +, *) when proof state requires it. Use `replace: true` to retry a failed tactic (undoes last insertion first). |
| `coq_try_tactic` | Single-call speculative tactic execution: get state, run tactic, return updated goals. Does NOT modify the file. Use to test a tactic before committing. |
| `coq_undo` | Restore the file to before the last N edit operations. |

### Lemma Management

| Tool | Purpose |
|------|---------|
| `coq_add_lemma` | Insert a lemma stub (Lemma name : statement. Proof. Admitted.) above a specified proof. Use `before` to name the proof it goes above. |
| `coq_reset_proof` | Wipe a proof body (from Proof. to Qed./Admitted.) and replace with fresh Admitted. Use to restart a broken proof. |

### Exploration

| Tool | Purpose |
|------|---------|
| `coq_search` | Search the Coq environment for lemmas/theorems. Simple names auto-quote. Use parentheses for patterns: `(_ + 0 = _)`. |
| `coq_check_term` | Check the type of a term speculatively. Runs `Check <term>.` |
| `coq_about` | Get information about a term/definition speculatively. Runs `About <term>.` |
| `coq_locate` | Find where a library, module, or term is defined. Useful before Require to check if a module exists. |
| `coq_require` | Require a library speculatively. Subsequent speculative queries on the same file will see the library. |

### File Editing

| Tool | Purpose |
|------|---------|
| `coq_apply_edit` | Apply text edits to a file and re-sync with rocq-lsp. Use `find`/`replace` for simple text search-and-replace instead of computing line numbers. |

## Proof Strategy

### 1. Start with the goal

Use `coq_focus` on the theorem to see the goal and proof context.

```coq
coq_focus name="my_theorem" file="path/file.v"
```

### 2. Plan the induction

Most Coq theorems about inductive relations are proved by induction on the relation itself.
- `induction Hstep` — if proving a step relation property
- `induction Hty` — if proving a typing property
- `induction t` — if proving a term property

### 3. Handle base cases first

Simple base cases often just need `inversion` and `exists`:
```coq
- inversion Hty; subst. exists S. split. apply extends_refl. ...
```

### 4. Use induction hypotheses

For inductive cases, `destruct (IH...)` to get the induction hypothesis, then combine with constructors:
```coq
- destruct (IHHstep T S H3 Hok Hlen) as [S' [Hext [Hok' [Hty' Hlen']]]].
  exists S'. split. exact Hext. ...
```

### 5. Add lemmas only when needed

When a case fails because a helper property is missing, add it with `coq_add_lemma`:
```coq
coq_add_lemma name="my_lemma" statement="forall x, P x"
              before="main_theorem" file="path/file.v"
```

Then prove the lemma before returning to the main theorem.

## Bullet System

### Auto-bullet behavior

When you insert a tactic and there are multiple goals remaining, the tool **automatically prepends a bullet prefix** with correct indentation.

**Bullet rotation**: To prevent Coq's focus stack from collapsing, sibling bullets use the same character but **nested bullets use different characters**:

- Level 0 (outermost): `-`
- Level 1 (first nesting): `+`
- Level 2 (second nesting): `*`
- Level 3+: `--`, `++`, `**`, `---`, ...

The tool determines this automatically. You just type the tactic name (e.g., `split.`), and the tool adds the right bullet and indentation.

### When bullets appear

A bullet is prepended when:
- **LSP says "Focus next goal with bullet X."** — The LSP knows the correct bullet for the next sibling. Trust it.
- **LSP says "unfinished" and >1 focused goals** — The current bullet context has multiple subgoals. A child bullet is needed, using the next character in rotation.
- **No LSP bullet and totalRemaining > 1** — The first bullet group in a branch. Starts with `-`.

No bullet is added when:
- Only 1 goal remains — the tactic runs in the current context.
- The tactic is `Qed.`, `Defined.`, or `Admitted.`.

### Bullet structure in proofs

```
split.               (* 2 goals created *)
- split.             (* focuses on goal 1, creates 2 subgoals *)
  + split.           (* focuses on subgoal 1.1, creates 2 sub-subgoals *)
    * trivial.       (* solves sub-subgoal 1.1.1 *)
    * trivial.       (* solves sub-subgoal 1.1.2 *)
  + trivial.         (* solves subgoal 1.2 *)
- trivial.           (* solves goal 2 *)
```

## Common Tactic Patterns

### Inversion
```coq
inversion Hty; subst.              (* destructure typing derivation *)
inversion H4; subst.               (* destructure value judgment *)
```

### Existence
```coq
exists S. split. exact Hext. split. exact Hok. split. constructor. ...
exists (S ++ [T]). split. exists [T]. reflexivity. ...
```

### Induction Hypothesis
```coq
destruct (IHHstep TyNat S H2 Hok Hlen) as [S' [Hext [Hok' [Hty' Hlen']]]].
```

### Context Weakening
```coq
eapply has_type_weaken; eauto.     (* when store extends *)
rewrite nth_error_app2 by lia.     (* when appending to store *)
```

### Arithmetic
```coq
lia                                (* linear integer arithmetic solver *)
omega                              (* older alternative to lia *)
rewrite app_length. simpl. lia.    (* length calculations *)
```

## Lemma Dependency Order

When proving a large theorem, add lemmas in dependency order:

| Lemma | Used By | Purpose |
|-------|---------|---------|
| `extends_refl` | Base cases | Every store extends itself |
| `nth_error_app_l` | `has_type_weaken` | Lookup in extended store |
| `has_type_weaken` | Many cases | Typing preserved under store extension |
| `extends_heap_ok` | S_RefV | Heap well-formedness under store extension |
| `heap_ok_lookup` | S_DerefLoc | Well-formed heap has typed entries |
| `substitution_preserves_typing` | S_AppAbs, S_Fix | Substitution preserves types |
| `heap_ok_update` | S_AssignV | Heap update preserves well-formedness |

## Troubleshooting

### LSP stale after bulk edits

If the LSP reports errors after `coq_apply_edit`, run `coq_check` to force re-processing:
```coq
coq_check file="path/file.v"
```

### Proof out of sync

If `coq_insert_tactic` inserts at the wrong position, use `coq_focus` to reset the cursor:
```coq
coq_focus name="my_theorem" file="path/file.v"
```

### Speculative check fails for proof-closing commands

`Qed.` and `Admitted.` bypass petanque pre-flight checks. Insert them directly.

### Replace a failed tactic

Use `replace: true` to undo the last insertion and retry:
```coq
coq_insert_tactic name="my_theorem" tactic="reflexivity." file="path/file.v" replace=true
```
