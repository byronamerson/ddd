# Run-Length Analysis — Exploration Notes

## The question
Given an arbitrary time series (e.g., a hydrograph), find:
- Sequential runs where data exceeds or falls below a threshold
- The length of each run
- The count of runs per period (water year, season, arbitrary dates)

## Test data
- **Meacham Creek, OR** (USGS 14020300) — snowmelt-influenced system
  in the Blue Mountains. Spring freshet dominance, winter rain-on-snow
  events.
- **Elder Creek, CA** (USGS 11475560) — rain-driven coast range
  stream in Mendocino County. Mediterranean climate, strong wet/dry
  seasonality. Part of the Angelo Coast Range Reserve / South Fork
  Eel watershed.

These two creeks have very different hydrologic regimes, which makes
them a good pair for testing whether run-length behaviour is
sensitive to flow regime type.

## Where this came from
Common need in hydrology and ecology — duration and frequency of
exceedance events (floods, low flows, temperature thresholds).
Relevant to habitat assessment (e.g., days of bankfull flow,
duration of low-flow stress), regulatory compliance, and
geomorphic process analysis.

## Open questions (to explore)
- How to handle NAs in the time series?
- How to define "period" flexibly (water year, calendar year, season,
  arbitrary start/stop)?
- Should the function return individual runs or just summaries?
- What about the boundary — does a run that spans two periods get
  counted in both? Split? Assigned to the period where it started?
- Strictly greater vs. >= ?
- What about ties at the threshold?
- How does run-length behaviour differ between Meacham (snowmelt)
  and Elder (rain-driven)? Does the function need to handle both
  regimes gracefully?
