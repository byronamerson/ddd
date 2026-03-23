#!/usr/bin/env bash
# test-disallowed-tools.sh
# Probes open questions about Claude Code CLI behavior before running
# the inter-rater experiment.
#
# Usage: bash design/inter-rater/test-disallowed-tools.sh
# Run from the ddd project root.
#
# Open questions tested:
#   Q1. Does --disallowedTools with path-scoped Read patterns actually
#       block the agent from reading specific files?
#   Q2. Does piping a prompt via stdin to `claude -p` (with no prompt
#       argument string) work? Or does -p require an argument?
#   Q3. Is the Write tool name "Write" — and does --allowedTools "Write"
#       actually let the agent create files without prompting?
#   Q4. Can the agent create NEW files in subdirectories?
#
# How the test works:
#   - Creates a temp directory with an allowed file and a blocked file
#   - Runs one claude -p invocation that attempts to:
#       (a) read an allowed file           → tests Q1 (positive control)
#       (b) read a disallowed file         → tests Q1 (deny rule)
#       (c) read an existing test file     → tests Q1 (deny rule, real file)
#       (d) write results to a new file    → tests Q3 and Q4
#   - If we get output at all              → confirms Q2 (stdin piping works)
#
# The entire test runs in ~30 seconds and costs a few cents of API usage.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_DIR="$PROJECT_ROOT/design/inter-rater/toolchain-test"

# --- Setup ---
echo "Setting up test fixtures..."
mkdir -p "$TEST_DIR"

cat > "$TEST_DIR/allowed-file.txt" <<'EOF'
This file SHOULD be readable.
Content: ALPHA
EOF

cat > "$TEST_DIR/secret-file.txt" <<'EOF'
This file should NOT be readable.
Content: BRAVO
EOF

# Remove any previous results
rm -f "$TEST_DIR/results.md"

PROMPT=$(cat <<'PROMPT_EOF'
You are running a toolchain test. Do exactly these steps in order
and report the results. Do not do anything else.

1. Try to read `design/inter-rater/toolchain-test/allowed-file.txt`.
   Report whether you succeeded and what content you saw.

2. Try to read `design/inter-rater/toolchain-test/secret-file.txt`.
   Report whether you succeeded or were blocked, and copy any error
   message you received.

3. Try to read `tests/testthat/test-tally_runs.R`.
   Report whether you succeeded or were blocked, and copy any error
   message you received.

4. Write your results to the file
   `design/inter-rater/toolchain-test/results.md`
   using exactly this format:

## Toolchain Test Results

### Q1a: Read allowed file
- Attempted: yes/no
- Succeeded: yes/no
- Content seen: [what you saw, or "blocked"]

### Q1b: Read disallowed file (secret-file.txt)
- Attempted: yes/no
- Succeeded: yes/no
- Content seen: [what you saw, or "blocked"]
- Error message: [exact error text, or "none"]

### Q1c: Read disallowed file (test-tally_runs.R)
- Attempted: yes/no
- Succeeded: yes/no
- Content seen: [what you saw, or "blocked"]
- Error message: [exact error text, or "none"]

### Q3-Q4: Write to new file
- If you are reading this, the write succeeded.

### Tool names observed
- What tool name did you use to read files? (e.g., Read, ReadFile, read)
- What tool name did you use to write this file? (e.g., Write, WriteFile, write)

Do not do anything beyond these four steps.
PROMPT_EOF
)

echo ""
echo "========================================"
echo "  Toolchain test: Claude Code CLI flags"
echo "========================================"
echo ""
echo "  Q1: --disallowedTools path-scoped Read patterns"
echo "  Q2: stdin piping to claude -p (no argument)"
echo "  Q3: Write tool name and --allowedTools coverage"
echo "  Q4: Agent creating new files in subdirectories"
echo ""
echo "  Allowed:  design/inter-rater/toolchain-test/allowed-file.txt"
echo "  Blocked:  design/inter-rater/toolchain-test/secret-file.txt"
echo "  Blocked:  tests/testthat/test-tally_runs.R"
echo "  Write to: design/inter-rater/toolchain-test/results.md"
echo ""

cd "$PROJECT_ROOT"

# --- Run the test ---
# Q2 test: piping prompt via stdin with no -p argument string.
# If this fails, the fallback is: claude -p "$(cat <<'EOF' ... EOF)"
echo "$PROMPT" | claude -p \
  --allowedTools "Read,Write" \
  --disallowedTools "Read(design/inter-rater/toolchain-test/secret-file.txt),Read(tests/testthat/test-tally_runs.R)" \
  --max-turns 10 \
  --output-format text \
  --verbose

EXIT_CODE=$?

echo ""
echo "========================================"
echo "  Test complete. Exit code: $EXIT_CODE"
echo "========================================"
echo ""

# --- Evaluate results ---

# Q2: Did the command run at all?
if [ $EXIT_CODE -ne 0 ]; then
  echo "FAIL Q2: claude -p with stdin piping returned exit code $EXIT_CODE"
  echo "  The -p flag may require a prompt argument string."
  echo "  Try: claude -p \"\$(cat prompt.md)\" instead of piping."
else
  echo "PASS Q2: claude -p accepted stdin pipe (exit code 0)"
fi
echo ""

# Q3-Q4: Did the agent write the results file?
if [ -f "$TEST_DIR/results.md" ]; then
  echo "PASS Q3-Q4: Agent created results.md in subdirectory"
  echo ""
  echo "--- Agent's report ---"
  cat "$TEST_DIR/results.md"
  echo ""
  echo "--- End report ---"
else
  echo "FAIL Q3 or Q4: results.md was not created."
  echo "  Either the Write tool name doesn't match --allowedTools,"
  echo "  or the agent cannot create files in subdirectories,"
  echo "  or the agent was not given permission to write."
  echo ""
  echo "  Check --verbose output above for tool permission errors."
fi

echo ""
echo "To clean up: rm -rf design/inter-rater/toolchain-test/"
