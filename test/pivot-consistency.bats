#!/usr/bin/env bats
# @category fast
# Validates bidirectional consistency of '## When to pivot' sections across
# workflows. If workflow A mentions pivoting to/from B and B has a pivot
# section, then B should mention A. Pivots that are inherently
# one-directional are listed in KNOWN_ONE_WAY; any other asymmetry fails.
# (Before 2026-09-26 every asymmetry was only printed, so deleting a pivot
# reference could never turn this suite red.)
#
# Covers every workflow with a '## When to pivot' section; a guard test fails
# if one is added without a WORKFLOW_PATTERNS entry, so the list cannot go
# silently stale (it once omitted parallel-worktrees and user-testing).
#
# Usage: bats test/pivot-consistency.bats

setup() {
  # Repo-relative, not the deployed ~/.claude install — see the note in
  # workflow-required-sections.bats. Keeps the suite hermetic.
  WORKFLOW_DIR="${WORKFLOW_DIR:-$BATS_TEST_DIRNAME/../workflows}"

  # Every workflow that has a '## When to pivot' section, discovered.
  PIVOT_WORKFLOWS=()
  local f
  for f in "$WORKFLOW_DIR"/*.md; do
    grep -q '^## When to pivot' "$f" && PIVOT_WORKFLOWS+=("$(basename "$f")")
  done

  # Mapping from workflow filename to search patterns that indicate a
  # reference. Each workflow may be referenced by its filename, its short
  # name, or common abbreviations used in prose.
  declare -gA WORKFLOW_PATTERNS
  WORKFLOW_PATTERNS=(
    [codebase-onboarding.md]="codebase-onboarding|Codebase Onboarding|[Oo]nboarding"
    [divergent-design.md]="divergent-design|Divergent Design|\\bDD\\b"
    [research-plan-implement.md]="research-plan-implement|Research.*Plan.*Implement|RPI"
    [spike.md]="spike\.md|[Ss]pike"
    [parallel-worktrees.md]="parallel-worktrees|[Bb]atch fan-out"
    [user-testing-workflow.md]="user-testing|[Uu]sability test"
  )

  # "A>B": A's pivot section names B, and B is not expected to name A back.
  # Onboarding feeds DD's diagnosis, but DD never hands off to onboarding.
  KNOWN_ONE_WAY=(
    "codebase-onboarding.md>divergent-design.md"
    # Batch fan-out is a pre-pass: items route out to RPI/DD and never back.
    "parallel-worktrees.md>divergent-design.md"
    "parallel-worktrees.md>research-plan-implement.md"
    # Usability findings can open a design fork; DD does not hand off to testing.
    "user-testing-workflow.md>divergent-design.md"
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

@test "every workflow with a pivot section has a reference pattern" {
  local wf missing=""
  [ "${#PIVOT_WORKFLOWS[@]}" -ge 4 ] || { echo "discovery found too few pivot workflows"; return 1; }
  for wf in "${PIVOT_WORKFLOWS[@]}"; do
    [ -n "${WORKFLOW_PATTERNS[$wf]+x}" ] || missing+=" $wf"
  done
  [ -z "$missing" ] || { echo "Add WORKFLOW_PATTERNS entries for:$missing"; return 1; }
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

@test "pivot references are bidirectionally consistent (except known one-way pivots)" {
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
        if ! section_mentions "$section_b" "$wf_a" \
            && [[ " ${KNOWN_ONE_WAY[*]} " != *" $wf_a>$wf_b "* ]]; then
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

  if [ -n "$asymmetries" ]; then
    echo -e "Asymmetric pivot references ($checked references checked):\n$asymmetries"
    echo "Add the missing back-reference, or list the pair in KNOWN_ONE_WAY if the pivot is one-directional."
    return 1
  fi
}
