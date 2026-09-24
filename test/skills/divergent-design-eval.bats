#!/usr/bin/env bats
# @category fast
# Evaluates divergent-design (router) output: three tradeoff-bearing decisions
# must route into workflows/divergent-design.md (read it, emit its console trail
# and recommendation banner) and prune the option each planted hard constraint
# kills; open-ended ideation and a single-obvious-answer question must not route.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash divergent-design
#
# Then run:
#   bats test/skills/divergent-design-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="divergent-design"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- Decisions: route and prune ---

@test "tc-dd1: job queue, no new infra + same-transaction enqueue — routes, recommends the Postgres queue" {
  eval_fixture "$SKILL" "tc-dd1-job-queue-no-new-infra"
}

@test "tc-dd2: date library, Moment over the bundle cap — routes, prunes Moment, does not recommend it" {
  eval_fixture "$SKILL" "tc-dd2-date-library-moment-maintenance"
}

@test "tc-dd3: live updates, proxies strip Upgrade — routes, prunes WebSockets, does not recommend them" {
  eval_fixture "$SKILL" "tc-dd3-live-updates-proxy-strips-websockets"
}

# --- Negatives: do not route ---

@test "tc-dd4: open-ended hackathon ideation — no DD trail or banner" {
  eval_fixture "$SKILL" "tc-dd4-open-ended-hackathon-themes"
}

@test "tc-dd5: typo fix with one correct answer — no DD trail, answers 'receive'" {
  eval_fixture "$SKILL" "tc-dd5-single-obvious-typo-fix"
}
