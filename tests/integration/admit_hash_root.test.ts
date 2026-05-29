/**
 * Integration tests for admit_hash targeting the root Admitted.
 *
 * When a proof has no tactic-level admit. lines, the closing Admitted.
 * is the single addressable admit. focus_proof returns its hash which
 * must match exactly what insert_tactic admit_hash uses — same snap position.
 *
 * Scenarios:
 *   1. Single goal (unstarted proof) — hash is usable directly
 *   2. Multiple goals (after split.) — hash covers all; hint says to bullet
 *   3. Hash from focus_proof matches insert_tactic admit_hash (no mismatch)
 */

import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import * as fs from 'fs';
import { McpHarness, createHarness, tempFixture, removeTempFixture, extractAdmitHashes } from './harness.js';

const TIMEOUT = 90_000;

let h: McpHarness;
beforeAll(async () => { h = await createHarness(); }, TIMEOUT);
afterAll(async () => { await h.teardown(); });

// ─────────────────────────────────────────────────────────────────────────────
// Single unstarted proof — Admitted. covers 1 goal
// ─────────────────────────────────────────────────────────────────────────────

describe('root Admitted. with single goal', () => {
  let tmpFile: string;

  beforeAll(async () => {
    tmpFile = tempFixture('multi_goal_admitted.v', 'rootsingle');
    await h.callTool('check_file', { file: tmpFile });
  }, TIMEOUT);
  afterAll(() => removeTempFixture(tmpFile));

  it('focus_proof returns exactly 1 admit for single_goal', async () => {
    const r = await h.callTool('focus_proof', { file: tmpFile, name: 'single_goal' });
    expect(r.isError).toBe(false);
    const admits = extractAdmitHashes(r.text);
    expect(admits).toHaveLength(1);
    expect(admits[0].goal).toMatch(/True/);
  }, TIMEOUT);

  it('hash from focus_proof works with insert_tactic admit_hash', async () => {
    const focus = await h.callTool('focus_proof', { file: tmpFile, name: 'single_goal' });
    const hash = extractAdmitHashes(focus.text)[0]?.hash;
    expect(hash).toBeTruthy();
    expect(hash).not.toBe('error');

    const r = await h.callTool('insert_tactic', {
      file: tmpFile,
      name: 'single_goal',
      tactic: 'exact I.',
      admit_hash: hash,
    });
    expect(r.isError).toBe(false);
    expect(r.text).toMatch(/Qed applied/i);

    const content = fs.readFileSync(tmpFile, 'utf8');
    expect(content).toMatch(/single_goal[\s\S]*?Qed\./);
    expect(content).not.toMatch(/single_goal[\s\S]*?Admitted\./);
  }, TIMEOUT);
});

// ─────────────────────────────────────────────────────────────────────────────
// Multiple goals at Admitted. — split. left 2 goals, no bullet structure
// ─────────────────────────────────────────────────────────────────────────────

describe('root Admitted. with multiple goals (after split.)', () => {
  let tmpFile: string;

  beforeAll(async () => {
    tmpFile = tempFixture('multi_goal_admitted.v', 'rootmulti');
    await h.callTool('check_file', { file: tmpFile });
  }, TIMEOUT);
  afterAll(() => removeTempFixture(tmpFile));

  it('focus_proof returns 1 admit entry covering N goals (| separated)', async () => {
    const r = await h.callTool('focus_proof', { file: tmpFile, name: 'multi_goal' });
    expect(r.isError).toBe(false);
    const admits = extractAdmitHashes(r.text);
    expect(admits).toHaveLength(1);
    // Goal text has | separating the 2 goals
    expect(admits[0].goal.split(' | ')).toHaveLength(2);
  }, TIMEOUT);

  it('focus_proof includes hint about bulleting N goals', async () => {
    const r = await h.callTool('focus_proof', { file: tmpFile, name: 'multi_goal' });
    expect(r.text).toMatch(/2 focused goals/);
    expect(r.text).toMatch(/bulleted admits/i);
  }, TIMEOUT);

  it('hash from focus_proof matches insert_tactic admit_hash for multi-goal Admitted.', async () => {
    const focus = await h.callTool('focus_proof', { file: tmpFile, name: 'multi_goal' });
    const hash = extractAdmitHashes(focus.text)[0]?.hash;
    expect(hash).toBeTruthy();
    expect(hash).not.toBe('error');

    // The hash is valid — insert_tactic must find it (no "No admit found" error)
    // Use "- exact I." to close the first focused goal under the implicit bullet
    const r = await h.callTool('insert_tactic', {
      file: tmpFile,
      name: 'multi_goal',
      tactic: '- exact I.',
      admit_hash: hash,
    });
    expect(r.isError).toBe(false);
    expect(r.text).toMatch(/replaced/i);
    // Both True goals share the same hash — exact I. closes both → Qed
    expect(r.text).toMatch(/Qed applied|1 admit\(s\) remaining/);
  }, TIMEOUT);
});

// ─────────────────────────────────────────────────────────────────────────────
// Regression: auto-Qed must NOT fire when background goals remain
//
// Scenario: split. → 2 goals, no tactic admits, one Admitted.
//   - insert first bullet "- exact I." → bullet 1 closed, 1 goal in background
//   - Admitted. still has 1 background goal
//   - auto-Qed must NOT fire here — proof is not complete
//   - file must still contain Admitted., not Qed.
// ─────────────────────────────────────────────────────────────────────────────

describe('auto-Qed must not fire with background goals remaining', () => {
  // Each test gets its own temp file to avoid LSP state bleed between tests.

  it('closing first bullet does not trigger Qed when second bullet is pending', async () => {
    const tmpFile = tempFixture('multi_goal_admitted.v', 'autqoed1');
    await h.callTool('check_file', { file: tmpFile });

    const focus = await h.callTool('focus_proof', { file: tmpFile, name: 'multi_goal' });
    const hash = extractAdmitHashes(focus.text)[0]?.hash;
    expect(hash).toBeTruthy();

    // Close first goal with a bullet — second goal still in background
    const r = await h.callTool('insert_tactic', {
      file: tmpFile, name: 'multi_goal', tactic: '- exact I.', admit_hash: hash,
    });
    expect(r.isError).toBe(false);

    // Must NOT have auto-Qed — 1 background goal remains
    expect(r.text).not.toMatch(/Qed applied/i);
    const content = fs.readFileSync(tmpFile, 'utf8');
    expect(content).toMatch(/Admitted\./);
    expect(content).not.toMatch(/\bQed\./);

    removeTempFixture(tmpFile);
  }, TIMEOUT);

  it('response message correctly reports background goal remaining, not Qed', async () => {
    // Verifies the response text accurately reflects state — "1 in background",
    // NOT "done — Qed applied" — when one bullet closes but another remains.
    const tmpFile = tempFixture('multi_goal_admitted.v', 'autqoed2');
    await h.callTool('check_file', { file: tmpFile });

    const focus = await h.callTool('focus_proof', { file: tmpFile, name: 'multi_goal' });
    const hash = extractAdmitHashes(focus.text)[0]?.hash;
    expect(hash).toBeTruthy();

    const r = await h.callTool('insert_tactic', {
      file: tmpFile, name: 'multi_goal', tactic: '- exact I.', admit_hash: hash,
    });
    expect(r.isError).toBe(false);
    // Response must indicate bullet closed with background remaining, not proof done
    expect(r.text).not.toMatch(/Qed applied/i);
    expect(r.text).toMatch(/background|remaining/i);

    removeTempFixture(tmpFile);
  }, TIMEOUT);
});

// ─────────────────────────────────────────────────────────────────────────────
// Regression: replacing a tactic-level admit. with a CLOSING tactic must NOT
// re-seal with a new admit. — the bullet is done, no open goals remain.
//
// This guards against the bug where querying proof/goals at firstLine+1 returns
// the next bullet's goal, causing a spurious re-seal after every admit_hash replace.
// ─────────────────────────────────────────────────────────────────────────────

describe('admit_hash: closing tactic must not re-seal', () => {
  it('replacing - admit. with a closing tactic produces no re-seal admit', async () => {
    const tmpFile = tempFixture('basic.v', 'noseal');
    await h.callTool('check_file', { file: tmpFile });

    // has_admits: True /\ True with split. and two - admit. bullets
    const focus = await h.callTool('focus_proof', { file: tmpFile, name: 'has_admits' });
    const admits = extractAdmitHashes(focus.text);
    // Should have 2 tactic-level admits
    expect(admits.length).toBeGreaterThanOrEqual(2);

    // Close first admit with a goal-closing tactic
    const hash = admits[0].hash;
    const r = await h.callTool('insert_tactic', {
      file: tmpFile,
      name: 'has_admits',
      tactic: 'exact I.',
      admit_hash: hash,
    });
    expect(r.isError).toBe(false);

    // Must NOT say "sealed with admit" — the tactic closed the goal
    expect(r.text).not.toMatch(/sealed with admit/i);

    // File must not have inserted a spurious admit. after the tactic
    const content = fs.readFileSync(tmpFile, 'utf8');
    // The replaced bullet should be "- exact I." with no admit. following it on the next line
    expect(content).not.toMatch(/- exact I\.\n\s+admit\./);

    removeTempFixture(tmpFile);
  }, TIMEOUT);

  it('replacing - admit. with a non-closing tactic (split.) DOES re-seal', async () => {
    const tmpFile = tempFixture('nested_conj.v', 'doseal');
    await h.callTool('check_file', { file: tmpFile });

    // nested_conj: (True /\ True) /\ (True /\ True) with two - admit. bullets
    const focus = await h.callTool('focus_proof', { file: tmpFile, name: 'nested_conj' });
    const hash = extractAdmitHashes(focus.text)[0]?.hash;
    expect(hash).toBeTruthy();

    const r = await h.callTool('insert_tactic', {
      file: tmpFile,
      name: 'nested_conj',
      tactic: 'split.',
      admit_hash: hash,
    });
    expect(r.isError).toBe(false);

    // split. on True /\ True leaves 2 open goals — MUST re-seal
    expect(r.text).toMatch(/sealed with/i);

    removeTempFixture(tmpFile);
  }, TIMEOUT);
});
