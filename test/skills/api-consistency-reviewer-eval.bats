#!/usr/bin/env bats
# @category fast
# Evaluates api-consistency-reviewer skill output against expected severities and
# the convention each fixture's planted inconsistency departs from.
#
# Prerequisites: generate reports first:
#   bash test/skills/generate-reports.bash api-consistency-reviewer
#
# Then run:
#   bats test/skills/api-consistency-reviewer-eval.bats
#
# Reports are model-dependent. Test failures on model change are expected and
# valuable — they signal behavioral differences in the new model.

load eval-helpers

SKILL="api-consistency-reviewer"

setup() {
  load_expected_verdicts "$SKILL"
}

# --- REST handlers ---

@test "tc-api1: divergent pagination — Inconsistent, names the cursor convention" {
  eval_fixture "$SKILL" "tc-api1-invoices-routes.ts"
}

@test "tc-api2: divergent error shape — Inconsistent, cites error_response envelope" {
  eval_fixture "$SKILL" "tc-api2-billing-handlers.py"
}

@test "tc-api7: request/response asymmetry — Inconsistent, target_url vs url" {
  eval_fixture "$SKILL" "tc-api7-webhooks-api.py"
}

# --- Exported library / SDK functions ---

@test "tc-api3: verb drift — Inconsistent/Minor, fetchTeam vs get<Noun>" {
  eval_fixture "$SKILL" "tc-api3-client-sdk.ts"
}

@test "tc-api8: clean negative — no Breaking/Inconsistent finding" {
  eval_fixture "$SKILL" "tc-api8-storage-client.py"
}

# --- CLI flags ---

@test "tc-api4: flag case drift — Inconsistent/Minor, --dry_run vs --dry-run" {
  eval_fixture "$SKILL" "tc-api4-deploy-cli.py"
}

# --- Config schema ---

@test "tc-api5: required config key without default — Breaking" {
  eval_fixture "$SKILL" "tc-api5-worker-config.go"
}

# --- Event payloads ---

@test "tc-api6: event timestamp drift — Inconsistent, timestamp vs occurred_at" {
  eval_fixture "$SKILL" "tc-api6-order-events.ts"
}
