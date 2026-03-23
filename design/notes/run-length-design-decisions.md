# Run-Length Analysis — Design Decisions

*Decisions from the Gear 2 design conversation. These form the
specification for the Gear 3 contract (Roxygen block and tests).*

Last updated: 2026-03-18

---

## Purpose

Detect sequential runs in a time series where a value meets a
threshold condition, and report the timing, count, and duration
of those runs within recurring time spans.

The domain operation: given a record of some measured quantity
over time, identify the periods where the quantity stayed
continuously above (or below) a threshold, and tally them by
year or season.

---

## Decisions

### 1. Input structure

A tibble (or data frame) with at least a datetime column and a
numeric value column. The function assumes the input represents
a single site. Multi-site data is handled by the caller using
purrr tools (`group_by() |> group_modify()`, `nest() |> mutate(map(...))`,
etc.).

### 2. Generic, not discharge-specific

The function works on any numeric time series with a threshold —
discharge, temperature, stage, turbidity, or anything else. The
interface does not assume hydrologic variables.

### 3. Column arguments

```
datetime_col = "Date"
value_col = "Flow"
```

Defaults match `dataRetrieval::renameNWISColumns()` output. The
user overrides for other data sources. No renaming required before
calling.

### 4. Comparison operator

Passed as a string. Default: `">="`. Valid values: `">"`, `"<"`,
`">="`, `"<="`. Anything else errors at validation.

### 5. Period as recurring span

All period options are the same operation: partition the time
series into recurring sub-annual or annual spans, and detect runs
within each span. Records outside the span are excluded.

Three interfaces:

- `period = "water_year"` — shortcut for Oct 1 to Sep 30
- `period = "annual"` — shortcut for Jan 1 to Dec 31
- `period = c("MMDD", "MMDD")` or `c("MMDD HHMM", "MMDD HHMM")`
  — custom span with optional sub-daily precision

Wrap-around spans (e.g., Oct 1 to Mar 31) are handled. The
format accommodates any time step — daily data uses MMDD, sub-daily
data can use MMDD HHMM.

Use lubridate for all datetime resolution internally.

### 6. Period labeling

Every span is labeled by the **ending year**, consistent with
the USGS water year convention (WY 2023 = Oct 2022–Sep 2023).
This applies to all spans, not just water years.

### 7. NA handling

NAs in the value column break runs. No gap-filling inside the
function. The function does not require NA-free input, but NAs
will interrupt what might otherwise be a single continuous run.
This behaviour is documented in the contract so users can make
informed preprocessing decisions.

### 8. Time zone

The function respects whatever time zone the input datetime
column carries. It does not convert or assume a time zone. This
is a documented assumption, not a parameter. The user is
responsible for their data's time zone before calling.

### 9. Return structure

A single tibble, one row per run. Periods with no runs get one
row with `run_number = 0` and NA in the detail columns. This
makes the output a complete ledger — every period in the input
appears in the output.

Columns:

| Column | Type | Description |
|--------|------|-------------|
| `period` | numeric | Ending year of the span |
| `run_number` | integer | 1..n for runs, 0 for periods with no runs |
| `start` | datetime | First record in the run (NA when run_number = 0) |
| `end` | datetime | Last record in the run (NA when run_number = 0) |
| `length` | integer | Number of records in the run (NA when run_number = 0) |
| `duration` | difftime | Elapsed time, start to end (NA when run_number = 0) |

Duration defaults to the natural unit of the data's time step.
The user can request a specific unit via a `duration_units`
argument (e.g., `"hours"`, `"days"`).

### 10. Specification, not algorithm

The contract describes the domain operation — detect sequential
runs meeting a condition, report their timing and duration. The
implementation approach (rle, cumsum, loop, or anything else) is
not prescribed by the specification.

### 11. One function

A single public function handles both detection and output. The
tally structure (one row per run, zero-run periods included) makes
summary statistics trivial via standard dplyr operations on the
output — no second function needed.

---

## What's next

This specification is ready for Gear 3:

1. Write the Roxygen block from these decisions.
2. Derive tests from the contract.
3. Implement.

The exploration script (`exploration/scripts/run-length-explore.R`)
is a reference for domain logic, not a template for implementation.
