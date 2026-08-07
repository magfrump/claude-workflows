#!/usr/bin/env bats
# @category fast
# Drift guard binding the 032 #4 measurement figures across the four documents
# that state them (modelled on sandbox-tool-map-drift.bats). The 2026-08-07
# review found these figures quoted in SKILL prose, decision 032, log row 34,
# and the run artifact — this suite fails if any copy drifts from the primary
# record or from its own arithmetic.
#
# Primary record: runs/review-arms/baseline-2026-08-06/hunt-verify/results.md
#
# Usage: bats test/lever-measurement-drift.bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SKILL="$REPO_ROOT/skills/code-review/SKILL.md"
  DEC032="$REPO_ROOT/docs/decisions/032-review-loop-token-reduction-levers.md"
  LOG="$REPO_ROOT/docs/decisions/log.md"
  RESULTS="$REPO_ROOT/runs/review-arms/baseline-2026-08-06/hunt-verify/results.md"
  LEVERS="$REPO_ROOT/runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md"
  for f in "$SKILL" "$DEC032" "$LOG" "$RESULTS" "$LEVERS"; do
    [ -f "$f" ] || skip "missing $f"
  done
}

@test "the 238,155-token panel figure agrees across results.md, 032, and log row 34" {
  grep -q '238,155' "$RESULTS"
  grep -q '238,155' "$DEC032"
  grep -q '238,155' "$LOG"
}

@test "the ~73% saving figure agrees across all four documents" {
  grep -q '73.3%' "$RESULTS"
  grep -qE '~?73%' "$DEC032"
  grep -qE '~?73%' "$LOG"
  grep -qE '~73%' "$SKILL"
}

@test "the primary record's percentage follows from its own addends" {
  # 238,155 / (86,824 + 238,155) = 73.28% — results.md rounds to 73.3%.
  pct=$(awk 'BEGIN { printf "%.1f", 238155 / (86824 + 238155) * 100 }')
  [ "$pct" = "73.3" ]
  grep -q '86,824' "$RESULTS"
  grep -q '324,979' "$RESULTS"
}

@test "the 0/8 canon tally agrees across the measurement docs and decisions" {
  grep -q '0/8' "$LEVERS"
  grep -q '0/8' "$DEC032"
  grep -q '0/8' "$LOG"
}

@test "the 225-commit trigger denominator agrees across SKILL, 032, and log" {
  grep -qE '(1.in.|in )225' "$SKILL"
  grep -q '225' "$DEC032"
  grep -q '225' "$LOG"
}
