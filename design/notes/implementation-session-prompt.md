# Session Prompt: Build an Implementation Skill for the DDD Paradigm

*Paste this into a new Claude Desktop chat within the ddd project.
All project knowledge docs should be loaded.*

---

## Context

You are joining an ongoing project to develop a contract-first,
test-driven workflow for LLM-collaborative R development. The project
is called `ddd` (doc-driven design) and lives in an R package. The
guiding documents are in project knowledge:

- **lingua.md** — principles for LLM-collaborative development
- **R-development-principles.md** — R-specific coding conventions
- **contract-first-development-with-llms.md** — the full workflow
- **three-gear-workflow.md** — exploration → design → contract-first
- **applied-science-workflow.md** — the working context
- **ddd-progress.md** — project history and architecture

Read these before doing anything. They are the shared grammar.

## What has been done

1. **Roxygen contract written** for `tally_runs()` in `R/tally_runs.R`.
   The function tallies sequential runs above or below a threshold in
   a time series, partitioned by water year, calendar year, or custom
   season. The contract is complete — `@param`, `@return`, `@details`
   with NA behaviour, period partitioning, and input validation.

2. **49 testthat 3e tests derived** from the contract by a zero-context
   agent. They are in `tests/testthat/test-tally_runs.R`. All 49 tests
   fail (RED phase confirmed) because the function body is a stub.

3. **A test-derivation skill** was built at
   `design/skills/test-from-contract/`. It generalises the prompt and
   methodology used for the test derivation step.

4. **Design notes** in `design/notes/` capture:
   - The test derivation prompt used (`test-derivation-prompt-tally-runs.md`)
   - A note on contract iteration after implementation
     (`contract-iteration-after-implementation.md`)
   - The Gear 2 design questions for run-length analysis
     (`gear2-run-length-prompt.md`, `run-length-design-decisions.md`)

## What needs to happen now

### Step 0: Validate the test-derivation skill (before implementation)

Run the generalized test-derivation skill
(`design/skills/test-from-contract/`) against the same `tally_runs()`
Roxygen block that the bespoke prompt was originally run against.
Compare the output to the existing 49 tests in
`tests/testthat/test-tally_runs.R`.

This is a proof run for the skill itself. Differences between the
skill's output and the original bespoke-prompt output reveal where
the generalization lost specificity or gained something new.
Document the comparison in `design/notes/`.

Do NOT overwrite the existing test file. Write the skill's output
to a separate file (e.g., `design/notes/skill-validation-tests.R`)
for comparison only.

### Step 1: Implement `tally_runs()` to pass all 49 tests

This is the GREEN phase. The function stub in `R/tally_runs.R` needs
a real implementation. The constraints:

- **The Roxygen block is the contract. Do not modify it.**
- **The tests define correctness. Do not modify them.**
- **Follow R-development-principles.md exactly.** Pure functions,
  one job per function, verb-noun names, purrr over apply, pipes for
  sequences, validate at the boundary, I/O at the boundary.
- **Follow lingua.md.** Discuss before coding. Name functions as ideas.
  Comment intent not mechanics. Make the orchestrator read like a
  narrative.
- **Decompose into helpers.** The contract is for the public function.
  Internal helpers will emerge — period assignment, run detection,
  validation, duration calculation. Each helper should be pure, named,
  and co-located in `R/tally_runs.R`.
- **Run tests frequently.** After writing validation, run the
  validation tests. After writing run detection, run those tests.
  Build incrementally, confirming GREEN as you go.

### Step 2: Build an implementation skill

After implementing `tally_runs()`, we want to generalise the process
into a reusable skill for an independent agent — analogous to the
test-derivation skill at `design/skills/test-from-contract/`.

The implementation skill should codify:

- How to read a Roxygen contract + failing tests as the specification
- How to decompose into helpers following R-development-principles.md
- How to build incrementally (validate first, then core logic, then
  edge cases)
- How to write contracts for helpers that emerge
- How to run tests after each increment
- What to report back (which tests pass, which fail, any contract
  gaps or ambiguities discovered during implementation)

The skill lives at `design/skills/implement-from-contract/` and follows
the same structure as `test-from-contract/` (SKILL.md + references/).

### Step 3: Evaluate the tests

Once all 49 tests are GREEN, evaluate test quality:

1. **`covr::package_coverage()`** — confirm the tests exercise all
   the implementation code. Report uncovered lines.
2. **`muttest::muttest()`** (if available) — score how well the
   assertions catch real bugs. Report surviving mutants.

This evaluation feeds back into the test-derivation skill — weak
spots in the tests reveal where the skill's guidance was insufficient.

## How to work

- **You are in Gear 3.** Full contract-first discipline. Roxygen
  first (already done), tests from contract (already done),
  implementation last (your job).
- **Read `CLAUDE.md`** in the project root for Gear 3 directives.
- **Discuss the decomposition before coding.** Propose the helper
  functions, their names, their responsibilities. Get alignment
  before writing code.
- **Commit on GREEN.** If tests pass, that's a save point.
- **The human is new to testing.** Explain what's happening as you
  go — which tests are passing, what that means, what's next. Keep
  explanations short and concrete.

## Starting point

1. Read the project knowledge docs (lingua, R principles, contract-first).
2. Read `design/skills/test-from-contract/` — the generalized skill.
3. Run the skill against `R/tally_runs.R` (Step 0 validation).
4. Compare output to `tests/testthat/test-tally_runs.R`, document.
5. Read `design/notes/contract-iteration-after-implementation.md`.
6. Propose the decomposition: which helpers, what each one does.
7. Discuss, then implement.
