#!/usr/bin/env bats
# @category fast
# Guards attrition() in scripts/crb-subset-leaderboard.py, added by the
# 2026-08-18 pre-mortem (narrative 3).
#
# Why this exists: the comparison subset is defined as "the PRs our tool has a
# judged row for". A cell that produced nothing injectable — voided by
# containment, budget-exhausted, or dropped at MAX_ATTEMPTS — never reaches the
# judge and so removes itself from the denominator without appearing anywhere in
# the table. The attrition is not random: the cells that fail are the ones the
# pipeline struggled on, so the surviving subset is selected FOR pipeline
# success and the recall it yields is biased in our own favour. The table
# printed "3 PR(s)" and that read as a scoping choice rather than as loss.
#
# Hermetic: synthetic evaluations/run-meta in BATS_TEST_TMPDIR. It does read the
# real runs/review-arms/crb/instances.json for the slug -> PR-url mapping, which
# is the same coupling the script has in production and is read-only.

setup_file() {
  export REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export SCRIPT="$REPO_ROOT/scripts/crb-subset-leaderboard.py"
  export MANIFEST="$REPO_ROOT/runs/review-arms/crb/instances.json"
  export TOOL=mfc-pipeline-e8
}

# Build an evaluations.json in which $TOOL has a judged row on the first N
# manifest slugs, plus a rival tool on all of them so the ranking is non-trivial.
make_evals() {
  python3 - "$MANIFEST" "$1" "$TOOL" "$BATS_TEST_TMPDIR/evaluations.json" <<'PY'
import json, sys
man = json.load(open(sys.argv[1])); n = int(sys.argv[2]); tool = sys.argv[3]
slugs = sorted(man)
evals = {}
for i, s in enumerate(slugs):
    url = man[s]["url"]
    evals[url] = {"rival-tool": {"tp": 2, "fp": 1, "fn": 3,
                                 "total_candidates": 3, "total_golden": 5}}
    if i < n:
        evals[url][tool] = {"tp": 3, "fp": 1, "fn": 2,
                            "total_candidates": 4, "total_golden": 5}
json.dump(evals, open(sys.argv[4], "w"))
PY
}

# run-meta describing a sweep over every manifest slug, with $1 = space-separated
# slugs marked voided.
make_run_meta() {
  python3 - "$MANIFEST" "$BATS_TEST_TMPDIR/run-meta.json" "${1:-}" <<'PY'
import json, sys
man = json.load(open(sys.argv[1]))
voided = sys.argv[3].split()
slugs = sorted(man)
json.dump({"arm": "crb-pipeline",
           "requested_instances": slugs,
           "cells": {s: {"cost_usd": 12.0, "voided_containment": s in voided}
                     for s in slugs},
           "missing_cells": [], "voided_cells": voided,
           "total_cost_usd": 60.0}, open(sys.argv[2], "w"))
PY
}

board() {
  run python3 "$SCRIPT" --tool "$TOOL" \
    --evaluations "$BATS_TEST_TMPDIR/evaluations.json" \
    --run-meta "$BATS_TEST_TMPDIR/run-meta.json" "$@"
}

@test "no attrition warning when every attempted cell was judged" {
  make_evals 5; make_run_meta
  board
  [ "$status" -eq 0 ]
  [[ "$output" != *"SUBSET ATTRITION"* ]]
  [[ "$output" == *"5 PR(s)"* ]]
}

@test "cells that never reached the judge are named, with a reason" {
  make_evals 3; make_run_meta
  board
  [ "$status" -eq 0 ]
  [[ "$output" == *"SUBSET ATTRITION: 2 of 5"* ]]
  [[ "$output" == *"no judged row"* ]]
  # The ranking still renders — this warns, it does not refuse.
  [[ "$output" == *"3 PR(s)"* ]]
}

@test "a containment-voided cell is reported as voided, not as unjudged" {
  make_evals 4; make_run_meta "sentry-greptile-PR5"
  board
  [ "$status" -eq 0 ]
  [[ "$output" == *"sentry-greptile-PR5"* ]]
  [[ "$output" == *"voided by a post-run containment failure"* ]]
}

@test "attrition is reported under --all-prs too (subset scope is not the question)" {
  make_evals 3; make_run_meta
  board --all-prs
  [ "$status" -eq 0 ]
  [[ "$output" == *"SUBSET ATTRITION: 2 of 5"* ]]
}

@test "attrition appears in the markdown body, not only on stderr" {
  make_evals 3; make_run_meta
  run python3 "$SCRIPT" --tool "$TOOL" --markdown \
    --evaluations "$BATS_TEST_TMPDIR/evaluations.json" \
    --run-meta "$BATS_TEST_TMPDIR/run-meta.json" 2>/dev/null
  [ "$status" -eq 0 ]
  [[ "$output" == *"> !! SUBSET ATTRITION"* ]]
}

@test "a missing run-meta says attrition was NOT checked rather than staying silent" {
  make_evals 3
  run python3 "$SCRIPT" --tool "$TOOL" \
    --evaluations "$BATS_TEST_TMPDIR/evaluations.json" \
    --run-meta "$BATS_TEST_TMPDIR/does-not-exist.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"attrition NOT checked"* ]]
}
