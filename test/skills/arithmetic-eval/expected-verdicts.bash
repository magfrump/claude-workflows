#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for arithmetic-eval fixtures.
# Used by health-check to validate fixture ↔ verdict coverage.
#
# Runs are FIXTURE_BASH=deny-record: every Bash call is denied and only
# recorded. A fixture with a derived figure must show a Mode 1 evaluator call
# whose expression gives the right value (mode1_equiv:). Several expressions are
# valid routes, e.g. computing the figure or checking the claimed one backwards,
# so each lists the values any of them would give. The no-arithmetic negative
# must not reach for Bash at all.
#
# Check formats used here (separated by ;;):
#   mode1_equiv:<v>[~tol]|...  — a denied Bash call is SKILL.md's Mode 1 block
#                                (wrapper exact, program AST-equal) and its
#                                expression evaluates to one of the values
#                                (relative tolerance, default 1e-6)
#   no_tool_called:<Tool>      — no call of <Tool> in the transcript
#   cites_pattern:<ERE>        — the report says so (the no-arithmetic negative
#                                must answer the prompt: no derived figures)

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Derived figures: must route through Mode 1 ---

EXPECTED_VERDICT["tc-ae1-inference-tokens-tenfold.md"]="routes"
CLAIM_ACCURACY["tc-ae1-inference-tokens-tenfold.md"]="flaw"  # 4750 / 0.0025 * 1000 = 1.9 billion, not 19 billion (off by 10x)
KEY_CHECK["tc-ae1-inference-tokens-tenfold.md"]="mode1_equiv:1900000000|1900000|47500"

EXPECTED_VERDICT["tc-ae2-growth-percent-overstated.md"]="routes"
CLAIM_ACCURACY["tc-ae2-growth-percent-overstated.md"]="flaw"  # (3.1 - 2.4) / 2.4 = 29.2%, not 42%
KEY_CHECK["tc-ae2-growth-percent-overstated.md"]="mode1_equiv:29.1666666667|0.291666666667|1.29166666667|3.408"

EXPECTED_VERDICT["tc-ae3-marathon-km-wrong.md"]="routes"
CLAIM_ACCURACY["tc-ae3-marathon-km-wrong.md"]="flaw"  # 26.2 mi * 1.609344 = 42.16 km, not 45.2 (tolerance covers 1.609 and 1.61 as the factor)
KEY_CHECK["tc-ae3-marathon-km-wrong.md"]="mode1_equiv:42.16~0.002|28.09~0.002"

EXPECTED_VERDICT["tc-ae4-sessions-correct.md"]="routes"
CLAIM_ACCURACY["tc-ae4-sessions-correct.md"]="sound"  # 1.2M * 4 = 4.8M is right, and still must be verified, not eyeballed (backward: 4.8M / 4 = 1.2M; 4.8M / 1.2M = 4 is left out as too unspecific)
KEY_CHECK["tc-ae4-sessions-correct.md"]="mode1_equiv:4800000|1200000"

# --- Negative: nothing to compute ---

EXPECTED_VERDICT["tc-ae5-no-arithmetic.md"]="does not route"
CLAIM_ACCURACY["tc-ae5-no-arithmetic.md"]="sound"  # No derived figures, so no evaluator call
KEY_CHECK["tc-ae5-no-arithmetic.md"]="no_tool_called:Bash;;cites_pattern:no (derived|computed|calculated)|no (numbers|figures|numeric|arithmetic|calculations?|math|quantit)|none of the (numbers|figures)|nothing (to (check|verify|compute|calculate)|is derived)|(not|isn.t|aren.t) (derived|computed|calculated)"
