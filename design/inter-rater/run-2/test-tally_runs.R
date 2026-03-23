# Tests derived from the Roxygen contract for tally_runs()
# Each test_that() block traces to one or more contract clauses.
# Expected values are hand-verified against inline test data.

# --- Shared fixture ---------------------------------------------------------
# Used by happy-path, return structure, and duration_units tests.
# 30 daily records in Jun 2022 (WY 2022), two exceedance runs above 100:
#   Jun 1-10 (10 records, Flow = 120) → run 1
#   Jun 11-15 (5 records, Flow = 80)  → gap
#   Jun 16-30 (15 records, Flow = 120) → run 2
fixture_daily <- data.frame(
  Date = as.Date("2022-06-01") + 0:29,
  Flow = c(rep(120, 10), rep(80, 5), rep(120, 15))
)

# =============================================================================
# Validation
# =============================================================================

test_that("error when df is not a data frame", {
  expect_error(tally_runs("not_a_df", threshold = 100), "df")
})

test_that("error when df has zero rows", {
  empty_df <- data.frame(Date = as.Date(character(0)), Flow = numeric(0))
  expect_error(tally_runs(empty_df, threshold = 100), "df")
})

test_that("error when datetime_col is not found in df", {
  df <- data.frame(Date = as.Date("2022-06-01"), Flow = 120)
  expect_error(
    tally_runs(df, datetime_col = "nonexistent", threshold = 100),
    "datetime_col|nonexistent"
  )
})

test_that("error when value_col is not found in df", {
  df <- data.frame(Date = as.Date("2022-06-01"), Flow = 120)
  expect_error(
    tally_runs(df, value_col = "nonexistent", threshold = 100),
    "value_col|nonexistent"
  )
})

test_that("error when datetime column is not Date or POSIXct", {
  df <- data.frame(Date = c("2022-06-01", "2022-06-02"), Flow = c(120, 120))
  expect_error(tally_runs(df, threshold = 100), "datetime_col|Date")
})

test_that("error when value column is not numeric", {
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:1,
    Flow = c("high", "low")
  )
  expect_error(tally_runs(df, threshold = 100), "value_col|Flow")
})

test_that("error when threshold is not a finite numeric scalar", {
  df <- data.frame(Date = as.Date("2022-06-01"), Flow = 120)
  expect_error(tally_runs(df, threshold = "abc"), "threshold")
  expect_error(tally_runs(df, threshold = NA_real_), "threshold")
  expect_error(tally_runs(df, threshold = Inf), "threshold")
  expect_error(tally_runs(df, threshold = c(1, 2)), "threshold")
})

test_that("error when comparison is not a valid operator", {
  df <- data.frame(Date = as.Date("2022-06-01"), Flow = 120)
  expect_error(tally_runs(df, threshold = 100, comparison = "=="), "comparison")
  expect_error(tally_runs(df, threshold = 100, comparison = "!="), "comparison")
})

test_that("error when period is invalid", {
  df <- data.frame(Date = as.Date("2022-06-01"), Flow = 120)
  expect_error(
    tally_runs(df, threshold = 100, period = "monthly"),
    "period"
  )
  expect_error(
    tally_runs(df, threshold = 100, period = c("0601", "0930", "1231")),
    "period"
  )
})

test_that("error when duration_units is not NULL or a recognized unit string", {
  df <- data.frame(Date = as.Date("2022-06-01") + 0:1, Flow = c(120, 120))
  expect_error(
    tally_runs(df, threshold = 100, duration_units = "fortnights"),
    "duration_units"
  )
})

# =============================================================================
# Happy-path
# =============================================================================

test_that("happy path: two runs in daily water-year data (contract example)", {
  result <- tally_runs(fixture_daily, threshold = 100)

  expect_equal(nrow(result), 2)
  # Run 1: Jun 1-10, 10 records
  expect_equal(result$start[1], as.Date("2022-06-01"))
  expect_equal(result$end[1], as.Date("2022-06-10"))
  expect_equal(result$length[1], 10L)
  expect_equal(result$run_number[1], 1L)
  # Run 2: Jun 16-30, 15 records
  expect_equal(result$start[2], as.Date("2022-06-16"))
  expect_equal(result$end[2], as.Date("2022-06-30"))
  expect_equal(result$length[2], 15L)
  expect_equal(result$run_number[2], 2L)
  # Both in WY 2022

  expect_equal(result$period, c(2022, 2022))
})

test_that("happy path: custom summer season (contract example)", {
  result <- tally_runs(fixture_daily, threshold = 100, period = c("0601", "0930"))

  # Same data, same threshold, but period is Jun 1-Sep 30

  # All 30 days are in Jun 2022, which falls within Jun 1-Sep 30 2022.
  # Ending year = 2022. Same two runs expected.
  expect_equal(nrow(result), 2)
  expect_equal(result$period, c(2022, 2022))
  expect_equal(result$run_number, c(1L, 2L))
  expect_equal(result$length, c(10L, 15L))
})

# =============================================================================
# Comparison operators
# =============================================================================

test_that(">= comparison includes values equal to threshold", {
  # Values: 100, 110, 100, 90, 100
  # >= 100: T, T, T, F, T → runs: {1-3} (length 3), {5} (length 1)
  df <- data.frame(
    Date = as.Date("2023-01-01") + 0:4,
    Flow = c(100, 110, 100, 90, 100)
  )
  result <- tally_runs(df, threshold = 100, comparison = ">=", period = "annual")

  expect_equal(nrow(result), 2)
  expect_equal(result$length, c(3L, 1L))
  expect_equal(result$start[1], as.Date("2023-01-01"))
  expect_equal(result$end[1], as.Date("2023-01-03"))
  expect_equal(result$start[2], as.Date("2023-01-05"))
  expect_equal(result$end[2], as.Date("2023-01-05"))
})

test_that("> comparison excludes values equal to threshold", {
  # Values: 100, 110, 100, 90, 100
  # > 100: F, T, F, F, F → runs: {2} (length 1)
  df <- data.frame(
    Date = as.Date("2023-01-01") + 0:4,
    Flow = c(100, 110, 100, 90, 100)
  )
  result <- tally_runs(df, threshold = 100, comparison = ">", period = "annual")

  expect_equal(nrow(result), 1)
  expect_equal(result$length, 1L)
  expect_equal(result$start, as.Date("2023-01-02"))
  expect_equal(result$end, as.Date("2023-01-02"))
})

test_that("<= comparison includes values equal to threshold", {
  # Values: 100, 110, 100, 90, 100
  # <= 100: T, F, T, T, T → runs: {1} (length 1), {3-5} (length 3)
  df <- data.frame(
    Date = as.Date("2023-01-01") + 0:4,
    Flow = c(100, 110, 100, 90, 100)
  )
  result <- tally_runs(df, threshold = 100, comparison = "<=", period = "annual")

  expect_equal(nrow(result), 2)
  expect_equal(result$length, c(1L, 3L))
  expect_equal(result$start[1], as.Date("2023-01-01"))
  expect_equal(result$end[1], as.Date("2023-01-01"))
  expect_equal(result$start[2], as.Date("2023-01-03"))
  expect_equal(result$end[2], as.Date("2023-01-05"))
})

test_that("< comparison excludes values equal to threshold", {
  # Values: 100, 110, 100, 90, 100
  # < 100: F, F, F, T, F → runs: {4} (length 1)
  df <- data.frame(
    Date = as.Date("2023-01-01") + 0:4,
    Flow = c(100, 110, 100, 90, 100)
  )
  result <- tally_runs(df, threshold = 100, comparison = "<", period = "annual")

  expect_equal(nrow(result), 1)
  expect_equal(result$length, 1L)
  expect_equal(result$start, as.Date("2023-01-04"))
  expect_equal(result$end, as.Date("2023-01-04"))
})

# =============================================================================
# Period partitioning
# =============================================================================

test_that("water_year labels by ending year (WY 2022 = Oct 2021-Sep 2022)", {
  # Data in Jun 2022 → WY 2022 (ending year)
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:2,
    Flow = c(120, 120, 120)
  )
  result <- tally_runs(df, threshold = 100)

  expect_equal(result$period, 2022)
})

test_that("annual period labels by calendar year", {
  df <- data.frame(
    Date = as.Date("2022-07-10") + 0:2,
    Flow = c(120, 120, 120)
  )
  result <- tally_runs(df, threshold = 100, period = "annual")

  expect_equal(result$period, 2022)
})

test_that("runs cannot span water year boundaries", {
  # Continuous exceedance from Sep 28 to Oct 3 (2022)
  # Sep 28-30 → WY 2022; Oct 1-3 → WY 2023
  # Should produce two separate runs, one per period
  df <- data.frame(
    Date = as.Date("2022-09-28") + 0:5,
    Flow = rep(120, 6)
  )
  result <- tally_runs(df, threshold = 100)

  expect_equal(nrow(result), 2)
  expect_equal(result$period, c(2022, 2023))
  expect_equal(result$run_number, c(1L, 1L))
  # WY 2022 portion: Sep 28-30, length 3
  expect_equal(result$start[1], as.Date("2022-09-28"))
  expect_equal(result$end[1], as.Date("2022-09-30"))
  expect_equal(result$length[1], 3L)
  # WY 2023 portion: Oct 1-3, length 3
  expect_equal(result$start[2], as.Date("2022-10-01"))
  expect_equal(result$end[2], as.Date("2022-10-03"))
  expect_equal(result$length[2], 3L)
})

test_that("runs cannot span annual period boundaries", {
  # Continuous exceedance from Dec 30 to Jan 2
  # Dec 30-31 → 2022; Jan 1-2 → 2023
  df <- data.frame(
    Date = as.Date("2022-12-30") + 0:3,
    Flow = rep(120, 4)
  )
  result <- tally_runs(df, threshold = 100, period = "annual")

  expect_equal(nrow(result), 2)
  expect_equal(result$period, c(2022, 2023))
  expect_equal(result$run_number, c(1L, 1L))
  expect_equal(result$length[1], 2L)
  expect_equal(result$length[2], 2L)
})

test_that("custom season excludes records outside the span", {
  # Data: May 30, 31, Jun 1, 2, 3, 4 — all Flow = 120
  # Season: Jun 1-Sep 30
  # May 30-31 should be excluded
  # Only Jun 1-4 remain → one run of length 4
  df <- data.frame(
    Date = as.Date("2022-05-30") + 0:5,
    Flow = rep(120, 6)
  )
  result <- tally_runs(df, threshold = 100, period = c("0601", "0930"))

  expect_equal(nrow(result), 1)
  expect_equal(result$start, as.Date("2022-06-01"))
  expect_equal(result$end, as.Date("2022-06-04"))
  expect_equal(result$length, 4L)
})

test_that("custom season labels by ending year", {
  df <- data.frame(
    Date = as.Date("2022-07-01") + 0:2,
    Flow = c(120, 120, 120)
  )
  result <- tally_runs(df, threshold = 100, period = c("0601", "0930"))

  # Season Jun 1-Sep 30 in 2022, ending year = 2022
  expect_equal(result$period, 2022)
})

test_that("wrap-around custom season spans year boundary", {
  # Season: Oct 1-Mar 31 (wraps around year boundary)
  # Data: Oct 1-3 (2022) all 120, Mar 29 80, Mar 30-31 120 (2023)
  # One span: Oct 2022-Mar 2023, ending year = 2023
  # Oct 1-3: consecutive, all >= 100 → run 1 (length 3)
  # Mar 29: 80 → not in run
  # Mar 30-31: both 120 → run 2 (length 2)
  df <- data.frame(
    Date = c(as.Date("2022-10-01") + 0:2, as.Date("2023-03-29") + 0:2),
    Flow = c(120, 120, 120, 80, 120, 120)
  )
  result <- tally_runs(df, threshold = 100, period = c("1001", "0331"))

  expect_equal(result$period[1], 2023)
  expect_true(all(result$period == 2023))
  expect_equal(result$run_number, c(1L, 2L))
  expect_equal(result$length[1], 3L)
  expect_equal(result$start[1], as.Date("2022-10-01"))
  expect_equal(result$end[1], as.Date("2022-10-03"))
  expect_equal(result$length[2], 2L)
  expect_equal(result$start[2], as.Date("2023-03-30"))
  expect_equal(result$end[2], as.Date("2023-03-31"))
})

# =============================================================================
# NA behaviour
# =============================================================================

test_that("NA in value column breaks a run into two separate runs", {
  # Values: 120, 120, NA, 120, 120
  # Expected: two runs of length 2 each
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:4,
    Flow = c(120, 120, NA, 120, 120)
  )
  result <- tally_runs(df, threshold = 100)

  expect_equal(nrow(result), 2)
  expect_equal(result$run_number, c(1L, 2L))
  expect_equal(result$length, c(2L, 2L))
  expect_equal(result$start[1], as.Date("2022-06-01"))
  expect_equal(result$end[1], as.Date("2022-06-02"))
  expect_equal(result$start[2], as.Date("2022-06-04"))
  expect_equal(result$end[2], as.Date("2022-06-05"))
})

test_that("NAs in value column do not cause an error", {
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:2,
    Flow = c(NA, NA, NA)
  )
  # Should not error; all NAs means no runs → zero-run row
  result <- tally_runs(df, threshold = 100)

  expect_equal(nrow(result), 1)
  expect_equal(result$run_number, 0L)
})

# =============================================================================
# Return structure
# =============================================================================

test_that("output is a tibble", {
  result <- tally_runs(fixture_daily, threshold = 100)
  expect_s3_class(result, "tbl_df")
})

test_that("output has exactly the specified column names", {
  result <- tally_runs(fixture_daily, threshold = 100)
  expect_equal(
    names(result),
    c("period", "run_number", "start", "end", "length", "duration")
  )
})

test_that("output column types match contract specification", {
  result <- tally_runs(fixture_daily, threshold = 100)
  expect_type(result$period, "double")
  expect_type(result$run_number, "integer")
  expect_type(result$length, "integer")
  # start and end: same class as input (Date)
  expect_s3_class(result$start, "Date")
  expect_s3_class(result$end, "Date")
})

test_that("start and end preserve POSIXct class when input is POSIXct", {
  df <- data.frame(
    Date = as.POSIXct(
      c("2022-06-01 00:00:00", "2022-06-02 00:00:00", "2022-06-03 00:00:00")
    ),
    Flow = c(120, 120, 120)
  )
  result <- tally_runs(df, threshold = 100)

  expect_s3_class(result$start, "POSIXct")
  expect_s3_class(result$end, "POSIXct")
})

# =============================================================================
# Zero-run periods
# =============================================================================

test_that("period with no runs produces a single row with run_number 0 and NAs", {
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:4,
    Flow = c(80, 80, 80, 80, 80)
  )
  result <- tally_runs(df, threshold = 100)

  expect_equal(nrow(result), 1)
  expect_equal(result$period, 2022)
  expect_equal(result$run_number, 0L)
  expect_true(is.na(result$start))
  expect_true(is.na(result$end))
  expect_true(is.na(result$length))
  expect_true(is.na(result$duration))
})

test_that("every period in the input appears in the output", {
  # WY 2022 data (Jun 2022): all below threshold → zero-run row
  # WY 2023 data (Oct 2022): all above threshold → one run
  df <- data.frame(
    Date = c(as.Date("2022-06-01") + 0:2, as.Date("2022-10-01") + 0:2),
    Flow = c(80, 80, 80, 120, 120, 120)
  )
  result <- tally_runs(df, threshold = 100)

  expect_equal(nrow(result), 2)
  expect_equal(result$period, c(2022, 2023))
  # WY 2022: zero-run row
  expect_equal(result$run_number[1], 0L)
  expect_true(is.na(result$start[1]))
  # WY 2023: one run of length 3
  expect_equal(result$run_number[2], 1L)
  expect_equal(result$length[2], 3L)
})

# =============================================================================
# Duration and duration_units
# =============================================================================

test_that("duration is elapsed time from start to end", {
  result <- tally_runs(fixture_daily, threshold = 100)

  # Run 1: Jun 1 to Jun 10 = 9 days elapsed
  expect_equal(as.numeric(result$duration[1]), 9)
  # Run 2: Jun 16 to Jun 30 = 14 days elapsed
  expect_equal(as.numeric(result$duration[2]), 14)
})

test_that("single-record run has duration of zero", {
  df <- data.frame(
    Date = as.Date(c("2022-06-01", "2022-06-02", "2022-06-03")),
    Flow = c(120, 80, 120)
  )
  result <- tally_runs(df, threshold = 100)

  # Two runs of length 1 each; duration = 0 for both
  expect_equal(nrow(result), 2)
  expect_equal(as.numeric(result$duration[1]), 0)
  expect_equal(as.numeric(result$duration[2]), 0)
})

test_that("explicit duration_units converts output duration", {
  # 10 daily records, one run from Jun 1 to Jun 10.
  # Duration = 9 days = 216 hours
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:9,
    Flow = rep(120, 10)
  )
  result <- tally_runs(df, threshold = 100, duration_units = "hours")

  expect_equal(as.numeric(result$duration), 216)
})

# =============================================================================
# Column name flexibility
# =============================================================================

test_that("non-default column names work when specified", {
  df <- data.frame(
    timestamp = as.Date("2022-06-01") + 0:2,
    discharge = c(120, 80, 120)
  )
  result <- tally_runs(
    df, datetime_col = "timestamp", value_col = "discharge", threshold = 100
  )

  # Records: 120, 80, 120 with threshold >= 100
  # Run 1: Jun 1 (length 1), Run 2: Jun 3 (length 1)
  expect_equal(nrow(result), 2)
  expect_equal(result$length, c(1L, 1L))
  expect_equal(result$start[1], as.Date("2022-06-01"))
  expect_equal(result$start[2], as.Date("2022-06-03"))
})

# =============================================================================
# Edge cases
# =============================================================================

test_that("single-row input meeting the condition produces one run", {
  df <- data.frame(Date = as.Date("2022-06-15"), Flow = 120)
  result <- tally_runs(df, threshold = 100)

  expect_equal(nrow(result), 1)
  expect_equal(result$run_number, 1L)
  expect_equal(result$length, 1L)
  expect_equal(result$start, as.Date("2022-06-15"))
  expect_equal(result$end, as.Date("2022-06-15"))
})

test_that("single-row input not meeting the condition produces a zero-run row", {
  df <- data.frame(Date = as.Date("2022-06-15"), Flow = 80)
  result <- tally_runs(df, threshold = 100)

  expect_equal(nrow(result), 1)
  expect_equal(result$run_number, 0L)
  expect_true(is.na(result$start))
  expect_true(is.na(result$length))
})

test_that("all values meet the condition produces a single run", {
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:4,
    Flow = c(120, 130, 110, 150, 105)
  )
  result <- tally_runs(df, threshold = 100)

  expect_equal(nrow(result), 1)
  expect_equal(result$run_number, 1L)
  expect_equal(result$length, 5L)
  expect_equal(result$start, as.Date("2022-06-01"))
  expect_equal(result$end, as.Date("2022-06-05"))
})

test_that("run_number is sequential within a period", {
  # Three separate runs in the same period
  # Values: 120, 80, 120, 80, 120 → 3 runs of length 1
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:4,
    Flow = c(120, 80, 120, 80, 120)
  )
  result <- tally_runs(df, threshold = 100)

  expect_equal(result$run_number, c(1L, 2L, 3L))
})

test_that("multiple periods with mixed results: runs in some, none in others", {
  # WY 2022 (Jun 2022): two above, one below → one run (length 2) + one run (length 1)
  #   Wait, let me be more precise.
  # Jun 1: 120 >= 100 ✓, Jun 2: 80 ✗, Jun 3: 120 ✓
  # WY 2023 (Oct 2022): all below → zero-run row
  df <- data.frame(
    Date = c(as.Date("2022-06-01") + 0:2, as.Date("2022-10-01") + 0:2),
    Flow = c(120, 80, 120, 50, 60, 70)
  )
  result <- tally_runs(df, threshold = 100)

  # WY 2022: run at Jun 1 (length 1), run at Jun 3 (length 1)
  # WY 2023: zero-run row
  expect_equal(nrow(result), 3)
  expect_equal(result$period, c(2022, 2022, 2023))
  expect_equal(result$run_number, c(1L, 2L, 0L))
  expect_equal(result$length[1], 1L)
  expect_equal(result$length[2], 1L)
  expect_true(is.na(result$length[3]))
})
