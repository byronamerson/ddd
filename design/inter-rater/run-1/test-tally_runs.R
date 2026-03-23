# Tests derived from the Roxygen contract of tally_runs()
# Source: R/tally_runs.R (Roxygen block only; function body is a stub)
# Agent: run-1 (inter-rater reliability experiment)

# --- Shared fixture ---
# 30 daily records in June 2022 (all within WY 2022).
# Flow pattern: 120 x10, 80 x5, 120 x15
# With threshold=100 and comparison=">=":
#   Run 1: indices 1-10  (2022-06-01 to 2022-06-10), length=10, duration=9 days
#   Run 2: indices 16-30 (2022-06-16 to 2022-06-30), length=15, duration=14 days
fixture_june <- data.frame(
  Date = as.Date("2022-06-01") + 0:29,
  Flow = c(rep(120, 10), rep(80, 5), rep(120, 15))
)

# ============================================================
# Validation
# ============================================================

test_that("error when df is not a data frame", {
  expect_error(tally_runs("not_a_df", threshold = 100), "df")
})

test_that("error when df has zero rows", {
  empty_df <- data.frame(Date = as.Date(character(0)), Flow = numeric(0))
  expect_error(tally_runs(empty_df, threshold = 100), "df")
})

test_that("error when datetime_col is not found in df", {
  df <- data.frame(Date = as.Date("2023-01-01"), Flow = 50)
  expect_error(
    tally_runs(df, datetime_col = "timestamp", threshold = 100),
    "datetime_col|timestamp"
  )
})

test_that("error when value_col is not found in df", {
  df <- data.frame(Date = as.Date("2023-01-01"), Flow = 50)
  expect_error(
    tally_runs(df, value_col = "discharge", threshold = 100),
    "value_col|discharge"
  )
})

test_that("error when datetime column is not Date or POSIXct", {
  df <- data.frame(Date = c("2023-01-01", "2023-01-02"), Flow = c(50, 60))
  expect_error(tally_runs(df, threshold = 100), "datetime_col|Date|POSIXct")
})

test_that("error when value column is not numeric", {
  df <- data.frame(
    Date = as.Date("2023-01-01") + 0:1,
    Flow = c("high", "low")
  )
  expect_error(tally_runs(df, threshold = 100), "value_col|numeric")
})

test_that("error when threshold is not a finite numeric scalar", {
  df <- data.frame(Date = as.Date("2023-01-01"), Flow = 50)
  expect_error(tally_runs(df, threshold = "abc"), "threshold")
  expect_error(tally_runs(df, threshold = Inf), "threshold")
  expect_error(tally_runs(df, threshold = NA_real_), "threshold")
  expect_error(tally_runs(df, threshold = c(1, 2)), "threshold")
})

test_that("error when comparison is not a valid operator", {
  df <- data.frame(Date = as.Date("2023-01-01"), Flow = 50)
  expect_error(tally_runs(df, threshold = 100, comparison = "=="), "comparison")
  expect_error(tally_runs(df, threshold = 100, comparison = "!="), "comparison")
})

test_that("error when period is invalid", {
  df <- data.frame(Date = as.Date("2023-01-01"), Flow = 50)
  # not a recognized string
  expect_error(tally_runs(df, threshold = 100, period = "fiscal_year"), "period")
  # wrong-length vector
  expect_error(tally_runs(df, threshold = 100, period = c("0601")), "period")
  # three-element vector
  expect_error(
    tally_runs(df, threshold = 100, period = c("0601", "0930", "1231")),
    "period"
  )
})

test_that("error when duration_units is not NULL or a recognized unit", {
  df <- data.frame(Date = as.Date("2023-01-01") + 0:2, Flow = c(50, 50, 50))
  expect_error(
    tally_runs(df, threshold = 40, duration_units = "bananas"),
    "duration_units"
  )
})

# ============================================================
# Happy-path / core behaviour
# ============================================================

test_that("contract example: two runs in June daily data", {
  result <- tally_runs(fixture_june, threshold = 100)

  expect_equal(nrow(result), 2L)
  expect_equal(result$period, c(2022, 2022))
  expect_equal(result$run_number, c(1L, 2L))
  expect_equal(result$start, as.Date(c("2022-06-01", "2022-06-16")))
  expect_equal(result$end, as.Date(c("2022-06-10", "2022-06-30")))
  expect_equal(result$length, c(10L, 15L))
})

test_that("single continuous run when all records meet condition", {
  df <- data.frame(
    Date = as.Date("2023-01-01") + 0:4,
    Flow = c(50, 60, 70, 80, 90)
  )
  result <- tally_runs(df, threshold = 40)

  expect_equal(nrow(result), 1L)
  expect_equal(result$run_number, 1L)
  expect_equal(result$length, 5L)
  expect_equal(result$start, as.Date("2023-01-01"))
  expect_equal(result$end, as.Date("2023-01-05"))
})

test_that("zero-run period when no records meet condition", {
  df <- data.frame(
    Date = as.Date("2023-01-01") + 0:4,
    Flow = c(10, 20, 30, 20, 10)
  )
  result <- tally_runs(df, threshold = 100)

  expect_equal(nrow(result), 1L)
  expect_equal(result$run_number, 0L)
  expect_true(is.na(result$start))
  expect_true(is.na(result$end))
  expect_true(is.na(result$length))
  expect_true(is.na(result$duration))
})

# ============================================================
# Comparison operators
# ============================================================

test_that("comparison '>=' includes values equal to threshold", {
  # Flow: 10, 20, 30, 20, 10; threshold=20
  # >= 20: indices 2,3,4 → 1 run, length=3
  df <- data.frame(
    Date = as.Date("2023-01-01") + 0:4,
    Flow = c(10, 20, 30, 20, 10)
  )
  result <- tally_runs(df, threshold = 20, comparison = ">=")

  expect_equal(result$length[result$run_number > 0], 3L)
  expect_equal(result$start[result$run_number > 0], as.Date("2023-01-02"))
  expect_equal(result$end[result$run_number > 0], as.Date("2023-01-04"))
})

test_that("comparison '>' excludes values equal to threshold", {
  # Flow: 10, 20, 30, 20, 10; threshold=20
  # > 20: index 3 only → 1 run, length=1
  df <- data.frame(
    Date = as.Date("2023-01-01") + 0:4,
    Flow = c(10, 20, 30, 20, 10)
  )
  result <- tally_runs(df, threshold = 20, comparison = ">")

  runs <- result[result$run_number > 0, ]
  expect_equal(nrow(runs), 1L)
  expect_equal(runs$length, 1L)
  expect_equal(runs$start, as.Date("2023-01-03"))
  expect_equal(runs$end, as.Date("2023-01-03"))
})

test_that("comparison '<=' includes values equal to threshold", {
  # Flow: 10, 20, 30, 20, 10; threshold=20
  # <= 20: indices 1,2 and 4,5 → 2 runs, lengths 2 and 2
  df <- data.frame(
    Date = as.Date("2023-01-01") + 0:4,
    Flow = c(10, 20, 30, 20, 10)
  )
  result <- tally_runs(df, threshold = 20, comparison = "<=")

  runs <- result[result$run_number > 0, ]
  expect_equal(nrow(runs), 2L)
  expect_equal(runs$length, c(2L, 2L))
})

test_that("comparison '<' excludes values equal to threshold", {
  # Flow: 10, 20, 30, 20, 10; threshold=20
  # < 20: indices 1 and 5 → 2 runs, lengths 1 and 1
  df <- data.frame(
    Date = as.Date("2023-01-01") + 0:4,
    Flow = c(10, 20, 30, 20, 10)
  )
  result <- tally_runs(df, threshold = 20, comparison = "<")

  runs <- result[result$run_number > 0, ]
  expect_equal(nrow(runs), 2L)
  expect_equal(runs$length, c(1L, 1L))
  expect_equal(runs$start, as.Date(c("2023-01-01", "2023-01-05")))
})

# ============================================================
# Period partitioning
# ============================================================

test_that("water_year labels by ending year (WY 2023 = Oct 2022 - Sep 2023)", {
  # Data in Jan 2023 → WY 2023
  df <- data.frame(
    Date = as.Date("2023-01-01") + 0:2,
    Flow = c(50, 50, 50)
  )
  result <- tally_runs(df, threshold = 40)
  expect_equal(result$period, 2023)
})

test_that("water_year: Oct date is in the NEXT water year", {
  # Oct 2022 → WY 2023 (not WY 2022)
  df <- data.frame(
    Date = as.Date("2022-10-15") + 0:2,
    Flow = c(50, 50, 50)
  )
  result <- tally_runs(df, threshold = 40)
  expect_equal(result$period, 2023)
})

test_that("runs cannot span water year boundary", {
  # Continuous exceedance crossing Sep 30 → Oct 1
  # 2022-09-29, 09-30 in WY 2022; 2022-10-01, 10-02 in WY 2023
  df <- data.frame(
    Date = as.Date("2022-09-29") + 0:3,
    Flow = c(50, 50, 50, 50)
  )
  result <- tally_runs(df, threshold = 40)

  runs <- result[result$run_number > 0, ]
  expect_equal(nrow(runs), 2L)
  expect_equal(runs$period, c(2022, 2023))
  expect_equal(runs$length, c(2L, 2L))
  expect_equal(runs$end[1], as.Date("2022-09-30"))
  expect_equal(runs$start[2], as.Date("2022-10-01"))
})

test_that("annual period labels by calendar year", {
  df <- data.frame(
    Date = as.Date("2023-06-01") + 0:2,
    Flow = c(50, 50, 50)
  )
  result <- tally_runs(df, threshold = 40, period = "annual")
  expect_equal(result$period, 2023)
})

test_that("runs cannot span calendar year boundary with annual period", {
  # 2022-12-30, 12-31 in year 2022; 2023-01-01, 01-02 in year 2023
  df <- data.frame(
    Date = as.Date("2022-12-30") + 0:3,
    Flow = c(50, 50, 50, 50)
  )
  result <- tally_runs(df, threshold = 40, period = "annual")

  runs <- result[result$run_number > 0, ]
  expect_equal(nrow(runs), 2L)
  expect_equal(runs$period, c(2022, 2023))
  expect_equal(runs$length, c(2L, 2L))
})

test_that("custom season with MMDD format includes only in-season records", {
  # Period Jun 1 - Sep 30. Data from May 30 to Jun 4 (6 records).
  # May 30, May 31 are outside → excluded. Jun 1-4 are inside.
  df <- data.frame(
    Date = as.Date("2023-05-30") + 0:5,
    Flow = rep(50, 6)
  )
  result <- tally_runs(df, threshold = 40, period = c("0601", "0930"))

  runs <- result[result$run_number > 0, ]
  # Only Jun 1-4 are in season → 1 run, length=4

  expect_equal(runs$length, 4L)
  expect_equal(runs$start, as.Date("2023-06-01"))
  expect_equal(runs$end, as.Date("2023-06-04"))
})

test_that("custom season labels by ending year", {
  df <- data.frame(
    Date = as.Date("2023-06-01") + 0:2,
    Flow = c(50, 50, 50)
  )
  result <- tally_runs(df, threshold = 40, period = c("0601", "0930"))
  expect_equal(result$period, 2023)
})

test_that("wrap-around custom season works (Oct 1 - Mar 31)", {
  # Data in Nov 2022 → in the Oct 2022 - Mar 2023 season, ending year = 2023
  df <- data.frame(
    Date = as.Date("2022-11-01") + 0:2,
    Flow = c(50, 50, 50)
  )
  result <- tally_runs(df, threshold = 40, period = c("1001", "0331"))

  runs <- result[result$run_number > 0, ]
  expect_equal(runs$period, 2023)
  expect_equal(runs$length, 3L)
})

# ============================================================
# NA behaviour
# ============================================================

test_that("NA in value column breaks a run into two separate runs", {
  # Flow: 50, 50, NA, 50, 50, 50; threshold=40, >=
  # Run 1: indices 1-2 (length=2), Run 2: indices 4-6 (length=3)
  df <- data.frame(
    Date = as.Date("2023-01-01") + 0:5,
    Flow = c(50, 50, NA, 50, 50, 50)
  )
  result <- tally_runs(df, threshold = 40)

  runs <- result[result$run_number > 0, ]
  expect_equal(nrow(runs), 2L)
  expect_equal(runs$length, c(2L, 3L))
  expect_equal(runs$start, as.Date(c("2023-01-01", "2023-01-04")))
  expect_equal(runs$end, as.Date(c("2023-01-02", "2023-01-06")))
})

test_that("NAs in value column do not cause an error", {
  df <- data.frame(
    Date = as.Date("2023-01-01") + 0:2,
    Flow = c(NA, NA, NA)
  )
  expect_no_error(tally_runs(df, threshold = 40))
})

# ============================================================
# Return structure
# ============================================================

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

test_that("start and end preserve POSIXct class from input", {
  df <- data.frame(
    datetime = as.POSIXct(
      c("2023-01-01 00:00:00", "2023-01-01 01:00:00", "2023-01-01 02:00:00"),
      tz = "UTC"
    ),
    value = c(50, 50, 50)
  )
  result <- tally_runs(df, datetime_col = "datetime", value_col = "value",
                       threshold = 40)

  expect_s3_class(result$start, "POSIXct")
  expect_s3_class(result$end, "POSIXct")
})

test_that("run_number is sequential within a period", {
  result <- tally_runs(fixture_june, threshold = 100)
  expect_equal(result$run_number, c(1L, 2L))
})

test_that("zero-run period row has run_number=0 and NAs for start, end, length, duration", {
  df <- data.frame(
    Date = as.Date("2023-01-01") + 0:2,
    Flow = c(10, 10, 10)
  )
  result <- tally_runs(df, threshold = 100)

  expect_equal(nrow(result), 1L)
  expect_equal(result$run_number, 0L)
  expect_true(is.na(result$start))
  expect_true(is.na(result$end))
  expect_true(is.na(result$length))
  expect_true(is.na(result$duration))
})

# ============================================================
# Every period in input appears in output
# ============================================================

test_that("every period in the input appears in the output", {
  # Data spans WY 2023 (Jan 2023) and WY 2024 (Nov 2023).
  # WY 2023 records meet condition; WY 2024 records do not.
  df <- data.frame(
    Date = c(as.Date("2023-01-01") + 0:2, as.Date("2023-11-01") + 0:2),
    Flow = c(50, 50, 50, 10, 10, 10)
  )
  result <- tally_runs(df, threshold = 40)

  expect_true(2023 %in% result$period)
  expect_true(2024 %in% result$period)

  # WY 2024 should be a zero-run row
  wy2024 <- result[result$period == 2024, ]
  expect_equal(wy2024$run_number, 0L)
})

# ============================================================
# Duration
# ============================================================

test_that("duration is elapsed time from start to end", {
  # Run from 2022-06-01 to 2022-06-10 = 9 days elapsed
  result <- tally_runs(fixture_june, threshold = 100)

  runs <- result[result$run_number > 0, ]
  # Run 1: 10 records, 2022-06-01 to 2022-06-10 → 9 days
  # Run 2: 15 records, 2022-06-16 to 2022-06-30 → 14 days
  expect_equal(as.numeric(runs$duration[1], units = "days"), 9)
  expect_equal(as.numeric(runs$duration[2], units = "days"), 14)
})

test_that("duration is zero for a single-record run", {
  df <- data.frame(
    Date = as.Date("2023-01-01") + 0:2,
    Flow = c(10, 50, 10)
  )
  result <- tally_runs(df, threshold = 40)

  runs <- result[result$run_number > 0, ]
  expect_equal(runs$length, 1L)
  expect_equal(as.numeric(runs$duration, units = "days"), 0)
})

test_that("duration_units converts to specified units", {
  # Run 1 in fixture: 9 days = 216 hours
  result <- tally_runs(fixture_june, threshold = 100, duration_units = "hours")

  runs <- result[result$run_number > 0, ]
  expect_equal(as.numeric(runs$duration[1]), 216)
})

# ============================================================
# Default parameters
# ============================================================

test_that("datetime_col defaults to 'Date'", {
  df <- data.frame(
    Date = as.Date("2023-01-01") + 0:2,
    Flow = c(50, 50, 50)
  )
  # Should work without specifying datetime_col
  expect_no_error(tally_runs(df, threshold = 40))
})

test_that("value_col defaults to 'Flow'", {
  df <- data.frame(
    Date = as.Date("2023-01-01") + 0:2,
    Flow = c(50, 50, 50)
  )
  # Should work without specifying value_col
  expect_no_error(tally_runs(df, threshold = 40))
})

test_that("non-default column names work", {
  df <- data.frame(
    timestamp = as.Date("2023-01-01") + 0:2,
    discharge = c(50, 50, 50)
  )
  result <- tally_runs(df, datetime_col = "timestamp", value_col = "discharge",
                       threshold = 40)

  expect_equal(nrow(result), 1L)
  expect_equal(result$run_number, 1L)
  expect_equal(result$length, 3L)
})

# ============================================================
# Edge cases
# ============================================================

test_that("single-row input with value meeting condition produces a run", {
  df <- data.frame(Date = as.Date("2023-01-01"), Flow = 50)
  result <- tally_runs(df, threshold = 40)

  expect_equal(nrow(result), 1L)
  expect_equal(result$run_number, 1L)
  expect_equal(result$length, 1L)
  expect_equal(result$start, as.Date("2023-01-01"))
  expect_equal(result$end, as.Date("2023-01-01"))
})

test_that("single-row input with value not meeting condition produces zero-run row", {
  df <- data.frame(Date = as.Date("2023-01-01"), Flow = 10)
  result <- tally_runs(df, threshold = 40)

  expect_equal(nrow(result), 1L)
  expect_equal(result$run_number, 0L)
})

test_that("multiple periods with mixed results (some with runs, some without)", {
  # WY 2023 (Jan 2023): has a run. WY 2024 (Jan 2024): no runs.
  df <- data.frame(
    Date = c(as.Date("2023-01-01") + 0:2, as.Date("2024-01-01") + 0:2),
    Flow = c(50, 50, 50, 10, 10, 10)
  )
  result <- tally_runs(df, threshold = 40)

  wy2023 <- result[result$period == 2023, ]
  wy2024 <- result[result$period == 2024, ]

  expect_true(nrow(wy2023) >= 1L)
  expect_equal(wy2023$run_number[1], 1L)
  expect_equal(wy2024$run_number, 0L)
})
