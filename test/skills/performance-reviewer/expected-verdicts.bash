#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for performance-reviewer evaluation fixtures.
# Used by health-check to validate fixture ↔ verdict coverage.
#
# performance-reviewer produces severity-tagged findings per file, not verdicts
# per claim. The "verdict" here is the expected severity tier from the skill's
# own scale (Critical / High / Medium / Low / Informational), checked by
# finding_match against the **Severity:** lines. Where SKILL.md's rubric makes
# the tier a judgment call (Macro × Hot anchors at High but "escalate to Critical
# when unbounded / DoS-enabling"), both tiers are allowed. Clean negatives carry
# EXPECTED_VERDICT="none" and use no_severity to catch false positives.
# finding_match:<tiers>=<ERE>[&&<ERE>...] needs ONE finding (a "####" block or a
# summary-table row) carrying both a tier from EXPECTED_VERDICT and a line
# matching each ERE outside lines copied from the fixture, so an unrelated
# finding with the right tier cannot pass (2026-09-26 audit T5).

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Planted defects: Macro × Hot path ---

EXPECTED_VERDICT["tc-perf1-orm-n-plus-one.py"]="High"
CLAIM_ACCURACY["tc-perf1-orm-n-plus-one.py"]="bug"  # Per-order customer/items/shipping queries on a 50-row page
KEY_CHECK["tc-perf1-orm-n-plus-one.py"]="finding_match:High=N ?\+ ?1|select_related|prefetch_related|annotate|\bjoins?\b;;format_check"

EXPECTED_VERDICT["tc-perf2-quadratic-merge.ts"]="Critical|High"
CLAIM_ACCURACY["tc-perf2-quadratic-merge.ts"]="bug"  # findIndex inside loop over an unbounded upload: O(n*m) per request
KEY_CHECK["tc-perf2-quadratic-merge.ts"]="finding_match:Critical|High=quadratic|O\(n.?2\)|O\(n²\)|O\(n ?. ?m\)|O\(m ?. ?n\)|new (Map|Set)|hash ?(map|set|table)|keyed by email|index(ed)? by email"

EXPECTED_VERDICT["tc-perf3-unbounded-cache.go"]="Critical|High"
CLAIM_ACCURACY["tc-perf3-unbounded-cache.go"]="bug"  # Package-lifetime map keyed by user-typed address, no eviction
KEY_CHECK["tc-perf3-unbounded-cache.go"]="finding_match:Critical|High=unbounded|evict|LRU|TTL|max.?(size|entries)|size.?(limit|cap|bound)|grows? without"

EXPECTED_VERDICT["tc-perf4-missing-pagination.py"]="High|Critical"
CLAIM_ACCURACY["tc-perf4-missing-pagination.py"]="bug"  # Whole org audit trail returned, no LIMIT/cursor
KEY_CHECK["tc-perf4-missing-pagination.py"]="finding_match:High|Critical=paginat|LIMIT|cursor|keyset|unbounded"

EXPECTED_VERDICT["tc-perf5-lock-across-io.go"]="High|Critical"
CLAIM_ACCURACY["tc-perf5-lock-across-io.go"]="bug"  # Global mutex held across the upstream HTTP call serializes all requests
KEY_CHECK["tc-perf5-lock-across-io.go"]="finding_match:High|Critical=serializ|contention|one (request|caller) at a time|held (across|during|while)|(outside|after|before) the (lock|mutex|critical section)|narrow"

# --- Clean negatives: look slow, fine at their stated scale ---

EXPECTED_VERDICT["tc-perf6-startup-config-scan.py"]="none"
CLAIM_ACCURACY["tc-perf6-startup-config-scan.py"]="clean"  # Pairwise scan, but once at process start over a small manifest
KEY_CHECK["tc-perf6-startup-config-scan.py"]="no_severity:Critical|High;;cites_pattern:cold|startup|start-up|once"

EXPECTED_VERDICT["tc-perf7-bounded-schedule.ts"]="none"
CLAIM_ACCURACY["tc-perf7-bounded-schedule.ts"]="clean"  # Nested loops over <=21 validated shifts x 7 days in a handler
KEY_CHECK["tc-perf7-bounded-schedule.ts"]="no_severity:Critical|High;;cites_pattern:MAX_SHIFTS|(^|[^0-9-])21([^0-9-]|$)|bounded|capped;;format_check"
