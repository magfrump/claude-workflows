Commit: 04c0746

# API Consistency Review: skill-fixtures, pass 1 (harness)

**Scope:** `git diff answers-2026-09-20...skill-fixtures` over the 40 harness files in the pass-1 brief (generate-reports.bash, eval-helpers.bash, 22 runner.bash, format bats, health-check, tests)
**Date:** 2026-09-24
**Based on:** `docs/reviews/code-fact-check-report-skill-fixtures.md` (merged k=3 fact-check). Claims 2, 16, 27, 40 and 41 are cited below and are not re-verified here.

Consumer surfaces reviewed: (a) the runner.bash contract (`FIXTURE_TOOLS`, `FIXTURE_MODE`, `FIXTURE_TRANSCRIPT`, `fixture_prompt`, `fixture_base`); (b) the `generate-reports.bash` CLI, its environment and output naming; (c) the `KEY_CHECK` check DSL in eval-helpers.bash; (d) the `REPORT_PATH` convention in `*-format.bats`. The consumers are expected-verdicts authors, runner authors and the eval bats suites.

## Baseline Conventions

These are the conventions that were in place at `answers-2026-09-20`, and which the diff either extends or departs from:

- **Check DSL** (`eval_fixture` case arms): names are `snake_case`. A check either takes no argument and reads `EXPECTED_VERDICT` (`verdict_match`), or takes an inline argument after `:` (`cites_pattern:<ERE>`, `max_claims:<N>`, `min_claims:<N>`). Count bounds put the qualifier first (`max_claims`, `min_claims`). The one negation is prefixed `no_` (`no_critique`). The `;;` separator is documented, but the old `IFS=';;'` actually split on single `;`.
- **EXPECTED_VERDICT sentinels:** `assert_verdict` treats `Any` as match-anything and `skip` as don't-check. Values are matched as a whole line (`^(allowed)$`).
- **Generator:** positional CLI `<skill> [fixture-prefix]`, configured through the `CLAUDE_MODEL` and `CLAUDE_FLAGS` environment variables. Output goes to `<skill>/output/<fixture>.report.md`.
- **Format bats:** `load_generic_report <default>` already honours `REPORT_PATH` internally (`helpers.bash:60`: `REPORT="${REPORT_PATH:-$1}"`), and it skips on a missing or empty report. Some suites write `${REPORT_PATH:-default}` explicitly (self-eval, pre-mortem, test-strategy, dependency-upgrade) and others pass the bare default.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `severity_match` | check | `verdict_match` | `test/skills/eval-helpers.bash:83` | Consistent. Same `<field>_match` shape, and it reads `EXPECTED_VERDICT` like its sibling |
| `no_severity:<set>` | check | `no_critique`, `verdict_match` | `eval-helpers.bash` case arms | Consistent `no_` prefix. Takes an inline argument where its positive twin reads `EXPECTED_VERDICT` (Finding 3) |
| `no_verdict:<set>` | check | `verdict_match`, `no_critique` | `eval-helpers.bash:83-94` | `no_` prefix is consistent. The asymmetry is in how its argument is sourced and matched (Findings 3, 4) |
| `field_match:<F>=<v>` | check | `verdict_match`, `cites_pattern:` | `eval-helpers.bash` | Inconsistent. The `_match` suffix now means both "reads EXPECTED_VERDICT" and "takes an inline argument" (Finding 3) |
| `no_field:<F>=<v>` | check | `no_severity:`, `no_verdict:` | `eval-helpers.bash` | Consistent with the new negatives |
| `no_pattern:<ERE>` | check | `cites_pattern:`, `no_critique` | `eval-helpers.bash` | Acceptable. The positive/negative pair reads `cites_pattern`/`no_pattern` rather than `cites_pattern`/`no_cites_pattern`, but it follows the `no_` precedent |
| `tool_called:<Tool>=<ERE>` | check | `field_match:<F>=<v>` (sibling in this diff), `web_search_used` | `eval-helpers.bash:127` | Consistent. Same `<key>=<value>` split as `field_match` |
| `subagents_min:<N>` | check | `min_claims:<N>`, `max_claims:<N>` | `eval-helpers.bash:113-120` | Inconsistent. The qualifier comes last, but existing bounds put it first (Finding 2) |
| `FIXTURE_TOOLS` / `FIXTURE_MODE` / `FIXTURE_TRANSCRIPT` | runner var | `CLAUDE_MODEL`, `CLAUDE_FLAGS` | `generate-reports.bash:52-54` | Consistent. `UPPER_SNAKE` with a shared `FIXTURE_` prefix |
| `fixture_prompt`, `fixture_base` | runner fn | none; the generator had no hooks before this diff | none, searched `test/skills/**/*.bash` at the base | New category. The lower_snake with `fixture_` prefix matches the vars and is consistent within itself |
| `FIXTURE_MODE` values `inline`/`repo`/`tree` | enum | none | none, searched `test/skills/` at the base | New category. Well documented at `generate-reports.bash:20-24` |
| `FIXTURE_TOOLS=none` | sentinel | `Any` / `skip` (EXPECTED_VERDICT sentinels) | `eval-helpers.bash:154-155` | Acceptable. It is a lowercase keyword where the check sentinels are capitalised, but the domains are separate |
| `<fixture>.transcript.jsonl` | output file | `<fixture>.report.md` | `generate-reports.bash:136` | Consistent. Same `<fixture>.<kind>.<ext>` shape |
| `REPORT_PATH` in draft-review / matrix-analysis format bats | env | `${REPORT_PATH:-…}` in self-eval, pre-mortem | `test/skills/{self-eval,pre-mortem}-format.bats` | Consistent with half the suites. Redundant given `helpers.bash:60` (Finding 10) |
| `eval_transcript_path`, `transcript_tool_inputs`, `assert_tool_called`, `assert_subagents_min`, `field_values` | helper fn | `load_eval_report`, `assert_report_matches`, `assert_max_claims` | `eval-helpers.bash` | Consistent. `assert_*` for checks, verb/noun helpers otherwise |

## Findings

#### 1. Negative-only KEY_CHECKs pass on an empty report, and the generator writes an empty report whenever a run fails

**Severity:** Inconsistent
**Location:** `test/skills/eval-helpers.bash:41-48`, `test/skills/helpers.bash:65-66`, `test/skills/generate-reports.bash:213-221`
**Move:** 3 (consumer contract), 7 (asymmetry)
**Confidence:** High (executed)
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
    # Empty report = 0 claims. Don't skip — let assertions run so that
    # negative test fixtures (e.g., empty-file inputs) actually verify
    # the max_claims:0 expectation instead of silently passing via skip.
```
```
  if [ -z "$REPORT_CONTENT" ]; then
    skip "Report is empty"
```
```
      > "$report_path" 2>/dev/null || : > "$report_path"
```
The two report loaders handle an empty file in opposite ways. `load_eval_report` keeps it and runs every check, which is correct for code-fact-check's empty-input fixtures. `load_generic_report` skips, so `format_check`, which shells out to the format bats, exits 0. Each of the new negative checks (`no_severity:`, `no_verdict:`, `no_field:`, `no_pattern:`) passes on an empty `REPORT_CONTENT` by design. So a fixture whose KEY_CHECK uses only negatives plus `format_check` passes when the model produced nothing.

The generator produces exactly that empty file on every failure path: `claude … || true`, and in transcript mode `|| : > "$report_path"`. It only prints `WARNING: empty report generated`.

I ran `eval_fixture security-reviewer tc-sec7-clean-dynamic-query.ts` against a zero-byte report and got `ok 1`. The fixtures exposed are tc-per7, tc-arch6, tc-mkt6, tc-moat7, tc-ue7, tc-cow7, tc-dss6, tc-dd4, tc-pm7, tc-sec7, tc-sec8, tc-ts6, tc-wi6 and tc-ygl7 (every negative control in batches 1-4). A claude outage or auth failure (see FP-097) therefore turns every clean-negative false-positive check green.

**Recommendation:** Treat an empty report as a failure outside the `max_claims:0` convention. Two ways: have `eval_fixture` fail on an empty `REPORT_CONTENT` unless the KEY_CHECK contains `max_claims:0`, or have negative checks assert the report is non-empty. Keep the existing empty-input semantics explicit rather than inherited. Route to test-strategy for a guard test.

#### 2. `subagents_min:` reverses the word order of the existing count bounds

**Severity:** Minor
**Location:** `test/skills/eval-helpers.bash:131-133`
**Move:** 2
**Confidence:** High
**Legibility-target:** for-author

Precedent: `min_claims:<N>` / `max_claims:<N>` (qualifier first) used in `test/skills/eval-helpers.bash:113-120`

Evidence:
```
      subagents_min:*)
        assert_subagents_min "${check#subagents_min:}" || failed=1
```
The existing bound checks read `min_claims:1` and `max_claims:0`. The new one reads `subagents_min:4`. Anyone writing an expected-verdicts file who has learned `min_claims:` will reach for `min_subagents:`, which falls into the `*)` arm and fails with "Unknown check type". That fails loudly, so there is no silent harm, only friction. There are 4 call sites, all in `matrix-analysis/expected-verdicts.bash`.

**Recommendation:** Rename it to `min_subagents:` (and `assert_min_subagents`) now, while it has only 4 call sites.

#### 3. The `_match` / `no_` pairs source their argument inconsistently, and test-strategy duplicates its expectation as a result

**Severity:** Minor
**Location:** `test/skills/eval-helpers.bash:83-101`, `test/skills/test-strategy/expected-verdicts.bash:32-34`
**Move:** 7 (asymmetry), 2
**Confidence:** High
**Legibility-target:** for-author

Precedent: `verdict_match` (no argument; reads `EXPECTED_VERDICT`) and `cites_pattern:<ERE>` (inline argument) used in `test/skills/eval-helpers.bash` at `answers-2026-09-20`

Evidence:
```
      severity_match)
        assert_severity "$expected_verdict" || failed=1
```
```
      no_verdict:*)
        assert_no_verdict "${check#no_verdict:}" || failed=1
```
```
      field_match:*)
        local spec="${check#field_match:}"
```
```
EXPECTED_VERDICT["tc-ts1-installment-split.py"]="high"
```
```
KEY_CHECK["tc-ts1-installment-split.py"]="field_match:Priority=high;;cites_pattern:…
```
Of the three positive field checks, two (`verdict_match`, `severity_match`) take no argument and read `EXPECTED_VERDICT`, and one (`field_match:F=v`) takes its value inline and ignores `EXPECTED_VERDICT`. Every negative (`no_verdict:`, `no_severity:`, `no_field:`) takes its value inline. So `_match` means "compare against EXPECTED_VERDICT" in two checks and "compare against my argument" in the third. For test-strategy the result is that "high" is written twice per fixture: once in `EXPECTED_VERDICT`, where nothing reads it, and once in `field_match:Priority=high`, which is what actually runs. Those two copies can drift apart without any test noticing.

**Recommendation:** Let `field_match:<Field>` with no `=value` read `EXPECTED_VERDICT`, mirroring `severity_match`, and use that form in test-strategy. Alternatively, state in the eval-helpers header which checks read `EXPECTED_VERDICT` and which do not.

#### 4. `verdict_match` and `no_verdict:` match the same field under different rules

**Severity:** Minor
**Location:** `test/skills/eval-helpers.bash:167`, `test/skills/eval-helpers.bash:218-221`
**Move:** 7
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
    if echo "$v" | grep -qiE "^(${allowed})$"; then
```
```
  hits=$(field_values Verdict \
    | grep -iE "^(${forbidden})([^[:alpha:]]|$)" || true)
```
`assert_verdict` requires the whole value to match. `assert_no_verdict`, `assert_severity`, `assert_field` and `assert_no_field` compare only the leading word or words. Take a moat report that writes `**Verdict:** Weak (switching costs)`: `no_verdict:Weak` catches it, but `verdict_match` with `EXPECTED_VERDICT="Weak"` does not. The positive and negative checks on one field therefore disagree about what counts as that verdict. The new functions' comment says "as in assert_no_severity" but does not mention that `assert_verdict` differs.

**Recommendation:** Pick one rule for all `**Verdict:**` comparisons. Probably the leading-word rule, since skills append qualifiers. Or document the difference in `assert_verdict`'s header.

#### 5. The EXPECTED_VERDICT sentinel vocabulary is uneven across checks and files

**Severity:** Minor
**Location:** `test/skills/eval-helpers.bash:154-155`, `test/skills/eval-helpers.bash:185`, `test/skills/performance-reviewer/expected-verdicts.bash:42`
**Move:** 2, 8
**Confidence:** High
**Legibility-target:** for-author

Precedent: `Any` / `skip` sentinels used in `test/skills/eval-helpers.bash:154-155` (assert_verdict)

Evidence:
```
  [ "$allowed" = "Any" ] && return 0
  [ "$allowed" = "skip" ] && return 0
```
```
  [ "$allowed" = "Any" ] && return 0
```
```
EXPECTED_VERDICT["tc-perf6-startup-config-scan.py"]="none"
```
`assert_verdict` honours both `Any` and `skip`, while the new `assert_severity` honours only `Any`. A fixture that copies fact-check's `skip` idiom onto `severity_match` would fail with "Expected a severity matching /skip/". Separately, the placeholder for clean negatives is `None` in 13 expected-verdicts files and `none` in performance-reviewer. Test-strategy uses `high` where the other reviewers use `High`. Nothing reads these placeholders today (the negatives use inline `no_*` checks), but that is not stated. If someone later adds `severity_match` to a negative, it would look for a "None" severity.

**Recommendation:** Accept `skip` in `assert_severity`, or factor both sentinels into one helper. Pick one casing for the documentation-only negative placeholder.

#### 6. Runners locate repo files three different ways, one through an undocumented generator internal

**Severity:** Minor
**Location:** `test/skills/self-eval/runner.bash:23`, `test/skills/divergent-design/runner.bash:19`, `test/skills/ai-personas-critique/runner.bash:13`
**Move:** 1, 3
**Confidence:** High
**Legibility-target:** for-author

Precedent: `$REPO_ROOT` exported for runners, documented in `test/skills/generate-reports.bash:37-40,59-61`

Evidence:
```
  cp -R "$SCRIPT_DIR/self-eval/base/skills/." "$dest/skills/"
```
```
  cp "$REPO_ROOT/workflows/divergent-design.md" "$1/workflows/"
```
```
PERSONAS_CATALOG="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../skills/ai-personas-critique" && pwd)/personas.md"
```
The header documents `REPO_ROOT` as the variable runners use, and marks it with an SC2034 disable "Used by the sourced runner.bash files". self-eval's `fixture_base` depends on `SCRIPT_DIR` as well, which the contract never mentions. It also hard-codes the skill directory name instead of deriving it. ai-personas-critique uses a third method: it resolves relative to `BASH_SOURCE`. All three work today. The `SCRIPT_DIR` dependency is the fragile one, because renaming that generator local would break self-eval with no error from the contract checks (`declare -F fixture_prompt`, the `FIXTURE_*` validation).

**Recommendation:** Use `$REPO_ROOT/test/skills/self-eval/base/skills` in self-eval. Or add `SCRIPT_DIR` to the documented runner environment. Optionally, move ai-personas to `$REPO_ROOT` for uniformity.

#### 7. Contract docs have drifted from the implemented contract

**Severity:** Minor
**Location:** `test/skills/generate-reports.bash:32-33`, `test/skills/generate-reports.bash:157-158`, `test/skills/eval-helpers.bash:7`, `test/skills/eval-helpers.bash:74-78`, `test/skills/eval-helpers.bash:135`
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check Claims 16, 27, 40)
**Legibility-target:** for-author

Evidence:
```
# them: in "repo" mode the fixture is copied in as subject.<ext>, and that
# neutral name is what fixture_prompt receives in both modes.
```
```
  # Run each check (separated by ;; in KEY_CHECK values). Every check runs and
```
```
  IFS=';' read -ra checks <<< "$key_check"
```
```
# Args: $1 = skill name (fact-check or code-fact-check)
```
These are the documented contracts runner and expected-verdicts authors read:
- "both modes" should be "inline and repo". In tree mode `fixture_prompt` receives `.` (Claim 16).
- The separator is documented as `;;`, but any single `;` splits a pattern. Only test-strategy's header warns about this ("so no pattern may contain ';'"). Behaviour is unchanged from base, but the rewrite was the moment to document it.
- `load_expected_verdicts` and `format_check` still name only the two original skills (Claim 40).
- The `--tools stays last` rationale does not describe what the ordering protects (Claim 27).

**Recommendation:** Fix the four comments. In the eval_fixture header, state that the separator is effectively `;` and that patterns must not contain `;`, and list the check vocabulary in one place, since it is currently scattered across per-skill expected-verdicts headers.

#### 8. The `FIXTURE_TOOLS` value grammar is undocumented, and the Write/Edit guard depends on it

**Severity:** Informational
**Location:** `test/skills/generate-reports.bash:16-18`, `test/skills/generate-reports.bash:89-94`
**Move:** 3
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
case ",$FIXTURE_TOOLS," in
  *,Write,*|*,Edit,*)
```
The header describes `FIXTURE_TOOLS` as "the --tools allowlist for claude -p, or "none"", but never says the value must be comma-separated with no spaces. The guard only works for that exact form: `Read, Write` or `Write(*)` would pass it. Every committed runner uses the no-space form today. The security side of this (Bash, NotebookEdit, MultiEdit) is escalated to security-reviewer in the fact-check. This finding only covers the contract gap.

**Recommendation:** Document the grammar as "comma-separated, no spaces, or none". Or normalise the value (strip spaces and `(…)` suffixes) before the guard. route: security-reviewer

#### 9. Inline prompt lead-ins end inconsistently

**Severity:** Informational
**Location:** `test/skills/business-plan-critique-market-sizing/runner.bash:12`, `test/skills/yglesias-critique/runner.bash:12`
**Move:** 1
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:
```
  printf '%s' "Critique the market sizing in the following business plan. No fact-check report is provided. Print the critique to stdout; do not write it to docs/reviews/."
```
The generator appends the fixture after `\n\n` (`printf '%s\n\n%s' "$prompt" "$fixture_content"`). Most inline runners end with a colon naming the payload: fact-check's pre-existing "Fact-check the following draft:", and "The proposal:", "The brief:", "The debt item:". market-sizing and yglesias end instead with an instruction sentence, so the draft follows "do not write it to docs/reviews/." with no marker introducing it. This probably makes no difference to the model, but it is a template inconsistency that the next runner author will copy from whichever file they open first.

**Recommendation:** End every inline `fixture_prompt` with a "The <payload>:" lead-in.

#### 10. The explicit `${REPORT_PATH:-…}` in two format bats is redundant with the helper

**Severity:** Informational
**Location:** `test/skills/draft-review-format.bats:11`, `test/skills/matrix-analysis-format.bats:11`
**Move:** 1
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
  load_generic_report "${REPORT_PATH:-docs/reviews/matrix-analysis.md}"
```
`load_generic_report` already does `REPORT="${REPORT_PATH:-$1}"` (`helpers.bash:60`), so the bare-default suites (security-reviewer, cowen-critique, and others) honour `format_check`'s `REPORT_PATH` equally well. These two edits add no behaviour and keep two styles in use. That is harmless, and the precedent for both styles predates this diff.

**Recommendation:** No change needed. If you want uniformity, pick one style in a later sweep.

#### 11. `field_values` widens `assert_verdict` for the existing fact-check and code-fact-check suites

**Severity:** Informational
**Location:** `test/skills/eval-helpers.bash:158`, `test/skills/eval-helpers.bash:233-236`
**Move:** 3, 6
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
  verdicts=$(field_values Verdict)
```
```
    | sed -E -n "s/^[[:space:]]*([-*+][[:space:]]+)?\*\*${field}:\*\* //p"
```
At base, `assert_verdict` read only `**Verdict:**` lines at column 0. It now also reads indented and bullet-prefixed ones, and strips `\r`. For a multi-claim fact-check report the check is "any verdict matches", so every additional line it harvests (a summary bullet, a quoted example) makes the check more permissive. This is backward-compatible, since no previously passing report can start failing, but the pre-existing fixtures have loosened silently.

**Recommendation:** None required. Note it in the commit or plan so the fact-check fixture baselines are not read as unchanged.

#### 12. health-check accepts either fixture shape, but the generator filters by mode

**Severity:** Informational
**Location:** `scripts/health-check.sh:317`, `test/skills/generate-reports.bash:237-242`
**Move:** 3
**Confidence:** Medium
**Legibility-target:** for-automated-gate

Evidence:
```
            [[ -f "$fixture" || -d "$fixture" ]] || continue
```
```
  if [ "$FIXTURE_MODE" = "tree" ]; then
    [ -d "$f" ] || continue
```
A directory fixture under a repo-mode skill, or a file under a tree-mode skill, passes the fixture-to-verdict check. The generator then silently skips it, and the eval bats skips it too with "No report". The only signal is a missing line in the generator's count. The test "every committed fixture set has a runner the generator accepts" only checks that the runner file exists (Claim 2), so no gate ties a fixture's shape to its runner's mode.

**Recommendation:** Have `generate-reports.bats`'s committed-fixtures test source each runner and assert every fixture's shape matches `FIXTURE_MODE`.

## What Looks Good

- **Runner contract shape.** A small, well-documented surface: three variables with a shared `FIXTURE_` prefix, one required and one optional hook, enumerated `FIXTURE_MODE` values, and validation that fails fast before any paid call (`generate-reports.bash:85-115`). The `none` sentinel means a runner that forgets `FIXTURE_TOOLS` errors out rather than silently getting no tools.
- **CLI backward compatibility.** `generate-reports.bash fact-check [prefix]` and `code-fact-check` keep their argv and output paths, and both skills gained runners that reproduce their old prompts and tool sets. The usage line generalises cleanly to `<skill>`.
- **Output naming.** `<fixture>.transcript.jsonl` sits next to `<fixture>.report.md` with a matching shape, and `eval_transcript_path` derives one from the other.
- **Check DSL growth follows existing shapes.** `no_` prefixes follow `no_critique`. `tool_called:` and `field_match:` share one `<key>=<value>` split rule. Unknown checks still fail loudly, and every check now contributes to the result instead of stopping at the first failure.
- **Transcript checks fail on a missing transcript** instead of skipping, with a remediation message. That is consistent with the intent of `load_eval_report`'s empty-report comment.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | Negative-only KEY_CHECKs pass on an empty report | Inconsistent | `eval-helpers.bash:41-48`, `helpers.bash:65-66`, `generate-reports.bash:221` | High |
| 2 | `subagents_min:` vs `min_claims:` word order | Minor | `eval-helpers.bash:131` | High |
| 3 | `_match`/`no_` argument-sourcing asymmetry; test-strategy duplicates its expectation | Minor | `eval-helpers.bash:83-101` | High |
| 4 | `verdict_match` full-line vs `no_verdict:` leading-word matching | Minor | `eval-helpers.bash:167,218` | High |
| 5 | Sentinel vocabulary uneven (`skip`, `None`/`none`, `high`/`High`) | Minor | `eval-helpers.bash:154-155,185` | High |
| 6 | Runners locate repo files 3 ways; self-eval uses undocumented `SCRIPT_DIR` | Minor | `self-eval/runner.bash:23` | High |
| 7 | Contract docs drift (both modes, `;;`, skill-name args, --tools rationale) | Minor | `generate-reports.bash:32,157`, `eval-helpers.bash:7,74,135` | High |
| 8 | `FIXTURE_TOOLS` grammar undocumented; guard depends on it | Informational | `generate-reports.bash:89-94` | Medium |
| 9 | Inline prompt lead-ins end inconsistently | Informational | `market-sizing/runner.bash:12`, `yglesias-critique/runner.bash:12` | Medium |
| 10 | Redundant explicit `${REPORT_PATH:-…}` | Informational | `draft-review-format.bats:11`, `matrix-analysis-format.bats:11` | High |
| 11 | `field_values` loosens pre-existing `assert_verdict` | Informational | `eval-helpers.bash:158,233` | Medium |
| 12 | health-check shape vs generator mode mismatch | Informational | `health-check.sh:317` | Medium |

## Overall Assessment

For the most part the new harness surface follows the grain of what existed. The runner contract is a clean, documented, validated extension; the CLI and output paths are backward-compatible; and new check names reuse the `no_` and `:arg` shapes. The one finding with real consumer impact is #1. The new negative checks inherit `load_eval_report`'s "keep empty reports" rule, and `format_check` skips on empty, so every clean-negative fixture in batches 1-4 passes when a run failed and wrote nothing. That is a correctness hole in the eval signal, not a style problem, and it should be closed before the fixtures are calibrated. The rest are cheap, in-place fixes to names and docs: rename `subagents_min` → `min_subagents`, unify the matching and sentinel rules, stop depending on `SCRIPT_DIR`, and correct four comments. None of them suggests the author skipped surveying the existing conventions.

## Goal-Alignment Note
- **Success criterion (restated verbatim):** a markdown critique saved to /workspace/docs/reviews/api-consistency-review-2026-09-24-skill-fixtures.md with a `Commit: 04c0746` line at the top, structured per the api-consistency-reviewer skill, ending with a Goal-Alignment Note.
- **Answered:** yes. I covered all four named surfaces (the runner contract, the generate-reports CLI and environment, the KEY_CHECK DSL, and the REPORT_PATH convention), with a name-pattern audit against pre-existing siblings. Finding 1 is backed by execution: `eval_fixture security-reviewer tc-sec7-clean-dynamic-query.ts` on a zero-byte report returned `ok 1`. I removed the temporary report afterwards.
- **Out of scope:** the security sufficiency of the tool guard and MCP isolation (fact-check escalations to security-reviewer); fixture data and the eval-criteria content (pass 2); whether claude's argv parsing can swallow a flag (Claim 27, unverifiable here).
- **Escalate:** Finding 1 goes to test-strategy / the orchestrator, because it affects the validity of every negative-control fixture and should be synthesised as the top-priority item. Finding 8 goes to security-reviewer, which already holds that escalation.
- **Decisions I made:** I rated Finding 1 "Inconsistent", which is the highest non-breaking tier on this skill's scale, because it breaks no existing consumer but defeats the new checks' purpose. The orchestrator may reasonably promote it. I kept `subagents_min` at Minor rather than Inconsistent because the DSL is internal and has 4 call sites.
