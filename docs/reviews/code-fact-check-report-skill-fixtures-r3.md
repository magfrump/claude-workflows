# Code Fact-Check Report

Commit: 04c0746

**Repository:** /workspace (claude-workflows)
**Scope:** pass-1 harness diff `answers-2026-09-20...skill-fixtures` (head 04c0746), restricted to the 40 files listed in the brief (generate-reports.bash, eval-helpers.bash, their bats suites, arithmetic-eval-gate.bats, health-check.sh + bats, .gitignore, the 22 in-scope runner.bash files and the changed *-format.bats files), plus the commit messages of commits touching them.
**Checked:** 2026-09-24
**Total claims checked:** 39
**Summary:** 24 verified, 5 mostly accurate, 2 stale, 1 incorrect, 7 unverifiable

Execution provenance note: the reviewer was forbidden to write repo files other than this report, so captured outputs live outside the repo under `LOG=/tmp/claude-1000/-workspace/486d17ef-98de-46e2-88d8-3db5f5c05a49/scratchpad/cfc-logs/` (not `docs/reviews/execution-logs/`). All executed runs used cwd `/workspace` unless stated. `claude` was never run; generate-reports.bash was run only against stubbed `claude` binaries in scratch trees. Hallucination-pattern log read; the only matching pattern family is "test-count claims in commit messages" (entry at `docs/reviews/hallucination-patterns.md:28`), checked under Claim 33.

---

## Claim 1: "Generated eval reports (model-dependent, not committed)" → `test/skills/*/output/`

**Location:** `.gitignore:4-5`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that report and transcript files under any `test/skills/<skill>/output/` are ignored and none are tracked; does not establish anything about output written elsewhere (e.g. a runner writing into the temp repo).
**Legibility-target:** for-orchestrator-synthesis

`.gitignore:5` reads `test/skills/*/output/`. `git check-ignore -v test/skills/matrix-analysis/output/tc-ma1.md.transcript.jsonl test/skills/self-eval/output/x.report.md` matched both against `.gitignore:5`, and `git ls-files 'test/skills/*/output/*' | wc -l` printed `0`. Command run 2026-09-25T00:10Z, cwd /workspace, exit 0 (paraphrased — no quote available because the output was two check-ignore lines and a count, reproduced here in full rather than captured to a file).

**Evidence:** `.gitignore:4-5`

---

## Claim 2: "A fixture is a file, or a directory for tree-mode runners (… self-eval, divergent-design)" — and the check now accepts them

**Location:** `scripts/health-check.sh:314-317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both loops of `check_fixture_verdicts` (forward `-f || -d`, reverse `-e`) for the self-eval and divergent-design sets; does not establish behaviour for symlinked or special-file fixtures (the reverse loop's `-e` would accept a FIFO or dangling-free symlink the forward loop skips).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/health-check.sh:316-317
        for fixture in "$skill_dir"/fixtures/*; do
            [[ -f "$fixture" || -d "$fixture" ]] || continue
# scripts/health-check.sh:333
            if [[ ! -e "$skill_dir/fixtures/$key" ]]; then
```

`bats test/scripts/health-check.bats` → `1..18`, all ok, including `ok 7 directory (tree-mode) fixture sets pass the fixture ↔ verdict check`; exit 0, 2026-09-25T00:06Z.

**Evidence:** `scripts/health-check.sh:314-333`, `test/scripts/health-check.bats:80-85`, `$LOG/health-check-bats.txt`

---

## Claim 3: "--tools is the last argument, so an empty value leaves "--tools " at the end of the recorded argv line."

**Location:** `test/generate-reports.bats:74-76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the argv built when `CLAUDE_MODEL` and `CLAUDE_FLAGS` are unset (the test's environment); does not establish the ordering claim when either is set — then `$model_flag`/`${CLAUDE_FLAGS}` follow `--tools` and the test would fail (see Claim 23).
**Legibility-target:** for-orchestrator-synthesis

`claude_args+=(--tools "$TOOLS_ARG")` (`test/skills/generate-reports.bash:165`) is the last array append, and the call is `claude "${claude_args[@]}" $model_flag ${CLAUDE_FLAGS:-}` (`:209-211`). `bats test/generate-reports.bats` → 19/19 ok, exit 0, 2026-09-25T00:03Z.

**Evidence:** `test/skills/generate-reports.bash:159-165`, `test/skills/generate-reports.bash:208-212`, `$LOG/generate-reports.txt`

---

## Claim 4: test name "every committed fixture set has a runner the generator accepts"

**Location:** `test/generate-reports.bats:272`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the test body asserts; does not establish whether today's runners would in fact be accepted (they would — see Claim 19a's runner survey — but the test does not check it).
**Legibility-target:** for-author

The body checks only that the file exists:

```bash
# test/generate-reports.bats:276-280
  for dir in "$REPO_ROOT"/test/skills/*/fixtures/; do
    local skill_dir="${dir%/fixtures/}"
    [ -f "$skill_dir/runner.bash" ] || missing+=("$(basename "$skill_dir")")
  done
  [ "${#missing[@]}" -eq 0 ] || { echo "no runner.bash: ${missing[*]}"; return 1; }
```

Acceptance by the generator means passing `test/skills/generate-reports.bash:85-115` (FIXTURE_TOOLS set, `fixture_prompt` defined, no Write/Edit, valid FIXTURE_MODE and FIXTURE_TRANSCRIPT). A runner with `FIXTURE_MODE="sideways"` or no `fixture_prompt` passes this test. Fix: rename to "…has a runner.bash", or source each runner in a subshell and apply the generator's checks.

**Evidence:** `test/generate-reports.bats:272-281`, `test/skills/generate-reports.bash:85-115`

---

## Claim 5: persona catalog path is "Resolved when generate-reports.bash sources this file" and a missing catalog makes the runner "Fail loudly"

**Location:** `test/skills/ai-personas-critique/runner.bash:10-21`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a non-zero `fixture_prompt` aborts generate-reports.bash before any `claude` call; does not establish behaviour if the skill directory itself is missing (then the `cd` in the source-time `$(...)` fails and aborts at source, a different but also loud path).
**Legibility-target:** for-orchestrator-synthesis

`PERSONAS_CATALOG="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../skills/ai-personas-critique" && pwd)/personas.md"` is evaluated at source time. In the generator, `prompt="$(fixture_prompt "$subject_name")"` (`test/skills/generate-reports.bash:155`) runs under `set -euo pipefail` outside any conditional. Probe: a scratch copy of the generator with a runner whose `fixture_prompt` returns 1 and a stub `claude` that logs calls → script printed `nope`, `exit=1`, `claude calls: 0` (cwd `…/scratchpad/failprompt`, 2026-09-25T00:07Z).

**Evidence:** `test/skills/ai-personas-critique/runner.bash:10-21`, `test/skills/generate-reports.bash:56`, `test/skills/generate-reports.bash:154-155`, `$LOG/fixture-prompt-fail.txt`

---

## Claim 6: "Both are extracted from SKILL.md at test time, so these tests exercise exactly what a model would paste."

**Location:** `test/skills/arithmetic-eval-gate.bats:7-8`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Python program text of the Mode 1 evaluator and check.py (the tests read the live `skills/arithmetic-eval/SKILL.md`, not a copy); does not establish the surrounding shell wrapper (`ulimit -t 5 -v 1000000`, `timeout 5`) or the confinement tiers, which the tests do not run (the header scopes confinement out explicitly at :11-12).
**Legibility-target:** for-orchestrator-synthesis

`SKILL="$REPO_ROOT/skills/arithmetic-eval/SKILL.md"` (`:18`) and both `awk` extractions read `"$SKILL"` (`:23-27`). The Mode 1 body sits in shell single quotes (`SKILL.md:42` `timeout 5 python3 -c '` … `:83` `' ) <<'EXPREOF'`); the extracted body contains no `'` (`grep -c "'"` → 0), so no `'\''` escaping makes the file differ from what python receives. Extracted sizes: mode1.py 40 lines, check.py 87 lines. `bats test/skills/arithmetic-eval-gate.bats` → 18/18 ok, exit 0, 2026-09-25T00:03Z.

**Evidence:** `test/skills/arithmetic-eval-gate.bats:16-28`, `skills/arithmetic-eval/SKILL.md:42-85`, `skills/arithmetic-eval/SKILL.md:106-194`, `$LOG/arithmetic-eval-gate.txt`, `$LOG/mode1.py`, `$LOG/check.py`

---

## Claim 7: "the three Mode 2 heredoc delimiters are distinct and no body line equals one"

**Location:** `test/skills/arithmetic-eval-gate.bats:57-65`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three AE_* delimiters across the whole SKILL.md (a body line equal to any of the three would raise that delimiter's bare-line count above 1); does not cover the Mode 1 `EXPREOF` delimiter.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/arithmetic-eval-gate.bats:61-64
  for d in AE_SCRIPT_EOF AE_CHECK_EOF AE_CONFINE_EOF; do
    [ "$(grep -c "<<'$d'\$" "$SKILL")" -eq 1 ] || …
    [ "$(grep -cx "$d" "$SKILL")" -eq 1 ] || …
```

SKILL.md has each opener once (`:102`, `:106`, `:196`) and each bare line once (`:104`, `:194`, `:261`); test ok in the run above.

**Evidence:** `test/skills/arithmetic-eval-gate.bats:57-65`, `skills/arithmetic-eval/SKILL.md:102-261`, `$LOG/arithmetic-eval-gate.txt`

---

## Claim 8: test name "gate allows the harmless dunders and pandas method names SKILL.md promises"

**Location:** `test/skills/arithmetic-eval-gate.bats:129`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test exercises (`np.__version__`, `__name__`, `json.load`); does not establish the pandas method names SKILL.md names (`df.rename`, `.eval`/`.query`), which no test runs.
**Legibility-target:** for-author

```bash
# test/skills/arithmetic-eval-gate.bats:130-133
  run gate $'import numpy as np\nprint(np.__version__)\nif __name__ == "__main__":\n    pass'
  …
  run gate $'import json\nd = json.load(open("data.json"))\nprint(d)'
```

`json.load` is a json-module function, not a pandas method; SKILL.md's promise (`skills/arithmetic-eval/SKILL.md:124` "they'd reject json.load / df.rename. And .eval/.query (pandas)") also covers `df.rename` and pandas `.eval`/`.query`, which are untested. Precise name: "…harmless dunders and json.load".

**Evidence:** `test/skills/arithmetic-eval-gate.bats:129-134`, `skills/arithmetic-eval/SKILL.md:124`, `$LOG/arithmetic-eval-gate.txt`

---

## Claim 9: "SKILL.md puts the no-fact-check warning (up to 5 lines) above the title, so the default 5-line window would fail a report that follows the skill."

**Location:** `test/skills/cowen-critique-format.bats:22-23` (same comment in the ai-personas, market-sizing, moat, unit-economics and yglesias format suites)
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the default window and the warning lengths in the six SKILL.md files; does not establish that 12 lines suffices for every real report (a preamble plus warning plus blank lines could exceed it).
**Legibility-target:** for-orchestrator-synthesis

`local max_lines="${2:-5}"` (`test/skills/helpers.bash:127`). The longest warning is market-sizing's five quoted lines (`skills/business-plan-critique-market-sizing/SKILL.md:115-119`), and each SKILL.md says to "emit the following warning at the top of your output before the critique begins" (e.g. `skills/cowen-critique/SKILL.md:56`); five warning lines + blank puts the title at line 7.

**Evidence:** `test/skills/helpers.bash:125-131`, `skills/business-plan-critique-market-sizing/SKILL.md:115-119`, `skills/cowen-critique/SKILL.md:56-60`, `skills/ai-personas-critique/SKILL.md` (Step 4 warning)

---

## Claim 10: synthetic transcript is "shaped like a real `claude -p --output-format stream-json --verbose` run: top-level events carry "parent_tool_use_id": null, and a sub-agent's own events carry its parent's id."

**Location:** `test/skills/eval-helpers-transcript.bats:4-6`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Would cover the real CLI's stream-json schema (field name `parent_tool_use_id`, tool name `Agent`, sub-agent events being streamed at all); none of this can be observed without running `claude`.
**Legibility-target:** for-orchestrator-synthesis

The commit that added it says "event shapes taken from a real haiku stream-json run" (489a19f message), and `docs/working/research-skill-fixtures-batch4.md:29-30` records an observed probe of Agent dispatch, but neither artifact quotes a raw event line showing `parent_tool_use_id` (paraphrased — no quote available because `grep -n parent_tool_use_id docs/working/research-skill-fixtures-batch4.md` returns nothing). Needed: one captured real stream with a sub-agent dispatch. Blocker: the brief forbids running `claude`.

**Evidence:** `test/skills/eval-helpers-transcript.bats:17-23`, `docs/working/research-skill-fixtures-batch4.md:29-30`, commit 489a19f

---

## Claim 11: "Args: $1 = skill name (fact-check or code-fact-check)" and format_check "Delegate to the format BATS suite (fact-check-format.bats or code-fact-check-format.bats)"

**Location:** `test/skills/eval-helpers.bash:7`, `test/skills/eval-helpers.bash:135`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers these two comments in the file whose header this branch rewrote; does not establish anything about behaviour (both functions are skill-generic).
**Legibility-target:** for-author

The branch changed the file header to "every skill with a fixture set" (`:1-2`), and the code is generic: `verdicts_file="${BATS_TEST_DIRNAME}/${skill}/expected-verdicts.bash"` (`:10`), `bats "${BATS_TEST_DIRNAME}/${skill}-format.bats"` (`:136`). format_check is now used by other skills too (commit 83c9681 "run format_check on matrix-analysis tc-ma3 too"). Both parentheticals should say "any skill".

**Evidence:** `test/skills/eval-helpers.bash:1-18`, `test/skills/eval-helpers.bash:134-137`, commit 83c9681

---

## Claim 12: "Every check runs and any failure fails the call, so the result holds under bats' `run` and in conditionals, not only under a test body's errexit."

**Location:** `test/skills/eval-helpers.bash:74-76`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loop in `eval_fixture` (every arm appends `|| failed=1`; final `[ -z "$failed" ]`); does not establish behaviour of the earlier `skip` in `load_eval_report` under `run`, nor KEY_CHECK tokens containing a literal `;` (they split).
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/eval-helpers.bash:77-79, :144
  local checks check failed=""
  IFS=';' read -ra checks <<< "$key_check"
  for check in "${checks[@]}"; do
  …
  [ -z "$failed" ]
```

Probe (scratch `evalfx/probe.bash`, sourcing the real helpers, 2026-09-25T00:04Z): a report with `**Severity:** Low` vs expected `High` gave `plain status=1` with the failing check first, `conditional: FAIL(right)`, and `fail-last status=1` with the failing check last; `cites_pattern:.*` inside a directory with files gave status 0 (no glob expansion).

**Evidence:** `test/skills/eval-helpers.bash:58-145`, `$LOG/eval-fixture-probe.txt`

---

## Claim 13: "A missing transcript fails rather than skips"

**Location:** `test/skills/eval-helpers.bash:318-320`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `assert_tool_called` and `assert_subagents_min`; does not establish the stated reason ("the run happened without FIXTURE_TRANSCRIPT=1") — a transcript can also be absent because the run was aborted between the `rm -f` and claude (Claim 22).
**Legibility-target:** for-orchestrator-synthesis

`eval_transcript_path` prints a message and `return 1` when `[ ! -f "$t" ]` (`:323-330`); both callers use `t="$(eval_transcript_path)" || { echo "$t"; return 1; }` (`:347`, `:363`). Test `ok 6 a missing transcript fails (not skips) and says how to fix it` passed (7/7, exit 0, 2026-09-25T00:03Z).

**Evidence:** `test/skills/eval-helpers.bash:322-330`, `test/skills/eval-helpers-transcript.bats:61-69`, `$LOG/eval-helpers-transcript.txt`

---

## Claim 14: tool_called matches "every tool_use block for the named tool, at any depth (sub-agents' calls included)"

**Location:** `test/skills/eval-helpers.bash:332-340`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the jq filter (no `parent_tool_use_id` restriction) against the synthetic transcript; does not establish that real stream-json output includes sub-agents' events at all (Claim 10).
**Legibility-target:** for-orchestrator-synthesis

```jq
# test/skills/eval-helpers.bash:338-339
'fromjson? | select(.type == "assistant") | .message.content[]?
 | select(.type == "tool_use" and .name == $n) | .input | tostring'
```

`ok 4 tool_called sees sub-agents' calls too` (a Bash call in an event with `parent_tool_use_id":"t2"`) passed.

**Evidence:** `test/skills/eval-helpers.bash:335-355`, `test/skills/eval-helpers-transcript.bats:21`, `test/skills/eval-helpers-transcript.bats:48-51`, `$LOG/eval-helpers-transcript.txt`

---

## Claim 15: subagents_min counts "Agent tool_use blocks with no parent — a sub-agent's own dispatches do not count"

**Location:** `test/skills/eval-helpers.bash:357-358`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the filter on a transcript whose sub-agent events carry a non-null `parent_tool_use_id`; does not establish real-CLI behaviour where an event lacks the key (jq's `.parent_tool_use_id == null` is also true for a missing key, so such events would count) or the real tool name (`Agent` vs a legacy `Task`).
**Legibility-target:** for-orchestrator-synthesis

```jq
# test/skills/eval-helpers.bash:364-366
'fromjson? | select(.type == "assistant" and .parent_tool_use_id == null)
 | .message.content[]? | select(.type == "tool_use" and .name == "Agent") | .name'
```

`ok 5 subagents_min counts top-level dispatches only` (2 top-level + 1 nested → `found 2`) passed.

**Evidence:** `test/skills/eval-helpers.bash:361-371`, `test/skills/eval-helpers-transcript.bats:53-59`, `$LOG/eval-helpers-transcript.txt`

---

## Claim 16a: "The model must never see them: in "repo" mode the fixture is copied in as subject.<ext>"

**Location:** `test/skills/generate-reports.bash:30-33`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers argv, stdin, cwd path and cwd listing in repo mode, and the temp repo's git metadata (`user.name=fixture`, message `fixture`); does not establish ambient context the real CLI adds, and does not cover dotted names without an extension (Claim 17).
**Legibility-target:** for-orchestrator-synthesis

`cp "$fixture_path" "$temp_dir/$subject_name"` (`:187`); temp dir from `mktemp -d` (`:172`); commit `-c user.name=fixture -c user.email=fixture@localhost commit -q -m "fixture"` (`:192-193`). `ok 4 the fixture's descriptive filename never reaches the model` (stub records argv/CWD/LS/stdin; asserts no `sql-injection`) passed.

**Evidence:** `test/skills/generate-reports.bash:167-201`, `test/generate-reports.bats:93-104`, `$LOG/generate-reports.txt`

---

## Claim 16b: "…and that neutral name is what fixture_prompt receives in both modes."

**Location:** `test/skills/generate-reports.bash:32-33`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "both modes" wording; does not affect the tree-mode behaviour, which the block at :35-46 describes correctly.
**Legibility-target:** for-author

There are now three modes, and tree mode passes `.`, not a subject name:

```bash
# test/skills/generate-reports.bash:147-152
  local subject_name="subject"
  if [ "$FIXTURE_MODE" = "tree" ]; then
    subject_name="."
  elif [[ "$fixture_name" == *.* ]]; then
    subject_name="subject.${fixture_name##*.}"
  fi
```

Should read "in inline and repo modes".

**Evidence:** `test/skills/generate-reports.bash:30-46`, `test/skills/generate-reports.bash:146-155`

---

## Claim 17: "Keep the extension (it tells the model the language); drop the name."

**Location:** `test/skills/generate-reports.bash:146`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every committed fixture name (none are affected today); does not hold for a dotted name with no real extension, where the "extension" is part of the descriptive name.
**Legibility-target:** for-author

`${fixture_name##*.}` takes everything after the last dot. Probe (2026-09-25T00:10Z): `tc-2.4-inaccurate -> subject.4-inaccurate`, `tc-c2.4-incorrect.js -> subject.js`, `tc-sec1-sql-injection.py -> subject.py`. The header's own usage example (`:6`) uses `tc-2.4-inaccurate`. A survey of all committed fixtures by mode found no name that yields a non-language suffix (the only non-common suffix is `tc-uv8-unity-layout.cs -> subject.cs`), so this is latent. A precise version: "keep a trailing extension; a dotted id with no extension leaks its suffix".

**Evidence:** `test/skills/generate-reports.bash:6`, `test/skills/generate-reports.bash:146-152`, `$LOG/subject-name.txt`

---

## Claim 18: tree mode: fixture_base runs first, fixture copied on top, "REQUEST.md … appended to the prompt and not copied", ".fixture-* … removed before the model runs", "fixture_prompt receives "."", "directory's descriptive name never reaches the model"

**Location:** `test/skills/generate-reports.bash:35-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers top-level REQUEST.md and top-level `.fixture-*` entries, and argv/stdin/cwd/file list as seen by a stub; does not establish removal of nested `.fixture-*` paths (the comment says top-level only, which is accurate) or anything fixture_base itself copies in.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/generate-reports.bash:177-185
      if declare -F fixture_base >/dev/null; then
        fixture_base "$temp_dir" "$fixture_path"
      fi
      cp -R "$fixture_path"/. "$temp_dir"/
      if [ -f "$temp_dir/REQUEST.md" ]; then
        prompt="$prompt"$'\n\n'"$(cat "$temp_dir/REQUEST.md")"
        rm "$temp_dir/REQUEST.md"
      fi
      rm -rf "$temp_dir"/.fixture-*
```

Removal happens before `git add .` (`:191`). Tests `ok 10`–`ok 13` (tree base + REQUEST.md, name never reaches model, markers steer and are removed, directories-only) passed.

**Evidence:** `test/skills/generate-reports.bash:176-193`, `test/generate-reports.bats:193-236`, `$LOG/generate-reports.txt`

---

## Claim 19a: "Cheat prevention: the tool allowlist never includes Write" (and bf172c5: "Runners granting Write/Edit are refused")

**Location:** `test/skills/generate-reports.bash:48`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all 22 committed runner.bash values (none contains a write-capable tool) and the guard's exact-token match; does not establish enforcement for spelling variants, other write-capable tools, or `CLAUDE_FLAGS`, none of which the guard inspects.
**Legibility-target:** for-author

```bash
# test/skills/generate-reports.bash:89-94
case ",$FIXTURE_TOOLS," in
  *,Write,*|*,Edit,*)
    echo "Error: $RUNNER_FILE: FIXTURE_TOOLS must not include Write or Edit" >&2
```

Case probe (2026-09-25T00:02Z): rejected `Read,Write`, `Edit`; accepted `Read, Write` (space), ` Write`, `Write(*)`, `Read,write`, `Bash`, `NotebookEdit`, `MultiEdit`. Committed runners set only `none`, `Read,Grep,Glob`, `WebSearch,WebFetch` or `Agent` (grep of every `test/skills/*/runner.bash`). `${CLAUDE_FLAGS:-}` is appended unexamined (`:200`, `:211`), so an env-supplied `--allowedTools`/`--tools`/`--mcp-config` bypasses the rule. Precise version: "no runner grants Write; the guard rejects the exact tokens Write and Edit only".

**Evidence:** `test/skills/generate-reports.bash:89-94`, `test/skills/generate-reports.bash:196-212`, `test/skills/*/runner.bash` (FIXTURE_TOOLS lines), `$LOG/guard-case.txt`

---

## Claim 19b: "in "repo" mode the working directory holds only the fixture"

**Location:** `test/skills/generate-reports.bash:48-49`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers repo-mode cwd contents (subject file + `.git`); does not cover inline mode, which runs `claude` in the invoker's cwd with no `cd` (`:208-212`), nor tree mode, where fixture_base adds live repo files by design.
**Legibility-target:** for-orchestrator-synthesis

`ok 3 repo mode: claude runs in a temp repo holding only the fixture` asserts `LS: subject.txt`, no `SECRET VERDICTS`, CWD not under the test tree; passed.

**Evidence:** `test/skills/generate-reports.bash:167-201`, `test/generate-reports.bats:80-91`, `$LOG/generate-reports.txt`

---

## Claim 19c: "…so the model cannot reach expected-verdicts.bash or eval-criteria.md"

**Location:** `test/skills/generate-reports.bash:49-50`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Would cover whether Read/Grep/Glob in headless `claude -p` can open absolute paths outside cwd (e.g. `/workspace/test/skills/<skill>/expected-verdicts.bash`); cwd isolation alone does not establish that.
**Legibility-target:** for-orchestrator-synthesis

The harness passes no `--permission-mode`, `--add-dir` or `--disallowedTools` (argv at `:159-165`), so the barrier rests entirely on the CLI refusing out-of-cwd reads in non-interactive mode (paraphrased — no quote available because the claim concerns CLI permission behaviour outside this repo). Needed: a headless probe asking a repo-mode run to Read an absolute path in the real repo. Blocker: running `claude` is forbidden in this review.

**Evidence:** `test/skills/generate-reports.bash:159-165`, `test/skills/generate-reports.bash:196-201`

---

## Claim 20a: "--strict-mcp-config on every run"

**Location:** `test/skills/generate-reports.bash:117`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers presence of the flag in argv in inline, repo and tree modes and with the transcript flags; does not establish its effect (Claim 20b).
**Legibility-target:** for-orchestrator-synthesis

`local -a claude_args=(-p --system-prompt-file "$SKILL_FILE" --strict-mcp-config)` (`:159`) is shared by both call sites. `ok 5 every mode passes --strict-mcp-config…` passed.

**Evidence:** `test/skills/generate-reports.bash:159`, `test/generate-reports.bats:106-117`, `$LOG/generate-reports.txt`

---

## Claim 20b: "without it the account's claude.ai MCP connectors … are exposed even under --tools "", in sub-agents too" (and ef05331's matching claim)

**Location:** `test/skills/generate-reports.bash:117-121`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Would cover the CLI's MCP exposure with and without the flag, under `--tools ""` and inside sub-agents; not observable without running `claude`.
**Legibility-target:** for-orchestrator-synthesis

The only recorded probe (commit ef05331) reports "the tool list drops from Read + 8 mcp__claude_ai_Claude_Docs__* to Read", i.e. a run with `--tools Read`; no artifact records the `--tools ""` or sub-agent cases the comment asserts (paraphrased — no quote available because no captured probe output is committed). Needed: headless `init` events for `--tools ""` and for an Agent sub-agent, with and without the flag. Blocker: `claude` may not be run.

**Evidence:** `test/skills/generate-reports.bash:117-121`, commit ef05331

---

## Claim 21: "claude -p reads --tools "" as "no tools"."

**Location:** `test/skills/generate-reports.bash:123-124`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the CLI's interpretation of an empty `--tools` value; the harness side (`TOOLS_ARG=""` when FIXTURE_TOOLS is `none`, `:125-126`) is verified by Claim 3.
**Legibility-target:** for-orchestrator-synthesis

External CLI semantics (paraphrased — no quote available because the behaviour lives in the claude binary, not this repo). Needed: an `init` event from `claude -p --tools ""` listing no tools. Blocker: `claude` may not be run.

**Evidence:** `test/skills/generate-reports.bash:123-126`

---

## Claim 22: "A stale transcript must never pair with a fresh report."

**Location:** `test/skills/generate-reports.bash:136-137`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all paths through `generate_one`: transcript off (sidecar removed up front), transcript on with claude failure (`|| true`, then jq rewrites the report), jq failure (`|| : > "$report_path"` truncates), and aborts after the `rm` (old report may survive but without a transcript); does not establish the converse (a stale report can survive an abort, unpaired).
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/generate-reports.bash:135-137, :220-221
  local transcript_path="$OUTPUT_DIR/${fixture_name}.transcript.jsonl"
  # A stale transcript must never pair with a fresh report.
  rm -f "$transcript_path"
  …
    jq -rR 'fromjson? | select(.type == "result") | .result // empty' "$transcript_path" \
      > "$report_path" 2>/dev/null || : > "$report_path"
```

In transcript mode the report is always re-created by a redirect, so it is never older than the transcript. `ok 8 transcript off: no stream-json flags, and a stale sidecar is removed` passed.

**Evidence:** `test/skills/generate-reports.bash:130-233`, `test/generate-reports.bats:148-158`, `$LOG/generate-reports.txt`

---

## Claim 23: "--tools stays last before the model/extra flags: an empty value must not swallow the next flag."

**Location:** `test/skills/generate-reports.bash:157-158`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about the CLI parser; the harness ordering is verified (Claim 3), but `$model_flag` and `${CLAUDE_FLAGS}` still follow `--tools` when set, so the ordering protects only the flags inside `claude_args`.
**Legibility-target:** for-orchestrator-synthesis

`claude "${claude_args[@]}" $model_flag ${CLAUDE_FLAGS:-}` (`:198-200`, `:209-211`) — `--tools ""` is immediately followed by `--model X` whenever `CLAUDE_MODEL` is set. Whether an empty value can swallow a following flag depends on the claude CLI's option parser (paraphrased — no quote available because the parser is in the external binary). The tests never set `CLAUDE_MODEL` or `CLAUDE_FLAGS`. Needed: a `--tools "" --model …` probe. Blocker: `claude` may not be run.

**Evidence:** `test/skills/generate-reports.bash:141-144`, `test/skills/generate-reports.bash:157-165`, `test/skills/generate-reports.bash:196-212`

---

## Claim 24: "-R + fromjson? parses line by line and skips non-JSON lines (a stray warning on stdout), which would otherwise abort jq and lose the report."

**Location:** `test/skills/generate-reports.bash:218-219` (same idiom commented at `test/skills/eval-helpers.bash:336`)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one-object-per-line streams with interleaved non-JSON lines; does not cover a JSON object split across lines (each fragment would be skipped).
**Legibility-target:** for-orchestrator-synthesis

On `{"type":"x"}` / `Warning: stray` / `{"type":"result","result":"R"}`: strict `jq -r 'select(.type=="result") | .result // empty'` printed `parse error: Invalid numeric literal at line 2, column 8` and exited 4 without `R`; the `-rR 'fromjson? | …'` form printed `R`, exit 0 (cwd `…/scratchpad/pre-d700`, 2026-09-25T00:04Z). `ok 7 FIXTURE_TRANSCRIPT=1: a non-JSON line in the stream does not lose the report` passed.

**Evidence:** `test/skills/generate-reports.bash:215-222`, `test/generate-reports.bats:134-146`, `$LOG/d700-testfirst.txt`, `$LOG/generate-reports.txt`

---

## Claim 25: "Sub-agents inherit the same tool list, so they cannot read the repo either"

**Location:** `test/skills/matrix-analysis/runner.bash:5-6`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Would cover the only in-scope runner that grants a tool in inline mode (`FIXTURE_TOOLS="Agent"`, cwd = the real repo); if sub-agents received a wider tool set, they could Read expected-verdicts.bash or Write into the working tree.
**Legibility-target:** for-orchestrator-synthesis

Corroborated but not re-executed here: `docs/working/research-skill-fixtures-batch4.md:30` records "Sub-agents inherit the `--tools` restriction: the sub-agent had Agent and Read, no Write, and failed to create a canary file. [observed]". That probe used `--tools "Agent,Read"` and did not test a Read of an out-of-scope path. Blocker: `claude` may not be run.

**Evidence:** `test/skills/matrix-analysis/runner.bash:1-15`, `docs/working/research-skill-fixtures-batch4.md:29-30`, `docs/working/checkpoint-skill-fixtures-batch4.md:13`

---

## Claim 26: "inline mode runs claude in the real repo" (matrix-analysis, ai-personas, market-sizing, moat, unit-economics, cowen, yglesias, pre-mortem, what-if, design-space-situating, dependency-upgrade, tech-debt-triage runners)

**Location:** `test/skills/matrix-analysis/runner.bash:3-4`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the inline call site; does not establish which directory that is — it is whatever cwd the invoker has.
**Legibility-target:** for-author

```bash
# test/skills/generate-reports.bash:208-212
    printf '%s\n\n%s' "$prompt" "$fixture_content" \
      | claude "${claude_args[@]}" \
        $model_flag \
        ${CLAUDE_FLAGS:-} \
      > "$out_path" 2>/dev/null || true
```

There is no `cd`, so inline claude runs in the caller's cwd — the real repo when invoked from inside it (including `test/skills/`, beside the verdict files, if run as the usage line `./generate-reports.bash` suggests). The runners' conclusion (withhold Read) is right. Precise version: "inline mode runs claude in the invoking shell's directory, normally inside the real repo".

**Evidence:** `test/skills/generate-reports.bash:4-8`, `test/skills/generate-reports.bash:202-213`

---

## Claim 27: "the fixture sits alone in a throwaway repo (no git history, so no branch diff to scope to)"

**Location:** `test/skills/security-reviewer/runner.bash:2-3`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the temp repo's history; the "no branch diff" conclusion holds.
**Legibility-target:** for-author

The repo has one commit: `commit -q -m "fixture" --allow-empty` (`test/skills/generate-reports.bash:192-193`). Precise version: "a single-commit history, so no branch diff". (self-eval's runner states this correctly: "a single commit named "fixture"".)

**Evidence:** `test/skills/security-reviewer/runner.bash:2-4`, `test/skills/generate-reports.bash:189-193`, `test/skills/self-eval/runner.bash:37`

---

## Claim 28: ".bats.in … stored renamed so scripts/run-tests.sh, which collects every *.bats under test/, never runs them"; "this repository's history is a single commit named "fixture""

**Location:** `test/skills/self-eval/runner.bash:10-12`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers run-tests.sh collection and the temp-repo commit; does not establish that no other tool (e.g. a direct `bats test/` call) picks up `.bats.in`.
**Legibility-target:** for-orchestrator-synthesis

`done < <(find "$TEST_DIR" -name '*.bats' -print0 | sort -z)` (`scripts/run-tests.sh:63`) matches no `*.bats.in`. Committed files are `.fixture-tests/skills/*.bats.in` (tc-se2, tc-se4 listing). The generator commits once with `-m "fixture"` (`test/skills/generate-reports.bash:192-193`).

**Evidence:** `scripts/run-tests.sh:43-63`, `test/skills/self-eval/runner.bash:10-35`, `test/skills/generate-reports.bash:189-193`

---

## Claim 29: bf172c5: "The two existing skills' prompts and tool lists move into runners unchanged."

**Location:** commit bf172c5
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the prompt text and tool strings; does not cover the subject filename, which 4f91e29 later changed deliberately (subject.<ext>).
**Legibility-target:** for-orchestrator-synthesis

Base `answers-2026-09-20:test/skills/generate-reports.bash:42` `ALLOWED_TOOLS="Read,Grep,Glob"`, `:44` `ALLOWED_TOOLS="WebSearch,WebFetch"`, `:77` `"Code fact-check the file ${fixture_name}. Check all claims in comments and docstrings against actual code behavior. Scope: ${fixture_name}"`, `:93` `"Fact-check the following draft:"` match `test/skills/code-fact-check/runner.bash:4,9` and `test/skills/fact-check/runner.bash:4,8` verbatim apart from the variable name.

**Evidence:** `answers-2026-09-20:test/skills/generate-reports.bash:42-96`, `test/skills/code-fact-check/runner.bash:1-10`, `test/skills/fact-check/runner.bash:1-9`

---

## Claim 30: 3023a20: "eval_fixture turned out to ignore its checks' exit status … Under `run` or in a conditional it returned 0 for a failing report … a pattern like `.*` can no longer glob-expand against the cwd"

**Location:** commit 3023a20
**Type:** Reference / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old unquoted for-list and missing status capture (static, from the diff) and the new behaviour (executed); does not re-run the old code under `run`.
**Legibility-target:** for-orchestrator-synthesis

The removed lines were `IFS=';;'` / `for check in $key_check; do` with arms like `assert_verdict "$expected_verdict"` and no status capture (diff of `test/skills/eval-helpers.bash`, old `:73-80`), so an unquoted `.*` token was subject to pathname expansion and the function's status was that of its last command. The new code is verified in Claim 12 (including `cites_pattern:.*` → status 0 in a populated cwd).

**Evidence:** `git diff answers-2026-09-20...skill-fixtures -- test/skills/eval-helpers.bash` (hunk `@@ -70,48 +71,77 @@`), `$LOG/eval-fixture-probe.txt`

---

## Claim 31: ef05331: "Verified by a headless probe: the tool list drops from Read + 8 mcp__claude_ai_Claude_Docs__* to Read."

**Location:** commit ef05331
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Would cover the CLI's tool list with/without `--strict-mcp-config`; no captured probe output exists in the repo.
**Legibility-target:** for-orchestrator-synthesis

The reviewer's own session exposes exactly eight `mcp__claude_ai_Claude_Docs__*` tools (batch, guide, update, create, delete, export, query, read), consistent with the count, but that is the host session, not a `claude -p` run (paraphrased — no quote available because the evidence is the reviewer's tool roster). Blocker: `claude` may not be run.

**Evidence:** commit ef05331, `test/skills/generate-reports.bash:117-121`

---

## Claim 32: b5bf458: "Mutation-checked: adding os to ALLOWED_MODULES, dropping __class__ from the dunder list, or dropping ast.Mod from the evaluator each fails a test."

**Location:** commit b5bf458
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named mutations against the current test file; does not establish mutation coverage of other entries.
**Legibility-target:** for-orchestrator-synthesis

Each mutation applied to a scratch copy of SKILL.md (one changed line each, targeting `SKILL.md:48`, `:114`, `:140`), with the real bats file run against it (cwd `…/scratchpad/mut`, 2026-09-25T00:04Z): `os` → `not ok 13 gate rejects non-approved imports…`; `__class__` → `not ok 15 gate rejects reflection dunders…`; `ast.Mod` → `not ok 6 Mode 1 handles unary minus, floor division and modulo`.

**Evidence:** `skills/arithmetic-eval/SKILL.md:48`, `skills/arithmetic-eval/SKILL.md:114`, `skills/arithmetic-eval/SKILL.md:140`, `$LOG/mutation.txt`

---

## Claim 33: fa3c5c0: "every key read as "fixture does not exist": 10 failures" and "run-tests.sh --fast: 939 ok, 0 failures"

**Location:** commit fa3c5c0
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the old `-f` logic re-applied to the current verdict files (10 misses) and today's fast-suite count (941), from which 939 at fa3c5c0 is inferred by subtracting the two tests d700f62 added; does not re-run the suite at fa3c5c0 itself. Checked against prior pattern "test-count claims in commit messages" (`docs/reviews/hallucination-patterns.md:28`) — no recurrence.
**Legibility-target:** for-orchestrator-synthesis

Old-logic emulation over self-eval and divergent-design `EXPECTED_VERDICT` keys printed `old-logic reverse-loop misses=10` (2026-09-25T00:06Z). `scripts/run-tests.sh --fast` → `1..941`, 941 ok (64 of them skips), 0 not ok, exit 0 (2026-09-25T00:07Z). d700f62 added one test to each of generate-reports.bats and eval-helpers-transcript.bats; 04c0746 added none.

**Evidence:** `scripts/health-check.sh:311-337`, `$LOG/hc-old-logic.txt`, `$LOG/run-tests-fast.txt`

---

## Claim 34: d700f62: "Test-first: new cases in generate-reports.bats and eval-helpers-transcript.bats failed before the change and pass after."

**Location:** commit d700f62
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named new cases against the d700f62^ tree; does not cover the commit's "slow suite (219)" figure.
**Legibility-target:** for-orchestrator-synthesis

`git archive d700f62^` into scratch, current bats files copied over, run (cwd `…/scratchpad/pre-d700`, 2026-09-25T00:04Z): `not ok 7 FIXTURE_TRANSCRIPT=1: a non-JSON line in the stream does not lose the report` and `not ok 7 a non-JSON line in the transcript does not blind the checks`, with every other case ok; both pass at HEAD (Claims 24, 13).

**Evidence:** `$LOG/d700-testfirst.txt`, `test/generate-reports.bats:134-146`, `test/skills/eval-helpers-transcript.bats:71-78`

---

## Claim 35: 04c0746: newest rubric by glob order is ans-guard-q048-q050; it writes "None."; rubric.md defines no sentinel; "This failure was already on answers-2026-09-20"

**Location:** commit 04c0746 (`test/skills/code-review-format.bats:84-96`)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Must Fix/Must Address tests and the base-branch failure; does not establish that other rubrics' empty states match either form.
**Legibility-target:** for-orchestrator-synthesis

`latest_rubric` keeps the last glob match (`test/skills/helpers.bash:49-57`); the last three sorted names end with `code-review-rubric-2026-09-23-ans-guard-q048-q050.md`, whose Must Fix section is `None.`. `grep -i "(none)\|none\.\|empty-state\|sentinel"` over `skills/code-review/references/rubric.md` returned nothing. `bats test/skills/code-review-format.bats` on a `git archive answers-2026-09-20` tree → `not ok 13 Must Fix section contains a table or (None)`, exit 1 (2026-09-25T00:06Z); the rubric's last commit b0b0651 is an ancestor of the base.

**Evidence:** `test/skills/code-review-format.bats:84-96`, `test/skills/helpers.bash:49-57`, `docs/reviews/code-review-rubric-2026-09-23-ans-guard-q048-q050.md`, `$LOG/base-code-review-format.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`test/generate-reports.bats:272`): the test named "…has a runner the generator accepts" only checks that `runner.bash` exists. Rename it, or apply the generator's validation (`generate-reports.bash:85-115`) to each runner.

### Stale
- **Claim 11** (`test/skills/eval-helpers.bash:7`, `:135`): "(fact-check or code-fact-check)" and "(fact-check-format.bats or code-fact-check-format.bats)" predate the generalization. The code serves any skill.
- **Claim 16b** (`test/skills/generate-reports.bash:32-33`): "in both modes" should now read inline and repo, since tree mode passes ".".

### Mostly Accurate
- **Claim 8** (`test/skills/arithmetic-eval-gate.bats:129`): says "pandas method names", but the test exercises `json.load`. `df.rename` and `.eval`/`.query` are untested.
- **Claim 17** (`test/skills/generate-reports.bash:146`): `${name##*.}` turns a dotted id with no extension (the header's own `tc-2.4-inaccurate`) into `subject.4-inaccurate` and leaks the label. This is latent: no committed fixture triggers it today.
- **Claim 19a** (`test/skills/generate-reports.bash:48`, `:89-94`): no runner grants Write. The guard only rejects the exact tokens `Write` and `Edit`. It accepts `Read, Write`, `Write(*)`, `NotebookEdit`, `MultiEdit` and `Bash`, and it never inspects `CLAUDE_FLAGS`.
- **Claim 26** (runner comments, e.g. `test/skills/matrix-analysis/runner.bash:3-4`): inline mode runs in the invoker's cwd. That is the real repo only when invoked from inside it.
- **Claim 27** (`test/skills/security-reviewer/runner.bash:2-3`): the temp repo has a single commit, so "no git history" is wrong. "No branch diff" is right.

### Unverifiable
- **Claim 10** (`test/skills/eval-helpers-transcript.bats:4-6`): to verify, capture one real stream-json run with a sub-agent dispatch that shows `parent_tool_use_id` and the `Agent` tool name.
- **Claim 19c** (`test/skills/generate-reports.bash:49-50`): to verify, run a headless probe that Reads an absolute path in the real repo from a repo-mode run. The cheat barrier depends on the CLI denying out-of-cwd reads.
- **Claim 20b** (`test/skills/generate-reports.bash:117-121`): to verify, capture init tool lists with and without `--strict-mcp-config` under `--tools ""` and in a sub-agent. The only recorded probe used `--tools Read`.
- **Claim 21** (`test/skills/generate-reports.bash:123-124`): to verify, capture the init event of `claude -p --tools ""`.
- **Claim 23** (`test/skills/generate-reports.bash:157-158`): to verify, run a `--tools "" --model X` probe. Also, `--model` and `CLAUDE_FLAGS` still come after `--tools`, and no test sets them.
- **Claim 25** (`test/skills/matrix-analysis/runner.bash:5-6`): this is the only inline runner that grants a tool (Agent), and it runs in the real repo. A recorded probe backs sub-agent inheritance, but that probe did not test an out-of-scope Read.
- **Claim 31** (commit ef05331): no captured probe output is committed.

---

## Goal-Alignment Note

- **Answered:** Success criterion: a code-fact-check report saved to /workspace/docs/reviews/code-fact-check-report-skill-fixtures-r3.md, following the SKILL.md schema, with a `Commit: 04c0746` line at the top. Every claim carries a Legibility-target field: Incorrect/Stale/Mostly Accurate → for-author; Verified/Unverifiable → for-orchestrator-synthesis. It is met: 39 claims covering all nine focus areas in the brief, with bats suites, jq filters, mutations and pre-fix trees executed where the sandbox allowed.
- **Out of scope:** fixture data, eval-criteria.md, expected-verdicts.bash and *-eval.bats (sibling context, per the brief). Running `claude` or generate-reports.bash end-to-end is forbidden, which is why Claims 10, 19c, 20b, 21, 23, 25 and 31 stay Unverifiable. Execution logs are kept outside the repo in the scratchpad, not in `docs/reviews/execution-logs/`, because this reviewer may not write other repo files.
- **Escalate:** The trust boundary depends on unexecuted CLI behaviour. Claim 19c: repo-mode Read of absolute paths. Claim 25: the inline-mode Agent sub-agents in matrix-analysis, which run in the real repo. Claim 19a: the Write guard can be bypassed by spelling variants and `CLAUDE_FLAGS`. One headless probe per item would settle all three.
