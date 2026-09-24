#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for matrix-analysis fixtures.
# Used by health-check to validate fixture ↔ verdict coverage.
#
# matrix-analysis must dispatch one sub-agent per criterion (SKILL.md "Execution
# rules"), checked on the transcript with subagents_min:<criteria count>. Its
# ratings are table cells, not **Field:** lines: the Comparison Matrix uses
# ++/+/-/? (or the requested numeric scale) and each Detailed Evaluations table
# uses Strong/Adequate/Weak, so row checks accept either form.
#
# Check formats used here (separated by ;; — so no pattern may contain ";"):
#   subagents_min:<N>    — at least N top-level Agent dispatches (transcript)
#   cites_pattern:<ERE>  — report matches <ERE> (case-insensitive, per line)
#   no_pattern:<ERE>     — report never matches <ERE>
#   format_check         — matrix-analysis-format.bats passes

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Planted facts ---

EXPECTED_VERDICT["tc-ma1-agpl-library-in-closed-saas.md"]="Kestrel weak on licence; recommend another"
CLAIM_ACCURACY["tc-ma1-agpl-library-in-closed-saas.md"]="flaw"  # Kestrel is AGPL-3.0 with no commercial licence, and Brightline serves customers over the network: AGPL's network clause would oblige publishing Brightline's source, which Legal forbids. Best on every other criterion, so a tally-style matrix would recommend it
KEY_CHECK["tc-ma1-agpl-library-in-closed-saas.md"]="subagents_min:4;;cites_pattern:\|[ *]*kestrel[ *]*\|[ *]*(weak|- |--)|agpl[^.]{0,160}(network|source|disclos|publish|copyleft|incompatib|not (allowed|permitted)|block|violat|disqualif|rule)|(network|copyleft)[^.]{0,120}agpl;;cites_pattern:agpl;;cites_pattern:(recommend|choose|go with|pick|select|adopt)[^.]{0,60}(folio|parchment);;format_check"

EXPECTED_VERDICT["tc-ma2-one-ci-provider-dominates.md"]="recommend Quarry CI"
CLAIM_ACCURACY["tc-ma2-one-ci-provider-dominates.md"]="flaw"  # Quarry is cheapest, fastest and the only one with native arm64 at x86 price — best on every criterion
KEY_CHECK["tc-ma2-one-ci-provider-dominates.md"]="subagents_min:3;;cites_pattern:(recommend|choose|go with|pick|select|adopt)[^.]{0,60}quarry;;format_check"

EXPECTED_VERDICT["tc-ma3-numeric-scale-requested.md"]="numeric 1-5 cells"
CLAIM_ACCURACY["tc-ma3-numeric-scale-requested.md"]="flaw"  # The user asked for 1-5 scores; SKILL.md Step 2: "If the user requests numeric scoring ... use that scale instead"
KEY_CHECK["tc-ma3-numeric-scale-requested.md"]="subagents_min:3;;cites_pattern:\|[ *]*(beacon|siren|klaxon)[ *]*\|[ *]*[1-5]( ?/ ?5)?[ *]*(\||[ -]);;no_pattern:\|[ *]*(strong|adequate|weak)[ *]*\|"

# --- Negative: a genuine tie must not be called ---

EXPECTED_VERDICT["tc-ma4-mirrored-tie-no-priority.md"]="conditional, no winner claimed"
CLAIM_ACCURACY["tc-ma4-mirrored-tie-no-priority.md"]="sound"  # Lumen wins latency and tuning, Harrow wins cost by 2.6x, and the user says they have not chosen between cost and speed — the honest recommendation is conditional
KEY_CHECK["tc-ma4-mirrored-tie-no-priority.md"]="subagents_min:3;;no_pattern:(is|as) (the )?(clear|obvious|outright|unambiguous) (winner|choice|pick|favou?rite);;cites_pattern:if [^.]{0,60}(cost|budget|price|spend|latency|speed|fast|performance)[^.]{0,100}(lumen|harrow)|(lumen|harrow)[^.]{0,100}if [^.]{0,60}(cost|budget|price|spend|latency|speed|fast|performance)|depends (on )?(whether|which)[^.]{0,80}(cost|budget|price|latency|speed);;format_check"
