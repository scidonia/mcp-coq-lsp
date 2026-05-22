# Kanban — MCP coq-lsp Tool Issues

## Backlog

### CRITICAL

**C1. Goals state shows "done" when query failed**
**Status: Fixed (76c785c).** When `proof/goals` returns no data (null, error, or
missing goals field), the state now shows "goals query failed" or "error: ..."
instead of "done — try Qed". The caller can distinguish from genuinely-done.
Compound tactics that genuinely close proofs continue to show "done — try Qed".
*Investigation note: all compound-tactic cases tested (`induction; auto`,
`induction; simpl; intros`) genuinely closed. No case of wrong 0-goals found.*

**C2. `coq_insert_tactic` inserts garbage when cursor past EOF**
**Status: Fixed (76c785c).** `autoAdvancePosition` and `insertPosition` now
cap to `lines.length`. Previously could return positions beyond the file,
causing insertions at line 150+ in a 130-line file. Orphan tactics scattered
throughout the file.

### HIGH

**H1. No proof context shown in `coq_insert_tactic` response**
Returns goals but not the proof script. Caller can't see what tactics are already
written without separate `coq_focus` calls. Makes it hard to track proof progress.
*Fix: include proof script lines in response.*

**H2. `coq_focus` auto-remove of `Admitted.` leaves empty proof body**
When `Proof.\nAdmitted.` has nothing between, auto-remove creates an empty
proof body with 0 goals. The tool doesn't confirm what was removed.
*Mitigation: check for empty body before removal; log what was removed.*

**H3. `coq_apply_edit` requires manual line number computation**
Absolute line ranges are error-prone. I computed wrong ranges twice during PCF.
A text-replace or diff-based interface would prevent off-by-one corruption.
*Fix: accept `oldText`/`newText` search-and-replace instead of line ranges.*

### MEDIUM

**M1. `coq_reset_proof` doesn't return cursor to reset proof's body**
After resetting, the cursor stays at the old position, which may be inside
the reset range. Subsequent `coq_insert_tactic` goes to wrong place.
*Fix: set cursor to first line inside reset proof body.*

**M2. `coq_add_lemma` indent in generated stub is wrong**
Lemma stub has `Proof.\nAdmitted.\n` but both lines should be indented
relative to the lemma statement. Generated stubs are at column 0.
*Fix: add 2-space indent to Proof. and Admitted. lines.*

**M3. Auto-bullet "prefix" includes verbose message text**
`proof/goals` returns `"Focus next goal with bullet -."` or
`"The current bullet - is unfinished"` as the bullet field.
Extraction regex needs to handle both forms robustly.
*Fix: use `rawBullet?.match(/[-+*]+/)` which should handle both (pending verification).*

**M4. `coq_focus` takes `Proof.` line position — should advance into body**
When given `Proof.` line, cursor lands BEFORE `Proof.` or at it.
Should auto-advance to first meaningful line INSIDE the proof.
*Current behavior: insertPosition does advance, but inconsistently.*

**M5. Goal display doesn't distinguish "0 at focus but N in background"**
When bullet closes a focus goal, the response says "0 goals" without
mentioning the remaining background goal. Caller gets confused.
*Fix: merged into stateMsg already ("bullet closed, 1 in background").*
*Status: partial — works in `coq_insert_tactic` but not in `coq_open_goals`.*

### LOW

**L1. File clean-up needed after bulk edits**
`coq_apply_edit` with multi-range edits leaves the file in a messy state.
Need a `coq_format` or `coq_cleanup` tool.
*Fix: add `coq_format_file` tool that re-indents and normalizes.*

**L2. `coq_check` summary shows too many items**
Debug output includes `Inductive`/`Definition`/`Fixpoint` as "open".
Should only show `Lemma`/`Theorem` items with Qed/Admitted status.
*Fix: filter summary to only proof-bearing toplevel items.*

## In Progress

(none)

## Done

- [x] **D1.** Template file `test_templates/pcf_ref.v` — all Admitted stub for testing
- [x] **D2.** `coq_reset_proof` reports proof name (commit 43534f1)
- [x] **D3.** `coq_focus`/`coq_reset_proof`/`coq_add_lemma` use names not positions (eef2d4e)
- [x] **D4.** "done" → "done — try Qed" (40e6a4b)
- [x] **D5.** Auto-indent based on bullet stack depth (b84f696)
- [x] **D6.** Tool description: prefer explicit `as` clauses (9824885)
- [x] **D7.** `coq_check` reports admitted count + line numbers (1a98364)
- [x] **D8.** State messages: "bullet closed, N in background" (26ee254)
- [x] **D9.** Qed replaces Admitted (3a6de0b)
- [x] **D10.** History-based undo (fix for issue #5 from axiomander docs)
- [x] **D11.** `coq_add_lemma` tool (0e3c4dd)
- [x] **D12.** `coq_reset_proof` tool (1465173)
- [x] **D13.** `coq_check` shows toplevel summary with per-item status (fe24ec8)
