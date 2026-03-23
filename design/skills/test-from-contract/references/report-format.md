# Derivation Report Format

*Template for the structured report that accompanies every test file
produced by the test-from-contract skill.*

---

## Purpose

The derivation report makes the agent's reasoning visible. It lets the
human evaluate whether the tests are sufficient, trace each test back
to the contract, and identify where the contract needs revision. It
also feeds forward into skill refinement — patterns in contract gaps
and assumptions reveal how to improve the prompt.

---

## Required sections

### 1. Test count by category

A table showing how many `test_that()` blocks fall in each category.
Categories should match the structure of the test file. Typical
categories for a data-processing function:

| Category | Count |
|---|---|
| Validation | ... |
| Happy-path | ... |
| Parameter-specific behaviour | ... |
| Return structure | ... |
| Edge cases | ... |
| **Total** | **...** |

Adapt categories to the function. A function with no validation section
won't have validation tests. A function with complex period logic will
have a "Period partitioning" category.

### 2. Traceability map

For each contract clause, list the test(s) that verify it. Use the
`test_that()` description strings as identifiers.

Format:

**`@param threshold` — "Must be finite numeric scalar"**
→ "error when threshold is not a finite numeric scalar"

**`@details` — NA behaviour**
→ "NA in the middle of an exceedance breaks it into two runs",
  "NAs in value column do not cause an error"

**Flag any contract clause with zero tests.** This is the most
important output of the traceability map — it reveals coverage gaps.

### 3. Contract gaps

Claims in the contract that are too ambiguous or underspecified to
derive a test from. For each gap, explain:

- What the contract says
- Why it's ambiguous
- What additional information would be needed

Example:
> **"Natural unit implied by the data's time step"** — The contract
> doesn't define how the natural unit is inferred. For regular daily
> data, days is reasonable. For irregular time steps (mixed 1-hour and
> 2-hour gaps), the behaviour is unspecified. A specification of the
> inference algorithm would be needed.

Contract gaps often indicate where helper functions will crystallise
during implementation. Flag this connection when it's visible.

### 4. Assumptions made

Places where the agent made a judgment call not explicitly stated in
the contract. For each assumption, explain:

- What was assumed
- Why it seemed reasonable
- What the alternative interpretation would be

Example:
> **Duration = end − start.** For a 3-record daily run (Jun 1–3),
> I used duration = 2 days, not 3. The contract says "elapsed time
> from start to end," which implies subtraction rather than counting
> records.

Assumptions are not errors — they're decision points. The human reviews
them and confirms or corrects.

### 5. Untested claims

Contract claims deliberately not tested, and why. Reasons might include:

- **Too implementation-dependent** — e.g., "the function respects the
  input time zone" is hard to verify without comparing tzone attributes,
  which is fragile across platforms.
- **Would duplicate another test** — e.g., testing `"days"` and
  `"weeks"` for `duration_units` when `"hours"` and `"secs"` already
  exercise the same code path.
- **Guidance, not behaviour** — e.g., "Multi-site data should be
  handled by the caller" is advice to the user, not a testable
  behaviour of the function.

---

## Example report

(Abbreviated for illustration)

### Test count by category

| Category | Count |
|---|---|
| Validation | 13 |
| Happy-path | 4 |
| Comparison operators | 4 |
| Period partitioning | 8 |
| NA behaviour | 2 |
| Column names | 1 |
| Return structure | 5 |
| Duration | 3 |
| Edge cases | 9 |
| **Total** | **49** |

### Traceability map

**`@param df`** — "error when df is not a data frame",
"error when df has zero rows"

**`@param threshold`** — "error when threshold is not a finite
numeric scalar"

**`@return` — tibble structure** — "output is a tibble with exactly
the specified column names", "output column types match the contract
specification"

*No contract clause has zero tests.*

### Contract gaps

1. **"Natural unit implied by the data's time step"** — behaviour for
   irregular time steps is unspecified.

### Assumptions made

1. **Duration = end − start**, not record count.
2. **WY 2023 for June 2023 data** — standard USGS convention.

### Untested claims

1. **Time zone preservation** — testing `tzone` attributes is fragile
   across platforms. Class preservation is tested instead.
2. **Multi-site disclaimer** — guidance, not testable behaviour.
