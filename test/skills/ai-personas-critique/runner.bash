# shellcheck shell=bash disable=SC2034  # Sourced by generate-reports.bash
# AI personas critique: the draft goes inline in the prompt. Step 1 of SKILL.md
# reads personas.md, but inline mode runs claude in the real repo, where a Read
# tool could also reach expected-verdicts.bash. So Read is withheld and the
# prompt carries the catalog itself, cat'd from the skill directory (resolved
# relative to this file). WebSearch only; no Write, so the report goes to stdout
# instead of docs/reviews/.
FIXTURE_TOOLS="WebSearch"
FIXTURE_MODE="inline"

# Resolved when generate-reports.bash sources this file, not when the function
# runs, so the path does not depend on the caller's working directory.
PERSONAS_CATALOG="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../skills/ai-personas-critique" && pwd)/personas.md"

fixture_prompt() {
  if [ ! -f "$PERSONAS_CATALOG" ]; then
    # Fail loudly: SKILL.md's six-persona fallback would quietly change what
    # every report is measuring.
    echo "runner.bash: persona catalog not found: $PERSONAS_CATALOG" >&2
    return 1
  fi
  printf '%s\n\n' "Critique the proposal below using your skill. User goal: stress-test this proposal from several independent angles before it goes to the people who will decide on it. Do not ask clarifying questions. No cowen-critique or yglesias-critique is running alongside, and no fact-check report is available. You have no file access, so the persona catalog (personas.md, which Step 1 reads) is reproduced in full between the markers below. Print the report to stdout instead of saving it to docs/reviews/."
  printf '%s\n' "----- BEGIN personas.md -----"
  cat "$PERSONAS_CATALOG"
  printf '%s\n\n' "----- END personas.md -----"
  printf '%s' "The proposal:"
}
