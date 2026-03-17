# Tests derived from the Roxygen contract in R/convert.R
# Each test traces to a specific clause in the contract.

test_that("ddd_convert_discharge() applies correct conversion factor", {
  # Contract: 1 cfs = 0.028316846592 m³/s
  expect_equal(ddd_convert_discharge(1), 0.028316846592)
  expect_equal(ddd_convert_discharge(100), 100 * 0.028316846592)
})

test_that("ddd_convert_discharge() returns same length as input", {
  # Contract: "Numeric vector the same length as cfs"
  input <- c(1, 10, 100)
  expect_length(ddd_convert_discharge(input), 3L)
})

test_that("ddd_convert_discharge() preserves NA values", {
  # Contract: "NA values are preserved"
  result <- ddd_convert_discharge(c(1, NA, 10))
  expect_true(is.na(result[2]))
  expect_false(is.na(result[1]))
  expect_false(is.na(result[3]))
})

test_that("ddd_convert_discharge() accepts zero", {
  # Contract: "Must be non-negative" — zero is non-negative
  expect_equal(ddd_convert_discharge(0), 0)
})

test_that("ddd_convert_discharge() returns empty numeric for empty input", {
  result <- ddd_convert_discharge(numeric(0))
  expect_length(result, 0L)
  expect_type(result, "double")
})

test_that("ddd_convert_discharge() rejects negative values", {
  # Contract: "Must be non-negative"
  expect_error(ddd_convert_discharge(-1))
  expect_error(ddd_convert_discharge(c(1, -0.5, 10)))
})

test_that("ddd_convert_discharge() rejects infinite values", {
  # Contract: "Infinite values are not accepted"
  expect_error(ddd_convert_discharge(Inf))
  expect_error(ddd_convert_discharge(c(1, Inf)))
  expect_error(ddd_convert_discharge(-Inf))
})

test_that("ddd_convert_discharge() rejects non-numeric input", {
  # Contract: "Numeric vector"
  expect_error(ddd_convert_discharge("10"))
  expect_error(ddd_convert_discharge(TRUE))
})
