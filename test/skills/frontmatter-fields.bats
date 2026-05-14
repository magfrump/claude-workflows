#!/usr/bin/env bats
# Validates that every skills/*.md file contains the required YAML frontmatter
# fields: 'name', 'description', and at least one of 'trigger' or 'when'.
#
# Independent from health-check.sh, which checks frontmatter existence but
# not field completeness.
#
# Usage: bats test/skills/frontmatter-fields.bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  SKILLS_DIR="$REPO_ROOT/skills"
}

# Extract YAML frontmatter (content between first pair of --- delimiters)
extract_frontmatter() {
  awk '/^---$/ { n++; next } n==1 { print } n>=2 { exit }' "$1"
}

@test "all skills have required frontmatter fields" {
  local missing=""
  local checked=0

  # Discover skills in both layouts: flat (skills/<name>.md) and
  # directory (skills/<name>/SKILL.md). Claude Code's registry only
  # auto-registers the directory form, but we validate frontmatter on
  # whichever shape is present.
  local -a skill_files=()
  local f
  for f in "$SKILLS_DIR"/*.md; do
    [ -f "$f" ] && skill_files+=("$f")
  done
  for f in "$SKILLS_DIR"/*/SKILL.md; do
    [ -f "$f" ] && skill_files+=("$f")
  done

  for skill in "${skill_files[@]}"; do
    local basename
    if [ "$(basename "$skill")" = "SKILL.md" ]; then
      basename="$(basename "$(dirname "$skill")")"
    else
      basename="$(basename "$skill" .md)"
    fi
    checked=$((checked + 1))

    local frontmatter
    frontmatter=$(extract_frontmatter "$skill")

    if [ -z "$frontmatter" ]; then
      missing+="  $basename: no YAML frontmatter found"$'\n'
      continue
    fi

    if ! echo "$frontmatter" | grep -q '^name:'; then
      missing+="  $basename: missing 'name' field"$'\n'
    fi

    if ! echo "$frontmatter" | grep -q '^description:'; then
      missing+="  $basename: missing 'description' field"$'\n'
    fi

    if ! echo "$frontmatter" | grep -q '^trigger:' &&
       ! echo "$frontmatter" | grep -q '^when:'; then
      missing+="  $basename: missing 'trigger' or 'when' field"$'\n'
    fi
  done

  # Guard: ensure we actually found skills to check
  [ "$checked" -gt 0 ] || {
    echo "No skill files found — check test setup"
    return 1
  }

  if [ -n "$missing" ]; then
    echo "Frontmatter field issues ($checked skills checked):"
    echo "$missing"
    return 1
  fi
}
