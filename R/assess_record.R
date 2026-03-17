# assess_record.R — Evaluate fitness of a temperature record for periodic fitting
#
# Diagnoses whether a zoo time series has sufficient length and continuity
# to support reliable amplitude/phase extraction at a target period. Based
# on Johnson et al. (2021) "Heed the data gap" empirical thresholds for
# annual OLS sine-wave fits, generalized to arbitrary target periods.


#' Assess whether a temperature record supports fitting at a target period
#'
#' Examines a zoo time series for gaps and total length relative to a target
#' period (diel, annual, or arbitrary). Returns a diagnostic object describing
#' contiguous segments, gap locations and durations, and a per-segment verdict
#' on whether the record is sufficient for fitting.
#'
#' @details
#' **Gap detection:** A gap is any interval between consecutive observations
#' that exceeds `gap_threshold` times the median sampling interval.
#'
#' **Segment classification:** Contiguous segments between gaps are classified:
#' \itemize{
#'   \item "sufficient" — segment spans >= `min_cycles` complete periods
#'   \item "marginal" — segment spans >= 1.0 but < `min_cycles` periods
#'   \item "insufficient" — segment spans < 1.0 periods
#' }
#'
#' **Overall verdict:** "sufficient" if any segment qualifies, "marginal"
#' if any segment >= 1.0 cycles but none meets `min_cycles`, "insufficient"
#' otherwise.
#'
#' **Gap tolerability:** A gap is tolerable if its duration is less than
#' `max_gap_frac * period`.
#'
#' @param x A zoo object (single-column). Index should be numeric (seconds)
#'   or POSIXct.
#' @param period Numeric: target period in seconds. Common values:
#'   86400 (diel), 31557600 (annual = 365.25 * 86400). No default; user
#'   must specify.
#' @param max_gap_frac Numeric: maximum tolerable gap as a fraction of
#'   `period`. Default 0.17.
#' @param min_cycles Numeric: minimum contiguous record length expressed as
#'   multiples of `period`. Default 2.0.
#' @param gap_threshold Numeric: multiplier on median sampling interval to
#'   detect gaps. Default 3.
#'
#' @return A list with class `"record_assessment"` containing:
#'   \describe{
#'     \item{segments}{A tibble with columns: `seg_id`, `start`, `end`,
#'       `duration_s`, `n_obs`, `cycles`, `verdict`.}
#'     \item{gaps}{A tibble with columns: `gap_id`, `start`, `end`,
#'       `duration_s`, `frac_of_period`, `tolerable`.}
#'     \item{overall_verdict}{Character: one of "sufficient", "marginal",
#'       "insufficient".}
#'     \item{params}{List of the parameter values used.}
#'   }
#'
#' @references
#' Johnson, Z. C. et al. (2021). Heed the data gap: Guidelines for using
#' incomplete datasets in annual stream temperature analyses. Ecological
#' Indicators, 122, 107229.
#'
#' @export
assess_record <- function(x,
                          period,
                          max_gap_frac = 0.17,
                          min_cycles = 2.0,
                          gap_threshold = 3) {
  # --- Validation at the boundary ---
  if (!zoo::is.zoo(x)) {
    stop("`x` must be a zoo object.", call. = FALSE)
  }

  # Extract index as numeric seconds
  idx <- zoo::index(x)
  if (inherits(idx, "POSIXct")) {
    idx <- as.numeric(idx)
  }
  if (!is.numeric(idx)) {
    stop("`x` index must be numeric (seconds) or POSIXct.", call. = FALSE)
  }

  n <- length(idx)
  intervals <- diff(idx)                    # time between consecutive obs (s)
  median_dt <- stats::median(intervals)     # median sampling interval (s)

  # --- Identify gap positions ---
  gap_cutoff <- gap_threshold * median_dt
  is_gap <- intervals > gap_cutoff

  # --- Build segment and gap tables ---
  # Break points: positions where a gap begins (1-based index into `idx`)
  gap_positions <- which(is_gap)

  # Segment boundaries: defined by start/end indices into idx
  seg_starts <- c(1L, gap_positions + 1L)
  seg_ends   <- c(gap_positions, n)

  segments <- tibble::tibble(
    seg_id     = seq_along(seg_starts),
    start      = idx[seg_starts],
    end        = idx[seg_ends],
    duration_s = idx[seg_ends] - idx[seg_starts],
    n_obs      = seg_ends - seg_starts + 1L,
    cycles     = (idx[seg_ends] - idx[seg_starts]) / period,
    verdict    = classify_segment(cycles, min_cycles)
  )

  if (length(gap_positions) > 0) {
    gap_starts <- idx[gap_positions]
    gap_ends   <- idx[gap_positions + 1L]
    gap_dur    <- gap_ends - gap_starts

    gaps <- tibble::tibble(
      gap_id          = seq_along(gap_positions),
      start           = gap_starts,
      end             = gap_ends,
      duration_s      = gap_dur,
      frac_of_period  = gap_dur / period,
      tolerable       = gap_dur < (max_gap_frac * period)
    )
  } else {
    gaps <- tibble::tibble(
      gap_id          = integer(0),
      start           = numeric(0),
      end             = numeric(0),
      duration_s      = numeric(0),
      frac_of_period  = numeric(0),
      tolerable       = logical(0)
    )
  }

  # --- Overall verdict ---
  max_cycles <- max(segments$cycles)
  if (max_cycles >= min_cycles) {
    overall <- "sufficient"
  } else if (max_cycles >= 1.0) {
    overall <- "marginal"
  } else {
    overall <- "insufficient"
  }

  structure(
    list(
      segments        = segments,
      gaps            = gaps,
      overall_verdict = overall,
      params          = list(
        period        = period,
        max_gap_frac  = max_gap_frac,
        min_cycles    = min_cycles,
        gap_threshold = gap_threshold
      )
    ),
    class = "record_assessment"
  )
}


# --- Internal helper ----------------------------------------------------------

#' Classify segment cycles into verdict
#' @param cycles Numeric vector of cycle counts.
#' @param min_cycles Numeric threshold for "sufficient".
#' @return Character vector of verdicts.
#' @noRd
classify_segment <- function(cycles, min_cycles) {
  ifelse(cycles >= min_cycles, "sufficient",
         ifelse(cycles >= 1.0, "marginal", "insufficient"))
}
