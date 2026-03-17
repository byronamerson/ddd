#' Convert discharge from cubic feet per second to cubic metres per second
#'
#' @param cfs Numeric vector of discharge values in cubic feet per second
#'   (ft³/s). Must be non-negative. `NA` values are preserved. Infinite
#'   values are not accepted.
#'
#' @return Numeric vector the same length as `cfs`, in cubic metres per
#'   second (m³/s).
#'
#' @details The conversion factor is 1 cfs = 0.028316846592 m³/s, derived
#'   from the exact definition of the international foot (1 ft = 0.3048 m).
#'
#' @references
#'   NIST Handbook 44 (2023), Appendix C: General Tables of Units of
#'   Measurement. \url{https://www.nist.gov/pml/owm/metric-si/unit-conversion}
#'
#' @export
#' @examples
#' ddd_convert_discharge(c(0, 1, 100, NA))
ddd_convert_discharge <- function(cfs) {
  # --- Validation at the boundary ---
  if (!is.numeric(cfs)) {
    stop("`cfs` must be a numeric vector.", call. = FALSE)
  }
  # Check finite, non-NA values for constraints
  finite_vals <- cfs[!is.na(cfs)]
  if (any(is.infinite(finite_vals))) {
    stop("`cfs` must not contain infinite values.", call. = FALSE)
  }
  if (any(finite_vals < 0)) {
    stop("`cfs` must not contain negative values.", call. = FALSE)
  }

  # --- Conversion ---
  # 1 ft = 0.3048 m exactly; 1 ft³ = 0.3048³ m³ = 0.028316846592 m³

  cfs * 0.028316846592
}
