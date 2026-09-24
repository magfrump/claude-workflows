#!/usr/bin/env bash
# shellcheck disable=SC2034  # Arrays are used by test files that source this file
# Machine-parseable expected verdicts for self-eval fixtures.
# Used by health-check to validate fixture ↔ verdict coverage.
#
# self-eval scores five dimensions in a table, one row each:
#   | <Dimension> | Strong/Adequate/Weak | <justification> |
# so these checks match table rows, not **Field:** lines. Each planted fixture
# makes ONE dimension Weak by the rubric's own definition; the negative
# (tc-se4) must not score Test coverage or Overlap Weak; tc-se5 has no rubric
# and must stop with SKILL.md's repo-only message instead of scoring.
#
# Check formats used here (separated by ;; — so no pattern may contain ";"):
#   cites_pattern:<ERE>  — report matches <ERE> (case-insensitive, per line)
#   no_pattern:<ERE>     — report never matches <ERE>
#   format_check         — self-eval-format.bats passes
#
# Row patterns allow bold (`| **Test coverage** | **Weak** |`) via [ *]*.

declare -gA EXPECTED_VERDICT
declare -gA CLAIM_ACCURACY
declare -gA KEY_CHECK

# --- Planted weaknesses, one dimension each ---

EXPECTED_VERDICT["tc-se1-no-tests-no-outputs"]="Test coverage: Weak"
CLAIM_ACCURACY["tc-se1-no-tests-no-outputs"]="flaw"  # A clear, distinct skill with nothing under test/ and nothing in docs/reviews/ — the rubric's Weak: "No tests written and no example outputs produced"
KEY_CHECK["tc-se1-no-tests-no-outputs"]="cites_pattern:\|[ *]*test coverage[ *]*\|[ *]*weak;;format_check"

EXPECTED_VERDICT["tc-se2-duplicates-migration-review"]="Overlap and redundancy: Weak"
CLAIM_ACCURACY["tc-se2-duplicates-migration-review"]="flaw"  # Same five checks, same severity scale, same rollout section, same triggers as the sibling sql-migration-review — "similar output on similar input"
KEY_CHECK["tc-se2-duplicates-migration-review"]="cites_pattern:\|[ *]*overlap and redundancy[ *]*\|[ *]*weak;;cites_pattern:sql-migration-review;;format_check"

EXPECTED_VERDICT["tc-se3-vague-trigger"]="Trigger clarity: Weak"
CLAIM_ACCURACY["tc-se3-vague-trigger"]="flaw"  # "Use it when it would be helpful" — no trigger phrase, no situation, matches everything
KEY_CHECK["tc-se3-vague-trigger"]="cites_pattern:\|[ *]*trigger clarity[ *]*\|[ *]*weak;;format_check"

# --- Negatives ---

EXPECTED_VERDICT["tc-se4-well-tested-distinct"]="no Weak on Test coverage or Overlap"
CLAIM_ACCURACY["tc-se4-well-tested-distinct"]="sound"  # Format and eval suites under test/, a fixture, and an example output in docs/reviews/; no sibling diffs API specs
KEY_CHECK["tc-se4-well-tested-distinct"]="cites_pattern:\|[ *]*test coverage[ *]*\|[ *]*(strong|adequate);;no_pattern:\|[ *]*(test coverage|overlap and redundancy)[ *]*\|[ *]*weak;;format_check"

EXPECTED_VERDICT["tc-se5-rubric-missing"]="stops"
CLAIM_ACCURACY["tc-se5-rubric-missing"]="sound"  # No docs/evaluation-rubric.md — SKILL.md Step 2: stop before scoring, "Do not substitute a remembered or improvised rubric"
KEY_CHECK["tc-se5-rubric-missing"]="cites_pattern:needs .?docs/evaluation-rubric\.md|docs/evaluation-rubric\.md.{0,60}(does not exist|doesn.t exist|not found|missing|absent)|(no|missing|without|cannot find|could not find|couldn.t find)[^.]{0,40}docs/evaluation-rubric\.md;;no_pattern:\|[ *]*(testability investment|test coverage|trigger clarity)[ *]*\|[ *]*(strong|adequate|weak)"
