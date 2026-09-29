#!/usr/bin/env bats
# @category fast
# Validates that every workflow has a router skill, and that each router keeps
# the router contract: it hands off to its workflow and stays a stub.
#
# Why: skills are listed with their descriptions in every Claude Code session
# and invoked through the Skill tool; workflows are reached only through
# instruction prose. The one workflow with a router (divergent-design) was
# opened 15 times in 49 days while research-plan-implement, the documented
# default, was opened zero times (docs/working/triage-2026-09-17-backlog.md
# §2.2). A router per workflow puts each one at the skill-selection layer.
# divergent-design's own, stricter contract lives in divergent-design-router.bats.
#
# Usage: bats test/skills/workflow-routers.bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  # A router body is a short pointer; the workflows it points at run 70-600
  # lines. Past this, the router has started restating its workflow.
  MAX_BODY_LINES=45
}

frontmatter() {
  awk '/^---$/ { n++; next } n==1 { print } n>=2 { exit }' "$1"
}

body() {
  tr -d '\r' < "$1" | awk '/^---$/ && n < 2 { n++; next } n >= 2'
}

workflow_names() {
  local f
  for f in "$REPO_ROOT"/workflows/*.md; do
    basename "$f" .md
  done
}

@test "every workflow has a router skill of the same name" {
  local name missing=()
  while IFS= read -r name; do
    [ -f "$REPO_ROOT/skills/$name/SKILL.md" ] || missing+=("$name")
  done < <(workflow_names)
  if [ ${#missing[@]} -gt 0 ]; then
    echo "workflows with no skills/<name>/SKILL.md router: ${missing[*]}"
    return 1
  fi
}

@test "each router's frontmatter names it after its workflow and has description and when" {
  local name skill fm bad=()
  while IFS= read -r name; do
    skill="$REPO_ROOT/skills/$name/SKILL.md"
    [ -f "$skill" ] || continue
    fm=$(frontmatter "$skill")
    echo "$fm" | grep -qE "^name:[[:space:]]*${name}[[:space:]]*\$" || bad+=("$name: name")
    echo "$fm" | grep -qE '^description:' || bad+=("$name: description")
    echo "$fm" | grep -qE '^when:' || bad+=("$name: when")
  done < <(workflow_names)
  if [ ${#bad[@]} -gt 0 ]; then
    printf 'bad frontmatter: %s\n' "${bad[@]}"
    return 1
  fi
}

@test "each router's body hands off to its own workflow file" {
  local name skill bad=()
  while IFS= read -r name; do
    skill="$REPO_ROOT/skills/$name/SKILL.md"
    [ -f "$skill" ] || continue
    # Asserted on the body, not the whole file: the description also names the
    # workflow, so a whole-file match survives deleting the handoff.
    body "$skill" | grep -qF "Read and follow **\`workflows/$name.md\`**" || bad+=("$name")
  done < <(workflow_names)
  if [ ${#bad[@]} -gt 0 ]; then
    echo "routers whose body lacks 'Read and follow **\`workflows/<name>.md\`**': ${bad[*]}"
    return 1
  fi
}

@test "each router identifies itself as a router in its title" {
  local name skill bad=()
  while IFS= read -r name; do
    skill="$REPO_ROOT/skills/$name/SKILL.md"
    [ -f "$skill" ] || continue
    body "$skill" | grep -qiE '^# .*\(router\)' || bad+=("$name")
  done < <(workflow_names)
  if [ ${#bad[@]} -gt 0 ]; then
    echo "routers without '(router)' in the H1: ${bad[*]}"
    return 1
  fi
}

@test "each router stays a stub (body at most MAX_BODY_LINES lines)" {
  local name skill n bad=()
  while IFS= read -r name; do
    skill="$REPO_ROOT/skills/$name/SKILL.md"
    [ -f "$skill" ] || continue
    n=$(body "$skill" | wc -l)
    [ "$n" -le "$MAX_BODY_LINES" ] || bad+=("$name ($n lines)")
  done < <(workflow_names)
  if [ ${#bad[@]} -gt 0 ]; then
    echo "routers over $MAX_BODY_LINES body lines (restating the workflow?): ${bad[*]}"
    return 1
  fi
}
