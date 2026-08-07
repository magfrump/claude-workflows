#!/usr/bin/env bats
# @category fast
# Contract tests for the code-review skill's conditional diff-delivery policy
# (decision 032 #3, shipped 2f5ad0b): a normal-sized diff is inlined once as the
# shared cacheable prefix of every agent prompt; only large diffs fall back to
# per-agent `git diff` self-read.
#
# The load-bearing case is the NEGATIVE assertion: any instruction in SKILL.md
# that tells an agent to run its own `git diff` (or says "pass scope, not
# diffs") must carry a conditionality marker nearby — otherwise the dispatch
# steps silently revert lever #3 to unconditional self-read, which is exactly
# the defect the 2026-08-07 review found at lines 340/634/1406.
#
# Usage: bats test/skills/code-review-context-delivery.bats

load ../lib/hermetic-env

SKILL="skills/code-review/SKILL.md"

# Print a ±2-line window around every line of $SKILL matching regex $1.
# Windows are separated so a marker in one window can't satisfy another.
windows_for() {
  local pattern="$1"
  awk -v pat="$pattern" '
    { lines[NR] = $0 }
    $0 ~ pat { hits[++n] = NR }
    END {
      for (i = 1; i <= n; i++) {
        for (j = hits[i] - 2; j <= hits[i] + 2; j++)
          if (j >= 1 && j <= NR) print lines[j]
        print "\x01"   # window separator
      }
    }
  ' "$BATS_TEST_DIRNAME/../../$SKILL"
}

# Every window must contain a conditionality marker.
assert_all_windows_conditional() {
  local pattern="$1"
  local out
  out=$(windows_for "$pattern")
  [ -n "$out" ]  # the pattern must still exist somewhere — vacuous pass is a rewrite signal
  local window="" line ok=1
  while IFS= read -r line; do
    if [ "$line" = $'\x01' ]; then
      # collapse the window to one line so markers split by prose wrapping still match
      if ! printf '%s\n' "$window" | tr -s '[:space:]' ' ' | grep -Eqi 'conditional|large[ -]diff|fall ?back'; then
        echo "window without conditionality marker for /$pattern/:" >&2
        printf '%s\n' "$window" >&2
        ok=0
      fi
      window=""
    else
      window="$window$line"$'\n'
    fi
  done <<< "$out"
  [ "$ok" -eq 1 ]
}

@test "Step 1 declares diff delivery as conditional" {
  grep -q "Diff delivery to agents is conditional" "$BATS_TEST_DIRNAME/../../$SKILL"
}

@test "inline shared-context section inlines the unified diff as shared-block part 2" {
  grep -q "The unified diff itself" "$BATS_TEST_DIRNAME/../../$SKILL"
}

@test "every 'runs its own git diff' instruction carries a conditionality marker nearby" {
  assert_all_windows_conditional 'runs? (its|their) own `git diff`'
}

@test "every 'pass scope, not diffs' instruction carries a conditionality marker nearby" {
  assert_all_windows_conditional '[Pp]ass scope, not diffs'
}

@test "Stage-1 replicate dispatch step references the conditional delivery rule" {
  awk '/^For each of the three replicate agents:/,/^3b\./' \
    "$BATS_TEST_DIRNAME/../../$SKILL" | grep -qi "conditional diff-delivery"
}

@test "Stage-2 critic dispatch step references the conditional delivery rule" {
  awk '/^For each critic agent, you MUST:/,/^4\./' \
    "$BATS_TEST_DIRNAME/../../$SKILL" | grep -qi "conditional diff-delivery"
}
