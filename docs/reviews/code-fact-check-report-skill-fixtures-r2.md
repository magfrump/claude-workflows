Commit: 04c0746

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Scope:** `git diff answers-2026-09-20...skill-fixtures` over the 40 harness files listed in the pass-1 brief (generate-reports.bash, eval-helpers.bash, the 22 runner.bash files, generate-reports.bats, eval-helpers-transcript.bats, arithmetic-eval-gate.bats, health-check.sh + its bats, the *-format.bats edits, .gitignore), plus the commit messages touching them
**Checked:** 2026-09-24
**Total claims checked:** 32
**Summary:** 19 verified, 3 mostly accurate, 1 stale, 3 incorrect, 6 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. No claim in this scope matches a logged pattern.

Execution provenance: all commands ran with cwd `/workspace` unless stated, between 2026-09-24T17:02:39-07:00 and 17:09:29-07:00. The captured outputs are in `/tmp/claude-1000/-workspace/486d17ef-98de-46e2-88d8-3db5f5c05a49/scratchpad/logs/` (shortened to `LOGS/` below). Per the brief, neither `claude` nor `generate-reports.bash` was run end to end. Every claim about the real CLI's runtime behaviour is therefore capped at Unverifiable. The four in-scope bats suites pass at head: `bats test/generate-reports.bats`, `test/skills/eval-helpers-transcript.bats`, `test/skills/arithmetic-eval-gate.bats` and `test/scripts/health-check.bats` each exited 0 (`LOGS/generate-reports.log`, `LOGS/eval-helpers-transcript.log`, `LOGS/arithmetic-eval-gate.log`, `LOGS/health-check.log`).

---

## Claim 1: "A fixture is a file, or a directory for tree-mode runners (test/skills/generate-reports.bash: self-eval, divergent-design)."

**Location:** `scripts/health-check.sh:314-317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both directions of the fixture ↔ expected-verdicts check (forward loop `-f || -d`, reverse check `-e`) for the self-eval and divergent-design sets. It does not establish that a directory fixture's contents are valid, or anything about symlinks and other special files that `-e` also accepts.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/health-check.sh:316-317, :333
        for fixture in "$skill_dir"/fixtures/*; do
            [[ -f "$fixture" || -d "$fixture" ]] || continue
...
            if [[ ! -e "$skill_dir/fixtures/$key" ]]; then
```

Executed: `bats test/scripts/health-check.bats` exit 0, including `ok 7 directory (tree-mode) fixture sets pass the fixture ↔ verdict check`. Its greps (`test/scripts/health-check.bats:83-84`) require the "all fixtures have verdicts and vice versa" line for both skills.

**Evidence:** `scripts/health-check.sh:314-335`, `test/scripts/health-check.bats:80-85`, `LOGS/health-check.log`

---

## Claim 2: "--tools is the last argument, so an empty value leaves \"--tools \" at the end of the recorded argv line."

**Location:** `test/generate-reports.bats:74-76`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers argv order when `CLAUDE_MODEL` and `CLAUDE_FLAGS` are unset in the test environment. It does not hold when either variable is exported, because the generator appends both after `--tools`.
**Legibility-target:** for-author

```bash
# test/skills/generate-reports.bash:197-200
      | claude "${claude_args[@]}" \
        $model_flag \
        ${CLAUDE_FLAGS:-} \
```

The test inherits the caller's environment and does not unset these variables. Executed at 2026-09-24T17:08:56-07:00: `CLAUDE_MODEL=sonnet bats -f "none passes|stream-json kept" test/generate-reports.bats` exited 1 with `not ok 1 FIXTURE_TOOLS=none passes an empty --tools list`, failing at line 76. The precise version: "--tools is last *when CLAUDE_MODEL/CLAUDE_FLAGS are unset*". As written, the test is not hermetic against those variables.

**Evidence:** `test/generate-reports.bats:69-78`, `test/skills/generate-reports.bash:141-144,196-201`, `LOGS/claude-model-env.log`

---

## Claim 3: "every committed fixture set has a runner the generator accepts" (bats test name)

**Location:** `test/generate-reports.bats:272-281`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test asserts. It does not establish whether the committed runners would pass the generator's checks; I checked that separately and all 22 do today.
**Legibility-target:** for-author

The test only checks that the file exists:

```bash
# test/generate-reports.bats:278
    [ -f "$skill_dir/runner.bash" ] || missing+=("$(basename "$skill_dir")")
```

It never sources the runner or applies the generator's gates (`FIXTURE_TOOLS` non-empty, `fixture_prompt` defined, no Write/Edit, mode in inline|repo|tree, transcript 0|1; `generate-reports.bash:85-115`). A runner with `FIXTURE_MODE=sideways` would still pass it. Executed: I sourced each of the 22 runners and applied those gates, and all 22 were accepted (paraphrased — no quote available because the check was an ad-hoc shell loop in this session, not repo code). So the property holds today, but this test does not guard it.

**Evidence:** `test/generate-reports.bats:272-281`, `test/skills/generate-reports.bash:85-115`

---

## Claim 4: "Resolved when generate-reports.bash sources this file, not when the function runs, so the path does not depend on the caller's working directory."

**Location:** `test/skills/ai-personas-critique/runner.bash:11-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers resolution of `PERSONAS_CATALOG` under bash via `BASH_SOURCE`, and a later `cd` before `fixture_prompt` runs. It does not cover sourcing from a non-bash shell: under zsh the `BASH_SOURCE`-based `cd` fails, which does not matter because generate-reports.bash is bash.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/ai-personas-critique/runner.bash:13
PERSONAS_CATALOG="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../skills/ai-personas-critique" && pwd)/personas.md"
```

Executed from the scratchpad cwd: `bash -c 'source .../runner.bash; echo "$PERSONAS_CATALOG"; cd /; fixture_prompt x | grep -c "BEGIN personas.md"'`. It printed `/workspace/skills/ai-personas-critique/personas.md` and `1` (exit 0).

**Evidence:** `test/skills/ai-personas-critique/runner.bash:11-27`

---

## Claim 5: "Both are extracted from SKILL.md at test time, so these tests exercise exactly what a model would paste."

**Location:** `test/skills/arithmetic-eval-gate.bats:7-8`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Python program text: the Mode 1 body between `timeout 5 python3 -c '` and `' ) <<'EXPREOF'` (SKILL.md:42-83), and check.py between the exact `AE_CHECK_EOF` delimiter lines (SKILL.md:106-194). It does not cover the shell wrapper around them (`ulimit`, `timeout`, heredoc stdin) or the confinement tiers, which the header scopes out.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/arithmetic-eval-gate.bats:23-27
  awk "/timeout 5 python3 -c '\$/ { f=1; next } /^' \\) <<'EXPREOF'\$/ { f=0 } f" \
    "$SKILL" > "$MODE1"
  awk "/^cat > \"\\\$AE\\/check.py\" <<'AE_CHECK_EOF'\$/ { f=1; next } /^AE_CHECK_EOF\$/ { f=0 } f" \
    "$SKILL" > "$CHECK"
```

The tests read the live `skills/arithmetic-eval/SKILL.md` and not a vendored copy, so the tested text cannot drift from the skill. The extracted Mode 1 body contains no `'` characters (`grep -n "'"` on the 40 extracted lines was empty). Shell unquoting of the `-c '...'` argument therefore does not change it, and what the test runs matches what `python3 -c` receives. All 18 tests pass.

**Evidence:** `test/skills/arithmetic-eval-gate.bats:16-28`, `skills/arithmetic-eval/SKILL.md:42-83,106-194`, `LOGS/arithmetic-eval-gate.log`

---

## Claim 6: "Mutation-checked: adding os to ALLOWED_MODULES, dropping __class__ from the dunder list, or dropping ast.Mod from the evaluator each fails a test." / "An empty extraction fails loudly instead of passing every reject case."

**Location:** commit `b5bf458`; `test/skills/arithmetic-eval-gate.bats:45-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named mutations and the line-count guards on extraction. It does not show that other gate weakenings (for example removing a banned builtin) would be caught.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/arithmetic-eval-gate.bats:48
  [ "$(wc -l < "$MODE1")" -ge 20 ] || { echo "Mode 1 extraction: ..."; return 1; }
```

Executed at 2026-09-24T17:05:52-07:00 in three scratch trees (`mut-os`, `mut-class`, `mut-mod`), each with a copy of the bats file and a mutated SKILL.md (sed on lines 113, 140 and 48 respectively). Each run exited 1:
- os → `not ok 13 gate rejects non-approved imports, including sys and importlib`
- class → `not ok 15 gate rejects reflection dunders as attributes and as string literals`
- mod → `not ok 6 Mode 1 handles unary minus, floor division and modulo`

**Evidence:** `test/skills/arithmetic-eval-gate.bats:45-55,81-85,138-161`, `LOGS/mutation-os.log`, `LOGS/mutation-class.log`, `LOGS/mutation-mod.log`

---

## Claim 7: "code-review-format.bats checks the newest rubric by glob order, which is now the ans-guard-q048-q050 rubric. That rubric writes \"None.\" under Must Fix ... rubric.md defines no empty-state sentinel for these two sections ... This failure was already on answers-2026-09-20."

**Location:** commit `04c0746`; `test/skills/code-review-format.bats:84-96`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers glob-order selection, the rubric's `None.` line, the absence of a sentinel in rubric.md's Must Fix/Must Address templates, and the base test failing against that rubric. It does not establish that the widened `^None\.$` pattern would reject a malformed section that happens to contain a bare `None.` line elsewhere.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/helpers.bash:51-53
  for f in docs/reviews/code-review-rubric-*.md; do
    [ -e "$f" ] || continue
    newest="$f"
```

The last glob match is `code-review-rubric-2026-09-23-ans-guard-q048-q050.md`, whose `## 🔴 Must Fix` section is followed by `None.` (lines 20-22). `skills/code-review/references/rubric.md:38-47` shows only a table template for Must Fix and no `(None)` sentinel. The rubric file already exists on `answers-2026-09-20` (`git ls-tree` shows blob 0a624d0). Executed at 2026-09-24T17:05:39-07:00: `git show answers-2026-09-20:test/skills/code-review-format.bats` run via `bats -f "Must Fix|Must Address"` exited 1 with `not ok 3 Must Fix section contains a table or (None)` (temp copy removed afterwards).

**Evidence:** `test/skills/helpers.bash:49-57`, `docs/reviews/code-review-rubric-2026-09-23-ans-guard-q048-q050.md:20-22`, `skills/code-review/references/rubric.md:38-60`, `LOGS/base-code-review-format.log`

---

## Claim 8: "Inline mode runs claude in the real repo, where Read could reach expected-verdicts.bash" (repeated across the inline runners)

**Location:** `test/skills/cowen-critique/runner.bash:2-3` (same wording in the ai-personas, business-plan-critique-*, dependency-upgrade, design-space-situating, matrix-analysis, pre-mortem, tech-debt-triage, what-if-analysis and yglesias runners)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the generator runs inline-mode claude. It does not establish what a Read tool could reach from there, since no inline runner grants Read.
**Legibility-target:** for-author

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

## Claim 9: "against a synthetic stream-json transcript shaped like a real `claude -p --output-format stream-json --verbose` run: top-level events carry \"parent_tool_use_id\": null, and a sub-agent's own events carry its parent's id."

**Location:** `test/skills/eval-helpers-transcript.bats:3-6`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing about the real CLI's event schema. The two things that would need checking are whether real sub-agent events appear in the stream with a non-null `parent_tool_use_id`, and whether the dispatch tool is named `Agent` rather than `Task`.
**Legibility-target:** for-orchestrator-synthesis

Checking this needs a real stream-json run, which the brief forbids ("execution required", blocked). The fixture's shape (`eval-helpers-transcript.bats:17-23`) is internally consistent with the checks. Commit `489a19f` says "event shapes taken from a real haiku stream-json run"; that claim is unverifiable here for the same reason.

**Evidence:** `test/skills/eval-helpers-transcript.bats:3-23`

---

## Claim 10: "Every check runs and any failure fails the call, so the result holds under bats' `run` and in conditionals, not only under a test body's errexit."

**Location:** `test/skills/eval-helpers.bash:74-76`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the dispatch loop, including unknown check types, and the final status. It does not establish that each individual assert is correct, and it does not cover patterns containing a literal `;`, which the `IFS=';'` split would break (no current KEY_CHECK contains one).
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/eval-helpers.bash:78, :144
  IFS=';' read -ra checks <<< "$key_check"
...
  [ -z "$failed" ]
```

Executed at 2026-09-24T17:04:45-07:00 using a scratch bats test with KEY_CHECK `severity_match;;cites_pattern:NOPE;;no_pattern:Report;;bogus_check`. `run eval_fixture` gave `status=1` and printed all four failure messages, so every check ran. The `if eval_fixture ...` form took the fail branch. Each assert ends in an explicit `return 1` and does not rely on errexit, which is disabled inside the `|| failed=1` context.

**Evidence:** `test/skills/eval-helpers.bash:56-145`, `LOGS/eval-fixture-allchecks.log`

---

## Claim 11: "The label may sit at the start of the line or after a list bullet (\"- **Severity:** High\") ... with \\r stripped."

**Location:** `test/skills/eval-helpers.bash:226-238`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers line-start, indented `-`/`*`/`+` bullets, CR stripping and mid-line rejection. It does not cover numbered-list items (`1. **Severity:**`), which are not matched. The comment names only list bullets, so this is not a contradiction.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/eval-helpers.bash:236-237
  echo "$REPORT_CONTENT" | tr -d '\r' \
    | sed -E -n "s/^[[:space:]]*([-*+][[:space:]]+)?\*\*${field}:\*\* //p"
```

Executed on sample content: the output was `High`, `Low`, `Medium` (the plain, `- ` and indented `* ` forms, with CR removed). The mid-line `Critical` and the `1.` item were not returned.

**Evidence:** `test/skills/eval-helpers.bash:226-238`, `LOGS/field-values.log`

---

## Claim 12: "A missing transcript fails rather than skips"

**Location:** `test/skills/eval-helpers.bash:318-320`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `tool_called` and `subagents_min` when the `.transcript.jsonl` sidecar is absent. It does not cover an empty or truncated transcript, which yields "0 calls seen" rather than a missing-file message.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/eval-helpers.bash:324-327
  local t="${REPORT_PATH%.report.md}.transcript.jsonl"
  if [ ! -f "$t" ]; then
    echo "No transcript at $t — regenerate with FIXTURE_TRANSCRIPT=1 in the runner"
    return 1
```

Executed: `ok 6 a missing transcript fails (not skips) and says how to fix it`.

**Evidence:** `test/skills/eval-helpers.bash:323-330,345-348,361-363`, `LOGS/eval-helpers-transcript.log`

---

## Claim 13: "every tool_use block for the named tool, at any depth (sub-agents' calls included)."

**Location:** `test/skills/eval-helpers.bash:332-340`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the jq filter, which applies no parent filter and so matches any assistant event in the file. It does not establish that the real CLI writes sub-agent tool calls into the parent's stream-json at all (see Claim 9).
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/eval-helpers.bash:337-339
  jq -rR --arg n "$2" \
    'fromjson? | select(.type == "assistant") | .message.content[]?
     | select(.type == "tool_use" and .name == $n) | .input | tostring' "$1"
```

Executed: `ok 4 tool_called sees sub-agents' calls too`. The matched Bash call sits on an event with `parent_tool_use_id:"t2"`.

**Evidence:** `test/skills/eval-helpers.bash:332-354`, `test/skills/eval-helpers-transcript.bats:21,48-51`

---

## Claim 14: "Agent tool_use blocks with no parent — a sub-agent's own dispatches do not count"

**Location:** `test/skills/eval-helpers.bash:357-358`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers streams where sub-agent events carry a non-null `parent_tool_use_id`. It does not hold if an event omits that key: `{} | .parent_tool_use_id == null` evaluates to `true` in jq, so such an event's dispatches would be counted. It also does not establish that the real dispatch tool is named `Agent`.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/eval-helpers.bash:364-366
  n=$(jq -rR 'fromjson? | select(.type == "assistant" and .parent_tool_use_id == null)
       | .message.content[]? | select(.type == "tool_use" and .name == "Agent")
       | .name' "$t" | grep -c . || true)
```

Executed: `ok 5 subagents_min counts top-level dispatches only`, which found 2 and excluded the nested `t4`. `jq -n '{} | .parent_tool_use_id == null'` printed `true`. The matrix-analysis runner grants `FIXTURE_TOOLS="Agent"`, so the name matches the harness's own tool list.

**Evidence:** `test/skills/eval-helpers.bash:356-371`, `test/skills/eval-helpers-transcript.bats:20-21,53-59`

---

## Claim 15a: "Fixture filenames describe the planted defect or the expected verdict ... The model must never see them"

**Location:** `test/skills/generate-reports.bash:30-33`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the prompt, stdin, cwd and file names in all three modes for every committed fixture: repo → `subject.<ext>`, tree → `.`, inline → only the neutral name is passed to `fixture_prompt`, and the temp dir comes from `mktemp -d` with commit message `fixture`. It does not cover (a) a future file fixture whose name contains a dot but no real extension (e.g. `tc-4.2-conflated-stats`), where `${fixture_name##*.}` would pass `subject.2-conflated-stats` to the model, (b) descriptive text inside fixture content, or (c) `CLAUDE_FLAGS`.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/generate-reports.bash:147-152
  local subject_name="subject"
  if [ "$FIXTURE_MODE" = "tree" ]; then
    subject_name="."
  elif [[ "$fixture_name" == *.* ]]; then
    subject_name="subject.${fixture_name##*.}"
  fi
```

Executed: generate-reports.bats `the fixture's descriptive filename never reaches the model` (repo) and `tree mode: the fixture directory's name never reaches the model` both pass. Listing every committed file fixture's suffix produced only `cs go js md patch py ts tsx`, so no name hits the dotted-name edge today. Tree-fixture inner paths are target skill names (e.g. `skills/release-risk-notes/SKILL.md`), not verdict names.

**Evidence:** `test/skills/generate-reports.bash:146-201`, `test/generate-reports.bats:93-104,206-211`, `LOGS/generate-reports.log`

---

## Claim 15b: "in \"repo\" mode the fixture is copied in as subject.<ext>, and that neutral name is what fixture_prompt receives in both modes."

**Location:** `test/skills/generate-reports.bash:32-33`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "both modes" wording only. There are now three modes, and tree mode passes `.`, not `subject.<ext>`.
**Legibility-target:** for-author

```bash
# test/skills/generate-reports.bash:148-149
  if [ "$FIXTURE_MODE" = "tree" ]; then
    subject_name="."
```

Tree mode was added in `2e98d3c`. The paragraph still says "both modes" and "subject.<ext>". The tree-mode section at lines 45-46 states the `.` behaviour correctly.

**Evidence:** `test/skills/generate-reports.bash:30-33,45-46,146-152`

---

## Claim 16: "top-level files named .fixture-* are control markers for fixture_base; they are removed before the model runs"

**Location:** `test/skills/generate-reports.bash:43-44`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers top-level removal. It does not cover `.fixture-*` entries in subdirectories, which are left in place.
**Legibility-target:** for-author

```bash
# test/skills/generate-reports.bash:185
      rm -rf "$temp_dir"/.fixture-*
```

The comment says "files", but `rm -rf` also removes directories, and the self-eval runner depends on that for its `.fixture-tests/` directory (`self-eval/runner.bash:10-12,26-29`). The precise version: "top-level files *or directories* named .fixture-*". Executed: `tree mode: .fixture-* markers steer fixture_base and are removed` passes.

**Evidence:** `test/skills/generate-reports.bash:176-186`, `test/skills/self-eval/runner.bash:20-33`, `test/generate-reports.bats:213-221`

---

## Claim 17a: "Cheat prevention: the tool allowlist never includes Write"

**Location:** `test/skills/generate-reports.bash:48`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 22 committed runners' `FIXTURE_TOOLS` values. It does not cover `CLAUDE_FLAGS`, which is appended after `--tools` and could grant tools or permissions, or the guard's completeness (Claim 18).
**Legibility-target:** for-orchestrator-synthesis

Executed: I sourced each runner and printed `FIXTURE_TOOLS`. The values are `none` (11 runners), `Read,Grep,Glob` (9: api-consistency, architecture, code-fact-check, divergent-design, performance, security, self-eval, test-strategy, ui-visual), `WebSearch,WebFetch` (fact-check) and `Agent` (matrix-analysis). None contains Write, Edit, NotebookEdit, MultiEdit or Bash (paraphrased — no quote available because the evidence is the output of an ad-hoc loop over 22 files).

**Evidence:** `test/skills/*/runner.bash` (FIXTURE_TOOLS lines), `test/skills/generate-reports.bash:196-201`

---

## Claim 17b: "in \"repo\" mode the working directory holds only the fixture, so the model cannot reach expected-verdicts.bash or eval-criteria.md."

**Location:** `test/skills/generate-reports.bash:48-50`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** The first half is confirmed: the stub's `LS: subject.txt` and `CWD` assertions show cwd is a `mktemp -d` directory holding only the fixture and `.git`. "Cannot reach" is not established. Read, Grep and Glob accept absolute paths, so the guarantee rests on Claude Code refusing reads outside cwd in non-interactive `-p` mode.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/generate-reports.bash:171-172
    local temp_dir
    temp_dir=$(mktemp -d)
```

Whether an absolute-path `Read(/workspace/test/skills/<skill>/expected-verdicts.bash)` is denied depends on the CLI's permission behaviour. Checking it needs a real `claude -p` probe, which the brief forbids. No Read/Grep/Glob allow rules or `additionalDirectories` exist in `~/.claude/settings.json` or `/workspace/.claude/settings*.json` (checked with jq). `CLAUDE_FLAGS` (e.g. `--add-dir`, `--dangerously-skip-permissions`) would void the guarantee.

**Evidence:** `test/skills/generate-reports.bash:167-201`, `test/generate-reports.bats:80-91`

---

## Claim 18: guard "FIXTURE_TOOLS must not include Write or Edit" / commit bf172c5 "Runners granting Write/Edit are refused."

**Location:** `test/skills/generate-reports.bash:89-94`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the guard's string matching. It rejects only an exact `Write` or `Edit` token between commas. It does not establish how the CLI parses the spellings that slip through, which is why confidence is Medium.
**Legibility-target:** for-author

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

## Claim 19a: "--strict-mcp-config on every run" / bats "every mode passes --strict-mcp-config"

**Location:** `test/skills/generate-reports.bash:117,159`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the argv that inline, repo and tree modes build. It does not cover what the flag does at runtime (Claim 19b).
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/generate-reports.bash:159
  local -a claude_args=(-p --system-prompt-file "$SKILL_FILE" --strict-mcp-config)
```

Executed: `ok 5 every mode passes --strict-mcp-config, so account MCP connectors stay out`, which loops over inline, repo and tree.

**Evidence:** `test/skills/generate-reports.bash:159-165`, `test/generate-reports.bats:106-117`

---

## Claim 19b: "without it the account's claude.ai MCP connectors (e.g. Claude Docs create/update/delete) are exposed even under --tools \"\", in sub-agents too"

**Location:** `test/skills/generate-reports.bash:117-121`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing at runtime. It does not establish that the connectors are exposed without the flag, or that `--strict-mcp-config` removes claude.ai connectors in the parent and in sub-agents.
**Legibility-target:** for-orchestrator-synthesis

The static text supports it. The CLI binary's option table has `.option("--strict-mcp-config","Only use MCP servers from --mcp-config, ignoring all other MCP configurations",...)` (found with `grep -a` in `@anthropic-ai/claude-code/bin/claude.exe`). Whether "all other MCP configurations" includes the account-level claude.ai connectors, and whether this applies to sub-agents, needs a real `claude -p` run, which the brief forbids. Commit `ef05331` says a headless probe showed the tool list dropping from Read + 8 Claude Docs tools to Read; that is unverifiable here.

**Evidence:** `test/skills/generate-reports.bash:117-121`, `/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe` (option-table string)

---

## Claim 20: "claude -p reads --tools \"\" as \"no tools\"."

**Location:** `test/skills/generate-reports.bash:123-124`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the CLI's documented option semantics only. It does not establish runtime behaviour, including whether MCP and Agent tools also disappear.
**Legibility-target:** for-orchestrator-synthesis

The bundled help text says `.option("--tools <tools...>",'Specify the list of available tools from the built-in set. Use "" to disable all tools, ...')`, which is direct documentary support. Under the skill's mandatory-execution rule this is capped at Unverifiable: running `claude` is forbidden by the brief. The harness side, "none" becoming an empty string argument, is confirmed by `ok 2 FIXTURE_TOOLS=none passes an empty --tools list`.

**Evidence:** `test/skills/generate-reports.bash:125-126,165`, `test/generate-reports.bats:69-78`, claude.exe option-table string

---

## Claim 21: "A stale transcript must never pair with a fresh report."

**Location:** `test/skills/generate-reports.bash:136-137`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every path through `generate_one`. The sidecar is deleted before anything can fail, and in transcript mode the report is always rewritten, by jq or by `: >`. It does not cover the reverse case: a stale *report* is left when the script aborts under `set -e` before claude runs (e.g. `fixture_prompt` or `cp` fails). In that case there is no transcript to pair with it.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/generate-reports.bash:137, :220-221
  rm -f "$transcript_path"
...
    jq -rR 'fromjson? | select(.type == "result") | .result // empty' "$transcript_path" \
      > "$report_path" 2>/dev/null || : > "$report_path"
```

Non-transcript mode: the sidecar is removed and never recreated, and the report is truncated by the redirect even if claude fails (`|| true`). Transcript mode: the claude redirect recreates the transcript and the report is always overwritten. Executed: `ok 8 transcript off: no stream-json flags, and a stale sidecar is removed`.

**Evidence:** `test/skills/generate-reports.bash:130-233`, `test/generate-reports.bats:148-158`

---

## Claim 22: "--tools stays last before the model/extra flags: an empty value must not swallow the next flag." (also bats: "--tools must stay last so an empty list cannot swallow a flag")

**Location:** `test/skills/generate-reports.bash:157-158`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the stated mechanism, as read from the commander parser bundled in the installed CLI. It does not establish runtime argv handling by executing claude, which the brief forbids.
**Legibility-target:** for-author

The rationale contradicts itself: `--tools` is *not* last, because `$model_flag` and `${CLAUDE_FLAGS}` follow it (`generate-reports.bash:198-200`). So if an empty value could swallow the next flag, `--model` would be swallowed. The bundled commander parser also does not work the way the comment assumes. For a required-value option it shifts the next argv element unconditionally as the value, so the separate `""` element is consumed. It then marks the option active-variadic, which appends only later arguments that do *not* start with `-`:

```js
// claude.exe bundled commander (minified), option parse loop
if(h.required){let u=s.shift();if(u===void 0)this.optionMissingArgument(h);this.emit(`option:${h.name()}`,u)} ... a=h.variadic?h:null;continue
```

A following `--model`/`--verbose` flag is therefore never swallowed. What the variadic `<tools...>` would swallow is a following *positional* argument, and there is none (the prompt goes on stdin). The precise version: "--tools is variadic; keep positional arguments out of the argv after it".

**Evidence:** `test/skills/generate-reports.bash:157-165,196-212`, `test/generate-reports.bats:74-76,126-127`, claude.exe bundled commander option-parse code

---

## Claim 23: "-R + fromjson? parses line by line and skips non-JSON lines (a stray warning on stdout), which would otherwise abort jq and lose the report."

**Location:** `test/skills/generate-reports.bash:218-221`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers non-JSON lines anywhere in the stream. It does not cover several `result` events in one stream: their texts would be concatenated.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/generate-reports.bash:220
    jq -rR 'fromjson? | select(.type == "result") | .result // empty' "$transcript_path" \
```

Executed on a 3-line file with a leading `Warning: stray` line. The `-rR 'fromjson? ...'` filter printed the result text and exited 0. Plain `jq -r 'select(.type=="result")...'` printed `parse error: Invalid numeric literal at line 1, column 8` and exited 4, which with `|| : > "$report_path"` would have emptied the report. Also `ok 7 FIXTURE_TRANSCRIPT=1: a non-JSON line in the stream does not lose the report`.

**Evidence:** `test/skills/generate-reports.bash:215-222`, `test/generate-reports.bats:134-146`, `LOGS/generate-reports.log`

---

## Claim 24: "Sub-agents inherit the same tool list, so they cannot read the repo either"

**Location:** `test/skills/matrix-analysis/runner.bash:5-6`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing at runtime. This is the only inline runner that grants any tool (`Agent`) while running in the caller's cwd, which is the real repo (Claim 8). If sub-agents are *not* restricted to the parent's `--tools` set, a general-purpose sub-agent could Read `test/skills/matrix-analysis/expected-verdicts.bash`.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/matrix-analysis/runner.bash:13-15
FIXTURE_TOOLS="Agent"
FIXTURE_MODE="inline"
FIXTURE_TRANSCRIPT=1
```

Whether `--tools` restricts sub-agents' tool pools is CLI runtime behaviour. Checking it needs a `claude -p` probe, which the brief forbids. This is the highest-stakes unverified trust-boundary claim in the diff. SKILL.md's "Sub-agents cannot read your filesystem" (`skills/matrix-analysis/SKILL.md:118`) is guidance to the model, not enforcement.

**Evidence:** `test/skills/matrix-analysis/runner.bash:1-20`, `test/skills/generate-reports.bash:202-213`

---

## Claim 25: "They are stored renamed so scripts/run-tests.sh, which collects every *.bats under test/, never runs them as real suites."

**Location:** `test/skills/self-eval/runner.bash:10-12`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers run-tests.sh's collector. It does not cover other tools, such as a bare `bats -r test/`, which picks up files by `.bats` extension and would also skip `.bats.in`.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/run-tests.sh:22, :63
TEST_DIR="$REPO_ROOT/test"
  done < <(find "$TEST_DIR" -name '*.bats' -print0 | sort -z)
```

`-name '*.bats'` does not match `*.bats.in`. The fixture files are stored as `.fixture-tests/skills/*.bats.in`, and `fixture_base` renames them in the temp repo only (`runner.bash:29-31`).

**Evidence:** `scripts/run-tests.sh:22,63`, `test/skills/self-eval/runner.bash:20-33`

---

## Claim 26: "Verified by a headless probe: the tool list drops from Read + 8 mcp__claude_ai_Claude_Docs__* to Read. Affects batches 1-3 as well (no reports were generated with the leak)."

**Location:** commit `ef05331`
**Type:** Reference / Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about the probe. It does not establish the connector count or that no leaked reports were ever produced on other machines.
**Legibility-target:** for-orchestrator-synthesis

The probe output is not in the repo, and re-running it needs `claude`, which the brief forbids. Consistent with the second part: no `test/skills/*/output/` directory exists in this checkout (paraphrased — no quote available because the claim concerns an absence; `ls -d test/skills/*/output` matched nothing). Those directories are gitignored (`.gitignore`: `test/skills/*/output/`), so the checkout cannot show other machines' history.

**Evidence:** `.gitignore:5`, `test/skills/generate-reports.bash:117-121`

---

## Claim 27: "every key read as \"fixture does not exist\": 10 failures, reproduced on the branch before this fix" / "clears two shellcheck warnings this batch introduced: SC2034 ... SC2115"

**Location:** commit `fa3c5c0`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 10-failure count and the two shellcheck codes. The commit's "run-tests.sh --fast: 939 ok" figure was not re-run.
**Legibility-target:** for-orchestrator-synthesis

Executed at 2026-09-24T17:09:29-07:00: `git show fa3c5c0^:scripts/health-check.sh`, with REPO_ROOT pinned to /workspace, run as `HEALTH_CHECK_SKIP_BATS=1 bash .../hc/scripts/health-check.sh`. It exited 1 with exactly 10 `fixture does not exist` lines (5 divergent-design + 5 self-eval directory keys). shellcheck on the pre-fix `generate-reports.bash` reports SC2034 and on the pre-fix `.bats` reports SC2115. At head both are clean (`shellcheck -i SC2115,SC2034 test/generate-reports.bats` rc=0; `generate-reports.bash` has no findings). The only remaining shellcheck note in scope, SC2016 at `scripts/health-check.sh:215`, is outside this diff.

**Evidence:** `scripts/health-check.sh:314-335`, `LOGS/prefix-health-check.log`

---

## Claim 28: "Under `run` or in a conditional it returned 0 for a failing report ... The checks are split into an array, not an unquoted for-list, so IFS stays unchanged and a pattern like `.*` can no longer glob-expand against the cwd."

**Location:** commit `3023a20`; `test/skills/eval-helpers.bash:78-79`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the current splitting code and its status propagation. The "before" behaviour is inferred from the base diff (`IFS=';;'` + `for check in $key_check`, unquoted, so pathname expansion applied), not executed.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/eval-helpers.bash:78-79
  IFS=';' read -ra checks <<< "$key_check"
  for check in "${checks[@]}"; do
```

The `IFS=` prefix scopes only to `read`, and `read -ra` does no pathname expansion. The status propagation was executed (Claim 10).

**Evidence:** `test/skills/eval-helpers.bash:74-144`, `LOGS/eval-fixture-allchecks.log`

---

## Claim 29: "One non-JSON line (a CLI warning on stdout mid-stream) aborted jq. The generator then lost the report ... Test-first: new cases ... failed before the change and pass after."

**Location:** commit `d700f62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the abort-and-empty mechanism and the new cases passing now. The pre-change red run was not literally replayed; the failure is shown by running the pre-change jq form on the same input.
**Legibility-target:** for-orchestrator-synthesis

Executed: the pre-change strict form `jq -r 'select(.type == "result") ...'` exits 4 on a leading non-JSON line (`parse error: Invalid numeric literal`). The generator's `|| : > "$report_path"` then empties the report, which is exactly what `generate-reports.bats:144-145`'s `diff` would reject. Both new cases pass at head (`ok 7` in each suite).

**Evidence:** `test/skills/generate-reports.bash:218-221`, `test/generate-reports.bats:134-146`, `test/skills/eval-helpers-transcript.bats:71-78`

---

## Claims Requiring Attention

### Incorrect
- **Claim 3** (`test/generate-reports.bats:272`): test name says runners are "accepted by the generator", but it only checks `runner.bash` exists. Rename it, or source each runner and apply the generator's gates.
- **Claim 18** (`test/skills/generate-reports.bash:89-94`): the Write/Edit guard is an exact-token match. `Read, Write`, `Write(*)`, `NotebookEdit`, `MultiEdit` and `Bash` all pass it, so "runners granting Write/Edit are refused" does not hold as an enforcement claim.
- **Claim 22** (`test/skills/generate-reports.bash:157-158`, `test/generate-reports.bats:126`): the comment gives the wrong mechanism. `--tools` is followed by `--model`/`CLAUDE_FLAGS` anyway, and commander never swallows a dash-flag after a variadic option. The real hazard is positional arguments after `--tools`.

### Stale
- **Claim 15b** (`test/skills/generate-reports.bash:32-33`): "subject.<ext> ... in both modes" predates tree mode, which passes `.`.

### Mostly Accurate
- **Claim 2** (`test/generate-reports.bats:74-76`): "--tools is the last argument" holds only when `CLAUDE_MODEL`/`CLAUDE_FLAGS` are unset. With `CLAUDE_MODEL` exported the test fails (executed).
- **Claim 8** (inline runners, e.g. `test/skills/cowen-critique/runner.bash:2-3`): claude runs in the caller's cwd, which is normally but not necessarily the real repo.
- **Claim 16** (`test/skills/generate-reports.bash:43-44`): ".fixture-* files". Directories such as `.fixture-tests/` are removed too, and self-eval relies on that.

### Unverifiable
- **Claim 9** (`test/skills/eval-helpers-transcript.bats:3-6`): needs a real stream-json run to confirm `parent_tool_use_id` and the `Agent` tool name.
- **Claim 17b** (`test/skills/generate-reports.bash:48-50`): "cannot reach expected-verdicts" depends on the CLI refusing absolute-path reads outside cwd under `-p`. Needs a probe.
- **Claim 19b** (`test/skills/generate-reports.bash:117-121`): needs a probe to confirm `--strict-mcp-config` drops claude.ai connectors, including in sub-agents.
- **Claim 20** (`test/skills/generate-reports.bash:123-124`): `--tools ""` = no tools. The CLI help says so, but this is not executed.
- **Claim 24** (`test/skills/matrix-analysis/runner.bash:5-6`): whether sub-agents inherit `--tools`. This is the key trust-boundary assumption for the one inline runner with a tool, and needs a probe.
- **Claim 26** (commit `ef05331`): the probe result is not reproducible without running claude.

---

## Goal-Alignment Note

- **Success criterion (verbatim):** a code-fact-check report saved to /workspace/docs/reviews/code-fact-check-report-skill-fixtures-r2.md, following the SKILL.md schema, with a `Commit: 04c0746` line at the top. Every claim carries a Legibility-target field: Incorrect/Stale/Mostly Accurate → for-author; Verified/Unverifiable → for-orchestrator-synthesis. End the report with the Goal-Alignment Note (canonical form, restating the Success criterion verbatim).
- **Answered:** All nine claim groups from the brief are covered. They map to claims 18/17a, 15a/15b/16/8, 19a/19b/20/22, 21, 23, 10-14, 5/6, 1/27, and the commits (6, 7, 26-29). Every verdict that could be executed without calling `claude` was executed. Execution logs are in the session scratchpad; no repo file other than this report was written, and nothing was committed.
- **Out of scope:** I did not re-run `run-tests.sh --fast` (fa3c5c0's "939 ok"). I did not check fixture data, eval-criteria, expected-verdicts or `*-eval.bats` content, per the brief. The format-suite edits (`*-format.bats` title-window widening) were only checked where a commit message made a claim about them.
- **Escalate:** Claims 24 and 17b are the unverified trust-boundary assumptions: matrix-analysis sub-agents running in the real repo, and absolute-path reads outside the temp repo. Settling them needs a one-off headless `claude -p` probe on the host, which this sandbox brief does not permit.
