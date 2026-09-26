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

# The decision-log row this suite binds (log.md has other rows quoting 0/8).
log_row_34() {
  grep -E '^\| 34 \|' "$LOG"
}

@test "the 238,155-token panel figure agrees across results.md, 032, and log row 34" {
  grep -q '238,155' "$RESULTS"
  grep -q '238,155' "$DEC032"
  grep -q '238,155' "$LOG"
}

@test "the ~73% saving figure agrees across all four documents" {
  # Pinned to the full phrases, not a bare ~73%: each of SKILL.md, 032 and
  # log.md states the figure more than once, so an unanchored grep stays green
  # while any single copy drifts. The SKILL count guards against a third copy
  # appearing that this test does not know about.
  grep -qF '73.3% of the red-gated pass' "$RESULTS"
  grep -qF 'measured ~73% when it fires' "$DEC032"
  grep -qF '238,155 tokens = 73% of that pass' "$DEC032"
  grep -qF '× ~73%, P low' "$DEC032"
  log_row_34 | grep -qF 'measured ~73% saving when it fires'
  log_row_34 | grep -qF '238,155-token panel = 73% of the pass'
  grep -qF 'measured at **~73% of the pass**' "$SKILL"
  grep -qF 'expected per-pass value ≈ ~73% ×' "$SKILL"
  [ "$(grep -o '73%' "$SKILL" | wc -l)" -eq 2 ]
}

@test "the primary record's percentage follows from its own addends" {
  # Parse the addends out of results.md rather than restating them here, so a
  # drifted figure in the record (not just in this test) turns this red.
  #   "- Pass **without** #4 = <fc> + <panel> = **<total>**"
  #   "| **panel total (what #4 skips)** | **<panel>** | |"
  #   "- **#4 saving = <panel> tokens = <pct>% of the red-gated pass.**"
  local without panel_row saving fc panel total panel2 saved pct
  without=$(grep -F 'Pass **without** #4 =' "$RESULTS")
  panel_row=$(grep -F 'panel total (what #4 skips)' "$RESULTS")
  # (The throttle case also has a "#4 saving = 0" line; select the one with
  # a percentage.)
  saving=$(grep -F '#4 saving =' "$RESULTS" | grep -F '% of the red-gated pass')
  [ "$(printf '%s\n' "$without" | grep -c .)" -eq 1 ]
  [ "$(printf '%s\n' "$saving" | grep -c .)" -eq 1 ]
  read -r fc panel total < <(printf '%s\n' "$without" \
    | sed -E 's/.*= ([0-9,]+) \+ ([0-9,]+) = \*\*([0-9,]+)\*\*.*/\1 \2 \3/' | tr -d ,)
  panel2=$(printf '%s\n' "$panel_row" | grep -oE '[0-9][0-9,]+' | tr -d , | head -1)
  saved=$(printf '%s\n' "$saving" | sed -E 's/.*saving = ([0-9,]+) tokens.*/\1/' | tr -d ,)
  pct=$(printf '%s\n' "$saving" | sed -E 's/.*tokens = ([0-9.]+)%.*/\1/')
  [[ "$fc" =~ ^[0-9]+$ && "$panel" =~ ^[0-9]+$ && "$total" =~ ^[0-9]+$ ]]
  [ $((fc + panel)) -eq "$total" ]
  [ "$panel" -eq "$panel2" ]
  [ "$saved" -eq "$panel" ]
  [ "$(awk -v p="$panel" -v t="$total" 'BEGIN { printf "%.1f", p / t * 100 }')" = "$pct" ]
}

@test "the 0/8 canon tally agrees across the measurement docs and decisions" {
  grep -q '0/8' "$LEVERS"
  grep -q '0/8' "$DEC032"
  # Row 34 specifically: row 30 also contains "0/8" (an unrelated sweep), so
  # an unanchored grep over log.md cannot fail on row 34 drifting.
  log_row_34 | grep -qF 'Fired 0/8 on the canon'
}

@test "the 225-commit trigger denominator agrees across SKILL, 032, and log" {
  grep -qE '(1.in.|in )225' "$SKILL"
  grep -q '225' "$DEC032"
  grep -q '225' "$LOG"
}
