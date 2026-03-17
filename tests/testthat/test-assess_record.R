# Tests derived from the Roxygen contract in R/assess_record.R
# Each test traces to a specific clause in the contract.

library(zoo)

# --- Helpers for constructing test zoo objects ---

# Regular hourly series (3600 s interval) with numeric index in seconds
make_regular_zoo <- function(n_hours, start_s = 0) {
  times <- seq(start_s, by = 3600, length.out = n_hours)
  zoo(seq_len(n_hours), order.by = times)
}

# Insert a gap by removing observations from a regular series
make_gapped_zoo <- function(n_hours, gap_start_hour, gap_end_hour) {
  times <- seq(0, by = 3600, length.out = n_hours)
  keep <- !(times >= gap_start_hour * 3600 & times < gap_end_hour * 3600)
  zoo(seq_len(sum(keep)), order.by = times[keep])
}

DIEL   <- 86400        # 24 hours in seconds
ANNUAL <- 31557600     # 365.25 days in seconds


# ---- Return structure --------------------------------------------------------

test_that("assess_record() returns a list with class 'record_assessment'", {
  # Contract: @return "A list with class 'record_assessment'"
  x <- make_regular_zoo(72)
  result <- assess_record(x, period = DIEL)
  expect_s3_class(result, "record_assessment")
  expect_type(result, "list")
})

test_that("assess_record() result contains required top-level elements", {
  # Contract: segments, gaps, overall_verdict, params
  x <- make_regular_zoo(72)
  result <- assess_record(x, period = DIEL)
  expect_named(result, c("segments", "gaps", "overall_verdict", "params"),
               ignore.order = TRUE)
})

test_that("segments tibble has the documented columns", {
  # Contract: seg_id, start, end, duration_s, n_obs, cycles, verdict
  x <- make_regular_zoo(72)
  result <- assess_record(x, period = DIEL)
  expected_cols <- c("seg_id", "start", "end", "duration_s", "n_obs",
                     "cycles", "verdict")
  expect_true(all(expected_cols %in% names(result$segments)))
})

test_that("gaps tibble has the documented columns", {
  # Contract: gap_id, start, end, duration_s, frac_of_period, tolerable
  x <- make_gapped_zoo(72, gap_start_hour = 24, gap_end_hour = 36)
  result <- assess_record(x, period = DIEL)
  expected_cols <- c("gap_id", "start", "end", "duration_s",
                     "frac_of_period", "tolerable")
  expect_true(all(expected_cols %in% names(result$gaps)))
})

test_that("overall_verdict is one of the three allowed values", {
  # Contract: "one of 'sufficient', 'marginal', 'insufficient'"
  x <- make_regular_zoo(72)
  result <- assess_record(x, period = DIEL)
  expect_true(result$overall_verdict %in%
                c("sufficient", "marginal", "insufficient"))
})

test_that("params records the parameter values used", {
  # Contract: "List of the parameter values used"
  x <- make_regular_zoo(72)
  result <- assess_record(x, period = DIEL, max_gap_frac = 0.2,
                          min_cycles = 3, gap_threshold = 5)
  expect_equal(result$params$period, DIEL)
  expect_equal(result$params$max_gap_frac, 0.2)
  expect_equal(result$params$min_cycles, 3)
  expect_equal(result$params$gap_threshold, 5)
})


# ---- Segment classification --------------------------------------------------

test_that("continuous record >= min_cycles periods is 'sufficient'", {
  # Contract: "sufficient — segment spans >= min_cycles complete periods"
  # 72 hours = 3 diel cycles, default min_cycles = 2
  x <- make_regular_zoo(73)  # just over 3 full days

  result <- assess_record(x, period = DIEL)
  expect_equal(result$segments$verdict, "sufficient")
  expect_equal(result$overall_verdict, "sufficient")
})

test_that("record spanning >= 1.0 but < min_cycles periods is 'marginal'", {
  # Contract: "marginal — segment spans >= 1.0 but < min_cycles periods"
  # 30 hours = 1.25 diel cycles, < 2 (default min_cycles)
  x <- make_regular_zoo(31)
  result <- assess_record(x, period = DIEL)
  expect_equal(result$segments$verdict, "marginal")
  expect_equal(result$overall_verdict, "marginal")
})

test_that("record spanning < 1.0 periods is 'insufficient'", {
  # Contract: "insufficient — segment spans < 1.0 periods"
  # 12 hours = 0.5 diel cycles
  x <- make_regular_zoo(13)
  result <- assess_record(x, period = DIEL)
  expect_equal(result$segments$verdict, "insufficient")
  expect_equal(result$overall_verdict, "insufficient")
})


# ---- Gap detection -----------------------------------------------------------

test_that("gap is detected when interval exceeds gap_threshold * median", {

  # Contract: "A gap is any interval between consecutive observations
  # that exceeds gap_threshold times the median sampling interval."
  # Median interval = 3600 s; default gap_threshold = 3 => 10800 s.
  # Insert a 12-hour gap (43200 s >> 10800 s).
  x <- make_gapped_zoo(72, gap_start_hour = 24, gap_end_hour = 36)
  result <- assess_record(x, period = DIEL)
  expect_true(nrow(result$gaps) >= 1)
})

test_that("no gaps in a perfectly regular series", {
  # Median interval = 3600 s, all intervals = 3600 s, none > 3 * 3600.
  x <- make_regular_zoo(72)
  result <- assess_record(x, period = DIEL)
  expect_equal(nrow(result$gaps), 0)
})

test_that("gap splits the record into multiple segments", {
  # A single 12-hour gap should produce 2 segments.
  x <- make_gapped_zoo(72, gap_start_hour = 24, gap_end_hour = 36)
  result <- assess_record(x, period = DIEL)
  expect_equal(nrow(result$segments), 2)
})


# ---- Gap tolerability --------------------------------------------------------

test_that("gap shorter than max_gap_frac * period is tolerable", {
  # Contract: "A gap is tolerable if its duration < max_gap_frac * period."
  # Default max_gap_frac = 0.17, period = DIEL => threshold = 14688 s (~4.08 h).
  # A 3-hour gap (10800 s) should be tolerable.
  x <- make_gapped_zoo(72, gap_start_hour = 24, gap_end_hour = 27)
  result <- assess_record(x, period = DIEL)
  expect_true(nrow(result$gaps) >= 1)
  expect_true(all(result$gaps$tolerable))
})

test_that("gap longer than max_gap_frac * period is not tolerable", {
  # 12-hour gap (43200 s) >> 0.17 * 86400 (14688 s)
  x <- make_gapped_zoo(72, gap_start_hour = 24, gap_end_hour = 36)
  result <- assess_record(x, period = DIEL)
  expect_true(any(!result$gaps$tolerable))
})

test_that("frac_of_period is computed correctly", {
  # Gap removes hours 24–35; last obs before gap is hour 23, first after is

  # hour 36. Actual gap duration = (36 - 23) * 3600 = 46800 s.
  # frac_of_period = 46800 / 86400 = 0.5417
  x <- make_gapped_zoo(72, gap_start_hour = 24, gap_end_hour = 36)
  result <- assess_record(x, period = DIEL)
  expect_equal(result$gaps$frac_of_period, 46800 / DIEL, tolerance = 1e-6)
})


# ---- Overall verdict logic ---------------------------------------------------

test_that("overall verdict is 'sufficient' if any segment qualifies", {
  # Contract: "'sufficient' if any segment qualifies"
  # Build: 72 h continuous, 12 h gap, 12 h continuous.
  # First segment = 24 h = 1 diel (marginal with min_cycles=2),
  # but use min_cycles = 1 so first segment qualifies.
  x <- make_gapped_zoo(72, gap_start_hour = 24, gap_end_hour = 36)
  result <- assess_record(x, period = DIEL, min_cycles = 1.0)
  expect_equal(result$overall_verdict, "sufficient")
})

test_that("overall verdict is 'marginal' when best segment >= 1 but < min_cycles", {
  # Contract: "'marginal' if any segment >= 1.0 cycles but none meets min_cycles"
  # 30 hours total, no gaps -> 1.25 cycles. Default min_cycles = 2.
  x <- make_regular_zoo(31)
  result <- assess_record(x, period = DIEL)
  expect_equal(result$overall_verdict, "marginal")
})

test_that("overall verdict is 'insufficient' when no segment reaches 1 period", {
  # Contract: "'insufficient' otherwise"
  # 12 hours = 0.5 diel cycles.
  x <- make_regular_zoo(13)
  result <- assess_record(x, period = DIEL)
  expect_equal(result$overall_verdict, "insufficient")
})


# ---- Cycles computation ------------------------------------------------------

test_that("cycles column reflects duration / period", {
  # 72 hours of hourly data = 3.0 diel cycles
  x <- make_regular_zoo(73)  # 73 points => 72 h span
  result <- assess_record(x, period = DIEL)
  expect_equal(result$segments$cycles, 3.0, tolerance = 0.01)
})


# ---- POSIXct index support ---------------------------------------------------

test_that("assess_record() works with POSIXct index", {
  # Contract: "Index should be numeric (seconds) or POSIXct."
  start <- as.POSIXct("2020-01-01", tz = "UTC")
  times <- seq(start, by = 3600, length.out = 73)
  x <- zoo(seq_along(times), order.by = times)
  result <- assess_record(x, period = DIEL)
  expect_s3_class(result, "record_assessment")
  expect_equal(result$overall_verdict, "sufficient")
})


# ---- Input validation --------------------------------------------------------

test_that("assess_record() requires period to be supplied", {
  # Contract: "No default; user must specify."
  x <- make_regular_zoo(72)
  expect_error(assess_record(x))
})

test_that("assess_record() defaults are applied correctly", {
  # Contract: max_gap_frac = 0.17, min_cycles = 2.0, gap_threshold = 3
  x <- make_regular_zoo(72)
  result <- assess_record(x, period = DIEL)
  expect_equal(result$params$max_gap_frac, 0.17)
  expect_equal(result$params$min_cycles, 2.0)
  expect_equal(result$params$gap_threshold, 3)
})
