# Inter-Rater Comparison Protocol

*How to analyse the output from three independent test-derivation runs.
Load this into a fresh session along with the three run outputs.*

---

## What you have

Three independent test files, three derivation reports, and three file
access logs, all derived from the same Roxygen contract (`R/tally_runs.R`)
using the same skill (`design/skills/test-from-contract/`). No run should
have had access to the others' output or to prior derivation artifacts.

Baseline for reference: `tests/testthat/test-tally_runs.R` (49 tests
from the original bespoke prompt derivation). This is not part of the
inter-rater comparison but provides a fourth data point.

---

## Analysis steps

### 0. Contamination check

Before any other analysis, read `file-access-log.md` from each run.
For each run, verify:

- Did the agent read `tests/testthat/test-tally_runs.R`?
- Did the agent read anything in `design/notes/` or `exploration/`?
- Did the agent read another run's output directory?
- Did the agent list directory contents that could have revealed
  structure or naming patterns?

If any run is contaminated, flag it in the comparison. A contaminated
run is still usable data — it tells you something about what the agent
converges toward when it has extra information — but it cannot count
as an independent derivation for the inter-rater analysis. Note which
runs are clean and which are not, and weight the convergence analysis
accordingly.

### 1. Test count comparison

From each derivation report, extract the test count by category.
Present as a table:

| Category | Run 1 | Run 2 | Run 3 | Bespoke |
|----------|-------|-------|-------|---------|
| Validation | | | | 13 |
| Happy-path | | | | 4 |
| ... | | | | |
| **Total** | | | | **49** |

Large differences in total count suggest the agents interpreted the
scope of the contract differently. Differences within categories are
more informative than total count.

### 2. Convergence analysis — test intents

The unit of comparison is *test intent*, not test implementation. Two
runs might both test "NA breaks a run" but with different fixture data,
different variable names, or different assertion structures. Those
are the same intent.

For each `test_that()` block in each run, extract the description
string. Group by intent across runs:

- **Full convergence (3/3):** All three runs test this claim. High
  confidence — the contract clearly implies it.
- **Majority convergence (2/3):** Two runs test it, one omits it.
  The omission is likely a miss, not a deliberate exclusion. Check
  whether the derivation report flags it as untested.
- **Singleton (1/3):** Only one run tests this. Either the contract
  is ambiguous about whether this is testable, or one agent was more
  thorough. Review the contract clause to determine which.
- **Universal omission (0/3):** A contract clause that no run tested.
  This is the danger zone — likely underspecified or phrased as
  guidance rather than behaviour.

### 3. Divergence analysis — different interpretations

Where runs disagree, classify the disagreement:

- **Same intent, different test data.** The agents chose different
  fixtures but tested the same claim. This is harmless variation.
- **Same intent, different assertions.** Same claim, but one uses
  `expect_equal()` on specific values while another uses structural
  checks. May reveal that the contract doesn't specify precision.
- **Different intents for the same contract clause.** One agent
  interprets a clause as testing X, another as testing Y. This
  reveals ambiguity in the contract.
- **Contradictory expectations.** Two agents expect different results
  for the same input. This is the most valuable divergence — it
  means the contract is genuinely ambiguous.

### 4. Contract gap comparison

From each derivation report, extract the "Contract gaps" section.

- **Gaps flagged by all three runs:** These are real underspecifications
  that need to be addressed in the contract.
- **Gaps flagged by one run only:** Either a false alarm or something
  the other agents resolved by making an assumption. Check the
  "Assumptions made" sections for the corresponding resolution.

### 5. Assumptions comparison

From each report, extract the "Assumptions made" section.

- **Same assumption across all three:** The contract implies this
  strongly enough that all agents converged. Consider making it
  explicit in the contract.
- **Different assumptions for the same ambiguity:** The contract is
  genuinely underspecified. The differing assumptions reveal the
  design decision that needs to be made.

### 6. Feedback to contract

Based on the above:

1. **Tighten** — contract clauses where agents diverged need more
   precise language.
2. **Confirm** — clauses where all three converged are well-specified.
3. **Add** — if agents consistently tested something not in the
   contract, it may be an implicit requirement worth making explicit.
4. **Remove** — if all three flagged a clause as untestable guidance,
   consider whether it belongs in the contract at all.

---

## Output

The comparison produces:

1. A contamination assessment for each run
2. A convergence table (test intents × runs)
3. A list of contract revisions needed
4. An assessment: is this technique worth routinizing?

The last question is the meta-experiment: did the three runs produce
enough divergence to be informative, or are they so similar that a
single run suffices?
