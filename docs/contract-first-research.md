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

This is not a finished methodology. It is a research base and
starting point for iterative refinement.

---

## 2. The Core Insight: Three Layers of Specification

Most TDD guides collapse specification into two layers — tests and
code. The research and the Lingua principles independently converge
on **three distinct layers**, each in a different medium and serving
a different purpose:

### Layer 1 — Intent (natural language)

What should this function do, and why? Expressed as:

- Roxygen blocks (R packages)
- Docstrings (Python)
- Lingua's "contract comments" (language-agnostic fallback)
- Spec documents (SDD / Spec Kit methodology)

This is where **domain knowledge** lives. An LLM cannot invent this
layer — it comes from the human. But once written, it constrains
everything downstream.

### Layer 2 — Behaviour (executable tests)

Given specific inputs, what outputs do I expect? Expressed as:

- `testthat` expectations (R)
- `pytest` assertions (Python)
- Property-based tests (Hypothesis, fast-check)

This is where **verification** lives. Tests are derivable from
the intent layer — if the Roxygen says `@param K_s Must be
positive`, the test follows: negative values must be rejected.

### Layer 3 — Implementation (code)

The actual algorithm. This is what the LLM is best at generating,
and what it should generate *last*, after layers 1 and 2 are in
place.

### Why three layers matter

Without the intent layer, the LLM can write tests that validate
whatever the code happens to do — "marking its own homework"
(Codemanship). Without the behaviour layer, the intent layer is
unverified prose. The three-layer stack creates a chain:

> Human writes intent → intent generates test expectations →
> tests constrain implementation → implementation is verified
> against both intent and tests.

Each layer is in a different medium (prose, assertions, code),
which means errors in one layer are visible from another. A
function whose Roxygen says it returns a tibble but whose test
expects a list exposes a contradiction *in language*, which is
where both humans and LLMs catch errors most reliably.

---

## 3. TDD with LLM Coders — Research Summary

### The red-green-refactor cycle adapted for LLMs

Traditional TDD follows a tight loop: write a failing test (red),
write minimal code to pass it (green), clean up (refactor). With
an LLM coder, the cycle adapts:

- **Red phase (human):** Write one failing test that defines one
  specific behaviour. This should almost always be human-authored
  because the test *is* the specification. Use descriptive test
  names that read like requirements.
- **Green phase (LLM):** Feed the failing test to the LLM with a
  clear prompt: "Write the minimal implementation to make this
  pass. Do not modify the tests." Run the test immediately — never
  trust the LLM's claim that code works.
- **Refactor phase (collaborative):** Improve structure and
  readability with the safety net of passing tests. Verify all
  tests still pass after each change.

Source: Builder.io, "Test-Driven Development with AI";
Codemanship, "Why Does TDD Work So Well in AI-Assisted
Programming?" (Jan 2026); The New Stack, "Claude Code and the
Art of Test-Driven Development."

### Why TDD matters more with LLMs than without

LLMs are probabilistic — they generate the most plausible-looking
code, not the most correct code. Key findings:

- **Broken code in context pollutes subsequent predictions.**
  Jason Gorman (Codemanship) found that once an LLM generates a
  bug, every subsequent interaction builds on that buggy
  foundation. TDD catches bugs before they enter context.
- **LLMs cannot distinguish working code from broken code** — it
  is all text in their context window. Tests provide a
  deterministic verification layer over probabilistic output.
- **TDD produces 40%–80% fewer bugs** than test-after approaches
  in traditional development (Eric Elliott, citing multiple
  studies). The gap is likely larger with LLM-generated code.
- **Context limits are smaller than advertised.** LLM accuracy
  drops well before the nominal context window is exhausted.
  TDD's one-problem-at-a-time approach keeps context small and
  focused, directly improving code quality.

Source: Addy Osmani, "My LLM Coding Workflow Going Into 2026";
Honeycomb, "How I Code with LLMs These Days"; Eric Elliott,
"Better AI Driven Development with TDD."

### The "marking your own homework" problem

When you let an AI write code and then ask it to write tests for
that code, it generates tests that validate whatever the code
already does — bugs included. David Eastman (The New Stack)
demonstrated this with Claude Code: the AI interpreted a daily
interest rate of 0.05 as 5% rather than 0.05%, and tests written
after the fact would have confirmed this incorrect behaviour.

This is the central argument for human-authored tests and,
more broadly, for the intent layer preceding both tests and
implementation.

Source: The New Stack, "Claude Code and the Art of TDD"; DEV.to,
Matti Bar-Zeev, "Why Testing After with AI Is Even Worse."

### Five major pitfalls

1. **Test modification trap.** LLMs modify tests to match buggy
   code instead of fixing the code. Kent Beck reported AI agents
   deleting tests to make them pass. Prevention: lock test files,
   commit tests before implementation, use explicit instructions
   ("NEVER modify test files").

2. **Mocks that hide real bugs.** LLMs generate extensive mocks
   that don't represent actual system behaviour. Prevention:
   minimise mocking, prefer integration tests, verify mocks match
   real API contracts.

3. **Overfitting to test cases.** Code passes specific tests
   without implementing a correct general solution. A Rust rewrite
   of SQLite passed tests but ran 20,000× slower because it
   satisfied cases without proper algorithms. Prevention:
   property-based testing, performance benchmarks, unhappy-path
   tests.

4. **Testing implementation, not behaviour.** LLM-generated tests
   couple to *how* code works rather than *what* it does, breaking
   on every refactor. Prevention: test observable inputs and
   outputs, not internal state.

5. **Trivially passing tests.** LLMs write tests that inflate
   coverage metrics without catching real faults — renaming test
   methods, testing already-covered lines. Mutation testing shows
   LLM-generated tests achieve only ~40% mutation kills.
   Prevention: use mutation testing tools, always verify the red
   phase.

Source: Compiled from Codemanship, DEV.to (Bar-Zeev),
Cybercorsairs, and Swagata Acharyya (Goodhart's LLM Principle).

### Property-based testing

Property-based testing (PBT) defines invariants that must hold
for *all* inputs, then generates random inputs to verify.
Research from Beihang University introduced the Property-Generated
Solver framework, showing 23%–37% improvements in code correctness
over traditional TDD with example-based tests.

PBT "breaks the cycle of self-deception" — when an LLM generates
both code and example-based tests, they often share the same
flawed assumptions. Properties are harder to game because they
describe fundamental truths about behaviour.

Practical frameworks: Hypothesis (Python), fast-check
(JavaScript), no mature equivalent in base R (but `hedgehog` and
`quickcheck` packages exist).

Source: arXiv 2506.18315, "Use Property-Based Testing to Bridge
LLM Code Generation and Validation."

---

## 4. Specification-Driven Development — Research Summary

### Spec Kit and the SDD methodology

GitHub released Spec Kit (open source, Sep 2025) formalising
specification-driven development for AI coding workflows. The
core principle: specifications are the source of truth; code is a
derived artifact.

The workflow has four gated phases:

1. **Specify** — define goals, user journeys, acceptance criteria
   in natural language. The AI helps draft; the human refines.
2. **Plan** — declare architecture, tech stack, constraints. The
   AI proposes a technical plan respecting organisational patterns.
3. **Tasks** — break the plan into small, reviewable,
   independently testable units.
4. **Implement** — the AI generates code for each task, guided by
   the spec and plan.

Each phase has explicit checkpoints. You do not advance until the
current phase is validated.

Source: GitHub Blog, "Spec-Driven Development with AI" (Sep 2025);
github.com/github/spec-kit; Microsoft Developer Blog, "Diving
Into Spec-Driven Development With GitHub Spec Kit."

### Why specifications help LLMs

- **LLMs are non-deterministic.** Identical prompts produce
  varying outputs. A spec anchors the output to a stable
  reference.
- **Code is a poor medium for requirements negotiation.** Once
  you write implementation, it is hard to decouple from it.
  Specs separate the "what" from the "how."
- **Specs reduce tangential mistakes.** When the AI knows exactly
  which part of the spec it is implementing, it produces more
  focused, reliable code.
- **Specs survive tool switching.** A spec that lives outside the
  IDE can be used with Claude Code, Cursor, Copilot, or any
  future tool.

Source: GitHub Blog (above); IntuitionLabs, "GitHub Spec Kit:
A Guide to Spec-Driven AI Development."

### Documentation-first as the micro-level version

Spec-driven development operates at the project level.
Documentation-first development operates at the function level.
Same principle, different scale:

> "Documentation-first development approaches will gain
> popularity, where developers write comprehensive docstrings
> before implementing functions — enabling AI assistants to
> generate implementation drafts based on the specifications."
> — Ashish Mishra, "Beyond Human Eyes: How Docstrings Are
> Becoming the Interface Between Your Code and AI Agents"

The parallel is precise: a Roxygen block above an R function is a
micro-spec. It defines intent, inputs, outputs, and domain rules.
An LLM reading that block has everything it needs to generate or
verify the implementation.

### Linters and type systems as executable specs

Factory.ai argues that linters, type annotations, and
documentation signals function as machine-enforced guarantees:

> "Linters turn human intent into machine-enforced guarantees
> that allow agents to plan, generate, and self-correct without
> waiting on humans."

In R, this role is partially filled by Roxygen (documentation
contracts), `stopifnot` / `match.arg` (runtime type checking at
the boundary), and `lintr` / `styler` (style enforcement). R
lacks a static type system, making the Roxygen contract more
important — it is the primary way parameter semantics are declared.

Source: Factory.ai, "Using Linters to Direct Agents."

---

## 5. The Lingua Principles — How They Connect

The **Lingua** document articulates a set of principles for
LLM-collaborative development, addressed to the model as a
collaborator. It was developed independently of the TDD/SDD
literature but converges on the same conclusions from a more
fundamental starting point: LLMs are language machines, so the
development process should stay in language as long as possible.

### Key principles and their connections

**§0 — The Nature of the Tool.** LLMs are language machines.
Code that reads like language is code they can reason about.
This is the theoretical foundation that SDD, TDD, and
documentation-first practices all rest on without always
articulating.

**§1 — Context Over Memory.** Treat training as a map, not the
territory. Load documentation into context every time. This
addresses the hallucination problem that makes TDD necessary —
LLMs reconstruct plausible-sounding details that may be wrong.

**§2 — Discuss Before Coding.** Reason in natural language first.
This is the intent layer: clarify what a task requires, decompose
the problem, surface edge cases, propose the approach and invite
pushback — all before any code is written. This maps directly
onto SDD's Specify phase and onto the practice of writing
Roxygen/docstrings before implementation.

**§3 — Write Code That Is Language (revised).** The revised
version introduces **contract comments** — a natural-language
description of the function's role, placed at every function
boundary. The contract should communicate purpose, the shape of
inputs and outputs, and any key decisions or domain rules the
function encodes. The exact format is determined by the language
dialect: Roxygen in R packages, docstrings in Python, structured
comments in scripts. What matters is the principle — that a
contract exists, that it defines semantic responsibility, and
that it should remain true even if implementation changes.

**§4 — Small, Pure, Atomic Functions.** Each function does one
thing, takes explicit inputs, returns a result without side
effects. This makes each function independently testable and
independently specifiable — one contract, one test, one
implementation.

**§5 — Record Decisions.** Without recorded decisions, the LLM
re-derives or second-guesses choices already made. Roxygen
`@references` tags, commit messages, and decision logs serve
this purpose. In a contract-first workflow, the contract itself
*is* a recorded decision about what the function should do.

**§7 — The Collaboration Is the Product.** The output is not just
code — it is code + conversation + references + tests. This
framing naturally incorporates all three specification layers.

### The Lingua insight the broader community is catching up to

Lingua §3 says: "A comment that states intent next to code that
implements it creates a verifiable contract. If the implementation
does not match the stated intent, the mismatch is a signal."

This is the mechanism underlying both TDD and SDD, stated more
precisely than most practitioners articulate it. The mismatch
between natural-language intent and code behaviour is the
debugging signal — and it works because natural language is where
both humans and LLMs are strongest at detecting contradictions.

---

## 6. The R Development Principles — Roxygen as the Bridge

The **R Development Principles** document translates Lingua's
abstractions into concrete R practices. Key sections relevant to
the contract-first workflow:

### Roxygen (§13) — the contract mechanism in R

A Roxygen block is simultaneously:

- **A specification** — `@param` entries define the contract for
  what inputs mean in the domain. `@return` defines expected
  output structure. `@details` records key decisions.
- **A prompt** — an LLM reading a complete Roxygen block has
  everything needed to generate or verify the implementation.
- **A contract in the Lingua sense** — if the Roxygen says the
  function returns a tibble with columns `time`, `depth`, and
  `value`, and the implementation returns something else, the
  contradiction is visible in language.
- **A test scaffold** — parameter constraints ("Must be positive")
  directly imply testthat expectations. `@examples` are
  executable code checked by `R CMD check`.

Example from the document:
```r
#' @param K_s Saturated hydraulic conductivity (m/s). Must be positive.
```
vs.
```r
#' @param K_s A numeric value.
```

The first is a domain contract. The second is noise. The first
generates a test (`expect_error` for negative values) and
communicates domain meaning to the LLM. The second does neither.

### Testing (§12) — the verification mechanism

The document prescribes testthat 3e with several practices that
align with TDD/contract-first:

- Test helpers directly (not just through the orchestrator)
- Test observable behaviour, not implementation details
- Use snapshot tests for conditions rather than fragile regex
- Validate that boundary checks catch invalid input

### Pure functions (§2) and one-job functions (§3) — testability

These principles create functions that are independently
specifiable and independently testable. A pure function with
explicit inputs and a single responsibility maps to exactly one
Roxygen block and one set of tests.

### The structural observation

The R principles document currently orders sections as: pure
functions → naming → composition → testing → Roxygen. In a
contract-first workflow, the *conceptual* order would be:
Roxygen (define the contract) → testing (verify the contract) →
implementation (satisfy both). This does not necessarily require
reordering the document, but the workflow guidance should make
the intended sequence clear: **write the Roxygen block first,
derive tests from it, then implement.**

---

## 7. The Emerging Workflow

Based on all of the above, the workflow that these principles
and research point toward:

### For each function:

1. **Write the Roxygen block** (in R) or contract comment (in
   scripts). Title line states purpose. `@param` entries describe
   inputs with domain semantics and constraints. `@return`
   describes expected output. `@details` or `@note` records key
   decisions and assumptions. `@references` cites methods.

2. **Write the function signature** with the Roxygen block
   attached. The function body is empty or contains a
   placeholder.

3. **Derive tests from the contract.** Each constraint in the
   Roxygen implies a test. "Must be positive" → test negative
   values are rejected. "Returns a tibble with columns x, y, z"
   → test the output structure. "Sentinel rows are identified
   by all-zero values" → test with known sentinel patterns.

4. **Run the tests and confirm they fail** (red phase). This
   verifies the tests are meaningful and not trivially passing.

5. **Implement** (green phase). Write the code — or ask the LLM
   to write it, providing the Roxygen block and failing tests as
   context. The prompt: "Here is the documentation and the
   failing tests. Write the implementation. Do not modify the
   tests or the Roxygen."

6. **Run tests and confirm they pass** (green). If they fail,
   feed the error back to the LLM and iterate.

7. **Refactor** with tests as safety net. Clean up, improve
   naming, simplify logic. Verify tests still pass.

8. **Commit on green.** If subsequent changes break tests, revert
   to the last working commit.

### For the project level:

- Before starting a feature, discuss the approach in natural
  language (Lingua §2). Clarify requirements, decompose the
  problem, surface edge cases.
- Write a brief spec or design note for non-trivial features
  (Lingua §5, SDD Specify phase).
- Break work into small, independently testable units (SDD
  Tasks phase, Lingua §4).

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

## 8. The Package Question

Adopting this workflow in R strongly favours the package
structure, even for personal or single-project work:

- `roxygen2::roxygenise()` turns Roxygen blocks into `.Rd` help
  pages and manages `NAMESPACE`.
- `devtools::load_all()` makes internal helpers available for
  testing without exporting them.
- `devtools::test()` runs the testthat suite.
- `devtools::check()` validates the whole package including
  examples in Roxygen blocks.
- `usethis::use_test("read")` scaffolds test files mirroring
  source files.

The transition from a script-based project to a package is
primarily a directory reorganisation:

```
myproject/
  R/           <- .R files move here
  man/         <- generated by roxygen2
  tests/
    testthat/  <- test files
  DESCRIPTION  <- package metadata
  NAMESPACE    <- generated by roxygen2
```

`usethis::create_package("myproject")` handles the scaffolding.
This is a structural change, not a conceptual one — the code
does not need to be rewritten.

---

## 9. Open Questions for the Project

These are the areas where the workflow needs refinement through
practice:

1. **Roxygen-first in practice.** How does writing the Roxygen
   block before the implementation actually feel in daily R work?
   What friction points emerge? Does it change how functions are
   decomposed?

2. **Test derivation.** How mechanically can tests be derived from
   Roxygen blocks? Is there a reliable pattern for translating
   `@param` constraints into `testthat` expectations, or does
   each case require fresh thinking?

3. **Contract granularity.** How detailed should the Roxygen block
   be for internal helpers vs. exported functions? The R
   principles doc says internal helpers trust their inputs — does
   that mean they need lighter contracts?

4. **The Lingua ↔ R principles relationship.** Lingua §3 defines
   the principle that every function gets a contract at its
   boundary. The R principles should say: "In R packages, the
   contract is a Roxygen block. In scripts, use a structured
   comment covering purpose, inputs/outputs, and key decisions."
   How prescriptive should the script-level format be, or is the
   content requirement sufficient?

5. **Property-based testing in R.** The PBT research shows large
   improvements for LLM-generated code. R's PBT ecosystem
   (`hedgehog`, `quickcheck`) is less mature than Python's
   Hypothesis. Is it worth incorporating, or do well-written
   example-based tests suffice for now?

6. **Workflow tooling.** What does the actual keystroke-level
   workflow look like? Open the R file, write Roxygen, run
   `devtools::document()`, open the test file, write tests,
   run `devtools::test()`, then implement? Or is there a more
   fluid sequence?

7. **Conversation as artifact.** Lingua §7 says the conversation
   is part of the product. How should design discussions and
   decision rationale from chat sessions be captured and loaded
   into future sessions? Decision logs? Markdown files in the
   project? Comments in the code?

---

## 10. Key References

### TDD with LLMs

- Eric Elliott, "Better AI Driven Development with Test Driven
  Development" (Medium / Effortless Programming)
- Codemanship, "Why Does Test-Driven Development Work So Well
  in AI-Assisted Programming?" (Jan 2026)
  https://codemanship.wordpress.com/2026/01/09/why-does-test-driven-development-work-so-well-in-ai-assisted-programming/
- David Eastman / The New Stack, "Claude Code and the Art of
  Test-Driven Development"
  https://thenewstack.io/claude-code-and-the-art-of-test-driven-development/
- Matti Bar-Zeev / DEV.to, "Why Testing After with AI Is Even
  Worse"
  https://dev.to/mbarzeev/why-testing-after-with-ai-is-even-worse-4jc1
- 8th Light, "TDD: The Missing Protocol for Effective AI
  Assisted Collaboration"
  https://8thlight.com/insights/tdd-effective-ai-collaboration
- Rotem Tamir, "Harnessing LLMs with TDD"
  https://rotemtam.com/2024/10/18/harnessing-llms-with-tdd/
- The Pragmatic Engineer, "TDD, AI Agents and Coding with
  Kent Beck"
  https://newsletter.pragmaticengineer.com/p/tdd-ai-agents-and-coding-with-kent
- Swagata Acharyya, "Goodhart's LLM Principle" (Medium)

### Spec-driven development

- GitHub Blog, "Spec-Driven Development with AI: Get Started
  with a New Open Source Toolkit" (Sep 2025)
  https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/
- GitHub, Spec Kit repository
  https://github.com/github/spec-kit
- Microsoft Developer Blog, "Diving Into Spec-Driven
  Development With GitHub Spec Kit"
  https://developer.microsoft.com/blog/spec-driven-development-spec-kit
- IntuitionLabs, "GitHub Spec Kit: A Guide to Spec-Driven AI
  Development"

### Documentation-first and contract-based approaches

- Ashish Mishra, "Beyond Human Eyes: How Docstrings Are
  Becoming the Interface Between Your Code and AI Agents"
  (Medium, May 2025)
- Factory.ai, "Using Linters to Direct Agents"
  https://factory.ai/news/using-linters-to-direct-agents
- Addy Osmani, "My LLM Coding Workflow Going Into 2026"
  https://addyosmani.com/blog/ai-coding-workflow/
- Honeycomb, "How I Code with LLMs These Days"
  https://www.honeycomb.io/blog/how-i-code-with-llms-these-days
- Harper Reed, "My LLM Codegen Workflow ATM"
  https://harper.blog/2025/02/16/my-llm-codegen-workflow-atm/

### Property-based testing with LLMs

- arXiv 2506.18315, "Use Property-Based Testing to Bridge LLM
  Code Generation and Validation"
- arXiv 2307.04346, "Can Large Language Models Write Good
  Property-Based Tests?"

### AI coding pitfalls

- Cybercorsairs, "Why LLM-Generated Code Fails: Testing Best
  Practices" (the SQLite/Rust 20,000× performance case)
  https://cybercorsairs.com/when-llm-code-looks-right-but-runs-20000x-wrong/
- monday.com engineering, "Coding with Cursor? Here's Why You
  Still Need TDD"
  https://engineering.monday.com/coding-with-cursor-heres-why-you-still-need-tdd/
- Testkube, "Hidden Risks of AI-Generated Code & How to Catch
  Them"
  https://testkube.io/blog/testing-ai-generated-code

### Tools

- TDD Guard for Claude Code (automated TDD enforcement)
  https://github.com/nizos/tdd-guard
- alexop.dev, "Forcing Claude Code to TDD: An Agentic
  Red-Green-Refactor Loop"
  https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/
- aihero.dev, "My Skill Makes Claude Code GREAT At TDD"
  https://www.aihero.dev/skill-test-driven-development-claude-code

### Foundational (R ecosystem)

- Wickham, H. (2019). *Advanced R* (2nd ed.)
  https://adv-r.hadley.nz/
- Wickham, H. (2015). *R Packages* (2nd ed.)
  https://r-pkgs.org/
- testthat 3e documentation
  https://testthat.r-lib.org/
- roxygen2 documentation
  https://roxygen2.r-lib.org/

### Project documents (to be loaded alongside this summary)

- **Lingua** — principles for LLM-collaborative development
  (language-agnostic)
- **R Development Principles** — R-specific translation of
  Lingua, including Roxygen and testing conventions

---

## Appendix A: Contract Comments at Function Boundaries

The core principle from Lingua §3 is that every reusable or
non-trivial function should have a **contract** in natural language
at its boundary — a statement of what the function does, what it
accepts and returns, and what domain rules or assumptions it
encodes.

The contract should communicate three things:

- **Purpose** — the function's role in the workflow
- **Inputs and outputs** — what goes in and what comes out, with
  domain meaning
- **Key decisions** — assumptions, algorithm choices, or domain
  rules that shaped the implementation

How this is expressed depends on the language and project context.
Lingua does not prescribe a single format — it defines the
*content* of the contract and delegates the *form* to the
language-specific guide.

### In R packages — Roxygen

```r
#' Split rows into logical groups separated by sentinel markers
#'
#' @param rows List of parsed row vectors from a single time block.
#' @return A list of matrices, one per variable group.
#'
#' @details Sentinel rows are identified by all-zero values.
#'   These are format artifacts, not physical data.
```

### In scripts or languages without a documentation system

A structured comment block covering the same content. The exact
format should be adapted to the project's conventions rather than
prescribed rigidly:

```
# Split rows into logical groups separated by sentinel markers.
# rows (list of row vectors) -> list of matrices, one per group.
# Sentinel rows are identified by all-zero values (format artifacts, not data).
```

### The relationship

**Lingua defines the grammar** — every function gets a contract
at its boundary. **Language-specific guides define the dialect** —
in R packages, the contract is a Roxygen block; in Python, a
docstring; in scripts, a structured comment. The kernel does not
hardwire a format because the right form depends on context.

---

## Appendix B: Workflow Diagram (Conceptual)

```
  ┌─────────────────────────────────────────────┐
  │         DISCUSSION (Lingua §2)              │
  │  Clarify requirements, decompose problem,   │
  │  surface edge cases, propose approach        │
  └──────────────────┬──────────────────────────┘
                     │
                     ▼
  ┌─────────────────────────────────────────────┐
  │      INTENT LAYER — Write the Contract      │
  │  Roxygen block (R) / docstring (Python) /   │
  │  contract comment (scripts)                 │
  │                                             │
  │  Purpose, inputs, outputs, domain rules,    │
  │  references                                 │
  └──────────────────┬──────────────────────────┘
                     │
                     ▼
  ┌─────────────────────────────────────────────┐
  │    BEHAVIOUR LAYER — Write Failing Tests    │
  │  Derive expectations from the contract:     │
  │  - typical input → expected output          │
  │  - constraints → error on violation         │
  │  - edge cases → correct handling            │
  │                                             │
  │  Run tests, confirm RED (they fail)         │
  └──────────────────┬──────────────────────────┘
                     │
                     ▼
  ┌─────────────────────────────────────────────┐
  │   IMPLEMENTATION LAYER — Write the Code     │
  │  LLM generates, constrained by contract     │
  │  and tests. Prompt: "Here is the Roxygen    │
  │  and the failing tests. Implement. Do not   │
  │  modify the tests or the documentation."    │
  │                                             │
  │  Run tests, confirm GREEN (they pass)       │
  └──────────────────┬──────────────────────────┘
                     │
                     ▼
  ┌─────────────────────────────────────────────┐
  │          REFACTOR — Clean Up                │
  │  Improve structure under test safety net.   │
  │  Commit on green. Revert on red.            │
  └──────────────────┬──────────────────────────┘
                     │
                     ▼
  ┌─────────────────────────────────────────────┐
  │      RECORD — Capture Decisions             │
  │  Commit message, decision log, or inline    │
  │  comments recording what was decided and    │
  │  why. Load next session.                    │
  └─────────────────────────────────────────────┘
```

---

*This document was compiled from an extended research conversation
in March 2026. It should be loaded into a Claude project alongside
the Lingua and R Development Principles documents as the shared
context for refining this workflow into daily practice.*
