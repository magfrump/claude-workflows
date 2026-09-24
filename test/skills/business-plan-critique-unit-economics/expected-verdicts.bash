#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expectations for business-plan-critique-unit-economics
# evaluation fixtures. Used by health-check to validate fixture <-> verdict coverage.
#
# This skill grades nothing: no **Verdict:** or **Severity:** lines. So
# EXPECTED_VERDICT is "Any" for every fixture (verdict_match is never used) and
# the checks are:
#   cites_pattern:<ERE>  the report names the planted flaw (or, where the
#                        corrected figure is unambiguous, recomputes it)
#   no_pattern:<ERE>     the report must not match — the stub's critique
#                        headings, the short plan's skip line, or a false
#                        complaint about something the sound plan does right
#   format_check         business-plan-critique-unit-economics-format.bats
# Patterns are case-insensitive ERE and never contain ';' (the list separator).
# Each planted-flaw fixture targets one of SKILL.md's five lenses; the other
# numbers in it are kept internally consistent.

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Planted flaws, one lens each ---

EXPECTED_VERDICT["tc-ue1-dental-scheduling-saas.md"]="Any"
CLAIM_ACCURACY["tc-ue1-dental-scheduling-saas.md"]="flaw"  # CAC: $1,500 blended hides founder-network $150 vs paid $4,875, modelled flat while growth shifts to paid
KEY_CHECK["tc-ue1-dental-scheduling-saas.md"]="cites_pattern:blend;;cites_pattern:founder|patel|study.?club|alumni|personal network|warm (intro|network);;cites_pattern:4,?875|[$] ?4\.9 ?k;;format_check"

EXPECTED_VERDICT["tc-ue2-fresh-pet-food-subscription.md"]="Any"
CLAIM_ACCURACY["tc-ue2-fresh-pet-food-subscription.md"]="flaw"  # LTV: $1,033 is revenue/churn at 38% GM, margin-weighted ~$393 (LTV/CAC ~2.2x not 5.7x)
KEY_CHECK["tc-ue2-fresh-pet-food-subscription.md"]="cites_pattern:margin.?(weight|adjust|based)|gross.?margin.{0,40}(LTV|lifetime value)|(LTV|lifetime value).{0,80}(revenue|top.?line)|revenue.?based LTV;;cites_pattern:[$] ?3[89][0-9]|2\.[12] ?x"

EXPECTED_VERDICT["tc-ue3-construction-project-software.md"]="Any"
CLAIM_ACCURACY["tc-ue3-construction-project-software.md"]="flaw"  # Contribution margin: CSMs (1 per 25 accounts, $4,400/acct/yr) and implementation ($9,333/new customer) booked as fixed overhead
KEY_CHECK["tc-ue3-construction-project-software.md"]="cites_pattern:(customer success|CSM|implementation|onboarding).{0,150}(variable|per.?(account|customer)|scale|headcount)|(variable|per.?(account|customer)).{0,150}(customer success|CSM|implementation|onboarding);;cites_pattern:4,?400|24(\.[0-9])? ?%|5[78](\.[0-9])? ?%|9,?333|24 CSMs;;format_check"

EXPECTED_VERDICT["tc-ue4-hr-compliance-platform.md"]="Any"
CLAIM_ACCURACY["tc-ue4-hr-compliance-platform.md"]="flaw"  # Payback: 16-month payback treated as self-funding after month 3, $3M ask vs ~$5.3M cumulative need over 18 months
KEY_CHECK["tc-ue4-hr-compliance-platform.md"]="cites_pattern:payback;;cites_pattern:self.?fund|working.capital|unrecovered|shortfall|run(s)? out of (cash|money)|out of cash|under.?(fund|siz)|cash (gap|trough|low point)"

EXPECTED_VERDICT["tc-ue5-bookkeeping-service.md"]="Any"
CLAIM_ACCURACY["tc-ue5-bookkeeping-service.md"]="flaw"  # Gross-margin trajectory: 41% to 75% rests on auto-approval going 22% to 80% when it moved 18% to 22% last year
KEY_CHECK["tc-ue5-bookkeeping-service.md"]="cites_pattern:automat;;cites_pattern:undemonstrated|not (yet )?(been )?(demonstrated|proven|shown)|unproven|hypothes|no evidence|track record|18 ?%"

# --- Negatives: the stub pre-flight ---

EXPECTED_VERDICT["tc-ue6-waste-hauling-marketplace.md"]="None"
CLAIM_ACCURACY["tc-ue6-waste-hauling-marketplace.md"]="stub"  # <100 words, TODOs and empty sections: must print only the skip line
KEY_CHECK["tc-ue6-waste-hauling-marketplace.md"]="cites_pattern:draft incomplete. unit.economics critique skipped;;no_pattern:^#+ .*(CAC|LTV|Contribution Margin|Payback Period|Gross.?Margin Trajectory) Assessment|^#+ *(Factual Foundation|Overall Assessment)|^# .*Unit.?Economics.*Critique"

EXPECTED_VERDICT["tc-ue7-veterinary-inventory-saas.md"]="None"
CLAIM_ACCURACY["tc-ue7-veterinary-inventory-saas.md"]="sound"  # <500 words, no stub markers, sound economics with CAC reported per channel: full critique, no false blended-CAC complaint
KEY_CHECK["tc-ue7-veterinary-inventory-saas.md"]="no_pattern:draft incomplete|critique skipped;;format_check;;no_pattern:(does not|doesn.t|fails to) (break|decompos|split|separat)[a-z]* (out )?(its |the )?CAC|reports only (a )?blended CAC"
