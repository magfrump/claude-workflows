#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for api-consistency-reviewer evaluation fixtures.
# Used by health-check to validate fixture ↔ verdict coverage.
#
# Each fixture is one self-contained file: several pre-existing sibling surfaces
# establish the convention, and the block(s) fenced by BEGIN/END CHANGE UNDER
# REVIEW comments are the change (see runner.bash). The "verdict" is the expected
# severity tier from the skill's scale (Breaking / Inconsistent / Minor /
# Informational), checked by finding_match against the **Severity:** lines;
# pipe-separated alternatives cover tiers that are a genuine judgment call.
# KEY_CHECK patterns verify the report names both the new surface and the
# convention it departs from. Clean negatives use no_severity instead.
# finding_match:<tiers>=<ERE>[&&<ERE>...] needs ONE finding (a "####" block or a
# summary-table row) carrying both a tier from EXPECTED_VERDICT and a line
# matching each ERE outside lines copied from the fixture, so an unrelated
# finding with the right tier cannot pass (2026-09-26 audit T5).

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- REST handlers ---

EXPECTED_VERDICT["tc-api1-invoices-routes.ts"]="Inconsistent"
CLAIM_ACCURACY["tc-api1-invoices-routes.ts"]="bug"  # New list endpoint uses page/per_page + {items,total}; siblings use limit/cursor + {data,next_cursor}
KEY_CHECK["tc-api1-invoices-routes.ts"]="finding_match:Inconsistent=cursor&&per_page|page.based|offset|page/per_page;;format_check"

EXPECTED_VERDICT["tc-api2-billing-handlers.py"]="Inconsistent|Breaking"
CLAIM_ACCURACY["tc-api2-billing-handlers.py"]="bug"  # New handler returns {success,error_message}; siblings use error_response() {error:{code,message}}
KEY_CHECK["tc-api2-billing-handlers.py"]="finding_match:Inconsistent|Breaking=error_message&&error_response|envelope|error.code|\{ ?.?error.? ?: ?\{"

EXPECTED_VERDICT["tc-api7-webhooks-api.py"]="Inconsistent"
CLAIM_ACCURACY["tc-api7-webhooks-api.py"]="bug"  # Request target_url/event_types come back as url/events; siblings echo request field names
KEY_CHECK["tc-api7-webhooks-api.py"]="finding_match:Inconsistent=target_url&&target_url[^.]{0,120}\burl\b|\burl\b[^.]{0,120}target_url|event_types[^.]{0,120}\bevents\b|\bevents\b[^.]{0,120}event_types|asymmetr|round.?trip"

# --- Exported library / SDK functions ---

EXPECTED_VERDICT["tc-api3-client-sdk.ts"]="Inconsistent|Minor"
CLAIM_ACCURACY["tc-api3-client-sdk.ts"]="bug"  # fetchTeam where every sibling single-resource read is get<Noun>
KEY_CHECK["tc-api3-client-sdk.ts"]="finding_match:Inconsistent|Minor=fetchTeam&&getTeam|getUser|getProject|get<"

EXPECTED_VERDICT["tc-api8-storage-client.py"]="None"
CLAIM_ACCURACY["tc-api8-storage-client.py"]="clean"  # get/list/delete_object mirror get/list/delete_bucket exactly
KEY_CHECK["tc-api8-storage-client.py"]="no_severity:Breaking|Inconsistent;;cites_pattern:get_bucket|list_buckets|delete_bucket;;format_check"

# --- CLI flags ---

EXPECTED_VERDICT["tc-api4-deploy-cli.py"]="Inconsistent|Minor"
CLAIM_ACCURACY["tc-api4-deploy-cli.py"]="bug"  # rollback --dry_run where deploy/scale use kebab-case --dry-run
KEY_CHECK["tc-api4-deploy-cli.py"]="finding_match:Inconsistent|Minor=dry_run&&dry-run|kebab"

# --- Config schema ---

EXPECTED_VERDICT["tc-api5-worker-config.go"]="Breaking"
CLAIM_ACCURACY["tc-api5-worker-config.go"]="bug"  # New dead_letter_queue key is required with no default; existing worker.yaml files stop loading
KEY_CHECK["tc-api5-worker-config.go"]="finding_match:Breaking=dead_letter_queue|DeadLetterQueue&&(no|without( a)?|lacks( a)?|missing( a)?) default|(existing|current|deployed|older?|every) [a-z. ]{0,30}(configs?|configuration|deployments?|workers?|yaml|files?)[^.]{0,100}(fail|break|stop|reject|refuse|error|no longer|won.t)|(fail|break|stop|reject|refuse)[^.]{0,60}(to load|loading|on (startup|load))|backwards?.?(compat|incompat)|(make|made|mark) (it |the (field|key) )?optional|default (value|to|it)"

# --- Event payloads ---

EXPECTED_VERDICT["tc-api6-order-events.ts"]="Inconsistent|Breaking"
CLAIM_ACCURACY["tc-api6-order-events.ts"]="bug"  # order.cancelled carries timestamp (epoch ms) where siblings carry occurred_at (ISO-8601)
KEY_CHECK["tc-api6-order-events.ts"]="finding_match:Inconsistent|Breaking=occurred_at&&timestamp|epoch"
