# test-tally_runs.R
# Tests derived from Roxygen contract for tally_runs()
# No implementation context — contract is the sole specification.

# --- Shared fixtures --------------------------------------------------------

# Daily data with multiple runs in a single water year (WY 2023).
# Jun 1–15 2023 — entirely within WY 2023 (Oct 2022–Sep 2023).
# Hand-verified run positions (threshold >= 100):
#   Run 1: Jun 1–3   (rows 1-3,  length=3, duration=2 days)
#   Run 2: Jun 6–7   (rows 6-7,  length=2, duration=1 day)
#   Run 3: Jun 11–14 (rows 11-14, length=4, duration=3 days)
fixture_multi_run <- data.frame(
  Date = as.Date("2023-06-01") + 0:14,
  Flow = c(120, 120, 120, 80, 80,
           120, 120, 80, 80, 80,
           120, 120, 120, 120, 80)
)

# Daily data spanning a water year boundary (WY 2023 → WY 2024).
# Sep 28–Oct 3 2023.  All values 120, threshold >= 100.
#   WY 2023 (ending 2023): Sep 28–30 → 1 run, length=3, duration=2 days
#   WY 2024 (ending 2024): Oct 1–3   → 1 run, length=3, duration=2 days
fixture_wy_boundary <- data.frame(
  Date = as.Date("2023-09-28") + 0:5,
  Flow = rep(120, 6)
)

# Daily data spanning a calendar-year boundary.
# Dec 30 2023 – Jan 2 2024. All values 120, threshold >= 100.
#   2023: Dec 30–31 → 1 run, length=2
#   2024: Jan 1–2   → 1 run, length=2
fixture_annual_boundary <- data.frame(
  Date = as.Date("2023-12-30") + 0:3,
  Flow = rep(120, 4)
)

# Boundary-value data for comparison operator testing.
# Jun 1–5 2023, values: 99, 100, 101, 100, 99.  threshold = 100.
#   >=  : pos 2,3,4 exceedance → 1 run, length=3 (Jun 2–4)
#   >   : pos 3 only           → 1 run, length=1 (Jun 3)
#   <=  : pos 1,2 then 4,5     → 2 runs, each length=2
#   <   : pos 1 then 5         → 2 runs, each length=1
fixture_boundary <- data.frame(
  Date = as.Date("2023-06-01") + 0:4,
  Flow = c(99, 100, 101, 100, 99)
)

# =============================================================================
# Validation tests
# =============================================================================

test_that("error when df is not a data frame", {
  expect_error(tally_runs("not_a_df", threshold = 100), "df")
  expect_error(tally_runs(list(a = 1, b = 2), threshold = 100), "df")
  expect_error(tally_runs(42, threshold = 100), "df")
})

test_that("error when datetime_col is not found in df", {
  df <- data.frame(Date = as.Date("2023-01-01"), Flow = 100)
  expect_error(
    tally_runs(df, datetime_col = "timestamp", threshold = 100),
    "datetime_col|timestamp"
  )
})

test_that("error when value_col is not found in df", {
  df <- data.frame(Date = as.Date("2023-01-01"), Flow = 100)
  expect_error(
    tally_runs(df, value_col = "discharge", threshold = 100),
    "value_col|discharge"
  )
})

test_that("error when datetime column is not Date or POSIXct", {
  df <- data.frame(Date = "2023-01-01", Flow = 100)
  expect_error(tally_runs(df, threshold = 100), "datetime_col|Date|POSIXct|class")
})

test_that("error when value column is not numeric", {
  df <- data.frame(Date = as.Date("2023-01-01"), Flow = "high")
  expect_error(tally_runs(df, threshold = 100), "value_col|numeric")
})

test_that("error when threshold is not a finite numeric scalar", {
  df <- data.frame(Date = as.Date("2023-01-01"), Flow = 100)
  expect_error(tally_runs(df, threshold = "abc"), "threshold")
  expect_error(tally_runs(df, threshold = Inf), "threshold")
  expect_error(tally_runs(df, threshold = -Inf), "threshold")
  expect_error(tally_runs(df, threshold = NA_real_), "threshold")
  expect_error(tally_runs(df, threshold = c(100, 200)), "threshold")
  expect_error(tally_runs(df, threshold = numeric(0)), "threshold")
})

test_that("error when comparison is not one of the four valid operators", {
  df <- data.frame(Date = as.Date("2023-01-01"), Flow = 100)
  expect_error(tally_runs(df, threshold = 100, comparison = "=="), "comparison")
  expect_error(tally_runs(df, threshold = 100, comparison = "!="), "comparison")
  expect_error(tally_runs(df, threshold = 100, comparison = "gt"), "comparison")
  expect_error(tally_runs(df, threshold = 100, comparison = ""), "comparison")
})

test_that("error when period is an unrecognised string", {
  df <- data.frame(Date = as.Date("2023-01-01"), Flow = 100)
  expect_error(tally_runs(df, threshold = 100, period = "monthly"), "period")
  expect_error(tally_runs(df, threshold = 100, period = "fiscal_year"), "period")
})

test_that("error when period is a single MMDD string instead of two-element vector", {
  df <- data.frame(Date = as.Date("2023-01-01"), Flow = 100)
  expect_error(tally_runs(df, threshold = 100, period = "0601"), "period")
})

test_that("error when period is a three-element vector", {
  df <- data.frame(Date = as.Date("2023-01-01"), Flow = 100)
  expect_error(
    tally_runs(df, threshold = 100, period = c("0601", "0930", "1201")),
    "period"
  )
})

test_that("error when period MMDD has invalid month or day", {
  df <- data.frame(Date = as.Date("2023-01-01"), Flow = 100)
  # month 13
  expect_error(tally_runs(df, threshold = 100, period = c("1301", "0930")), "period")
  # day 0
  expect_error(tally_runs(df, threshold = 100, period = c("0600", "1130")), "period")
  # non-MMDD garbage
  expect_error(tally_runs(df, threshold = 100, period = c("abc", "1130")), "period")
})

test_that("error when duration_units is not NULL or a valid time unit", {
  df <- data.frame(Date = as.Date("2023-01-01"), Flow = 100)
  expect_error(tally_runs(df, threshold = 100, duration_units = "months"), "duration_units")
  expect_error(tally_runs(df, threshold = 100, duration_units = "years"), "duration_units")
  expect_error(tally_runs(df, threshold = 100, duration_units = "fortnights"), "duration_units")
})

test_that("error when df has zero rows", {
  df <- data.frame(Date = as.Date(character(0)), Flow = numeric(0))
  expect_error(tally_runs(df, threshold = 100), "df|row|zero|empty|no data")
})

# =============================================================================
# Happy-path tests
# =============================================================================

test_that("single run within a single period is detected correctly", {
  # 5-day dataset, all exceeding.  One continuous run.
  df <- data.frame(
    Date = as.Date("2023-06-01") + 0:4,
    Flow = c(120, 130, 140, 110, 105)
  )
  result <- tally_runs(df, threshold = 100)
  # All in WY 2023, 1 run, length = 5
  expect_equal(nrow(result), 1L)
  expect_equal(result$period, 2023)
  expect_equal(result$run_number, 1L)
  expect_equal(result$length, 5L)
  expect_equal(result$start, as.Date("2023-06-01"))
  expect_equal(result$end, as.Date("2023-06-05"))
})

test_that("multiple runs within a single period are detected correctly", {
  result <- tally_runs(fixture_multi_run, threshold = 100)
  # 3 runs, all in WY 2023
  expect_equal(nrow(result), 3L)
  expect_equal(result$run_number, c(1L, 2L, 3L))
  expect_equal(result$length, c(3L, 2L, 4L))
  expect_equal(result$start, as.Date(c("2023-06-01", "2023-06-06", "2023-06-11")))
  expect_equal(result$end, as.Date(c("2023-06-03", "2023-06-07", "2023-06-14")))
})

test_that("runs across multiple periods are assigned to the correct period", {
  result <- tally_runs(fixture_wy_boundary, threshold = 100)
  # 2 runs, one per water year
  expect_equal(nrow(result), 2L)
  expect_equal(result$period, c(2023, 2024))
  expect_equal(result$run_number, c(1L, 1L))
  expect_equal(result$length, c(3L, 3L))
})

test_that("zero-run period produces a row with run_number 0 and NA details", {
  df <- data.frame(
    Date = as.Date("2023-06-01") + 0:4,
    Flow = rep(80, 5)
  )
  result <- tally_runs(df, threshold = 100)
  # All below threshold → 1 zero-run row in WY 2023
  expect_equal(nrow(result), 1L)
  expect_equal(result$period, 2023)
  expect_equal(result$run_number, 0L)
  expect_true(is.na(result$start))
  expect_true(is.na(result$end))
  expect_true(is.na(result$length))
  expect_true(is.na(result$duration))
})

# =============================================================================
# Comparison operator tests
# =============================================================================

test_that(">= includes values equal to the threshold", {
  result <- tally_runs(fixture_boundary, threshold = 100, comparison = ">=")
  # Positions 2 (100), 3 (101), 4 (100) → 1 run, length 3
  expect_equal(nrow(result), 1L)
  expect_equal(result$run_number, 1L)
  expect_equal(result$length, 3L)
  expect_equal(result$start, as.Date("2023-06-02"))
  expect_equal(result$end, as.Date("2023-06-04"))
})

test_that("> excludes values equal to the threshold", {
  result <- tally_runs(fixture_boundary, threshold = 100, comparison = ">")
  # Only position 3 (101) → 1 run, length 1
  expect_equal(nrow(result), 1L)
  expect_equal(result$run_number, 1L)
  expect_equal(result$length, 1L)
  expect_equal(result$start, as.Date("2023-06-03"))
  expect_equal(result$end, as.Date("2023-06-03"))
})

test_that("<= includes values equal to the threshold", {
  result <- tally_runs(fixture_boundary, threshold = 100, comparison = "<=")
  # Positions 1,2 (99,100) then break at 3 (101), then 4,5 (100,99)
  # 2 runs, each length 2
  expect_equal(nrow(result), 2L)
  expect_equal(result$run_number, c(1L, 2L))
  expect_equal(result$length, c(2L, 2L))
  expect_equal(result$start, as.Date(c("2023-06-01", "2023-06-04")))
  expect_equal(result$end, as.Date(c("2023-06-02", "2023-06-05")))
})

test_that("< excludes values equal to the threshold", {
  result <- tally_runs(fixture_boundary, threshold = 100, comparison = "<")
  # Only positions 1 (99) and 5 (99), separated by non-qualifying values
  # 2 runs, each length 1
  expect_equal(nrow(result), 2L)
  expect_equal(result$run_number, c(1L, 2L))
  expect_equal(result$length, c(1L, 1L))
  expect_equal(result$start, as.Date(c("2023-06-01", "2023-06-05")))
  expect_equal(result$end, as.Date(c("2023-06-01", "2023-06-05")))
})

# =============================================================================
# Period tests
# =============================================================================

test_that("water_year partitions at Oct 1 and labels by ending year", {
  result <- tally_runs(fixture_wy_boundary, threshold = 100, period = "water_year")
  # Sep 28–30 → WY 2023, Oct 1–3 → WY 2024
  expect_equal(result$period, c(2023, 2024))
  expect_equal(result$start[1], as.Date("2023-09-28"))
  expect_equal(result$end[1], as.Date("2023-09-30"))
  expect_equal(result$start[2], as.Date("2023-10-01"))
  expect_equal(result$end[2], as.Date("2023-10-03"))
})

test_that("annual period partitions at Jan 1 and labels by year", {
  result <- tally_runs(fixture_annual_boundary, threshold = 100, period = "annual")
  # Dec 30–31 → 2023, Jan 1–2 → 2024
  expect_equal(nrow(result), 2L)
  expect_equal(result$period, c(2023, 2024))
  expect_equal(result$length, c(2L, 2L))
})

test_that("runs do not span period boundaries (water_year)", {
  # The 6-day continuous exceedance in fixture_wy_boundary must become
  # two runs (one per WY), not one run of length 6.
  result <- tally_runs(fixture_wy_boundary, threshold = 100, period = "water_year")
  expect_equal(nrow(result), 2L)
  # No single run of length 6
  expect_true(all(result$length <= 3L))
})

test_that("runs do not span period boundaries (annual)", {
  result <- tally_runs(fixture_annual_boundary, threshold = 100, period = "annual")
  expect_equal(nrow(result), 2L)
  expect_true(all(result$length <= 2L))
})

test_that("custom non-wrapping period includes only records within the span", {
  # May 30 – Jun 4 2023.  Custom period Jun 1–Nov 30 → c("0601", "1130").
  # May 30–31 are outside the span, Jun 1–4 are inside.
  df <- data.frame(
    Date = as.Date("2023-05-30") + 0:5,
    Flow = rep(120, 6)
  )
  result <- tally_runs(df, threshold = 100, period = c("0601", "1130"))
  # Only Jun 1–4 contribute.  1 run, length = 4, period = 2023.
  expect_equal(nrow(result), 1L)
  expect_equal(result$length, 4L)
  expect_equal(result$start, as.Date("2023-06-01"))
  expect_equal(result$end, as.Date("2023-06-04"))
  expect_equal(result$period, 2023)
})

test_that("custom wrap-around period works correctly", {
  # c("1001", "0331"): Oct 1 to Mar 31, labeled by ending year.
  # Data: Mar 29–Apr 2 2023, all values 120.
  # Mar 29–31 fall inside Oct 2022–Mar 2023 (period 2023).
  # Apr 1–2 are outside the span → excluded.
  df <- data.frame(
    Date = as.Date("2023-03-29") + 0:4,
    Flow = rep(120, 5)
  )
  result <- tally_runs(df, threshold = 100, period = c("1001", "0331"))
  # 1 run of length 3 in period 2023
  expect_equal(nrow(result), 1L)
  expect_equal(result$length, 3L)
  expect_equal(result$period, 2023)
  expect_equal(result$start, as.Date("2023-03-29"))
  expect_equal(result$end, as.Date("2023-03-31"))
})

test_that("records outside a custom span are excluded from results", {
  # All data falls outside the custom span → zero-run row (or no row
  # if the period is never entered — the contract says "every period
  # in the input appears").  Here all data is in May, span is Jun–Nov.
  df <- data.frame(
    Date = as.Date("2023-05-01") + 0:4,
    Flow = rep(120, 5)
  )
  result <- tally_runs(df, threshold = 100, period = c("0601", "1130"))
  # No records inside the span.  The function should not create runs
  # from excluded records.  Expect zero rows or a zero-run row.
  # Either way, no run with length > 0.
  expect_true(nrow(result) == 0L || all(result$run_number == 0L))
})

test_that("custom period with MMDD HHMM format is accepted", {
  # Verify that sub-daily boundary format doesn't error.
  df <- data.frame(
    Date = as.POSIXct(
      c("2023-06-01 07:00", "2023-06-01 08:00", "2023-06-01 09:00"),
      tz = "UTC"
    ),
    Flow = c(120, 120, 120)
  )
  # Span from Jun 1 06:00 to Nov 30 18:00
  result <- tally_runs(
    df, threshold = 100,
    period = c("0601 0600", "1130 1800")
  )
  expect_s3_class(result, "tbl_df")
})

# =============================================================================
# NA behaviour tests
# =============================================================================

test_that("NA in the middle of an exceedance breaks it into two runs", {
  # 7 days: 120, 120, NA, 120, 120, 120, 80
  # threshold >= 100
  # Run 1: pos 1–2 (length 2, Jun 1–2)
  # Run 2: pos 4–6 (length 3, Jun 4–6)
  df <- data.frame(
    Date = as.Date("2023-06-01") + 0:6,
    Flow = c(120, 120, NA, 120, 120, 120, 80)
  )
  result <- tally_runs(df, threshold = 100)
  expect_equal(nrow(result), 2L)
  expect_equal(result$run_number, c(1L, 2L))
  expect_equal(result$length, c(2L, 3L))
  expect_equal(result$start, as.Date(c("2023-06-01", "2023-06-04")))
  expect_equal(result$end, as.Date(c("2023-06-02", "2023-06-06")))
})

test_that("NAs in value column do not cause an error", {
  df <- data.frame(
    Date = as.Date("2023-06-01") + 0:4,
    Flow = c(NA, NA, NA, NA, NA)
  )
  # Should run without error, returning a zero-run row
  result <- tally_runs(df, threshold = 100)
  expect_s3_class(result, "tbl_df")
  expect_equal(result$run_number, 0L)
})

# =============================================================================
# Column name argument tests
# =============================================================================

test_that("non-default datetime_col and value_col names work", {
  df <- data.frame(
    timestamp = as.Date("2023-06-01") + 0:4,
    temp      = c(120, 120, 120, 80, 80)
  )
  result <- tally_runs(
    df, datetime_col = "timestamp", value_col = "temp", threshold = 100
  )
  # 1 run: length 3
  expect_equal(nrow(result), 1L)
  expect_equal(result$length, 3L)
  expect_equal(result$start, as.Date("2023-06-01"))
  expect_equal(result$end, as.Date("2023-06-03"))
})

# =============================================================================
# Return structure tests
# =============================================================================

test_that("output is a tibble with exactly the specified column names", {
  df <- data.frame(
    Date = as.Date("2023-06-01") + 0:2,
    Flow = c(120, 120, 120)
  )
  result <- tally_runs(df, threshold = 100)
  expect_s3_class(result, "tbl_df")
  expect_equal(
    names(result),
    c("period", "run_number", "start", "end", "length", "duration")
  )
})

test_that("output column types match the contract specification", {
  result <- tally_runs(fixture_multi_run, threshold = 100)
  expect_type(result$period, "double")       # Numeric
  expect_type(result$run_number, "integer")  # Integer
  expect_type(result$length, "integer")      # Integer
  # start and end tested separately for Date / POSIXct preservation
})

test_that("start and end preserve Date class when input is Date", {
  df <- data.frame(
    Date = as.Date("2023-06-01") + 0:2,
    Flow = c(120, 120, 120)
  )
  result <- tally_runs(df, threshold = 100)
  expect_s3_class(result$start, "Date")
  expect_s3_class(result$end, "Date")
})

test_that("start and end preserve POSIXct class when input is POSIXct", {
  df <- data.frame(
    Date = as.POSIXct(
      c("2023-06-01 12:00", "2023-06-02 12:00", "2023-06-03 12:00"),
      tz = "America/New_York"
    ),
    Flow = c(120, 120, 120)
  )
  result <- tally_runs(df, threshold = 100)
  expect_s3_class(result$start, "POSIXct")
  expect_s3_class(result$end, "POSIXct")
})

test_that("zero-run row has run_number 0 and NA in detail columns", {
  df <- data.frame(
    Date = as.Date("2023-06-01") + 0:2,
    Flow = c(50, 60, 70)
  )
  result <- tally_runs(df, threshold = 100)
  expect_equal(result$run_number, 0L)
  expect_true(is.na(result$start))
  expect_true(is.na(result$end))
  expect_true(is.na(result$length))
  expect_true(is.na(result$duration))
})

# =============================================================================
# Duration tests
# =============================================================================

test_that("default duration_units uses the natural time step for daily data", {
  df <- data.frame(
    Date = as.Date("2023-06-01") + 0:4,
    Flow = c(120, 120, 120, 120, 120)
  )
  result <- tally_runs(df, threshold = 100)
  # 1 run: Jun 1–5, duration = end - start = 4 days
  expect_equal(as.numeric(result$duration), 4)
})

test_that("duration_units converts duration to the requested unit", {
  df <- data.frame(
    Date = as.Date("2023-06-01") + 0:2,
    Flow = c(120, 120, 120)
  )
  result_hours <- tally_runs(df, threshold = 100, duration_units = "hours")
  # Jun 1–3, 2 days elapsed = 48 hours
  expect_equal(as.numeric(result_hours$duration), 48)

  result_secs <- tally_runs(df, threshold = 100, duration_units = "secs")
  # 2 days = 172800 seconds
  expect_equal(as.numeric(result_secs$duration), 172800)
})

test_that("duration_units works with hourly POSIXct data", {
  df <- data.frame(
    Date = as.POSIXct("2023-06-01 00:00:00", tz = "UTC") +
      (0:5) * 3600,
    Flow = c(120, 120, 120, 120, 80, 80)
  )
  # 1 run: hours 0–3, duration = 3 hours
  result <- tally_runs(df, threshold = 100, duration_units = "hours")
  expect_equal(as.numeric(result$duration), 3)

  result_mins <- tally_runs(df, threshold = 100, duration_units = "mins")
  expect_equal(as.numeric(result_mins$duration), 180)
})

# =============================================================================
# Edge case tests
# =============================================================================

test_that("all values meet the condition produces one long run per period", {
  df <- data.frame(
    Date = as.Date("2023-06-01") + 0:9,
    Flow = rep(120, 10)
  )
  result <- tally_runs(df, threshold = 100)
  expect_equal(nrow(result), 1L)
  expect_equal(result$run_number, 1L)
  expect_equal(result$length, 10L)
})

test_that("no values meet the condition returns a zero-run row for each period", {
  # Spans two water years: Sep 29–Oct 2 2023
  df <- data.frame(
    Date = as.Date("2023-09-29") + 0:3,
    Flow = rep(80, 4)
  )
  result <- tally_runs(df, threshold = 100)
  # WY 2023: Sep 29–30, WY 2024: Oct 1–2 → two zero-run rows
  expect_equal(nrow(result), 2L)
  expect_equal(result$run_number, c(0L, 0L))
  expect_equal(result$period, c(2023, 2024))
  expect_true(all(is.na(result$start)))
  expect_true(all(is.na(result$end)))
  expect_true(all(is.na(result$length)))
})

test_that("single-row input meeting the condition produces a run of length 1", {
  df <- data.frame(
    Date = as.Date("2023-06-15"),
    Flow = 120
  )
  result <- tally_runs(df, threshold = 100)
  expect_equal(nrow(result), 1L)
  expect_equal(result$run_number, 1L)
  expect_equal(result$length, 1L)
  expect_equal(result$start, as.Date("2023-06-15"))
  expect_equal(result$end, as.Date("2023-06-15"))
  expect_equal(as.numeric(result$duration), 0)
})

test_that("single-row input not meeting the condition produces a zero-run row", {
  df <- data.frame(
    Date = as.Date("2023-06-15"),
    Flow = 50
  )
  result <- tally_runs(df, threshold = 100)
  expect_equal(nrow(result), 1L)
  expect_equal(result$run_number, 0L)
})

test_that("data spanning only one period returns results for that period only", {
  df <- data.frame(
    Date = as.Date("2023-01-10") + 0:4,
    Flow = c(120, 80, 120, 120, 80)
  )
  # All in WY 2023.  Runs: Jan 10 (len 1), Jan 12–13 (len 2).
  result <- tally_runs(df, threshold = 100)
  expect_true(all(result$period == 2023))
  expect_equal(nrow(result), 2L)
})

test_that("threshold equal to all values: >= detects a run, > does not", {
  df <- data.frame(
    Date = as.Date("2023-06-01") + 0:4,
    Flow = rep(100, 5)
  )
  result_gte <- tally_runs(df, threshold = 100, comparison = ">=")
  expect_equal(result_gte$run_number, 1L)
  expect_equal(result_gte$length, 5L)

  result_gt <- tally_runs(df, threshold = 100, comparison = ">")
  expect_equal(result_gt$run_number, 0L)
  expect_true(is.na(result_gt$length))
})

test_that("threshold equal to all values: <= detects a run, < does not", {
  df <- data.frame(
    Date = as.Date("2023-06-01") + 0:4,
    Flow = rep(100, 5)
  )
  result_lte <- tally_runs(df, threshold = 100, comparison = "<=")
  expect_equal(result_lte$run_number, 1L)
  expect_equal(result_lte$length, 5L)

  result_lt <- tally_runs(df, threshold = 100, comparison = "<")
  expect_equal(result_lt$run_number, 0L)
  expect_true(is.na(result_lt$length))
})

test_that("every period in the input appears in the output", {
  # 2 periods: WY 2023 has runs, WY 2024 does not
  df <- data.frame(
    Date = c(as.Date("2023-09-29") + 0:1,     # WY 2023: Sep 29–30
             as.Date("2023-10-01") + 0:1),      # WY 2024: Oct 1–2
    Flow = c(120, 120, 80, 80)
  )
  result <- tally_runs(df, threshold = 100)
  # WY 2023: 1 run; WY 2024: zero-run row
  expect_equal(sort(result$period), c(2023, 2024))
  expect_equal(nrow(result), 2L)
})

test_that("duration of a single-record run is zero", {
  df <- data.frame(
    Date = as.Date("2023-06-01") + 0:2,
    Flow = c(80, 120, 80)
  )
  result <- tally_runs(df, threshold = 100)
  # 1 run of length 1: Jun 2 to Jun 2, duration = 0
  expect_equal(result$length, 1L)
  expect_equal(as.numeric(result$duration), 0)
})
