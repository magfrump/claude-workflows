#!/usr/bin/env bash
# Searches GitHub for Claude Code workflow patterns, skill designs, and community
# practices, then outputs a curated candidate list for human review.
#
# Uses the GitHub REST API (via `gh` CLI or `curl` fallback) to search for repos
# and code matching terms like 'claude code workflow', 'claude code skills', and
# 'CLAUDE.md patterns'. Results are deduplicated, tagged by relevance, and written
# to docs/working/external-ideas-candidates.md for manual curation.
#
# Hypothesis support (H-EXT-01): The output includes a "Novel Ideas" section
# comparing candidates against docs/working/feature-ideas.md to measure whether
# external search surfaces ideas not already in the backlog.
#
# Usage:
#   scripts/search-external-ideas.sh [OPTIONS]
#
# Options:
#   --output FILE    Output file path (default: docs/working/external-ideas-candidates.md)
#   --dry-run        Print results to stdout instead of writing file
#   --help           Show this help
#
# Prerequisites:
#   - `gh` CLI (preferred) or `curl` + `jq` for GitHub API access
#   - Internet connectivity
#
# Environment variables:
#   GITHUB_TOKEN          Optional token for higher rate limits (unauthenticated: 10 req/min)
#   MAX_RESULTS_PER_QUERY Maximum results per search query (default: 15)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# --- Defaults ---
OUTPUT_FILE="${REPO_ROOT}/docs/working/external-ideas-candidates.md"
DRY_RUN=0
MAX_RESULTS="${MAX_RESULTS_PER_QUERY:-15}"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
DATE_SHORT="$(date -u +%Y-%m-%d)"

# --- Search queries ---
# Each entry: "query|relevance_tag"
SEARCH_QUERIES=(
  "claude code workflow|workflow-pattern"
  "claude code skills|skill-design"
  "CLAUDE.md patterns|claude-md-pattern"
  "CLAUDE.md best practices|claude-md-pattern"
  "claude code hooks|hook-pattern"
  "claude code slash command skill|skill-design"
)

# --- Parse options ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)  OUTPUT_FILE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help)
      sed -n '2,/^$/s/^# \?//p' "$0"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# --- Dependency check ---
HAS_GH=0
HAS_CURL=0
HAS_JQ=0

command -v gh   >/dev/null 2>&1 && HAS_GH=1
command -v curl >/dev/null 2>&1 && HAS_CURL=1
command -v jq   >/dev/null 2>&1 && HAS_JQ=1

if [[ "$HAS_GH" -eq 0 && ("$HAS_CURL" -eq 0 || "$HAS_JQ" -eq 0) ]]; then
  echo "Error: requires either 'gh' CLI or both 'curl' and 'jq'" >&2
  exit 1
fi

# --- API helper ---
# Searches GitHub repositories API. Returns JSON array of {name, url, description, stars}.
github_search_repos() {
  local query="$1"
  local per_page="$2"

  if [[ "$HAS_GH" -eq 1 ]]; then
    gh api "search/repositories" \
      -f q="${query}" \
      -f sort=stars \
      -f order=desc \
      -F per_page="$per_page" 2>/dev/null \
    | jq -r '.items // [] | .[:'"$per_page"'] | map({
        name: .full_name,
        url: .html_url,
        description: (.description // "No description"),
        stars: .stargazers_count
      })'
  else
    local -a curl_args=(-s)
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
      curl_args+=(-H "Authorization: token ${GITHUB_TOKEN}")
    fi
    local encoded_query
    encoded_query="$(printf '%s' "$query" | jq -sRr @uri)"
    curl "${curl_args[@]}" \
      "https://api.github.com/search/repositories?q=${encoded_query}&sort=stars&order=desc&per_page=${per_page}" \
    | jq -r '.items // [] | .[:'"$per_page"'] | map({
        name: .full_name,
        url: .html_url,
        description: (.description // "No description"),
        stars: .stargazers_count
      })'
  fi
}

# Searches GitHub code API. Returns JSON array of {repo, path, url}.
github_search_code() {
  local query="$1"
  local per_page="$2"

  if [[ "$HAS_GH" -eq 1 ]]; then
    gh api "search/code" \
      -f q="${query}" \
      -F per_page="$per_page" 2>/dev/null \
    | jq -r '.items // [] | .[:'"$per_page"'] | map({
        repo: .repository.full_name,
        path: .path,
        url: .html_url,
        repo_url: .repository.html_url,
        repo_description: (.repository.description // "No description")
      })'
  else
    local -a curl_args=(-s)
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
      curl_args+=(-H "Authorization: token ${GITHUB_TOKEN}")
    fi
    local encoded_query
    encoded_query="$(printf '%s' "$query" | jq -sRr @uri)"
    curl "${curl_args[@]}" \
      "https://api.github.com/search/code?q=${encoded_query}&per_page=${per_page}" \
    | jq -r '.items // [] | .[:'"$per_page"'] | map({
        repo: .repository.full_name,
        path: .path,
        url: .html_url,
        repo_url: .repository.html_url,
        repo_description: (.repository.description // "No description")
      })'
  fi
}

# --- Collect results ---
echo "Searching GitHub for external Claude Code ideas..." >&2
echo "Timestamp: ${TIMESTAMP}" >&2

# Temporary files for aggregation
TMPDIR_WORK="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_WORK"' EXIT

REPO_RESULTS="${TMPDIR_WORK}/repos.json"
CODE_RESULTS="${TMPDIR_WORK}/code.json"
echo '[]' > "$REPO_RESULTS"
echo '[]' > "$CODE_RESULTS"

error_count=0

for entry in "${SEARCH_QUERIES[@]}"; do
  query="${entry%%|*}"
  tag="${entry##*|}"

  echo "  Searching repos: '${query}' [${tag}]..." >&2

  repo_json="$(github_search_repos "$query" "$MAX_RESULTS" 2>/dev/null || echo '[]')"
  if [[ "$repo_json" == "[]" || -z "$repo_json" ]]; then
    echo "    Warning: no repo results for '${query}'" >&2
    error_count=$((error_count + 1))
  else
    # Add tag to each result and merge
    tagged="$(echo "$repo_json" | jq --arg tag "$tag" --arg q "$query" \
      'map(. + {tag: $tag, query: $q})')"
    merged="$(jq -s '.[0] + .[1]' "$REPO_RESULTS" <(echo "$tagged"))"
    echo "$merged" > "$REPO_RESULTS"
  fi

  # Code search — look for CLAUDE.md files with relevant content
  if [[ "$query" == *"CLAUDE.md"* ]]; then
    echo "  Searching code: '${query}' [${tag}]..." >&2
    code_json="$(github_search_code "filename:CLAUDE.md ${query}" "$MAX_RESULTS" 2>/dev/null || echo '[]')"
    if [[ "$code_json" != "[]" && -n "$code_json" ]]; then
      tagged="$(echo "$code_json" | jq --arg tag "$tag" --arg q "$query" \
        'map(. + {tag: $tag, query: $q})')"
      merged="$(jq -s '.[0] + .[1]' "$CODE_RESULTS" <(echo "$tagged"))"
      echo "$merged" > "$CODE_RESULTS"
    fi
  fi

  # Rate limit: GitHub unauthenticated = 10 req/min
  sleep 6
done

# --- Deduplicate repos by name ---
deduped_repos="$(jq -r '
  group_by(.name) |
  map(
    .[0] + {
      tags: (map(.tag) | unique | join(", ")),
      queries: (map(.query) | unique | join("; "))
    }
  ) |
  sort_by(-.stars)
' "$REPO_RESULTS")"

deduped_code="$(jq -r '
  group_by(.url) |
  map(
    .[0] + {
      tags: (map(.tag) | unique | join(", "))
    }
  )
' "$CODE_RESULTS")"

repo_count="$(echo "$deduped_repos" | jq 'length')"
code_count="$(echo "$deduped_code" | jq 'length')"
echo "" >&2
echo "Found ${repo_count} unique repos and ${code_count} unique code results." >&2

# --- Load existing ideas for novelty comparison ---
FEATURE_IDEAS_FILE="${REPO_ROOT}/docs/working/feature-ideas.md"
existing_ideas=""
if [[ -f "$FEATURE_IDEAS_FILE" ]]; then
  # Extract idea titles (bold text after numbered list items)
  existing_ideas="$(grep -oP '\*\*[^*]+\*\*' "$FEATURE_IDEAS_FILE" | tr '[:upper:]' '[:lower:]' || true)"
fi

# --- Generate output ---
generate_output() {
  cat <<HEADER
# External Ideas Candidates

**Generated:** ${TIMESTAMP}
**Search method:** GitHub API (repos + code search)
**Queries:** $(printf '%s' "${SEARCH_QUERIES[*]}" | sed 's/|[^ ]* */ /g; s/  */ /g')
**Status:** AWAITING HUMAN REVIEW

> **Instructions:** Review each candidate below. Mark items as:
> - \`[NOVEL]\` — Not in our backlog, worth investigating
> - \`[KNOWN]\` — Already covered by existing ideas/features
> - \`[SKIP]\` — Not relevant or low quality
>
> After review, move \`[NOVEL]\` items to the feature ideas backlog.

---

## Hypothesis Tracking

This output supports evaluation of hypothesis **H-EXT-01**:
> Running the external ideas search script will surface at least 2 ideas
> not already in the repo's ideas backlog or prior feature-ideas documents,
> reducing the insularity of the idea generation process.

**Evaluation criteria:**
- Count items marked \`[NOVEL]\` after human review
- Compare against docs/working/feature-ideas.md (${DATE_SHORT} snapshot)
- Hypothesis confirmed if novel_count >= 2

| Metric | Value |
|--------|-------|
| Total candidates | $((repo_count + code_count)) |
| Unique repos | ${repo_count} |
| Code results | ${code_count} |
| Search errors | ${error_count} |
| Novel ideas (fill after review) | ___ |

---

## Repository Candidates

Repos matching Claude Code workflow/skill patterns, sorted by stars.

HEADER

  # Repo table
  echo "| # | Repository | Stars | Description | Relevance Tag | Review |"
  echo "|---|-----------|-------|-------------|---------------|--------|"

  echo "$deduped_repos" | jq -r '
    to_entries[] |
    "\(.key + 1) | [\(.value.name)](\(.value.url)) | \(.value.stars) | \(.value.description | gsub("[|]"; "/") | .[0:80]) | `\(.value.tags)` | [ ]"
  ' | while IFS= read -r line; do
    echo "| ${line} |"
  done

  if [[ "$code_count" -gt 0 ]]; then
    cat <<'CODE_HEADER'

---

## CLAUDE.md / Code Pattern Candidates

Specific files found containing Claude Code configuration patterns.

CODE_HEADER

    echo "| # | Repository | File | Description | Tag | Review |"
    echo "|---|-----------|------|-------------|-----|--------|"

    echo "$deduped_code" | jq -r '
      to_entries[] |
      "\(.key + 1) | [\(.value.repo)](\(.value.repo_url)) | [\(.value.path)](\(.value.url)) | \(.value.repo_description | gsub("[|]"; "/") | .[0:60]) | `\(.value.tags)` | [ ]"
    ' | while IFS= read -r line; do
      echo "| ${line} |"
    done
  fi

  cat <<'CURATION'

---

## Human Curation Checklist

After reviewing the tables above:

- [ ] Mark each row with `[NOVEL]`, `[KNOWN]`, or `[SKIP]` in the Review column
- [ ] For `[NOVEL]` items, briefly note what idea they suggest
- [ ] Update the "Novel ideas" count in the Hypothesis Tracking table
- [ ] If novel_count >= 2, mark H-EXT-01 as SUPPORTED in hypothesis-backlog.md
- [ ] Move confirmed novel ideas to docs/working/feature-ideas.md or hypothesis-backlog.md

---

## Existing Ideas Reference

Ideas already in our backlog (for quick cross-reference during review):

CURATION

  if [[ -n "$existing_ideas" ]]; then
    echo "$existing_ideas" | while IFS= read -r idea; do
      echo "- ${idea}"
    done
  else
    echo "_Could not load existing ideas from feature-ideas.md_"
  fi
}

# --- Write output ---
if [[ "$DRY_RUN" -eq 1 ]]; then
  generate_output
else
  mkdir -p "$(dirname "$OUTPUT_FILE")"
  generate_output > "$OUTPUT_FILE"
  echo "" >&2
  echo "Output written to: ${OUTPUT_FILE}" >&2
  echo "Next step: review the candidates and mark [NOVEL], [KNOWN], or [SKIP]." >&2
fi
