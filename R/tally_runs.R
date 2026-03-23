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
