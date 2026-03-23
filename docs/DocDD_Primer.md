# Documentation-Driven Development (DocDD) — A Primer

## Introduction

LLMs can write code fast. The problem is discipline: without structure, a coding session turns into a context-window garbage pile. Specs drift from implementation. Tests end up asserting how code works instead of what it's supposed to do. Failed attempts accumulate in context, and the next attempt inherits all the confusion from the last one.

DocDD (Documentation-Driven Development) is a workflow for LLM-assisted development that treats documentation as the source of truth. Docs, tests, and code always enter the codebase together in a single green commit. When something goes wrong, code is rolled back — but the spec and comments survive. The LLM gets a clean slate for the next attempt, armed with better documentation and no memory of the failed approach.

The core discipline: With the LLM, co-create robust documentation, tests, and inline comments as scafolding,  for each function with the LLM.

- Describe the purpose of the function to the LLM

- Have the LLM draft the documentation:

  - a narrative describing the purpose of the function

  - function signature

  - Args: descriptions and role of each argument

  - Side Effects: any side effects the function creates

  - Returns: description of the return value

  - Raises: A description of any errors raised by the function

- Discuss and improve the documentation.

- Have the LLM identify a test suite and test descriptions to the documentation.  Describe tests as *Conditon: Expected result.*  These are espeically useful for spelling out desired function behavior under edge cases.

Then:

- have the LLM write the actual tests and then discuss the tests with the LLM.  If tests are incomplete or missing, update the documentation first to include the information necessary to improve the tests and let the LLM update the tests.
- Commit as a potential rollback point.

NOTE: It is imperative that the LLM write tests based only on the documentation -- without knowledge of implenation.  This way the tests reflect what the code *should* do (rather than being a self-fulfilling prophesy of tests that expect the code to behave exactly as written, bugs and all).

Next:

- Scafold the code by writing inline comments for the code.  The comments should reflect the steps the function algorithm should take, now how to accomplish them.

- Commit the documentation, tests, and comments to a code management repo (e.g., git).  This serves as a roll-back point, if necessary.

The Documentation, tests, and comments provide the LLM the necessay context to create the function.  Finally:

- Let the LLM write the code and run the tests.

- Don't let the LLM fix the tests.  Instead discuss with the LLM what is wrong?  Establish if the problem is with the code or the tests.

- On red, you must intuit which commit to rollback to.  If there are problems with the tests, rolling back the the first test is the most conservative apporach.  That way tests can be fixed without the LLM having knowledge of inline comments.  Practially, rolling back to the second commit usually works and saves rewriting the inline comments.

- Whichever point you roll back to, add any necessary information to the documentation so that the LLM won't repeat its mistake in the tests and/or code.

- Commit again

- run the tests.  Rinse and repeat.

- On green, commit the final code.

The most critical feature of this workflow is that the LLM writes the tests based no knowledge of the documentation only and write the code based on documentation, tests, and inline comments.

---

## The Microcycle (Initial Write)

This is the sequence for writing a new function from scratch.

### Step 1 Spec

Standard section order: description, `Args`, `Side Effects`, `Returns`, `Raises`, `Tests`.

I recommend having the LLM write and discuss everything but the test descriptions.  Discuss and improve.  Then write test descriptions.  Discuss and improve -- potentially identifying tests that are missing from the test suite.

```python
async def client_create(session: AsyncSession, data: dict) -> tuple[dict, str]:
    """Create a new client.

    Args:
        session: Async database session (SQLAlchemy AsyncSession object).
        data: Dict of client fields (e.g., name, issuer, jwks_url, jwks_keys).

    Side Effects:
        Inserts a client row into the database.

    Returns:
        Tuple of (client dict, plaintext API key).

    Raises:
        IntegrityError: If a client with that name already exists.

    Tests:
        Valid name only
            Expect tuple of (dict, str). Dict has name, active=True, id,
            created_at, updated_at. Plaintext API key hashes to api_key_hash.
        Duplicate name
            Expect IntegrityError
        Two successive creates
            Expect different API keys generated
        Missing name in data
            Expect IntegrityError (not-null violation)
    """
```

### Step 2 — Test

Once the spec is approved, tell the LLM to write the tests from the `Tests:` section. There's no need to run the tests.  Just have the LLM write them with know knowledge of implementation.

Review the test code Tests must assert the **contract** — the specification — not the implementation. This is the whole point of writing tests before code: the LLM can't accidentally expect the results of the implementation if the implementation doesn't exist.

### Step 3 — Commit (First rollback point)

### Step 4 — Plan

Ask the LLM to write inline comments that describe the algorithm it will write — the steps the code will follow, written as plain English inside the function body. Review the and discuss with the LLM

```python
async def client_create(session: AsyncSession, data: dict) -> tuple[dict, str]:
  """..."""
# Generate plaintext API key
# Copy data to avoid mutating caller's dict, add hashed key
# Create a Client from the data dict and save to database
# Return the client dict and the plaintext API key
```

Comments describe **what to do and why** — not how to do it. More on this in [Inline Comments](#inline-comments-algorithm-not-implementation).

  ### Step 4 — Commit (Second rollback point)

  Checkpoint. Commit the spec (docstring), the tests, and the inline comments. This is the rollback point.

  If the next step fails, you roll back here — not to an empty file.

  ### Step 5 — Code

  Tell the LLM to write the implementation, interleaved with the comments already in place. The comments act as a scaffold.

  ### Step 6 — Run Tests

  - **Green** — commit. Done.
  - **Red** — roll back the code **AND THE CONVERSATION** to one of the commit points, depending on the problems that are revealed by the failed test. If the problem is in the code, rollback point 2 is fine. If the tests themselves have problems, rolling back to point 1 can be helpful.
  - Improve the documentation, tests, and comments and continue with microcycle from the rollback point.

  The rollback removes any knowledge of the failed code from context, protecting the "context hygene." The improved documentation should provide the information necessary to improve the tests/code.

  ---

    ## The Update Microcycle (Subsequent Changes)

    For improvements, modifications, and bug fixes — when the function already exists and has passed all tests and have been committed in a prior microcycle, you don't need to rollback to points from the prior microcycle.  The committed code from the prior microcycle become the first rollback point.

- Update the Spec (including test descriptions)

- Have the LLM write the tests.

- Update the inline comments.

- Commit (Second rollback point)

- Let the LLM update the code

- Commit on green, rollback on red..

---

## Side Effects in Documentation

The `Side Effects:` section documents any mutations the function performs — database writes, changes to request state, file system operations, external API calls. For pure functions with no mutations, use `None.`

```
Side Effects:
    Inserts a client row into the database.
```

```
Side Effects:
    None.
```

This section matters for three reasons:

1. **Makes impact explicit.** You know what a function touches without reading the implementation.
2. **Guides test authors.** Beyond asserting the return value, tests need to verify side effects — a database row was inserted, a file was written, a field was updated.
3. **Speeds up code review.** Reviewers can assess the scope of a change without tracing through the code.

If the side effects are wrong in the docstring, the spec is wrong. Fix it.

---

## Test Descriptions: The Case/Expect Pattern

The `Tests:` section uses a two-line format: the condition on one line, the expectation indented below it.

```
Tests:
    Valid name only
        Expect tuple of (dict, str). Dict has name, active=True, id,
        created_at, updated_at. Plaintext API key hashes to api_key_hash.
    Duplicate name
        Expect IntegrityError
    Two successive creates
        Expect different API keys generated
    Missing name in data
        Expect IntegrityError (not-null violation)
```

This format does three things:

**Forces edge case thinking during design.** You decide what the function should do when given a duplicate name, a missing required field, or an empty dict — before any code is written. Finding these during design is cheap. Finding them during implementation is not. The LLM will draft test cases, but you are the one who knows which edge cases actually matter for your domain. Review them critically.

**Gives the LLM unambiguous test specs.** The LLM translates each case/expect pair into a test. The description is the test name; the expectation is the assertion. No guessing.

**Acts as an executable contract.** If the tests pass but the descriptions don't match what the code actually does, the spec is wrong. Fix the spec.

  ---

    ## Inline Comments: Algorithm, Not Implementation

    Inline comments describe the algorithm — what to do and why — not the specific code used to do it.

  **Good:** `# Validate each filter dict — required keys, known field, supported op, safe value type`

  **Bad:** `# Loop through filters and check isinstance() on each value`

  The good version states a requirement. The bad version describes an implementation choice. The distinction matters because implementations change; algorithms rarely do. If you refactor from a loop to a list comprehension, the bad comment is now wrong. The good comment stays correct.

  Comments are permanent documentation. They survive refactors and serve as context for anyone reading the code — including the LLM in its next session. Review them with the same care you give the docstring.

  From the actual codebase:

    ```python
  async def client_create(session: AsyncSession, data: dict) -> tuple[dict, str]:
    """..."""
  # Generate plaintext API key

  # Copy data to avoid mutating caller's dict, add hashed key

  # Create a Client from the data dict and save to database

  # Return the client dict and the plaintext API key

  ```

  Each comment states what the next line does and why. The why is as important as the what — "avoid mutating caller's dict" is context that the code alone doesn't convey.

---

## Commits and Rollbacks: Context Hygiene

The checkpoint/rollback strategy is the mechanism that keeps the LLM's context clean.

  **How it works:**

    1. The checkpoint commits saves the spec, tests, and comments at the state where the LLM does not know the implementation.
  2. You tell the LLM to write code against that checkpoint.
  3. If tests fail, you roll back the CODE AND CONVERSATION the code to the checkpoint. The failed code is gone from the working directory and from context.  Essentially, you give the LLM amnesia.
  4. You discuss the failure with the LLM, improve the spec and comments together, commit a new checkpoint, and try again — with better guidance and no memory of what failed.

  **Why this works:**

    Failed approaches accumulate in an LLM's context window and pollute the next attempt. The LLM starts reasoning about what it just tried rather than what the spec requires. Rolling back the converation resets that. The improved documentation is all the LLM needs — it doesn't need to remember the failure, because the failure has been diagnosed and encoded into better specs and comments.

  For subsequent changes, rollback returns to the last green commit rather than to nothing. The function stays functional while the spec iterates.

  ---

    ## Discussion vs Action: You Control the Workflow

    LLMs have a proclivity for coding.  They often write code before there is a complete understanding of the code.

  Discussion means talking through the spec, reviewing drafts, debating edge cases, figuring out what the implementation should do.

  Action means modifying files, running commands, committing.

  Informing the LLM that it should never more forward from discussion to actions on its own..  Tell the LLM that you will direct it to take action.  Four helpful rules to tell your LLM:

    1. ALWAYS FEEL FREE to continue a discussion or provide relevant information without asking if I want to keep discussion.  Unless I tell you otherwise, assume I want to keep discussing.
  2. NEVER go from discussion to taking action (modifying files, committing, searching, etc.) without my permission. If you think it's time to act, you may ask me.
3. Once permission is given, you may take multiple actions, like modifying more than one file without asking each time.
4. When tests fail, don't keep going with actions to fix the tests.  Describe what has happed to me and expect to discuss how to proceed.

  The last point is the most important: **when tests go red, the LLM stops.** It reports what failed and waits for you to decide what to do. It does not diagnose and immediately retry. It does not try to fix the code on its own. That decision — whether to adjust the spec, the test, or the comments — is yours to make. It determines what the next attempt looks like, and the LLM doesn't have the domain knowledge to make it correctly.

---

## Conclusion

DocDD is about having an LLM write code that conforms with the user documentation and passes a predermined suite of unit tests.

When you write the spec first and review it carefully, tests assert a contract. When tests are written before code, the spec has to be clear enough to guide test design. When comments describe the algorithm before the code exists, the implementation has a scaffold instead of a blank page.

The microcycle enforces synchronization: docs, tests, and code are always in the same commit, always in agreement. The rollback strategy enforces clean context: failed attempts don't accumulate, they get replaced with better specs.

  The result is a workflow where green tests actually mean something: the code meets the spec, the spec reflects the domain, and the documentation is something you can hand to the next developer — or the next LLM session — and trust.  As a valuable side effect, this workflow naturally yields documentation, a test suite, and robust code that are always synchronized.
