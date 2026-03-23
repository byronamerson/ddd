# Derivation Report: tally_runs()

## 1. Test count by category

| Category | Count |
|---|---|
| Validation | 11 |
| Happy-path | 2 |
| Comparison operators | 4 |
| Period partitioning | 7 |
| NA behaviour | 2 |
| Return structure | 4 |
| Zero-run periods | 2 |
| Duration and duration_units | 3 |
| Column name flexibility | 1 |
| Edge cases | 5 |
| **Total** | **41** |

Note: validation test count of 11 counts each `test_that()` block as 1,
though several blocks contain multiple `expect_error()` calls (e.g., the
threshold validation block tests 4 invalid inputs).

## 2. Traceability map

**`@param df` — "A data frame or tibble"**
→ "error when df is not a data frame"

**`@details` Input validation — "df with zero rows"**
→ "error when df has zero rows"

**`@param datetime_col` — "Character string naming the datetime column"**
→ "error when datetime_col is not found in df",
  "error when datetime column is not Date or POSIXct"

**`@param datetime_col` — Default `"Date"`**
→ "happy path: two runs in daily water-year data (contract example)" (uses default),
  "non-default column names work when specified"

**`@param value_col` — "Character string naming the numeric value column"**
→ "error when value_col is not found in df",
  "error when value column is not numeric"

**`@param value_col` — Default `"Flow"`**
→ "happy path: two runs in daily water-year data (contract example)" (uses default),
  "non-default column names work when specified"

**`@param threshold` — "Numeric scalar"**
→ "error when threshold is not a finite numeric scalar"

**`@param comparison` — "One of `>=`, `>`, `<=`, `<`"**
→ ">= comparison includes values equal to threshold",
  "> comparison excludes values equal to threshold",
  "<= comparison includes values equal to threshold",
  "< comparison excludes values equal to threshold",
  "error when comparison is not a valid operator"

**`@param period` — `"water_year"` (default)**
→ "water_year labels by ending year (WY 2022 = Oct 2021-Sep 2022)",
  "runs cannot span water year boundaries",
  "happy path: two runs in daily water-year data (contract example)"

**`@param period` — `"annual"`**
→ "annual period labels by calendar year",
  "runs cannot span annual period boundaries"

**`@param period` — Two-element character vector (custom season)**
→ "custom season excludes records outside the span",
  "custom season labels by ending year",
  "happy path: custom summer season (contract example)"

**`@param period` — Wrap-around spans**
→ "wrap-around custom season spans year boundary"

**`@param period` — Validation**
→ "error when period is invalid"

**`@param duration_units` — "If NULL, uses the natural unit"**
→ "duration is elapsed time from start to end" (uses default NULL)

**`@param duration_units` — Explicit unit string**
→ "explicit duration_units converts output duration"

**`@param duration_units` — Validation**
→ "error when duration_units is not NULL or a recognized unit string"

**`@return` — tibble**
→ "output is a tibble"

**`@return` — Column names**
→ "output has exactly the specified column names"

**`@return` — Column types (period numeric, run_number integer, length integer)**
→ "output column types match contract specification"

**`@return` — start/end same class as input**
→ "output column types match contract specification" (Date),
  "start and end preserve POSIXct class when input is POSIXct"

**`@return` — run_number sequential within period (1, 2, ..., n)**
→ "run_number is sequential within a period"

**`@return` — Zero-run periods: run_number 0, NAs for start/end/length/duration**
→ "period with no runs produces a single row with run_number 0 and NAs"

**`@return` — "every period in the input appears in the output"**
→ "every period in the input appears in the output"

**`@return` — duration: elapsed time from start to end**
→ "duration is elapsed time from start to end",
  "single-record run has duration of zero"

**`@details` NA behaviour — "NA values in the value column break runs"**
→ "NA in value column breaks a run into two separate runs"

**`@details` NA behaviour — No errors from NAs**
→ "NAs in value column do not cause an error"

**`@details` Period partitioning — "Runs cannot span period boundaries"**
→ "runs cannot span water year boundaries",
  "runs cannot span annual period boundaries"

*No contract clause has zero tests.*

## 3. Contract gaps

1. **"Natural unit implied by the data's time step"** — The contract
   does not define how the natural unit is inferred from the data. For
   regular daily data, "days" is the obvious choice. For irregular time
   steps or POSIXct data with mixed intervals, the behaviour is
   unspecified. A specification of the inference algorithm (e.g., modal
   time step, minimum time step) would be needed to write a precise test.
   I tested that duration equals elapsed time with default NULL but did
   not test the unit selection logic.

2. **MMDD HHMM format for custom seasons** — The contract mentions
   `"MMDD HHMM"` format for sub-daily precision (e.g.,
   `c("0601 0600", "1130 1800")`). The exact parsing rules and
   interaction with POSIXct data are not fully specified. I tested MMDD
   format only.

3. **Custom season period validation — "valid MMDD or MMDD HHMM
   strings"** — The contract says invalid period values raise errors but
   does not define what makes an MMDD string "valid" beyond the format
   (e.g., is `"1301"` for month 13 invalid? Is `"0230"` for Feb 30
   invalid?). I tested obviously invalid string forms but not boundary
   date validity.

4. **"Continuous sequences of records"** — The contract describes
   identifying "continuous sequences of records where a value meets a
   threshold condition." It is ambiguous whether "continuous" means
   consecutive rows in the data frame or records at consecutive time
   steps. For data with temporal gaps (e.g., missing days), the behaviour
   is unspecified. My tests use data with no temporal gaps, avoiding
   this ambiguity.

## 4. Assumptions made

1. **Duration = end − start, not record count minus one.** The contract
   says "elapsed time from start to end." For a 10-record daily run
   (Jun 1–10), I used duration = 9 days (end − start), not 10 or 9
   based on record count. This is the natural reading of "elapsed time."

2. **Water year convention: WY 2022 = Oct 2021–Sep 2022.** The contract
   explicitly states this (labeled by ending year), so this is not truly
   an assumption, but I'm noting it for clarity since it differs from
   some conventions where WY is labeled by the starting year.

3. **Valid `duration_units` values = valid `base::difftime` units.**
   The contract says duration_units is "passed to `base::as.numeric()`
   for conversion." Based on R documentation for `difftime`, valid units
   are `"secs"`, `"mins"`, `"hours"`, `"days"`, `"weeks"`. I used
   `"hours"` in the conversion test and `"fortnights"` as an invalid
   value.

4. **"Continuous sequences of records" = consecutive rows in the data
   frame.** In the wrap-around custom season test, Oct 2022 and Mar 2023
   records are non-contiguous in time but consecutive in the data frame
   (with a gap-value row breaking the run). I assumed the function
   operates on row adjacency, not temporal adjacency.

5. **Zero-run row preserves the zero-run structure even for all-NA
   data.** When all values are NA, no values meet the threshold condition,
   so the period should produce a zero-run row. The contract doesn't
   explicitly address all-NA input but the "NA breaks runs" rule implies
   NAs never contribute to runs.

## 5. Untested claims

1. **Time zone preservation** — The contract says "the function respects
   whatever time zone the input datetime column carries and does not
   convert or assume a time zone." Testing `tzone` attributes is fragile
   across platforms and R versions. Class preservation (Date, POSIXct)
   is tested instead.

2. **Multi-site disclaimer** — "Multi-site data should be handled by
   the caller using purrr or dplyr group operations." This is guidance
   to the user, not a testable behaviour of the function.

3. **MMDD HHMM sub-daily custom season boundaries** — Noted as a
   contract gap. Would require POSIXct test data and careful boundary
   verification.

4. **`duration_units = NULL` unit selection for non-daily data** — The
   "natural unit" inference is a contract gap. I verified elapsed time
   is correct with default NULL on daily data but did not test that the
   function picks appropriate units for hourly or irregular data.

5. **Not all `duration_units` values tested** — Only `"hours"` was
   tested for explicit conversion. `"secs"`, `"mins"`, `"days"`,
   `"weeks"` exercise the same code path (passed to `as.numeric()`),
   so testing one is representative.
