# Tests derived from the Roxygen contract of tally_runs().
# Each test_that() corresponds to one or more testable claims in the contract.

# --- Shared fixtures ---

# 30 days of daily discharge in June 2022 (water year 2022).
# Flow pattern: 10 days at 120, 5 days at 80, 15 days at 120.
# With threshold = 100 and comparison ">=":
#   Run 1: Jun 1-10 (length 10, duration 9 days)
#   Run 2: Jun 16-30 (length 15, duration 14 days)
fixture_june <- data.frame(
  Date = as.Date("2022-06-01") + 0:29,
  Flow = c(rep(120, 10), rep(80, 5), rep(120, 15))
)

# Data spanning a water year boundary (Sep 28 - Oct 3, 2022).
# All values exceed threshold. WY 2022 ends Sep 30; WY 2023 starts Oct 1.
# With threshold = 100, ">=":
#   WY 2022: Sep 28-30 → run length 3, duration 2 days
#   WY 2023: Oct 1-3 → run length 3, duration 2 days
fixture_wy_boundary <- data.frame(
  Date = as.Date("2022-09-28") + 0:5,
  Flow = rep(120, 6)
)

# Data in two water years: Jun 2022 (WY 2022) and Nov 2022 (WY 2023).
# WY 2022: all below threshold → zero-run period row
# WY 2023: all above threshold → one run
# With threshold = 100, ">=":
#   WY 2022: period=2022, run_number=0, start/end/length/duration=NA
#   WY 2023: period=2023, run_number=1, start=Nov 1, end=Nov 5, length=5, duration=4 days
fixture_two_wy <- data.frame(
  Date = c(as.Date("2022-06-01") + 0:4, as.Date("2022-11-01") + 0:4),
  Flow = c(rep(80, 5), rep(120, 5))
)


# ==========================================================================
# Validation tests
# ==========================================================================

test_that("error when df is not a data frame", {
  expect_error(tally_runs(df = "not a df", threshold = 100), "df")
  expect_error(tally_runs(df = list(a = 1), threshold = 100), "df")
  expect_error(tally_runs(df = 42, threshold = 100), "df")
})

test_that("error when df has zero rows", {
  empty_df <- data.frame(Date = as.Date(character(0)), Flow = numeric(0))
  expect_error(tally_runs(empty_df, threshold = 100), "df|row|empty")
})

test_that("error when datetime_col is not found in df", {
  df <- data.frame(Date = as.Date("2022-06-01"), Flow = 120)
  expect_error(
    tally_runs(df, datetime_col = "timestamp", threshold = 100),
    "datetime_col|timestamp"
  )
})

test_that("error when value_col is not found in df", {
  df <- data.frame(Date = as.Date("2022-06-01"), Flow = 120)
  expect_error(
    tally_runs(df, value_col = "discharge", threshold = 100),
    "value_col|discharge"
  )
})

test_that("error when datetime_col column is not Date or POSIXct", {
  df <- data.frame(Date = c("2022-06-01", "2022-06-02"), Flow = c(120, 120))
  expect_error(tally_runs(df, threshold = 100), "datetime_col|Date|POSIXct")

  df_numeric <- data.frame(Date = c(1, 2), Flow = c(120, 120))
  expect_error(tally_runs(df_numeric, threshold = 100), "datetime_col|Date|POSIXct")
})

test_that("error when value_col column is not numeric", {
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:1,
    Flow = c("high", "low")
  )
  expect_error(tally_runs(df, threshold = 100), "value_col|Flow|numeric")
})

test_that("error when threshold is not a finite numeric scalar", {
  df <- data.frame(Date = as.Date("2022-06-01"), Flow = 120)
  expect_error(tally_runs(df, threshold = "abc"), "threshold")
  expect_error(tally_runs(df, threshold = Inf), "threshold")
  expect_error(tally_runs(df, threshold = -Inf), "threshold")
  expect_error(tally_runs(df, threshold = NA_real_), "threshold")
  expect_error(tally_runs(df, threshold = c(1, 2)), "threshold")
  expect_error(tally_runs(df, threshold = numeric(0)), "threshold")
})

test_that("error when comparison is not a valid operator", {
  df <- data.frame(Date = as.Date("2022-06-01"), Flow = 120)
  expect_error(tally_runs(df, threshold = 100, comparison = "=="), "comparison")
  expect_error(tally_runs(df, threshold = 100, comparison = "!="), "comparison")
  expect_error(tally_runs(df, threshold = 100, comparison = ""), "comparison")
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
  expect_error(
    tally_runs(df, threshold = 100, period = c("1301", "0930")),
    "period"
  )
})

test_that("error when duration_units is not NULL or a recognized unit string", {
  df <- data.frame(Date = as.Date("2022-06-01") + 0:1, Flow = c(120, 120))
  expect_error(
    tally_runs(df, threshold = 100, duration_units = "fortnights"),
    "duration_units"
  )
  expect_error(
    tally_runs(df, threshold = 100, duration_units = 42),
    "duration_units"
  )
})


# ==========================================================================
# Return structure tests
# ==========================================================================

test_that("output is a tibble", {
  result <- tally_runs(fixture_june, threshold = 100)
  expect_s3_class(result, "tbl_df")
})

test_that("output has exactly the specified column names", {
  result <- tally_runs(fixture_june, threshold = 100)
  expect_equal(
    names(result),
    c("period", "run_number", "start", "end", "length", "duration")
  )
})

test_that("output column types match the contract", {
  result <- tally_runs(fixture_june, threshold = 100)
  expect_type(result$period, "double")
  expect_type(result$run_number, "integer")
  expect_s3_class(result$start, "Date")
  expect_s3_class(result$end, "Date")
  expect_type(result$length, "integer")
})

test_that("start and end preserve POSIXct class when input is POSIXct", {
  df <- data.frame(
    Date = as.POSIXct(c("2022-06-01", "2022-06-02", "2022-06-03"),
                      tz = "UTC"),
    Flow = c(120, 120, 120)
  )
  result <- tally_runs(df, threshold = 100)
  expect_s3_class(result$start, "POSIXct")
  expect_s3_class(result$end, "POSIXct")
})


# ==========================================================================
# Happy-path tests
# ==========================================================================

test_that("basic two-run example from contract produces correct results", {
  # fixture_june: 10 above, 5 below, 15 above. Threshold 100, >=.
  # All in WY 2022 (Jun 2022 → ending year 2022).
  result <- tally_runs(fixture_june, threshold = 100)

  expect_equal(nrow(result), 2L)
  expect_equal(result$period, c(2022, 2022))
  expect_equal(result$run_number, c(1L, 2L))
  expect_equal(result$start, as.Date(c("2022-06-01", "2022-06-16")))
  expect_equal(result$end, as.Date(c("2022-06-10", "2022-06-30")))
  expect_equal(result$length, c(10L, 15L))
  # Duration: Jun 1 to Jun 10 = 9 days; Jun 16 to Jun 30 = 14 days
  expect_equal(as.numeric(result$duration), c(9, 14))
})

test_that("custom season example from contract works", {
  # period = c("0601", "0930") → Jun 1 to Sep 30.

  # All 30 days of fixture_june fall within this span.
  # Same runs as happy path; season labeled by ending year.
  # Jun 2022 → season ends Sep 30, 2022 → label = 2022.
  result <- tally_runs(fixture_june, threshold = 100, period = c("0601", "0930"))

  expect_equal(nrow(result), 2L)
  expect_equal(result$period, c(2022, 2022))
  expect_equal(result$run_number, c(1L, 2L))
  expect_equal(result$length, c(10L, 15L))
})

test_that("default column names work with Date and Flow columns", {
  # The defaults are datetime_col="Date", value_col="Flow".
  # fixture_june uses these defaults. Just confirm it doesn't error
  # and returns the right shape.
  result <- tally_runs(fixture_june, threshold = 100)
  expect_equal(nrow(result), 2L)
})

test_that("non-default column names are respected", {
  df <- data.frame(
    timestamp = as.Date("2022-06-01") + 0:4,
    discharge = c(120, 120, 80, 120, 120)
  )
  # threshold=100, >=: records 1-2 (run 1), records 4-5 (run 2)
  result <- tally_runs(df, datetime_col = "timestamp", value_col = "discharge",
                       threshold = 100)
  expect_equal(nrow(result), 2L)
  expect_equal(result$length, c(2L, 2L))
  expect_equal(result$start, as.Date(c("2022-06-01", "2022-06-04")))
  expect_equal(result$end, as.Date(c("2022-06-02", "2022-06-05")))
})


# ==========================================================================
# Comparison operator tests
# ==========================================================================

test_that(">= includes records equal to threshold", {
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:3,
    Flow = c(100, 100, 80, 100)
  )
  # >= 100: records 1-2 (run 1, length 2), record 4 (run 2, length 1)
  result <- tally_runs(df, threshold = 100, comparison = ">=")
  expect_equal(nrow(result), 2L)
  expect_equal(result$length, c(2L, 1L))
})

test_that("> excludes records equal to threshold", {
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:3,
    Flow = c(100, 101, 80, 101)
  )
  # > 100: record 2 (run 1, length 1), record 4 (run 2, length 1)
  result <- tally_runs(df, threshold = 100, comparison = ">")
  expect_equal(nrow(result), 2L)
  expect_equal(result$length, c(1L, 1L))
  expect_equal(result$start, as.Date(c("2022-06-02", "2022-06-04")))
})

test_that("<= includes records equal to threshold", {
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:4,
    Flow = c(100, 80, 120, 100, 90)
  )
  # <= 100: records 1-2 (run 1, length 2), records 4-5 (run 2, length 2)
  result <- tally_runs(df, threshold = 100, comparison = "<=")
  expect_equal(nrow(result), 2L)
  expect_equal(result$length, c(2L, 2L))
})

test_that("< excludes records equal to threshold", {
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:4,
    Flow = c(100, 80, 120, 100, 90)
  )
  # < 100: record 2 (run 1, length 1), record 5 (run 2, length 1)
  result <- tally_runs(df, threshold = 100, comparison = "<")
  expect_equal(nrow(result), 2L)
  expect_equal(result$length, c(1L, 1L))
  expect_equal(result$start, as.Date(c("2022-06-02", "2022-06-05")))
})


# ==========================================================================
# Period partitioning tests
# ==========================================================================

test_that("water_year labels by ending year (WY 2022 = Oct 2021-Sep 2022)", {
  # June 2022 is in WY 2022 (ends Sep 30, 2022).
  result <- tally_runs(fixture_june, threshold = 100)
  expect_equal(unique(result$period), 2022)
})

test_that("annual period labels by calendar year", {
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:4,
    Flow = rep(120, 5)
  )
  result <- tally_runs(df, threshold = 100, period = "annual")
  expect_equal(unique(result$period), 2022)
  expect_equal(result$run_number, 1L)
})

test_that("runs cannot span water year boundaries", {
  # fixture_wy_boundary: Sep 28-Oct 3, 2022. All values 120, threshold 100.
  # WY boundary at Oct 1.
  # Expected: 2 runs, one per WY.
  result <- tally_runs(fixture_wy_boundary, threshold = 100)

  expect_equal(nrow(result), 2L)
  expect_equal(result$period, c(2022, 2023))
  expect_equal(result$run_number, c(1L, 1L))
  # WY 2022 run: Sep 28-30, length 3, duration 2 days
  expect_equal(result$start[1], as.Date("2022-09-28"))
  expect_equal(result$end[1], as.Date("2022-09-30"))
  expect_equal(result$length[1], 3L)
  expect_equal(as.numeric(result$duration[1]), 2)
  # WY 2023 run: Oct 1-3, length 3, duration 2 days
  expect_equal(result$start[2], as.Date("2022-10-01"))
  expect_equal(result$end[2], as.Date("2022-10-03"))
  expect_equal(result$length[2], 3L)
  expect_equal(as.numeric(result$duration[2]), 2)
})

test_that("zero-run periods produce a row with run_number=0 and NAs", {
  # fixture_two_wy: WY 2022 all below, WY 2023 all above.
  result <- tally_runs(fixture_two_wy, threshold = 100)

  expect_equal(nrow(result), 2L)

  # WY 2022: zero-run period
  wy22 <- result[result$period == 2022, ]
  expect_equal(wy22$run_number, 0L)
  expect_true(is.na(wy22$start))
  expect_true(is.na(wy22$end))
  expect_true(is.na(wy22$length))
  expect_true(is.na(wy22$duration))

  # WY 2023: one run
  wy23 <- result[result$period == 2023, ]
  expect_equal(wy23$run_number, 1L)
  expect_equal(wy23$start, as.Date("2022-11-01"))
  expect_equal(wy23$end, as.Date("2022-11-05"))
  expect_equal(wy23$length, 5L)
})

test_that("every period in the input appears in the output", {
  # fixture_two_wy spans WY 2022 and WY 2023.
  result <- tally_runs(fixture_two_wy, threshold = 100)
  expect_true(2022 %in% result$period)
  expect_true(2023 %in% result$period)
})

test_that("custom season excludes records outside the span", {
  # Data: Jun 1-10, 2022. Season: Jul 1 - Sep 30 (c("0701", "0930")).
  # All records are in June → outside the span → no data in season.
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:9,
    Flow = rep(120, 10)
  )
  result <- tally_runs(df, threshold = 100, period = c("0701", "0930"))
  # No records fall in the season, so output should reflect zero runs
  # (or possibly zero rows if no period is created — contract says
  # "every period in the input appears in the output", but if no records
  # are in any period, the behavior may be empty).
  # The safest assertion: no run with length > 0.
  expect_true(all(is.na(result$length)) || nrow(result) == 0L)
})

test_that("wrap-around custom season works", {
  # Season: Oct 1 - Mar 31 (c("1001", "0331")). Wrap-around.
  # Data: Nov 1-5, 2022 (inside season). All above threshold.
  # Season labeled by ending year: ends Mar 31, 2023 → label = 2023.
  df <- data.frame(
    Date = as.Date("2022-11-01") + 0:4,
    Flow = rep(120, 5)
  )
  result <- tally_runs(df, threshold = 100, period = c("1001", "0331"))

  expect_equal(nrow(result), 1L)
  expect_equal(result$period, 2023)
  expect_equal(result$length, 5L)
})


# ==========================================================================
# NA behaviour tests
# ==========================================================================

test_that("NA in value column breaks a run into two separate runs", {
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:5,
    Flow = c(120, 120, NA, 120, 120, 120)
  )
  # >= 100: records 1-2 (run 1), NA breaks, records 4-6 (run 2)
  result <- tally_runs(df, threshold = 100)

  runs <- result[!is.na(result$length), ]
  expect_equal(nrow(runs), 2L)
  expect_equal(runs$length, c(2L, 3L))
  expect_equal(runs$start, as.Date(c("2022-06-01", "2022-06-04")))
  expect_equal(runs$end, as.Date(c("2022-06-02", "2022-06-06")))
})

test_that("NAs in value column do not cause an error", {
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:4,
    Flow = c(NA, NA, NA, NA, NA)
  )
  # All NAs → no runs. Should not error.
  expect_no_error(tally_runs(df, threshold = 100))
})


# ==========================================================================
# Duration tests
# ==========================================================================

test_that("duration reflects elapsed time from start to end", {
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:4,
    Flow = rep(120, 5)
  )
  # Single run: Jun 1 to Jun 5. Duration = 4 days.
  result <- tally_runs(df, threshold = 100)
  expect_equal(as.numeric(result$duration), 4)
})

test_that("single-record run has duration zero", {
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:2,
    Flow = c(80, 120, 80)
  )
  # One run: Jun 2 only. Length 1, duration = 0 (start == end).
  result <- tally_runs(df, threshold = 100)
  runs <- result[!is.na(result$length), ]
  expect_equal(runs$length, 1L)
  expect_equal(as.numeric(runs$duration), 0)
})

test_that("explicit duration_units converts duration", {
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:4,
    Flow = rep(120, 5)
  )
  # Run: Jun 1-5. Duration = 4 days = 4*24 = 96 hours.
  result <- tally_runs(df, threshold = 100, duration_units = "hours")
  expect_equal(as.numeric(result$duration), 96)
})


# ==========================================================================
# Edge case tests
# ==========================================================================

test_that("single-row input meeting threshold produces one run", {
  df <- data.frame(Date = as.Date("2022-06-01"), Flow = 120)
  result <- tally_runs(df, threshold = 100)

  runs <- result[!is.na(result$length), ]
  expect_equal(nrow(runs), 1L)
  expect_equal(runs$length, 1L)
  expect_equal(runs$start, as.Date("2022-06-01"))
  expect_equal(runs$end, as.Date("2022-06-01"))
})

test_that("single-row input not meeting threshold produces zero-run row", {
  df <- data.frame(Date = as.Date("2022-06-01"), Flow = 80)
  result <- tally_runs(df, threshold = 100)

  expect_equal(nrow(result), 1L)
  expect_equal(result$run_number, 0L)
  expect_true(is.na(result$length))
})

test_that("all values meet condition produces a single run per period", {
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:9,
    Flow = rep(120, 10)
  )
  result <- tally_runs(df, threshold = 100)

  expect_equal(nrow(result), 1L)
  expect_equal(result$run_number, 1L)
  expect_equal(result$length, 10L)
})

test_that("no values meet condition produces a zero-run row", {
  df <- data.frame(
    Date = as.Date("2022-06-01") + 0:9,
    Flow = rep(80, 10)
  )
  result <- tally_runs(df, threshold = 100)

  expect_equal(nrow(result), 1L)
  expect_equal(result$run_number, 0L)
  expect_true(is.na(result$start))
  expect_true(is.na(result$end))
  expect_true(is.na(result$length))
  expect_true(is.na(result$duration))
})

test_that("run_number is sequential within a period", {
  # fixture_june has 2 runs in WY 2022.
  result <- tally_runs(fixture_june, threshold = 100)
  expect_equal(result$run_number, c(1L, 2L))
})

test_that("multiple periods with mixed results", {
  # Create data with 3 water years:
  # WY 2022 (Jun 2022): 1 run above threshold
  # WY 2023 (Nov 2022): no runs above threshold
  # WY 2023 also has (Mar 2023): 1 run above threshold
  # Actually, let me be more careful:
  # Jun 2022 → WY 2022. Aug 2022 → WY 2022. Nov 2022 → WY 2023.
  df <- data.frame(
    Date = c(as.Date("2022-06-01") + 0:2,  # WY 2022: Jun 1-3
             as.Date("2022-06-10") + 0:1,   # WY 2022: Jun 10-11
             as.Date("2022-11-01") + 0:2),  # WY 2023: Nov 1-3
    Flow = c(120, 120, 120,   # WY 2022 run 1
             80, 80,          # WY 2022 below threshold
             120, 120, 120)   # WY 2023 run 1
  )
  result <- tally_runs(df, threshold = 100)

  wy22 <- result[result$period == 2022, ]
  wy23 <- result[result$period == 2023, ]

  # WY 2022: 1 run (Jun 1-3, length 3). Jun 10-11 are below → no run.
  expect_equal(nrow(wy22), 1L)
  expect_equal(wy22$run_number, 1L)
  expect_equal(wy22$length, 3L)

  # WY 2023: 1 run (Nov 1-3, length 3).
  expect_equal(nrow(wy23), 1L)
  expect_equal(wy23$run_number, 1L)
  expect_equal(wy23$length, 3L)
})
