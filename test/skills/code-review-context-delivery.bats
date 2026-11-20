#!/usr/bin/env bats
# @category fast
# Contract tests for the code-review skill's conditional diff-delivery policy
# (decision 032 #3, shipped 2f5ad0b): a normal-sized diff is inlined once and the
# same shared block goes into every agent prompt; only large diffs fall back to
# per-agent `git diff` self-read. The 2026-11-19 amendment to decision 032 records
# that this buys no cross-agent prompt-cache saving on the Agent-tool path, so the
# last tests guard against the cache claims and the skill-pasting rule returning.
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
      if ! printf '%s\n' "$window" | tr -s '[:space:]' ' ' | grep -Eqi 'conditional|large[ -]diff|fall ?back|over budget|degrade'; then
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

@test "inline shared-context section inlines the unified diff as a shared-block part" {
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

# --- the numeric budget and degrade ladder (decision log row 35) ---

@test "size guard names the numeric shared-block budget" {
  grep -qE 'Budget: 25,000 tokens' "$BATS_TEST_DIRNAME/../../$SKILL"
}

@test "degrade ladder inlines the diff alone before falling back to full self-read" {
  # The awk range ends at the production-loop-only line; assert it exists so a reword
  # cannot let the range run silently to end of file.
  grep -q '^This section is \*\*production-loop-only' "$BATS_TEST_DIRNAME/../../$SKILL"
  awk '/\*\*Size guard/,/^This section is \*\*production-loop-only/' "$BATS_TEST_DIRNAME/../../$SKILL" \
    | grep -qi 'diff only'
}

@test "per-file churn rule is explicitly excluded from the delivery gate" {
  grep -q 'plays no part in this delivery gate' "$BATS_TEST_DIRNAME/../../$SKILL"
}

@test "shared block still lists the diff (part 5) and the fact-check summary (part 6)" {
  grep -qE '^5\. \*\*The unified diff itself\*\*' "$BATS_TEST_DIRNAME/../../$SKILL"
  grep -qE '^6\. The Stage-1 merged fact-check summary' "$BATS_TEST_DIRNAME/../../$SKILL"
}

# --- decision 032 amendment 2026-11-19: no cross-agent cache saving on this path ---

@test "skill states the measured no-cache-saving result and cites both A8 docs" {
  local f="$BATS_TEST_DIRNAME/../../$SKILL"
  grep -q 'It buys no prompt-cache saving across agents' "$f"
  grep -q 'runs/review-arms/a8-2026-11-19/results.md' "$f"
  grep -q 'runs/review-arms/a8-2026-11-19/cache-probe.md' "$f"
}

@test "the refuted cache-saving claims are gone from the skill" {
  local f="$BATS_TEST_DIRNAME/../../$SKILL"
  run grep -nE -i 'cacheable|cache-warm|prompt cache serve|because it is free|make the cache actually hit|only the tail varies|per-agent variation lives in the tail' "$f"
  [ "$status" -eq 1 ]
}

@test "agents get their skill file by path, not a pasted copy" {
  local f="$BATS_TEST_DIRNAME/../../$SKILL"
  run grep -nE -i 'cannot read (your|the orchestrator.s) (files|filesystem)|Paste skill file contents|Paste those contents directly' "$f"
  [ "$status" -eq 1 ]
  awk '/^For each of the three replicate agents:/,/^3b\./' "$f" | grep -q 'whole file'
  awk '/^For each critic agent, you MUST:/,/^4\./' "$f" | grep -q 'whole file'
}
