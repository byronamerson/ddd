# Inter-Rater Comparison Analysis

*Analysis of three independent test-derivation runs against the
`tally_runs()` Roxygen contract. 2026-03-22.*

---

## 0. Contamination check

All three runs are clean. Each agent read only the four required files
(SKILL.md, test-principles.md, report-format.md, R/tally_runs.R) plus
directory listings of their own output folder. Run 2 additionally noted
that CLAUDE.md was loaded automatically and that git status showed
filenames of restricted files (paths only, no content). No content
contamination occurred in any run.

**All three runs are valid for inter-rater comparison.**

---

## 1. Test count comparison

| Category | Run 1 | Run 2 | Run 3 | Bespoke |
|----------|-------|-------|-------|---------|
| Validation | 10 | 11 | 10 | 13 |
| Happy-path | 3 | 2 | 4 | 4 |
| Comparison operators | 4 | 4 | 4 | 4 |
| Period partitioning | 8 | 7 | 7 | 8 |
| NA behaviour | 2 | 2 | 2 | 2 |
| Return structure | 6 | 4 | 4 | 5 |
| Zero-run / every-period | 1 | 2 | — | — |
| Duration | 3 | 3 | 3 | 3 |
| Defaults / column names | 3 | 1 | — | 1 |
| Edge cases | 3 | 5 | 6 | 9 |
| **Total** | **43** | **41** | **40** | **49** |

Categories are not perfectly aligned across runs (each agent chose
slightly different groupings), but the totals cluster tightly:
40–43 for the skill runs vs. 49 for the bespoke prompt. The bespoke
prompt was more exhaustive — it had a more detailed, function-specific
set of instructions.

---

## 2. Convergence analysis — test intents

### Full convergence (3/3) — contract clearly implies these

| Intent | R1 | R2 | R3 |
|--------|----|----|-----|
| error: df not a data frame | ✓ | ✓ | ✓ |
| error: df has zero rows | ✓ | ✓ | ✓ |
| error: datetime_col not found | ✓ | ✓ | ✓ |
| error: value_col not found | ✓ | ✓ | ✓ |
| error: datetime col wrong class | ✓ | ✓ | ✓ |
| error: value col not numeric | ✓ | ✓ | ✓ |
| error: threshold not finite numeric | ✓ | ✓ | ✓ |
| error: comparison invalid | ✓ | ✓ | ✓ |
| error: period invalid | ✓ | ✓ | ✓ |
| error: duration_units invalid | ✓ | ✓ | ✓ |
| >= includes equal to threshold | ✓ | ✓ | ✓ |
| > excludes equal to threshold | ✓ | ✓ | ✓ |
| <= includes equal to threshold | ✓ | ✓ | ✓ |
| < excludes equal to threshold | ✓ | ✓ | ✓ |
| water_year labels by ending year | ✓ | ✓ | ✓ |
| annual labels by calendar year | ✓ | ✓ | ✓ |
| runs cannot span WY boundary | ✓ | ✓ | ✓ |
| custom season excludes out-of-span | ✓ | ✓ | ✓ |
| wrap-around custom season works | ✓ | ✓ | ✓ |
| NA breaks a run into two | ✓ | ✓ | ✓ |
| NAs don't cause an error | ✓ | ✓ | ✓ |
| output is a tibble | ✓ | ✓ | ✓ |
| output has correct column names | ✓ | ✓ | ✓ |
| output column types correct | ✓ | ✓ | ✓ |
| POSIXct class preserved | ✓ | ✓ | ✓ |
| zero-run row: run_number=0, NAs | ✓ | ✓ | ✓ |
| every period appears in output | ✓ | ✓ | ✓ |
| duration = elapsed time (start to end) | ✓ | ✓ | ✓ |
| single-record run has duration 0 | ✓ | ✓ | ✓ |
| duration_units converts output | ✓ | ✓ | ✓ |
| run_number is sequential in period | ✓ | ✓ | ✓ |
| contract @examples happy path | ✓ | ✓ | ✓ |
| non-default column names work | ✓ | ✓ | ✓ |

**33 intents converge across all three runs.** This is the high-
confidence core — the contract clearly implies these tests and all
agents independently derived them.

### Majority convergence (2/3)

| Intent | R1 | R2 | R3 | Notes |
|--------|----|----|-----|-------|
| runs cannot span annual boundary | ✓ | ✓ | — | R3 tests WY boundary but not annual explicitly |
| custom season labels by ending year | ✓ | ✓ | — | R3 tests this implicitly within other tests |
| Oct date → next water year | ✓ | — | — | R1 has a separate test; R2/R3 fold into WY label test |
| custom season @examples test | — | ✓ | ✓ | R1 tests custom season differently |
| all values meet condition → single run | ✓ | ✓ | ✓ | Actually 3/3 on closer reading |
| single-row meets → one run | — | ✓ | ✓ | R1 omits single-row edge case |
| single-row doesn't meet → zero-run | — | ✓ | ✓ | R1 omits this too |
| default column names work | ✓ | — | ✓ | R2 tests defaults implicitly through happy path |
| multiple periods mixed results | — | ✓ | ✓ | R1 tests "every period" differently |

### Singletons (1/3)

| Intent | Run | Notes |
|--------|-----|-------|
| no values meet condition → zero-run | R1 | R2/R3 cover via zero-run structure tests |
| error: 11 validation tests (extra) | R2 | R2 counted 11 vs 10; extra may be a grouping difference |

### Universal omissions (0/3)

No contract clause was untested by all three runs. Every agent
achieved full contract coverage by their own assessment.

---

## 3. Divergence analysis

### Same intent, different test data

Most common type of divergence. All three agents test the same
claims but build different fixture data. Examples:
- WY label test: R1 uses Jan 2023, R2 uses data spanning Oct 2021-Sep 2022, R3 uses same pattern as R2
- Comparison tests: R1 uses Flow 10/20/30, R2/R3 use similar but slightly different value patterns
- NA test: All use a 6-element vector with NA in position 3, but start dates vary

This is harmless variation. The test intent is identical.

### Same intent, different structure

- **Zero-run testing:** R1 has a single dedicated "zero-run period"
  test plus a separate "every period" test. R2 splits this into two
  tests (zero-run structure + every period). R3 combines them
  differently. Same coverage, different organization.

- **Default column names:** R1 has a dedicated test. R2 relies on
  happy-path tests using defaults. R3 has a dedicated test. Same
  claim verified, different strategy.

### No contradictory expectations

No run produces expected values that conflict with another run's
expected values for the same input. The agents agree on what
"correct" looks like.

---

## 4. Contract gaps — comparison

| Gap | R1 | R2 | R3 |
|-----|----|----|-----|
| Natural unit inference unspecified | ✓ | ✓ | ✓ |
| MMDD HHMM + Date interaction | ✓ | ✓ | ✓ |
| MMDD validation boundary (Feb 30?) | ✓ | ✓ | — |
| "Continuous" = rows vs time? | — | ✓ | — |
| Custom season labeling edge cases | — | — | ✓ |

**Two gaps are universal (3/3):** natural unit inference and MMDD HHMM
format. These are real underspecifications that should be addressed.

**One gap is majority (2/3):** MMDD validation boundary (what's a
"valid" date string).

**Two gaps are singletons:** "continuous" ambiguity (R2 only) and
custom season labeling edge cases (R3 only). These are less critical
but worth reviewing.

---

## 5. Assumptions — comparison

| Assumption | R1 | R2 | R3 |
|------------|----|----|-----|
| Duration = end − start (not record count) | ✓ | ✓ | ✓ |
| Valid duration_units = difftime units | ✓ | ✓ | ✓ |
| WY convention matches USGS standard | ✓ | ✓ | ✓ |
| "Continuous" = consecutive rows | ✓ | ✓ | — |
| period column type is double | — | — | ✓ |
| Custom season excludes → dropped before run detection | ✓ | — | — |

**Three assumptions are universal:** duration interpretation,
duration_units valid set, and WY convention. These should be made
explicit in the contract.

---

## 6. Untested claims — comparison

| Untested claim | R1 | R2 | R3 |
|----------------|----|----|-----|
| Time zone preservation | ✓ | ✓ | ✓ |
| Multi-site disclaimer | ✓ | ✓ | ✓ |
| MMDD HHMM sub-daily format | ✓ | ✓ | ✓ |
| Not all duration_units tested | ✓ | ✓ | ✓ |
| Gap-filling guidance | ✓ | — | — |

Universal agreement on 4 untested claims: timezone (fragile),
multi-site (guidance), MMDD HHMM (contract gap), and partial
duration_units coverage (redundant).

---

## 7. Feedback to contract

### Tighten (agents diverged)

1. **"Natural unit implied by the data's time step"** — All three
   flagged this. Specify the inference algorithm (e.g., "the modal
   time difference between consecutive records") or state that
   NULL returns a raw difftime object.

2. **MMDD HHMM interaction with Date input** — All three flagged
   this. State explicitly: "MMDD HHMM boundaries require POSIXct
   input; Date input uses MMDD only."

3. **MMDD validation boundary** — Two of three flagged "what counts
   as valid?" (e.g., Feb 30). Add: "The function validates that
   month is 01-12 and day is 01-31. It does not validate calendar
   correctness of the specific month-day combination (e.g., 0230
   is accepted)." — or the opposite, if you prefer strict validation.

### Confirm (all three converged)

The 33 fully convergent test intents represent a well-specified
core. The contract clearly communicates:
- All validation rules
- All comparison operator semantics
- Water year and annual period mechanics
- NA behaviour
- Return structure
- Duration semantics

### Add (implicit requirement worth making explicit)

1. **Duration = end − start** — All three assumed this but noted
   it could also be record count. The contract says "elapsed time"
   which implies subtraction, but making it unambiguous would help.

2. **"Continuous" = consecutive rows** — R2 flagged ambiguity
   about whether "continuous" means row-adjacent or time-adjacent.
   Add: "Runs are identified by consecutive rows in the data frame.
   Temporal gaps between records do not break runs; only changes in
   the exceedance condition or NAs do."

### Remove

Nothing. No clause was universally flagged as untestable guidance
that doesn't belong.

---

## 8. Meta-assessment: is this technique worth routinizing?

### What worked

- **The three runs produced meaningful divergence.** Total test
  counts varied (40, 41, 43) and the specific tests were not
  identical. The divergence revealed real contract ambiguities
  (natural unit inference, MMDD validation) that a single run
  would have either hit or missed depending on the agent's
  interpretation.

- **Contract gaps converged strongly.** The two most important
  gaps (natural unit, MMDD HHMM) were flagged by all three runs.
  This is high-confidence signal.

- **Assumptions surfaced reliably.** The three universal assumptions
  (duration interpretation, duration_units valid set, WY convention)
  are exactly the things that should be explicit in the contract
  but weren't.

- **No false disagreements.** No run produced contradictory expected
  values. When agents disagreed, it was about coverage scope or
  organization, not about what correct behavior looks like.

### What was less informative

- **The core 33 intents were identical.** The contract is specific
  enough that 33 of ~40 test intents converge across all runs.
  This means about 80% of the test file is deterministic given the
  contract — a single run would have captured it.

- **The marginal value of run 3 over run 2 was small.** Most of
  the divergence-driven insights come from comparing any two runs.
  The third run added confirmation (majority vote) but few new
  gaps or assumptions.

### Verdict

**Worth doing once per function at contract-finalization time.
Not worth routinizing for every function.**

Two runs capture most of the value (divergence reveals ambiguity).
Three runs add majority-vote resolution. The technique is most
valuable when:
- The contract is complex (many parameters, domain rules)
- The function encodes non-obvious behavior
- You want to validate the contract before committing to implementation

For simpler functions (like `ddd_convert_discharge()`), a single
derivation run is probably sufficient. The inter-rater technique
is a calibration tool, not a daily practice.

### Cost

Three runs × ~3 minutes each = ~10 minutes wall time. API cost
negligible on a subscription plan. Human review of the comparison
is the real cost — about 30 minutes for a thorough analysis.
Total: under 1 hour for a comprehensive contract validation. This
is reasonable for a function like `tally_runs()` with 7 parameters
and complex period logic.
