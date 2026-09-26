#!/usr/bin/env bats
# @category fast
# @needs-reports performance-reviewer
# Evaluates performance-reviewer skill output against expected severities and
# the mechanism or fix each fixture's planted defect calls for, plus two clean
# negatives that must not draw Critical/High findings.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash performance-reviewer
#
# Then run:
#   bats test/skills/performance-reviewer-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="performance-reviewer"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- Planted defects: Macro × Hot path ---

@test "tc-perf1: ORM N+1 — High, select_related/prefetch_related" {
  eval_fixture "$SKILL" "tc-perf1-orm-n-plus-one.py"
}

@test "tc-perf2: quadratic merge — Critical/High, index by email" {
  eval_fixture "$SKILL" "tc-perf2-quadratic-merge.ts"
}

@test "tc-perf3: unbounded cache — Critical/High, eviction or size cap" {
  eval_fixture "$SKILL" "tc-perf3-unbounded-cache.go"
}

@test "tc-perf4: missing pagination — High/Critical, LIMIT or cursor" {
  eval_fixture "$SKILL" "tc-perf4-missing-pagination.py"
}

@test "tc-perf5: lock across I/O — High/Critical, contention on the mutex" {
  eval_fixture "$SKILL" "tc-perf5-lock-across-io.go"
}

# --- Clean negatives ---

@test "tc-perf6: startup config scan — clean, no Critical/High (cold path)" {
  eval_fixture "$SKILL" "tc-perf6-startup-config-scan.py"
}

@test "tc-perf7: bounded schedule — clean, no Critical/High (N capped)" {
  eval_fixture "$SKILL" "tc-perf7-bounded-schedule.ts"
}
