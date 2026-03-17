# CLAUDE.md

Read this before starting any work. These directives take precedence
over cleverness, brevity, or convention. The full reference documents
are in `docs/`.

---

## The Workflow — Contract First, Always

For every non-trivial function, in this order:

1. **Discuss** — reason in natural language before writing code.
   Clarify requirements, decompose the problem, surface edge cases.
   Do not jump to implementation.

2. **Write the contract** — Roxygen block (R packages) or structured
   docstring (Python) before the function body exists. Title states
   purpose. `@param` entries carry domain semantics and constraints,
   not just types. `@return` describes output structure. `@details`
   records key decisions.

3. **Write failing tests** — derive expectations directly from the
   contract. Each constraint implies a test. Run them. Confirm RED.

4. **Implement** — write the minimum code to make tests pass.
   Do not modify the tests or the contract to fit the implementation.

5. **Refactor** — clean up under the test safety net. Commit on green.

6. **Record decisions** — commit message, inline comment, or decision
   log. What was decided and why.

---

## Code Principles — R

- **Pure functions.** All inputs are explicit arguments. No free
  variables, no global state, no side effects. I/O happens once,
  in the outermost orchestrator only.
- **One function, one job.** If the name needs "and", split it.
- **Verb-noun names.** `parse_timestamp`, `split_groups`,
  `is_sentinel`. If the name is unclear, the function is doing
  too much.
- **purrr over apply.** `map2` not `mapply`. `map_lgl` not `vapply`.
  `list_rbind` not `do.call(rbind, ...)`.
- **Pipes for sequences.** `x %>% f() %>% g()` over `g(f(x))`.
  Named intermediates when the object has scientific meaning.
- **No deep nesting.** One level of anonymous function inside `map()`
  is acceptable. Two is a signal to name it. Three is never acceptable.
- **Validate once.** At the top of the exported function.
  Internal helpers trust their inputs.
- **Roxygen is the contract.** `@param K_s Saturated hydraulic
  conductivity (m/s). Must be positive.` — not `@param K_s A numeric.`

## Code Principles — Python

- Same pure function and one-job rules as above.
- `.assign()` over in-place mutation. `.pipe()` for named steps.
- `_underscore` prefix for internal helpers.
- NumPy-style docstrings. Domain semantics in parameter descriptions.
- Ruff for formatting and linting.

---

## Testing

- **Never modify test files** to make failing tests pass. Fix the
  implementation or the contract.
- **Test helpers directly.** Do not route all tests through the
  orchestrator.
- **Snapshot conditions** in R: `expect_snapshot(error = TRUE)`
  not `expect_error(., "regex")`.
- **`pytest.approx`** for floats in Python.
- Confirm RED before implementing. A test that was never red is
  unverified.

---

## Applied Science Reminders

- **Sniff-test at every transition.** Plot the output. Do the values
  make physical sense? Are the units right? Are the ranges plausible?
- **State units everywhere** a physical quantity appears — in variable
  names, docstrings, comments.
- **No hand-transfer of numbers.** Tables and figures are generated
  by code, not assembled by hand.
- **Slow is smooth.** Review output before sharing. Check axes,
  labels, units, ranges.

---

## Full Reference Documents

- `docs/lingua.md` — principles for LLM-collaborative development
- `docs/r-principles.md` — R coding conventions
- `docs/python-principles.md` — Python coding conventions
- `docs/contract-first.md` — contract-first workflow in full
- `docs/applied-science-workflow.md` — applied science context

When a section of this file is insufficient, read the relevant
full document before proceeding.
