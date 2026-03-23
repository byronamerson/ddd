# Session Prompt: Comparative Audit of R Package Function Development Practices

*Paste this into a new Claude Desktop chat within the ddd project.
All project knowledge docs should be loaded.*

---

## Context

I'm developing a contract-first workflow for R function development
(documented in `docs/contract-first.md` and `docs/ddd-progress.md`).
The workflow involves writing Roxygen documentation before
implementation, deriving tests from the contract, then implementing.
It works, but it feels like more ceremony than I'm used to.

Before going further, I want to calibrate. **What do well-regarded R
packages actually do for functions at `tally_runs()`-level complexity?**
By that I mean functions with:

- 5–8 parameters
- Domain logic (not just wrappers)
- Non-obvious edge cases
- Input validation
- A structured return value (tibble/data.frame with specific columns)

## What I want to explore

For 3–5 published, well-regarded R packages, pick one function per
package that matches the complexity profile above. For each function,
examine:

### 1. Documentation quality

- How detailed is the Roxygen? Does it describe domain semantics
  (`@param` says what the parameter *means*) or just types?
- Does `@return` describe the output structure precisely?
- Are edge cases, NA handling, or boundary behaviour documented?
- Are `@examples` present and meaningful?
- How does the documentation compare to the `tally_runs()` contract
  in `R/tally_runs.R`?

### 2. Testing

- Does the function have dedicated tests?
- What fraction of the documented behaviour is tested?
- Are validation checks tested (error on bad input)?
- Are edge cases tested (empty input, NAs, boundary values)?
- Is there any evidence of tests preceding implementation (unlikely
  in most packages, but worth noting)?
- Roughly how many `test_that()` blocks cover the function?

### 3. Input validation

- Does the function validate inputs at the boundary?
- How informative are the error messages?
- Is validation comprehensive (all parameters) or selective?

### 4. Overall ceremony

- What is the ratio of documentation + test code to implementation
  code? (rough line counts are fine)
- Does the package seem to follow a "document first" or "test first"
  philosophy, or is it "implement first, document after"?

## Package selection guidance

Good candidates are tidyverse-adjacent or domain packages that are
well-maintained and have both documentation and tests. Some starting
points to consider (but feel free to suggest better examples):

- **dplyr** or **tidyr** — a function with domain logic, not just
  a verb wrapper
- **sf** — spatial functions with coordinate system parameters
- **lubridate** — date/time functions with edge cases
- **dataRetrieval** — USGS data functions (closest to my domain)
- **survival** or **lme4** — statistical functions with structured
  return values
- **hydrostats** or **fasstr** — hydrological analysis packages

The ideal comparison function is one where I can look at the Roxygen,
the tests, and the implementation side by side and ask: how does this
compare to what my workflow produces?

## How to work

**This is Gear 1 — exploration.** No contracts, no tests, no
structure. Help me read source code, browse GitHub repos, and
compare practices. Be a reactive collaborator.

Use the R session MCP tools to look at installed packages where
available. Use web search and web fetch to browse GitHub repos for
source code and test files. Read the actual `.R` and `test-*.R`
files — don't summarize from memory.

For each function you examine, give me a concrete, honest comparison
to `tally_runs()`. Not "this is good documentation" — show me
specifically what they document vs. what I document, what they test
vs. what I test, and where my workflow produces more or less than
standard practice.

## The question I'm trying to answer

**Is my contract-first workflow producing something substantially
more thorough than well-regarded packages, roughly equivalent, or
actually below standard?** And where the answer is "more thorough"
— is the extra thoroughness earning its keep, or is it overhead?

## Starting point

1. Read `R/tally_runs.R` to refresh on what our contract looks like.
2. Read `tests/testthat/test-tally_runs.R` (first 50 lines or so)
   to see the test density.
3. Pick 3–5 comparison functions and examine them.
4. Synthesize: where does my workflow sit relative to community
   practice?
