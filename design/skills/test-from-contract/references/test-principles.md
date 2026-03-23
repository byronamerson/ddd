# Test Principles: Extracting Testable Claims from Roxygen

*Reference for the test-from-contract skill. Read this before writing
any tests.*

---

## How to read a Roxygen block for testable claims

### @param entries

Each `@param` can generate multiple tests:

**Type/class constraints** → validation tests.
```
@param K_s Saturated hydraulic conductivity (m/s). Must be positive.
```
Tests: non-numeric input errors, negative value errors, zero behaviour,
NA handling, Inf handling, vector-vs-scalar if specified.

**Enumerated valid values** → validation + behaviour tests.
```
@param comparison One of ">=", ">", "<=", "<". Any other value raises
  an error.
```
Tests: each valid value produces correct behaviour, invalid values error.

**Default values** → the function works without specifying the param.
```
@param datetime_col Default "Date".
```
Tests: function works with default, function works with a non-default
value.

**Domain semantics** → behaviour tests.
```
@param period "water_year" -- Oct 1 to Sep 30, labeled by the ending year.
```
Tests: verify the Oct 1 boundary, verify ending-year labeling.

### @return

Every claim about the return value is testable:

- Column names → `expect_equal(names(result), c(...))`
- Column types → `expect_type()` or `expect_s3_class()`
- Row counts → `expect_equal(nrow(result), ...)`
- Class preservation → if input is Date, output should be Date
- Special rows (e.g., zero-run rows with NAs) → verify structure

### @details subsections

Each subsection typically describes one behaviour:

- **NA behaviour** → test that NAs break runs, don't cause errors
- **Period partitioning** → test that runs don't span boundaries
- **Input validation** → each bullet is one test (or one `test_that`
  with multiple `expect_error` calls for the same parameter)

### @examples

Examples are executable code. They define the minimal happy path. The
test file should include at least one test that exercises the same
scenario as the examples, but with explicit assertions rather than
just "doesn't error."

---

## Validation test patterns

Use `expect_error()` with a `regexp` argument matching the parameter
name. This confirms the error is about the right parameter without
being fragile to exact message wording.

```r
# Good — matches the parameter name
expect_error(my_func(threshold = "abc"), "threshold")

# Good — matches parameter name OR the column name for flexible messages
expect_error(my_func(df, datetime_col = "nope"), "datetime_col|nope")

# Bad — too specific, breaks if message is reworded
expect_error(my_func(threshold = "abc"), "threshold must be a finite numeric scalar")

# Bad — too vague, passes even if the wrong error fires
expect_error(my_func(threshold = "abc"))
```

### Common validation targets

When the contract says "raises an error for X", test with:

| Constraint | Test inputs |
|---|---|
| Must be numeric | `"abc"`, `TRUE`, `factor("x")` |
| Must be finite numeric scalar | `Inf`, `-Inf`, `NA_real_`, `c(1, 2)`, `numeric(0)`, `"abc"` |
| Must be positive | `-1`, `0` (check if zero is valid), `-0.001` |
| Must be one of [set] | A value not in the set, empty string, `NA` |
| Column must exist in df | A name not present in the data frame |
| Column must be class X | A column of the wrong class |
| df must not be empty | A zero-row data frame |

---

## Resolving known R type ambiguities

When a contract says a parameter is "passed to" a base R function,
the valid set is defined by that function's documentation.

| Contract says | Valid set (from R docs) |
|---|---|
| Passed to `base::as.numeric()` for difftime | `"secs"`, `"mins"`, `"hours"`, `"days"`, `"weeks"` |
| Passed to `match.arg()` | The values listed in the function signature |
| Must be class Date or POSIXct | Test with character, numeric, factor |

Note these resolutions in the **Assumptions made** section of the
derivation report.

---

## Shared fixtures vs inline data

**Inline** (inside `test_that()`): Use for small, test-specific data.
Each test is self-contained. Preferred for most validation tests and
simple happy-path tests.

**Shared fixture** (top of file, before first `test_that()`): Use for
larger datasets reused by 3+ tests. Document the fixture with comments
explaining the data layout and which test scenarios it supports.

Rules for shared fixtures:
- Give them descriptive names: `fixture_wy_boundary`, not `df1`.
- Comment the expected results for each scenario the fixture supports.
- Each test using the fixture must still be independently readable.
- Do not modify fixtures inside `test_that()` blocks.

---

## Edge cases to always consider

These edge cases should be tested if the contract doesn't explicitly
exclude them:

- Empty input (zero rows)
- Single-row input
- All values meet the condition
- No values meet the condition
- Input with NAs
- Boundary values (equal to threshold)
- Multiple periods with mixed results (some with runs, some without)
- Single period

---

## What NOT to do

- Do not implement the function. Tests only.
- Do not modify the Roxygen block.
- Do not assume implementation details (algorithm, internal helpers).
- Do not write tests for behaviour not specified in the contract.
- Do not use snapshot tests for structured data output.
- Do not write tests that would pass against an empty function body.
  Every test must fail against a stub (RED phase).
