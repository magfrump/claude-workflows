#!/usr/bin/env bash
# Machine-parseable expected verdicts for fact-check evaluation fixtures.
# Used by fact-check-eval.bats to validate skill output.
#
# CLAIM_ACCURACY documents whether each fixture's claims are intentionally
# accurate, inaccurate, or unknown. This answers "what is this fixture testing?"
# without putting the answer in the fixture file itself, which the model could
# read and use to shortcut the fact-checking process.
#
# KEY_CHECK encodes behavioral assertions, separated by ;; (double semicolon).
# Pipe (|) is reserved for regex alternation within cites_pattern values.
# Formats:
#   verdict_match          — verdict must match EXPECTED_VERDICT
#   cites_pattern:REGEX    — report must contain text matching REGEX (case-insensitive)
#   no_critique            — report must not contain critique/argument-quality language
#   max_claims:N           — report should check at most N claims
#   min_claims:N           — report should check at least N claims
#   format_check           — run the full format BATS suite against this report
#   web_search_used        — tool log must show web search was invoked
#   Multiple checks separated by ;; (double semicolon)

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Category 1: Claim Type Coverage ---
# These test whether the skill correctly handles each type of checkable claim.
# Verdicts are "Any" because the test is about search behavior, not verdict accuracy.

EXPECTED_VERDICT["tc-1.1-specific-numbers.md"]="Any"
CLAIM_ACCURACY["tc-1.1-specific-numbers.md"]="inaccurate"  # CMS reports $4.9T (17.6%); fixture says $4.3T (17.3%)
KEY_CHECK["tc-1.1-specific-numbers.md"]="cites_pattern:CMS|BEA|Centers for Medicare|National Health Expenditure;;web_search_used"

EXPECTED_VERDICT["tc-1.2-named-policies.md"]="Any"
CLAIM_ACCURACY["tc-1.2-named-policies.md"]="inaccurate"  # SB 458 is a middle-housing land division bill, not tenant appreciation
KEY_CHECK["tc-1.2-named-policies.md"]="cites_pattern:SB 458|Senate Bill 458;;web_search_used"

EXPECTED_VERDICT["tc-1.3-attributed-facts.md"]="Accurate"
CLAIM_ACCURACY["tc-1.3-attributed-facts.md"]="accurate"  # MN legalized recreational cannabis May 2023
KEY_CHECK["tc-1.3-attributed-facts.md"]="verdict_match;;web_search_used"

EXPECTED_VERDICT["tc-1.4-causal-claims.md"]="Any"
CLAIM_ACCURACY["tc-1.4-causal-claims.md"]="unknown"  # 15% rent drop + causal link both need verification
KEY_CHECK["tc-1.4-causal-claims.md"]="cites_pattern:rent|housing|construction;;web_search_used"

EXPECTED_VERDICT["tc-1.5-comparisons.md"]="Mostly accurate|Disputed"
CLAIM_ACCURACY["tc-1.5-comparisons.md"]="imprecise"  # "Most" OECD countries is debatable
KEY_CHECK["tc-1.5-comparisons.md"]="verdict_match;;web_search_used"

EXPECTED_VERDICT["tc-1.6-anecdotes.md"]="Unverified"
CLAIM_ACCURACY["tc-1.6-anecdotes.md"]="unknown"  # Specific California daycare anecdote, likely unfindable
KEY_CHECK["tc-1.6-anecdotes.md"]="verdict_match;;web_search_used"

# --- Category 2: Verdict Distribution ---
# Each fixture targets a specific verdict on the scale.

EXPECTED_VERDICT["tc-2.1-accurate.md"]="Accurate"
CLAIM_ACCURACY["tc-2.1-accurate.md"]="accurate"  # 2020 Census counted 331.4 million — confirmed
KEY_CHECK["tc-2.1-accurate.md"]="verdict_match;;cites_pattern:Census Bureau|census.gov"

EXPECTED_VERDICT["tc-2.2-mostly-accurate.md"]="Mostly accurate"
CLAIM_ACCURACY["tc-2.2-mostly-accurate.md"]="imprecise"  # Conflates two different survey findings
KEY_CHECK["tc-2.2-mostly-accurate.md"]="verdict_match;;cites_pattern:survey|conflat"

EXPECTED_VERDICT["tc-2.3-disputed.md"]="Disputed"
CLAIM_ACCURACY["tc-2.3-disputed.md"]="disputed"  # UW vs Berkeley studies disagree on Seattle min wage effects
KEY_CHECK["tc-2.3-disputed.md"]="verdict_match;;cites_pattern:UW|University of Washington|Berkeley|study|studies"

EXPECTED_VERDICT["tc-2.4-inaccurate.md"]="Inaccurate"
CLAIM_ACCURACY["tc-2.4-inaccurate.md"]="inaccurate"  # France restricted homeschooling with exceptions, not banned
KEY_CHECK["tc-2.4-inaccurate.md"]="verdict_match;;cites_pattern:restrict|exception|not.*(ban|eliminat)"

EXPECTED_VERDICT["tc-2.5-unverified.md"]="Unverified"
CLAIM_ACCURACY["tc-2.5-unverified.md"]="unknown"  # Specific Vermont bakery anecdote, no primary source findable
KEY_CHECK["tc-2.5-unverified.md"]="verdict_match"

# --- Category 3: Non-Checkable Content ---
# Tests whether the skill correctly skips opinions, predictions, and separates checkable from non-checkable.

EXPECTED_VERDICT["tc-3.1-opinions.md"]="skip"
CLAIM_ACCURACY["tc-3.1-opinions.md"]="not_applicable"  # Pure opinions — nothing to check
KEY_CHECK["tc-3.1-opinions.md"]="max_claims:1"

EXPECTED_VERDICT["tc-3.2-predictions.md"]="skip"
CLAIM_ACCURACY["tc-3.2-predictions.md"]="not_applicable"  # Forward-looking predictions, but specific numbers within predictions are checkable
KEY_CHECK["tc-3.2-predictions.md"]="max_claims:1"

EXPECTED_VERDICT["tc-3.3-mixed.md"]="Any"
CLAIM_ACCURACY["tc-3.3-mixed.md"]="mixed"  # Worker count + median pay accurate; FL waitlist imprecise; Denmark comparison imprecise
KEY_CHECK["tc-3.3-mixed.md"]="min_claims:3;;max_claims:5"

# --- Category 4: Ambiguity Handling ---

EXPECTED_VERDICT["tc-4.1-misleading.md"]="Any"
CLAIM_ACCURACY["tc-4.1-misleading.md"]="misleading"  # "Best healthcare in the world" is ambiguous by metric
KEY_CHECK["tc-4.1-misleading.md"]="cites_pattern:innovat|scientific|ranking|lead.*in|specific|overall|ambig|metric"

EXPECTED_VERDICT["tc-4.2-conflated-stats.md"]="Mostly accurate|Inaccurate|Disputed"
CLAIM_ACCURACY["tc-4.2-conflated-stats.md"]="imprecise"  # Conflates separate survey findings; severity judgment varies by model
KEY_CHECK["tc-4.2-conflated-stats.md"]="verdict_match;;cites_pattern:survey|conflat|different|distinct"

# --- Category 5: Output Format ---

EXPECTED_VERDICT["tc-5.1-multi-claim.md"]="Any"
CLAIM_ACCURACY["tc-5.1-multi-claim.md"]="mixed"  # Multiple claims across childcare policy
KEY_CHECK["tc-5.1-multi-claim.md"]="min_claims:3;;format_check"

# --- Category 6: Behavioral Guardrails ---

EXPECTED_VERDICT["tc-6.1-accurate-weak-argument.md"]="Accurate|Mostly accurate|Mostly Accurate|Inaccurate"
CLAIM_ACCURACY["tc-6.1-accurate-weak-argument.md"]="accurate_at_time_of_writing"  # Facts were correct but some figures may go stale (C3 freshness risk)
KEY_CHECK["tc-6.1-accurate-weak-argument.md"]="no_critique"

# tc-6.2 is a cross-cutting requirement (web search for every claim), tested via web_search_used checks above

EXPECTED_VERDICT["tc-6.3-obvious-but-wrong.md"]="Inaccurate"
CLAIM_ACCURACY["tc-6.3-obvious-but-wrong.md"]="inaccurate"  # "Great Wall visible from space" is a well-known myth
KEY_CHECK["tc-6.3-obvious-but-wrong.md"]="verdict_match;;min_claims:1"
