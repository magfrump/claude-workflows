#!/usr/bin/env bats
# @category fast
# Behavioural test for generate_morning_summary (scripts/lib/si-morning-summary.sh),
# the entry point the self-improvement loop calls after a run.
#
# WHY THIS SUITE EXISTS
# ---------------------
# The section helpers have unit tests (morning-summary-clusters.bats), and
# function-inventory.bats checks the entry point exists — but nothing ran the
# entry point itself, so replacing its body with `return 0` kept the whole repo
# green (audit-test-constraint-2026-09-26). This suite runs it end to end
# against a fixture working dir and asserts on what it writes: every section,
# in order, with counts that follow from the fixture.
#
# Usage: bats test/morning-summary-generate.bats

load lib/hermetic-env

# Assertions compare captured output; keep bash's setlocale warning out of it.
pin_hermetic_locale

setup() {
  source "$BATS_TEST_DIRNAME/../scripts/lib/log-format.sh"
  # print_gate_stats (the Gate Statistics section) lives in si-functions.sh.
  source "$BATS_TEST_DIRNAME/../scripts/lib/si-functions.sh"
  source "$BATS_TEST_DIRNAME/../scripts/lib/si-morning-summary.sh"

  WD="$BATS_TEST_TMPDIR/working"
  OUT="$BATS_TEST_TMPDIR/morning-summary.md"
  mkdir -p "$WD"

  # Isolate usage-log reads (the deferred section pre-aggregates it).
  USAGE_LOG_FILE="$BATS_TEST_TMPDIR/usage.jsonl"
  export USAGE_LOG_FILE

  # Stub the claude CLI (the What's New section's contrastive-pair step can
  # call it). The stub records any call so the test can prove the pre-seeded
  # caches below kept it unused. Convention enforced by
  # test/fixture-hermeticity.bats.
  CLAUDE_CALLS="$BATS_TEST_TMPDIR/claude-calls"
  export CLAUDE_CALLS
  mkdir -p "$BATS_TEST_TMPDIR/stub-bin"
  # shellcheck disable=SC2016  # $CLAUDE_CALLS expands when the stub runs
  printf '#!/usr/bin/env bash\necho called >> "$CLAUDE_CALLS"\nexit 0\n' \
    > "$BATS_TEST_TMPDIR/stub-bin/claude"
  chmod +x "$BATS_TEST_TMPDIR/stub-bin/claude"
  PATH="$BATS_TEST_TMPDIR/stub-bin:$PATH"

  write_fixture
}

# Two rounds, six launched tasks (4 approved, 2 rejected), one matured and one
# not-yet-matured open hypothesis, a round history for gate stats, and a
# contrastive-note cache for each round (round 1 carries a note, round 2 a skip).
write_fixture() {
  cat > "$WD/round-1-report.json" <<'JSON'
{"validation":{
  "t1":{"tests":"pass","lint":"pass","verdict":"approved"},
  "t2":{"tests":"pass","lint":"pass","verdict":"approved"},
  "t3":{"tests":"fail","lint":"pass","verdict":"rejected"}}}
JSON
  cat > "$WD/round-2-report.json" <<'JSON'
{"validation":{
  "t4":{"tests":"pass","lint":"pass","verdict":"approved"},
  "t5":{"tests":"pass","lint":"pass","verdict":"approved"},
  "t6":{"tests":"pass","lint":"fail","verdict":"rejected"}}}
JSON
  jq -s '.' "$WD/round-1-report.json" "$WD/round-2-report.json" > "$WD/round-history.json"

  cat > "$WD/tasks-round-1.json" <<'JSON'
[{"id":"t1","description":"x","files_touched":["scripts/a.sh"],"category":"feature"},
 {"id":"t2","description":"x","files_touched":["scripts/b.sh"],"category":"maintenance"},
 {"id":"t3","description":"x","files_touched":["scripts/c.sh"],"category":"feature"}]
JSON
  cat > "$WD/tasks-round-2.json" <<'JSON'
[{"id":"t4","description":"x","files_touched":["scripts/d.sh"],"category":"data-pipeline"},
 {"id":"t5","description":"x","files_touched":["scripts/e.sh"]},
 {"id":"t6","description":"x","files_touched":["scripts/f.sh"],"category":"feature"}]
JSON

  cat > "$WD/completed-tasks.md" <<'MD'
- **t1**: added the frobnicator
MD
  echo "summary file line for t2" > "$WD/summary-t2.md"

  echo '{"approved_id":"t1","rejected_id":"t3","note":"t1 kept the change small.","round":1}' \
    > "$WD/contrastive-note-round-1.json"
  echo '{"skip":true,"reason":"fixture","round":2}' > "$WD/contrastive-note-round-2.json"

  # h1: round 1 + window 1 <= end round 2 -> matured, surfaces as a question.
  # h2: round 2 + window 5 > 2 -> not matured, must not be asked about.
  cat > "$WD/hypothesis-log.md" <<'MD'
# Hypothesis Log

| Round | Task ID | Hypothesis | Source | Window | Evaluator | Requires | Checked at Round | Outcome | Status Date | Evidence |
|-|-|-|-|-|-|-|-|-|-|-|
| 1 | h1 | the frobnicator will be used weekly |  | 1 | user |  |  |  |  |  |
| 2 | h2 | the widget will reduce retries |  | 5 | user |  |  |  |  |  |
MD
}

@test "generate_morning_summary writes every section, in order" {
  run generate_morning_summary 1 2 "$OUT" "$WD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Morning summary written to: $OUT"* ]]
  [ -s "$OUT" ]

  # Headings in the order the function composes them; grep -n gives each a
  # line number, and the sequence must be strictly increasing.
  local prev=0 line heading
  for heading in \
      "# Morning Summary — " \
      "## Run Overview" \
      "## What You Need To Do" \
      "## Failure Modes This Cycle" \
      "## Project State" \
      "### Task Category Mix" \
      "## What's New" \
      "### Round 1 " \
      "### Round 2 " \
      "## Gate Statistics" \
      "## Deferred Evaluation Questions" \
      "## Recording Your Responses"; do
    line=$(grep -nF -- "$heading" "$OUT" | head -1 | cut -d: -f1)
    [ -n "$line" ] || { echo "missing heading: $heading"; cat "$OUT"; false; }
    [ "$line" -gt "$prev" ] || { echo "out of order: $heading"; cat "$OUT"; false; }
    prev=$line
  done
}

@test "generate_morning_summary: run overview counts follow from the round reports" {
  generate_morning_summary 1 2 "$OUT" "$WD"
  grep -qxF -- "- Rounds completed: 2 (rounds 1-2)" "$OUT"
  grep -qxF -- "- Total tasks attempted: 6" "$OUT"
  grep -qxF -- "- Tasks approved: 4 (66%)" "$OUT"
  grep -qxF -- "- Tasks rejected: 2" "$OUT"
}

@test "generate_morning_summary: per-round listings, failures, and category mix" {
  generate_morning_summary 1 2 "$OUT" "$WD"
  # What's New: headings with counts, summaries from both sources, rejections.
  grep -qxF "### Round 1 (3 tasks, 2 approved)" "$OUT"
  grep -qxF "### Round 2 (3 tasks, 2 approved)" "$OUT"
  grep -qxF -- "- **t1**: added the frobnicator" "$OUT"
  grep -qxF -- "- **t2**: summary file line for t2" "$OUT"
  grep -qxF -- "- **t5**: (no summary available)" "$OUT"
  grep -qxF -- "- REJECTED: **t3** (failed: tests)" "$OUT"
  grep -qxF -- "- REJECTED: **t6** (failed: lint)" "$OUT"
  grep -qF "**Contrastive note** (approved **t1** vs rejected **t3**): t1 kept the change small." "$OUT"
  # Failure Modes: one distinct task per failing gate.
  grep -qxF -- "- **tests**: 1 task(s) (t3)" "$OUT"
  grep -qxF -- "- **lint**: 1 task(s) (t6)" "$OUT"
  # Category mix across both rounds' task files.
  grep -qxF -- "- feature: 3" "$OUT"
  grep -qxF -- "- maintenance: 1" "$OUT"
  grep -qxF -- "- data-pipeline: 1" "$OUT"
  grep -qxF -- "- uncategorized: 1" "$OUT"
  # The pre-seeded contrastive caches mean claude was never needed.
  [ ! -e "$CLAUDE_CALLS" ]
}

@test "generate_morning_summary: gate stats come from the round history" {
  generate_morning_summary 1 2 "$OUT" "$WD"
  grep -qE '^tests +5/6 pass \(83%\), 1 fail$' "$OUT"
  grep -qE '^lint +5/6 pass \(83%\), 1 fail$' "$OUT"
}

@test "generate_morning_summary: only the matured hypothesis is asked, and the action block agrees" {
  generate_morning_summary 1 2 "$OUT" "$WD"
  grep -qF "**Answer the 1 matured deferred hypothesis question**" "$OUT"
  local deferred
  deferred=$(sed -n '/^## Deferred Evaluation Questions/,/^## Recording/p' "$OUT")
  [[ "$deferred" == *'**h1** (round 1): "the frobnicator will be used weekly"'* ]]
  # h2 is still open (Project State lists it) but not matured: not a question.
  [[ "$deferred" != *'**h2**'* ]]
  # Numbered questions in the deferred section == the action block's N.
  [ "$(printf '%s\n' "$deferred" | grep -cE '^[0-9]+\. ')" -eq 1 ]
}

@test "generate_morning_summary rejects missing arguments without writing" {
  run generate_morning_summary 1 2 "$OUT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage: generate_morning_summary"* ]]
  [ ! -e "$OUT" ]
}
