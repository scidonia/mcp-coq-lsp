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
