#!/usr/bin/env bash
# Interactive hypothesis-resolution survey runner.
# Presents the questions from docs/working/hypothesis-resolution-questionnaire.md
# as terminal prompts, collects answers, and writes results to a timestamped
# companion file under docs/working/survey-results/.
#
# Usage:
#   scripts/run-hypothesis-survey.sh
#
# No arguments. Takes ~2 minutes. Produces a Markdown results file that can be
# scored against the questionnaire's Scoring Guide to resolve H-01 through H-07.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESULTS_DIR="$REPO_ROOT/docs/working/survey-results"
TIMESTAMP="$(date +%Y-%m-%dT%H%M%S)"
RESULTS_FILE="$RESULTS_DIR/survey-$TIMESTAMP.md"

mkdir -p "$RESULTS_DIR"

# --- Color helpers ---
bold()   { printf '\033[1m%s\033[0m' "$*"; }
dim()    { printf '\033[2m%s\033[0m' "$*"; }
green()  { printf '\033[1;32m%s\033[0m' "$*"; }
cyan()   { printf '\033[1;36m%s\033[0m' "$*"; }

# --- Input helpers ---
# Read a free-text answer (multi-line: blank line or Ctrl-D to finish)
ask_free() {
  local prompt="$1"
  local varname="$2"
  echo ""
  bold "$prompt"
  echo ""
  dim "  (Type your answer. Press Enter twice to finish.)"
  echo ""

  local answer=""
  local prev_blank=false
  while IFS= read -r line; do
    if [[ -z "$line" ]]; then
      if $prev_blank; then
        break
      fi
      prev_blank=true
      answer+=$'\n'
    else
      prev_blank=false
      answer+="$line"$'\n'
    fi
  done

  # Trim trailing whitespace
  answer="$(echo "$answer" | sed -e 's/[[:space:]]*$//')"
  eval "$varname=\"\$answer\""
}

# Read a single-choice answer
ask_choice() {
  local prompt="$1"
  local varname="$2"
  shift 2
  local options=("$@")

  echo ""
  bold "$prompt"
  echo ""
  local i=1
  for opt in "${options[@]}"; do
    echo "  $i) $opt"
    ((i++))
  done
  echo ""

  local choice
  while true; do
    printf "  Enter number (1-%d): " "${#options[@]}"
    read -r choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
      eval "$varname=\"\${options[$((choice-1))]}\""
      return
    fi
    echo "  Invalid choice. Try again."
  done
}

# Read a table of project/workflow usage
ask_project_table() {
  local varname="$1"
  local workflows=("RPI" "Bug-diagnosis" "Divergent Design" "Codebase Onboarding" "Other" "None")

  echo ""
  bold "Q2. For each project listed above, which workflows did you use?"
  dim "  (Enter each project name, then select workflows. Empty project name to finish.)"
  echo ""

  local table_header="| Project | RPI | Bug-diagnosis | Divergent Design | Codebase Onboarding | Other | None |"
  local table_sep="|---------|-----|---------------|------------------|---------------------|-------|------|"
  local table_rows=""

  while true; do
    printf "  Project name (blank to finish): "
    read -r proj_name
    [[ -z "$proj_name" ]] && break

    echo "  Select workflows used in '$proj_name' (comma-separated numbers, e.g. 1,3):"
    local i=1
    for wf in "${workflows[@]}"; do
      echo "    $i) $wf"
      ((i++))
    done
    printf "  > "
    read -r selections

    local row="| $proj_name "
    for idx in $(seq 1 ${#workflows[@]}); do
      if echo ",$selections," | grep -q ",$idx,"; then
        row+="| X "
      else
        row+="| "
      fi
    done
    row+="|"
    table_rows+="$row"$'\n'
  done

  eval "$varname=\"$table_header
$table_sep
$table_rows\""
}

# Read directory convention answers
ask_dir_conventions() {
  local varname="$1"
  echo ""
  bold "Q6. Which external projects have adopted these directory conventions?"
  dim "  (Enter project names for each, or leave blank for none.)"
  echo ""

  local dirs=("docs/decisions/" "docs/thoughts/" "docs/working/")
  local result=""

  for d in "${dirs[@]}"; do
    printf "  %s projects: " "$d"
    read -r projects
    if [[ -n "$projects" ]]; then
      result+="- \`$d\` — $projects"$'\n'
    else
      result+="- \`$d\` — (none)"$'\n'
    fi
  done

  eval "$varname=\"\$result\""
}

# ============================================================
# Main survey flow
# ============================================================
clear 2>/dev/null || true
echo ""
green "╔══════════════════════════════════════════════════╗"
green "║   Hypothesis Resolution Survey (H-01 — H-07)   ║"
green "╚══════════════════════════════════════════════════╝"
echo ""
echo "This survey resolves 7 hypotheses about workflow/skill adoption."
echo "It takes about 2 minutes. Your answers are saved to:"
dim "  $RESULTS_FILE"
echo ""
echo "Press Enter to begin..."
read -r

# --- Section A: Workflow Usage ---
cyan "═══ Section A: Workflow Usage (H-01, H-03, H-04, H-07) ═══"

ask_free "Q1. List the external projects (not claude-workflows itself) where you've used Claude Code in the last 30 days." A1

ask_project_table A2

ask_free "Q3. In the last 30 days, roughly how many times have you kicked off the full RPI workflow (research doc + plan doc + implement) in external projects?" A3

ask_free "Q4. Have you started any new projects (or returned to a dormant one) since the codebase-onboarding workflow was added? If yes, did you use the onboarding workflow?" A4

ask_free "Q5. Have you ever used the bug-diagnosis workflow in an external project? If yes, name the project and what you were debugging." A5

# --- Section B: Structural Patterns ---
cyan "═══ Section B: Structural Patterns (H-02) ═══"

ask_dir_conventions A6

ask_free "Q7. For projects that adopted these patterns: do you perceive a difference in how organized or structured the work feels compared to projects without them?" A7

# --- Section C: Skills vs. Workflows ---
cyan "═══ Section C: Skills vs. Workflows (H-05) ═══"

ask_free "Q8. Which skills (e.g., fact-check, draft-review, simplify, cowen-critique, ui-visual-review) have you used in external projects in the last 30 days?" A8

ask_choice "Q9. Roughly, how does the frequency compare?" A9 \
  "I use skills much more often than workflows in external projects" \
  "I use skills and workflows about equally" \
  "I use workflows more often than skills" \
  "I rarely use either in external projects"

# --- Section D: Adoption Barriers ---
cyan "═══ Section D: Adoption Barriers (H-06) ═══"

ask_free "Q10. Are there workflows you've consciously avoided or stopped using? If yes, which ones and why?" A10

ask_free "Q11. Does the length or complexity of a workflow doc affect whether you'll invoke it? (e.g., \"I skip X because it's too many steps\")" A11

# --- Section E: Open-ended ---
cyan "═══ Section E: Open-ended ═══"

ask_free "Q12. Is there anything about your workflow/skill usage patterns that the questions above didn't capture?" A12

# ============================================================
# Write results
# ============================================================
cat > "$RESULTS_FILE" << RESULTS_EOF
# Hypothesis Resolution Survey Results

**Date:** $(date +%Y-%m-%d)
**Time:** $(date +%H:%M:%S)
**Runner version:** 1.0.0

---

## Section A: Workflow Usage (H-01, H-03, H-04, H-07)

**Q1.** List the external projects where you've used Claude Code in the last 30 days.

> $A1

**Q2.** For each project, which workflows did you use?

$A2

**Q3.** How many times have you kicked off full RPI in external projects (last 30 days)?

> $A3

**Q4.** Have you started new projects since codebase-onboarding was added? Did you use it?

> $A4

**Q5.** Have you used bug-diagnosis in an external project?

> $A5

---

## Section B: Structural Patterns (H-02)

**Q6.** Which external projects adopted directory conventions?

$A6

**Q7.** Perceived difference in structure/organization?

> $A7

---

## Section C: Skills vs. Workflows (H-05)

**Q8.** Which skills have you used in external projects (last 30 days)?

> $A8

**Q9.** Frequency comparison:

> $A9

---

## Section D: Adoption Barriers (H-06)

**Q10.** Workflows avoided or stopped using?

> $A10

**Q11.** Does complexity affect adoption?

> $A11

---

## Section E: Open-ended

**Q12.** Anything else?

> $A12

---

## Meta: Hypothesis Evaluation Support

This file was generated by \`scripts/run-hypothesis-survey.sh\` to support resolution
of hypotheses H-01 through H-07. Score results using the Scoring Guide in
\`docs/working/hypothesis-resolution-questionnaire.md\`.

**Runner hypothesis:** Making the survey a runnable script will result in it being
executed at least once within 2 rounds, resolving at least 2 of 7 TRACKING hypotheses.
This file's existence is evidence of execution. Count resolved hypotheses after scoring.
RESULTS_EOF

echo ""
green "════════════════════════════════════════"
green "  Survey complete! Results saved to:"
echo "  $RESULTS_FILE"
green "════════════════════════════════════════"
echo ""
echo "Next step: Score results using the Scoring Guide in"
echo "  docs/working/hypothesis-resolution-questionnaire.md"
echo ""
