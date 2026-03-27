#!/usr/bin/env bats
# Validates that CLAUDE.md, AGENTS.md, and GEMINI.md reference the same set
# of workflow and skill filenames.
#
# Each entry point uses a different format for referencing files:
#   CLAUDE.md:  - **research-plan-implement.md** — ...
#   AGENTS.md:  - **@./workflows/research-plan-implement.md** — ...
#   GEMINI.md:  - **research-plan-implement.md** — ...
#
# This test extracts bare filenames (basename only) so format differences
# are tolerated. It catches drift when a workflow or skill is added to one
# entry point but not others.
#
# Usage: bats test/entry-point-consistency.bats

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/.."
  ENTRY_POINTS=(CLAUDE.md AGENTS.md GEMINI.md)
}

# Extract bare .md filenames from bold references (**...**) in an entry point.
# Strips path prefixes (e.g., @./workflows/) to produce bare basenames.
# Returns a sorted unique list, one filename per line.
extract_md_filenames() {
  local file="$1"
  # Match **...anything....md** — bold-wrapped references ending in .md
  grep -o '\*\*[^*]*\.md\*\*' "$file" \
    | sed 's/^\*\*//; s/\*\*$//' \
    | while IFS= read -r ref; do basename "$ref"; done \
    | sort -u
}

@test "all entry points exist" {
  for ep in "${ENTRY_POINTS[@]}"; do
    [ -f "$REPO_ROOT/$ep" ] || {
      echo "Missing entry point: $ep"
      return 1
    }
  done
}

@test "each entry point references at least one .md filename" {
  for ep in "${ENTRY_POINTS[@]}"; do
    local count
    count=$(extract_md_filenames "$REPO_ROOT/$ep" | wc -l)
    [ "$count" -gt 0 ] || {
      echo "$ep: no .md filenames found in bold references"
      return 1
    }
  done
}

@test "all entry points reference the same set of workflow/skill filenames" {
  local reference_ep="${ENTRY_POINTS[0]}"
  local reference_set
  reference_set=$(extract_md_filenames "$REPO_ROOT/$reference_ep")

  local all_match=true
  local report=""

  for ep in "${ENTRY_POINTS[@]:1}"; do
    local current_set
    current_set=$(extract_md_filenames "$REPO_ROOT/$ep")

    # Files in reference but not in current
    local missing
    missing=$(comm -23 <(echo "$reference_set") <(echo "$current_set"))

    # Files in current but not in reference
    local extra
    extra=$(comm -13 <(echo "$reference_set") <(echo "$current_set"))

    if [ -n "$missing" ] || [ -n "$extra" ]; then
      all_match=false
      report+="Drift between $reference_ep and $ep:"$'\n'
      if [ -n "$missing" ]; then
        report+="  In $reference_ep but not $ep:"$'\n'
        while IFS= read -r f; do
          report+="    - $f"$'\n'
        done <<< "$missing"
      fi
      if [ -n "$extra" ]; then
        report+="  In $ep but not $reference_ep:"$'\n'
        while IFS= read -r f; do
          report+="    - $f"$'\n'
        done <<< "$extra"
      fi
    fi
  done

  if [ "$all_match" = false ]; then
    echo "$report"
    return 1
  fi
}
