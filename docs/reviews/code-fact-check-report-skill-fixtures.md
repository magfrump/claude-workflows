# Code Fact-Check Report

**Commit:** 04c0746
**Replication:** k=3
**Repository:** /workspace (claude-workflows)
**Scope:** Pass 1 of a split review (harness only): `git diff answers-2026-09-20...skill-fixtures` restricted to 40 harness files (generate-reports.bash, eval-helpers.bash and their bats suites, arithmetic-eval-gate.bats, health-check.sh/.bats, .gitignore, 22 runner.bash, 10 *-format.bats), plus the commit messages touching them. Merged most-severe-wins from replicates r1-r3 (`code-fact-check-report-skill-fixtures-r{1,2,3}.md`).
**Checked:** 2026-09-24
**Total claims checked:** 45
**Summary:** 26 verified, 8 mostly accurate, 2 stale, 3 incorrect, 6 unverifiable

Merge note: r1's claim sections are the base; clusters surfaced only by r2/r3 carry that replicate's section. Evidence and execution logs are in each replicate report (scratchpad logs; not committed).

---

## Claim 1: "A fixture is a file, or a directory for tree-mode runners (test/skills/generate-reports.bash: self-eval, divergent-design)."

**Location:** `scripts/health-check.sh:314-315`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both loops of `check_fixture_verdicts` (the forward loop accepts `-f || -d`; the reverse loop tests `-e`) and the fa3c5c0 claim that the pre-fix script produced 10 failures. Does not establish behavior for symlinked or special-file fixtures, which `-e` also accepts.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

```bash
# scripts/health-check.sh:316-317
            [[ -f "$fixture" || -d "$fixture" ]] || continue
# scripts/health-check.sh:333
            if [[ ! -e "$skill_dir/fixtures/$key" ]]; then
```
`test/scripts/health-check.bats:80-85` passes, and it asserts both "self-eval: all fixtures have verdicts and vice versa" and the same line for divergent-design. The pre-fix script (`fa3c5c0^`), run with `HEALTH_CHECK_SKIP_BATS=1` from /workspace (exit status not captured; the log records the failure count), prints exactly 10 "fixture does not exist" failures. That matches the commit message's "10 failures, reproduced".

**Evidence:** `scripts/health-check.sh:299-342`, `test/scripts/health-check.bats:80-85`, LOGS/cfc-skill-fixtures-r1-bats.log (cmd `bats test/generate-reports.bats test/skills/eval-helpers-transcript.bats test/skills/arithmetic-eval-gate.bats test/scripts/health-check.bats`, cwd /workspace, exit 0, 2026-09-24T17:04), LOGS/cfc-skill-fixtures-r1-hc-old.log (2026-09-24T17:07)

---

---
## Claim 2: "every committed fixture set has a runner the generator accepts"

**Location:** `test/generate-reports.bats:272`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what this test asserts. Does not establish whether today's runners are accepted; I checked that separately, and all 22 are.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** none

The test only checks that the file exists:
```bash
# test/generate-reports.bats:276-280
  for dir in "$REPO_ROOT"/test/skills/*/fixtures/; do
    local skill_dir="${dir%/fixtures/}"
    [ -f "$skill_dir/runner.bash" ] || missing+=("$(basename "$skill_dir")")
  done
  [ "${#missing[@]}" -eq 0 ] || { echo "no runner.bash: ${missing[*]}"; return 1; }
```
The test never sources the runner and never applies the generator's FIXTURE_TOOLS, fixture_prompt, Write/Edit, FIXTURE_MODE or FIXTURE_TRANSCRIPT checks (`generate-reports.bash:85-115`). A runner with `FIXTURE_MODE="sideways"` or `FIXTURE_TOOLS="Read,Write"` would pass it. I sourced each of the 22 runners under bash and applied those guards. All 22 are accepted today, so the test's conclusion holds now, but the test does not enforce it. Fix: rename the test to "…has a runner.bash", or source each runner and apply the guards.

**Evidence:** `test/generate-reports.bats:272-281`, `test/skills/generate-reports.bash:85-115`, LOGS/cfc-skill-fixtures-r1-guard.log (cwd /workspace, exit 0, 2026-09-24T17:08)

---

---
## Claim 3: "SKILL.md puts the no-fact-check warning (up to 5 lines) above the title" (ai-personas-critique)

**Location:** `test/skills/ai-personas-critique-format.bats:22-23`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what ai-personas-critique's SKILL.md says about where the warning goes. Does not establish where real reports put it.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

The SKILL says only "before the critique", not "above the title":
```
# skills/ai-personas-critique/SKILL.md:110-113
If no fact-check report is provided, emit this warning before the critique:

> **No fact-check report provided.** Checkable claims have not been independently verified.
> For full verification, run the `fact-check` skill first or use the `draft-review` orchestrator.
```
The warning is 2 lines, which is within "up to 5". But this SKILL does not put it above the title. The widened 12-line window is harmless. The comment should say "before the critique (placement relative to the title unspecified)".

**Evidence:** `skills/ai-personas-critique/SKILL.md:104-113`, `test/skills/helpers.bash:125-131`

---

---
## Claim 4: "Resolved when generate-reports.bash sources this file, not when the function runs, so the path does not depend on the caller's working directory."

**Location:** `test/skills/ai-personas-critique/runner.bash:11-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers resolution of PERSONAS_CATALOG under bash from an unrelated cwd. Does not establish behavior under non-bash shells (under zsh `BASH_SOURCE` is unset and the `cd` fails), and the generator always uses bash.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

```bash
# test/skills/ai-personas-critique/runner.bash:13
PERSONAS_CATALOG="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../skills/ai-personas-critique" && pwd)/personas.md"
```
`bash -c 'cd /tmp && source /workspace/test/skills/ai-personas-critique/runner.bash && fixture_prompt subject.md'` produced the full prompt with the catalog embedded (8651 bytes, exit 0). If the catalog is missing, `fixture_prompt` returns 1 (`:15-20`). `prompt="$(fixture_prompt …)"` at `generate-reports.bash:155` then aborts the script under `set -e`, which matches "Fail loudly".

**Evidence:** `test/skills/ai-personas-critique/runner.bash:11-26`, `test/skills/generate-reports.bash:154-155` (paraphrased — no quote available because the run's output was inspected in the terminal and not saved to a log file; command given above, cwd /tmp, 2026-09-24T17:04)

---

---
## Claim 5: "Both are extracted from SKILL.md at test time, so these tests exercise exactly what a model would paste." (plus b5bf458: "Mutation-checked: adding os to ALLOWED_MODULES, dropping __class__ from the dunder list, or dropping ast.Mod from the evaluator each fails a test.")

**Location:** `test/skills/arithmetic-eval-gate.bats:7-8`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers extraction of the live `skills/arithmetic-eval/SKILL.md` (not a vendored copy), the non-empty-extraction guards, and all three commit-message mutations. Does not establish coverage of confine.py or the bwrap/unshare tiers (out of scope per the file's own header).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

```bash
# test/skills/arithmetic-eval-gate.bats:18,23-27
  SKILL="$REPO_ROOT/skills/arithmetic-eval/SKILL.md"
  awk "/timeout 5 python3 -c '\$/ { f=1; next } /^' \\) <<'EXPREOF'\$/ { f=0 } f" \
    "$SKILL" > "$MODE1"
  awk "/^cat > \"\\\$AE\\/check.py\" <<'AE_CHECK_EOF'\$/ { f=1; next } /^AE_CHECK_EOF\$/ { f=0 } f" \
    "$SKILL" > "$CHECK"
```
Today the extractions yield 40 lines (Mode 1) and 87 lines (check.py). The delimiters sit at SKILL.md:42/83 and :106/194. I ran each mutation on a copy of SKILL.md in a scratch tree and re-ran the suite. Adding "os" to ALLOWED_MODULES failed test 13. Removing `"__class__",` failed test 15. Removing `ast.Mod:operator.mod` failed test 6. The whole suite passes at HEAD.

**Evidence:** `test/skills/arithmetic-eval-gate.bats:16-65`, `skills/arithmetic-eval/SKILL.md:42-85,106-194`, LOGS/cfc-skill-fixtures-r1-mutations.log (cwd scratchpad, 2026-09-24T17:05), LOGS/cfc-skill-fixtures-r1-bats.log

---

---
## Claim 6: "gate allows the harmless dunders and pandas method names SKILL.md promises"

**Location:** `test/skills/arithmetic-eval-gate.bats:129`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the test's inputs exercise. Does not establish whether pandas method names such as `df.rename` pass the gate.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Mostly accurate
**Replicate annotations:** none

```bash
# test/skills/arithmetic-eval-gate.bats:130-133
  run gate $'import numpy as np\nprint(np.__version__)\nif __name__ == "__main__":\n    pass'
  [ "$status" -eq 0 ]
  run gate $'import json\nd = json.load(open("data.json"))\nprint(d)'
```
The second case tests `json.load`, not a pandas method. SKILL.md names both (`# they'd reject json.load / df.rename`, SKILL.md:124). The name should say "json.load", or the test should add a `df.rename` case.

**Evidence:** `test/skills/arithmetic-eval-gate.bats:129-134`, `skills/arithmetic-eval/SKILL.md:124`

---

---
## Claim 7: "SKILL.md puts the no-fact-check warning (up to 5 lines) above the title, so the default 5-line window would fail a report that follows the skill." (market-sizing, moat, unit-economics, cowen, yglesias; and what-if's "3-line no-upstream-critique note … above the title")

**Location:** `test/skills/business-plan-critique-market-sizing-format.bats:26` (same comment at `business-plan-critique-moat-format.bats:23`, `business-plan-critique-unit-economics-format.bats:23`, `cowen-critique-format.bats:22`, `yglesias-critique-format.bats:22`, `what-if-analysis-format.bats:37`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the SKILL.md placement and length of each warning, and the default window of `assert_title_matches`. Does not establish that real generated reports obey the placement.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** none

Each SKILL.md says "at the top of your output". For example, `skills/cowen-critique/SKILL.md:56` reads "emit the following warning at the top of your output before the critique begins". The longest warning is market-sizing's, at 5 lines (`SKILL.md:115-119`). What-if's note is 3 lines at the top (`skills/what-if-analysis/SKILL.md:74-79`), and its Prior Art note also goes "at the top of your output" (`:97`). The default window is `local max_lines="${2:-5}"` (`test/skills/helpers.bash:127`).

**Evidence:** `skills/business-plan-critique-market-sizing/SKILL.md:112-119`, `skills/business-plan-critique-moat/SKILL.md:83-89`, `skills/business-plan-critique-unit-economics/SKILL.md:67-72`, `skills/cowen-critique/SKILL.md:56-60`, `skills/yglesias-critique/SKILL.md:61-65`, `skills/what-if-analysis/SKILL.md:74-97`, `test/skills/helpers.bash:125-131`

---

---
## Claim 8: "rubric.md defines no empty-state sentinel for this section; real rubrics write either "(None)" or a bare "None." line" (plus 04c0746: "This failure was already on answers-2026-09-20")

**Location:** `test/skills/code-review-format.bats:87-89`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rubric.md's missing sentinel, the base-branch failure, and the widened regex passing on the newest rubric. Does not establish that other empty-state spellings (such as "_None_") are accepted.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

`grep -n -i none skills/code-review/references/rubric.md` returns no lines. `code-review-rubric-2026-09-23-ans-guard-q048-q050.md` is present on `answers-2026-09-20`, and the branch changes no file under `docs/reviews/`. The base-branch version of the test fails `not ok 13 Must Fix section contains a table or (None)` at `grep -qE '(\|.*\||\(None\))'`. The HEAD version passes all 17 tests.

**Evidence:** `test/skills/code-review-format.bats:84-96`, `skills/code-review/references/rubric.md`, LOGS/cfc-skill-fixtures-r1-crf.log (cwd /workspace, 2026-09-24T17:06)

---

---
## Claim 9: "a synthetic stream-json transcript shaped like a real `claude -p --output-format stream-json --verbose` run: top-level events carry "parent_tool_use_id": null, and a sub-agent's own events carry its parent's id."

**Location:** `test/skills/eval-helpers-transcript.bats:3-6`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing about the real CLI's event shape. Does not establish that real runs emit sub-agent tool_use events in the parent stream, or that the dispatch tool is named "Agent" and not "Task".
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** none

Checking this needs a real stream-json run, which this pass may not make. The only corroboration is second-hand: commit 489a19f says "event shapes taken from a real haiku stream-json run" (paraphrased — no quote available because this is a commit-message statement with no captured transcript in the repo; no `*.transcript.jsonl` exists on disk).

**Evidence:** `test/skills/eval-helpers-transcript.bats:17-23`, commit 489a19f message

---

---
## Claim 10: "Every check runs and any failure fails the call, so the result holds under bats' `run` and in conditionals, not only under a test body's errexit."

**Location:** `test/skills/eval-helpers.bash:74-76`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loop in `eval_fixture` and every assert function it dispatches. All of them `return 1` explicitly and do not rely on errexit. Does not establish correct splitting of a check whose argument contains a single `;` (none exists today: I scanned every KEY_CHECK and found none).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

```bash
# test/skills/eval-helpers.bash:77-80,144
  local checks check failed=""
  IFS=';' read -ra checks <<< "$key_check"
  for check in "${checks[@]}"; do
    [ -n "$check" ] || continue
  ...
  [ -z "$failed" ]
```
A scratch fixture with four failing checks (severity, cites_pattern, no_pattern, unknown) printed all four messages under `run` with nonzero status. `if eval_fixture …; then false; fi` took the false branch, and a passing fixture returned 0.

**Evidence:** `test/skills/eval-helpers.bash:58-145`, LOGS/cfc-skill-fixtures-r1-evalhelpers.log (cmd `bats r1x/ef/t.bats`, cwd scratchpad, 2 ok, 2026-09-24T17:08)

---

---
## Claim 11: "only the leading word is compared" / field_values "The label may sit at the start of the line or after a list bullet"

**Location:** `test/skills/eval-helpers.bash:179-181`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `assert_severity`, `assert_no_severity`, `assert_no_verdict`, `assert_field` and `assert_no_field` via `field_values` (`:226-235`). Does not establish handling of indented continuation lines or of fields written as `**Field**:` (colon outside the bold).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** none

```bash
# test/skills/eval-helpers.bash:191
  if ! echo "$severities" | grep -qiE "^(${allowed})([^[:alpha:]]|$)"; then
# test/skills/eval-helpers.bash:234
    | sed -E -n "s/^[[:space:]]*([-*+][[:space:]]+)?\*\*${field}:\*\* //p"
```
In the scratch run, `- **Severity:** Low` was parsed from a bullet (reported "got: Low"), and `**Severity:** Critical (executed)` matched `Critical`.

**Evidence:** `test/skills/eval-helpers.bash:179-262`, LOGS/cfc-skill-fixtures-r1-evalhelpers.log

---

---
## Claim 12: "A missing transcript fails rather than skips"

**Location:** `test/skills/eval-helpers.bash:318-320`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both transcript checks. Does not establish that a *stale* transcript is detected. That is the generator's job (Claim 23).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

```bash
# test/skills/eval-helpers.bash:323-327
  local t="${REPORT_PATH%.report.md}.transcript.jsonl"
  if [ ! -f "$t" ]; then
    echo "No transcript at $t — regenerate with FIXTURE_TRANSCRIPT=1 in the runner"
    return 1
```
Both callers use `t="$(eval_transcript_path)" || { echo "$t"; return 1; }` (`:343`, `:363`). `eval-helpers-transcript.bats:61-69` passes.

**Evidence:** `test/skills/eval-helpers.bash:321-371`, LOGS/cfc-skill-fixtures-r1-bats.log

---

---
## Claim 13: "Inputs … of every tool_use block for the named tool, at any depth (sub-agents' calls included)."

**Location:** `test/skills/eval-helpers.bash:332-333`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the jq filter. It has no `parent_tool_use_id` filter, so it matches assistant events at every nesting level present in the transcript, including across a non-JSON line. Does not establish that real `claude -p` streams contain sub-agents' events at all (Claim 9 residue).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

```bash
# test/skills/eval-helpers.bash:337-339
  jq -rR --arg n "$2" \
    'fromjson? | select(.type == "assistant") | .message.content[]?
     | select(.type == "tool_use" and .name == $n) | .input | tostring' "$1"
```
"tool_called sees sub-agents' calls too" passes against the synthetic sub-agent Bash event.

**Evidence:** `test/skills/eval-helpers.bash:332-354`, `test/skills/eval-helpers-transcript.bats:48-51`, LOGS/cfc-skill-fixtures-r1-bats.log

---

---
## Claim 14: "Assert the top-level session dispatched at least N sub-agents (Agent tool_use blocks with no parent — a sub-agent's own dispatches do not count)."

**Location:** `test/skills/eval-helpers.bash:357-358`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the jq count (`parent_tool_use_id == null`, name `"Agent"`). Does not establish that the real CLI names the tool "Agent", which the matrix-analysis runner also relies on. Events that lack the key entirely also count as top-level.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "subagents_min would count an event with no parent_tool_use_id key at all as top-level" (edge; real stream-json shape unverified)

```bash
# test/skills/eval-helpers.bash:364-366
  n=$(jq -rR 'fromjson? | select(.type == "assistant" and .parent_tool_use_id == null)
       | .message.content[]? | select(.type == "tool_use" and .name == "Agent")
       | .name' "$t" | grep -c . || true)
```
The synthetic transcript has 2 top-level dispatches and 1 nested. `subagents_min 2` passes, and `subagents_min 3` fails with "found 2".

**Evidence:** `test/skills/eval-helpers.bash:357-371`, `test/skills/eval-helpers-transcript.bats:53-59`, LOGS/cfc-skill-fixtures-r1-bats.log

---

---
## Claim 15: "Fixture filenames describe the planted defect or the expected verdict … The model must never see them"

**Location:** `test/skills/generate-reports.bash:30-32`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers every channel the harness controls: the prompt on stdin (`subject.<ext>` or `.`), the argv, the cwd (a `mktemp -d` path in repo/tree mode), the temp repo's file tree and git metadata (author "fixture", message "fixture"), REQUEST.md and `.fixture-*` handling, and fixture bodies (no `tc-…` token or HTML comment in any fixture file). Does not establish what Claude Code itself injects in inline mode, where claude runs in the caller's cwd (usually the real repo) and any environment/git-status context it adds under `--system-prompt-file` could carry commit subjects that name fixtures; I cannot run claude to check.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: "a future fixture with a dot but no extension (e.g. tc-4.2-foo, or the header's own example tc-2.4-inaccurate) leaks the label into subject.<ext>; none exists today"

```bash
# test/skills/generate-reports.bash:147-155
  local subject_name="subject"
  if [ "$FIXTURE_MODE" = "tree" ]; then
    subject_name="."
  elif [[ "$fixture_name" == *.* ]]; then
    subject_name="subject.${fixture_name##*.}"
  fi
  local prompt
  prompt="$(fixture_prompt "$subject_name")"
```
The stub-claude tests ("the fixture's descriptive filename never reaches the model" for repo mode, and "tree mode: the fixture directory's name never reaches the model") grep the recorded argv, cwd, file list and stdin, and both pass. The self-eval REQUEST.md files name only synthetic skills. `grep -rnE '<!--|\btc-[a-z]*[0-9]' test/skills/*/fixtures` returns nothing.

**Evidence:** `test/skills/generate-reports.bash:130-213`, `test/generate-reports.bats:93-104,206-211`, LOGS/cfc-skill-fixtures-r1-bats.log

---

---
## Claim 16: "in "repo" mode the fixture is copied in as subject.<ext>, and that neutral name is what fixture_prompt receives in both modes."

**Location:** `test/skills/generate-reports.bash:32-33`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "both modes" wording. Does not affect the tree-mode paragraph at `:45-46`, which states the tree case correctly.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Stale
**Replicate annotations:** none

This line dates from 4f91e29, when there were two modes. 2e98d3c added a third, and in it `fixture_prompt` receives `"."`, not `subject.<ext>` (`subject_name="."`, `generate-reports.bash:149`). It should say "in inline and repo modes" or "in every mode but tree".

**Evidence:** `test/skills/generate-reports.bash:32-33,45-46,147-152`, commits 4f91e29 and 2e98d3c

---

---
## Claim 17: "REQUEST.md, if present, is appended to the prompt and not copied." / "top-level files named .fixture-* are control markers … removed before the model runs"

**Location:** `test/skills/generate-reports.bash:42-44`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree-mode copy/append/remove sequence. Does not establish handling of a REQUEST.md or `.fixture-*` below the top level (neither is touched).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** none

```bash
# test/skills/generate-reports.bash:180-185
      cp -R "$fixture_path"/. "$temp_dir"/
      if [ -f "$temp_dir/REQUEST.md" ]; then
        prompt="$prompt"$'\n\n'"$(cat "$temp_dir/REQUEST.md")"
        rm "$temp_dir/REQUEST.md"
      fi
      rm -rf "$temp_dir"/.fixture-*
```
REQUEST.md *is* copied, then deleted before `git add`/the claude run. Directory markers are removed as well (`rm -rf`), and self-eval relies on that for `.fixture-tests/`. So the markers are not only "files". The end state (neither the file nor the marker names reach the model) is confirmed by the passing tree-mode tests. The precise wording is: "copied, then removed before commit; appended to the prompt", and "top-level entries (files or directories)".

**Evidence:** `test/skills/generate-reports.bash:176-188`, `test/skills/self-eval/runner.bash:25-32`, `test/generate-reports.bats:193-221`, LOGS/cfc-skill-fixtures-r1-bats.log

---

---
## Claim 18: "Cheat prevention: the tool allowlist never includes Write"

**Location:** `test/skills/generate-reports.bash:48`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the FIXTURE_TOOLS value of all 22 committed runners. None includes Write, Edit, MultiEdit, NotebookEdit or Bash. The values are `none` (12), `Read,Grep,Glob` (8), `WebSearch,WebFetch` (1) and `Agent` (1). Does not establish enforcement against future runners (Claim 18), or that `CLAUDE_FLAGS`, which is appended after `--tools`, cannot add tools.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:** none

(paraphrased — no quote available because the claim covers 22 files; each runner's value is listed in the guard log)

**Evidence:** `test/skills/*/runner.bash`, LOGS/cfc-skill-fixtures-r1-guard.log (cwd /workspace, exit 0, 2026-09-24T17:08)

---

---
## Claim 19: "in "repo" mode the working directory holds only the fixture, so the model cannot reach expected-verdicts.bash or eval-criteria.md."

**Location:** `test/skills/generate-reports.bash:48-50`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the cwd contents, which hold only `subject.<ext>` plus `.git` (bats "repo mode" test). Does not establish that Read/Grep/Glob are confined to the cwd. The harness passes no directory restriction, and whether headless `claude -p` denies absolute-path reads outside the cwd (such as `/workspace/test/skills/<skill>/expected-verdicts.bash`) is CLI behavior I cannot run. The same residue applies to tree mode (self-eval, divergent-design), which the sentence does not mention.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable (compound)
**Replicate annotations:** r3 split: "working directory holds only the fixture" Verified; "cannot reach expected-verdicts" Unverifiable (absolute-path Read not probed)

(paraphrased — no quote available because the claim's load-bearing half concerns claude CLI permission behavior, not code in this repo) The conclusion "cannot reach" follows from "cwd holds only the fixture" only if the tools are cwd-bound. Checking that needs a claude run that tries an absolute-path Read.

**Evidence:** `test/skills/generate-reports.bash:167-201`, `test/generate-reports.bats:80-91`

---

---
## Claim 20: ""inline" skills should omit Read."

**Location:** `test/skills/generate-reports.bash:50`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 14 inline runners. None includes Read (12 `none`, fact-check `WebSearch,WebFetch`, matrix-analysis `Agent`). Does not establish what matrix-analysis's sub-agents can use (Claim 26).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

(paraphrased — no quote available because the claim spans 14 runner files; values listed in the guard log)

**Evidence:** `test/skills/generate-reports.bash:89-94`, LOGS/cfc-skill-fixtures-r1-guard.log

---

---
## Claim 21: guard "FIXTURE_TOOLS must not include Write or Edit" / commit bf172c5 "Runners granting Write/Edit are refused."

**Location:** `test/skills/generate-reports.bash:89-94`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the guard's string matching. It rejects only an exact `Write` or `Edit` token between commas. It does not establish how the CLI parses the spellings that slip through, which is why confidence is Medium.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Incorrect · r3=Mostly accurate
**Replicate annotations:** r1: "accepts `Read, Write`, `Write(*)`, `write`, MultiEdit, NotebookEdit, Bash" · r3: "CLAUDE_FLAGS is appended unvalidated" · all: no committed runner uses such a form today

```bash
# test/skills/generate-reports.bash:89-94
case ",$FIXTURE_TOOLS," in
  *,Write,*|*,Edit,*)
    echo "Error: $RUNNER_FILE: FIXTURE_TOOLS must not include Write or Edit" >&2
    exit 1
    ;;
esac
```

Executed: I applied the same `case` to candidate values. It rejected `Read,Write`, `Edit` and `Read,Edit,Glob`. It accepted `Read, Write` (space after the comma), `Write(*)`, `Read,write`, `Read,NotebookEdit`, `MultiEdit` and `Bash`. NotebookEdit and Bash can write files, and the CLI help lists tool names in the form `"Bash,Edit,Read"`. So as an enforcement mechanism, "runners granting Write/Edit are refused" holds only for the exact comma-delimited spelling. Only that spelling is tested (`test/generate-reports.bats:257-263`, `"Read,Write"`). No committed runner currently uses a slipping form (Claim 17a).

**Evidence:** `test/skills/generate-reports.bash:89-94`, `test/generate-reports.bats:257-263`

---

_(Evidence carried from replicate r2's claim 18.)_

---
## Claim 22: "--strict-mcp-config on every run"

**Location:** `test/skills/generate-reports.bash:117`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the flag being present in the built argv in inline, repo and tree modes, with and without transcript mode. Does not establish its effect (Claim 19b).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

```bash
# test/skills/generate-reports.bash:159
  local -a claude_args=(-p --system-prompt-file "$SKILL_FILE" --strict-mcp-config)
```
Both invocation branches (`:198`, `:209`) expand `"${claude_args[@]}"`. The bats test "every mode passes --strict-mcp-config" passes.

**Evidence:** `test/skills/generate-reports.bash:157-213`, `test/generate-reports.bats:106-117`, LOGS/cfc-skill-fixtures-r1-bats.log

---

---
## Claim 23: "without it the account's claude.ai MCP connectors (e.g. Claude Docs create/update/delete) are exposed even under --tools "", in sub-agents too" (and ef05331: "Verified by a headless probe: the tool list drops from Read + 8 mcp__claude_ai_Claude_Docs__* to Read.")

**Location:** `test/skills/generate-reports.bash:117-121`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing I could execute. Checking it needs claude runs with and without the flag. Does not establish that `--strict-mcp-config` also strips connectors inside sub-agents, which is the case matrix-analysis (`--tools Agent`) depends on.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** r3: "the only recorded probe used --tools Read, not --tools \"\""

Blocker: this pass may not run `claude`. Second-hand corroboration is research-skill-fixtures-batch4.md:31, tagged [observed] (paraphrased — no quote available because the source is a working-doc note describing a probe whose output is not captured in the repo). The note says the connector appeared "in every fixture run, even `FIXTURE_TOOLS="none"`, and in sub-agents" and that the flag removes it. It does not say the flag-on probe covered a sub-agent.

**Evidence:** `test/skills/generate-reports.bash:117-121`, `docs/working/research-skill-fixtures-batch4.md:31`, `docs/working/checkpoint-skill-fixtures-batch4.md:14`, commit ef05331 message

---

---
## Claim 24: "claude -p reads --tools "" as "no tools"."

**Location:** `test/skills/generate-reports.bash:123-124`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the harness side: `none` becomes the empty string, which is passed as its own argv element (bats "FIXTURE_TOOLS=none passes an empty --tools list" passes). Does not establish the CLI's reading of the empty value.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** none

```bash
# test/skills/generate-reports.bash:125-126
TOOLS_ARG="$FIXTURE_TOOLS"
[ "$FIXTURE_TOOLS" = "none" ] && TOOLS_ARG=""
```
The CLI half needs a claude run (blocked). docs/decisions/log.md row 37 records `scripts/lite-review.py` using `--tools ""` in production (paraphrased — no quote available because the row is a long table cell; it lists `--tools ""` among lite-review's flags).

**Evidence:** `test/skills/generate-reports.bash:123-126,165`, `test/generate-reports.bats:69-78`, `docs/decisions/log.md:59`

---

---
## Claim 25: "A stale transcript must never pair with a fresh report."

**Location:** `test/skills/generate-reports.bash:136-137`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every path through `generate_one`. `rm -f "$transcript_path"` runs first. In transcript mode, claude's stdout is redirected to the transcript (truncated even if claude fails) and the report is always rewritten by jq or `: >`. In non-transcript mode, the transcript stays deleted. Does not establish the converse: if `generate_one` aborts under `set -e` after the `rm` (for example a failing `fixture_prompt`, `cp` or `git`), the *previous* report survives with no transcript. Eval then reads a stale report, and transcript checks fail on the missing sidecar.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

```bash
# test/skills/generate-reports.bash:220-221
    jq -rR 'fromjson? | select(.type == "result") | .result // empty' "$transcript_path" \
      > "$report_path" 2>/dev/null || : > "$report_path"
```
The bats test "transcript off: … a stale sidecar is removed" passes. With a missing transcript file, the jq-or-truncate line yields a 0-byte report.

**Evidence:** `test/skills/generate-reports.bash:130-233`, `test/generate-reports.bats:148-158`, LOGS/cfc-skill-fixtures-r1-jq.log (2026-09-24T17:05-17:07), LOGS/cfc-skill-fixtures-r1-bats.log

---

---
## Claim 26: "--tools is the last argument, so an empty value leaves "--tools " at the end of the recorded argv line."

**Location:** `test/generate-reports.bats:74-76`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the argv built when `CLAUDE_MODEL` and `CLAUDE_FLAGS` are unset (the test's environment); does not establish the ordering claim when either is set — then `$model_flag`/`${CLAUDE_FLAGS}` follow `--tools` and the test would fail (see Claim 23).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** none

`claude_args+=(--tools "$TOOLS_ARG")` (`test/skills/generate-reports.bash:165`) is the last array append, and the call is `claude "${claude_args[@]}" $model_flag ${CLAUDE_FLAGS:-}` (`:209-211`). `bats test/generate-reports.bats` → 19/19 ok, exit 0, 2026-09-25T00:03Z.

**Evidence:** `test/skills/generate-reports.bash:159-165`, `test/skills/generate-reports.bash:208-212`, `$LOG/generate-reports.txt`

---

_(Evidence carried from replicate r3's claim 3.)_

---
## Claim 27: "an empty value must not swallow the next flag" (also `test/generate-reports.bats:126`: "--tools must stay last so an empty list cannot swallow a flag")

**Location:** `test/skills/generate-reports.bash:157-158`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the protective mechanism the ordering claims. Does not establish whether claude's parser can in fact consume a flag after an empty `--tools` value; I cannot run claude.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Unverifiable
**Replicate annotations:** none

The flags that follow `--tools ""` are the model and extra flags themselves:
```bash
# test/skills/generate-reports.bash:198-200
      | claude "${claude_args[@]}" \
        $model_flag \
        ${CLAUDE_FLAGS:-} \
```
Whenever `CLAUDE_MODEL` or `CLAUDE_FLAGS` is set, `--model …` is "the next flag" after the empty value. So if an empty value could swallow the next flag, this ordering hands it `--model`. The ordering protects only `--output-format`/`--verbose`, and only by keeping them *before* `--tools`. It does not make the next flag safe. Also, `""` is a separate argv element (`claude_args+=(--tools "$TOOLS_ARG")`), so the empty value is present as an explicit argument. The bats test only checks the no-CLAUDE_MODEL case, where nothing follows. The comment should either state the real invariant ("the stream-json flags precede --tools") or put the model/extra flags before `--tools` too.

**Evidence:** `test/skills/generate-reports.bash:141-144,157-165,195-212`, `test/generate-reports.bats:69-78,119-132`

---

---
## Claim 28: "-R + fromjson? parses line by line and skips non-JSON lines (a stray warning on stdout), which would otherwise abort jq and lose the report." (and d700f62: "Test-first: new cases … failed before the change and pass after.")

**Location:** `test/skills/generate-reports.bash:218-219`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers non-JSON lines and valid-but-non-object JSON lines (`42`, `[1]`); both are skipped and the result text survives. Covers the same filter in eval-helpers (`:336`, `:364`). Does not establish handling of a result event split across lines, which stream-json does not produce by design and I could not observe.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

I ran jq on `Warning: stray` followed by `{"type":"result","result":"R"}`. With `-rR 'fromjson? | …'` it printed `R` and exited 0. Without `-R` it printed `parse error: Invalid numeric literal at line 1, column 8` and exited 4. That confirms the "would otherwise abort" half. The d700f62 tests, run against the pre-fix generator and eval-helpers (`d700f62^`), fail both ("not ok … a non-JSON line in the stream does not lose the report" and "not ok … does not blind the checks"). They pass at HEAD.

**Evidence:** `test/skills/generate-reports.bash:215-222`, LOGS/cfc-skill-fixtures-r1-jq.log (cwd scratchpad, 2026-09-24T17:05), LOGS/cfc-skill-fixtures-r1-testfirst.log (2026-09-24T17:06)

---

---
## Claim 29: "A run that died before emitting one leaves an empty report (warned below)."

**Location:** `test/skills/generate-reports.bash:216-217`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a transcript with no `result` event, and a missing or unreadable transcript. Does not establish the case where the result event is present with `is_error: true`: that error text becomes a non-empty "report" and is *not* warned.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

jq on a transcript with no result event exits 0 with 0 bytes, and on a missing file the `|| : >` fallback gives 0 bytes. An empty report then reaches `echo "  WARNING: empty report generated"` (`:231`) via `if [ -s "$report_path" ]` (`:224`).

**Evidence:** `test/skills/generate-reports.bash:215-232`, LOGS/cfc-skill-fixtures-r1-jq.log

---

---
## Claim 30: "tree fixtures are directories; the other modes take files." (and 2e98d3c: "a mixed dir cannot feed the wrong mode")

**Location:** `test/skills/generate-reports.bash:238`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers fixture selection in the main loop. Does not establish the treatment of symlinks (`-d`/`-f` follow them).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

```bash
# test/skills/generate-reports.bash:239-243
  if [ "$FIXTURE_MODE" = "tree" ]; then
    [ -d "$f" ] || continue
  else
    [ -f "$f" ] || continue
  fi
```
The bats test "tree mode takes directories only; repo mode takes files only" passes.

**Evidence:** `test/skills/generate-reports.bash:235-248`, `test/generate-reports.bats:223-236`, LOGS/cfc-skill-fixtures-r1-bats.log

---

---
## Claim 31: "Sub-agents inherit the same tool list, so they cannot read the repo either"

**Location:** `test/skills/matrix-analysis/runner.bash:5`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing I could execute. Does not establish that a sub-agent type with its own tool list (such as general-purpose) is also restricted, or that MCP connectors are absent inside sub-agents (Claim 19b).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** r2: "most important open question: matrix-analysis is the only inline runner granting a tool (Agent) and runs in the real repo"

Blocker: this needs a claude run with `--tools Agent`. Second-hand, research-skill-fixtures-batch4.md:30, tagged [observed], says a sub-agent "had Agent and Read, no Write, and failed to create a canary file" (paraphrased — no quote available because the probe's transcript is not in the repo). That probe granted Agent+Read, not Agent alone, so it does not directly show the Read-less case.

**Evidence:** `test/skills/matrix-analysis/runner.bash:1-15`, `docs/working/research-skill-fixtures-batch4.md:29-30`

---

---
## Claim 32: "They are stored renamed so scripts/run-tests.sh, which collects every *.bats under test/, never runs them as real suites."

**Location:** `test/skills/self-eval/runner.bash:11-13`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers run-tests.sh's collection glob and the stored names (`*.bats.in` under `.fixture-tests/`). Does not establish that no other tool (such as shellcheck in health-check) scans `.bats.in` files.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

```bash
# scripts/run-tests.sh:63
  done < <(find "$TEST_DIR" -name '*.bats' -print0 | sort -z)
```
`-name '*.bats'` does not match `migration-safety-check-format.bats.in`. The full fast run (Claim 31) shows none of those names.

**Evidence:** `scripts/run-tests.sh:43-63`, `test/skills/self-eval/fixtures/tc-se2-duplicates-migration-review/.fixture-tests/skills/migration-safety-check-format.bats.in`, LOGS/cfc-skill-fixtures-r1-runtests-fast.log

---

---
## Claim 33: ef05331 "Affects batches 1-3 as well (no reports were generated with the leak)."

**Location:** commit ef05331 message
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers this checkout only, which has no `test/skills/*/output/` directory at all (gitignored). Does not establish what was generated on other machines or worktrees.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** none

(paraphrased — no quote available because the claim is about absence of generated artifacts; `ls test/skills/*/output` finds no match here) Checking it needs the outputs or run logs of the machine that ran batches 1-3.

**Evidence:** `.gitignore:5`, commit ef05331

---

---
## Claim 34: 489a19f "A stale sidecar is deleted before each run." / "a missing transcript fails rather than skips … the failure says to set FIXTURE_TRANSCRIPT=1."

**Location:** commit 489a19f message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claims 12 and 21. Does not cover the "event shapes taken from a real haiku stream-json run" sentence (Claim 9).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

The code is `rm -f "$transcript_path"` (`generate-reports.bash:137`), and the failure message is `"No transcript at $t — regenerate with FIXTURE_TRANSCRIPT=1 in the runner"` (`eval-helpers.bash:325`). Both are covered by passing tests.

**Evidence:** `test/skills/generate-reports.bash:136-137`, `test/skills/eval-helpers.bash:323-327`, LOGS/cfc-skill-fixtures-r1-bats.log

---

---
## Claim 35: 2e98d3c "Top-level .fixture-* markers steer fixture_base and are removed before the model runs. The directory name never reaches the model; fixture_prompt receives "."."

**Location:** commit 2e98d3c message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stub-observed argv, stdin, cwd and file tree. Carries Claim 15a's residue about CLI-injected context. Also, a marker's name reaches the model only if fixture_base copies it under another name, which no runner does.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** none

`fixture_base` runs before the copy and reads markers from the source fixture dir (`[ -e "$fx/.fixture-no-rubric" ]`, self-eval `runner.bash:24`). The markers are then removed from the temp dir (`rm -rf "$temp_dir"/.fixture-*`). The tree-mode bats tests pass.

**Evidence:** `test/skills/generate-reports.bash:176-185`, `test/skills/self-eval/runner.bash:20-33`, `test/generate-reports.bats:193-221`, LOGS/cfc-skill-fixtures-r1-bats.log

---

---
## Claim 36: fa3c5c0 "run-tests.sh --fast: 939 ok, 0 failures. health-check.bats: green."

**Location:** commit fa3c5c0 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HEAD (04c0746): 941 ok, 0 `not ok`. The +2 matches the two fast tests d700f62 added after fa3c5c0. Does not re-run the count at fa3c5c0 itself.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

The `scripts/run-tests.sh --fast` run at HEAD reports 941 `ok` lines and no `not ok`.

**Evidence:** LOGS/cfc-skill-fixtures-r1-runtests-fast.log (cmd `scripts/run-tests.sh --fast`, cwd /workspace, 2026-09-24T17:09; exit status not captured by the log's PIPESTATUS line, 0 failures in output), LOGS/cfc-skill-fixtures-r1-bats.log

---

---
## Claim 37: "the fixture's descriptive filename never reaches the model … The report is still keyed by the real fixture name, for the eval suite."

**Location:** `test/generate-reports.bats:93-104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers repo mode with a `.py` fixture. Does not cover inline-mode CLI context (Claim 15a residue).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

```bash
# test/generate-reports.bats:100-103
  [[ "$call" != *"sql-injection"* ]]
  [[ "$call" == *"LS: subject.py"* ]]
  # The report is still keyed by the real fixture name, for the eval suite.
  [ -f "$TEST_TMPDIR/test/skills/demo/output/tc-9-sql-injection.py.report.md" ]
```
The test passes. The report path is `$OUTPUT_DIR/${fixture_name}.report.md` (`generate-reports.bash:134`).

**Evidence:** `test/generate-reports.bats:93-104`, `test/skills/generate-reports.bash:134`, LOGS/cfc-skill-fixtures-r1-bats.log

---

---
## Claim 38: 04c0746 "the test only accepted "(None)" … widened the test rather than editing the rubric artifact"

**Location:** commit 04c0746 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the base regex, the new regex, and that no rubric artifact changed on the branch. Does not establish the "newest rubric by glob order" selection logic in helpers.bash's `latest_rubric`, which I did not read.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** none

The base regex is `'(\|.*\||\(None\))'`. HEAD's is `'(\|.*\||\(None\)|^None\.$)'`. `git diff --name-only answers-2026-09-20...skill-fixtures -- docs/reviews/` is empty.

**Evidence:** `test/skills/code-review-format.bats:84-96`, LOGS/cfc-skill-fixtures-r1-crf.log

---

---
## Claim 39: "Inline mode runs claude in the real repo, where Read could reach expected-verdicts.bash" (repeated across the inline runners)

**Location:** `test/skills/cowen-critique/runner.bash:2-3` (same wording in the ai-personas, business-plan-critique-*, dependency-upgrade, design-space-situating, matrix-analysis, pre-mortem, tech-debt-triage, what-if-analysis and yglesias runners)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the generator runs inline-mode claude. It does not establish what a Read tool could reach from there, since no inline runner grants Read.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none

Inline mode never changes directory: claude runs in whatever directory the caller invoked the script from.

```bash
# test/skills/generate-reports.bash:208-212
    printf '%s\n\n%s' "$prompt" "$fixture_content" \
      | claude "${claude_args[@]}" \
        $model_flag \
        ${CLAUDE_FLAGS:-} \
      > "$out_path" 2>/dev/null || true
```

With the documented usage (`./generate-reports.bash ...` from `test/skills/`, `generate-reports.bash:5-8`), that directory is inside the real repo, so the conclusion holds. The precise version: "inline mode runs claude in the caller's working directory, normally inside the real repo".

**Evidence:** `test/skills/generate-reports.bash:5-8,202-213`

---

_(Evidence carried from replicate r2's claim 8.)_

---
## Claim 40: "Args: $1 = skill name (fact-check or code-fact-check)" and format_check "Delegate to the format BATS suite (fact-check-format.bats or code-fact-check-format.bats)"

**Location:** `test/skills/eval-helpers.bash:7`, `test/skills/eval-helpers.bash:135`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers these two comments in the file whose header this branch rewrote; does not establish anything about behaviour (both functions are skill-generic).
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=— · r3=Stale · single-replicate detection
**Replicate annotations:** none

The branch changed the file header to "every skill with a fixture set" (`:1-2`), and the code is generic: `verdicts_file="${BATS_TEST_DIRNAME}/${skill}/expected-verdicts.bash"` (`:10`), `bats "${BATS_TEST_DIRNAME}/${skill}-format.bats"` (`:136`). format_check is now used by other skills too (commit 83c9681 "run format_check on matrix-analysis tc-ma3 too"). Both parentheticals should say "any skill".

**Evidence:** `test/skills/eval-helpers.bash:1-18`, `test/skills/eval-helpers.bash:134-137`, commit 83c9681

---

_(Evidence carried from replicate r3's claim 11.)_

---
## Claim 41: "Keep the extension (it tells the model the language); drop the name."

**Location:** `test/skills/generate-reports.bash:146`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every committed fixture name (none are affected today); does not hold for a dotted name with no real extension, where the "extension" is part of the descriptive name.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection
**Replicate annotations:** none

`${fixture_name##*.}` takes everything after the last dot. Probe (2026-09-25T00:10Z): `tc-2.4-inaccurate -> subject.4-inaccurate`, `tc-c2.4-incorrect.js -> subject.js`, `tc-sec1-sql-injection.py -> subject.py`. The header's own usage example (`:6`) uses `tc-2.4-inaccurate`. A survey of all committed fixtures by mode found no name that yields a non-language suffix (the only non-common suffix is `tc-uv8-unity-layout.cs -> subject.cs`), so this is latent. A precise version: "keep a trailing extension; a dotted id with no extension leaks its suffix".

**Evidence:** `test/skills/generate-reports.bash:6`, `test/skills/generate-reports.bash:146-152`, `$LOG/subject-name.txt`

---

_(Evidence carried from replicate r3's claim 17.)_

---
## Claim 42: "the fixture sits alone in a throwaway repo (no git history, so no branch diff to scope to)"

**Location:** `test/skills/security-reviewer/runner.bash:2-3`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the temp repo's history; the "no branch diff" conclusion holds.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection
**Replicate annotations:** none

The repo has one commit: `commit -q -m "fixture" --allow-empty` (`test/skills/generate-reports.bash:192-193`). Precise version: "a single-commit history, so no branch diff". (self-eval's runner states this correctly: "a single commit named "fixture"".)

**Evidence:** `test/skills/security-reviewer/runner.bash:2-4`, `test/skills/generate-reports.bash:189-193`, `test/skills/self-eval/runner.bash:37`

---

_(Evidence carried from replicate r3's claim 27.)_

---
## Claim 43: "Generated eval reports (model-dependent, not committed)" → `test/skills/*/output/`

**Location:** `.gitignore:4-5`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that report and transcript files under any `test/skills/<skill>/output/` are ignored and none are tracked; does not establish anything about output written elsewhere (e.g. a runner writing into the temp repo).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

`.gitignore:5` reads `test/skills/*/output/`. `git check-ignore -v test/skills/matrix-analysis/output/tc-ma1.md.transcript.jsonl test/skills/self-eval/output/x.report.md` matched both against `.gitignore:5`, and `git ls-files 'test/skills/*/output/*' | wc -l` printed `0`. Command run 2026-09-25T00:10Z, cwd /workspace, exit 0 (paraphrased — no quote available because the output was two check-ignore lines and a count, reproduced here in full rather than captured to a file).

**Evidence:** `.gitignore:4-5`

---

_(Evidence carried from replicate r3's claim 1.)_

---
## Claim 44: "the three Mode 2 heredoc delimiters are distinct and no body line equals one"

**Location:** `test/skills/arithmetic-eval-gate.bats:57-65`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three AE_* delimiters across the whole SKILL.md (a body line equal to any of the three would raise that delimiter's bare-line count above 1); does not cover the Mode 1 `EXPREOF` delimiter.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

```bash
# test/skills/arithmetic-eval-gate.bats:61-64
  for d in AE_SCRIPT_EOF AE_CHECK_EOF AE_CONFINE_EOF; do
    [ "$(grep -c "<<'$d'\$" "$SKILL")" -eq 1 ] || …
    [ "$(grep -cx "$d" "$SKILL")" -eq 1 ] || …
```

SKILL.md has each opener once (`:102`, `:106`, `:196`) and each bare line once (`:104`, `:194`, `:261`); test ok in the run above.

**Evidence:** `test/skills/arithmetic-eval-gate.bats:57-65`, `skills/arithmetic-eval/SKILL.md:102-261`, `$LOG/arithmetic-eval-gate.txt`

---

_(Evidence carried from replicate r3's claim 7.)_

---
## Claim 45: bf172c5: "The two existing skills' prompts and tool lists move into runners unchanged."

**Location:** commit bf172c5
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the prompt text and tool strings; does not cover the subject filename, which 4f91e29 later changed deliberately (subject.<ext>).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

Base `answers-2026-09-20:test/skills/generate-reports.bash:42` `ALLOWED_TOOLS="Read,Grep,Glob"`, `:44` `ALLOWED_TOOLS="WebSearch,WebFetch"`, `:77` `"Code fact-check the file ${fixture_name}. Check all claims in comments and docstrings against actual code behavior. Scope: ${fixture_name}"`, `:93` `"Fact-check the following draft:"` match `test/skills/code-fact-check/runner.bash:4,9` and `test/skills/fact-check/runner.bash:4,8` verbatim apart from the variable name.

**Evidence:** `answers-2026-09-20:test/skills/generate-reports.bash:42-96`, `test/skills/code-fact-check/runner.bash:1-10`, `test/skills/fact-check/runner.bash:1-9`

---

_(Evidence carried from replicate r3's claim 29.)_

---
## Claims Requiring Attention

### Incorrect
- Claim 2: "every committed fixture set has a runner the generator accepts"
- Claim 21: guard "FIXTURE_TOOLS must not include Write or Edit" / commit bf172c5 "Runners granting Write/Edit are refused."
- Claim 27: "an empty value must not swallow the next flag" (also `test/generate-reports.bats:126`: "--tools must stay last so an empty list cannot swallow a flag")

### Stale
- Claim 16: "in "repo" mode the fixture is copied in as subject.<ext>, and that neutral name is what fixture_prompt receives in both modes."
- Claim 40: "Args: $1 = skill name (fact-check or code-fact-check)" and format_check "Delegate to the format BATS suite (fact-check-format.bats or code-fact-check-format.bats)"

### Mostly Accurate
- Claim 3: "SKILL.md puts the no-fact-check warning (up to 5 lines) above the title" (ai-personas-critique)
- Claim 6: "gate allows the harmless dunders and pandas method names SKILL.md promises"
- Claim 17: "REQUEST.md, if present, is appended to the prompt and not copied." / "top-level files named .fixture-* are control markers … removed before the model runs"
- Claim 18: "Cheat prevention: the tool allowlist never includes Write"
- Claim 26: "--tools is the last argument, so an empty value leaves "--tools " at the end of the recorded argv line."
- Claim 39: "Inline mode runs claude in the real repo, where Read could reach expected-verdicts.bash" (repeated across the inline runners)
- Claim 41: "Keep the extension (it tells the model the language); drop the name."
- Claim 42: "the fixture sits alone in a throwaway repo (no git history, so no branch diff to scope to)"

### Unverifiable
- Claim 9: "a synthetic stream-json transcript shaped like a real `claude -p --output-format stream-json --verbose` run: top-level events carry "parent_tool_use_id": null, and a sub-agent's own events carry its 
- Claim 19: "in "repo" mode the working directory holds only the fixture, so the model cannot reach expected-verdicts.bash or eval-criteria.md."
- Claim 23: "without it the account's claude.ai MCP connectors (e.g. Claude Docs create/update/delete) are exposed even under --tools "", in sub-agents too" (and ef05331: "Verified by a headless probe: the tool l
- Claim 24: "claude -p reads --tools "" as "no tools"."
- Claim 31: "Sub-agents inherit the same tool list, so they cannot read the repo either"
- Claim 33: ef05331 "Affects batches 1-3 as well (no reports were generated with the leak)."

## Escalations

- `test/skills/matrix-analysis/runner.bash:5-6` — inline mode + `Agent` tool, runs in the real repo; whether sub-agents inherit `--tools` is unverified (r1, r2, r3) → addressee: security-reviewer
- `test/skills/generate-reports.bash:89-94` — Write/Edit guard is exact-token; Bash/NotebookEdit/MultiEdit/`Write(*)`/spaced forms pass; `CLAUDE_FLAGS` unvalidated (r1, r2, r3) → addressee: security-reviewer
- repo/tree mode absolute-path reads of `expected-verdicts.bash` not probed (r1, r2, r3) → addressee: security-reviewer
- `test/skills/generate-reports.bash:146` dotted-name-without-extension leak (r2, r3) → addressee: security-reviewer
- `test/generate-reports.bats:74-76` empty-`--tools` test fails with `CLAUDE_MODEL` exported (r2) → addressee: test-strategy (not dispatched) / orchestrator

## Verdict stability

- Clusters: 45
- All reporting replicates agreed: 40
- Disagreed: 5
  - Claim 17: r1=Mostly accurate · r2=Mostly accurate · r3=Verified
  - Claim 18: r1=Verified · r2=Verified · r3=Mostly accurate
  - Claim 21: r1=Mostly accurate · r2=Incorrect · r3=Mostly accurate
  - Claim 26: r1=Verified · r2=Mostly accurate · r3=Verified
  - Claim 27: r1=Incorrect · r2=Incorrect · r3=Unverifiable
- Agreement rate: 89%

## Goal-Alignment Note
- Success criterion (restated verbatim): merged most-severe-wins report of the three replicates, canonical for this run.
- Answered: yes
- Out of scope: pass 2 (fixture data)
- Escalate: see ## Escalations
