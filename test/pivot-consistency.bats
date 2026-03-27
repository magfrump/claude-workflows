#!/usr/bin/env bats
# Validates bidirectional consistency of '## When to pivot' sections across
# workflows. If workflow A mentions pivoting to/from B and B has a pivot
# section, then B should mention A. Asymmetries are flagged as warnings
# (printed output) rather than hard failures, since some pivots are
# inherently one-directional (e.g., codebase-onboarding → RPI).
#
# Only checks the 5 workflows that currently have pivot sections.
#
# Usage: bats test/pivot-consistency.bats

setup() {
  WORKFLOW_DIR="$HOME/.claude/workflows"

  # The 5 workflows that have '## When to pivot' sections.
  PIVOT_WORKFLOWS=(
    bug-diagnosis.md
    codebase-onboarding.md
    divergent-design.md
    research-plan-implement.md
    spike.md
  )

  # Mapping from workflow filename to search patterns that indicate a
  # reference. Each workflow may be referenced by its filename, its short
  # name, or common abbreviations used in prose.
  declare -gA WORKFLOW_PATTERNS
  WORKFLOW_PATTERNS=(
    [bug-diagnosis.md]="bug-diagnosis|Bug Diagnosis|bug.diagnosis"
    [codebase-onboarding.md]="codebase-onboarding|Codebase Onboarding|[Oo]nboarding"
    [divergent-design.md]="divergent-design|Divergent Design|DD"
    [research-plan-implement.md]="research-plan-implement|Research.*Plan.*Implement|RPI"
    [spike.md]="spike\.md|[Ss]pike"
  )
}

# Helper: extract the '## When to pivot' section from a workflow file.
# Prints all lines from '## When to pivot' up to (but not including) the
# next '##' heading, or end of file.
extract_pivot_section() {
  local file="$1"
  sed -n '/^## When to pivot/,/^## /{ /^## When to pivot/d; /^## /d; p; }' "$file"
}

# Helper: check whether a pivot section mentions a given workflow.
# Returns 0 if the section contains a match for the workflow's patterns.
section_mentions() {
  local section="$1"
  local workflow="$2"
  local pattern="${WORKFLOW_PATTERNS[$workflow]}"
  echo "$section" | grep -qE "$pattern"
}

@test "all pivot workflows exist and have '## When to pivot' sections" {
  local failures=""

  for wf in "${PIVOT_WORKFLOWS[@]}"; do
    local path="$WORKFLOW_DIR/$wf"
    if [ ! -f "$path" ]; then
      failures+="  MISSING FILE: $wf\n"
      continue
    fi

    if ! grep -q '^## When to pivot' "$path"; then
      failures+="  $wf: missing '## When to pivot' section\n"
    fi
  done

  if [ -n "$failures" ]; then
    echo -e "Pivot section problems:\n$failures"
    return 1
  fi
}

@test "pivot references are bidirectionally consistent (asymmetries are warnings)" {
  local asymmetries=""
  local checked=0

  # Build an associative array of pivot sections for each workflow
  declare -A SECTIONS
  for wf in "${PIVOT_WORKFLOWS[@]}"; do
    local path="$WORKFLOW_DIR/$wf"
    [ -f "$path" ] || continue
    SECTIONS[$wf]="$(extract_pivot_section "$path")"
  done

  # For each pair (A, B) where A != B, check: if A mentions B, does B mention A?
  for wf_a in "${PIVOT_WORKFLOWS[@]}"; do
    [ -z "${SECTIONS[$wf_a]+x}" ] && continue
    local section_a="${SECTIONS[$wf_a]}"

    for wf_b in "${PIVOT_WORKFLOWS[@]}"; do
      [ "$wf_a" = "$wf_b" ] && continue
      [ -z "${SECTIONS[$wf_b]+x}" ] && continue
      local section_b="${SECTIONS[$wf_b]}"

      if section_mentions "$section_a" "$wf_b"; then
        checked=$((checked + 1))
        if ! section_mentions "$section_b" "$wf_a"; then
          asymmetries+="  $wf_a mentions $wf_b, but $wf_b does not mention $wf_a\n"
        fi
      fi
    done
  done

  # Guard: ensure we actually found references to check
  [ "$checked" -gt 0 ] || {
    echo "No pivot cross-references found — check test setup"
    return 1
  }

  # Report asymmetries as warnings but do not fail
  if [ -n "$asymmetries" ]; then
    echo -e "WARNING: Asymmetric pivot references found ($checked references checked):\n$asymmetries"
    echo "(These are warnings, not failures — some pivots are inherently one-directional.)"
  else
    echo "All $checked pivot cross-references are bidirectionally consistent."
  fi
}
