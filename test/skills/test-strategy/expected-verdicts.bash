#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for test-strategy evaluation fixtures.
# Used by health-check to validate fixture ↔ verdict coverage.
#
# Each fixture is a module with its existing tests below a marker comment.
# Each planted fixture leaves ONE high-risk path untested (a money-rounding
# branch, a retry path, a DST conversion, a concurrency path, a pagination
# loop). test-strategy names gaps "**G1** — file:LINES — <path> — not covered"
# and tags each recommended test "**Priority:** high|medium|low".
#
# Check formats used here (separated by ;; — so no pattern may contain ";"):
#   field_match:Priority=<v> — some **Priority:** line starts with <v>
#   no_field:Priority=<v>    — no **Priority:** line starts with <v>
#   cites_pattern:<ERE>      — report matches <ERE> (case-insensitive, per line)
#   no_pattern:<ERE>         — report never matches <ERE>
#   format_check             — test-strategy-format.bats passes
#
# Every cites_pattern / no_pattern starts with \*\*G[0-9]+\*\* so it only
# matches a gap entry: the fixture text has no G-lines, and the planted path's
# name must appear in the enumerated gap, not just anywhere in the report.
# field_match passes on ANY **Priority:** line, so the gap pattern is the real
# signal. EXPECTED_VERDICT is the Priority the test closing the planted gap
# should get ("None" for the negative, which has no high-risk untested path).

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Planted gaps: one untested high-risk path each ---

EXPECTED_VERDICT["tc-ts1-installment-split.py"]="high"
CLAIM_ACCURACY["tc-ts1-installment-split.py"]="gap"  # remainder-cent loop in split_order never runs: every test total divides evenly
KEY_CHECK["tc-ts1-installment-split.py"]="field_match:Priority=high;;cites_pattern:\*\*G[0-9]+\*\*.*(remainder|leftover|indivisible|not (evenly |exactly )?divisible|divide(s)? unevenly|extra cent|odd cent);;format_check"

EXPECTED_VERDICT["tc-ts2-webhook-client.go"]="high"
CLAIM_ACCURACY["tc-ts2-webhook-client.go"]="gap"  # retry path (429/5xx -> backoff/Retry-After -> next attempt, and giving up after MaxAttempts) never exercised
KEY_CHECK["tc-ts2-webhook-client.go"]="field_match:Priority=high;;cites_pattern:\*\*G[0-9]+\*\*.*(429|5[0-9][0-9]|5xx|Retry-After|backoff|exhaust|MaxAttempts|retryable status|retry loop)"

EXPECTED_VERDICT["tc-ts3-nightly-export-schedule.py"]="high"
CLAIM_ACCURACY["tc-ts3-nightly-export-schedule.py"]="gap"  # _localize's non-round-trip branch (spring-forward nonexistent local time) untested: tests use UTC and a January offset
KEY_CHECK["tc-ts3-nightly-export-schedule.py"]="field_match:Priority=high;;cites_pattern:\*\*G[0-9]+\*\*.*(DST|daylight|spring.?forward|nonexistent|non-existent|skipped (hour|time|local)|_round_trips|round.?trip|clock(s)? (change|jump))"

EXPECTED_VERDICT["tc-ts4-token-cache.ts"]="high"
CLAIM_ACCURACY["tc-ts4-token-cache.ts"]="gap"  # concurrent get() calls sharing the in-flight refresh promise: every test awaits calls one at a time
KEY_CHECK["tc-ts4-token-cache.ts"]="field_match:Priority=high;;cites_pattern:\*\*G[0-9]+\*\*.*(concurren|in.?flight|simultaneous|parallel|overlapping|single.?flight|dedup|already (in progress|pending|refreshing|running)|share[sd]? (the |a |one |single )?(refresh|promise|fetch));;format_check"

EXPECTED_VERDICT["tc-ts5-order-sync.py"]="high"
CLAIM_ACCURACY["tc-ts5-order-sync.py"]="gap"  # iter_orders following next_cursor: FakeClient always returns next_cursor=None, so only one page is ever read
KEY_CHECK["tc-ts5-order-sync.py"]="field_match:Priority=high;;cites_pattern:\*\*G[0-9]+\*\*.*(multi.?page|second page|subsequent page|more than one page|next page|follow(s|ing)? (the )?(next_)?cursor|next_cursor (is )?(set|non.?empty|present|truthy|not (none|empty))|pagination)"

# --- Negative: risky paths all covered, only trivial code untested ---

EXPECTED_VERDICT["tc-ts6-duration-parser.py"]="None"
CLAIM_ACCURACY["tc-ts6-duration-parser.py"]="clean"  # every error branch is in the parametrized reject table; only __repr__ is untested
KEY_CHECK["tc-ts6-duration-parser.py"]="no_pattern:\*\*G[0-9]+\*\*.*(unknown|unrecogni[sz]ed|invalid|unsupported) unit;;no_field:Priority=high;;format_check"
