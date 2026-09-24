#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for business-plan-critique-market-sizing
# evaluation fixtures. Used by health-check to validate fixture ↔ verdict coverage.
#
# The skill grades each of its five lenses with a "**Verdict:**" line from
# Defensible / Plausible / Inflated / Speculative / Not Claimed. Each flawed
# fixture plants one market-sizing flaw aimed at one lens; its EXPECTED_VERDICT
# is the failing set (Inflated|Speculative). verdict_match passes if ANY lens
# carries a failing verdict, so it is a coarse signal; the flaw-specific
# cites_pattern is what shows the right lens caught the right flaw.
#
# Check formats used below (joined with ";;", ERE, case-insensitive):
#   verdict_match        — some **Verdict:** line matches EXPECTED_VERDICT
#   cites_pattern:<ERE>  — report body matches the pattern
#   no_pattern:<ERE>     — report body does not match the pattern
#   no_verdict:<values>  — no **Verdict:** line carries one of these values
#   format_check         — business-plan-critique-market-sizing-format.bats passes
#
# Negatives come from SKILL.md's stub pre-flight: a stub (<500 words AND stub
# markers) must print only the skip line
# ("draft incomplete; market-sizing critique skipped" — the pattern spells ";"
# as "." because KEY_CHECK splits on it); a short complete plan must not be
# skipped. The short complete plan is also the sound plan, checked with
# no_verdict:Inflated. EXPECTED_VERDICT is "None" for both negatives.

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- TAM definition ---

EXPECTED_VERDICT["tc-mkt1-veterinary-inventory.md"]="Inflated|Speculative"
CLAIM_ACCURACY["tc-mkt1-veterinary-inventory.md"]="flawed"  # TAM = $62B global animal-health (product) market, adjacent to inventory software; bottom-up SAM is $52.8M
KEY_CHECK["tc-mkt1-veterinary-inventory.md"]="verdict_match;;cites_pattern:drugs|pharmaceutical|product (spend|sales|revenue)|spend on (the )?products|software (spend|budget|market)|adjacent (industry|category|market)|category (mis)?fit|mismatch|orders? of magnitude;;format_check"

# --- SAM realism ---

EXPECTED_VERDICT["tc-mkt2-public-records-redaction.md"]="Inflated|Speculative"
CLAIM_ACCURACY["tc-mkt2-public-records-redaction.md"]="flawed"  # SAM counts federal (FedRAMP) and state (StateRAMP) agencies, 46% of SAM, with no authorisation until 2028+
KEY_CHECK["tc-mkt2-public-records-redaction.md"]="verdict_match;;cites_pattern:(fedramp|stateramp|certif|authori[sz]).{0,150}(not (yet )?(addressable|serviceable)|gat(e|ed|ing)|until|aspiration|exclud|remov|strip|lack|without|before)|(not (yet )?(addressable|serviceable)|gat(e|ed|ing)|exclud|remov|strip|aspiration).{0,150}(fedramp|stateramp|certif|authori[sz])"

# --- SOM achievability ---

EXPECTED_VERDICT["tc-mkt3-accounts-payable.md"]="Speculative|Inflated"
CLAIM_ACCURACY["tc-mkt3-accounts-payable.md"]="flawed"  # SOM is "1% of SAM, plus a point a year" with no beachhead, customer count or sales plan
KEY_CHECK["tc-mkt3-accounts-payable.md"]="verdict_match;;cites_pattern:beachhead|wedge|how many customers|customer count|number of customers|customers (needed|required)|[0-9,]{3,} customers|sales (capacity|reps?|hiring|team|org)|no (path|mechanism|go.to.market)|linear|s.?curve"

# --- Market timing ---

EXPECTED_VERDICT["tc-mkt4-landscaping-scheduling.md"]="Speculative|Inflated"
CLAIM_ACCURACY["tc-mkt4-landscaping-scheduling.md"]="flawed"  # "why now" = smartphones, cloud adoption, younger owners: decade-long trends, no dated trigger
KEY_CHECK["tc-mkt4-landscaping-scheduling.md"]="verdict_match;;cites_pattern:persistent|decade|why ever|since 20[01][0-9]|not (a |an )?(specific |dated )?(trigger|catalyst|inflection)|no (specific |named |dated )?(trigger|catalyst|inflection)|trend,? not a trigger|true for (years|a decade|over a decade|ten years|the (last|past))"

# --- Comparable benchmarks ---

EXPECTED_VERDICT["tc-mkt5-construction-project-management.md"]="Inflated|Speculative"
CLAIM_ACCURACY["tc-mkt5-construction-project-management.md"]="flawed"  # comp set = the three best-known $100M+ winners (one boom-assisted), no failures or median
KEY_CHECK["tc-mkt5-construction-project-management.md"]="verdict_match;;cites_pattern:cherry.?pick|surviv|selection|outlier|negative comps?|fail(ed|ures?)|median|base rate|unsuccessful|winners;;format_check"

# --- Negatives (stub pre-flight) ---

EXPECTED_VERDICT["tc-mkt6-physio-insurer-billing.md"]="None"
CLAIM_ACCURACY["tc-mkt6-physio-insurer-billing.md"]="sound"  # 425-word complete plan, no stub markers: reconciled TAM, behavioural SAM, beachhead SOM, dated trigger, comps with a failure
KEY_CHECK["tc-mkt6-physio-insurer-billing.md"]="no_pattern:draft incomplete;;no_verdict:Inflated;;format_check"

EXPECTED_VERDICT["tc-mkt7-pet-insurance-marketplace.md"]="None"
CLAIM_ACCURACY["tc-mkt7-pet-insurance-marketplace.md"]="stub"  # 77 words, TODO/TBD/placeholder sections
KEY_CHECK["tc-mkt7-pet-insurance-marketplace.md"]="cites_pattern:draft incomplete. market.sizing critique skipped;;no_pattern:^#+ .*(TAM Definition|SAM Realism|SOM Achievability|Market Timing|Comparable Benchmarks|Overall Assessment);;no_pattern:^\*\*(Verdict|Confidence):"
