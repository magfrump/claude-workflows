#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for code-fact-check evaluation fixtures.
# Used by code-fact-check-eval.bats to validate skill output.
#
# See fact-check/expected-verdicts.bash for format documentation.
# Checks separated by ;; (double semicolon). Pipe (|) reserved for regex alternation.

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Category 1: Claim Type Coverage ---

EXPECTED_VERDICT["tc-c1.1-behavioral.js"]="Incorrect"
CLAIM_ACCURACY["tc-c1.1-behavioral.js"]="inaccurate"  # Docstring says "returns null", code returns undefined
KEY_CHECK["tc-c1.1-behavioral.js"]="verdict_match;;cites_pattern:undefined|null"

EXPECTED_VERDICT["tc-c1.2-performance.js"]="Incorrect"
CLAIM_ACCURACY["tc-c1.2-performance.js"]="inaccurate"  # Comment says O(n), nested loops make it O(n^2)
KEY_CHECK["tc-c1.2-performance.js"]="verdict_match;;cites_pattern:O\\(n|nested|loop"

EXPECTED_VERDICT["tc-c1.3-architectural.js"]="Incorrect"
CLAIM_ACCURACY["tc-c1.3-architectural.js"]="inaccurate"  # "Only caller" is false; wsAuthHandler also calls validateToken
KEY_CHECK["tc-c1.3-architectural.js"]="verdict_match;;cites_pattern:wsAuthHandler|caller"

EXPECTED_VERDICT["tc-c1.4-invariant.js"]="Incorrect"
CLAIM_ACCURACY["tc-c1.4-invariant.js"]="inaccurate"  # "Never null" violated by optional chaining (can be undefined)
KEY_CHECK["tc-c1.4-invariant.js"]="verdict_match;;cites_pattern:optional.chaining|undefined|\\?\\."

EXPECTED_VERDICT["tc-c1.5-configuration.js"]="Verified"
CLAIM_ACCURACY["tc-c1.5-configuration.js"]="accurate"  # 300 seconds = 5 minutes, comment matches code
KEY_CHECK["tc-c1.5-configuration.js"]="verdict_match"

EXPECTED_VERDICT["tc-c1.6-reference.js"]="Verified|Unverifiable"
CLAIM_ACCURACY["tc-c1.6-reference.js"]="unknown"  # References issue #1234; depends on gh availability
KEY_CHECK["tc-c1.6-reference.js"]="verdict_match"

EXPECTED_VERDICT["tc-c1.7-staleness.js"]="Stale"
CLAIM_ACCURACY["tc-c1.7-staleness.js"]="inaccurate"  # Comment says validateInput() but function is now sanitizeInput()
KEY_CHECK["tc-c1.7-staleness.js"]="verdict_match;;cites_pattern:validateInput|sanitizeInput|renamed"

# --- Category 2: Verdict Distribution ---

EXPECTED_VERDICT["tc-c2.1-verified.js"]="Verified"
CLAIM_ACCURACY["tc-c2.1-verified.js"]="accurate"  # Code does throw TypeError on empty input
KEY_CHECK["tc-c2.1-verified.js"]="verdict_match"

EXPECTED_VERDICT["tc-c2.2-mostly-accurate.js"]="Mostly accurate"
CLAIM_ACCURACY["tc-c2.2-mostly-accurate.js"]="imprecise"  # O(n) claim but sort makes it O(n log n)
KEY_CHECK["tc-c2.2-mostly-accurate.js"]="verdict_match;;cites_pattern:sort|log"

EXPECTED_VERDICT["tc-c2.3-stale.js"]="Stale"
CLAIM_ACCURACY["tc-c2.3-stale.js"]="inaccurate"  # Comment says 5 retries, code does 3
KEY_CHECK["tc-c2.3-stale.js"]="verdict_match;;cites_pattern:5|3|retri"

EXPECTED_VERDICT["tc-c2.4-incorrect.js"]="Incorrect"
CLAIM_ACCURACY["tc-c2.4-incorrect.js"]="inaccurate"  # Docstring says creates directory, code throws
KEY_CHECK["tc-c2.4-incorrect.js"]="verdict_match;;cites_pattern:throw|creat"

EXPECTED_VERDICT["tc-c2.5-unverifiable.py"]="Unverifiable"
CLAIM_ACCURACY["tc-c2.5-unverifiable.py"]="unknown"  # Thread-safety claim in complex concurrency code
KEY_CHECK["tc-c2.5-unverifiable.py"]="verdict_match"

# --- Category 4: Non-Checkable Content ---

EXPECTED_VERDICT["tc-c4-skip-targets.js"]="skip"
CLAIM_ACCURACY["tc-c4-skip-targets.js"]="not_applicable"  # Design rationale, TODOs, license, trivial restatements
KEY_CHECK["tc-c4-skip-targets.js"]="max_claims:0"

# --- Category 5: Ambiguity Handling ---

EXPECTED_VERDICT["tc-c5.1-thread-safety-partial.py"]="Any"
CLAIM_ACCURACY["tc-c5.1-thread-safety-partial.py"]="misleading"  # Locally safe but calls shared-state code
KEY_CHECK["tc-c5.1-thread-safety-partial.py"]="cites_pattern:shared.state|thread|safe|mislead"

EXPECTED_VERDICT["tc-c5.2-intended-vs-actual.js"]="Incorrect"
CLAIM_ACCURACY["tc-c5.2-intended-vs-actual.js"]="inaccurate"  # Intent was 3 retries, actual is 2 (off-by-one)
KEY_CHECK["tc-c5.2-intended-vs-actual.js"]="verdict_match;;cites_pattern:2|3|off.by.one|actual"

# --- Category 6: Output Format ---

EXPECTED_VERDICT["tc-c6.1-multi-claim.js"]="Any"
CLAIM_ACCURACY["tc-c6.1-multi-claim.js"]="mixed"  # Multiple claims with varied verdicts
KEY_CHECK["tc-c6.1-multi-claim.js"]="min_claims:5;;format_check"

# --- Category 8: Edge Cases / Negative Test Fixtures ---
# Tests whether the skill gracefully handles degenerate inputs rather than producing confused analysis.

EXPECTED_VERDICT["tc-c8.1-empty.js"]="skip"
CLAIM_ACCURACY["tc-c8.1-empty.js"]="not_applicable"  # Empty file — nothing to check
KEY_CHECK["tc-c8.1-empty.js"]="max_claims:0"

EXPECTED_VERDICT["tc-c8.2-no-comments.js"]="skip"
CLAIM_ACCURACY["tc-c8.2-no-comments.js"]="not_applicable"  # Code with no comments or docstrings
KEY_CHECK["tc-c8.2-no-comments.js"]="max_claims:0"

EXPECTED_VERDICT["tc-c8.3-binary-content.js"]="skip"
CLAIM_ACCURACY["tc-c8.3-binary-content.js"]="not_applicable"  # Binary/garbled content, not code
KEY_CHECK["tc-c8.3-binary-content.js"]="max_claims:0"

EXPECTED_VERDICT["tc-c8.4-extremely-short.js"]="skip"
CLAIM_ACCURACY["tc-c8.4-extremely-short.js"]="not_applicable"  # Single assignment, no claims
KEY_CHECK["tc-c8.4-extremely-short.js"]="max_claims:0"
