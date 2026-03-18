# Three-Gear Workflow

*How exploratory science work, collaborative design, and contract-first
development fit together.*

---

## The Problem

Contract-first development produces reliable, tested code — but it
assumes you already know what to build. Applied science work often
starts without that certainty. Forcing contract-first discipline on
exploratory work creates friction without adding value. Leaving
exploratory work unstructured forever produces fragile scripts that
quietly break.

The solution is three gears, shifted as understanding solidifies.

---

## Gear 1 — Exploration

**Directory:** `exploration/`
**Context:** `exploration/CONTEXT.md`
**Working artifacts:** scripts, plots, scratch notes
**LLM role:** reactive helper (like live Stack Overflow)
**Structure level:** minimal — no contracts, no tests, no package

You have data and a question. You are building intuition — plotting,
reshaping, checking patterns, reading papers, testing ideas. Code is
rough and disposable. The LLM helps you get scripts running and
surfaces tools you might not know about.

**Shift up when:** a pattern, calculation, or workflow stabilises
and you start caring about correctness across cases.

---

## Gear 2 — Collaborative Design

**Directory:** `design/`
**Context:** `design/CONTEXT.md`
**Working artifacts:** prototype scripts, design notes
**LLM role:** collaborative designer (asks questions, proposes structure)
**Structure level:** informal contracts, working prototypes

You have a functional goal but not a complete specification. Through
dialogue, the LLM asks clarifying questions, proposes helpers,
surfaces edge cases, and builds working prototypes. The specification
emerges from the conversation. Design decisions are recorded as they
happen.

**Shift up when:** you can articulate what each function does, what
it takes, what it returns, and what domain rules it encodes.

---

## Gear 3 — Contract-First Development

**Directory:** package root (`R/`, `tests/`, `man/`)
**Context:** `CLAUDE.md`
**Working artifacts:** Roxygen blocks, testthat files, package code
**LLM role:** constrained implementer (operates within contract + tests)
**Structure level:** full discipline — Roxygen first, tests from
contract, implementation last

The function's purpose, inputs, outputs, and domain rules are known.
Write the Roxygen block. Derive tests. Implement. The LLM generates
code constrained by the contract and validated by the tests.

**Shift down when:** review reveals gaps, new questions emerge, or
the function needs redesign. Drop back to Gear 2 (or Gear 1 if the
problem itself has changed).

---

## The Transition Is a Crystallisation, Not a Copy

Code does not move mechanically from exploration → design → package.
Understanding moves. Each gear produces a different kind of artifact:

- Exploration produces **insight** (plots, patterns, intuition)
- Design produces **specification** (prototypes, decisions, structure)
- Contract-first produces **reliable code** (tested, documented,
  package-ready)

When a function graduates to the package, you write the contract
fresh, informed by what you learned in design. The prototype is a
reference, not a template. This prevents carrying over the rough
edges and implicit assumptions of exploratory code.

---

## The Gears Cycle

The workflow is not a one-way escalator from 1 → 2 → 3. It is a
cycle. Building a tested function in Gear 3 often produces derivative
data or reveals an unconsidered nuance that sends you right back to
Gear 1. You run the new function on real data, look at the output,
and discover a pattern or problem you did not anticipate. That is
not a failure of the process — it is how applied science works.

Common cycling patterns:

- **3 → 1:** A new function generates output that raises new
  questions. Back to exploration with the new data.
- **3 → 2:** Code review or testing reveals a design gap — the
  function needs a different decomposition or an additional helper.
  Back to design.
- **2 → 1:** A design conversation surfaces a question about the
  data itself that cannot be answered without looking. Back to
  exploration.
- **1 → 2 → 1 → 2 → 3:** Multiple loops between exploration and
  design before the specification is stable enough for contract-first.

Each cycle through the gears adds understanding. The exploration
notes and design decisions accumulate — they are the record of how
the analysis matured. A return to Gear 1 is not starting over. It
is a deepening.

---

## Context Isolation

Each gear has its own context document that tells the LLM how to
behave. The key difference:

| | Exploration | Design | Contract-First |
|--|-------------|--------|----------------|
| Contracts | None | Informal comments | Full Roxygen |
| Tests | None | None (maybe ad hoc) | Derived from contract |
| LLM autonomy | Low (reactive) | Medium (proposes) | High (implements within rails) |
| Structure enforcement | None | Light | Full |
| Sniff test | Always | Always | Always |

For agentic tools (Claude Code, Codex), these contexts should be
separate directories with their own CLAUDE.md / AGENTS.md to prevent
the contract-first instructions from polluting exploratory work. For
interactive chat, simply stating which gear you are in is sufficient.

---

## Saying It Out Loud

When working in this desktop app or any interactive chat, state the
gear at the start of a session or when shifting:

- "I'm in exploration mode — help me get this script working."
- "Let's move to design — I want to specify the run-length analysis."
- "This is ready for the package — let's write the contract."

The LLM adjusts its behaviour accordingly. No nagging about tests
during exploration. No skipping contracts during package work.
