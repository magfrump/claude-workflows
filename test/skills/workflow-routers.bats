#!/usr/bin/env bats
# @category fast
# Validates that every workflow has a router skill unless its own frontmatter
# opts out, and that each router keeps the router contract: it hands off to
# the installed copy of its workflow and stays a stub.
#
# Why: skills are listed with their descriptions in every Claude Code session
# and invoked through the Skill tool; workflows are reached only through
# instruction prose. divergent-design got a router for exactly that reason
# (its SKILL.md: "so divergent design competes at the skill-selection layer").
# A router per workflow puts each one there. (Hook-based usage counts are not
# cited: they under-count silently, Q-017.)
# divergent-design's own, stricter contract lives in divergent-design-router.bats.
#
# Adding a workflow: either add skills/<name>/SKILL.md, or, for a workflow that
# only runs inside another one, put `router: "none — <reason>"` in its
# frontmatter.
#
# Usage: bats test/skills/workflow-routers.bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  # A router body is a short pointer; the workflows it points at run about
  # 70-610 lines. Past this, the router has started restating its workflow.
  MAX_BODY_LINES=45
}

frontmatter() {
  awk '/^---$/ { n++; next } n==1 { print } n>=2 { exit }' "$1"
}

body() {
  tr -d '\r' < "$1" | awk '/^---$/ && n < 2 { n++; next } n >= 2'
}

# A workflow opts out of having a router with `router: "none — <reason>"`.
opted_out() {
  frontmatter "$REPO_ROOT/workflows/$1.md" | grep -qE '^router:[[:space:]]*"?none'
}

# Names of workflows that should have a router.
routed_names() {
  local f name
  for f in "$REPO_ROOT"/workflows/*.md; do
    name=$(basename "$f" .md)
    opted_out "$name" || echo "$name"
  done
}

@test "every workflow without router: none has a router skill of the same name" {
  local name missing=()
  while IFS= read -r name; do
    [ -f "$REPO_ROOT/skills/$name/SKILL.md" ] || missing+=("$name")
  done < <(routed_names)
  if [ ${#missing[@]} -gt 0 ]; then
    echo "workflows with no skills/<name>/SKILL.md router (add one, or opt out with router: \"none — <reason>\" in the workflow's frontmatter): ${missing[*]}"
    return 1
  fi
}

@test "a workflow that opts out gives a reason and has no router" {
  local f name bad=()
  for f in "$REPO_ROOT"/workflows/*.md; do
    name=$(basename "$f" .md)
    opted_out "$name" || continue
    frontmatter "$f" | grep -qE '^router:[[:space:]]*"?none[[:space:]]+—[[:space:]]+[^[:space:]]' \
      || bad+=("$name: router: none without a reason")
    [ ! -e "$REPO_ROOT/skills/$name" ] || bad+=("$name: opted out but skills/$name exists")
  done
  if [ ${#bad[@]} -gt 0 ]; then
    printf '%s\n' "${bad[@]}"
    return 1
  fi
}

@test "each router's frontmatter names it after its workflow and has a description" {
  local name skill fm bad=()
  while IFS= read -r name; do
    skill="$REPO_ROOT/skills/$name/SKILL.md"
    [ -f "$skill" ] || continue
    fm=$(frontmatter "$skill")
    echo "$fm" | grep -qE "^name:[[:space:]]*${name}[[:space:]]*\$" || bad+=("$name: name")
    echo "$fm" | grep -qE '^description:' || bad+=("$name: description")
  done < <(routed_names)
  if [ ${#bad[@]} -gt 0 ]; then
    printf 'bad frontmatter: %s\n' "${bad[@]}"
    return 1
  fi
}

@test "each router's body hands off to the installed copy of its own workflow" {
  local name skill b bad=()
  while IFS= read -r name; do
    skill="$REPO_ROOT/skills/$name/SKILL.md"
    [ -f "$skill" ] || continue
    # Asserted on the body, where the agent acts on it: the frontmatter only
    # decides whether the skill fires (same rule as divergent-design-router.bats).
    b=$(body "$skill")
    grep -qF "Read and follow **\`workflows/$name.md\`**" <<< "$b" || bad+=("$name: no 'Read and follow **\`workflows/$name.md\`**'")
    # The bare relative path resolves against the current project; outside
    # claude-workflows it could pick up an unrelated file of the same name.
    # shellcheck disable=SC2088  # a literal "~/" in the router text, not a path
    grep -qF "~/.claude/workflows/$name.md" <<< "$b" || bad+=("$name: no installed path ~/.claude/workflows/$name.md")
    grep -qF "Never follow a same-named file" <<< "$b" || bad+=("$name: no 'Never follow a same-named file' line")
  done < <(routed_names)
  if [ ${#bad[@]} -gt 0 ]; then
    printf '%s\n' "${bad[@]}"
    return 1
  fi
}

@test "each router identifies itself as a router in its title" {
  local name skill bad=()
  while IFS= read -r name; do
    skill="$REPO_ROOT/skills/$name/SKILL.md"
    [ -f "$skill" ] || continue
    body "$skill" | grep -qiE '^# .*\(router\)' || bad+=("$name")
  done < <(routed_names)
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
  done < <(routed_names)
  if [ ${#bad[@]} -gt 0 ]; then
    echo "routers over $MAX_BODY_LINES body lines (restating the workflow?): ${bad[*]}"
    return 1
  fi
}
