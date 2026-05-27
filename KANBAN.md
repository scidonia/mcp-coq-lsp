# Ergonomic Issues — Kanban

## In Progress

### Show full hypothesis list in spec preview (single-goal tactics)
- **Problem:** After `intros ... inversion ...`, you don't know what names Coq chose (`H4`? `H6`?). You guess wrong, commit, undo, redo.
- **Fix:** When spec check finds 1 goal, show full hypotheses with types. Commit `42c6980`.

## Backlog — High Priority

### No way to return to admitted/outstanding bullets
- **Problem:** When you `admit` a case mid-induction (e.g., S_AppAbs, S_Fix), those subgoals become "given-up." The proof continues with remaining bullets. After finishing all solvable cases, there's no tool to:
  - List which bullets were admitted/given-up
  - Jump back to a specific admitted bullet
  - Replace `admit.` with a real proof
  The only option is to scroll through the file and manually find `admit` lines.
- **Proposed:** A `list_admitted` tool and a `jump_to_bullet` command.

### Multi-tactic one-liner silently drops tail
- **Problem:** `intros. inversion; subst. destruct... exists... split... apply...` on one line. If any `.`-separated tactic fails mid-line, Coq stops processing, everything after is dead code. No error reported, file corrupted.
- **Proposed:** Warn when tactic contains >3 `.` separators; suggest splitting into multiple `insert_tactic` calls.

### Undo removes wrong operation in multi-insert bullets
- **Problem:** A bullet with two `insert_tactic` calls (e.g., `intros/inversion` on one line, `destruct/exists` on next). `undo_step(1)` removes the first line, leaving the second as an orphan referencing names that no longer exist.
- **Proposed:** Undo should remove the LAST insert, not the first. Or track insert order per bullet.

## Backlog — Medium Priority

### Bullet position shifts after mid-sequence undo+reinsert
- **Problem:** Removing and re-inserting a bullet in the middle of a 21-bullet sequence causes subsequent `insert_tactic` calls to land on wrong goals (e.g., S_Ref tactic went into S_AppAbs's slot).
- **Proposed:** Recompute bullet positions after every undo; or use named bullet targets instead of position-based.

### No batch-solve for repeated identical subgoal patterns
- **Problem:** 8+ cases share `intros; inversion; exists S; split; extends_refl; split; Hok; constructor`. Each requires separate `insert_tactic`. Coq supports `all: try (...)` but the tool doesn't help compose or apply bulk tactics.
- **Proposed:** A `batch_tactic` command that applies the same tactic to all remaining background goals at the same stack level.

### LLM admits mid-proof with no recovery path
- **Problem:** The LLM (or user) uses `admit.` on hard cases. These become "given-up" in the proof state. After the Qed/admitted line, you can't navigate back to fix them. The only option is to manually locate `admit` lines and replace them.
- **Proposed:** `focus_proof` should list given-up goals. `reset_proof` on a subgoal should be possible without wiping the entire proof.

## Done

- [x] Tool renames — removed `coq_` prefix, descriptive names
- [x] Proof-scoped undo — `undo_step` doesn't cross lemma boundaries
- [x] Lemma persistence through undo — `add_lemma` anchors history
- [x] `Proof.` auto-injection — missing `Proof.` is automatically added
- [x] Multi-line `check_file` types — no truncation
- [x] Multi-subgoal strategies in SKILL.md
- [x] Spec preview in `insert_tactic` — shows resulting goals before commit
- [x] `delete_lemma` — removes lemma block + forces LSP re-sync
- [x] `delete_step` — removes last N tactic lines without history
- [x] Auto-`.` — appends period if missing from tactic
- [x] No goal/type truncation — full visibility for AI reasoning
- [x] Stale LSP after edit — close+reopen+poll with petanque memo=false
- [x] Full hypothesis list in spec preview (single-goal cases)
