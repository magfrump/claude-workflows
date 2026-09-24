#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for cowen-critique evaluation fixtures.
# Used by cowen-critique-eval.bats, and by health-check to validate
# fixture <-> verdict coverage.
#
# cowen-critique grades nothing: SKILL.md prescribes no **Verdict:** or
# **Severity:** lines, and cowen-critique-format.bats forbids the reviewer and
# fact-check scales. EXPECTED_VERDICT is therefore "None" for every fixture and
# verdict_match / severity_match are never used.
#
# Every full critique must use the words "boring", "revealed", "contingent",
# "market", "inversion" and "sub-claim" (SKILL.md section rules), so no
# cites_pattern keys on those words. Each one names the specific fact in the
# draft that the planted flaw turns on.
#
# CLAIM_ACCURACY names the planted flaw (or "stub" / "complete" for the
# pre-flight negatives), kept here and out of the fixture file.
#
# KEY_CHECK encodes behavioral assertions, separated by ;; (double semicolon).
# Patterns are ERE, case-insensitive, and must not contain a semicolon.
# Formats used here:
#   cites_pattern:REGEX — report must contain text matching REGEX
#   no_pattern:REGEX    — report must NOT contain text matching REGEX
#   format_check        — run cowen-critique-format.bats against the report

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Planted flaws: one cognitive move each ---

EXPECTED_VERDICT["tc-cow1-library-visits.md"]="None"
CLAIM_ACCURACY["tc-cow1-library-visits.md"]="boring-explanation"  # visits -42% blamed on an attention crisis; branch hours cut 60->36 (-40%) in 2021, mentioned in passing
KEY_CHECK["tc-cow1-library-visits.md"]="cites_pattern:(opening|branch|library|standard|reduced|shorter|fewer|cut|trimmed) hours|hours (were |was |being )?(cut|trimmed|reduced|slashed)|60 to 36|36 (hours|a week);;format_check"

EXPECTED_VERDICT["tc-cow2-office-return.md"]="None"
CLAIM_ACCURACY["tc-cow2-office-return.md"]="revealed-vs-stated"  # 78% say they value in-person work, yet the optional office runs at 14% desk occupancy
KEY_CHECK["tc-cow2-office-return.md"]="cites_pattern:occupan|14 ?(%|percent)|empty (desks|office|floors)|(don.t|do not|aren.t|are not|rarely|seldom|not) (actually )?(come|coming|show|showing|use|using) (in|up|the office|it)|stay(ing)? (home|away)|vote[sd]? with their feet;;format_check"

EXPECTED_VERDICT["tc-cow3-school-calendar.md"]="None"
CLAIM_ACCURACY["tc-cow3-school-calendar.md"]="contingent-as-natural"  # long summer treated as 'the natural rhythm of childhood' and timeless
KEY_CHECK["tc-cow3-school-calendar.md"]="cites_pattern:agrar|farm|harvest|19th|nineteenth|other countries|abroad|international|Japan|Korea|German|Australia|England|Europe|histor(ical|y)[^.]{0,60}(summer|calendar|holiday|break)|(summer|calendar|holiday|break)[^.]{0,60}histor(ical|y)"

EXPECTED_VERDICT["tc-cow4-open-plan.md"]="None"
CLAIM_ACCURACY["tc-cow4-open-plan.md"]="fails-inversion"  # +56% chat volume read as collaboration; equally evidence people stopped talking in person
KEY_CHECK["tc-cow4-open-plan.md"]="cites_pattern:substitut|instead of (talk|speak|face|conversation|in.person|walk)|rather than (talk|speak|walk|face)|retreat|escap|avoid(ing)? (talk|conversation|face|interaction|noise)|face.to.face[^.]{0,80}(fell|drop|declin|decreas|less|fewer|down)|(fewer|less) (face.to.face|in.person|spoken)|headphones?[^.]{0,80}(chat|messag)|(chat|messag)[^.]{0,80}headphones?"

EXPECTED_VERDICT["tc-cow5-office-conversions.md"]="None"
CLAIM_ACCURACY["tc-cow5-office-conversions.md"]="ignored-market-signal"  # claims a ~25% conversion margin on $95/sqft towers but never asks why no developer has taken it
KEY_CHECK["tc-cow5-office-conversions.md"]="cites_pattern:(why|if)[^.]{0,60}(no|nobody|no one|haven.t|hasn.t|have not|has not|aren.t|isn.t)[^.]{0,60}(developer|investor|buyer|capital|lender|owner)|(developers?|investors?|buyers?|lenders?|owners?|capital)[^.]{0,60}(haven.t|have not|hasn.t|has not|aren.t|not already|would already|already have|already be)|twenty.dollar|\\\$20 bill|sidewalk"

# --- Pre-flight negatives ---

EXPECTED_VERDICT["tc-cow6-transit-fares.md"]="None"
CLAIM_ACCURACY["tc-cow6-transit-fares.md"]="stub"  # 92 words, TODO markers, empty sections -> skip line only
KEY_CHECK["tc-cow6-transit-fares.md"]="cites_pattern:draft incomplete.{1,3}persona pass skipped;;no_pattern:^#{1,3} .*(Cowen|Argument.*Decomposed|Survives the Inversion|Boring Explanation|Revealed vs|Contingent Assumptions|What the Market Says|Overall Assessment|Factual Foundation);;no_pattern:load.bearing objection;;no_pattern:no fact.check report provided"

EXPECTED_VERDICT["tc-cow7-farmers-market.md"]="None"
CLAIM_ACCURACY["tc-cow7-farmers-market.md"]="complete"  # 414 words, no stub markers -> full critique
KEY_CHECK["tc-cow7-farmers-market.md"]="no_pattern:persona pass skipped;;format_check"
