#!/usr/bin/env bats
# @category fast
# Guards the lever #3 follow-on correction (brief 2026-11-19-lever3-followons):
# the review skills, the divergent-design workflow, the orchestrated-review
# pattern and the sub-agent briefing guide no longer say that sub-agents cannot
# read the orchestrator's files (so skill text must be pasted), nor that a shared
# prompt block is a cacheable prefix. The 2026-11-19 A8 measurement found every
# agent read its skill file by path and no cross-agent cache saving through the
# Agent tool (runs/review-arms/a8-2026-11-19/cache-probe.md). The code-review
# skill's own guard is test/skills/code-review-context-delivery.bats.
#
# Usage: bats test/skills/subagent-context-delivery.bats

load ../lib/hermetic-env

ROOT="$BATS_TEST_DIRNAME/../.."
FILES=(
  skills/draft-review/SKILL.md
  skills/matrix-analysis/SKILL.md
  workflows/divergent-design.md
  patterns/orchestrated-review.md
  guides/sub-agent-briefing.md
)

@test "every guarded file exists" {
  local p
  for p in "${FILES[@]}"; do
    [ -f "$ROOT/$p" ] || { echo "missing: $p"; return 1; }
  done
}

@test "no guarded file says sub-agents cannot read the orchestrator's files" {
  local p
  for p in "${FILES[@]}"; do
    run grep -nE -i 'sub-?agents? cannot read|cannot read (your|the orchestrator.s) (files|filesystem)|Paste skill file contents|Paste those contents directly' "$ROOT/$p"
    [ "$status" -eq 1 ] || { echo "$p: $output"; return 1; }
  done
}

@test "no guarded file calls a shared prompt block a cacheable prefix" {
  local p
  for p in "${FILES[@]}"; do
    run grep -nE -i 'cacheable' "$ROOT/$p"
    [ "$status" -eq 1 ] || { echo "$p: $output"; return 1; }
  done
}

@test "draft-review gives fact-check and critic agents their skill file by path" {
  local f="$ROOT/skills/draft-review/SKILL.md" start
  # Each range ends at its own step 4, before the next heading; assert that line exists so a
  # reword cannot let the range run on and match text from another section.
  for start in 'For each fact-check agent, you MUST:' 'For each critic agent instance, you MUST:'; do
    awk -v s="$start" 'index($0, s) == 1 { on = 1; next } on && /^#/ { exit } on && /^4\. Include the full draft text/ { found = 1; exit } END { exit !found }' "$f" \
      || { echo "no step 4 after: $start"; return 1; }
    awk -v s="$start" 'index($0, s) == 1 { on = 1 } on && (/^#/ || /^4\./) { exit } on' "$f" | grep -q 'read that whole file with the Read tool' \
      || { echo "no by-path read under: $start"; return 1; }
    awk -v s="$start" 'index($0, s) == 1 { on = 1 } on && (/^#/ || /^4\./) { exit } on' "$f" | grep -q 'only when the agent cannot reach the path' \
      || { echo "no paste-only-when rule under: $start"; return 1; }
  done
}
