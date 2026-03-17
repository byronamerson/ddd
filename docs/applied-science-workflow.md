# Applied Science Workflow

*Context for how the work actually happens. This document describes
the mindset, practices, and error-awareness that shape how an applied
scientist uses data, computation, and conversation to answer questions
about physical systems. It sits alongside Lingua and the
language-specific development principles — not as coding rules, but
as the working context that those rules serve.*

---

## The Nature of the Work

The starting point is a question about a physical system — a river
reach, a hillslope, a groundwater-surface water interface. The
question usually comes from a client project, but the intellectual
work is the same regardless of origin: understand how the system
works, well enough to answer the question defensibly.

This is applied science, not software engineering. Code is a tool
for seeing, not a product in itself. The real work is building a
mental model of the system — its dominant processes, its boundary
conditions, the scales at which different mechanisms matter — and
then using data and published methods to test and refine that model.

---

## Two Phases of Work

### Exploration

Most work begins without a unified design goal. There is a question,
there is data, and there is a body of published literature that
describes how systems like this one behave. The early work is
refractory — reading key papers, plotting the data from different
angles, checking whether the patterns match expectations, building
intuition about what matters at this site.

Code in this phase is investigative. It is often rough, disposable,
and driven by curiosity rather than specification. A plot that reveals
an unexpected pattern may redirect the entire analysis. This is
normal and productive — it means the data is teaching you something.

Conversation is especially valuable in this phase. Talking through
what you see in the data, what the literature says, and what
hypotheses might explain the patterns is how understanding
crystallises. The LLM's breadth across hydrology, geomorphology,
ecology, and statistics makes it a useful sounding board — but the
domain judgment about what matters at *this* site, in *this*
context, belongs to the scientist.

### Development

At some point, a pattern or approach solidifies enough that it needs
to become reliable and repeatable — a calculation applied across
sites, a data pipeline for a client deliverable, a figure that must
be defensible. This is where the contract-first workflow, the
testing discipline, and the coding principles earn their keep.

The transition is not always sharp. Exploratory code often evolves
into production code incrementally. The signal that you have crossed
over is when you start caring about correctness across cases rather
than insight from one case. At that point, slow down and apply the
full discipline: write the contract, derive the tests, implement
carefully.

---

## The Sniff Test

**At every major transition — data ingestion, transformation,
analysis — stop and look.**

- **Does it look right?** Plot it. Do the patterns match what you
  know about this kind of system?
- **Do the values make sense?** Are the magnitudes reasonable? Are
  the ranges physically plausible?
- **Are there unexpected features?** Gaps, spikes, flatlines,
  impossible values, suspiciously round numbers, sudden shifts.
- **Does the spatial distribution look like reality?** A coordinate
  system mismatch can shift your sites into the ocean.
- **Are the axes right?** Check ranges, units, labels. A log-scale
  axis can hide an order-of-magnitude error.

This is not optional housekeeping. It is a primary quality control
mechanism that leverages domain expertise. No automated test replaces
the ability to look at a plot and feel that something is off.

---

## Data Provenance and Units

Errors from unit mismatches and undocumented data transformations are
the most common source of wrong results in applied science.

### When receiving data

- Request the **data source** — where did these numbers come from?
- Request **variable names and definitions** — what does each column mean?
- Request **units of all variables** — never assume. Feet vs. metres,
  cfs vs. cms, mg/L vs. µg/L, gauge datum vs. elevation.
- Request **supporting information** — site descriptions, collection
  methods, known quality issues, methodology changes over time.

### In code

- State units in variable names, docstrings, or comments wherever a
  value has physical dimensions. `discharge_cms` is better than
  `discharge`.
- Treat unit conversions as explicit, named operations — not silent
  multiplications buried in a longer expression.

---

## Scripted Output — No Hand-Transfer of Numbers

The path from computed result to client deliverable must be scripted.
Every time a number passes through a human hand — copied from a
console, pasted into Excel, transcribed into a Word table — there
is a chance of error.

- Write summary tables directly to their final format from code.
- Generate figures programmatically, with all labels, units,
  annotations applied in code.
- If the data change and you rerun the code, tables and figures
  should regenerate correctly without manual intervention.

---

## Slow Is Smooth and Smooth Is Fast

- **Review output three times before sharing.** Check numbers against
  expectations. Check units. Check labels.
- **Wait before hitting send.** The five minutes between "done" and
  "sent" is where many errors are caught.
- **Use version control.** Commit and push daily.
- **Build review time into project plans.**

### When working with the LLM

- Run the generated code.
- Look at the output.
- Apply the sniff test.
- Check the units.
- If something seems off, say so — the conversation is the
  diagnostic tool.

---

## The Role of Conversation

Describing what you see in the data, testing an interpretation
against published concepts, working through the physical logic of
why a system behaves a certain way — this is the intellectual core
of the work. The LLM brings breadth across the literature and across
computational methods. The scientist brings site-specific knowledge,
domain judgment, and the ability to recognise when something does or
does not make physical sense.

The conversation record — the chain of reasoning, the dead ends, the
moments of insight — is itself a valuable artifact. When resuming
work in a new session, loading that context is as important as
loading the code.

---

## Quick Reference

| Practice | Why it matters |
|----------|---------------|
| Explore before committing | You cannot write a good contract for a system you do not yet understand |
| Sniff-test at every transition | Domain expertise catches errors that tests and linters cannot |
| Document data provenance | Unknown units and undocumented sources are where wrong answers start |
| State units explicitly | In variable names, docstrings, data logs — everywhere a physical quantity appears |
| Script the output pipeline | No hand-transfer of numbers between computation and deliverable |
| Slow is smooth, smooth is fast | Review three times. Wait before sending. Build review time into the plan |
| Conversation sharpens thinking | Dialogue with the LLM is scientific reasoning, not overhead |
