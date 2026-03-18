Gear 2 — collaborative design mode. Read `design/CONTEXT.md` and `docs/three-gear-workflow.md` before responding. You are a design collaborator — ask questions, propose structure, surface edge cases, record decisions.

## What we're designing

A function (or family of functions) that detects and summarises sequential runs above or below a threshold in a daily hydrograph. The working exploration script is at `exploration/scripts/run-length-explore.R` — read it to understand the current approach, but treat it as a reference, not a template.

## What we learned in exploration

- **Data source:** USGS daily values via `dataRetrieval::readNWISdv()`. After `renameNWISColumns()`, the discharge column is `Flow` (cfs) and the date column is `Date` (class Date).
- **Core engine:** `rle()` on a logical exceedance vector (e.g., `Flow >= threshold`) gives run lengths and values. Grouping by period (water year or calendar year) before `rle()` prevents runs from spanning period boundaries.
- **Season filtering:** Encode month-day as integer (MMDD), handle wrap-around seasons (e.g. Oct–Mar) with OR logic vs. non-wrapping (Jun–Nov) with AND logic.
- **Period assignment:** `dataRetrieval::calcWaterYear()` takes a Date vector and returns numeric water year (Oct 1 start, USGS convention). This is the right tool — no need to roll our own.
- **NA behaviour:** `rle()` treats NA as unequal to everything, so an NA in the middle of a run splits it into two. The exploration script flags this but doesn't resolve it — a design decision is needed.
- **Two output levels:** (1) per-period summary (n_runs, mean_length, max_length, total_days), and (2) individual run detail (start_date, end_date, length, exceedance flag, period).
- **Two test gages:** Meacham Creek OR (14020300, snowmelt) and Elder Creek CA (11475560, rain-driven). Different hydrologic regimes useful for checking generality.

## Design questions to work through

These surfaced during exploration. Some may have obvious answers; others need discussion.

1. **Function boundary:** One function that returns both summary and detail? Separate functions? A core function that returns detail, with a summary wrapper?
2. **Input contract:** What does the function take? A full dataframe with `Date` and `Flow` columns? Or just a Date vector and a numeric vector? What about the threshold, comparison operator, season window, and period type — all arguments?
3. **NA handling policy:** Fill short gaps before run detection? Drop NAs? Treat them as run-breakers (current default)? Should this be user-configurable?
4. **Season filtering:** Should it live inside the run-length function, or be a separate preprocessing step the user applies before calling?
5. **Generality:** This was built on discharge data, but run-length analysis applies to any time series with a threshold (temperature, stage, turbidity). How generic should the interface be?
6. **Return structure:** Tibble? Named list of tibbles? What columns?
7. **The comparison operator:** Currently passed as a string (`">="`) and resolved with `match.fun()`. Is there a cleaner interface?
8. **What `rle()` doesn't give you:** Start and end dates require manual index arithmetic (see `build_runs_df()` in the exploration script). Worth wrapping cleanly.
