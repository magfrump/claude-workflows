#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for divergent-design fixtures.
# Used by health-check to validate fixture ↔ verdict coverage.
#
# divergent-design is a router. A fixture with 3+ tradeoff-bearing options must
# route: the model reads workflows/divergent-design.md (transcript check) and
# emits the workflow's compact console trail ("◇ step 1 diverge  N candidates")
# and its recommendation banner ("▶ recommend [ID] ..."). Each routed fixture
# also plants one hard constraint that should prune a named option, and checks
# that the output prunes it. The two negatives (open-ended ideation, a single
# obvious answer) fail the trigger test and must not produce the trail.
#
# Check formats used here (separated by ;; — so no pattern may contain ";"):
#   tool_called:<Tool>=<ERE> — some <Tool> call's input matches <ERE> (transcript)
#   cites_pattern:<ERE>      — report matches <ERE> (case-insensitive, per line)
#   no_pattern:<ERE>         — report never matches <ERE>
#   cites_count:<N>=<ERE>    — at least N report lines match <ERE> (the open-ended
#                              negative must still brainstorm: a list of ideas,
#                              which a refusal is not)
#
# The glyphs ◇ and ▶ are left out of patterns: "step 1 diverge" and "recommend"
# followed by a bracketed ID are the load-bearing tokens, and a model that drops
# the glyph still followed the workflow.

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Decisions: must route, and prune the option the planted constraint kills ---

EXPECTED_VERDICT["tc-dd1-job-queue-no-new-infra"]="routes"
CLAIM_ACCURACY["tc-dd1-job-queue-no-new-infra"]="flaw"  # No Redis/AWS and two-quarter procurement kills Redis and SQS; enqueue-in-the-same-transaction kills both again and the cron; the Postgres SKIP LOCKED queue is the only survivor
KEY_CHECK["tc-dd1-job-queue-no-new-infra"]="tool_called:Read=workflows/divergent-design\.md;;cites_pattern:step 1 +diverge;;cites_pattern:recommend +\[?[0-9]+\]?[^.]{0,80}(postgres|skip.?locked|database.?(backed|queue))"

EXPECTED_VERDICT["tc-dd2-date-library-moment-maintenance"]="routes"
CLAIM_ACCURACY["tc-dd2-date-library-moment-maintenance"]="flaw"  # Moment + timezone data is 74 KB gz against a 60 KB cap with 38 KB already spent, and is in maintenance mode — it must be pruned despite the team knowing it
KEY_CHECK["tc-dd2-date-library-moment-maintenance"]="tool_called:Read=workflows/divergent-design\.md;;cites_pattern:step 1 +diverge;;cites_pattern:moment[^.]{0,160}(74|over (the )?(budget|cap)|exceed|bust|breaks? the|60 ?kb|maintenance|legacy|prun|discard|eliminat|✗|⚠)|(prun|discard|eliminat)[^.]{0,80}moment;;no_pattern:recommend +\[?[0-9]+\]?[^.]{0,40}moment"

EXPECTED_VERDICT["tc-dd3-live-updates-proxy-strips-websockets"]="routes"
CLAIM_ACCURACY["tc-dd3-live-updates-proxy-strips-websockets"]="flaw"  # 30% of customers' proxies strip Upgrade, so WebSockets silently fail for them; updates are server-to-client only, so nothing needs WebSockets
KEY_CHECK["tc-dd3-live-updates-proxy-strips-websockets"]="tool_called:Read=workflows/divergent-design\.md;;cites_pattern:step 1 +diverge;;cites_pattern:websockets?[^.]{0,160}(proxy|proxies|upgrade|30 ?%|strip|prun|discard|eliminat|✗|⚠)|(proxy|proxies|upgrade)[^.]{0,160}websockets?;;no_pattern:recommend +\[?[0-9]+\]?[^.]{0,40}websockets?"

# --- Negatives: fail the trigger test, so no DD trail ---

EXPECTED_VERDICT["tc-dd4-open-ended-hackathon-themes"]="does not route"
CLAIM_ACCURACY["tc-dd4-open-ended-hackathon-themes"]="sound"  # Genuinely open-ended ideation, no competing options — SKILL.md: "skill does not apply; open-ended brainstorming does. Stop here."
KEY_CHECK["tc-dd4-open-ended-hackathon-themes"]="no_pattern:step 1 +diverge;;no_pattern:recommend +\[[0-9]+\];;cites_count:3=^[[:space:]]*(([-*+]|[0-9]+[.)]|#{2,4})[[:space:]]+.*[[:alpha:]]{4}|\*\*[^*]*[[:alpha:]]{4})"

EXPECTED_VERDICT["tc-dd5-single-obvious-typo-fix"]="does not route"
CLAIM_ACCURACY["tc-dd5-single-obvious-typo-fix"]="sound"  # Two options, no tradeoff axis, one is simply correct — fails "3+ viable options that differ on a tradeoff axis"
KEY_CHECK["tc-dd5-single-obvious-typo-fix"]="no_pattern:step 1 +diverge;;no_pattern:recommend +\[[0-9]+\];;cites_pattern:receive"
