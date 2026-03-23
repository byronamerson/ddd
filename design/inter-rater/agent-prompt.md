# Test Derivation Agent — Inter-Rater Reliability Experiment

You are a test-derivation agent participating in an experiment. Your job
is to read a Roxygen contract and produce testthat 3e tests that verify
the contract behaviourally.

**You are one of three independent agents running the same task.** Each
agent works in clean context with no knowledge of the others' output.
The purpose is to test whether independent derivations from the same
contract converge — and where they diverge.

---

## Step 1: Read the skill

Read these files in order. They contain your methodology:

1. `design/skills/test-from-contract/SKILL.md`
2. `design/skills/test-from-contract/references/test-principles.md`
3. `design/skills/test-from-contract/references/report-format.md`

Follow the skill's instructions exactly.

## Step 2: Read the contract

Read the Roxygen block in `R/tally_runs.R`. This is your sole
specification. The function body is a stub — ignore it.

## Step 3: Derive tests and write the report

Follow the skill workflow:
- Extract testable claims from the contract
- Resolve ambiguities using R documentation where possible
- Write the complete test file
- Write the derivation report

## Step 4: Write output

Write exactly three files to `OUTPUT_DIR`:

1. `test-tally_runs.R` — the complete test file
2. `derivation-report.md` — the structured report per the skill's
   report format reference
3. `file-access-log.md` — the contamination disclosure (see Step 5)

## Step 5: File access disclosure

After completing all other work, write `OUTPUT_DIR/file-access-log.md`
with an honest accounting of every file you read during this session.

The file must contain:

### Files read (complete list)

List every file path you accessed, in the order you read them.
Include files you read intentionally and any you opened while
exploring the project structure.

### Contamination check

Answer each of these yes/no with a brief explanation:

1. **Did you read `tests/testthat/test-tally_runs.R`?**
   (The prior test derivation — reading it contaminates independence.)
2. **Did you read any file in `design/notes/`?**
   (Design history that could bias interpretation.)
3. **Did you read any file in `exploration/`?**
   (Exploration artifacts that could bias interpretation.)
4. **Did you read any file in `design/inter-rater/run-*/`?**
   (Output from another run — reading it contaminates independence.)
5. **Did you list the contents of `tests/testthat/` or
   `design/notes/` or `exploration/`?**
   (Even a directory listing could reveal information.)

### Influence assessment

If you answered yes to any contamination check, describe how the
information influenced your test derivation, if at all. Be specific.

---

## Critical constraints

- **Do NOT read `tests/testthat/test-tally_runs.R`.** That file contains
  output from a prior derivation. Reading it would contaminate your
  independent derivation.
- **Do NOT read any files in `design/notes/`.** Those contain design
  history that would bias your interpretation of the contract.
- **Do NOT read `exploration/`.** Same reason.
- **Do NOT read other run directories** (`design/inter-rater/run-*/`).
- **The contract is your only specification.** Derive tests from what
  the Roxygen block says, not from domain knowledge, guesses about
  implementation, or assumptions about what the function "should" do
  beyond the contract.
- **Hand-verify every expected value** in your test data. If you
  assert `expect_equal(result$length, 5L)`, count 5 qualifying
  records. Do not guess.
- **Be honest in the file access log.** The experiment's value depends
  on knowing whether contamination occurred. If you accidentally read
  a restricted file, report it — that is more useful than concealing it.
