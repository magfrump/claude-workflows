#!/usr/bin/env bats
# @category fast
# Offline half of the cowen-critique dimension checks: every keyword in
# COWEN_DIMENSION_KEYWORDS (test/skills/critic-dimensions.bash) must be one the
# skill actually prescribes. skills/cowen-critique/SKILL.md's "How to Structure
# the Critique" template gives each output section a "Use the word/phrase X"
# rule; dimensions.bats then checks generated reports for those same words.
# Dropping a section (or its keyword rule) from the skill turns this red with
# no model run, where the report-based suite could only notice on regeneration.

load ../critic-dimensions

SKILL_MD="$BATS_TEST_DIRNAME/../../../skills/cowen-critique/SKILL.md"

setup() {
  [ -f "$SKILL_MD" ] || { echo "missing $SKILL_MD" >&2; return 1; }
  # The output template: from its ## heading to the next ## heading. Only its
  # ### subsections are rendered as report sections.
  TEMPLATE=$(tr -d '\r' < "$SKILL_MD" | awk '
    /^## How to Structure the Critique/ { on = 1; next }
    on && /^## / { exit }
    on { print }
  ')
}

# Print the template subsection (### heading through its body) that carries a
# "Use the word/words/phrase ... \"<kw>\"" rule for keyword $1.
section_prescribing() {
  local kw="$1"
  echo "$TEMPLATE" | awk -v kw="$kw" '
    /^### / { if (hit) exit; sec = ""; }
    { sec = sec $0 "\n" }
    tolower($0) ~ /use the (word|words|phrase)/ && index(tolower($0), "\"" tolower(kw) "\"") { hit = 1 }
    END { if (hit) printf "%s", sec }
  '
}

@test "SKILL.md has an output template with ### section headings" {
  [ -n "$TEMPLATE" ]
  echo "$TEMPLATE" | grep -qE '^### '
}

@test "every cowen dimension keyword is prescribed by a SKILL.md template section" {
  local kw missing=()
  for kw in "${COWEN_DIMENSION_KEYWORDS[@]}"; do
    [ -n "$(section_prescribing "$kw")" ] || missing+=("$kw")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    echo "No template section tells the critic to use: ${missing[*]}" >&2
    return 1
  fi
}

@test "each prescribing section is a real report section, not Overall Assessment" {
  local kw sec
  for kw in "${COWEN_DIMENSION_KEYWORDS[@]}"; do
    sec=$(section_prescribing "$kw")
    echo "$sec" | head -1 | grep -qE '^### [A-Z]' || { echo "$kw: no ### heading" >&2; return 1; }
    ! echo "$sec" | head -1 | grep -q 'Overall Assessment' || { echo "$kw: only in Overall Assessment" >&2; return 1; }
  done
}
