#!/usr/bin/env bats
# @category fast
# Unit tests for the report-grading harness fixes of the 2026-09-26
# test-constraint audit (Batch G), against a throwaway repo layout and
# synthetic reports; nothing here runs a model or reads test/skills/*/output/.
#   T3  provenance stamps: a report whose skill, runner or fixture changed
#       since generation fails; so does one with no stamp. The shared
#       runner-contract.bash is not stamped (Q-071 [1]), and the reports and
#       their sidecars are not ignored by git, so they can be committed.
#   T4  once a skill has reports, a missing one fails rather than skips, and
#       format_check fails when its nested suite skipped every test.
#   T5  finding_match: tier and pattern in the same finding; cites_pattern and
#       finding_match ignore lines copied verbatim from the fixture.
#   T6  a fixture with only absence checks fails unless allowlisted, and the
#       allowlist is exactly the real expected-verdicts' absence-only set.
#   T2  resolve_skill_report (the format suites' loader) has no committed
#       default and fails on a missing or stale generated report.

load eval-helpers
load helpers

bats_require_minimum_version 1.5.0

setup() {
  REAL_SK="$BATS_TEST_DIRNAME"
  TEST_TMPDIR=$(mktemp -d)
  SK="$TEST_TMPDIR/test/skills"
  mkdir -p "$SK/demo/output" "$SK/demo/fixtures" "$TEST_TMPDIR/skills/demo/references"
  cp "$REAL_SK/runner-contract.bash" "$SK/"
  echo "# demo skill" > "$TEST_TMPDIR/skills/demo/SKILL.md"
  echo "template" > "$TEST_TMPDIR/skills/demo/references/out.md"
  echo "FIXTURE_TOOLS=none" > "$SK/demo/runner.bash"
  cat > "$SK/demo/fixtures/tc-1-idor.ts" <<'EOF'
// TODO: scope this query to the caller's org (ownership check)
const doc = await db.docs.findOne({ id: req.params.id });
EOF
  echo "other" > "$SK/demo/fixtures/tc-2-other.ts"
  # shellcheck disable=SC2034  # read by eval-helpers.bash / helpers.bash
  BATS_TEST_DIRNAME="$SK"
  declare -gA KEY_CHECK EXPECTED_VERDICT
  unset REPORT_PATH
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# report <fixture> <text>: a generated report plus the stamp the generator
# would write for the current tree.
report() {
  printf '%s\n' "$2" > "$SK/demo/output/$1.report.md"
  report_stamp "$SK" demo "$1" > "$SK/demo/output/$1.stamp"
}

# --- T3: provenance stamps ---

@test "stamp: a report generated from the current tree passes" {
  report tc-1-idor.ts "# R"
  run check_report_stamp "$SK" demo tc-1-idor.ts
  [ "$status" -eq 0 ]
}

@test "stamp: a missing stamp fails and says to regenerate" {
  report tc-1-idor.ts "# R"
  rm "$SK/demo/output/tc-1-idor.ts.stamp"
  run check_report_stamp "$SK" demo tc-1-idor.ts
  [ "$status" -ne 0 ]
  [[ "$output" == *"No provenance stamp"*"generate-reports.bash demo tc-1-idor.ts, then commit test/skills/demo/output/" ]]
}

@test "stamp: editing any input after generation fails, naming the input" {
  local what file
  for what in skill:skills/demo/SKILL.md skill:skills/demo/references/out.md \
      runner:test/skills/demo/runner.bash \
      fixture:test/skills/demo/fixtures/tc-1-idor.ts; do
    report tc-1-idor.ts "# R"
    file="$TEST_TMPDIR/${what#*:}"
    cp "$file" "$file.orig"
    echo "# edited" >> "$file"
    run check_report_stamp "$SK" demo tc-1-idor.ts
    mv "$file.orig" "$file"
    [ "$status" -ne 0 ] || { echo "edit to ${what#*:} was not caught"; return 1; }
    [[ "$output" == *"Stale report for demo/tc-1-idor.ts: changed since generation: ${what%%:*}. Regenerate: bash test/skills/generate-reports.bash demo tc-1-idor.ts, then commit test/skills/demo/output/" ]] \
      || { echo "wrong message for ${what#*:}: $output"; return 1; }
  done
  # A new file in the skill directory counts too.
  report tc-1-idor.ts "# R"
  echo x > "$TEST_TMPDIR/skills/demo/references/new.md"
  run check_report_stamp "$SK" demo tc-1-idor.ts
  [ "$status" -ne 0 ]
}

@test "stamp: editing the shared runner-contract.bash does not stale a report (Q-071 [1])" {
  report tc-1-idor.ts "# R"
  echo "# edited" >> "$SK/runner-contract.bash"
  run check_report_stamp "$SK" demo tc-1-idor.ts 3>&-
  [ "$status" -eq 0 ]
  [[ "$output" != *WARNING* ]]
  # The stamp is the format line, the skill's own inputs, and the
  # informational harness line.
  [ "$(cut -d' ' -f1 "$SK/demo/output/tc-1-idor.ts.stamp" | tr '\n' ' ')" = "format skill runner fixture harness " ]
}

@test "stamp: a changed harness warns but does not fail; a comment-only edit is silent" {
  printf '#!/usr/bin/env bash\n# about the flags\nFLAGS=(--a)\n' > "$SK/generate-reports.bash"
  report tc-1-idor.ts "# R"
  printf '# another comment\n\n' >> "$SK/generate-reports.bash"
  run check_report_stamp "$SK" demo tc-1-idor.ts 3>&-
  [ "$status" -eq 0 ]
  [[ "$output" != *WARNING* ]] || { echo "comment edit warned: $output"; return 1; }
  printf 'FLAGS=(--b)\n' >> "$SK/generate-reports.bash"
  run check_report_stamp "$SK" demo tc-1-idor.ts 3>&-
  [ "$status" -eq 0 ]
  [[ "$output" == "WARNING: demo/tc-1-idor.ts: the shared harness"*"not a failure"*"then commit test/skills/demo/output/" ]]
  # A changed skill input still fails, and says so rather than warning.
  echo "# edited" >> "$TEST_TMPDIR/skills/demo/SKILL.md"
  run check_report_stamp "$SK" demo tc-1-idor.ts 3>&-
  [ "$status" -ne 0 ]
  [[ "$output" == *"changed since generation: skill. "* ]]
}

@test "stamp: any stamp without the current format line reads as stale: stamp format" {
  local body
  report tc-1-idor.ts "# R"
  body="$(tail -n +2 "$SK/demo/output/tc-1-idor.ts.stamp")"
  # The format-1 shape: input lines only, plus the old contract line. Its
  # hashes still match the tree, so only the format line can catch it.
  printf '%s\ncontract %064d\n' "$body" 0 > "$SK/demo/output/tc-1-idor.ts.stamp"
  run check_report_stamp "$SK" demo tc-1-idor.ts
  [ "$status" -ne 0 ]
  [[ "$output" == *"changed since generation: stamp format. "* ]]
  printf 'format 1\n%s\n' "$body" > "$SK/demo/output/tc-1-idor.ts.stamp"
  run check_report_stamp "$SK" demo tc-1-idor.ts
  [ "$status" -ne 0 ]
  [[ "$output" == *"changed since generation: stamp format. "* ]]
}

@test "stamp: reports and every sidecar the suites read are tracked, not gitignored" {
  local root f
  root="$(cd "$REAL_SK/../.." && pwd)"
  for f in report.md stamp failed transcript.jsonl; do
    run git -C "$root" check-ignore -q "test/skills/code-review/output/tc-x.$f"
    [ "$status" -eq 1 ] || { echo "output/*.$f is gitignored"; return 1; }
  done
  # Anything else a run might leave in output/ stays ignored.
  git -C "$root" check-ignore -q test/skills/code-review/output/scratch.tmp
}

@test "stamp: another fixture's edit does not stale this report" {
  report tc-1-idor.ts "# R"
  echo "# edited" >> "$SK/demo/fixtures/tc-2-other.ts"
  run check_report_stamp "$SK" demo tc-1-idor.ts
  [ "$status" -eq 0 ]
}

@test "stamp: eval_fixture fails a stale report before grading it" {
  KEY_CHECK["tc-1-idor.ts"]="cites_pattern:IDOR"
  report tc-1-idor.ts "The handler has an IDOR."
  run eval_fixture demo tc-1-idor.ts
  [ "$status" -eq 0 ] || { echo "control: $output"; return 1; }
  echo "# changed" >> "$TEST_TMPDIR/skills/demo/SKILL.md"
  run eval_fixture demo tc-1-idor.ts
  [ "$status" -ne 0 ]
  [[ "$output" == *"Stale report"* ]]
}

# --- T4: missing reports fail once the skill has any ---

@test "missing report: skips when the skill has no reports at all" {
  KEY_CHECK["tc-1-idor.ts"]="cites_pattern:IDOR"
  skip() { echo "SKIP: $*"; exit 0; }
  run eval_fixture demo tc-1-idor.ts
  [ "$status" -eq 0 ]
  [[ "$output" == "SKIP: No generated reports for demo"* ]]
}

@test "missing report: fails when the skill has another fixture's report" {
  KEY_CHECK["tc-1-idor.ts"]="cites_pattern:IDOR"
  report tc-2-other.ts "# R"
  run eval_fixture demo tc-1-idor.ts
  [ "$status" -ne 0 ]
  [[ "$output" == *"No report for tc-1-idor.ts, although demo has generated reports"* ]]
}

@test "format_check: a nested suite that skipped every test fails" {
  local suite="$SK/demo-format.bats"
  printf '#!/usr/bin/env bats\n@test "a" { skip "no values"; }\n@test "b" { skip "no values"; }\n' > "$suite"
  REPORT_PATH="$TEST_TMPDIR/r.md"; echo "# R" > "$REPORT_PATH"
  run run_format_check "$suite"
  [ "$status" -ne 0 ]
  [[ "$output" == *"every test in demo-format.bats skipped"* ]]
}

@test "format_check: one test that ran is enough; a failing one fails" {
  local suite="$SK/demo-format.bats"
  REPORT_PATH="$TEST_TMPDIR/r.md"; echo "# R" > "$REPORT_PATH"
  printf '#!/usr/bin/env bats\n@test "a" { skip "x"; }\n@test "b" { grep -q "# R" "$REPORT_PATH"; }\n' > "$suite"
  run run_format_check "$suite"
  [ "$status" -eq 0 ]
  printf '#!/usr/bin/env bats\n@test "b" { grep -q "absent" "$REPORT_PATH"; }\n' > "$suite"
  run run_format_check "$suite"
  [ "$status" -ne 0 ]
  [[ "$output" == *"failed against"* ]]
}

# --- T5: finding_match and fixture echo ---

# A security-reviewer-shaped report: an unrelated High finding, the IDOR named
# only in a Low finding, and a mandated header that contains "scop".
CROSS_BLOCK='# Security Review

**Scope:** handler.ts

## Findings

#### Verbose error messages

**Severity:** High

Stack traces reach the client.

#### Missing ownership check

**Severity:** Low

The lookup is not scoped to the org: an IDOR.

## What Looks Good

Nothing else.'

@test "finding_match: tier and pattern in different findings fail (the tc-sec2 hole)" {
  REPORT_CONTENT="$CROSS_BLOCK"
  # The old pair of checks passes this report:
  run assert_severity 'Critical|High'
  [ "$status" -eq 0 ]
  run assert_report_matches 'idor|scop'
  [ "$status" -eq 0 ]
  # finding_match does not.
  run assert_finding_match 'Critical|High' 'idor|scop'
  [ "$status" -ne 0 ]
  [[ "$output" == *"No single finding"*"High, Low"* ]]
}

@test "finding_match: tier and pattern in the same finding pass" {
  REPORT_CONTENT="${CROSS_BLOCK/\*\*Severity:\*\* Low/**Severity:** Critical}"
  run assert_finding_match 'Critical|High' 'idor'
  [ "$status" -eq 0 ]
}

@test "finding_match: a finding's own sub-headings belong to it; its parent section does not" {
  REPORT_CONTENT='## Findings

The section intro mentions an IDOR in passing.

#### Missing ownership check

- **Severity:** High

##### Fix

Scope the query by org_id.

#### Next finding

**Severity:** Low'
  run assert_finding_match 'High' 'org_id'
  [ "$status" -eq 0 ]
  # The intro line sits in "## Findings", outside the finding: no match.
  run assert_finding_match 'High' 'idor'
  [ "$status" -ne 0 ]
}

@test "finding_match: a summary-table row is a finding; only the Severity column counts" {
  REPORT_CONTENT='| # | Finding | Severity | Location |
|---|---|---|---|
| 1 | IDOR in doc lookup | **High** | handler.ts:2 |
| 2 | Verbose errors | Low | handler.ts:9 |'
  run assert_finding_match 'Critical|High' 'idor'
  [ "$status" -eq 0 ]
  run assert_finding_match 'Critical|High' 'verbose'
  [ "$status" -ne 0 ]
  REPORT_CONTENT='| # | Finding | Likelihood |
|---|---|---|
| 1 | IDOR in doc lookup | High |'
  run assert_finding_match 'High' 'idor'
  [ "$status" -ne 0 ]
}

@test "finding_match: eval_fixture dispatches it and ignores a quoted fixture line" {
  KEY_CHECK["tc-1-idor.ts"]="finding_match:Critical|High=ownership check"
  # The only "ownership check" in the High finding is the fixture's own comment.
  report tc-1-idor.ts '#### Error handling

**Severity:** High

```
// TODO: scope this query to the caller'"'"'s org (ownership check)
```'
  run eval_fixture demo tc-1-idor.ts
  [ "$status" -ne 0 ]
  report tc-1-idor.ts '#### Missing ownership check

**Severity:** High

Any user can read any org'"'"'s document.'
  run eval_fixture demo tc-1-idor.ts
  [ "$status" -eq 0 ]
}

@test "finding_match: && needs every pattern in the same finding" {
  REPORT_CONTENT="${CROSS_BLOCK/\*\*Severity:\*\* Low/**Severity:** High}"
  run assert_finding_match 'High' 'ownership&&idor'
  [ "$status" -eq 0 ]
  # "Stack traces" is in the other High finding: no single finding has both.
  run assert_finding_match 'High' 'stack traces&&idor'
  [ "$status" -ne 0 ]
}

@test "claim_match: the verdict and the mechanism in the same claim section" {
  REPORT_CONTENT='# Code Fact-Check Report

**Checked:** 2026-09-23

## Claim 1: "Retries the operation up to 5 times"

**Verdict:** Stale

The comment predates the refactor.

## Claim 2: "Uses exponential backoff"

**Verdict:** Verified

MAX_RETRIES is 3 and the delay doubles.'
  # The mechanism is only in the Verified claim; the date supplies a 3.
  run assert_finding_match 'Stale' 'MAX_RETRIES[^.]*3' "" Verdict
  [ "$status" -ne 0 ]
  REPORT_CONTENT="${REPORT_CONTENT/predates the refactor./predates the refactor: MAX_RETRIES is now 3.}"
  run assert_finding_match 'Stale' 'MAX_RETRIES[^.]*3' "" Verdict
  [ "$status" -eq 0 ]
}

@test "cites_count: counts matching lines outside the fixture echo" {
  REPORT_CONTENT='- one idea here
- two ideas here'
  run assert_report_cites_count 3 '^- '
  [ "$status" -ne 0 ]
  REPORT_CONTENT="$REPORT_CONTENT
- three ideas here"
  run assert_report_cites_count 3 '^- '
  [ "$status" -eq 0 ]
}

@test "web_search_used: needs a Sources line naming a source, not the word Sources" {
  REPORT_CONTENT='# Sources

I could not find sources.'
  run assert_sources_named
  [ "$status" -ne 0 ]
  REPORT_CONTENT='**Sources:** CMS National Health Expenditure data, 2024'
  run assert_sources_named
  [ "$status" -eq 0 ]
}

@test "cites_pattern: a line copied verbatim from the fixture does not count" {
  KEY_CHECK["tc-1-idor.ts"]="cites_pattern:ownership check"
  report tc-1-idor.ts '# Review

>   // TODO: scope this query to the caller'"'"'s org (ownership check)

Looks fine.'
  run eval_fixture demo tc-1-idor.ts
  [ "$status" -ne 0 ]
  [[ "$output" == *"outside lines copied from the fixture"* ]]
  report tc-1-idor.ts '# Review

The missing ownership check lets any caller read the document.'
  run eval_fixture demo tc-1-idor.ts
  [ "$status" -eq 0 ]
}

@test "cites_pattern: tree fixtures (directories) are echo-filtered too" {
  mkdir -p "$SK/demo/fixtures/tc-3-tree/src"
  echo "the planted phrase" > "$SK/demo/fixtures/tc-3-tree/src/a.md"
  REPORT_CONTENT="the planted phrase"
  run assert_report_cites 'planted' "$SK/demo/fixtures/tc-3-tree"
  [ "$status" -ne 0 ]
  # shellcheck disable=SC2034  # read by assert_report_cites
  REPORT_CONTENT="the model found the planted phrase"
  run assert_report_cites 'planted' "$SK/demo/fixtures/tc-3-tree"
  [ "$status" -eq 0 ]
}

# --- T6: absence-only fixtures ---

@test "positive-check guard: an absence-only fixture fails unless allowlisted" {
  KEY_CHECK["tc-1-idor.ts"]="no_severity:Critical|High"
  EXPECTED_VERDICT["tc-1-idor.ts"]="None"
  report tc-1-idor.ts "I can't help with that."
  NEGATIVE_ONLY_ALLOWLIST=()
  run eval_fixture demo tc-1-idor.ts
  [ "$status" -ne 0 ]
  [[ "$output" == *"demo/tc-1-idor.ts has only absence checks"* ]]
  NEGATIVE_ONLY_ALLOWLIST=(demo/tc-1-idor.ts)
  run eval_fixture demo tc-1-idor.ts
  [ "$status" -eq 0 ]
}

@test "positive-check guard: an allowlisted fixture that gained a positive check fails" {
  KEY_CHECK["tc-1-idor.ts"]="no_severity:Critical|High;cites_pattern:help"
  report tc-1-idor.ts "I can't help with that."
  NEGATIVE_ONLY_ALLOWLIST=(demo/tc-1-idor.ts)
  run eval_fixture demo tc-1-idor.ts
  [ "$status" -ne 0 ]
  [[ "$output" == *"remove it from NEGATIVE_ONLY_ALLOWLIST"* ]]
}

@test "positive-check guard: which checks count as positive" {
  run key_check_has_positive "no_severity:High;no_pattern:x;max_claims:0;no_critique;no_tool_called:Bash" None
  [ "$status" -ne 0 ]
  run key_check_has_positive "severity_match" Any
  [ "$status" -ne 0 ]
  run key_check_has_positive "verdict_match" skip
  [ "$status" -ne 0 ]
  run key_check_has_positive "min_claims:0" Any
  [ "$status" -ne 0 ]
  run key_check_has_positive "cites_count:0=x" Any
  [ "$status" -ne 0 ]
  local c
  for c in severity_match verdict_match "min_claims:1" "cites_pattern:x" "finding_match:High=x" \
      "field_match:R=x" format_check "tool_called:Read" "subagents_min:2" "mode1_equiv:2" web_search_used \
      "claim_match:Stale=x" "cites_count:3=x"; do
    run key_check_has_positive "no_pattern:y;$c" High
    [ "$status" -eq 0 ] || { echo "$c not counted as positive"; return 1; }
  done
}

@test "positive-check guard: the allowlist is exactly the real absence-only fixtures" {
  local vf skill fixture ids=()
  for vf in "$REAL_SK"/*/expected-verdicts.bash; do
    skill="$(basename "$(dirname "$vf")")"
    unset KEY_CHECK EXPECTED_VERDICT
    declare -gA KEY_CHECK EXPECTED_VERDICT
    # shellcheck disable=SC1090
    source "$vf"
    for fixture in "${!KEY_CHECK[@]}"; do
      key_check_has_positive "${KEY_CHECK[$fixture]}" "${EXPECTED_VERDICT[$fixture]:-}" \
        || ids+=("$skill/$fixture")
    done
  done
  diff <(printf '%s\n' "${ids[@]}" | LC_ALL=C sort) \
       <(printf '%s\n' "${NEGATIVE_ONLY_ALLOWLIST[@]}" | LC_ALL=C sort)
}

# --- T2: resolve_skill_report, the format suites' loader ---

@test "resolve_skill_report: no committed default; skips when the skill has no reports" {
  # bats' skip ends the test; a stand-in shows what it was called with.
  skip() { echo "SKIP: $*"; exit 0; }
  run resolve_skill_report demo tc-1-idor.ts
  [ "$status" -eq 0 ]
  [[ "$output" == "SKIP: No report to grade: set REPORT_PATH, or generate demo's reports"* ]]
  run resolve_skill_report code-review
  [[ "$output" == "SKIP: No report to grade"* ]]
}

@test "resolve_skill_report: the default fixture's report, fresh, once the skill has reports" {
  report tc-1-idor.ts "# R"
  resolve_skill_report demo tc-1-idor.ts
  [ "$REPORT_PATH" = "$SK/demo/output/tc-1-idor.ts.report.md" ]
}

@test "resolve_skill_report: fails on a missing, stale, failed or empty default report" {
  report tc-2-other.ts "# R"
  run resolve_skill_report demo tc-1-idor.ts
  [ "$status" -ne 0 ]
  [[ "$output" == *"No report for tc-1-idor.ts"* ]]
  report tc-1-idor.ts "# R"
  echo "# changed" >> "$TEST_TMPDIR/skills/demo/SKILL.md"
  run resolve_skill_report demo tc-1-idor.ts
  [ "$status" -ne 0 ]
  [[ "$output" == *"Stale report"* ]]
  report tc-1-idor.ts "   "
  run resolve_skill_report demo tc-1-idor.ts
  [ "$status" -ne 0 ]
  [[ "$output" == *"Empty report"* ]]
  report tc-1-idor.ts "# R"
  echo "claude exited 1" > "$SK/demo/output/tc-1-idor.ts.failed"
  run resolve_skill_report demo tc-1-idor.ts
  [ "$status" -ne 0 ]
  [[ "$output" == *"Generation failed"* ]]
}

@test "resolve_skill_report: REPORT_PATH wins, and a missing REPORT_PATH fails" {
  REPORT_PATH="$TEST_TMPDIR/mine.md"
  echo "# mine" > "$REPORT_PATH"
  resolve_skill_report demo tc-1-idor.ts
  [ "$REPORT_PATH" = "$TEST_TMPDIR/mine.md" ]
  REPORT_PATH="$TEST_TMPDIR/nope.md"
  run resolve_skill_report demo tc-1-idor.ts
  [ "$status" -ne 0 ]
}

@test "no format suite falls back to a committed report" {
  local f body
  for f in "$REAL_SK"/*-format.bats; do
    case "$f" in */arithmetic-eval-format.bats) continue ;; esac
    body="$(awk '/^setup\(\)/ { p = 1 } p { print } p && /^}/ { exit }' "$f")"
    [[ "$body" == *resolve_skill_report* ]] || { echo "$f does not load via resolve_skill_report"; return 1; }
    if [[ "$body" == *docs/* || "$body" == *latest_rubric* ]]; then
      echo "$f setup still names a committed report"; return 1
    fi
  done
}
