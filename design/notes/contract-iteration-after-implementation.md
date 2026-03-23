# Contract Iteration After Implementation

*Observation from the tally_runs test-derivation session, 2026-03-19.*

The contract-first workflow writes the Roxygen block before tests and
implementation. But implementation reveals decomposition — helpers
emerge (e.g., `assign_water_year()`, `detect_runs()`, `validate_period()`)
that weren't visible at the contract stage.

Each helper that encodes domain knowledge or a non-obvious decision
needs its own contract (per the contract threshold test in
ddd-progress.md). Those contracts didn't exist at test-derivation
time because the helpers didn't exist yet.

This means the workflow has a natural iteration loop:

1. Write the public function contract
2. Derive tests from it
3. Implement — helpers emerge
4. Write contracts for the helpers
5. Derive tests for the helpers
6. Possibly revise the public contract if implementation revealed
   gaps, ambiguities, or wrong assumptions

The derivation report from the test agent flagged several of these
gaps (natural time step inference, duration type ambiguity, custom
period labeling for multi-year data). Those gaps are likely where
helpers will crystallise.

**Implication for the skill:** The test-derivation skill should be
re-runnable. After implementation produces helpers with their own
contracts, the skill runs again on each helper. It may also re-run
on the revised public contract if the implementation surfaced changes.
The skill is not a one-shot tool — it's part of an iterative cycle.
