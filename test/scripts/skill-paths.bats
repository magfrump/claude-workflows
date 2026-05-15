#!/usr/bin/env bats
# @category fast
# Unit tests for scripts/lib/skill-paths.sh — the shared path-classification
# helpers used by hooks/log-usage.sh, scripts/health-check.sh, and
# scripts/lib/si-morning-summary.sh.

setup() {
  source "$BATS_TEST_DIRNAME/../../scripts/lib/skill-paths.sh"
}

# --- extract_skill_name ---

@test "extract_skill_name: flat layout returns name without .md" {
  [ "$(extract_skill_name "/repo/skills/fact-check.md")" = "fact-check" ]
}

@test "extract_skill_name: dir layout returns parent dir name" {
  [ "$(extract_skill_name "/repo/skills/draft-review/SKILL.md")" = "draft-review" ]
}

@test "extract_skill_name: SKILL.md directly under skills/ matches flat-layout rule" {
  # The flat-layout branch accepts any depth-0 .md, so skills/SKILL.md
  # resolves to "SKILL". This is the legacy behaviour preserved from the
  # original hook; it's documented here to catch unintended regressions.
  [ "$(extract_skill_name "/repo/skills/SKILL.md")" = "SKILL" ]
}

@test "extract_skill_name: relative path with skills/ prefix works" {
  [ "$(extract_skill_name "skills/fact-check.md")" = "fact-check" ]
  [ "$(extract_skill_name "skills/draft-review/SKILL.md")" = "draft-review" ]
}

@test "extract_skill_name: nested file (references/) is not a skill" {
  [ -z "$(extract_skill_name "/repo/skills/draft-review/references/x.md")" ]
}

@test "extract_skill_name: README.md inside a skill dir is not a skill" {
  [ -z "$(extract_skill_name "/repo/skills/draft-review/README.md")" ]
}

@test "extract_skill_name: path without skills/ segment returns empty" {
  [ -z "$(extract_skill_name "/repo/docs/skills-overview.md")" ]
  [ -z "$(extract_skill_name "/repo/src/main.ts")" ]
}

@test "extract_skill_name: deeply nested skills/foo/bar/baz.md is not a skill" {
  [ -z "$(extract_skill_name "/repo/skills/foo/bar/baz.md")" ]
}

@test "extract_skill_name: last /skills/ segment wins" {
  # claude-workflows/skills/foo.md — there are TWO skill-like segments
  [ "$(extract_skill_name "/home/u/claude-workflows/skills/fact-check.md")" = "fact-check" ]
}

# --- extract_workflow_name ---

@test "extract_workflow_name: direct file" {
  [ "$(extract_workflow_name "/repo/workflows/rpi.md")" = "rpi" ]
}

@test "extract_workflow_name: relative path" {
  [ "$(extract_workflow_name "workflows/rpi.md")" = "rpi" ]
}

@test "extract_workflow_name: nested file is not a workflow" {
  [ -z "$(extract_workflow_name "/repo/workflows/sub/x.md")" ]
}

@test "extract_workflow_name: non-md file is not a workflow" {
  [ -z "$(extract_workflow_name "/repo/workflows/notes.txt")" ]
}

@test "extract_workflow_name: path without workflows/ returns empty" {
  [ -z "$(extract_workflow_name "/repo/docs/workflows-overview.md")" ]
}

# --- extract_command_name ---

@test "extract_command_name: direct file" {
  [ "$(extract_command_name "/repo/commands/loop.md")" = "loop" ]
}

@test "extract_command_name: nested file is not a command" {
  [ -z "$(extract_command_name "/repo/commands/sub/x.md")" ]
}

# --- classify_skill_path ---

@test "classify_skill_path: skill flat" {
  [ "$(classify_skill_path "/repo/skills/fact-check.md")" = "skill:fact-check" ]
}

@test "classify_skill_path: skill dir" {
  [ "$(classify_skill_path "/repo/skills/draft-review/SKILL.md")" = "skill:draft-review" ]
}

@test "classify_skill_path: workflow" {
  [ "$(classify_skill_path "/repo/workflows/rpi.md")" = "workflow:rpi" ]
}

@test "classify_skill_path: command" {
  [ "$(classify_skill_path "/repo/commands/loop.md")" = "command:loop" ]
}

@test "classify_skill_path: skill wins over workflow when path contains both" {
  # claude-workflows/skills/foo.md should classify as skill, not workflow,
  # because /skills/ is the more specific (later) segment.
  result=$(classify_skill_path "/home/u/claude-workflows/skills/foo.md")
  [ "$result" = "skill:foo" ]
}

@test "classify_skill_path: non-classifiable path returns empty" {
  [ -z "$(classify_skill_path "/repo/src/main.ts")" ]
  [ -z "$(classify_skill_path "/repo/skills/foo/references/x.md")" ]
}
