# Applied Analysis Workflow

*How existing tools get composed into defensible analytical products.
This is not contract-first development — it is the downstream work
that contract-first development serves, and where many projects
spend most of their time.*

---

## What This Document Is

The contract-first development workflow (DDD) is about how functions
get built — Roxygen first, tests derived from the contract,
implementation last. This document describes a different mode of
work: composing existing tools — both off-the-shelf R packages and
any bespoke functions produced by DDD — into analytical pipelines
that answer questions and produce deliverables.

For many projects, this is the *only* mode of work. The available
packages handle everything; no new functions need to be built. The
intellectual challenge is not "how do I decompose this into testable
functions" but "how do I chain these pieces together to answer the
question clearly and correctly."

This workflow shares a lineage with DDD. Lingua's principles —
discuss before coding, record decisions, context over memory — apply
here. The R development principles — pure functions, clear naming,
I/O at the boundary — guide how the chains are written. The applied
science workflow's sniff test, data provenance discipline, and "slow
is smooth" practices are more relevant here than anywhere else.

But the unit of work, the quality criteria, and the failure modes
are all different.

---

## The Character of the Work

**This mode has Gear 1 energy — interactive, iterative, LLM as
reactive collaborator. But the stakes are Gear 3 — the output goes
to clients and needs to be defensible.**

The unit of work is not a function with a contract but an analytical
script that embodies a chain of reasoning from data to conclusion.
The script is a living document of the analyst's train of thought
and methods — defensible enough to be deposed. In a legal or
regulatory setting, the analytical script is the evidentiary record
of how conclusions were reached, just as field notes or email
correspondence can be.

This shapes what "quality" means. A package function is a *tool* —
reusable, and verified by tests. An analytical script is an
*argument* — a chain of reasoning from data to conclusion, verified
by whether a competent reviewer can follow it and arrive at the
same judgment.

---

## Relationship to DDD and the Three-Gear Workflow

The dependency runs one direction. The applied analysis workflow
benefits from DDD-produced functions (tested, documented, reliable),
but it works fine with entirely off-the-shelf tools. DDD does not
depend on the applied analysis workflow.

Both depend on the shared foundations:

- **Lingua** — discuss before coding, record decisions, context
  over memory, code as language
- **R Development Principles** — pure functions, clear naming,
  method chains, no deep nesting
- **Applied Science Workflow** — sniff test, data provenance,
  unit discipline, scripted output, slow is smooth

The applied analysis workflow is not a "gear" in the DDD sense. It
is a sibling workflow that shares the same intellectual foundations
but operates on a different unit of work with different quality
criteria.

---

## The Unit of Work: The Analytical Script

The structural element of this workflow is a script (or notebook, or
script-plus-notebook pair) that chains existing tools into a pipeline
producing specific data products.

### What a script contains

- Data ingestion and any preprocessing
- Analytical transformations, each a composition of existing
  functions (from packages or from DDD-produced bespoke tools)
- Production of data products: tables, figures, summary statistics
- Interpretive notes and observations captured as they emerge

### The script-level contract

Just as a function benefits from a Roxygen block stating its purpose,
inputs, and outputs, an analytical script benefits from a header
block that states what it produces and from what:

```r
# =============================================================
# Table 3: Annual exceedance summary by period
# Figure 5: Hydrograph with exceedance runs highlighted
#
# Input: cleaned daily discharge (cms) from data/processed/
# Sites: Meacham Creek (USGS 14018500), Elder Creek (USGS 11475560)
# Units: discharge in cms throughout
# Year convention: water year (Oct 1 start)
# =============================================================
```

This header is not a test scaffold — it is a stated intent against
which the output can be checked. If the header says "discharge in
cms" and the figure axis says "cfs," the contradiction is visible.
If it says "water year" and the x-axis shows calendar years, the
mismatch is a signal.

### The companion notebook pattern

One promising structural form: the script stays the computational
backbone — runs top to bottom, produces all outputs, is the thing
you rerun when data change. A companion Quarto document sources the
script (or key sections) and wraps the products in interpretive
narrative. The script is the reproducible record. The notebook is
the readable one. They stay linked because the notebook calls the
script, not because someone copied numbers between them.

---

## Where Unforced Errors Live

Three error patterns dominate this mode of work, and the mitigations
for each are different.

### Composition errors

Wrong column fed to a function, filter applied in the wrong order,
a join that silently drops or duplicates rows. The code runs without
complaint. The output looks plausible. The error hides.

**Mitigation: inline assertions at major transformation steps.**
Not formal tests — lightweight, disposable guardrails:

```r
# After join: every site in discharge_df should appear in result
stopifnot(all(discharge_df$site_id %in% result$site_id))

# After filter: should retain only summer months
stopifnot(all(result$month %in% 6:9))

# After pivot: row count should equal sites × years
stopifnot(nrow(result) == n_distinct(result$site) * n_distinct(result$year))
```

These catch the silent filter-that-dropped-rows or
join-that-duplicated-records problems before they propagate. They
are disposable — delete them or comment them out once the pipeline
is stable. But during development, they are the equivalent of the
sniff test written into the script.

### Presentation errors

Mislabeled axes, wrong units on a figure, a table with the wrong
date range, a legend that does not match the data. These are
syntactically correct code. They are only visible to a domain
expert looking at the final product.

**Mitigation: the reviewer agent (see below) and the script-level
contract.** The stated intent in the script header gives the
reviewer — human or automated — something to check against. "This
figure shows discharge in cms, log scale, water year 2019–2023"
is a checkable claim.

The deeper mitigation is the "review three times before sending"
discipline from the applied science workflow. The question is
whether structural aids can make that review more systematic.

### Staleness errors

You ran sections interactively during development. You modified
something in the middle and reran the bottom half but not the top.
The script now depends on objects in the global environment that
would not exist in a clean session. The output looks correct
because it was produced from stale intermediates.

**Mitigation: rerun from a clean session before anything ships.**
`source()` the script in a fresh R session with nothing in the
global environment. If it does not produce the right output from
a cold start, the script has a hidden dependency on interactive
state.

Quarto's render-from-clean-session behaviour enforces this
automatically, which is a practical argument for using it as the
production wrapper even if development is interactive.

---

## The Reviewer Agent

A concept for catching presentation errors: a system prompt encoding
the review habits of an experienced colleague, designed to be
persnickety rather than deferential.

### The principle

Separating the *maker* role from the *checker* role is why human
code review works and why "marking your own homework" fails. The
analyst is in production mode when making the figure. The reviewer
agent is in adversarial mode when checking it.

### What it needs

- **The review protocol** — captured from an experienced reviewer
  of charts and tables. What they look at first (scan order), what
  triggers instant rejection, what triggers "this smells funny"
  questions.
- **The analyst's greatest hits** — the personalised, recurring
  error patterns that a regular reviewer learns over time. "Did
  you check the datum?" "Is this cfs or cms?" "Did the seasonal
  filter actually exclude what you think it excluded?"
- **The stated intent** — the script-level contract. "Here is
  Figure 3 and here is what it is supposed to show." Mismatch
  detection between stated intent and visible output is the core
  task.

### How it works

Feed the agent a figure (as an image) or table plus the intent
statement from the script header. The agent asks the annoying
questions a good reviewer would. It does not hedge. A reviewer
who hedges is useless.

### Status

The review protocol needs to be captured from a domain expert.
The structural elements — script-level intent statement, adversarial
system prompt, vision-model review of figures — are ready to
prototype once the protocol exists.

---

## The LLM's Role in This Workflow

The LLM operates as a reactive collaborator — the "live Stack
Overflow" role from Gear 1, but applied to composition rather than
exploration. Typical interactions:

- "How do I reshape this output for the summary table?"
- "What's the right way to overlay the run-length results on the
  hydrograph?"
- "This join is producing more rows than I expected — help me
  diagnose."
- "Write the ggplot code for Figure 3 per the spec in the header."

The LLM helps write the chains quickly, but it can also silently
get a column name wrong and the code will run without complaint.
The inline assertions and the sniff test are the counterweights.

### Notes and observations

During analysis, the LLM can help capture observations as they
emerge — patterns noticed in the data, sensitivities discovered,
anomalies flagged for later investigation. These become the raw
material for reporting and for future sessions. They are the
applied-science equivalent of Lingua §5 (record decisions).

---

## Pre-Registered Expectations — The Red Test for Analysis

In contract-first development, the red phase — writing a failing
test before the implementation exists — is what prevents the code
from silently defining its own standard of correctness. The same
principle applies to analytical work, but the mechanism needs to
be different because the unit of work is a pipeline step, not a
function.

### The core idea

Before running a major transformation or generating a data product,
write down what you expect the result to look like. Not a formal
test — a falsifiable claim, recorded in the script before the code
that produces the result.

```r
# EXPECT: join produces ~3,650 rows (10 years × 365 days)
# EXPECT: discharge range 0.5–200 cms for Meacham Creek
# EXPECT: figure shows clear seasonal signal, peak flows in spring
result <- discharge_df %>%
  left_join(site_info, by = "site_id") %>%
  filter(water_year %in% 2013:2022)

# CHECK (delete or comment out when stable)
stopifnot(nrow(result) > 3000, nrow(result) < 4000)
stopifnot(range(result$discharge_cms, na.rm = TRUE)[2] < 500)
```

### Why this is different from the sniff test

The sniff test is post-hoc and implicit — you look at the output
and ask "does this seem right?" The pre-registered expectation is
written down *before* the result exists, so it cannot be influenced
by what the result happens to show. A discharge value of 2,000 cms
looks wrong if you wrote "expect 0.5–200" beforehand. It might
look plausible if you see it cold and think "well, maybe there was
a big flood."

This is the same principle that makes tests-before-implementation
work in DDD: you form expectations before seeing the result, so the
result cannot quietly reshape your expectations. It is also the
principle behind pre-registration in experimental science.

### What this might look like in practice

This is not yet tested. The open questions:

- **Granularity.** At every pipeline step? Only at major
  transitions? Only when producing a final data product? Too
  coarse and it misses composition errors. Too fine and it
  becomes friction that gets skipped under deadline pressure.
- **Format.** Comment-based expectations (human-readable, no
  runtime effect) vs. `stopifnot()` assertions (catch violations
  automatically but require numeric thresholds) vs. a mix of
  both. The qualitative expectations ("clear seasonal signal")
  cannot be automated — they are prompts for the human sniff
  test. The quantitative ones ("~3,650 rows," "range 0.5–200")
  can be.
- **Lifecycle.** Do the expectations stay in the script
  permanently (as documentation of what the pipeline should
  produce) or get cleaned out once the pipeline is stable? If
  they stay, they serve double duty as the script-level contract
  and as regression checks when the data change.
- **Integration with the reviewer agent.** The qualitative
  expectations ("figure shows seasonal signal, peak flows in
  spring") are exactly the kind of stated intent the reviewer
  agent would check against. The expectations become the
  prompt for the reviewer.

### Next step

Try this on a real project and see where it helps and where it is
just noise. The hypothesis is that the quantitative expectations
(row counts, value ranges, column presence) catch composition
errors cheaply, and the qualitative expectations (what the figure
should show) prime the sniff test so it is deliberate rather than
casual. But this needs practice to verify.

---

## Open Questions

1. **Script-level contract format.** How prescriptive should the
   header block be? Is the content requirement (state products,
   inputs, units, conventions) sufficient, or does a specific
   template help?

2. **Notebook vs. script vs. both.** When is a companion notebook
   worth the overhead? When is a well-commented script sufficient?
   Does the answer depend on whether the deliverable includes
   interpretive narrative?

3. **Pre-registered expectations in practice.** Does writing
   expectations before pipeline steps actually catch errors, or
   does it become a ritual that gets skipped? What granularity
   works?

4. **The reviewer agent.** Capture the review protocol from a
   domain expert. Prototype the adversarial reviewer. Test whether
   vision-model review of figures catches real presentation errors.

5. **Greatest-hit error catalogue.** Build a running list of
   personal recurring errors to feed the reviewer agent. This list
   is the highest-value input to the system.

---

## Quick Reference

| Element | In this workflow |
|---------|-----------------|
| Unit of work | Analytical script or script + notebook pair |
| Quality criterion | A competent reviewer can follow the chain from data to conclusion |
| LLM role | Reactive collaborator — helps compose, diagnose, capture notes |
| Contract | Script-level header stating products, inputs, units, conventions |
| Verification | Inline assertions, sniff test, pre-registered expectations, clean-session rerun, reviewer agent |
| Error patterns | Composition (silent misjoins), presentation (labels/units), staleness (interactive state) |
| Shared foundations | Lingua, R development principles, applied science workflow |
| Relationship to DDD | Sibling workflow, not a gear. Benefits from DDD tools, does not require them |

---

*This document was developed in conversation, March 2026. It should
be loaded alongside Lingua, the language-specific development
principles, and the applied science workflow document as shared
context.*
