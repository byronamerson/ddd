# Derivation Report: `tally_runs()`

## 1. Test count by category

| Category | Count |
|---|---|
| Validation | 10 |
| Return structure | 4 |
| Happy-path | 4 |
| Comparison operators | 4 |
| Period partitioning | 7 |
| NA behaviour | 2 |
| Duration | 3 |
| Edge cases | 6 |
| **Total** | **40** |

## 2. Traceability map

**`@param df` — "data frame or tibble"**
→ "error when df is not a data frame"

**`@param df` — "zero rows"**
→ "error when df has zero rows"

**`@param datetime_col` — "Character string naming the datetime column"**
→ "error when datetime_col is not found in df"

**`@param datetime_col` — "must be of class Date or POSIXct"**
→ "error when datetime_col column is not Date or POSIXct"

**`@param datetime_col` — Default `"Date"`**
→ "default column names work with Date and Flow columns"

**`@param value_col` — "Character string naming the numeric value column"**
→ "error when value_col is not found in df"

**`@param value_col` — "not numeric"**
→ "error when value_col column is not numeric"

**`@param value_col` — Default `"Flow"`**
→ "default column names work with Date and Flow columns"

**`@param threshold` — "finite numeric scalar"**
→ "error when threshold is not a finite numeric scalar"

**`@param comparison` — "One of `>=`, `>`, `<=`, `<`"**
→ "error when comparison is not a valid operator",
  ">= includes records equal to threshold",
  "> excludes records equal to threshold",
  "<= includes records equal to threshold",
  "< excludes records equal to threshold"

**`@param period` — "water_year" Oct 1–Sep 30, labeled by ending year**
→ "water_year labels by ending year (WY 2022 = Oct 2021-Sep 2022)"

**`@param period` — "annual" Jan 1–Dec 31**
→ "annual period labels by calendar year"

**`@param period` — Two-element character vector**
→ "custom season example from contract works",
  "custom season excludes records outside the span",
  "wrap-around custom season works"

**`@param period` — invalid values**
→ "error when period is invalid"

**`@param duration_units` — NULL default / explicit unit**
→ "duration reflects elapsed time from start to end",
  "explicit duration_units converts duration",
  "error when duration_units is not NULL or a recognized unit string"

**`@return` — tibble**
→ "output is a tibble"

**`@return` — column names**
→ "output has exactly the specified column names"

**`@return` — column types**
→ "output column types match the contract"

**`@return` — class preservation (Date/POSIXct)**
→ "start and end preserve POSIXct class when input is POSIXct",
  "output column types match the contract" (Date case)

**`@return` — zero-run period row structure**
→ "zero-run periods produce a row with run_number=0 and NAs"

**`@return` — run_number sequential within period**
→ "run_number is sequential within a period"

**`@details` — NA behaviour**
→ "NA in value column breaks a run into two separate runs",
  "NAs in value column do not cause an error"

**`@details` — Period partitioning: runs cannot span boundaries**
→ "runs cannot span water year boundaries"

**`@details` — every period in the input appears in the output**
→ "every period in the input appears in the output"

**`@examples` — daily discharge happy path**
→ "basic two-run example from contract produces correct results"

**`@examples` — custom summer season**
→ "custom season example from contract works"

**No contract clause has zero tests.**

## 3. Contract gaps

1. **"Natural unit implied by the data's time step"** — The contract does not
   define how the natural unit is inferred from the data. For regular daily
   data, "days" is intuitive. For irregular time steps (e.g., mixed hourly
   and sub-hourly), the algorithm for inferring the natural unit is
   unspecified. A specification of the inference method (median gap, mode
   gap, minimum gap) would be needed. This likely signals a helper function
   during implementation.

2. **Custom season MMDD HHMM format** — The contract specifies sub-daily
   precision with `"MMDD HHMM"` format but does not describe how this
   interacts with Date-class (day-resolution) datetime columns. Presumably
   sub-daily boundaries only apply to POSIXct inputs, but this is not
   stated.

3. **Custom season labeling edge cases** — The contract says custom seasons
   are "labeled by the ending year." For a non-wrap-around season like
   Jun 1–Nov 30 where all data falls within a single calendar year, the
   ending year is clear. But for a wrap-around season like Oct 1–Mar 31,
   data in Oct–Dec belongs to a season ending in the following year. The
   contract states this via the wrap-around example, but boundary
   assignment for records exactly on the boundary date is not specified.

## 4. Assumptions made

1. **Duration = end − start (elapsed time), not record count.** The
   contract says "elapsed time from start to end." For a 5-record daily
   run (Jun 1–5), I used duration = 4 days, not 5. This follows the
   subtraction interpretation. Alternative: duration could equal record
   count × time step.

2. **`duration_units` valid set = `difftime` units.** The contract says
   the parameter is "passed to `base::as.numeric()` for conversion" and
   gives examples `"hours"`, `"days"`, `"mins"`. I inferred the valid set
   is `c("secs", "mins", "hours", "days", "weeks")` from `?difftime`.
   I tested conversion with `"hours"` (4 days × 24 = 96 hours).

3. **Water year convention matches USGS standard.** June 2022 falls in
   WY 2022 (Oct 2021–Sep 2022). This is the standard USGS convention,
   consistent with the contract's statement "labeled by the ending year."

4. **`period` numeric type is double.** The contract says `period` is
   "Numeric. The ending year of the span." I used `expect_type(result$period, "double")`
   since year values like 2022 are stored as double in R by default.
   An integer representation would also be reasonable.

5. **Non-default column names test.** I tested with `datetime_col = "timestamp"`
   and `value_col = "discharge"` to verify the function respects custom
   column names. The contract specifies defaults but the parameterization
   implies arbitrary names should work.

## 5. Untested claims

1. **Time zone preservation** — The contract states "The function respects
   whatever time zone the input datetime column carries and does not
   convert or assume a time zone." Testing `tzone` attributes is fragile
   across platforms (e.g., `""` vs `"UTC"` vs system-specific defaults).
   Class preservation is tested instead (POSIXct in → POSIXct out).

2. **Multi-site disclaimer** — "Multi-site data should be handled by the
   caller" is guidance to the user, not a testable behaviour of the
   function.

3. **`duration_units` with all valid difftime units** — I tested `"hours"`
   as a representative case. Testing `"secs"`, `"mins"`, `"days"`, and
   `"weeks"` would exercise the same code path (passthrough to
   `as.numeric()`).

4. **Custom season with `"MMDD HHMM"` sub-daily format** — Flagged as a
   contract gap. Without clarity on how sub-daily boundaries interact
   with Date-class inputs, I did not write tests for sub-daily custom
   season boundaries.
