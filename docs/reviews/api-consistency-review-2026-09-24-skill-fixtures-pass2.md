Commit: 0a81388

# API Consistency Review: skill-fixtures, pass 2 (fix commits)

**Scope:** `git diff 4371ec0..0a81388 -- . ':!docs'` (fix commits a2972bf, a75ba3e, c90b97a): `generate-reports.bash`, the new `runner-contract.bash`, `eval-helpers.bash`, `eval-helpers-empty-report.bats`, `generate-reports.bats`, `eval-helpers-transcript.bats`, 13 runner comment/path edits
**Date:** 2026-09-24
**Based on:** pass-1 report `docs/reviews/api-consistency-review-2026-09-24-skill-fixtures.md` and rubric `docs/reviews/code-review-rubric-2026-09-24-skill-fixtures.md` (context only)

> ⚠️ **No code fact-check report provided.** API documentation claims have not been
> independently verified against implementation. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

Executed for this pass: the three bats suites touched by the fixes (33/33 ok); `shellcheck -x` on `runner-contract.bash`, `generate-reports.bash` and `eval-helpers.bash` (clean); `eval_fixture` against synthetic reports in a scratch copy of `test/skills/` (repo untouched); `jq` on synthetic result events; `check_runner_settings` on edge-case `FIXTURE_TOOLS` values. `claude` was not run.

## Baseline Conventions

- **Check helpers** are named `<verb>_<noun>` and signal by exit status with a message: `check_*` in `scripts/health-check.sh` (`check_fixture_verdicts`, `check_shellcheck`, ...), `assert_*` / `load_*` in `eval-helpers.bash`.
- **Runner settings** are `UPPER_SNAKE` with a `FIXTURE_` prefix (`FIXTURE_TOOLS`, `FIXTURE_MODE`, `FIXTURE_TRANSCRIPT`); runner hooks are `fixture_prompt` / `fixture_base`; the generator's own inputs are `CLAUDE_MODEL`, `CLAUDE_FLAGS`, `REPO_ROOT`.
- **Generator errors** are `Error: <runner path>: <problem>` on stderr, exit 1, before any `claude` call.
- **Eval failure messages** go to stdout and the call returns 1 (`No KEY_CHECK entry for fixture: ...`, `Unknown check type: ...`).
- **Empty-report rule (as of this diff):** `eval_fixture` fails an empty `REPORT_CONTENT` unless the KEY_CHECK contains the token `max_claims:0`.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `check_runner_settings` | function | `check_fixture_verdicts`, `check_shellcheck`, `check_skill_frontmatter` | `scripts/health-check.sh:98,299,397` | Consistent `check_<noun>` shape and exit-status signalling. It also normalizes `FIXTURE_TRANSCRIPT`, which the health-check `check_*` functions never do; this is documented at `runner-contract.bash:26` |
| `reset_runner_settings` | function | none found with a `reset_` prefix | none, searched `test/` and `scripts/` for `^reset_[a-z_]+\(\)` | New verb. Reads naturally beside `check_runner_settings` |
| `RUNNER_ALLOWED_TOOLS` | array | `FIXTURE_TOOLS`, `FIXTURE_MODE`, `CLAUDE_FLAGS` | `test/skills/generate-reports.bash:13-26,69-71` | Minor mismatch: it constrains `FIXTURE_TOOLS` but uses a `RUNNER_` prefix (Finding 5) |
| `runner-contract.bash` | file | `eval-helpers.bash`, `helpers.bash`, `critic-dimensions.bash` | `test/skills/*.bash` | Consistent kebab-case `.bash` library beside its siblings. The file says "contract" while its functions say "settings" (Finding 5) |
| `eval-helpers-empty-report.bats` | test file | `eval-helpers-transcript.bats` | `test/skills/eval-helpers-transcript.bats` | Consistent `eval-helpers-<topic>.bats` |
| Console line `Done: N lines in report` | CLI output | `Done: N claims, M severity-tagged findings in report` (removed) | `git show 4371ec0:test/skills/generate-reports.bash` | No parser depends on either (grep below). Wording issues in Finding 4 |
| Console line `WARNING: empty report generated (eval_fixture will fail it)` | CLI output | `WARNING: empty report generated` | same | The added clause is not always true (Finding 3) |
| Error `FIXTURE_TOOLS may only name ...` | error message | `FIXTURE_MODE must be inline, repo or tree, got '...'` | `runner-contract.bash:38` | Consistent `<VAR> must/may ... got '<value>'` shape |
| Error `inline mode must not grant file tools; got '...'` | error message | same | `runner-contract.bash:38` | Consistent |
| Error `Empty report for <fixture>: ...` | eval message | `No KEY_CHECK entry for fixture: <fixture>` | `eval-helpers.bash:70` | Consistent stdout + return 1 |

## Findings

#### 1. Pass-1 #1 is closed for empty output only: a failed run that prints text, or whitespace, still scores as a pass on fixtures without `format_check`

**Severity:** Inconsistent
**Location:** `test/skills/eval-helpers.bash:74-82`, `test/skills/generate-reports.bash:189-201`, `test/skills/security-reviewer/expected-verdicts.bash:55`, `test/skills/divergent-design/expected-verdicts.bash:45`
**Move:** 3 (consumer contract), 7 (asymmetry)
**Confidence:** High on the eval side (executed). Medium that a real failure produces this text: the transcript path rests on the probe recorded in the user's memory note `cc-bare-headless-ignores-oauth-token` (a failed auth run returns `"Not logged in · Please run /login"` as the result, exit 0); the text-mode path is [assumed].
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
  if [ -z "$REPORT_CONTENT" ] && [[ ";$key_check;" != *";max_claims:0;"* ]]; then
    echo "Empty report for $fixture: the generation run failed or printed nothing"
    return 1
  fi
```
```
    jq -rR 'fromjson? | select(.type == "result") | .result // empty' "$transcript_path" \
      > "$report_path" 2>/dev/null || : > "$report_path"
```
```
KEY_CHECK["tc-sec8-clean-exec.go"]="no_severity:Critical|High"
```
The guard catches the zero-byte file and a file of bare newlines, because `$(cat)` strips trailing newlines. Both cases the fix targeted are closed, and `a failed claude run leaves no stale report behind` covers C3. But the guard tests *emptiness*, and the generator still treats "the run failed" and "the model's output" as the same stream. Three failure shapes get through:

- **Error text as the report.** In transcript mode, jq copies a failed run's `result` field into the report regardless of `is_error` (executed: an `is_error:true` event with `"Not logged in · Please run /login"` produces exactly that line). Text mode has the same exposure if the CLI prints the error to stdout, since only stderr is discarded.
- **Whitespace-only output.** `"   \n"` gives a non-empty `REPORT_CONTENT` of three spaces.
- **An empty `result` string.** jq prints `""` as `\n`, which the guard does catch. The generator's messages get this case wrong (Finding 3).

Executed in a scratch copy of `test/skills/`: with the report set to `Not logged in · Please run /login` or to three spaces, `eval_fixture security-reviewer tc-sec8-clean-exec.go` and `eval_fixture divergent-design tc-dd4-open-ended-hackathon-themes` both return **ok**. Every other clean negative from pass 1 carries `format_check`, and those return **not ok** because the format suite runs on non-empty text and fails it (tc-sec7, tc-cow7 checked). So the residual exposure is 2 fixtures in the new sets. The pre-existing fact-check/code-fact-check controls are also exposed: tc-3.1/3.2 (`max_claims:1`) and tc-6.1 (`no_critique`) pass on error text, and the 9 `max_claims:0` fixtures pass on any failure by design (Finding 2). The protection for the other 12 is incidental: it depends on `format_check` happening to be in the KEY_CHECK, not on the guard.

**Recommendation:** Record the failure where it happens. In transcript mode, write the report only when the result event has `is_error == false`, and otherwise leave a `<fixture>.failed` marker (or no report, so `load_eval_report` skips instead of passing). For text mode, check `claude`'s exit status instead of `|| true`, or move every run to `--output-format json` so `is_error` is available. Then `eval_fixture` can fail on the marker whatever the KEY_CHECK contains. A cheaper partial fix: trim whitespace before the emptiness test, and add `format_check` to tc-sec8 and tc-dd4. route: test-strategy (guard test with an error-text report)

#### 2. The `max_claims:0` exemption lets a dead run pass 9 pre-existing fixtures, including one that is not an empty input

**Severity:** Minor
**Location:** `test/skills/eval-helpers.bash:77-79`, `test/skills/eval-helpers.bash:41-48`
**Move:** 3
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
  # every clean-negative fixture. Only a fixture that expects no claims at all
  # (max_claims:0, e.g. an empty input file) may have an empty report.
```
```
KEY_CHECK["tc-c4-skip-targets.js"]="max_claims:0"
```
The exemption keys on the check (`max_claims:0`), but the comment's justification is about the input ("an empty input file"). Nine fixtures use it: fact-check tc-7.1 to 7.4, code-fact-check tc-c4 and tc-c8.1 to 8.4. For these, an empty report is indistinguishable from a failed run, so the A1 hole stays open for the two original skills. `tc-c4-skip-targets.js` is not an empty input. It is a file whose comments should all be skipped, and a working run on it should still print a report shell. Whether the two skills really print nothing for empty inputs is not recorded anywhere I could find. `skills/code-fact-check/SKILL.md:271` only says not to emit per-claim sections.

**Recommendation:** Once Finding 1's failure marker exists, drop the exemption: a failed run is then detected directly, and a legitimately empty report can stay a pass. Until then, say in the comment that the exemption keeps the pre-A1 behaviour for these 9 fixtures, and that a dead run passes them.

#### 3. The generator's empty-report messages disagree with `eval_fixture`'s rule in both directions

**Severity:** Minor
**Location:** `test/skills/generate-reports.bash:204-208`, `test/skills/eval-helpers.bash:79`
**Move:** 7 (asymmetry), 3
**Confidence:** High (executed jq; rule read from code)
**Legibility-target:** for-author

Evidence:
```
  if [ -s "$report_path" ]; then
    echo "  Done: $(wc -l < "$report_path" | tr -d ' ') lines in report"
  else
    echo "  WARNING: empty report generated (eval_fixture will fail it)"
```
The generator tests byte size (`-s`); `eval_fixture` tests the content after `$(cat)`, and also exempts `max_claims:0`. So:
- A transcript run whose result is `""` writes `\n`. The generator prints `Done: 1 lines in report`, but `eval_fixture` fails it as `Empty report ... the generation run failed`.
- A zero-byte report for a `max_claims:0` fixture prints `(eval_fixture will fail it)`, but `eval_fixture` passes it.

The operator reads the generator's line as the verdict on the run, and here it contradicts the scorer.

**Recommendation:** Drop the parenthetical, or make it conditional. Better, share one predicate: a `report_is_empty` helper in eval-helpers (content after whitespace trim) that both scripts call. That also settles the whitespace case from Finding 1.

#### 4. The new `Done:` line carries less signal and counts newlines rather than lines

**Severity:** Informational
**Location:** `test/skills/generate-reports.bash:205`
**Move:** 3
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
    echo "  Done: $(wc -l < "$report_path" | tr -d ' ') lines in report"
```
The old line (`Done: N claims, M severity-tagged findings in report`) was wrong for 20 of 22 skills (rubric C8), so replacing it is right. I grepped the whole repo, including `docs/`, `scripts/`, `test/` and `runs/`, for consumers of the old strings (`severity-tagged findings`, `Done: N claims`, `claim_count`) and for the old `must not include Write` error. Outside historical review artifacts in `docs/reviews/`, only `test/generate-reports.bats` referenced them, and it was updated to `lines in report` / `FIXTURE_TOOLS may only name`. So no caller is broken. Two small points remain. `wc -l` counts newlines, so a one-line report with no trailing newline prints `0 lines in report`, and the grammar reads `1 lines`. And fact-check / code-fact-check lost a claim count that was correct for them.

**Recommendation:** Optional. Print bytes, or `claim_heading_re`'s count for the skills that define one. Not worth a separate commit.

#### 5. `RUNNER_ALLOWED_TOOLS` and `*_runner_settings` use a different prefix from the variables they govern

**Severity:** Informational
**Location:** `test/skills/runner-contract.bash:14`, `test/skills/runner-contract.bash:18`, `test/skills/runner-contract.bash:28`
**Move:** 2
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: `FIXTURE_` prefix for runner-set values (`FIXTURE_TOOLS`, `FIXTURE_MODE`, `FIXTURE_TRANSCRIPT`) and `fixture_` for hooks, used in `test/skills/generate-reports.bash:13-26` and `test/skills/*/runner.bash`

Evidence:
```
RUNNER_ALLOWED_TOOLS=(Read Grep Glob WebSearch WebFetch Agent)
```
The contract has three vocabularies: the file is a "contract", the functions manage "runner settings", and the values are `FIXTURE_*`. Someone grepping `FIXTURE_TOOLS` for its allowed values reaches the error message, not the array. This is Informational because the prefix is internal, and "runner" is an accurate noun: runner.bash sets these values.

**Recommendation:** None required. If touched again, consider `FIXTURE_ALLOWED_TOOLS`, or a comment on `FIXTURE_TOOLS` in the generator header naming the array. The header already points at runner-contract.bash.

#### 6. Allowlist error message and parsing edge cases

**Severity:** Informational
**Location:** `test/skills/runner-contract.bash:44-55`, `test/skills/runner-contract.bash:30-31`
**Move:** 4 (error consistency)
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence:
```
        echo "Error: $label: FIXTURE_TOOLS may only name ${RUNNER_ALLOWED_TOOLS[*]} (comma-separated, no spaces) or be 'none'; got '$tool'" >&2
```
```
    echo "Error: $label must set FIXTURE_TOOLS and define fixture_prompt" >&2
```
- The message demands comma-separated values but lists the allowed names space-separated (`Read Grep Glob ...`), so a reader copying from it gets the wrong form.
- `read -ra` drops a trailing empty field. So `Read,` is accepted (and passed to `--tools` as `Read,`), while `,Read` and `Read,,Grep` are rejected with `got ''`. None of the committed runners does this.
- The first error omits the `:` after `$label` that every other contract error uses. This is carried over verbatim from the pre-fix generator.

**Recommendation:** Join the list with commas in the message (`local IFS=,; echo "${RUNNER_ALLOWED_TOOLS[*]}"`), reject empty fields consistently, and add the colon.

#### 7. The runner contract's usage block omits `REPO_ROOT`, which runners now need when they are sourced

**Severity:** Informational
**Location:** `test/skills/runner-contract.bash:5-6`, `test/skills/ai-personas-critique/runner.bash:9`
**Move:** 3
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
# Load with: source runner-contract.bash
# Then: reset_runner_settings; source <runner.bash>; check_runner_settings <label>
```
```
PERSONAS_CATALOG="$REPO_ROOT/skills/ai-personas-critique/personas.md"
```
The C6 fix moved ai-personas from `BASH_SOURCE` to `$REPO_ROOT`, and did so at source time, not inside a function. Both current callers set `REPO_ROOT` first: the generator at `:78`, and the bats test inside its subshell. The contract file is presented as the shared entry point, though, and its usage line does not list `REPO_ROOT`. A third caller that omits it gets `/skills/ai-personas-critique/personas.md`, passes `check_runner_settings`, and fails later in `fixture_prompt`. Only the generator header documents `REPO_ROOT` (`generate-reports.bash:76-78`).

**Recommendation:** Add `REPO_ROOT must be set before sourcing a runner` to the usage block.

#### 8. Out-of-scope stale docs found during the grep (fixture-data pass)

**Severity:** Informational
**Location:** `test/skills/cowen-critique/eval-criteria.md:46-47`, `test/skills/yglesias-critique/eval-criteria.md:50-51`, `test/skills/business-plan-critique-moat/eval-criteria.md:43`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
- WebSearch is on only because generate-reports.bash needs a non-empty tool
  list. SKILL.md tells the critic not to fact-check.
```
All three runners set `FIXTURE_TOOLS="none"` (already true at 4371ec0), so these rationale lines describe a tool grant and a constraint that no longer exist. This is not introduced by the fix diff, and `eval-criteria.md` belongs to the deferred fixture-data pass. It is listed here because the brief asked for every remaining reference to removed behaviour. `docs/working/checkpoint-skill-fixtures-batch4.md:34` ("No Write/Edit in fixture runs") is still true under the allowlist.

**Recommendation:** Fix in the fixture-data pass: "No tools (`FIXTURE_TOOLS=none`); SKILL.md tells the critic not to fact-check."

## What Looks Good

- **The allowlist replaces the denylist cleanly.** Every spelling pass 1 found getting through (`Read, Write`, `Write(*)`, `write`, `MultiEdit`, `NotebookEdit`, `Bash`, `Read,Bash(git:*)`) is refused, and a test pins each one. The inline rule depends on `FIXTURE_MODE` already being validated, and it is: the mode is checked first.
- **One contract, two callers.** The generator and the fast committed-runners test apply the same `reset` / `source` / `check` sequence. The test runs each runner in a subshell, so runners cannot leak into each other, and `reset_runner_settings` `unset -f`s the hooks, so a runner that forgets `fixture_prompt` cannot inherit the previous one. This closes A5.
- **Generator CLI and output paths unchanged.** `generate-reports.bash <skill> [prefix]`, `CLAUDE_MODEL` / `CLAUDE_FLAGS`, and `<fixture>.report.md` / `.transcript.jsonl` are as before. fact-check and code-fact-check behave the same apart from the intended hardening: a temp cwd for inline, and `--restricted --safe-mode`.
- **The single pipeline is correctly quoted.** `stdin_text` is built with `printf '%s\n\n%s'` / `$'\n\n'` and piped with `printf '%s'`. The `--tools ""` element stays its own argv entry. shellcheck is clean.
- **C2 and C3 are fixed with tests.** The dotted-name rule (`^[A-Za-z0-9]{1,5}$` after a real dot) maps `tc-2.4-inaccurate` to `subject`, and the report is removed before each run.
- **Error messages match the established `Error: <label>: <VAR> must ..., got '<value>'` shape**, and the eval-side `Empty report for <fixture>: ...` matches the sibling stdout + return-1 messages.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | Pass-1 #1 closed only for empty output; error text or whitespace still passes tc-sec8 and tc-dd4 | Inconsistent | `eval-helpers.bash:74-82`, `generate-reports.bash:189-201` | High (eval, executed) / Medium (CLI failure text) |
| 2 | `max_claims:0` exemption lets a dead run pass 9 pre-existing fixtures (tc-c4 is not empty input) | Minor | `eval-helpers.bash:77-79` | High |
| 3 | Generator's empty/Done messages contradict `eval_fixture`'s rule both ways | Minor | `generate-reports.bash:204-208` | High |
| 4 | `Done: N lines` counts newlines; no consumer broken by removed lines (grep) | Informational | `generate-reports.bash:205` | High |
| 5 | `RUNNER_` / "settings" / "contract" vs `FIXTURE_` vocabulary | Informational | `runner-contract.bash:14,18,28` | Medium |
| 6 | Allowlist message lists names space-separated; `Read,` accepted, `,Read` rejected; missing colon | Informational | `runner-contract.bash:30-55` | High |
| 7 | Contract usage block omits the `REPO_ROOT` prerequisite | Informational | `runner-contract.bash:5-6` | High |
| 8 | Stale "non-empty tool list" rationale in 3 eval-criteria.md (fixture-data pass) | Informational | `cowen-critique/eval-criteria.md:46` et al. | High |

## Overall Assessment

The fixes do what the brief says. A4, A5, A7, C2 and C3 are closed with tests. The new runner-contract surface follows the codebase's `check_*` and error-message conventions, and fact-check / code-fact-check keep their CLI, outputs and prompts. I found no regressions from the pipeline merge, the `unset -f` scoping, the dotted-name regex or `set -e`, and the suites and shellcheck are green. The one item that matters is that A1 / pass-1 #1 is only partly closed. The guard tests "is the report empty", but the thing to detect is "did the run fail". A failed run that prints an error line or whitespace still passes tc-sec8 and tc-dd4, and the other clean negatives are safe only because they happen to include `format_check`. The fix belongs in the generator, which should record a failure explicitly from `is_error` or the exit status. The eval side could then drop both the emptiness heuristic and the `max_claims:0` exemption. Findings 2 and 3 fall out of the same root. The rest is wording.

## Goal-Alignment Note
- **Success criterion (restated):** a markdown critique saved to /workspace/docs/reviews/api-consistency-review-2026-09-24-skill-fixtures-pass2.md, with `Commit: 0a81388` at the top, structured per the skill, ending with a Goal-Alignment Note.
- **Answered:** (1) Is pass-1 #1 closed? Partly. It is closed for zero-byte and newline-only reports. It stays open for error-text and whitespace reports on fixtures without `format_check` (executed: tc-sec8 and tc-dd4 pass), and by design for the 9 `max_claims:0` fixtures. (2) runner-contract.bash naming, error messages and the new console output: reviewed, and only Minor or Informational items remain. (3) References to removed behaviour: I grepped the whole repo, and no live caller or doc depends on the old error, `severity-tagged`, or `Done: N claims` strings. Three stale eval-criteria lines from an earlier change are noted as out of scope.
- **Out of scope:** security sufficiency of `--restricted` / `--safe-mode` (security-reviewer); fixture data and eval-criteria content (the deferred data pass); running `claude` (forbidden by the brief). So the CLI's text-mode failure output is [assumed].
- **Escalate:** Finding 1 goes to the orchestrator as the only item that affects eval validity. It should stay amber, not be marked resolved. It also goes to test-strategy for an error-text guard test.
- **Decisions I made:** I kept Finding 1 at Inconsistent (pass 1's tier), because the residual is narrower (2 new fixtures plus the pre-existing ones) but the same class. I rated the `max_claims:0` exemption Minor because it preserves pre-branch behaviour.
