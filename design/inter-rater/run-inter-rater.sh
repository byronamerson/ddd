#!/usr/bin/env bash
# run-inter-rater.sh
# Runs three independent test-derivation agents against the tally_runs() contract.
# Each agent gets clean context and writes to its own output directory.
#
# Usage: bash design/inter-rater/run-inter-rater.sh
#
# Prerequisites:
#   - Claude Code CLI installed and authenticated
#   - Run from the ddd project root
#
# Notes on flags:
#   -p                    Non-interactive (headless) mode. Agent runs, outputs, exits.
#   --allowedTools        Pre-approve Read and Write so the agent can read the skill
#                         files and write output without interactive prompts.
#   --disallowedTools     Deny reads on files that would contaminate independence.
#   --max-turns           Cap agent iterations for cost control.
#   --output-format text  Plain text stdout (we don't need JSON for this).
#
# The agent picks up CLAUDE.md from the project root automatically.
# Each run is a fresh invocation with no shared session state.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROMPT_TEMPLATE="$SCRIPT_DIR/agent-prompt.md"

if [ ! -f "$PROMPT_TEMPLATE" ]; then
  echo "Error: prompt template not found at $PROMPT_TEMPLATE"
  exit 1
fi

cd "$PROJECT_ROOT"

for RUN in 1 2 3; do
  OUTPUT_DIR="design/inter-rater/run-${RUN}"
  mkdir -p "$OUTPUT_DIR"

  echo "========================================"
  echo "  Run ${RUN} of 3"
  echo "  Output: ${OUTPUT_DIR}/"
  echo "========================================"

  # Substitute the output directory into the prompt
  PROMPT=$(sed "s|OUTPUT_DIR|${OUTPUT_DIR}|g" "$PROMPT_TEMPLATE")

  # Run the agent in headless mode.
  # --allowedTools: Read (skill files, contract), Write (output files)
  # --disallowedTools: Block reads on files that would contaminate independence
  # --max-turns: Cap iterations (test derivation shouldn't need more than 15)
  echo "$PROMPT" | claude -p \
    --allowedTools "Read,Write" \
    --disallowedTools "Read(tests/testthat/test-tally_runs.R),Read(design/notes/*),Read(exploration/*),Read(design/inter-rater/run-*/*)" \
    --max-turns 20 \
    --output-format text \
    --verbose

  echo ""
  echo "  Run ${RUN} complete. Output in ${OUTPUT_DIR}/"
  echo ""
done

echo "========================================"
echo "  All three runs complete."
echo "  Compare outputs in design/inter-rater/run-{1,2,3}/"
echo "========================================"
