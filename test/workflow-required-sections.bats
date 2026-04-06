#!/usr/bin/env bats
# @category fast
# Validates that convention-following workflows contain required sections:
# - '## When to use' — explains when to reach for this workflow
# - Numbered process step headers (### N. ...) under '## Process'
#
# Usage: bats test/workflow-required-sections.bats

setup() {
  WORKFLOW_DIR="$HOME/.claude/workflows"

  # These 6 workflows follow the standard convention of having
  # '## When to use' and numbered '### N.' process steps.
  #
  # Excluded workflows and why:
  #   review-fix-loop.md   — a sub-procedure embedded in pr-prep, not a standalone workflow
  #   branch-strategy.md   — a reference/policy doc, not a step-by-step process
  #   user-testing-workflow.md — uses Phase-based structure instead of '## When to use' + '## Process'
  CONVENTION_WORKFLOWS=(
    research-plan-implement.md
    divergent-design.md
    spike.md
    pr-prep.md
    codebase-onboarding.md
    task-decomposition.md
  )
}

@test "convention workflows each contain '## When to use'" {
  local failures=""

  for wf in "${CONVENTION_WORKFLOWS[@]}"; do
    local path="$WORKFLOW_DIR/$wf"
    if [ ! -f "$path" ]; then
      failures+="  MISSING FILE: $wf\n"
      continue
    fi

    if ! grep -q '^## When to use' "$path"; then
      failures+="  $wf: missing '## When to use'\n"
    fi
  done

  if [ -n "$failures" ]; then
    echo -e "Workflows missing '## When to use':\n$failures"
    return 1
  fi
}

@test "convention workflows each contain numbered process step headers" {
  local failures=""

  for wf in "${CONVENTION_WORKFLOWS[@]}"; do
    local path="$WORKFLOW_DIR/$wf"
    if [ ! -f "$path" ]; then
      failures+="  MISSING FILE: $wf\n"
      continue
    fi

    # Look for at least one header like '### 1.' or '#### 1.' etc.
    # Some workflows (e.g., pr-prep) nest steps under phase headings using ####.
    if ! grep -q '^###\+ [0-9]\+\.' "$path"; then
      failures+="  $wf: missing numbered process step headers (### N. or #### N. ...)\n"
    fi
  done

  if [ -n "$failures" ]; then
    echo -e "Workflows missing process step headers:\n$failures"
    return 1
  fi
}

@test "convention workflows have at least 3 process steps" {
  local failures=""

  for wf in "${CONVENTION_WORKFLOWS[@]}"; do
    local path="$WORKFLOW_DIR/$wf"
    [ ! -f "$path" ] && continue

    local count
    count=$(grep -c '^###\+ [0-9]\+\.' "$path" || true)

    if [ "$count" -lt 3 ]; then
      failures+="  $wf: only $count process step(s), expected >= 3\n"
    fi
  done

  if [ -n "$failures" ]; then
    echo -e "Workflows with too few process steps:\n$failures"
    return 1
  fi
}
