# Neurosymbolic Programming with Coq LSP

## Overview

This project demonstrates how a **Language Server Protocol (LSP)** interface to the **Coq proof assistant** enables **neurosymbolic programming**: the seamless integration of neural networks (LLMs) with symbolic reasoning systems (proof assistants).

## What is Neurosymbolic Programming?

Neurosymbolic programming combines:

- **Neural/Statistical AI** (LLMs): Pattern recognition, natural language understanding, heuristic search
- **Symbolic AI** (Proof assistants): Logical reasoning, formal verification, guaranteed correctness

This approach leverages the complementary strengths of both paradigms:

| Neural (LLM) | Symbolic (Coq) |
|--------------|----------------|
| Intuition & pattern matching | Rigorous logical deduction |
| Generates candidate solutions | Verifies correctness |
| Probabilistic & approximate | Deterministic & exact |
| Learns from examples | Reasons from axioms |
| Fast but fallible | Slow but infallible |

## How LSP Enables Neurosymbolic Coq Programming

### The Traditional Problem

Historically, interacting with proof assistants required:
- Deep knowledge of proof tactics and syntax
- Understanding of internal proof state representations
- Manual, tedious proof construction
- Limited automation capabilities

This created a barrier between AI systems (which excel at pattern matching and generation) and proof assistants (which excel at verification).

### The LSP Solution

The **Language Server Protocol** provides a standardized, machine-friendly interface that:

1. **Exposes Proof State**: Query current goals, hypotheses, and proof context at any position
2. **Enables Interactive Editing**: Apply tactics and immediately observe their effects
3. **Supports Speculative Execution**: Try tactics without committing to file edits (Pétanque API)
4. **Provides Structured Feedback**: Parse errors, type information, and verification results

This transforms the proof assistant into a **verification oracle** that an LLM can query interactively.

### The Neurosymbolic Loop

```
┌─────────────┐
│   LLM       │  ← Reads: proof goals, context, error messages
│  (Neural)   │  → Generates: candidate tactics, proof strategies
└──────┬──────┘
       │
       ↓ (proposes tactics)
┌──────────────┐
│  LSP Server  │  ← Bridges neural and symbolic systems
│  (Interface) │  → Translates between LLM and Coq
└──────┬───────┘
       │
       ↓ (executes & verifies)
┌──────────────┐
│  Coq/Rocq    │  ← Verifies: type-checks, proves correctness
│  (Symbolic)  │  → Returns: success/failure, updated goals
└──────────────┘
```

**Workflow:**
1. LLM reads proof goal via LSP (`coq_open_goals`)
2. LLM generates candidate tactic(s) based on patterns learned from training
3. Tactics are applied via LSP (`coq_insert_tactic`)
4. Coq verifies the tactic is type-correct and logically sound
5. If successful: proof progresses (new subgoals or QED)
6. If failed: error message guides LLM to try alternatives
7. Loop continues until proof is complete

### Why This Is Powerful

This architecture achieves:

**Guided Generation**: The LLM doesn't need to be "correct" — only creative. Coq acts as a discriminator that filters out invalid proofs.

**Incremental Verification**: Each step is verified immediately, preventing cascading errors.

**Explainable AI**: Every LLM decision is justified by a formal proof that can be audited by humans.

**Learning from Mistakes**: Structured error feedback allows the LLM to refine its search strategy.

**Safe Automation**: The LLM can explore aggressively because Coq guarantees soundness.

## Key Capabilities Enabled by LSP

### 1. Goal-Directed Search

The LLM can:
- Query the current proof goal: "Prove that `forall n, n + 0 = n`"
- Understand the hypothesis context: "Given: `n : nat`"
- Generate relevant tactics: "I'll try induction on `n`"

**LSP Tool**: `coq_open_goals` — returns structured goal representation

### 2. Speculative Execution

The LLM can:
- Try multiple tactics without modifying the file
- Quickly discard failures
- Only commit tactics that successfully reduce the goal

**LSP Tools**: `coq_get_state_at_pos`, `coq_run_tactic`, `coq_goals_for_state` (Pétanque API)

### 3. Interactive Proof Refinement

The LLM can:
- Incrementally build proofs tactic-by-tactic
- Respond to verification failures by adjusting strategy
- Learn which patterns work in different contexts

**LSP Tool**: `coq_insert_tactic` — applies tactic and returns updated goals

### 4. Error-Driven Learning

The LLM can:
- Receive structured error messages from Coq
- Understand type mismatches, unification failures, etc.
- Adjust tactics based on specific error feedback

**LSP Feature**: All tools return structured error information

## Concrete Example: LLM Proving a Theorem

**Goal**: Prove `forall n, n + 0 = n` in Coq

**Without LSP (traditional)**:
```coq
(* Human manually writes: *)
Lemma add_zero_r : forall n, n + 0 = n.
Proof.
  induction n.
  - reflexivity.
  - simpl. rewrite IHn. reflexivity.
Qed.
```

**With LSP (neurosymbolic)**:

```
1. LLM: "Let me check the goal"
   → coq_open_goals(file="Add.v", line=13)
   ← Goal: "forall n : nat, n + 0 = n"

2. LLM: "I need to prove a universal quantifier, I'll introduce the variable"
   → coq_insert_tactic(tactic="induction n.")
   ← Success! New goals:
      • Goal 1: "0 + 0 = 0"
      • Goal 2: "S n + 0 = S n" (with IH: "n + 0 = n")

3. LLM: "First goal is trivial by reflexivity"
   → coq_insert_tactic(tactic="- reflexivity.")
   ← Success! Goal 1 complete. Now on Goal 2.

4. LLM: "Let me simplify and use the induction hypothesis"
   → coq_insert_tactic(tactic="- simpl. rewrite IHn. reflexivity.")
   ← Success! Proof complete. QED.
```

**Key neurosymbolic elements**:
- LLM uses **pattern recognition** (recognizes ∀ needs intro, S needs induction)
- Coq provides **verification** (each tactic is type-checked)
- LSP provides **interaction protocol** (query → propose → verify → iterate)

## Architecture: This Project

This MCP (Model Context Protocol) server implements the LSP bridge:

```
┌──────────────────────────────────────┐
│  OpenCode / LLM Agent                │
│  (Claude, GPT-4, etc.)               │
└─────────────┬────────────────────────┘
              │ MCP Protocol
              │ (tool calls)
┌─────────────▼────────────────────────┐
│  mcp-coq-lsp                         │
│  • Exposes 8 MCP tools               │
│  • Manages document state            │
│  • Handles LSP ↔ MCP translation     │
└─────────────┬────────────────────────┘
              │ JSON-RPC (LSP + Pétanque)
              │ (stdio)
┌─────────────▼────────────────────────┐
│  coq-lsp / rocq-lsp                  │
│  • Type-checks Coq files             │
│  • Tracks proof state                │
│  • Executes tactics                  │
└─────────────┬────────────────────────┘
              │ OCaml API
              │
┌─────────────▼────────────────────────┐
│  Coq/Rocq Kernel                     │
│  • Formal verification engine        │
│  • Proof checker                     │
│  • Type theory implementation        │
└──────────────────────────────────────┘
```

### 8 MCP Tools for Neurosymbolic Coq

| Tool | Neural Use Case | Symbolic Capability |
|------|----------------|---------------------|
| `coq_open_goals` | "What do I need to prove?" | Returns current goals & context |
| `coq_proof_state` | "What proof am I working on?" | Returns proof name & statements |
| `coq_get_state_at_pos` | "Save this proof state" | Returns state ID for speculation |
| `coq_run_tactic` | "Will this tactic work?" | Executes tactic without file edit |
| `coq_goals_for_state` | "Show me goals after that tactic" | Returns goals for a state ID |
| `coq_apply_edit` | "Update the proof file" | Applies text edits & re-verifies |
| `coq_insert_tactic` | "Try this tactic and show results" | Insert + verify + return new goals |
| `coq_check` | "Is the whole file valid?" | Forces full document checking |

## Benefits of This Approach

### For AI/LLM Developers
- **Structured Interface**: No need to parse Coq syntax or output
- **Immediate Feedback**: Know instantly if a tactic succeeds
- **Safe Exploration**: Can't generate unsound proofs
- **Reduced Search Space**: Type system eliminates invalid candidates

### For Proof Engineers
- **AI Assistance**: Let LLMs handle tedious proof details
- **Guaranteed Soundness**: All proofs are formally verified
- **Interactive Refinement**: Guide AI when it gets stuck
- **Explainable Results**: Every proof step is auditable

### For Researchers
- **Benchmark Platform**: Test AI proof capabilities
- **Formal ML**: Train models on verified code
- **Safe Code Generation**: Generate formally verified programs
- **Hybrid Intelligence**: Study human-AI-proof collaboration

## Real-World Applications

### 1. Automated Theorem Proving
LLMs can tackle routine lemmas while experts focus on complex proofs.

### 2. Formally Verified Software
Generate code with machine-checked correctness proofs (e.g., crypto, compilers).

### 3. Mathematical Formalization
Convert natural language math into Coq, assisted by LLMs.

### 4. Education
Interactive tutoring systems that teach both intuition (LLM) and rigor (Coq).

### 5. AI Safety Research
Build verifiably safe AI systems with formal guarantees.

## Getting Started

### Prerequisites
```bash
# Install Coq and coq-lsp
opam install coq coq-lsp

# Verify installation
coq-lsp --version
```

### Installation
```bash
cd mcp-coq-lsp
npm install
npm run build
```

### Usage with OpenCode

Add to your MCP settings:
```json
{
  "mcpServers": {
    "coq-lsp": {
      "command": "node",
      "args": [
        "/path/to/mcp-coq-lsp/dist/index.js",
        "--workspace-root",
        "/path/to/your/coq/project"
      ]
    }
  }
}
```

Then in OpenCode:
```
You: "Help me prove that addition is commutative in Coq"

OpenCode: [Uses coq_open_goals to see the goal]
OpenCode: [Uses coq_insert_tactic to try "induction n"]
OpenCode: [Iteratively builds the proof using LSP feedback]
OpenCode: "Proof complete! Here's what I did..."
```

## Example Session

See `mcp-coq-lsp/example.v` for a complete example with:
- A finished proof (to query goals)
- An incomplete proof (to practice tactics)
- Test cases for each MCP tool

## The Future of Neurosymbolic Programming

This LSP-based architecture represents a paradigm shift:

**From**: "AI generates code, humans verify"  
**To**: "AI and proof assistants collaborate in real-time"

**From**: "LLMs are black boxes"  
**To**: "Every LLM decision has a formal proof"

**From**: "Formal verification is for experts"  
**To**: "LLMs make formal methods accessible"

As LLMs improve and proof assistants expose richer APIs, we expect:
- **Automated formalization** of mathematical papers
- **AI-assisted discovery** of new theorems
- **Verified AI systems** with formal safety guarantees
- **Natural language to formal proof** translation

## Learn More

- **Specification**: See `mcp-coq-lsp/MCP_COQ_LSP_SPEC.md`
- **Implementation**: See `mcp-coq-lsp/IMPLEMENTATION.md`
- **Quick Start**: See `mcp-coq-lsp/QUICKSTART.md`
- **Coq Documentation**: https://coq.inria.fr/
- **coq-lsp Project**: https://github.com/ejgallego/coq-lsp

## Contributing

This is a research prototype demonstrating neurosymbolic programming principles. Contributions welcome:
- Add support for other proof assistants (Lean, Isabelle)
- Improve tactic suggestion heuristics
- Build benchmark suites for AI proof capabilities
- Develop training datasets from verified code

## License

MIT License - See LICENSE file for details

---

**Built with**: TypeScript, coq-lsp, Model Context Protocol

**Enables**: LLMs + Coq = Formally Verified AI-Assisted Programming
