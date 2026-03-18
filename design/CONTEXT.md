# Design Context

*This is the collaborative design workspace. Read this before working
in this directory.*

---

## What This Space Is For

You have a functional goal — "I want to measure run lengths by
season" or "I need a function that detrends temperature data" —
but the specification is not yet complete. This is where
specification emerges through conversation and prototyping.

## How the LLM Should Behave Here

- **Be a collaborative designer.** Ask clarifying questions. Propose
  structure. Suggest edge cases the user hasn't considered. Build
  helpers the user might not have thought of. This is Lingua §2 at
  full strength.
- **Produce working code, but treat it as a draft.** Code written
  here is a prototype — it demonstrates the approach and surfaces
  requirements. It is not the final implementation.
- **Use informal contracts.** Functions should have a comment block
  that says what they do and why, but not full Roxygen with every
  `@param` entry. The goal is to capture design intent, not to
  produce package-ready documentation.
- **Record design decisions as they emerge.** When a question gets
  answered ("should the function handle NA runs or not?"), note the
  decision in a comment or in the design notes file. These decisions
  are the raw material for the formal contract later.
- **Suggest decomposition.** When a functional goal implies multiple
  helpers, propose the breakdown. Name the helpers. Sketch what each
  one does. The user validates the decomposition against domain
  knowledge.
- **Do not enforce test-before-implement here.** The prototype may
  evolve through several iterations before the design settles. Tests
  come later, in the package context.
- **Sniff test still applies.** Run the prototype on real or
  realistic data. Check that results make physical sense.

## What Lives Here

```
design/
  prototypes/    # working scripts that prototype a function or workflow
  notes/         # design decisions, conversation summaries, sketches
```

## Transition Signal

When the prototype works, the decomposition is stable, and you can
articulate what each function does, what it takes, what it returns,
and what domain rules it encodes — the design is ready to graduate
to the package. At that point:

1. Write the formal Roxygen contract in the package, informed by
   what you learned here.
2. Derive tests from the contract.
3. Implement in the package, using the prototype as a reference but
   not copying it verbatim.

The design notes and prototype remain here as a record of how the
specification emerged.
