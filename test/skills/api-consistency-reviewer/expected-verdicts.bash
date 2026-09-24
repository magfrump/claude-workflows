#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for api-consistency-reviewer evaluation fixtures.
# Used by health-check to validate fixture ↔ verdict coverage.
#
# Each fixture is one self-contained file: several pre-existing sibling surfaces
# establish the convention, and the block(s) fenced by BEGIN/END CHANGE UNDER
# REVIEW comments are the change (see runner.bash). The "verdict" is the expected
# severity tier from the skill's scale (Breaking / Inconsistent / Minor /
# Informational), checked by severity_match against the **Severity:** lines;
# pipe-separated alternatives cover tiers that are a genuine judgment call.
# KEY_CHECK patterns verify the report names both the new surface and the
# convention it departs from. Clean negatives use no_severity instead.

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- REST handlers ---

EXPECTED_VERDICT["tc-api1-invoices-routes.ts"]="Inconsistent"
CLAIM_ACCURACY["tc-api1-invoices-routes.ts"]="bug"  # New list endpoint uses page/per_page + {items,total}; siblings use limit/cursor + {data,next_cursor}
KEY_CHECK["tc-api1-invoices-routes.ts"]="severity_match;;cites_pattern:cursor;;cites_pattern:per_page|page.based|offset;;format_check"

EXPECTED_VERDICT["tc-api2-billing-handlers.py"]="Inconsistent|Breaking"
CLAIM_ACCURACY["tc-api2-billing-handlers.py"]="bug"  # New handler returns {success,error_message}; siblings use error_response() {error:{code,message}}
KEY_CHECK["tc-api2-billing-handlers.py"]="severity_match;;cites_pattern:error_message;;cites_pattern:error_response|envelope|error.code"

EXPECTED_VERDICT["tc-api7-webhooks-api.py"]="Inconsistent"
CLAIM_ACCURACY["tc-api7-webhooks-api.py"]="bug"  # Request target_url/event_types come back as url/events; siblings echo request field names
KEY_CHECK["tc-api7-webhooks-api.py"]="severity_match;;cites_pattern:target_url;;cites_pattern:asymmetr|round.trip|mismatch|differ|echo|mirror|event_types"

# --- Exported library / SDK functions ---

EXPECTED_VERDICT["tc-api3-client-sdk.ts"]="Inconsistent|Minor"
CLAIM_ACCURACY["tc-api3-client-sdk.ts"]="bug"  # fetchTeam where every sibling single-resource read is get<Noun>
KEY_CHECK["tc-api3-client-sdk.ts"]="severity_match;;cites_pattern:fetchTeam;;cites_pattern:getTeam|getUser|getProject"

EXPECTED_VERDICT["tc-api8-storage-client.py"]="None"
CLAIM_ACCURACY["tc-api8-storage-client.py"]="clean"  # get/list/delete_object mirror get/list/delete_bucket exactly
KEY_CHECK["tc-api8-storage-client.py"]="no_severity:Breaking|Inconsistent;;cites_pattern:get_bucket|list_buckets|delete_bucket;;format_check"

# --- CLI flags ---

EXPECTED_VERDICT["tc-api4-deploy-cli.py"]="Inconsistent|Minor"
CLAIM_ACCURACY["tc-api4-deploy-cli.py"]="bug"  # rollback --dry_run where deploy/scale use kebab-case --dry-run
KEY_CHECK["tc-api4-deploy-cli.py"]="severity_match;;cites_pattern:dry_run;;cites_pattern:dry-run|kebab"

# --- Config schema ---

EXPECTED_VERDICT["tc-api5-worker-config.go"]="Breaking"
CLAIM_ACCURACY["tc-api5-worker-config.go"]="bug"  # New dead_letter_queue key is required with no default; existing worker.yaml files stop loading
KEY_CHECK["tc-api5-worker-config.go"]="severity_match;;cites_pattern:dead_letter_queue|DeadLetterQueue;;cites_pattern:default|optional|existing (config|deploy|worker|yaml|file)"

# --- Event payloads ---

EXPECTED_VERDICT["tc-api6-order-events.ts"]="Inconsistent|Breaking"
CLAIM_ACCURACY["tc-api6-order-events.ts"]="bug"  # order.cancelled carries timestamp (epoch ms) where siblings carry occurred_at (ISO-8601)
KEY_CHECK["tc-api6-order-events.ts"]="severity_match;;cites_pattern:occurred_at;;cites_pattern:timestamp|epoch"
