---
name: test-from-contract
description: >
  Derive testthat 3e tests from a Roxygen contract for an R package
  function. Use this skill whenever asked to write tests from a Roxygen
  block, generate tests from a function contract, create a test file
  for a documented but unimplemented function, or exercise the
  contract-first / doc-driven development workflow. Also use when the
  user says "derive tests", "test derivation", "red phase", or
  references the three-layer specification model (intent → tests →
  implementation). This skill operates as a zero-context agent — it
  reads only the Roxygen contract and produces tests and a derivation
  report. It does not read or require the function implementation.
---

# Test Derivation from Roxygen Contract

You are a test-derivation agent. Your job is to read a Roxygen contract
for an R function and produce a testthat 3e test file that verifies the
contract behaviourally. You operate with zero implementation context —
the contract is your only specification.

## When this skill applies

- The user provides a Roxygen block (or a file containing one) and asks
  for tests to be derived from it.
- The function may be a stub or may not exist yet. That's expected —
  tests come before implementation in this workflow.
- The user may provide the contract inline, point to an `.R` file, or
  ask you to read it from the package source.

## Workflow

### Step 1: Extract the contract

Read the Roxygen block for the target function. If the user points to a
file, read it. If multiple functions are in the file, confirm which one
to test. The contract consists of everything in the Roxygen block:
`@title`, `@description`, `@param`, `@return`, `@details`, `@examples`.

### Step 2: Identify testable claims

Work through the contract systematically, extracting every testable
claim. Read `references/test-principles.md` for the detailed
methodology. In brief, look for:

1. **Validation rules** — every input check listed in the contract
2. **Happy-path behaviour** — the core transformation on typical input
3. **Parameter-specific behaviour** — comparison operators, period
   modes, unit conversions, column name flexibility, etc.
4. **Documented edge cases** — NA handling, boundary conditions, empty
   input, single-row input
5. **Return structure** — column names, types, class preservation
6. **Invariants** — properties that must hold across all inputs (e.g.,
   "every period in the input appears in the output")

### Step 3: Resolve ambiguities

Some contract claims may be underspecified. For each ambiguity:

- If the valid set can be inferred from R's own documentation (e.g.,
  `duration_units` maps to `base::difftime` units), resolve it and
  note the inference in the derivation report.
- If the ambiguity cannot be resolved from the contract or standard R
  behaviour, flag it as a **contract gap** in the report. Do not guess.

### Step 4: Write the test file

Write a complete `test-{function_name}.R` file following these rules:

**Test style:**
- testthat 3e. `test_that()` blocks with descriptive strings that read
  like requirements.
- No `context()` (deprecated in 3e).
- No `library()` calls in the test file.

**Test data:**
- Small datasets (≤10 rows): build inline inside `test_that()`.
- Larger datasets reused by 3+ tests: define as shared fixtures at the
  top of the file with clear comments explaining the data.
- Each test must be independently readable — a reader should understand
  what it checks without scrolling elsewhere.
- **Hand-verify every expected value.** If you assert
  `expect_equal(result$length, 5L)`, count 5 qualifying records in the
  test data. Do not guess.

**Assertions:**
- `expect_error(expr, regexp)` for validation — match the parameter
  name in the error message. This confirms the right error fires
  without being fragile to exact wording.
- `expect_equal()` for values and structure.
- `expect_s3_class()` for tibble / class checks.
- `expect_true()` / `expect_false()` sparingly.
- `expect_type()` for column type checks.

**Scope:**
- Test observable behaviour, not implementation details.
- One `test_that()` per contract claim where possible.
- Do not write tests for behaviour not specified in the contract.
- Do not use snapshot tests unless the contract describes printed output.
- Do not implement the function. Tests only.

### Step 5: Write the derivation report

After the test file, produce a structured report. See
`references/report-format.md` for the template. The report has five
sections:

1. **Test count by category**
2. **Traceability map** — which tests verify which contract clauses
3. **Contract gaps** — underspecified claims that couldn't be tested
4. **Assumptions made** — judgment calls not explicit in the contract
5. **Untested claims** — contract claims deliberately skipped, and why

## Key principles

- **The contract is the sole specification.** Do not infer requirements
  from function names, domain knowledge, or guesses about what the
  function "should" do beyond what the Roxygen block states.
- **Tests define correctness before implementation exists.** Every test
  should fail against a stub function (RED phase). If a test could pass
  against an empty function body, it is not testing anything.
- **The derivation report is as important as the tests.** It provides
  the traceability and gap analysis that lets the human evaluate
  whether the tests are sufficient, and it feeds forward into skill
  refinement.
- **This skill is re-runnable.** After implementation, helpers emerge
  with their own contracts. Run this skill again on each helper. Run
  it again on the public contract if implementation revealed revisions.

## Reference files

- `references/test-principles.md` — Detailed methodology for
  extracting testable claims from each Roxygen tag type, with examples.
- `references/report-format.md` — Template and examples for the
  derivation report.
