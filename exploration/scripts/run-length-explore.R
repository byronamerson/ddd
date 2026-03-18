# run-length-explore.R
# Exploration: sequential runs above/below threshold in a hydrograph
#
# Question: given a time series (e.g., a hydrograph), how long are
# the runs where flow exceeds or falls below a threshold? How many
# such runs occur per water year or per season?

library(tidyverse)
library(lubridate)
library(dataRetrieval)

# === Data pull ============================================================
# Meacham Creek, OR (USGS 14020300) — snowmelt, Blue Mountains
# Elder Creek, CA (USGS 11475560) — rain-driven, Mendocino coast range
#
# readNWISdv() returns: agency_cd, site_no, Date, X_00060_00003, etc.
# renameNWISColumns() renames X_00060_00003 -> Flow (for param 00060)
# Date column stays as "Date" (class Date) throughout.

meacham <- readNWISdv(
  siteNumbers = "14020300",
  parameterCd = "00060",
  startDate = "2000-10-01",
  endDate = "2023-09-30"
) %>%
  renameNWISColumns()

elder <- readNWISdv(
  siteNumbers = "11475560",
  parameterCd = "00060",
  startDate = "2000-10-01",
  endDate = "2023-09-30"
) %>%
  renameNWISColumns()

# --- First look ---
glimpse(meacham)
glimpse(elder)
names(meacham)   # confirm column names

ggplot(meacham, aes(Date, Flow)) +
  geom_line(linewidth = 0.3) +
  labs(title = "Meacham Creek, OR (14020300)", y = "Discharge (cfs)")

ggplot(elder, aes(Date, Flow)) +
  geom_line(linewidth = 0.3) +
  labs(title = "Elder Creek, CA (11475560)", y = "Discharge (cfs)")

# NAs? rle() treats NA as unequal to everything — an NA in the middle
# of a run breaks it into two runs. Need to know if this matters here.
sum(is.na(meacham$Flow))
sum(is.na(elder$Flow))

# === Settings =============================================================
# These are the knobs for the analysis.

threshold <- median(meacham$Flow, na.rm = TRUE)
comparison <- ">="          # one of ">", "<", ">=", "<="
season_start <- "0601"      # MMDD — June 1
season_end <- "1130"        # MMDD — Nov 30
period_type <- "water_year" # "water_year" or "annual"

# === Preprocessing: season filter + period assignment =====================
# This happens BEFORE run detection. The sequence:
#   1. Encode month-day as integer for season filtering
#   2. Filter to the season window
#   3. Assign period (water year or calendar year) using calcWaterYear()
#   4. Apply the threshold comparison
#
# calcWaterYear() from dataRetrieval takes a Date vector and returns
# numeric water year per USGS definition (Oct 1 start). No column
# name ambiguity — it works on any Date/POSIXct vector.

# Step 1: month-day encoding
s_md <- as.integer(substr(season_start, 1, 2)) * 100L +
        as.integer(substr(season_start, 3, 4))
e_md <- as.integer(substr(season_end, 1, 2)) * 100L +
        as.integer(substr(season_end, 3, 4))

meacham_work <- meacham %>%
  mutate(md = month(Date) * 100L + day(Date))

# Step 2: filter to season window
# If season doesn't cross calendar year boundary (e.g. Jun–Nov): AND
# If it does (e.g. Oct–Sep for water year): OR
if (s_md <= e_md) {
  meacham_season <- meacham_work %>% filter(md >= s_md, md <= e_md)
} else {
  meacham_season <- meacham_work %>% filter(md >= s_md | md <= e_md)
}

# Step 3: assign period
# period_type is a scalar config setting, not a row-level condition —
# use base if/else (evaluates once), not dplyr::if_else (vectorised).
meacham_season <- meacham_season %>%
  mutate(
    period = if (period_type == "water_year") {
      calcWaterYear(Date)
    } else {
      as.numeric(year(Date))
    }
  )

# Step 4: apply threshold comparison
compare_fn <- match.fun(comparison)

meacham_season <- meacham_season %>%
  mutate(exceedance = compare_fn(Flow, threshold))

# === Run detection (within each period) ===================================
# group_by(period) + rle() ensures runs cannot span period boundaries.
#
# NA safety: rle()$values can contain NAs (from NA Flow values).
# Subsetting with .x$values == TRUE would produce NAs in the index,
# pulling phantom entries. which() drops NAs from the index.

runs_summary <- meacham_season %>%
  group_by(period) %>%
  summarise(
    runs_raw = list(rle(exceedance)),
    .groups = "drop"
  ) %>%
  mutate(
    n_runs = map_int(runs_raw, ~ length(which(.x$values == TRUE))),
    mean_length = map_dbl(runs_raw, ~ {
      lens <- .x$lengths[which(.x$values == TRUE)]
      if (length(lens) == 0) NA_real_ else mean(lens)
    }),
    max_length = map_dbl(runs_raw, ~ {
      lens <- .x$lengths[which(.x$values == TRUE)]
      if (length(lens) == 0) NA_real_ else max(lens)
    }),
    total_days = map_int(runs_raw, ~ {
      sum(.x$lengths[which(.x$values == TRUE)])
    })
  ) %>%
  select(-runs_raw)

runs_summary

# Sniff test:
# - Does total_days + days below ≈ season length per period?
# - Are there periods with zero runs? Expected?
# - Do the numbers match what the hydrograph looks like?

# === Individual runs with dates ===========================================
# For when you need to see each run: when it started, ended, how long.

build_runs_df <- function(df) {
  runs <- rle(df$exceedance)
  run_ends <- cumsum(runs$lengths)
  run_starts <- c(1L, head(run_ends, -1L) + 1L)
  # period column is added back by group_modify() from the grouping key —
  # no need to extract it here (df doesn't contain grouping columns).
  tibble(
    exceedance = runs$values,
    length     = runs$lengths,
    start_date = df$Date[run_starts],
    end_date   = df$Date[run_ends]
  )
}

runs_detail <- meacham_season %>%
  group_by(period) %>%
  group_modify(~ build_runs_df(.x)) %>%
  ungroup()

# Exceedance runs only
runs_detail %>% filter(exceedance)

# === Next questions =======================================================
# - Try on Elder Creek — does the pattern differ by regime?
# - Try different thresholds (bankfull, 75th percentile, low-flow)
# - Try different seasons (full water year, wet season only)
# - NA handling: rle() breaks runs at NAs. Should we fill short NA gaps
#   before run detection, or treat them as true breaks?
# - What should the function signature look like when this graduates
#   to the design phase?
