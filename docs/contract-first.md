# Contract-First Development with LLMs

*An annotated research summary and working framework for developing a
practical specification-driven, test-verified workflow for
LLM-collaborative coding. This document is the kernel of a project to
refine these ideas into daily practice.*

---

## 1. What This Document Is

This summarises an extended research conversation covering
test-driven development (TDD) with LLM coders, specification-driven
development (SDD), documentation-first workflows, and how all of
these converge with a set of independently developed principles for
LLM-collaborative coding (the **Lingua** principles and a companion
**R Development Principles** document).

The goal is a practical workflow where:

- **Natural-language contracts** (Roxygen blocks, docstrings,
  structured comments) define what each function does, what it
  accepts, and what domain rules it encodes — *before implementation
  begins*.
- **Executable tests** verify those contracts behaviourally —
  *before or alongside implementation*.
- **Implementation** is the last step, often delegated to the LLM,
  constrained by the contract and validated by the tests.

---

## 2. The Core Insight: Three Layers of Specification

### Layer 1 — Intent (natural language)

What should this function do, and why? Expressed as Roxygen blocks,
docstrings, or contract comments. This is where **domain knowledge**
lives. An LLM cannot invent this layer — it comes from the human.

### Layer 2 — Behaviour (executable tests)

Given specific inputs, what outputs do I expect? Expressed as
`testthat` expectations or `pytest` assertions. Tests are derivable
from the intent layer — if the Roxygen says `@param K_s Must be
positive`, the test follows: negative values must be rejected.

### Layer 3 — Implementation (code)

The actual algorithm. This is what the LLM is best at generating,
and what it should generate *last*, after layers 1 and 2 are in place.

### Why three layers matter

Without the intent layer, the LLM can write tests that validate
whatever the code happens to do — "marking its own homework." Without
the behaviour layer, the intent layer is unverified prose. The
three-layer stack creates a chain:

> Human writes intent → intent generates test expectations →
> tests constrain implementation → implementation is verified
> against both intent and tests.

---

## 3. The Workflow

### For each function:

1. **Write the Roxygen block** before the function body exists.
   Title states purpose. `@param` entries carry domain semantics
   and constraints. `@return` describes output. `@details` records
   key decisions.

2. **Write the function signature** with the Roxygen block attached.
   Body is empty or placeholder.

3. **Derive tests from the contract.** Each constraint implies a test.
   "Must be positive" → test negative values are rejected.
   "Returns a tibble with columns x, y, z" → test output structure.

4. **Run tests and confirm RED.** This verifies the tests are
   meaningful and not trivially passing.

5. **Implement** — write the code, or ask the LLM to write it,
   providing the Roxygen block and failing tests as context.
   Prompt: "Here is the documentation and the failing tests.
   Write the implementation. Do not modify the tests or the Roxygen."

6. **Run tests and confirm GREEN.**

7. **Refactor** with tests as safety net. Commit on green.

8. **Record decisions** in commit message, decision log, or inline
   comments.

### What the human owns vs. what the LLM helps with:

| Step | Human | LLM |
|------|-------|-----|
| Roxygen / contract | Author (domain knowledge required) | Can draft from discussion, human refines |
| Test expectations | Author (defines "correct") | Can suggest additional edge cases |
| Test scaffolding | — | Generates boilerplate |
| Implementation | Reviews and approves | Generates, constrained by contract + tests |
| Refactoring | Directs intent | Executes under test safety net |
| Decision recording | Decides what to record | Helps draft commit messages, comments |

---

## 4. Why TDD Matters More with LLMs

- **Broken code in context pollutes subsequent predictions.** Once
  an LLM generates a bug, every subsequent interaction builds on
  that buggy foundation. TDD catches bugs before they enter context.
- **LLMs cannot distinguish working code from broken code** — it is
  all text. Tests provide a deterministic verification layer over
  probabilistic output.
- **The "marking your own homework" problem.** When you let an AI
  write code and then ask it to write tests for that code, it
  generates tests that validate whatever the code already does —
  bugs included. Human-authored tests and the intent layer
  preceding both tests and implementation prevent this.

### Five major pitfalls

1. **Test modification trap.** LLMs modify tests to match buggy code.
   Prevention: lock test files, commit tests before implementation,
   use explicit instructions ("NEVER modify test files").

2. **Mocks that hide real bugs.** Prevention: minimise mocking,
   prefer integration tests.

3. **Overfitting to test cases.** Code passes specific tests without
   implementing a correct general solution. Prevention:
   property-based testing, unhappy-path tests.

4. **Testing implementation, not behaviour.** Prevention: test
   observable inputs and outputs, not internal state.

5. **Trivially passing tests.** Prevention: always verify the red
   phase. A test that was never red is unverified.

---

## 5. Key References

- Codemanship, "Why Does TDD Work So Well in AI-Assisted Programming?" (Jan 2026)
  https://codemanship.wordpress.com/2026/01/09/why-does-test-driven-development-work-so-well-in-ai-assisted-programming/
- David Eastman / The New Stack, "Claude Code and the Art of TDD"
  https://thenewstack.io/claude-code-and-the-art-of-test-driven-development/
- GitHub Blog, "Spec-Driven Development with AI" (Sep 2025)
  https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/
- arXiv 2506.18315, "Use Property-Based Testing to Bridge LLM Code Generation and Validation"
- Addy Osmani, "My LLM Coding Workflow Going Into 2026"
  https://addyosmani.com/blog/ai-coding-workflow/
