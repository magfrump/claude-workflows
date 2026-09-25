**Commit:** 0a81388
**Replication:** k=1 (loop pass, decision 031)

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows), branch `skill-fixtures`
**Scope:** pass-2 fix diff `git diff 4371ec0..0a81388 -- . ':!docs'` (commits a2972bf, a75ba3e, c90b97a, and their messages), plus the "948 ok" line that 0a81388 added to `docs/reviews/code-review-rubric-2026-09-24-skill-fixtures.md`
**Checked:** 2026-09-24
**Total claims checked:** 39
**Summary:** 27 verified, 5 mostly accurate, 0 stale, 0 incorrect, 7 unverifiable

Method notes:
- All executed checks ran against a `git archive 0a81388 test skills` export in the session scratchpad (`$S/p2-0a81388`), not against the working tree. The working tree has moved since 0a81388 (9ab81b4 changed `test/generate-reports.bats:321`, and `test/skills/generate-reports.bash` changed on disk during this review), so it is not the commit under review.
- No `claude` model call was made. The only live `claude` invocations were `claude --help` and two argv-parse probes that fail on an unknown option before any request is sent.
- `docs/reviews/hallucination-patterns.md` was read. No logged pattern resembles any claim here.
- `$S` = `/tmp/claude-1000/-workspace/486d17ef-98de-46e2-88d8-3db5f5c05a49/scratchpad`. Execution logs are in `docs/reviews/execution-logs/cfc-skill-fixtures-pass2-*.log`.

Executed commands referenced below:
- **E1** `bats test/generate-reports.bats test/skills/eval-helpers-empty-report.bats test/skills/eval-helpers-transcript.bats`. cwd `$S/p2-0a81388`, exit 0, 2026-09-25T00:48:56Z (UTC). Result: 33/33 ok. Log: `docs/reviews/execution-logs/cfc-skill-fixtures-pass2-bats.log`
- **E2** `bats test/skills/eval-helpers-empty-report.bats` with the 0a81388 test file and the **4371ec0** `eval-helpers.bash`. cwd `$S/p2-4371ec0`, exit 1, 2026-09-25T00:49:08Z. Result: `not ok 1 an empty report fails a clean-negative fixture`; tests 2 and 3 ok. Log: `...-pass2-testfirst.log`
- **E3** `time bats <4371ec0>/test/generate-reports.bats`, then `time bats <0a81388>/test/generate-reports.bats`. cwd `/workspace`, both exit 0, 2026-09-25T00:49:08Z. Result: old 9.875 s total, new 1.404 s total. Log: `...-pass2-timing.log`
- **E4** `scripts/run-tests.sh --fast`. cwd `/workspace` at HEAD cb8076b (its test diff from 0a81388 is one changed assertion, with no tests added or removed), exit 0, 2026-09-25T00:49:37Z. Result: 948 `ok`, 0 `not ok`. Log: `...-pass2-fast.log`
- **E5** `claude -p --tools "" --bogus-flag-xyz </dev/null` and `claude -p --tools Read --bogus-flag-xyz </dev/null`. cwd `$S`, both exit 1, 2026-09-25T00:51:44Z, claude 2.1.282. Both print `error: unknown option '--bogus-flag-xyz'`. Log: `...-pass2-tools-argv.log`
- **E6** 0a81388 generator, tree-mode runner whose `fixture_base` is `false`, stale `OLD` report pre-seeded, stub `claude`. cwd `$S/stale`, exit 1, 2026-09-25T00:52:25Z. Result: the output dir is empty afterwards and the stub never ran. Log: `...-pass2-stale-report.log`
- **E7** `bats -f "stale report" test/generate-reports.bats` from 0a81388, with the **4371ec0** generator swapped in. cwd `$S/p2-oldgen`, exit 0. Result: `ok 1 a failed claude run leaves no stale report behind`. Log: `...-pass2-stale-oldgen.log`
- **E8** `find . -path ./.git -prune -o -type f -print | wc -l`. cwd `/workspace`, exit 0. Result: 395022 (not captured to a file; the number is recorded here).
- **E9** `claude --help`. cwd `$S`/`/tmp`, exit 0, claude 2.1.282. The relevant help text is quoted inline in claims 4b and 14b. This is documentation evidence, not execution of the flag's behaviour.

---

## Claim 1: "in a copy of the repo layout under a temp dir so no report is ever written into the real test/skills/*/output/"

**Location:** `test/generate-reports.bats:3-5`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every test that runs `$GEN`. It does not establish the behaviour of the one test (`:332`) that sources committed runners from the real repo; that test runs no generator and writes no report.
**Legibility-target:** for-orchestrator-synthesis

`cp "$REPO_ROOT/test/skills/generate-reports.bash" ... "$TEST_TMPDIR/test/skills/"` and `GEN="$TEST_TMPDIR/test/skills/generate-reports.bash"` (`test/generate-reports.bats:12-14`). The generator derives its output from its own location: `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"` ... `OUTPUT_DIR="$SCRIPT_DIR/${SKILL}/output"` (`test/skills/generate-reports.bash:75,84`). So every report lands under `$TEST_TMPDIR`.

**Evidence:** `test/generate-reports.bats:12-14`, `test/skills/generate-reports.bash:75-84`

---

## Claim 2: "the stub lists its working directory, which must not be the repo root (395k files there made this suite ~14 s)"

**Location:** `test/generate-reports.bats:15-17`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the file count and the order of magnitude of the old suite's runtime on this machine. It does not reproduce the exact ~14 s figure, which depends on the machine and on cache state.
**Legibility-target:** for-author

E8 counted 395022 files, using the same `find ... -prune` shape the stub uses (`printf 'FILES: %s\n' "\$(find . -path ./.git -prune -o -type f -print ...)"`, `test/generate-reports.bats:29`). E3 timed the 4371ec0 suite from `/workspace` at 9.875 s, not ~14 s. The mechanism (the stub walks the repo root) and the conclusion (the suite is slow when cwd is the repo root) both hold. The figure is high for this run. A precise version would say "~10-14 s".

**Evidence:** `test/generate-reports.bats:15-19,27-30`; E3 `docs/reviews/execution-logs/cfc-skill-fixtures-pass2-timing.log`; E8

---

## Claim 3: "--tools is the last argument, so an empty value leaves "--tools " at the end of the recorded argv line."

**Location:** `test/generate-reports.bats:90-91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test environment, where `setup` runs `unset CLAUDE_MODEL CLAUDE_FLAGS` (`:18`). It does not hold in a real run with `CLAUDE_MODEL` or `CLAUDE_FLAGS` set: those expand after `--tools`.
**Legibility-target:** for-orchestrator-synthesis

`claude_args+=(--tools "$TOOLS_ARG")` is the last `claude_args` append (`test/skills/generate-reports.bash:154`). The call is `claude "${claude_args[@]}" $model_flag ${CLAUDE_FLAGS:-}` (`:190-192`), and both trailing expansions are empty under the test's `unset`. E1: `ok 3 FIXTURE_TOOLS=none passes an empty --tools list`.

**Evidence:** `test/skills/generate-reports.bash:145-154,189-193`; `test/generate-reports.bats:18,85-94`; E1 log

---

## Claim 4a: test name "every mode passes --strict-mcp-config --restricted --safe-mode"

**Location:** `test/generate-reports.bats:122`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the argv for inline, repo and tree modes. It does not establish what the flags do (claims 4b and 14b).
**Legibility-target:** for-orchestrator-synthesis

`local -a claude_args=(-p --system-prompt-file "$SKILL_FILE"` / `--strict-mcp-config --restricted --safe-mode)` (`test/skills/generate-reports.bash:145-146`) is built once for every mode. The test loops over `for mode in inline repo tree` (`test/generate-reports.bats:128`). E1: `ok 6`.

**Evidence:** `test/skills/generate-reports.bash:145-146`; `test/generate-reports.bats:122-138`; E1 log

---

## Claim 4b: "Without --strict-mcp-config, claude.ai connectors (write-capable Claude Docs tools) are exposed even under --tools "" and in sub-agents. --restricted confines the file tools to the temp dir and drops the user's settings and hooks; --safe-mode drops memory files, skills and plugins."

**Location:** `test/generate-reports.bats:123-126`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers agreement with the claude 2.1.282 `--help` text. It does not establish runtime behaviour; the connector-exposure half rests on an earlier probe that has no captured transcript in the repo.
**Legibility-target:** for-orchestrator-synthesis

The CLI help (E9) supports the flag descriptions: `--restricted ... ignores user, project and local settings files (managed settings and --settings still apply ...). Also confines the file tools to the working directories` and `--safe-mode  Start with all customizations (CLAUDE.md, skills, installed plugins, hooks, MCP servers, custom commands and agents ...) disabled ... built-in tools and plugins ... work normally`. Two nuances follow. Hooks in *managed* settings survive `--restricted`. `--safe-mode` drops *installed* plugins but not built-in ones, which matches the commit's "plugins (6 -> 2)". Blocker: execution required, and a paid `claude` run is excluded by the brief. Checking the MCP-exposure half would need a stream-json init event with and without `--strict-mcp-config`.

**Evidence:** `test/generate-reports.bats:123-126`; E9 (`claude --help`, `--restricted`/`--safe-mode` entries)

---

## Claim 5: "Every spelling the old Write/Edit denylist let through (FC 21, 2026-09-24)."

**Location:** `test/generate-reports.bats:277`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed spelling against the 4371ec0 denylist. It does not establish whether the CLI would have accepted each spelling.
**Legibility-target:** for-author

The old denylist was:

```bash
# git show 4371ec0:test/skills/generate-reports.bash:89-94
case ",$FIXTURE_TOOLS," in
  *,Write,*|*,Edit,*)
    echo "Error: $RUNNER_FILE: FIXTURE_TOOLS must not include Write or Edit" >&2
```

`Edit` in the list at `:279` (`"write" "Edit" "MultiEdit"`) matches `*,Edit,*`, so the old denylist **refused** it. The other eight spellings (`Read,Write`, `Read, Write`, `Write(*)`, `write`, `MultiEdit`, `NotebookEdit`, `Bash`, `Read,Bash(git:*)`) did get through it. Precise version: "every spelling ... let through, plus Edit".

**Evidence:** `test/generate-reports.bats:276-288`; `git show 4371ec0:test/skills/generate-reports.bash` lines 89-94

---

## Claim 6: new test names at `:75`, `:85`, `:276`, `:290`, `:301`, `:312`

**Location:** `test/generate-reports.bats:75-323`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name as a description of what its body asserts, and those assertions passing at 0a81388. It does not establish that `:312` ("a failed claude run leaves no stale report behind") discriminates the C3 `rm -f` fix: E7 shows it also passes on the 4371ec0 generator, whose `) > "$out_path"` redirect already truncated the report when `claude` failed. The fix-specific path (an earlier step failing) is covered by claim 17, not by this test.
**Legibility-target:** for-orchestrator-synthesis

E1 reports `ok 2 inline mode: claude runs in an empty temp directory, not the caller's`, `ok 3 FIXTURE_TOOLS=none passes an empty --tools list`, `ok 17 a runner naming any tool outside the allowlist is refused`, `ok 18 an inline runner granting a file tool is refused`, `ok 19 a dotted fixture name with no plain extension reaches the model as 'subject'` and `ok 20 a failed claude run leaves no stale report behind`. Each body asserts what its name states. For example, `:80-82` asserts `LS: \n` and `FILES: \n` (an empty cwd), and `:308-309` asserts `Review subject please` with no `inaccurate`. At 0a81388, `:321` ends the test on `! grep -q "Old report"`. Because that line is the test's last command, it is armed (see 9ab81b4, which later changed it to `run` + status anyway).

**Evidence:** `test/generate-reports.bats:75-94,276-323`; E1 log; E7 `docs/reviews/execution-logs/cfc-skill-fixtures-pass2-stale-oldgen.log`

---

## Claim 7: "every committed fixture set has a runner the generator accepts" / "Each runner is sourced and checked against the same contract the generator applies"

**Location:** `test/generate-reports.bats:332-336`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the runner contract (`reset_runner_settings` → source → `check_runner_settings`), the same three calls the generator makes. It does not establish the generator's other preconditions: `skills/<skill>/SKILL.md` existing (`generate-reports.bash:87`) and `jq` being present when `FIXTURE_TRANSCRIPT=1` (`:103`).
**Legibility-target:** for-orchestrator-synthesis

The test runs `source "$REPO_ROOT/test/skills/runner-contract.bash"` / `reset_runner_settings` / `source "$skill_dir/runner.bash"` / `check_runner_settings "$skill"` (`test/generate-reports.bats:348-351`). The generator runs `source "$SCRIPT_DIR/runner-contract.bash"` / `reset_runner_settings` / `source "$RUNNER_FILE"` / `check_runner_settings "$RUNNER_FILE" || exit 1` (`test/skills/generate-reports.bash:97-101`). E1: `ok 22`.

**Evidence:** `test/generate-reports.bats:332-357`; `test/skills/generate-reports.bash:87-106`; E1 log

---

## Claim 8: header and test names of eval-helpers-empty-report.bats ("absence-only checks ... all pass on empty text"; "an empty report fails a clean-negative fixture"; "a non-empty clean report still passes"; "an empty report still passes a max_claims:0 fixture")

**Location:** `test/skills/eval-helpers-empty-report.bats:3-7,33,40,46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named behaviours and, for `no_severity:` and `no_pattern:`, that the pre-fix helpers passed empty text. It does not execute `no_verdict:` or `no_field:` on empty text (claim 11 covers those statically).
**Legibility-target:** for-orchestrator-synthesis

E1: `ok 24`, `ok 25`, `ok 26`. E2 runs the same file against the 4371ec0 helpers: `not ok 1 an empty report fails a clean-negative fixture`, while tests 2 and 3 pass. So the fixture `KEY_CHECK["tc-clean.py"]="no_severity:Critical|High;no_pattern:injection"` (`:19`) passed on an empty report before the fix.

**Evidence:** `test/skills/eval-helpers-empty-report.bats:1-50`; E1 log; E2 `docs/reviews/execution-logs/cfc-skill-fixtures-pass2-testfirst.log`

---

## Claim 9: "top-level events carry "parent_tool_use_id": null, and a sub-agent's own events carry its parent's id (checked against real runs, 2026-09-24)"

**Location:** `test/skills/eval-helpers-transcript.bats:3-7`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the event shape in a committed real stream-json transcript. It does not establish the date of the author's own check, or that `claude -p` runs under the fixture harness flags produce the identical shape.
**Legibility-target:** for-orchestrator-synthesis

In `runs/review-arms/e7-fable-3x/mfc-corpus/rep2/transcript.jsonl`, 42 events carry `"parent_tool_use_id":null`. The id `toolu_01AecQhFFGqJpqixD1vTNLaW` is both the id of a top-level `Agent`/`Task` `tool_use` and the `parent_tool_use_id` of 25 later events (paraphrased — no quote available because the evidence is jq aggregation over a multi-megabyte JSONL, not a single line).

**Evidence:** `test/skills/eval-helpers-transcript.bats:3-7`; `runs/review-arms/e7-fable-3x/mfc-corpus/rep2/transcript.jsonl`

---

## Claim 10: "Args: $1 = skill name (any skill with test/skills/<skill>/expected-verdicts.bash)" and "Delegate to the skill's format suite, test/skills/<skill>-format.bats"

**Location:** `test/skills/eval-helpers.bash:7,145`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the paths the two functions build. It does not establish that every skill has a `-format.bats` file.
**Legibility-target:** for-orchestrator-synthesis

`local verdicts_file="${BATS_TEST_DIRNAME}/${skill}/expected-verdicts.bash"` (`:10`) and `bats "${BATS_TEST_DIRNAME}/${skill}-format.bats"` (`:146`) are both parameterized on `$skill`. 24 `test/skills/*-format.bats` files exist.

**Evidence:** `test/skills/eval-helpers.bash:7-10,144-147`

---

## Claim 11: "An empty report is what generate-reports.bash leaves when claude fails. The absence-only checks (no_severity:, no_verdict:, no_field:, no_pattern:) and a skipped format_check all pass on it ... Only a fixture that expects no claims at all (max_claims:0 ...) may have an empty report."

**Location:** `test/skills/eval-helpers.bash:74-78`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard at `:79` and the pass-on-empty behaviour of the four named assertions and of the format suites' loaders. It does not establish that a report with only whitespace counts as empty: the guard tests `-z "$REPORT_CONTENT"`, and `load_eval_report` sets that to `""` only when the file is zero bytes (`:41`).
**Legibility-target:** for-orchestrator-synthesis

The guard `if [ -z "$REPORT_CONTENT" ] && [[ ";$key_check;" != *";max_claims:0;"* ]]; then` (`:79`) fires before any check runs. The absence checks grep for hits and fail only on a non-empty match, for example `hits=$(echo "$REPORT_CONTENT" | grep -iE "$pattern" || true)` in `assert_report_not_matches` (eval-helpers.bash, function body at `:286-294`, read). The same holds for `assert_no_severity`, `assert_no_verdict` and `assert_no_field` (paraphrased — no quote available because the pattern repeats across sibling functions at `:210-274`). Format suites skip on empty text: `if [ -z "$REPORT_CONTENT" ]; then skip "Report is empty"` (`test/skills/helpers.bash:65-66`), and `load_report` skips on zero claims (`:25-26`). "What generate-reports.bash leaves when claude fails" is confirmed by E6/E7 (`WARNING: empty report`). E1 and E2 cover the executed half.

**Evidence:** `test/skills/eval-helpers.bash:34-52,58-155`; `test/skills/helpers.bash:17-27,59-68`; E1, E2 logs

---

## Claim 12: "inline ... claude runs in an empty temp directory" / "Every mode runs in a fresh temp directory: empty for inline, a minimal git repo holding the fixture for repo and tree."

**Location:** `test/skills/generate-reports.bash:18-19,156-157`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the working directory `claude` runs in for all three modes. It does not establish cleanup on a `set -e` abort: the `trap ... RETURN` at `:161` does not fire when the script exits mid-function (E6 leaves its temp dir behind).
**Legibility-target:** for-orchestrator-synthesis

`temp_dir=$(mktemp -d)` (`:159`); inline only builds `stdin_text` (`:164-165`); repo/tree copy into `$temp_dir` and `git init` (`:167-184`); then `(cd "$temp_dir" && printf '%s' "$stdin_text" | claude ...` (`:189`). E1: `ok 2` (inline `LS:` and `FILES:` empty), `ok 4` (`LS: subject.txt`), `ok 11` (tree).

**Evidence:** `test/skills/generate-reports.bash:156-193`; E1 log

---

## Claim 13: "fixture_prompt receives subject.<ext> (the extension alone tells the model the language; "subject" when the name has no plain extension)" / "A dotted name with no real extension (tc-2.4-inaccurate) gets no suffix"

**Location:** `test/skills/generate-reports.bash:34-37,132-134`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "plain extension" as defined by the code (1-5 alphanumerics after the last dot). It does not establish that such a suffix is never itself descriptive (e.g. `tc-3.2` → `subject.2`).
**Legibility-target:** for-orchestrator-synthesis

`local subject_name="subject" ext="${fixture_name##*.}"` ... `elif [ "$ext" != "$fixture_name" ] && [[ "$ext" =~ ^[A-Za-z0-9]{1,5}$ ]]; then subject_name="subject.$ext"` (`:135-140`). For `tc-2.4-inaccurate`, ext is `4-inaccurate` and fails the regex. E1: `ok 5` (`LS: subject.py`), `ok 19` (`Review subject please`).

**Evidence:** `test/skills/generate-reports.bash:132-140`; `test/generate-reports.bats:109-120,301-310`; E1 log

---

## Claim 14a: "Every mode runs claude in a fresh temp directory, never in this repo"

**Location:** `test/skills/generate-reports.bash:54-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the process cwd. The file-tool confinement that makes the cwd a boundary is claim 14b.
**Legibility-target:** for-orchestrator-synthesis

See claim 12: `(cd "$temp_dir" && ... | claude ...` (`:189`), with `temp_dir=$(mktemp -d)` (`:159`), in every mode. E1 tests 2, 4 and 11 assert that cwd is not under `$TEST_TMPDIR/test`.

**Evidence:** `test/skills/generate-reports.bash:158-193`; E1 log

---

## Claim 14b: "--restricted  file tools confined to that directory, whatever the user's permission settings allow; user and project settings files (and so the user's hooks) are ignored / --safe-mode  no memory files, user skills, plugins, hooks or custom agents / --strict-mcp-config  no account MCP connectors (Claude Docs create/update/delete leaked into every run without it, even under --tools "" ...)"

**Location:** `test/skills/generate-reports.bash:56-64`
**Type:** Behavioral / Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers consistency with the claude 2.1.282 `--help` text. It does not establish runtime behaviour, and in particular not the connector leak or its suppression.
**Legibility-target:** for-orchestrator-synthesis

The help text (E9) agrees with each description: `--restricted ... ignores user, project and local settings files ... Also confines the file tools to the working directories`, `--safe-mode ... (CLAUDE.md, skills, installed plugins, hooks, MCP servers, custom commands and agents ...) disabled`, and `--strict-mcp-config  Only use MCP servers from --mcp-config`. Two nuances: managed-settings hooks still apply, and built-in plugins stay (claim 4b). The commit itself says "Hook suppression rests on the CLI help text; the probe could not observe hook injection directly" (a75ba3e body). Blocker: execution required; paid `claude` runs are excluded by the brief.

**Evidence:** `test/skills/generate-reports.bash:54-67`; E9; `git show -s a75ba3e`

---

## Claim 14c: "--tools  the runner's list, never a write-capable tool (runner-contract.bash)"

**Location:** `test/skills/generate-reports.bash:65-66`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fact that FIXTURE_TOOLS can only name allowlisted tools, and that the allowlist has no built-in write tool. It does not establish anything about `CLAUDE_FLAGS`: a caller can append its own `--tools` or other flags after the runner's (`:192`).
**Legibility-target:** for-orchestrator-synthesis

`RUNNER_ALLOWED_TOOLS=(Read Grep Glob WebSearch WebFetch Agent)` (`test/skills/runner-contract.bash:14`). Every comma-separated token must equal one of them (`:46-55`). `TOOLS_ARG="$FIXTURE_TOOLS"` (`generate-reports.bash:110`) is passed only after `check_runner_settings ... || exit 1` (`:101`). E1: `ok 17` covers nine non-allowlisted spellings, all refused.

**Evidence:** `test/skills/runner-contract.bash:14,43-67`; `test/skills/generate-reports.bash:101,110-111,154,192`; E1 log

---

## Claim 14d: "sub-agents inherit it. So the model cannot reach expected-verdicts.bash or eval-criteria.md."

**Location:** `test/skills/generate-reports.bash:66-67`
**Type:** Behavioral / Invariant
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** The conclusion depends on 14b (runtime confinement) and on sub-agent `--tools` inheritance. Neither is observable without a paid run. The claim also does not address `WebFetch`, which `--restricted` removes only "unless --tools names them", and which the allowlist permits.
**Legibility-target:** for-orchestrator-synthesis

The inheritance claim rests on the canary probe described in a75ba3e's body ("A general-purpose sub-agent under --tools Agent got 'No such tool available: Read ... in subagents as well as here'"). No transcript of that probe is committed (paraphrased — no quote available because the claim covers the absence of a captured artefact; `git ls-files` shows no probe log). Blocker: execution required; paid run excluded.

**Evidence:** `test/skills/generate-reports.bash:54-67`; `git show -s a75ba3e`

---

## Claim 15: ""none" is explicit so a runner that forgets FIXTURE_TOOLS still errors above"

**Location:** `test/skills/generate-reports.bash:108`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers a runner that never assigns FIXTURE_TOOLS. It does not establish the behaviour of a runner that assigns it an empty string explicitly (same outcome, refused).
**Legibility-target:** for-orchestrator-synthesis

`reset_runner_settings` sets `FIXTURE_TOOLS=""` (`runner-contract.bash:19`), and `check_runner_settings` fails on `if [ -z "$FIXTURE_TOOLS" ] || ! declare -F fixture_prompt` (`:30-32`) before the `none` → `""` mapping at `generate-reports.bash:110-111`.

**Evidence:** `test/skills/runner-contract.bash:18-33`; `test/skills/generate-reports.bash:98-111`

---

## Claim 16a: "An empty --tools value is its own argv element; the CLI ... does not consume the flag after it."

**Location:** `test/skills/generate-reports.bash:152-153`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the argv shape and the CLI's parsing of an option-looking argument after `--tools ""` (claude 2.1.282). It does not establish the behaviour for a *non-flag* argument after `--tools`: the help shows `--tools <tools...>` as variadic, so a bare word in `CLAUDE_FLAGS` placed right after it would be consumed as a tool name.
**Legibility-target:** for-orchestrator-synthesis

`claude_args+=(--tools "$TOOLS_ARG")` (`:154`) is a quoted array element, so `""` survives as its own argv entry. E1 `ok 3` records `--tools ` followed by a newline. E5: `claude -p --tools "" --bogus-flag-xyz` gives `error: unknown option '--bogus-flag-xyz'`, the same as with `--tools Read`. The following flag was parsed as an option, not taken as a tool value.

**Evidence:** `test/skills/generate-reports.bash:152-154`; E1 log; E5 `docs/reviews/execution-logs/cfc-skill-fixtures-pass2-tools-argv.log`

---

## Claim 16b: "claude -p reads --tools "" as "no tools"" / "the CLI reads it as "no tools""

**Location:** `test/skills/generate-reports.bash:109,152-153`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers agreement with the CLI help. It does not establish the runtime tool list, which would need an init event from a real run.
**Legibility-target:** for-orchestrator-synthesis

E9 help: `--tools <tools...>  Specify the list of available tools from the built-in set. Use "" to disable all tools`. Blocker: execution required (a `system/init` stream-json event); a paid run is excluded.

**Evidence:** `test/skills/generate-reports.bash:109,152-154`; E9

---

## Claim 17: "Neither a previous run's report nor its transcript may survive to be scored as this run's, whichever step below fails."

**Location:** `test/skills/generate-reports.bash:121-123`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the early-step failure path (`fixture_base` failing under `set -e`) and the claude-failure path. It does not establish anything about other fixtures in the same batch: an abort mid-batch leaves the later fixtures' old reports in place, because they are never reached.
**Legibility-target:** for-orchestrator-synthesis

`rm -f "$report_path" "$transcript_path"` (`:123`) runs first in `generate_one`, before `fixture_prompt`, `mktemp`, `fixture_base`, `cp` and `git`. In E6 a tree runner whose `fixture_base` is `false` aborts the script (exit 1) before the stub runs, and the output dir is empty afterwards, so the pre-seeded `OLD` report is gone. The claude-failure path writes via `) > "$out_path" ... || true` (`:193`) and, for transcripts, `|| : > "$report_path"` (`:201`).

**Evidence:** `test/skills/generate-reports.bash:115-209`; E6 `docs/reviews/execution-logs/cfc-skill-fixtures-pass2-stale-report.log`

---

## Claim 18: "A run that died before emitting one leaves an empty report (warned below). -R + fromjson? parses line by line and skips non-JSON lines"

**Location:** `test/skills/generate-reports.bash:196-199`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the transcript branch only (`FIXTURE_TRANSCRIPT=1`). It does not establish the report content when several `result` events are present: all of them would be concatenated.
**Legibility-target:** for-orchestrator-synthesis

`jq -rR 'fromjson? | select(.type == "result") | .result // empty' "$transcript_path" > "$report_path" 2>/dev/null || : > "$report_path"` (`:200-201`). With no result event this writes nothing, and the `[ -s ]` check at `:204` then warns. E1: `ok 7` and `ok 8` (a stray non-JSON line keeps the report).

**Evidence:** `test/skills/generate-reports.bash:195-208`; E1 log

---

## Claim 19: "WARNING: empty report generated (eval_fixture will fail it)"

**Location:** `test/skills/generate-reports.bash:207`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the interaction with `eval_fixture`'s empty-report guard. It does not establish outcomes for suites that call assertions directly rather than through `eval_fixture`.
**Legibility-target:** for-author

The guard exempts max_claims:0 fixtures: `if [ -z "$REPORT_CONTENT" ] && [[ ";$key_check;" != *";max_claims:0;"* ]]` (`test/skills/eval-helpers.bash:79`). E1 `ok 26` passes an empty report on such a fixture. Nine `max_claims:0` entries exist across 2 expected-verdicts files (paraphrased — no quote available because the count is a grep aggregate over `test/skills/*/expected-verdicts.bash`). Precise version: "eval_fixture will fail it unless the fixture expects max_claims:0".

**Evidence:** `test/skills/generate-reports.bash:204-208`; `test/skills/eval-helpers.bash:74-82`

---

## Claim 20: "Sub-agents inherit the session's --tools, so they get none either (canary probe, 2026-09-24)"

**Location:** `test/skills/matrix-analysis/runner.bash:5-6`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond the runner's own settings. This runner sets `FIXTURE_TOOLS="Agent"` (`:13`), so "none" means no file tools, not that sub-agents have no tools at all.
**Legibility-target:** for-orchestrator-synthesis

Same basis as claim 14d: an uncommitted canary probe cited in a75ba3e's body. Blocker: execution required; paid run excluded.

**Evidence:** `test/skills/matrix-analysis/runner.bash:1-15`; `git show -s a75ba3e`

---

## Claim 21: "The runner.bash contract, shared by generate-reports.bash and the fast test that checks every committed runner (test/generate-reports.bats) ... Then: reset_runner_settings; source <runner.bash>; check_runner_settings <label>"

**Location:** `test/skills/runner-contract.bash:1-6`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two callers named. It does not claim that there are no other callers (grep finds none).
**Legibility-target:** for-orchestrator-synthesis

`source "$SCRIPT_DIR/runner-contract.bash"` (`generate-reports.bash:97`) and `source "$REPO_ROOT/test/skills/runner-contract.bash"` (`test/generate-reports.bats:348`), each followed by the documented three-step sequence (see claim 7).

**Evidence:** `test/skills/runner-contract.bash:1-6`; `test/skills/generate-reports.bash:96-101`; `test/generate-reports.bats:346-352`

---

## Claim 22a: "Anything else, including ... ("Read, Write", "Write(*)", "Bash"), is refused: this is an allowlist, not a Write/Edit denylist."

**Location:** `test/skills/runner-contract.bash:8-10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exact-token matching after splitting on commas. It does not establish that a trailing comma is refused: `"Read,"` splits to `(Read)` under `read -ra` and is accepted.
**Legibility-target:** for-orchestrator-synthesis

`IFS=',' read -ra tools <<< "$FIXTURE_TOOLS"` ... `[ "$tool" = "$allowed" ] && ok=1` ... `if [ -z "$ok" ]; then echo "Error: ... FIXTURE_TOOLS may only name ..." >&2; return 1` (`:46-55`). `"Read, Write"` yields the token `" Write"`, which matches nothing. E1: `ok 17`.

**Evidence:** `test/skills/runner-contract.bash:43-67`; E1 log

---

## Claim 22b: "a spelling the CLI would also accept ("Read, Write", "Write(*)", "Bash")"

**Location:** `test/skills/runner-contract.bash:9`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about CLI parsing of these spellings. `Bash` is a documented tool name (the help's own example is `"Bash,Edit,Read"`); how the CLI treats `"Read, Write"` and `"Write(*)"` is not established.
**Legibility-target:** for-orchestrator-synthesis

The E9 help text lists tool-name syntax only as `"Bash,Edit,Read"`. Blocker: execution required (an init event per spelling); paid run excluded.

**Evidence:** `test/skills/runner-contract.bash:8-10`; E9

---

## Claim 23: "Sub-agents inherit the session's --tools (checked by a canary probe on 2026-09-24 ...), so Agent adds dispatch, not file access."

**Location:** `test/skills/runner-contract.bash:10-13`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Same basis as claims 14d and 20. It does not establish behaviour for sub-agent types other than general-purpose, or for `Agent` combined with `Read` in repo/tree mode, where sub-agents would inherit `Read`.
**Legibility-target:** for-orchestrator-synthesis

The probe is described only in the a75ba3e message, and its output is not committed (paraphrased — no quote available because the claim covers an absent artefact). Blocker: execution required; paid run excluded.

**Evidence:** `test/skills/runner-contract.bash:8-14`; `git show -s a75ba3e`

---

## Claim 24: "Clear the settings a runner is expected to set, so a runner that forgets one fails check_runner_settings instead of inheriting a previous runner's value."

**Location:** `test/skills/runner-contract.bash:16-17`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four names cleared by `reset_runner_settings`. It does not establish any case where two runners are sourced into one shell: the generator sources one runner per process, and the bats test sources each runner in a subshell, so in practice the reset guards against inherited *environment* values.
**Legibility-target:** for-author

`FIXTURE_TOOLS=""`, `FIXTURE_MODE=""`, `FIXTURE_TRANSCRIPT=""`, `unset -f fixture_prompt fixture_base` (`:19-22`). Forgetting FIXTURE_TOOLS, FIXTURE_MODE or fixture_prompt does fail (`:30-41`). Forgetting the optional `FIXTURE_TRANSCRIPT` normalizes to 0 (`""|0) FIXTURE_TRANSCRIPT=0`, `:70`), and forgetting the optional `fixture_base` means none is called (`generate-reports.bash:168`). Neither fails. Precise version: "...so a runner that forgets a required one fails, and an optional one falls back to its default, instead of inheriting a previous value".

**Evidence:** `test/skills/runner-contract.bash:16-77`; `test/skills/generate-reports.bash:167-170`

---

## Claim 25: "Validate the settings a sourced runner left behind. Prints the first problem and returns 1. On success, normalizes FIXTURE_TRANSCRIPT to 0 or 1."

**Location:** `test/skills/runner-contract.bash:25-27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function body to its final `esac` (`:28-77`, read). It does not establish the exit status under a caller's `set -e` without `||`. Both callers use `|| exit 1` or `if !`, which suspends errexit inside the function.
**Legibility-target:** for-orchestrator-synthesis

Each failure branch does `echo "Error: ..." >&2` then `return 1` (`:31-32`, `:38-39`, `:53-54`, `:61-62`, `:73-74`), and the final `case` sets `FIXTURE_TRANSCRIPT=0` or leaves `1` (`:69-76`). E1: `ok 10` (bad FIXTURE_TRANSCRIPT refused), `ok 21` (unknown mode refused), `ok 22`.

**Evidence:** `test/skills/runner-contract.bash:25-77`; E1 log

---

## Claim 26: "Inline fixtures arrive in the prompt, and the run's working directory is empty, so a file tool can only be a mistake."

**Location:** `test/skills/runner-contract.bash:56-57`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the inline branch of `generate_one`. It does not cover `CLAUDE_FLAGS` such as `--add-dir`, which could widen the reachable directories.
**Legibility-target:** for-orchestrator-synthesis

`stdin_text="$(printf '%s\n\n%s' "$prompt" "$(cat "$fixture_path")")"` (`generate-reports.bash:165`) means inline never copies anything into `$temp_dir`. E1: `ok 2` (empty `LS:`/`FILES:`) and `ok 18` (inline Read/Grep/Glob refused).

**Evidence:** `test/skills/runner-contract.bash:56-65`; `test/skills/generate-reports.bash:163-165`; E1 log

---

## Claim 27: "the fixture sits alone in a throwaway repo (one "fixture" commit, so no branch diff to scope to)"

**Location:** `test/skills/security-reviewer/runner.bash:2-4`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the repo the generator builds. It does not establish how the skill reacts to finding no `main` branch (default branch name depends on git config; no global `init.defaultBranch` is set here).
**Legibility-target:** for-orchestrator-synthesis

`git -C "$temp_dir" init -q` / `add .` / `commit -q -m "fixture" --allow-empty` (`test/skills/generate-reports.bash:181-184`). That is exactly one commit, with no second branch.

**Evidence:** `test/skills/security-reviewer/runner.bash:1-6`; `test/skills/generate-reports.bash:176-185`

---

## Claim 28: "inline mode grants no file tools (runner-contract.bash), so the prompt carries the catalog itself, cat'd from the skill directory. No tools at all"

**Location:** `test/skills/ai-personas-critique/runner.bash:2-5`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the runner's settings and catalog path. It does not establish the prompt text beyond the path the catalog is read from.
**Legibility-target:** for-orchestrator-synthesis

`FIXTURE_TOOLS="none"` / `FIXTURE_MODE="inline"` / `PERSONAS_CATALOG="$REPO_ROOT/skills/ai-personas-critique/personas.md"` (`:6-9`). The contract refuses file tools in inline mode (`runner-contract.bash:58-64`). E1 `ok 22` shows this runner sources cleanly with `REPO_ROOT` set.

**Evidence:** `test/skills/ai-personas-critique/runner.bash:1-15`; `test/skills/runner-contract.bash:56-65`

---

## Claim 29: "Test-first: "an empty report fails a clean-negative fixture" fails on the previous helpers and passes now."

**Location:** `git:a2972bf` (commit message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that one test against the 4371ec0 and a2972bf..0a81388 helpers. It does not establish the message's "14 clean-negative fixtures in batches 1-4" count, which was not recounted.
**Legibility-target:** for-orchestrator-synthesis

E2 (old helpers): `not ok 1 an empty report fails a clean-negative fixture`. E1 (0a81388): `ok 24 an empty report fails a clean-negative fixture`.

**Evidence:** `test/skills/eval-helpers-empty-report.bats:33-38`; E1, E2 logs

---

## Claim 30: "generate-reports.bats cds to its temp dir and unsets CLAUDE_MODEL and CLAUDE_FLAGS: 13.9 s -> 1.4 s (A7, C10)."

**Location:** `git:a75ba3e` (commit message body)
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the before/after wall time of `bats test/generate-reports.bats` run from `/workspace` on this machine, and the `cd`/`unset` mechanism. It does not reproduce the 13.9 s baseline, which is machine- and cache-dependent. The old suite also had fewer tests, so the comparison is suite-to-suite, not like-for-like.
**Legibility-target:** for-author

`unset CLAUDE_MODEL CLAUDE_FLAGS` / `cd "$TEST_TMPDIR"` (`test/generate-reports.bats:18-19`) is present. E3: old 9.875 s → new 1.404 s. The 1.4 s figure reproduces; the baseline measured about 30% lower than stated. Precise version: "~10-14 s -> 1.4 s".

**Evidence:** `test/generate-reports.bats:15-19`; E3 `docs/reviews/execution-logs/cfc-skill-fixtures-pass2-timing.log`

---

## Claim 31: "Runners use REPO_ROOT, not the private SCRIPT_DIR or BASH_SOURCE (C6)."

**Location:** `git:a75ba3e` (commit message body)
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every committed `test/skills/*/runner.bash` at 0a81388. It does not establish anything about fixture files or helper scripts.
**Legibility-target:** for-orchestrator-synthesis

`git grep -n 'SCRIPT_DIR\|BASH_SOURCE' 0a81388 -- 'test/skills/*/runner.bash'` returns no matches (rc=1) (paraphrased — no quote available because the claim covers the absence of code). The two former users now read `"$REPO_ROOT/skills/ai-personas-critique/personas.md"` (`ai-personas-critique/runner.bash:9`) and `"$REPO_ROOT/test/skills/self-eval/base/skills/."` (`self-eval/runner.bash:23`, and the directory exists).

**Evidence:** `test/skills/ai-personas-critique/runner.bash:9`; `test/skills/self-eval/runner.bash:23`

---

## Claim 32: "The report is removed before each run, so a failed run cannot leave the previous report to be scored (C3)."

**Location:** `git:a75ba3e` (commit message body)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same code as claim 17. It does not establish that the committed regression test (`test/generate-reports.bats:312`) guards this fix: E7 shows it also passes on the pre-fix generator.
**Legibility-target:** for-orchestrator-synthesis

`rm -f "$report_path" "$transcript_path"` (`test/skills/generate-reports.bash:123`). E6 shows the stale report gone after an early-step failure.

**Evidence:** `test/skills/generate-reports.bash:121-123`; E6, E7 logs

---

## Claim 33: "`run-tests.sh --fast`: 948 ok, 0 failed."

**Location:** `docs/reviews/code-review-rubric-2026-09-24-skill-fixtures.md:93`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HEAD cb8076b, whose only `test/` change from 0a81388 rewrites one assertion (the test count is unchanged). It does not establish the slow suite.
**Legibility-target:** for-orchestrator-synthesis

E4: 948 lines match `^ok `, none match `^not ok`, exit 0; the last line is `ok 948 convention workflows have at least 3 process steps`.

**Evidence:** E4 `docs/reviews/execution-logs/cfc-skill-fixtures-pass2-fast.log`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 2** (`test/generate-reports.bats:15-17`): the old suite measured 9.9 s here, not ~14 s. Say "~10-14 s".
- **Claim 5** (`test/generate-reports.bats:277`): the old denylist refused `Edit`, so not every listed spelling "got through". Drop `Edit` from the list or reword.
- **Claim 19** (`test/skills/generate-reports.bash:207`): eval_fixture does not fail an empty report for max_claims:0 fixtures. Add "unless the fixture expects max_claims:0".
- **Claim 24** (`test/skills/runner-contract.bash:16-17`): forgetting the optional FIXTURE_TRANSCRIPT or fixture_base falls back to the default and does not fail.
- **Claim 30** (`git:a75ba3e`): the 13.9 s baseline reproduced as 9.9 s; the 1.4 s figure holds.

### Unverifiable
- **Claim 4b** (`test/generate-reports.bats:123-126`) and **Claim 14b** (`test/skills/generate-reports.bash:56-64`): flag effects agree with the `claude --help` text but need a real run (init event, hook observation) to execute.
- **Claim 14d** (`test/skills/generate-reports.bash:66-67`), **Claim 20** (`test/skills/matrix-analysis/runner.bash:5-6`), **Claim 23** (`test/skills/runner-contract.bash:10-13`): sub-agent `--tools` inheritance rests on an uncommitted canary probe. It needs a captured stream-json transcript of a sub-agent refusing a file tool.
- **Claim 16b** (`test/skills/generate-reports.bash:109,152-153`): `--tools ""` = no tools per the help text; confirming it needs an init event.
- **Claim 22b** (`test/skills/runner-contract.bash:9`): whether the CLI accepts `"Read, Write"` and `"Write(*)"` needs a real run.

Additional scoped residue, recorded as findings for the orchestrator (not verdicts):
- `test/generate-reports.bats:312` ("a failed claude run leaves no stale report behind") passes on the pre-fix generator (E7), so it does not guard the C3 `rm -f`. The early-failure path it would need to exercise is shown in E6.
- `trap "rm -rf '$temp_dir'" RETURN` (`test/skills/generate-reports.bash:161`) does not run when `set -e` aborts inside `generate_one` (E6 leaks its temp dir).
- `--tools <tools...>` is variadic, so a non-flag word placed right after it in `CLAUDE_FLAGS` would be consumed as a tool name (claim 16a scope).

---

## Goal-Alignment Note

Success criterion (verbatim): "a report saved to /workspace/docs/reviews/code-fact-check-report-skill-fixtures-pass2.md. It must start with `**Commit:** 0a81388` and `**Replication:** k=1 (loop pass, decision 031)` header lines and follow the SKILL.md schema. Tag each claim with a Legibility-target (Incorrect/Stale/Mostly Accurate → for-author; others → for-orchestrator-synthesis). End with a Goal-Alignment Note that restates this Success criterion verbatim."

- **Answered:** every claim the brief singled out. The runner-contract header's canary claim is claim 23, Unverifiable as instructed. The hermeticity block is claims 14a-14d. The empty `--tools` argv claim is 16a (Verified, executed with a parse-only probe) and 16b. The eval_fixture empty-report comment is claim 11. The "13.9 s -> 1.4 s" claim is claim 30. The "948 ok" claim (found in the 0a81388 rubric, not a commit message) is claim 33. The test names in `generate-reports.bats` are claims 4a, 6 and 7, and those in `eval-helpers-empty-report.bats` are claim 8. The runner comment edits are claims 20, 27 and 28, plus claim 31.
- **Out of scope:** the "14 clean-negative fixtures in batches 1-4" count in the a2972bf message was not recounted. The 10 unchanged-meaning runner comment rewordings (business-plan-*, cowen, dependency-upgrade, design-space, pre-mortem, what-if, yglesias) share claim 28's basis (inline plus the contract) and were not verdicted individually.
- **Escalate:** the three residue findings listed above (a non-discriminating stale-report test, the temp-dir leak on abort, and variadic `--tools` consumption) are for the orchestrator's critics, not fact-check verdicts. Execution logs were written under `docs/reviews/execution-logs/`, which is inside `docs/reviews/` alongside the report. Nothing was committed.
