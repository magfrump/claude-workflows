#!/usr/bin/env bash
# Manages a hypothesis backlog for screening potential improvements before
# implementation. Gathers evidence from external projects (usage logs, git
# history, review artifacts) to evaluate hypotheses without building anything.
#
# Subcommands:
#   check            Gather evidence for all TRACKING hypotheses (default)
#   add "text" "src" Add a new hypothesis to the backlog
#   report           Print summary by status and REFUTED rate
#
# Options:
#   --markdown       Output as markdown
#
# Evidence sources (declared per hypothesis, comma-separated):
#   usage.jsonl      Skill/workflow invocation logs
#   git-log          Git history in external project directories
#   reviews          Review artifacts in docs/reviews/
#   grep:PATTERN     Custom grep pattern across repos
#
# Env overrides:
#   HYPOTHESIS_BACKLOG_FILE  Path to backlog markdown (default: docs/working/hypothesis-backlog.md)
#   USAGE_LOG_FILE           Path to usage log (default: ~/.claude/logs/usage.jsonl)
#   EXTERNAL_PROJECTS        Colon-separated list of project dirs (default: auto-discover)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# --- Color helpers (disabled when piped) ---
if [ -t 1 ]; then
  bold()   { printf '\033[1m%s\033[0m' "$*"; }
  boldln() { printf '\033[1m%s\033[0m\n' "$*"; }
  dim()    { printf '\033[2m%s\033[0m' "$*"; }
  dimln()  { printf '\033[2m%s\033[0m\n' "$*"; }
else
  bold()   { printf '%s' "$*"; }
  boldln() { printf '%s\n' "$*"; }
  dim()    { printf '%s' "$*"; }
  dimln()  { printf '%s\n' "$*"; }
fi

# --- Dependency check ---
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed." >&2; exit 1; }

# --- Parse options ---
MARKDOWN=0
SUBCMD=""
ADD_TEXT=""
ADD_SOURCES=""
for arg in "$@"; do
  case "$arg" in
    --markdown) MARKDOWN=1 ;;
    check|report)
      if [ -z "$SUBCMD" ]; then SUBCMD="$arg"; else echo "Unknown argument: $arg" >&2; exit 1; fi ;;
    add)
      if [ -z "$SUBCMD" ]; then SUBCMD="add"; else echo "Unknown argument: $arg" >&2; exit 1; fi ;;
    *)
      if [ "$SUBCMD" = "add" ] && [ -z "$ADD_TEXT" ]; then
        ADD_TEXT="$arg"
      elif [ "$SUBCMD" = "add" ] && [ -z "$ADD_SOURCES" ]; then
        ADD_SOURCES="$arg"
      else
        echo "Unknown argument: $arg" >&2; exit 1
      fi ;;
  esac
done
SUBCMD="${SUBCMD:-check}"

# --- Configurable paths ---
BACKLOG="${HYPOTHESIS_BACKLOG_FILE:-${REPO_ROOT}/docs/working/hypothesis-backlog.md}"
USAGE_LOG="${USAGE_LOG_FILE:-$HOME/.claude/logs/usage.jsonl}"

# --- Trim whitespace helper ---
trim() {
  local v="$1"
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  printf '%s' "$v"
}

# --- Discover external projects ---
discover_external_projects() {
  if [ -n "${EXTERNAL_PROJECTS:-}" ]; then
    IFS=':' read -ra dirs <<< "$EXTERNAL_PROJECTS"
    printf '%s\n' "${dirs[@]}"
    return
  fi

  local cutoff
  cutoff="$(date -u -d '6 months ago' +%Y-%m-%d 2>/dev/null || date -u -v-6m +%Y-%m-%d 2>/dev/null || echo "2025-10-01")"

  # Collect candidate dirs from two sources, dedup by realpath
  declare -A seen_projects=()

  # Source 1: usage.jsonl project names (best signal — these actually used our tools)
  if [ -f "$USAGE_LOG" ] && [ -s "$USAGE_LOG" ]; then
    local usage_names
    usage_names="$(jq -r 'select(.project) | .project' "$USAGE_LOG" \
      | sort -u | { grep -vE '^(claude-workflows|wt-|$)' || true; })"
    while IFS= read -r proj_name; do
      [ -n "$proj_name" ] || continue
      # Search common locations for this project name
      for search_root in "$HOME" "$HOME"/*/ /mnt/c/Users/*/; do
        [ -d "$search_root" ] || continue
        local candidate="${search_root%/}/${proj_name}"
        if [ -d "$candidate/.git" ]; then
          local rp
          rp="$(realpath "$candidate" 2>/dev/null || echo "$candidate")"
          if [ -z "${seen_projects[$rp]:-}" ]; then
            seen_projects["$rp"]=1
            printf '%s\n' "$rp"
          fi
          break
        fi
      done
    done <<< "$usage_names"
  fi

  # Source 2: filesystem scan of $HOME/*/ (catches projects not yet in usage log)
  for dir in "$HOME"/*/; do
    [ -d "$dir" ] || continue
    local name
    name="${dir%/}"
    name="${name##*/}"
    case "$name" in
      claude-workflows|wt-*|.*) continue ;;
    esac
    [ -d "${dir}.git" ] || continue
    local rp
    rp="$(realpath "${dir%/}" 2>/dev/null || echo "${dir%/}")"
    [ -z "${seen_projects[$rp]:-}" ] || continue
    # Check for recent activity
    local latest
    latest="$(git -C "$dir" log -1 --format=%ci 2>/dev/null || echo "")"
    if [ -n "$latest" ] && [[ "$latest" > "$cutoff" ]]; then
      seen_projects["$rp"]=1
      printf '%s\n' "$rp"
    fi
  done
}

# --- Parse backlog into arrays ---
declare -a HYP_IDS=()
declare -A HYP_TEXT=()
declare -A HYP_SOURCES=()
declare -A HYP_CREATED=()
declare -A HYP_STATUS=()
declare -A HYP_CHECKED=()
declare -A HYP_EVIDENCE=()

parse_backlog() {
  if [ ! -f "$BACKLOG" ]; then
    echo "Error: backlog not found at $BACKLOG" >&2
    exit 1
  fi
  while IFS='|' read -r _ id text sources created status checked evidence _; do
    id="$(trim "$id")"
    # Skip header, separator, and empty rows
    [[ "$id" =~ ^H-[0-9]+$ ]] || continue
    HYP_IDS+=("$id")
    HYP_TEXT["$id"]="$(trim "$text")"
    HYP_SOURCES["$id"]="$(trim "$sources")"
    HYP_CREATED["$id"]="$(trim "$created")"
    HYP_STATUS["$id"]="$(trim "$status")"
    # shellcheck disable=SC2034
    HYP_CHECKED["$id"]="$(trim "$checked")"
    HYP_EVIDENCE["$id"]="$(trim "$evidence")"
  done < "$BACKLOG"
}

# --- Evidence: usage.jsonl ---
gather_usage_evidence() {
  local hyp_id="$1"
  local hyp_text="${HYP_TEXT[$hyp_id]}"

  if [ ! -f "$USAGE_LOG" ] || [ ! -s "$USAGE_LOG" ]; then
    echo "  usage.jsonl: No data (file missing or empty)"
    return
  fi

  # Count external entries (excluding claude-workflows and wt-*)
  local external_count
  external_count="$(jq -r 'select(.project) | .project' "$USAGE_LOG" \
    | { grep -vE '^(claude-workflows|wt-|$)' || true; } | wc -l | tr -d ' ')"

  if [ "$external_count" -lt 5 ]; then
    echo "  usage.jsonl: SPARSE external data ($external_count entries). Evidence from git-log may be more reliable."
  fi

  # Extract skill/workflow names from hypothesis text by matching against known items
  local known_names=()
  for f in "$REPO_ROOT"/skills/*.md "$REPO_ROOT"/workflows/*.md; do
    [ -f "$f" ] || continue
    local n="${f##*/}"
    n="${n%.md}"
    known_names+=("$n")
  done

  local matched_names=()
  local hyp_lower
  hyp_lower="$(echo "$hyp_text" | tr '[:upper:]' '[:lower:]')"
  for n in "${known_names[@]}"; do
    local n_lower
    n_lower="$(echo "$n" | tr '[:upper:]' '[:lower:]')"
    # Match hyphenated name or space-separated version
    local n_spaced="${n_lower//-/ }"
    if [[ "$hyp_lower" == *"$n_lower"* ]] || [[ "$hyp_lower" == *"$n_spaced"* ]]; then
      matched_names+=("$n")
    fi
  done

  if [ ${#matched_names[@]} -eq 0 ]; then
    # No specific name matched — report overall external usage
    local total
    total="$(jq -r 'select(.event) | .event' "$USAGE_LOG" | wc -l | tr -d ' ')"
    local ext_projects
    ext_projects="$(jq -r 'select(.project) | .project' "$USAGE_LOG" \
      | { grep -vE '^(claude-workflows|wt-|$)' || true; } | sort -u | head -20 | paste -sd', ' -)"
    echo "  usage.jsonl: No specific skill/workflow name matched in hypothesis text."
    echo "    Total entries: $total, External entries: $external_count"
    if [ -n "$ext_projects" ]; then
      echo "    External projects: $ext_projects"
    fi
    return
  fi

  for name in "${matched_names[@]}"; do
    local total_for_name ext_for_name projects_for_name
    total_for_name="$(jq -r --arg n "$name" 'select(.name == $n) | .name' "$USAGE_LOG" | wc -l | tr -d ' ')"
    ext_for_name="$(jq -r --arg n "$name" 'select(.name == $n and .project) | .project' "$USAGE_LOG" \
      | { grep -vE '^(claude-workflows|wt-|$)' || true; } | wc -l | tr -d ' ')"
    projects_for_name="$(jq -r --arg n "$name" 'select(.name == $n and .project) | .project' "$USAGE_LOG" \
      | { grep -vE '^(claude-workflows|wt-|$)' || true; } | sort -u | paste -sd', ' -)"
    echo "  usage.jsonl [$name]: $total_for_name total, $ext_for_name external"
    if [ -n "$projects_for_name" ]; then
      echo "    External projects: $projects_for_name"
    fi
  done
}

# --- Evidence: git-log ---
gather_gitlog_evidence() {
  local hyp_id="$1"
  local hyp_text="${HYP_TEXT[$hyp_id]}"

  # Git-log evidence is cumulative — look back 90 days or to creation date,
  # whichever is earlier, so we catch pre-existing patterns
  local ninety_ago
  ninety_ago="$(date -u -d '90 days ago' +%Y-%m-%d 2>/dev/null || date -u -v-90d +%Y-%m-%d 2>/dev/null || echo "2026-01-01")"
  local created="${HYP_CREATED[$hyp_id]}"
  local since_date="$ninety_ago"
  if [ -n "$created" ] && [[ "$created" < "$ninety_ago" ]]; then
    since_date="$created"
  fi

  local projects
  projects="$(discover_external_projects)"
  if [ -z "$projects" ]; then
    echo "  git-log: No external projects found."
    return
  fi

  local project_count=0
  local active_count=0
  local evidence_count=0
  local evidence_projects=""

  # Build search terms from hypothesis text — look for workflow/decision patterns
  local search_terms=("docs/decisions" "docs/thoughts" "docs/working" "divergent" "research-plan" "spike" "bug-diagnosis" "onboarding")
  # Also add matched skill/workflow names
  for f in "$REPO_ROOT"/skills/*.md "$REPO_ROOT"/workflows/*.md; do
    [ -f "$f" ] || continue
    local n="${f##*/}"
    n="${n%.md}"
    local hyp_lower
    hyp_lower="$(echo "$hyp_text" | tr '[:upper:]' '[:lower:]')"
    local n_lower="${n,,}"
    local n_spaced="${n_lower//-/ }"
    if [[ "$hyp_lower" == *"$n_lower"* ]] || [[ "$hyp_lower" == *"$n_spaced"* ]]; then
      search_terms+=("$n")
    fi
  done

  while IFS= read -r dir; do
    [ -d "$dir" ] || continue
    project_count=$((project_count + 1))
    local proj_name="${dir##*/}"

    local commit_count
    commit_count="$(git -C "$dir" log --oneline --since="$since_date" 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$commit_count" -eq 0 ]; then
      continue
    fi
    active_count=$((active_count + 1))

    # Search for evidence of workflow adoption
    local found=0
    for term in "${search_terms[@]}"; do
      local matches
      matches="$(git -C "$dir" log --oneline --since="$since_date" --grep="$term" 2>/dev/null | wc -l | tr -d ' ')"
      if [ "$matches" -gt 0 ]; then
        found=1
        break
      fi
    done

    # Also check for workflow artifact directories
    if [ "$found" -eq 0 ]; then
      for artifact_dir in "docs/decisions" "docs/thoughts" "docs/working"; do
        if [ -d "${dir}/${artifact_dir}" ]; then
          found=1
          break
        fi
      done
    fi

    if [ "$found" -eq 1 ]; then
      evidence_count=$((evidence_count + 1))
      if [ -n "$evidence_projects" ]; then
        evidence_projects="${evidence_projects}, ${proj_name}"
      else
        evidence_projects="$proj_name"
      fi
    fi
  done <<< "$projects"

  echo "  git-log: $project_count external projects scanned, $active_count active (since $since_date)"
  if [ "$active_count" -eq 0 ]; then
    echo "    No active external projects found. Cannot evaluate hypothesis."
  elif [ "$evidence_count" -eq 0 ]; then
    echo "    0 of $active_count active projects show evidence. This is evidence AGAINST the hypothesis."
  else
    echo "    $evidence_count of $active_count active projects show evidence: $evidence_projects"
  fi
}

# --- Evidence: reviews ---
gather_reviews_evidence() {
  local hyp_id="$1"
  local reviews_dir="${REPO_ROOT}/docs/reviews"

  if [ ! -d "$reviews_dir" ]; then
    echo "  reviews: No docs/reviews/ directory found."
    return
  fi

  local count
  count="$(find "$reviews_dir" -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$count" -eq 0 ]; then
    echo "  reviews: No review artifacts found."
    return
  fi

  local newest
  newest="$(find "$reviews_dir" -type f -name '*.md' -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn | head -1 | cut -d' ' -f2-)"
  echo "  reviews: $count artifacts found. Most recent: ${newest##*/}"
}

# --- Evidence: grep:PATTERN ---
gather_grep_evidence() {
  local pattern="$1"

  local repo_matches=0
  local ext_matches=0

  # Search in this repo
  repo_matches="$({ grep -rl "$pattern" "$REPO_ROOT" --include='*.md' --include='*.sh' 2>/dev/null || true; } | wc -l | tr -d ' ')"

  # Search in external projects (limit depth to avoid scanning huge repos)
  local projects
  projects="$(discover_external_projects)"
  if [ -n "$projects" ]; then
    while IFS= read -r dir; do
      [ -d "$dir" ] || continue
      local m
      m="$({ grep -rl --max-depth=3 "$pattern" "$dir" --include='*.md' --include='*.sh' 2>/dev/null || true; } | wc -l | tr -d ' ')"
      ext_matches=$((ext_matches + m))
    done <<< "$projects"
  fi

  echo "  grep:$pattern: $repo_matches matches in repo, $ext_matches in external projects"
}

# --- Subcommand: check ---
cmd_check() {
  parse_backlog

  local tracking_count=0
  for id in "${HYP_IDS[@]}"; do
    if [ "${HYP_STATUS[$id]}" = "TRACKING" ]; then
      tracking_count=$((tracking_count + 1))
    fi
  done

  if [ "$tracking_count" -eq 0 ]; then
    echo "No TRACKING hypotheses to check."
    return
  fi

  local today
  today="$(date -u +%Y-%m-%d)"

  if [ "$MARKDOWN" -eq 1 ]; then
    echo "# Hypothesis Screening Report"
    echo ""
    echo "**Date:** $today"
    echo "**TRACKING hypotheses:** $tracking_count"
    echo ""
  else
    boldln "Hypothesis Screening Report — $today"
    echo "TRACKING hypotheses: $tracking_count"
    echo ""
  fi

  # Collect summaries for backlog update
  declare -A check_summaries=()

  for id in "${HYP_IDS[@]}"; do
    [ "${HYP_STATUS[$id]}" = "TRACKING" ] || continue

    if [ "$MARKDOWN" -eq 1 ]; then
      echo "## $id: ${HYP_TEXT[$id]}"
      echo ""
      echo "**Sources:** ${HYP_SOURCES[$id]} | **Created:** ${HYP_CREATED[$id]}"
      echo ""
      echo "\`\`\`"
    else
      boldln "--- $id: ${HYP_TEXT[$id]}"
      dimln "Sources: ${HYP_SOURCES[$id]} | Created: ${HYP_CREATED[$id]}"
    fi

    # Evidence details go to stdout; summary is "Checked <date>"

    # Dispatch to evidence gatherers based on declared sources
    IFS=',' read -ra sources <<< "${HYP_SOURCES[$id]}"
    for src in "${sources[@]}"; do
      src="$(trim "$src")"
      case "$src" in
        usage.jsonl) gather_usage_evidence "$id" ;;
        git-log)     gather_gitlog_evidence "$id" ;;
        reviews)     gather_reviews_evidence "$id" ;;
        grep:*)      gather_grep_evidence "${src#grep:}" ;;
        *)           echo "  Unknown source: $src" ;;
      esac
    done

    if [ "$MARKDOWN" -eq 1 ]; then
      echo "\`\`\`"
      echo ""
    else
      echo ""
    fi

    check_summaries["$id"]="Checked $today"
  done

  # Update backlog: set Last Checked for all checked hypotheses
  if [ ${#check_summaries[@]} -gt 0 ]; then
    local tmpfile
    tmpfile="$(mktemp)"
    while IFS= read -r line; do
      local updated=0
      for id in "${!check_summaries[@]}"; do
        if [[ "$line" == *"| $id |"* ]]; then
          # Reconstruct line with updated Last Checked
          local new_line
          new_line="$(echo "$line" | awk -F'|' -v date="$today" '{
            OFS="|"
            # Field 7 is Last Checked (1-indexed, field 0 is empty before first pipe)
            $7 = " " date " "
            print
          }')"
          echo "$new_line" >> "$tmpfile"
          updated=1
          break
        fi
      done
      if [ "$updated" -eq 0 ]; then
        echo "$line" >> "$tmpfile"
      fi
    done < "$BACKLOG"
    mv "$tmpfile" "$BACKLOG"
  fi
}

# --- Subcommand: add ---
cmd_add() {
  if [ -z "$ADD_TEXT" ]; then
    echo "Usage: hypothesis-screen.sh add \"Hypothesis text\" \"evidence-sources\"" >&2
    exit 1
  fi
  if [ -z "$ADD_SOURCES" ]; then
    echo "Usage: hypothesis-screen.sh add \"Hypothesis text\" \"evidence-sources\"" >&2
    echo "  evidence-sources: comma-separated list (usage.jsonl, git-log, reviews, grep:PATTERN)" >&2
    exit 1
  fi

  if [ ! -f "$BACKLOG" ]; then
    echo "Error: backlog not found at $BACKLOG" >&2
    exit 1
  fi

  # Find the next ID
  local max_num=0
  while IFS='|' read -r _ id _rest; do
    id="$(trim "$id")"
    if [[ "$id" =~ ^H-([0-9]+)$ ]]; then
      local num="${BASH_REMATCH[1]}"
      num=$((10#$num))
      if [ "$num" -gt "$max_num" ]; then
        max_num="$num"
      fi
    fi
  done < "$BACKLOG"

  local next_num=$((max_num + 1))
  local next_id
  next_id="$(printf 'H-%02d' "$next_num")"
  local today
  today="$(date -u +%Y-%m-%d)"

  echo "| $next_id | $ADD_TEXT | $ADD_SOURCES | $today | TRACKING | | |" >> "$BACKLOG"
  echo "Added $next_id: $ADD_TEXT"
}

# --- Subcommand: report ---
cmd_report() {
  parse_backlog

  local total=${#HYP_IDS[@]}
  local tracking=0 confirmed=0 refuted=0 inconclusive=0 implemented=0

  for id in "${HYP_IDS[@]}"; do
    case "${HYP_STATUS[$id]}" in
      TRACKING)     tracking=$((tracking + 1)) ;;
      CONFIRMED)    confirmed=$((confirmed + 1)) ;;
      REFUTED)      refuted=$((refuted + 1)) ;;
      INCONCLUSIVE) inconclusive=$((inconclusive + 1)) ;;
      IMPLEMENTED)  implemented=$((implemented + 1)) ;;
    esac
  done

  local resolved=$((confirmed + refuted + inconclusive))
  local refuted_rate="n/a"
  if [ "$resolved" -gt 0 ]; then
    refuted_rate="$((refuted * 100 / resolved))%"
  fi

  if [ "$MARKDOWN" -eq 1 ]; then
    echo "# Hypothesis Backlog Summary"
    echo ""
    echo "| Metric | Value |"
    echo "|--------|------:|"
    echo "| Total | $total |"
    echo "| TRACKING | $tracking |"
    echo "| CONFIRMED | $confirmed |"
    echo "| REFUTED | $refuted |"
    echo "| INCONCLUSIVE | $inconclusive |"
    echo "| IMPLEMENTED | $implemented |"
    echo "| **REFUTED rate** | **$refuted_rate** |"
    echo ""
    echo "REFUTED rate = work saved. Higher is better."
    echo ""
    if [ "$tracking" -gt 0 ]; then
      echo "## TRACKING"
      echo ""
      for id in "${HYP_IDS[@]}"; do
        [ "${HYP_STATUS[$id]}" = "TRACKING" ] || continue
        echo "- **$id**: ${HYP_TEXT[$id]}"
      done
      echo ""
    fi
    for status in CONFIRMED REFUTED INCONCLUSIVE IMPLEMENTED; do
      local has_any=0
      for id in "${HYP_IDS[@]}"; do
        if [ "${HYP_STATUS[$id]}" = "$status" ]; then has_any=1; break; fi
      done
      if [ "$has_any" -eq 1 ]; then
        echo "## $status"
        echo ""
        for id in "${HYP_IDS[@]}"; do
          [ "${HYP_STATUS[$id]}" = "$status" ] || continue
          echo "- **$id**: ${HYP_TEXT[$id]}"
        if [ -n "${HYP_EVIDENCE[$id]:-}" ]; then
          echo "  - Evidence: ${HYP_EVIDENCE[$id]}"
        fi
        done
        echo ""
      fi
    done
  else
    boldln "Hypothesis Backlog Summary"
    echo ""
    echo "Total:         $total"
    echo "TRACKING:      $tracking"
    echo "CONFIRMED:     $confirmed"
    echo "REFUTED:       $refuted"
    echo "INCONCLUSIVE:  $inconclusive"
    echo "IMPLEMENTED:   $implemented"
    echo ""
    boldln "REFUTED rate: $refuted_rate (work saved — higher is better)"
    echo ""
    if [ "$tracking" -gt 0 ]; then
      boldln "TRACKING:"
      for id in "${HYP_IDS[@]}"; do
        [ "${HYP_STATUS[$id]}" = "TRACKING" ] || continue
        echo "  $id: ${HYP_TEXT[$id]}"
      done
      echo ""
    fi
    for status in CONFIRMED REFUTED INCONCLUSIVE IMPLEMENTED; do
      local has_any=0
      for id in "${HYP_IDS[@]}"; do
        if [ "${HYP_STATUS[$id]}" = "$status" ]; then has_any=1; break; fi
      done
      if [ "$has_any" -eq 1 ]; then
        boldln "$status:"
        for id in "${HYP_IDS[@]}"; do
          [ "${HYP_STATUS[$id]}" = "$status" ] || continue
          echo "  $id: ${HYP_TEXT[$id]}"
          if [ -n "${HYP_EVIDENCE[$id]:-}" ]; then
            echo "    Evidence: ${HYP_EVIDENCE[$id]}"
          fi
        done
        echo ""
      fi
    done
  fi
}

# --- Main dispatch ---
case "$SUBCMD" in
  check)  cmd_check ;;
  add)    cmd_add ;;
  report) cmd_report ;;
  *)      echo "Unknown subcommand: $SUBCMD" >&2; exit 1 ;;
esac
