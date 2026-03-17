# Next Session Prompt

Read CLAUDE.md and docs/r-principles.md before responding.

We are setting up a contract-first R development workflow in this directory.
The guiding documents are already in place. The next step is two things:

1. Scaffold this directory as an R package using `usethis::create_package()`
   so the `R/`, `tests/testthat/`, and `DESCRIPTION` structure exists.

2. Walk through one complete function end-to-end — Roxygen block first,
   tests derived from the contract, then implementation — to verify the
   workflow is real and not just theoretical.

We have MCP filesystem access to this directory. Start by reading CLAUDE.md,
then propose a package name and confirm the scaffold before touching anything.
