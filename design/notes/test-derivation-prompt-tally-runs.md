# Test Derivation from Roxygen Contract

*You are a test-derivation agent. Your job is to read a Roxygen
contract and produce a testthat 3e test file that verifies the
contract behaviourally. You have no other context — no design
notes, no exploration scripts, no prior conversation. The contract
is your only specification.*

---

## Your task

Read the Roxygen block below. Derive testthat 3e tests that verify
every testable claim in the contract. Write a complete test file
named `test-tally_runs.R`.

**Do not implement the function.** Write tests only.

---

## Principles for test derivation

### What to test

Each `@param` constraint implies at least one test. Each `@return`
claim implies at least one test. Each `@details` section describes
behaviour that should be verified.

Work through the contract systematically:

1. **Validation tests.** Every condition listed in the Input
   validation section should have a test confirming that an
   informative error is raised. Use `expect_error()` with a
   `regexp` argument matching the relevant parameter name — this
   confirms the error is about the right thing without being
   fragile to exact wording. Example:
   `expect_error(tally_runs(df, threshold = "abc"), "threshold")`

2. **Happy-path tests.** The core operation: does the function
   detect runs correctly for typical input? Build small, hand-
   verifiable datasets where you know the exact answer. Test:
   - A single run within a single period
   - Multiple runs within a single period
   - Runs across multiple periods
   - A period with no runs (the zero-run row)

3. **Comparison operator tests.** Each of the four valid operators
   should produce the correct result. A dataset near the threshold
   (values equal to, above, and below) exercises the boundary
   between `>` and `>=`, `<` and `<=`.

4. **Period tests.** Test each of the three period modes:
   - `"water_year"` — verify the Oct 1 boundary and ending-year
     labeling (WY 2023 = Oct 2022–Sep 2023)
   - `"annual"` — verify Jan 1 boundary
   - Custom span — test both non-wrapping (e.g., Jun–Nov) and
     wrap-around (e.g., Oct–Mar) spans
   - Verify that records outside a custom span are excluded
   - Verify that runs do not span period boundaries

5. **NA behaviour.** Test that an NA in the middle of an exceedance
   sequence breaks it into two runs. Test that NAs do not cause
   the function to error.

6. **Column name arguments.** Test that non-default column names
   work (i.e., `datetime_col = "timestamp"`, `value_col = "temp"`).

7. **Return structure.** Test the output tibble:
   - Correct column names and types
   - `run_number` is 0 with NAs in detail columns for zero-run
     periods
   - `start` and `end` preserve the class of the input datetime
     column (Date stays Date, POSIXct stays POSIXct)

8. **Duration.** Test that `duration_units` controls the output
   units. Test the default behaviour (natural time step).

9. **Edge cases.**
   - All values meet the condition (one long run per period)
   - No values meet the condition (zero-run row for each period)
   - Single-row input
   - Data spanning only one period
   - Threshold equal to all values (boundary of `>=` vs `>`)

### Validation reference: valid values for key parameters

**`comparison`:** Exactly one of `">="`, `">"`, `"<="`, `"<"`.
Anything else (e.g., `"=="`, `"!="`, `"gt"`) is invalid.

**`duration_units`:** `NULL` (default) or any value accepted by
`base::as.numeric.difftime()`: `"secs"`, `"mins"`, `"hours"`,
`"days"`, `"weeks"`. Values like `"months"`, `"years"`, or
`"fortnights"` are invalid (months/years are not constant length;
arbitrary strings are not recognized).

**`period`:** One of `"water_year"`, `"annual"`, or a two-element
character vector where each element is a date boundary in MMDD
format (four digits, e.g., `"0601"`) or MMDD HHMM format (e.g.,
`"0601 0600"`). Invalid examples: `"1301"` (month 13),
`"0600"` (day 0), `"abc"`, a three-element vector, a single
MMDD string.

### How to write the tests

- **Use testthat 3e style.** `test_that()` with descriptive
  strings that read like requirements.
- **Build test data inline or as shared fixtures.** For small,
  test-specific datasets (5–10 rows), build them inside the
  `test_that()` block. For larger datasets reused across multiple
  tests (e.g., a year of daily data for period boundary testing),
  define them once at the top of the file before the first
  `test_that()` call. Each test that uses a shared fixture should
  still be independently readable — a reader should understand
  what the test checks without scrolling to the fixture.
- **Test observable behaviour, not implementation.** You do not
  know or care whether the function uses `rle()`, `cumsum()`, or
  a loop internally. Test inputs and outputs.
- **Use `expect_equal()` for structure checks, `expect_error()`
  with `regexp` for validation.** Use `expect_s3_class()` for
  tibble checks. Use `expect_true()` / `expect_false()` sparingly.
- **Keep each `test_that()` focused on one specific claim from
  the contract.** Use descriptive test names that read like
  requirements.
- **Hand-verify every expected value.** If you write
  `expect_equal(result$length, 5L)`, you must be able to count
  5 records in the test data that meet the condition. Do not
  guess — count.

### What NOT to do

- Do not implement `tally_runs()`. Write tests only.
- Do not modify the Roxygen block.
- Do not assume implementation details (algorithm, internal
  helpers, package dependencies beyond tibble for the return).
- Do not write tests for behaviour not specified in the contract.
- Do not use snapshot tests for this function — the output is
  structured data, not a printed message.

---

## The contract

```r
#' Tally sequential runs above or below a threshold in a time series
#'
#' Identifies continuous sequences of records where a value meets a
#' threshold condition, partitioned into recurring time spans (water years,
#' calendar years, or custom seasons). Returns one row per run, with
#' zero-run periods represented as a single row so that every period in
#' the input appears in the output.
#'
#' @param df A data frame or tibble containing at least a datetime column
#'   and a numeric value column. Assumed to represent a single site.
#'   Multi-site data should be handled by the caller using purrr or
#'   dplyr group operations.
#' @param datetime_col Character string naming the datetime column in
#'   `df`. Default `"Date"` (matches `dataRetrieval::renameNWISColumns()`
#'   output). The column must be of class Date or POSIXct.
#' @param value_col Character string naming the numeric value column in
#'   `df`. Default `"Flow"` (matches `dataRetrieval::renameNWISColumns()`
#'   output).
#' @param threshold Numeric scalar. The value against which records are
#'   compared.
#' @param comparison Character string specifying the comparison operator.
#'   One of `">="` (default), `">"`, `"<="`, `"<"`. Any other value
#'   raises an error.
#' @param period How to partition the time series into recurring spans.
#'   One of:
#'   \itemize{
#'     \item `"water_year"` (default) -- Oct 1 to Sep 30, labeled by the
#'       ending year (WY 2023 = Oct 2022-Sep 2023).
#'     \item `"annual"` -- Jan 1 to Dec 31, labeled by year.
#'     \item A two-element character vector of start and end boundaries
#'       in `"MMDD"` or `"MMDD HHMM"` format (e.g., `c("0601", "1130")`
#'       for Jun 1-Nov 30, or `c("0601 0600", "1130 1800")` for sub-daily
#'       precision). Wrap-around spans are supported (e.g.,
#'       `c("1001", "0331")` for Oct 1-Mar 31). Records outside the span
#'       are excluded. Each span is labeled by the ending year.
#'   }
#' @param duration_units Character string specifying the units for the
#'   `duration` column in the output. If `NULL` (default), uses the
#'   natural unit implied by the data's time step. Otherwise, passed to
#'   [base::as.numeric()] for conversion (e.g., `"hours"`, `"days"`,
#'   `"mins"`).
#'
#' @return A tibble with one row per run and one row per zero-run period:
#'   \describe{
#'     \item{period}{Numeric. The ending year of the span.}
#'     \item{run_number}{Integer. Sequential run index within the period
#'       (1, 2, ..., n). Zero for periods with no runs.}
#'     \item{start}{Datetime (same class as input). First record in the
#'       run. `NA` when `run_number` is 0.}
#'     \item{end}{Datetime (same class as input). Last record in the run.
#'       `NA` when `run_number` is 0.}
#'     \item{length}{Integer. Number of records in the run. `NA` when
#'       `run_number` is 0.}
#'     \item{duration}{Numeric or difftime. Elapsed time from `start` to
#'       `end`. Units determined by `duration_units` or by the data's
#'       time step. `NA` when `run_number` is 0.}
#'   }
#'
#' @details
#' ## NA behaviour
#' NA values in the value column break runs -- an NA in the middle of
#' what would otherwise be a continuous exceedance produces two separate,
#' shorter runs. No gap-filling is performed. Users who wish to fill
#' short gaps should do so before calling this function.
#'
#' ## Time zone
#' The function respects whatever time zone the input datetime column
#' carries and does not convert or assume a time zone.
#'
#' ## Period partitioning
#' Runs cannot span period boundaries. A continuous exceedance that
#' crosses from one period into the next is recorded as two separate
#' runs, one in each period.
#'
#' ## Input validation
#' The function validates all inputs at entry and raises informative
#' errors for:
#' - `df` that is not a data frame or tibble
#' - `datetime_col` or `value_col` not found in `df`
#' - `datetime_col` column not of class Date or POSIXct
#' - `value_col` column not numeric
#' - `threshold` that is not a finite numeric scalar
#' - `comparison` not one of `">="`, `">"`, `"<="`, `"<"`
#' - `period` that is not `"water_year"`, `"annual"`, or a two-element
#'   character vector of valid MMDD or MMDD HHMM strings
#' - `duration_units` that is not `NULL` or a recognized time unit string
#' - `df` with zero rows (no data to process)
#'
#' @examples
#' # Daily discharge data with water year periods
#' df <- data.frame(
#'   Date = as.Date("2022-06-01") + 0:29,
#'   Flow = c(rep(120, 10), rep(80, 5), rep(120, 15))
#' )
#' tally_runs(df, threshold = 100)
#'
#' # Custom summer season
#' tally_runs(df, threshold = 100, period = c("0601", "0930"))
#'
#' @export
tally_runs <- function(df,
                       datetime_col = "Date",
                       value_col = "Flow",
                       threshold,
                       comparison = ">=",
                       period = "water_year",
                       duration_units = NULL) {
  # Implementation derived from contract and tests -- not yet written.
}
```

---

## Output

Deliver two things: the test file and a derivation report.

### 1. The test file

Write the complete test file. It should begin with:

```r
# test-tally_runs.R
# Tests derived from Roxygen contract for tally_runs()
# No implementation context — contract is the sole specification.
```

### 2. Derivation report

After the test file, provide a structured report with these sections:

**Test count by category:** Number of `test_that()` blocks in each
category (validation, happy-path, comparison, period, NA, column
names, return structure, duration, edge cases).

**Traceability map:** For each contract clause (`@param`, `@return`,
each `@details` subsection, each validation bullet), list which
test(s) verify it. Use the test description strings as identifiers.
Flag any contract clause that has zero tests.

**Contract gaps:** Any claim in the contract that is too ambiguous
or underspecified to derive a test from. Explain what additional
information would be needed.

**Assumptions made:** Any place where you made a judgment call
that was not explicitly stated in the contract. For example:
choosing a specific date range, interpreting an edge case, deciding
whether a condition should error or return empty output.

**Untested claims:** Any contract claim you deliberately chose not
to test, and why (e.g., too implementation-dependent, requires
external data, or would duplicate another test).
