# Derivation Report: `tally_runs()`

**Source:** `R/tally_runs.R` (Roxygen block only)
**Agent:** run-1 (inter-rater reliability experiment)

---

## 1. Test count by category

| Category | Count |
|---|---|
| Validation | 10 |
| Happy-path / core behaviour | 3 |
| Comparison operators | 4 |
| Period partitioning | 8 |
| NA behaviour | 2 |
| Return structure | 6 |
| Every period in output | 1 |
| Duration | 3 |
| Default parameters | 3 |
| Edge cases | 3 |
| **Total** | **43** |

---

## 2. Traceability map

**`@param df` — "A data frame or tibble"**
→ "error when df is not a data frame"

**`@param df` — "Assumed to represent a single site"**
→ Not tested (guidance, not behaviour; see Untested claims)

**`@details` Input validation — "df with zero rows"**
→ "error when df has zero rows"

**`@param datetime_col` — 'Default "Date"'**
→ "datetime_col defaults to 'Date'"

**`@param datetime_col` — "The column must be of class Date or POSIXct"**
→ "error when datetime column is not Date or POSIXct"

**`@param datetime_col` — "not found in df"**
→ "error when datetime_col is not found in df"

**`@param value_col` — 'Default "Flow"'**
→ "value_col defaults to 'Flow'"

**`@param value_col` — "not found in df"**
→ "error when value_col is not found in df"

**`@param value_col` — "numeric value column"**
→ "error when value column is not numeric"

**`@param threshold` — "Numeric scalar"**
→ "error when threshold is not a finite numeric scalar"

**`@param comparison` — 'One of ">=" (default), ">", "<=", "<"'**
→ "comparison '>=' includes values equal to threshold",
  "comparison '>' excludes values equal to threshold",
  "comparison '<=' includes values equal to threshold",
  "comparison '<' excludes values equal to threshold"

**`@param comparison` — "Any other value raises an error"**
→ "error when comparison is not a valid operator"

**`@param period` — "water_year (default) -- Oct 1 to Sep 30, labeled by the ending year"**
→ "water_year labels by ending year (WY 2023 = Oct 2022 - Sep 2023)",
  "water_year: Oct date is in the NEXT water year"

**`@param period` — "annual -- Jan 1 to Dec 31, labeled by year"**
→ "annual period labels by calendar year",
  "runs cannot span calendar year boundary with annual period"

**`@param period` — "Two-element character vector of start and end boundaries in MMDD format"**
→ "custom season with MMDD format includes only in-season records",
  "custom season labels by ending year"

**`@param period` — "Wrap-around spans are supported"**
→ "wrap-around custom season works (Oct 1 - Mar 31)"

**`@param period` — "Records outside the span are excluded"**
→ "custom season with MMDD format includes only in-season records"

**`@param period` — validation of invalid period**
→ "error when period is invalid"

**`@param duration_units` — 'If NULL (default), uses the natural unit'**
→ "duration is elapsed time from start to end" (implicitly tests NULL default)

**`@param duration_units` — "passed to base::as.numeric() for conversion"**
→ "duration_units converts to specified units"

**`@param duration_units` — validation**
→ "error when duration_units is not NULL or a recognized unit"

**`@return` — "A tibble"**
→ "output is a tibble"

**`@return` — column names**
→ "output has exactly the specified column names"

**`@return` — column types (period numeric, run_number integer, etc.)**
→ "output column types match the contract"

**`@return` — "same class as input" for start/end**
→ "start and end preserve POSIXct class from input",
  "output column types match the contract" (Date case)

**`@return` — "run_number: Sequential run index within the period"**
→ "run_number is sequential within a period"

**`@return` — "Zero for periods with no runs" / NAs for zero-run rows**
→ "zero-run period row has run_number=0 and NAs for start, end, length, duration",
  "zero-run period when no records meet condition"

**`@return` — "one row per zero-run period" / "every period in the input appears in the output"**
→ "every period in the input appears in the output"

**`@details` NA behaviour — "NA values break runs"**
→ "NA in value column breaks a run into two separate runs"

**`@details` NA behaviour — "No gap-filling is performed"**
→ "NA in value column breaks a run into two separate runs" (confirmed by separate runs),
  "NAs in value column do not cause an error"

**`@details` Period partitioning — "Runs cannot span period boundaries"**
→ "runs cannot span water year boundary",
  "runs cannot span calendar year boundary with annual period"

**`@details` Time zone — "respects whatever time zone the input carries"**
→ Not directly tested (see Untested claims)

**No contract clause has zero tests** (excluding items explicitly listed as untested).

---

## 3. Contract gaps

1. **"Natural unit implied by the data's time step"** — The contract does
   not define how the natural unit is inferred. For regular daily data,
   "days" is a reasonable inference. For irregular time steps (mixed 1-hour
   and 2-hour gaps) or sub-daily POSIXct data, the behaviour is unspecified.
   A specification of the inference algorithm (or a statement that it relies
   on `difftime`'s default) would be needed.

2. **Custom season with "MMDD HHMM" format** — The contract mentions
   sub-daily precision (e.g., `"0601 0600"`), but the rules for how
   sub-daily boundaries interact with Date-class input are unspecified.
   This likely only applies to POSIXct input, but the contract doesn't
   state that.

3. **"Valid MMDD or MMDD HHMM strings"** — The contract doesn't fully
   specify what counts as "valid." Month 13 (`"1301"`) is presumably
   invalid, but what about Feb 30 (`"0230"`)? The validation boundary
   is unclear.

---

## 4. Assumptions made

1. **Duration = end − start (elapsed time), not record count.** For a
   10-record daily run from Jun 1 to Jun 10, I used duration = 9 days.
   The contract says "elapsed time from start to end," which implies
   subtraction. Alternative: duration could equal length (number of
   records), but the contract's wording suggests otherwise.

2. **`as.numeric()` for difftime accepts "secs", "mins", "hours",
   "days", "weeks".** The contract says `duration_units` is "passed to
   `base::as.numeric()` for conversion." I inferred the valid set from
   R's `as.numeric.difftime()` documentation. Invalid values like
   `"bananas"` should error.

3. **Water year assignment: Oct–Dec dates belong to the following
   year's WY.** The contract says "WY 2023 = Oct 2022-Sep 2023." I
   applied this to test that Oct 2022 data → period 2023.

4. **"Continuous sequences of records" means consecutive rows in the
   data frame.** Runs are identified by adjacency in row order, not by
   checking temporal gaps between timestamps. A gap in dates between
   consecutive rows does not break a run unless the gap contains
   records that don't meet the condition (which would be present in
   the data frame). This is implied by "sequential runs" but not
   explicitly stated.

5. **Custom season exclusion test: dates outside the span are simply
   absent from run detection.** I assumed excluded records are dropped
   before run detection, so a run cannot start or end outside the span.

---

## 5. Untested claims

1. **Time zone preservation** — The contract says "respects whatever
   time zone the input datetime column carries and does not convert or
   assume a time zone." Testing `tzone` attributes is fragile across
   platforms. Class preservation (Date/POSIXct) is tested instead.

2. **Multi-site disclaimer** — "Multi-site data should be handled by
   the caller." This is guidance to the user, not testable behaviour
   of the function.

3. **"Users who wish to fill short gaps should do so before calling
   this function"** — Guidance, not behaviour.

4. **Custom season "MMDD HHMM" format** — I tested MMDD format but
   not the sub-daily "MMDD HHMM" variant. The contract gap around
   its interaction with Date input makes it unclear what to test.
   A test for POSIXct input with HHMM boundaries could be added once
   the contract clarifies behaviour.

5. **All valid `duration_units` values** — I tested `"hours"` as a
   representative unit conversion. Testing `"secs"`, `"mins"`,
   `"days"`, `"weeks"` would exercise the same code path and was
   omitted to avoid redundancy.
