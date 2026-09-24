#!/usr/bin/env bats
# @category fast
# Evaluates dependency-upgrade output: each planted decisive fact (a breaking
# change to a called API, a security advisory, an unmet runtime minimum, a
# peer conflict, a required intermediate version) is named and drives the
# Recommendation or Breaking change impact; the negative, whose breaking
# changes touch only unused APIs, is not rated Don't upgrade and lists no
# unused API as affecting project code.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash dependency-upgrade
#
# Then run:
#   bats test/skills/dependency-upgrade-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="dependency-upgrade"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- Planted decisive facts, one per fixture ---

@test "tc-dep1: timeout switches from ms to seconds on called createClient — Upgrade soon/Defer, impact not None, names the 5000/30000 values; report is well-formed" {
  eval_fixture "$SKILL" "tc-dep1-http-client.md"
}

@test "tc-dep2: TARN-2026-0117 traversal in extract_all on uploaded bundles — Upgrade now, names the reachable path; evidence Unverified; report is well-formed" {
  eval_fixture "$SKILL" "tc-dep2-archive-import.md"
}

@test "tc-dep3: ledgerline 2.0 needs Node 22, project runs node:20 — Defer/Don't upgrade, names 20 vs 22; report is well-formed" {
  eval_fixture "$SKILL" "tc-dep3-invoice-renderer.md"
}

@test "tc-dep4: formwright 6 needs React 19, datepane peers on React 18 — Defer/Don't upgrade, names the datepane conflict" {
  eval_fixture "$SKILL" "tc-dep4-signup-forms.md"
}

@test "tc-dep5: strata-orm 1.8 → 3.2 must step through 2.x migrate-meta — impact not None, names the intermediate step" {
  eval_fixture "$SKILL" "tc-dep5-analytics-orm.md"
}

# --- Negative: breaking changes touch only unused APIs ---

@test "tc-dep6: pixelgrain 5.0 breaks only unused APIs — not Don't upgrade, impact not Moderate/Significant, no unused API in the affects table; evidence Unverified; report is well-formed" {
  eval_fixture "$SKILL" "tc-dep6-thumbnail-service.md"
}
