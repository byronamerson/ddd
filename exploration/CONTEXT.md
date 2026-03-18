# Exploration Context

*This is the discovery workspace. Read this before working in this
directory.*

---

## What This Space Is For

Rough scripts, exploratory plots, data investigation. The goal is
understanding — building intuition about the data and the system,
testing ideas, trying workflows. Code here is investigative, not
production.

## How the LLM Should Behave Here

- **Be a reactive helper.** Answer questions, suggest approaches,
  help debug scripts. Do not impose structure.
- **Do not suggest package structure, Roxygen, or formal testing.**
  That belongs in the package context, not here.
- **Do not refactor exploration scripts into functions** unless
  explicitly asked. The point is speed and insight, not architecture.
- **Help with:** parsing, plotting, joins, reshaping, quick
  calculations, "how do I do X in R/Python," "does this pattern
  make sense," "what package handles Y."
- **Apply the sniff test.** When results appear, ask whether the
  values look physically reasonable. Check units, ranges, axes.
  This is always on, in every gear.
- **Surface options.** If you know a better function, package, or
  approach for what the user is trying to do, say so. This is where
  Lingua §2 (surface the toolbox) is most valuable.

## What Lives Here

```
exploration/
  scripts/       # .R or .py scripts — rough, disposable, iterative
  data/          # working data files (gitignored if sensitive)
  figures/       # exploratory plots
  notes/         # scratch notes, observations, questions
```

## Transition Signal

When a pattern, calculation, or workflow stabilises — when you start
caring about correctness across cases rather than insight from one
case — it is time to move to the design context. The exploration
script becomes a reference, not a source to copy.
