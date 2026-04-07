#!/usr/bin/env bash
# Scans a configurable list of local project directories for workflow and skill
# usage signals, producing a structured JSON report mapping each hypothesis
# (H-01 through H-07) to the evidence found.
#
# Usage:
#   scripts/collect-evidence.sh [OPTIONS]
#
# Options:
#   --config FILE    Path to config file listing project dirs (default: .evidence-config)
#   --output FILE    Write JSON to file instead of stdout
#   --pretty         Pretty-print JSON output
#   --help           Show this help
#
# Config file format:
#   One absolute path per line. Lines starting with # are comments. Empty lines ignored.
#
# Evidence sources scanned per project:
#   - docs/decisions/, docs/working/, docs/thoughts/ directory presence
#   - Git log mentions of workflow names (RPI, spike, divergent-design, etc.)
#   - CLAUDE.md files referencing workflows
#   - usage.jsonl entries (if present)
#
# Env overrides:
#   USAGE_LOG_FILE    Path to usage log (default: ~/.claude/logs/usage.jsonl)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# --- Defaults ---
CONFIG_FILE="${REPO_ROOT}/.evidence-config"
OUTPUT_FILE=""
PRETTY=0

# --- Parse options ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)  CONFIG_FILE="$2"; shift 2 ;;
    --output)  OUTPUT_FILE="$2"; shift 2 ;;
    --pretty)  PRETTY=1; shift ;;
    --help)
      sed -n '2,/^$/s/^# \?//p' "$0"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# --- Dependency check ---
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed." >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "Error: git is required but not installed." >&2; exit 1; }

# --- Load config ---
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Config file not found: $CONFIG_FILE" >&2
  echo "Create it with one project directory path per line." >&2
  echo "See .evidence-config.example for format." >&2
  exit 1
fi

PROJECT_DIRS=()
while IFS= read -r line; do
  line="${line%%#*}"           # strip comments
  line="${line#"${line%%[![:space:]]*}"}"  # trim leading
  line="${line%"${line##*[![:space:]]}"}"  # trim trailing
  [ -n "$line" ] || continue
  PROJECT_DIRS+=("$line")
done < "$CONFIG_FILE"

if [ ${#PROJECT_DIRS[@]} -eq 0 ]; then
  echo "Error: No project directories found in $CONFIG_FILE" >&2
  exit 1
fi

# --- Usage log ---
USAGE_LOG="${USAGE_LOG_FILE:-$HOME/.claude/logs/usage.jsonl}"

# --- Workflow search terms ---
# Maps short names to grep-friendly patterns for git log searching
declare -A WORKFLOW_PATTERNS=(
  [rpi]="research-plan-implement\|RPI\|research-plan\|docs/working/plan-\|docs/working/research-"
  [spike]="spike\|spike:"
  [divergent-design]="divergent.design\|divergent-design"
  [bug-diagnosis]="bug-diagnosis\|bug.diagnosis"
  [codebase-onboarding]="codebase-onboarding\|codebase.onboarding"
  [pr-prep]="pr-prep\|pr.prep"
  [task-decomposition]="task-decomposition\|task.decomposition"
  [branch-strategy]="branch-strategy\|branch.strategy"
  [user-testing]="user-testing-workflow\|user.testing"
)

# --- Helper: scan a single project directory ---
# Outputs a JSON object with all signals found
scan_project() {
  local dir="$1"
  local proj_name="${dir##*/}"

  if [ ! -d "$dir" ]; then
    jq -n --arg name "$proj_name" --arg path "$dir" \
      '{name: $name, path: $path, error: "directory not found"}'
    return
  fi

  local is_git="false"
  [ ! -d "$dir/.git" ] || is_git="true"

  # Directory presence checks
  local has_decisions="false" has_working="false" has_thoughts="false"
  [ ! -d "$dir/docs/decisions" ] || has_decisions="true"
  [ ! -d "$dir/docs/working" ] || has_working="true"
  [ ! -d "$dir/docs/thoughts" ] || has_thoughts="true"

  # CLAUDE.md workflow references
  local claude_md_workflows="[]"
  if [ -f "$dir/CLAUDE.md" ]; then
    local refs=()
    for wf_name in "${!WORKFLOW_PATTERNS[@]}"; do
      if grep -qi "$wf_name" "$dir/CLAUDE.md" 2>/dev/null; then
        refs+=("\"$wf_name\"")
      fi
    done
    if [ ${#refs[@]} -gt 0 ]; then
      claude_md_workflows="[$(IFS=,; echo "${refs[*]}")]"
    fi
  fi

  # Git log workflow mentions (last 90 days)
  local git_workflow_mentions="{}"
  if [ "$is_git" = "true" ]; then
    local since_date
    since_date="$(date -u -d '90 days ago' +%Y-%m-%d 2>/dev/null || date -u -v-90d +%Y-%m-%d 2>/dev/null || echo "2025-10-01")"

    local mentions_json="{"
    local first=1
    for wf_name in "${!WORKFLOW_PATTERNS[@]}"; do
      local pattern="${WORKFLOW_PATTERNS[$wf_name]}"
      local count
      count="$(git -C "$dir" log --oneline --since="$since_date" --grep="$wf_name" -i 2>/dev/null | wc -l | tr -d ' ')"
      # Also search with the full pattern for multi-word matches
      if [ "$count" -eq 0 ]; then
        count="$(git -C "$dir" log --oneline --since="$since_date" --grep="$pattern" 2>/dev/null | wc -l | tr -d ' ')"
      fi
      if [ "$count" -gt 0 ]; then
        [ "$first" -eq 1 ] || mentions_json+=","
        mentions_json+="\"$wf_name\":$count"
        first=0
      fi
    done
    mentions_json+="}"
    git_workflow_mentions="$mentions_json"
  fi

  # Structured commits check (conventional commit format)
  local structured_commit_ratio="null"
  if [ "$is_git" = "true" ]; then
    local since_date
    since_date="$(date -u -d '90 days ago' +%Y-%m-%d 2>/dev/null || date -u -v-90d +%Y-%m-%d 2>/dev/null || echo "2025-10-01")"
    local total_commits
    total_commits="$(git -C "$dir" log --oneline --since="$since_date" 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$total_commits" -gt 0 ]; then
      local structured_commits
      structured_commits="$(git -C "$dir" log --oneline --since="$since_date" 2>/dev/null \
        | grep -cE '^\w+ (feat|fix|refactor|test|docs|chore|style|perf|ci|build|spike|revert)[(:!]' || true)"
      structured_commit_ratio="$(echo "scale=2; $structured_commits / $total_commits" | bc 2>/dev/null || echo "null")"
    fi
  fi

  # Decision count
  local decision_count=0
  if [ -d "$dir/docs/decisions" ]; then
    decision_count="$(find "$dir/docs/decisions" -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')"
  fi

  # Working doc count
  local working_count=0
  if [ -d "$dir/docs/working" ]; then
    working_count="$(find "$dir/docs/working" -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')"
  fi

  jq -n \
    --arg name "$proj_name" \
    --arg path "$dir" \
    --argjson is_git "$is_git" \
    --argjson has_decisions "$has_decisions" \
    --argjson has_working "$has_working" \
    --argjson has_thoughts "$has_thoughts" \
    --argjson claude_md_workflows "$claude_md_workflows" \
    --argjson git_workflow_mentions "$git_workflow_mentions" \
    --argjson structured_commit_ratio "$structured_commit_ratio" \
    --argjson decision_count "$decision_count" \
    --argjson working_count "$working_count" \
    '{
      name: $name,
      path: $path,
      is_git: $is_git,
      has_decisions: $has_decisions,
      has_working: $has_working,
      has_thoughts: $has_thoughts,
      claude_md_workflows: $claude_md_workflows,
      git_workflow_mentions: $git_workflow_mentions,
      structured_commit_ratio: $structured_commit_ratio,
      decision_count: $decision_count,
      working_count: $working_count
    }'
}

# --- Gather usage.jsonl evidence ---
gather_usage_data() {
  if [ ! -f "$USAGE_LOG" ] || [ ! -s "$USAGE_LOG" ]; then
    echo '{}'
    return
  fi

  # Get the list of project names from config (basenames)
  local project_names=()
  for dir in "${PROJECT_DIRS[@]}"; do
    project_names+=("${dir##*/}")
  done

  # Build jq filter for matching project names
  local names_json
  names_json="$(printf '%s\n' "${project_names[@]}" | jq -R . | jq -s .)"

  # Extract per-project, per-event-type counts
  jq --argjson names "$names_json" '
    select(.project as $p | $names | index($p))
  ' "$USAGE_LOG" 2>/dev/null | jq -s '
    group_by(.project) | map({
      key: .[0].project,
      value: {
        total: length,
        skills: [.[] | select(.event == "skill") | .name] | group_by(.) | map({key: .[0], value: length}) | from_entries,
        workflows: [.[] | select(.event == "workflow") | .name] | group_by(.) | map({key: .[0], value: length}) | from_entries,
        skill_count: [.[] | select(.event == "skill")] | length,
        workflow_count: [.[] | select(.event == "workflow")] | length
      }
    }) | from_entries
  ' 2>/dev/null || echo '{}'
}

# --- Map evidence to hypotheses ---
build_hypothesis_evidence() {
  local projects_json="$1"
  local usage_json="$2"

  # Count projects with various signals
  local project_count
  project_count="$(echo "$projects_json" | jq 'length')"

  # H-01: RPI actively used (>2/month) in external projects
  local h01_evidence
  h01_evidence="$(echo "$projects_json" | jq '{
    hypothesis: "RPI workflow is actively used in external projects (>2 per month)",
    signals: {
      projects_with_working_docs: [.[] | select(.has_working == true) | .name],
      projects_with_rpi_git_mentions: [.[] | select(.git_workflow_mentions.rpi > 0) | {name: .name, count: .git_workflow_mentions.rpi}],
      projects_with_rpi_in_claude_md: [.[] | select(.claude_md_workflows | index("rpi")) | .name]
    },
    usage_log: '"$(echo "$usage_json" | jq '{
      projects_with_workflow_usage: [to_entries[] | select(.value.workflows | to_entries | map(select(.key | test("research-plan";"i"))) | length > 0) | .key]
    }' 2>/dev/null || echo '{"projects_with_workflow_usage":[]}')"',
    assessment: (
      ([.[] | select(.has_working == true)] | length) as $working |
      ([.[] | select(.git_workflow_mentions.rpi > 0)] | length) as $git |
      if ($working + $git) > 0 then "EVIDENCE_FOUND"
      else "NO_EVIDENCE"
      end
    )
  }')"

  # H-02: Workflow adopters produce more structured commits
  local h02_evidence
  h02_evidence="$(echo "$projects_json" | jq '{
    hypothesis: "External projects adopting workflow patterns produce more structured commits",
    signals: {
      adopters: [.[] | select(.has_decisions == true or .has_working == true or .has_thoughts == true) |
        {name: .name, structured_commit_ratio: .structured_commit_ratio, has_decisions: .has_decisions, has_working: .has_working}],
      non_adopters: [.[] | select(.has_decisions == false and .has_working == false and .has_thoughts == false) |
        {name: .name, structured_commit_ratio: .structured_commit_ratio}]
    },
    assessment: (
      ([.[] | select(.has_decisions == true or .has_working == true) | .structured_commit_ratio // 0] | if length > 0 then (add / length) else null end) as $adopter_avg |
      ([.[] | select(.has_decisions == false and .has_working == false) | .structured_commit_ratio // 0] | if length > 0 then (add / length) else null end) as $non_avg |
      if $adopter_avg == null or $non_avg == null then "INSUFFICIENT_DATA"
      elif $adopter_avg > $non_avg then "EVIDENCE_FOR"
      elif $adopter_avg < $non_avg then "EVIDENCE_AGAINST"
      else "INCONCLUSIVE"
      end
    )
  }')"

  # H-03: Bug-diagnosis never used outside self-improvement
  local h03_evidence
  h03_evidence="$(echo "$projects_json" | jq '{
    hypothesis: "The bug-diagnosis workflow is never used outside the self-improvement loop",
    signals: {
      projects_with_bug_diagnosis_git_mentions: [.[] | select(.git_workflow_mentions."bug-diagnosis" > 0) | {name: .name, count: .git_workflow_mentions."bug-diagnosis"}],
      projects_with_bug_diagnosis_in_claude_md: [.[] | select(.claude_md_workflows | index("bug-diagnosis")) | .name]
    },
    usage_log: '"$(echo "$usage_json" | jq '{
      projects_with_bug_diagnosis: [to_entries[] | select(.value.workflows | to_entries | map(select(.key | test("bug-diagnosis";"i"))) | length > 0) | .key]
    }' 2>/dev/null || echo '{"projects_with_bug_diagnosis":[]}')"',
    assessment: (
      ([.[] | select(.git_workflow_mentions."bug-diagnosis" > 0)] | length) as $git |
      if $git > 0 then "EVIDENCE_AGAINST (used externally — hypothesis likely false)"
      else "EVIDENCE_FOR (no external usage found — hypothesis may be true)"
      end
    )
  }')"

  # H-04: Divergent design used for architectural decisions externally
  local h04_evidence
  h04_evidence="$(echo "$projects_json" | jq '{
    hypothesis: "Divergent design is used in external projects for architectural decisions",
    signals: {
      projects_with_dd_git_mentions: [.[] | select(.git_workflow_mentions."divergent-design" > 0) | {name: .name, count: .git_workflow_mentions."divergent-design"}],
      projects_with_dd_in_claude_md: [.[] | select(.claude_md_workflows | index("divergent-design")) | .name],
      projects_with_decisions_dir: [.[] | select(.has_decisions == true) | {name: .name, count: .decision_count}]
    },
    usage_log: '"$(echo "$usage_json" | jq '{
      projects_with_dd_usage: [to_entries[] | select(.value.workflows | to_entries | map(select(.key | test("divergent";"i"))) | length > 0) | .key]
    }' 2>/dev/null || echo '{"projects_with_dd_usage":[]}')"',
    assessment: (
      ([.[] | select(.git_workflow_mentions."divergent-design" > 0)] | length) as $git |
      ([.[] | select(.has_decisions == true)] | length) as $decisions |
      if ($git + $decisions) > 0 then "EVIDENCE_FOUND"
      else "NO_EVIDENCE"
      end
    )
  }')"

  # H-05: Skills invoked more frequently than workflows
  local h05_evidence
  h05_evidence="$(echo "$usage_json" | jq '{
    hypothesis: "Skills are invoked more frequently than workflows in external projects",
    signals: {
      per_project: to_entries | map({
        name: .key,
        skill_count: .value.skill_count,
        workflow_count: .value.workflow_count,
        skills_dominate: (.value.skill_count > .value.workflow_count)
      }),
      totals: {
        total_skills: ([to_entries[].value.skill_count] | add // 0),
        total_workflows: ([to_entries[].value.workflow_count] | add // 0)
      }
    },
    assessment: (
      ([to_entries[].value.skill_count] | add // 0) as $skills |
      ([to_entries[].value.workflow_count] | add // 0) as $workflows |
      if ($skills + $workflows) == 0 then "NO_USAGE_DATA"
      elif $skills > $workflows then "EVIDENCE_FOR"
      elif $skills < $workflows then "EVIDENCE_AGAINST"
      else "INCONCLUSIVE"
      end
    )
  }' 2>/dev/null || echo '{"hypothesis":"Skills invoked more frequently than workflows","signals":{},"assessment":"NO_USAGE_DATA"}')"

  # H-06: Workflow complexity correlates negatively with adoption
  # Count lines in each workflow file and cross-reference with usage
  local workflow_sizes="{}"
  if [ -d "$REPO_ROOT/workflows" ]; then
    workflow_sizes="$(
      for f in "$REPO_ROOT"/workflows/*.md; do
        [ -f "$f" ] || continue
        local name="${f##*/}"
        name="${name%.md}"
        local lines
        lines="$(wc -l < "$f" | tr -d ' ')"
        printf '"%s":%d,' "$name" "$lines"
      done | sed 's/,$//' | { read -r data; echo "{${data:-}}"; }
    )"
  fi
  local h06_evidence
  h06_evidence="$(jq -n \
    --argjson sizes "$workflow_sizes" \
    --argjson usage "$usage_json" \
    --argjson projects "$projects_json" \
    '{
      hypothesis: "Workflow complexity (line count) correlates negatively with adoption",
      signals: {
        workflow_line_counts: $sizes,
        workflow_adoption: ($projects | map(.git_workflow_mentions) | map(to_entries) | flatten | group_by(.key) | map({key: .[0].key, value: ([.[].value] | add)}) | from_entries),
        usage_log_adoption: ($usage | to_entries | map(.value.workflows) | map(to_entries) | flatten | group_by(.key) | map({key: .[0].key, value: ([.[].value] | add)}) | from_entries)
      },
      assessment: "REQUIRES_MANUAL_ANALYSIS (compare line counts against adoption counts)"
    }')"

  # H-07: Codebase-onboarding used when starting new projects
  local h07_evidence
  h07_evidence="$(echo "$projects_json" | jq '{
    hypothesis: "The codebase-onboarding workflow is used when starting new projects",
    signals: {
      projects_with_onboarding_git_mentions: [.[] | select(.git_workflow_mentions."codebase-onboarding" > 0) | {name: .name, count: .git_workflow_mentions."codebase-onboarding"}],
      projects_with_onboarding_in_claude_md: [.[] | select(.claude_md_workflows | index("codebase-onboarding")) | .name]
    },
    usage_log: '"$(echo "$usage_json" | jq '{
      projects_with_onboarding: [to_entries[] | select(.value.workflows | to_entries | map(select(.key | test("onboarding";"i"))) | length > 0) | .key]
    }' 2>/dev/null || echo '{"projects_with_onboarding":[]}')"',
    assessment: (
      ([.[] | select(.git_workflow_mentions."codebase-onboarding" > 0)] | length) as $git |
      if $git > 0 then "EVIDENCE_FOUND"
      else "NO_EVIDENCE"
      end
    )
  }')"

  # Assemble final report
  jq -n \
    --argjson h01 "$h01_evidence" \
    --argjson h02 "$h02_evidence" \
    --argjson h03 "$h03_evidence" \
    --argjson h04 "$h04_evidence" \
    --argjson h05 "$h05_evidence" \
    --argjson h06 "$h06_evidence" \
    --argjson h07 "$h07_evidence" \
    --argjson project_count "$project_count" \
    --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg config "$CONFIG_FILE" \
    '{
      meta: {
        timestamp: $timestamp,
        config_file: $config,
        projects_scanned: $project_count,
        script_version: "1.0.0"
      },
      hypotheses: {
        "H-01": $h01,
        "H-02": $h02,
        "H-03": $h03,
        "H-04": $h04,
        "H-05": $h05,
        "H-06": $h06,
        "H-07": $h07
      }
    }'
}

# --- Main ---
echo "Scanning ${#PROJECT_DIRS[@]} project directories..." >&2

# Scan all projects
project_results="[]"
for dir in "${PROJECT_DIRS[@]}"; do
  echo "  Scanning: $dir" >&2
  result="$(scan_project "$dir")"
  project_results="$(echo "$project_results" | jq --argjson r "$result" '. + [$r]')"
done

# Gather usage.jsonl data
echo "  Gathering usage.jsonl data..." >&2
usage_data="$(gather_usage_data)"

# Build hypothesis evidence map
echo "  Building hypothesis evidence report..." >&2
report="$(build_hypothesis_evidence "$project_results" "$usage_data")"

# Add raw project data to report
report="$(echo "$report" | jq --argjson projects "$project_results" '. + {projects: $projects}')"

# Output
if [ "$PRETTY" -eq 1 ]; then
  formatted="$(echo "$report" | jq .)"
else
  formatted="$report"
fi

if [ -n "$OUTPUT_FILE" ]; then
  echo "$formatted" > "$OUTPUT_FILE"
  echo "Report written to: $OUTPUT_FILE" >&2
else
  echo "$formatted"
fi

echo "Done. $(echo "$report" | jq '[.hypotheses | to_entries[] | select(.value.assessment | test("EVIDENCE_FOUND|EVIDENCE_FOR|EVIDENCE_AGAINST"))] | length') of 7 hypotheses have actionable evidence." >&2
