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

## 3. Contract Coverage and Agentic Inter-Rater Reliability

Code coverage (`covr`) measures which lines tests execute. Mutation
testing measures whether tests catch injected bugs. Neither measures
**contract coverage** — whether the tests actually verify what the
specification promised.

### The technique

Run the test-derivation skill multiple times (two or three), each
in a clean context with no memory of prior runs, all working from
the same Roxygen contract. Compare the outputs:

- **Tests that appear in all runs** are high-confidence — the
  contract clearly implies them.
- **Tests unique to one run** are candidates for review — either
  the contract was ambiguous or one agent was more thorough.
- **Contract clauses that no run tested** signal the contract is
  underspecified.

The convergence pattern *is* the coverage audit. Divergences point
directly to ambiguous clauses, undertested constraints, or places
where the contract needs to say more.

### Experimental results (2026-03-22)

Three independent Claude Code CLI agents (`claude -p`) ran the
`test-from-contract` skill against the `tally_runs()` Roxygen
contract. Each ran in headless mode with `--disallowedTools`
blocking access to the existing test file and design notes. File
access logs confirmed no contamination.

**Test counts:** 40, 41, 43 across three runs.

**33 test intents converged (3/3).** The high-confidence core.
About 80% of the test file is deterministic given the contract —
a single derivation run would capture it.

**~7 intents at majority (2/3) or singleton (1/3).** The 20%
divergence points directly to contract ambiguities and coverage
scope judgments.

**No contradictory expectations.** Where agents disagreed, it was
about whether to test something, not about what the correct answer
would be.

**Contract gaps flagged universally (3/3):**
- "Natural unit implied by the data's time step" — inference
  algorithm unspecified
- MMDD HHMM format interaction with Date-class input undefined

**Assumptions converged universally (3/3):**
- Duration = end − start (not record count)
- Valid `duration_units` = difftime units
- Water year convention follows USGS standard

These universal assumptions should be made explicit in the contract
rather than left for the implementer to infer.

### When to use it

**Worth doing for complex functions at contract-finalization time.**
"Complex" means multiple parameters, domain rules, non-obvious edge
cases — functions like `tally_runs()` with 7 parameters and period
logic. Two runs capture most of the value (divergence reveals
ambiguity). Three runs add majority-vote resolution.

**Not worth routinizing for every function.** For simpler functions
(like a unit conversion), a single derivation run suffices. The
technique is a calibration tool, not a daily practice.

**Cost:** Three runs × ~3 minutes each = ~10 minutes wall time.
Human review of the comparison is the real cost — about 30 minutes
for thorough analysis. Total: under 1 hour for a comprehensive
contract validation. Reasonable for functions at `tally_runs()`
complexity.

### Practical setup

The experiment infrastructure lives in `design/inter-rater/`. Key
files:
- `agent-prompt.md` — the prompt each agent receives, including
  a contamination disclosure requirement
- `run-inter-rater.sh` — shell script that invokes `claude -p`
  three times with `--allowedTools` and `--disallowedTools` flags
- `comparison-protocol.md` — analysis playbook
- `comparison-analysis.md` — results of the first experiment
- `test-disallowed-tools.sh` — toolchain verification script that
  confirmed the CLI flags work as expected

The `--disallowedTools` flag with path-scoped Read patterns
successfully blocks agents from reading contaminating files. The
file access log in each run's output provides an additional
verification layer.

---

## 4. The Workflow

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

### For complex functions: inter-rater validation after step 1

After writing the Roxygen block but before committing to tests and
implementation, run the test-derivation skill 2–3 times
independently. Use the divergences to tighten the contract before
proceeding. This catches ambiguities early, when they are cheapest
to fix.

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

## 5. Why TDD Matters More with LLMs

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

## 6. When Full Ceremony Earns Its Keep

The full contract-first cycle — Roxygen, test derivation, RED phase,
implementation, GREEN, refactor — is more ceremony than most daily
applied science work requires. Most work lives in exploration and
the applied analysis workflow: scripts, plots, composing existing
tools to answer questions about physical systems.

The full machinery fires when something crosses the threshold into
"this needs to be reliable across cases and worth keeping." That
is occasional by nature. The signals:

- The function will be reused across sites, projects, or time
- It encodes domain knowledge that is not obvious from the code
- Getting it wrong would produce silently incorrect results
- You are building a package, even if only for yourself

When that threshold is crossed, doing it right — contract first,
tests from the contract, implementation last — prevents the class
of errors that applied scientists are most vulnerable to: functions
that run without complaint but produce wrong numbers.

---

## 7. Key References

- Codemanship, "Why Does TDD Work So Well in AI-Assisted Programming?" (Jan 2026)
  https://codemanship.wordpress.com/2026/01/09/why-does-test-driven-development-work-so-well-in-ai-assisted-programming/
- David Eastman / The New Stack, "Claude Code and the Art of TDD"
  https://thenewstack.io/claude-code-and-the-art-of-test-driven-development/
- GitHub Blog, "Spec-Driven Development with AI" (Sep 2025)
  https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/
- arXiv 2506.18315, "Use Property-Based Testing to Bridge LLM Code Generation and Validation"
- Addy Osmani, "My LLM Coding Workflow Going Into 2026"
  https://addyosmani.com/blog/ai-coding-workflow/

---

*This document was compiled from extended research conversations in
March 2026. The inter-rater reliability section (§3) reports
experimental results from 2026-03-22. Load alongside the Lingua and
R Development Principles documents as the shared context for this
workflow.*
