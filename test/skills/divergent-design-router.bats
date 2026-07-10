#!/usr/bin/env bats
# @category fast
# Validates the ROUTER CONTRACT of the divergent-design skill.
#
# Unlike the *-format.bats suites, this skill produces no report of its own:
# divergent-design is a thin router that hands off to workflows/divergent-design.md
# (per decision 004, anti-redundancy). A report-format test therefore does not
# fit. Instead we validate the SKILL.md source directly — that it carries the
# router frontmatter, points at the workflow, keeps the trigger-test contract,
# and stays a stub rather than duplicating the workflow it routes to.
#
# Usage: bats test/skills/divergent-design-router.bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  SKILL="$REPO_ROOT/skills/divergent-design/SKILL.md"
  WORKFLOW="$REPO_ROOT/workflows/divergent-design.md"
  [ -f "$SKILL" ] || skip "divergent-design SKILL.md not found at $SKILL"
  SKILL_CONTENT=$(tr -d '\r' < "$SKILL")
}

# Extract YAML frontmatter (content between first pair of --- delimiters)
extract_frontmatter() {
  awk '/^---$/ { n++; next } n==1 { print } n>=2 { exit }' "$1"
}

# --- Frontmatter contract ---

@test "skill has required frontmatter fields (name, description, when/trigger)" {
  local frontmatter
  frontmatter=$(extract_frontmatter "$SKILL")
  [ -n "$frontmatter" ]
  echo "$frontmatter" | grep -qE '^name:[[:space:]]*divergent-design'
  echo "$frontmatter" | grep -qE '^description:'
  echo "$frontmatter" | grep -qE '^(trigger|when):'
}

# --- Title ---

@test "skill identifies itself as a router in its title" {
  echo "$SKILL_CONTENT" | grep -qiE '^# .*Divergent Design.*router'
}

# --- Router contract: hands off to the workflow ---

@test "skill points at the divergent-design workflow file" {
  echo "$SKILL_CONTENT" | grep -qE 'workflows/divergent-design\.md'
}

@test "the workflow file it routes to actually exists" {
  [ -f "$WORKFLOW" ]
}

# --- Trigger-test contract ---

@test "skill states the 3+ tradeoff-bearing options trigger test" {
  echo "$SKILL_CONTENT" | grep -qiE '3\+ viable options'
  echo "$SKILL_CONTENT" | grep -qiE 'tradeoff axis'
}

@test "skill defines the brainstorming-supersession boundary" {
  # The router exists to compete with open-ended brainstorming at selection time;
  # the contract must name both the supersede case and the fall-through-to-brainstorming case.
  echo "$SKILL_CONTENT" | grep -qiE 'brainstorming'
  echo "$SKILL_CONTENT" | grep -qiE 'supersede'
}

# --- Anti-redundancy: stays a stub, does not duplicate the workflow ---

@test "skill is a thin stub, not a re-implementation of the workflow" {
  # The router is intentionally short (decision 004). The full process lives in
  # the workflow. A bloated SKILL.md signals the stub has started duplicating it.
  # The workflow itself is large (tens of KB); the router must stay far smaller.
  local skill_lines workflow_lines
  skill_lines=$(echo "$SKILL_CONTENT" | wc -l)
  workflow_lines=$(tr -d '\r' < "$WORKFLOW" | wc -l)
  [ "$skill_lines" -lt 120 ]
  [ "$skill_lines" -lt "$workflow_lines" ]
}

@test "skill does not restate the full diverge/diagnose/match/decide process inline" {
  # It may name the four-phase shape once (as a pointer), but it must not contain
  # the workflow's per-phase section headers — those belong to the workflow file.
  local phase_headers
  phase_headers=$(echo "$SKILL_CONTENT" | grep -cE '^#{2,4} .*(Diverge|Diagnose|Match|Decide)\b' || true)
  [ "$phase_headers" -eq 0 ]
}
