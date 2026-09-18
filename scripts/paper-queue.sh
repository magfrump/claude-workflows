#!/usr/bin/env bash
# Queue papers whose full text the container cannot fetch, for host-side retrieval.
#
# Why this exists: inside a `cc-isolated --profile scholar` session the SNI proxy
# admits the metadata APIs and the open-access hosts (arXiv, PMC, Europe PMC,
# bioRxiv/medRxiv, OpenReview) and rejects everything else by exact name. So
# Unpaywall happily returns a "free" PDF URL on sciencedirect.com, a university
# repository, or a publisher CDN, and the fetch dies at the proxy. Widening the
# allowlist is not the answer — proxies, CAPTCHA interstitials and inconsistent
# paywalls mean the next host always disappoints too, and each addition is a
# permanent hole in the boundary for one paper. The queue converts that silent
# dead end into a list a human can act on: the session records the identifier and
# keeps going, the human fetches the PDF on the host, drops it in `papers/`, and
# marks it done. The boundary stays exactly where it was.
#
# Usage:
#   scripts/paper-queue.sh add <identifier> [note...]   queue a paper (DOI, URL or arXiv id)
#   scripts/paper-queue.sh list                         print the open requests
#   scripts/paper-queue.sh done <identifier>            mark a request fulfilled
#   scripts/paper-queue.sh status                       counts, and which open requests have a file
#
# The queue is a TSV at `papers/requests.tsv` under the current project
# (override with $PAPER_QUEUE). `add` is idempotent on the identifier.
# `status` looks for a file whose name starts with the identifier's slug in the
# same directory, so a human's drop-off is detected without any bookkeeping.

set -euo pipefail

# Byte-oriented text handling throughout. The container has no usable UTF-8
# locale (`locale` errors on LC_CTYPE), and under a broken locale grep treats a
# file containing any invalid multi-byte sequence as binary and returns nothing
# at all — not a zero count, no output — so every grep-based assertion over such
# a file passes vacuously. LC_ALL=C plus `grep -a` makes that impossible, and
# keeps identifier slugging a byte operation rather than a locale-dependent one.
export LC_ALL=C

HEADER=$'date\tstatus\tidentifier\thost\tnote'

resolve_queue() {
    if [[ -n "${PAPER_QUEUE:-}" ]]; then
        printf '%s\n' "$PAPER_QUEUE"
        return
    fi
    local root
    root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    printf '%s\n' "$root/papers/requests.tsv"
}

QUEUE="$(resolve_queue)"
PAPERS_DIR="$(dirname "$QUEUE")"

usage() {
    # Reprint the usage block from this file's own header, so there is one copy.
    grep -a -A 10 '^# Usage:' "${BASH_SOURCE[0]}" | grep -a '^#' | sed 's/^# \{0,1\}//'
}

# --- Field hygiene --------------------------------------------------------
# A tab or a newline inside a field would split the row and silently corrupt
# every later read. Escape both to two-character forms (and backslash first, so
# the escaping is reversible); the file then always has exactly five columns and
# one row per line.
escape_field() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' | awk '
        { lines[NR] = $0 }
        END {
            out = ""
            for (i = 1; i <= NR; i++) {
                if (i > 1) out = out "\\n"
                out = out lines[i]
            }
            gsub(/\t/, "\\t", out)
            gsub(/\r/, "\\r", out)
            printf "%s", out
        }
    '
}

# Host out of a URL identifier; empty for a DOI or a bare arXiv id.
parse_host() {
    local id="$1"
    case "$id" in
        http://*|https://*)
            id="${id#*://}"
            id="${id%%/*}"
            id="${id%%\?*}"
            id="${id##*@}"   # strip userinfo
            id="${id%%:*}"   # strip port
            printf '%s' "$id"
            ;;
        *) printf '' ;;
    esac
}

# Filename-safe slug for an identifier, used to detect a dropped-in PDF.
slugify() {
    # shellcheck disable=SC2018,SC2019  # ASCII ranges are the intent: the slug has
    # to be a filename a human can retype, and under LC_ALL=C [:upper:]/[:lower:]
    # are the same ASCII ranges anyway.
    printf '%s' "$1" \
        | tr 'A-Z' 'a-z' \
        | sed -e 's#^[a-z]*://##' \
              -e 's/[^a-z0-9._-]\{1,\}/-/g' \
              -e 's/^-\{1,\}//' -e 's/-\{1,\}$//'
}

ensure_queue() {
    mkdir -p "$PAPERS_DIR"
    if [[ ! -f "$QUEUE" ]]; then
        printf '%s\n' "$HEADER" > "$QUEUE"
    fi
}

# Emit data rows (header dropped). No-op when the queue does not exist yet.
rows() {
    [[ -f "$QUEUE" ]] || return 0
    tail -n +2 "$QUEUE"
}

# Split one TSV row into R_DATE/R_STATUS/R_ID/R_HOST/R_NOTE.
#
# `IFS=$'\t' read` is NOT usable here: tab is IFS *whitespace*, so bash collapses
# runs of it and an empty host column silently shifts the note left by one field.
# Splitting by hand keeps empty columns empty. Fields never contain a literal tab
# (escape_field guarantees it), so the prefix/suffix trims are exact.
split_row() {
    local line="$1"
    R_DATE="${line%%$'\t'*}";   line="${line#*$'\t'}"
    R_STATUS="${line%%$'\t'*}"; line="${line#*$'\t'}"
    R_ID="${line%%$'\t'*}";     line="${line#*$'\t'}"
    R_HOST="${line%%$'\t'*}";   line="${line#*$'\t'}"
    R_NOTE="$line"
}

find_row() {
    local want="$1" line
    while IFS= read -r line; do
        split_row "$line"
        [[ "$R_ID" == "$want" ]] || continue
        printf '%s\n' "$line"
    done < <(rows)
}

# A file whose name starts with the slug, in the queue's directory.
dropped_file() {
    local slug="$1" f
    for f in "$PAPERS_DIR/$slug"*; do
        [[ -e "$f" ]] || continue
        [[ "$f" == "$QUEUE" ]] && continue
        [[ -f "$f" ]] || continue
        printf '%s' "$(basename "$f")"
        return 0
    done
    return 1
}

cmd_add() {
    local raw="${1:-}"
    shift || true
    if [[ -z "$raw" ]]; then
        echo "paper-queue: add needs an identifier (DOI, URL or arXiv id)" >&2
        exit 1
    fi
    local identifier note host
    identifier="$(escape_field "$raw")"
    note="$(escape_field "${*:-}")"
    host="$(parse_host "$raw")"

    ensure_queue

    if [[ -n "$(find_row "$identifier")" ]]; then
        echo "already queued: $identifier"
        exit 0
    fi

    printf '%s\t%s\t%s\t%s\t%s\n' "$(date +%Y-%m-%d)" open "$identifier" "$host" "$note" >> "$QUEUE"
    echo "queued: $identifier"
}

cmd_list() {
    local any=false line
    while IFS= read -r line; do
        split_row "$line"
        [[ "$R_STATUS" == "open" ]] || continue
        any=true
        printf '%s  %s' "$R_DATE" "$R_ID"
        [[ -n "$R_HOST" ]] && printf '  [%s]' "$R_HOST"
        [[ -n "$R_NOTE" ]] && printf '  — %s' "$R_NOTE"
        printf '\n'
    done < <(rows)
    $any || echo "no open requests"
}

cmd_done() {
    local raw="${1:-}"
    if [[ -z "$raw" ]]; then
        echo "paper-queue: done needs an identifier" >&2
        exit 1
    fi
    local identifier
    identifier="$(escape_field "$raw")"

    if [[ ! -f "$QUEUE" ]] || [[ -z "$(find_row "$identifier")" ]]; then
        echo "not queued: $identifier"
        exit 0
    fi

    # The identifier travels in the environment, not in `-v`: awk expands escape
    # sequences in a -v assignment, so an escaped identifier like `id\twith\ttab`
    # would arrive at awk containing real tabs and never match its own row.
    PQ_WANT="$identifier" awk -F'\t' -v OFS='\t' '
        NR == 1 { print; next }
        $3 == ENVIRON["PQ_WANT"] { $2 = "fulfilled" }
        { print }
    ' "$QUEUE" > "$QUEUE.tmp"
    mv "$QUEUE.tmp" "$QUEUE"
    echo "fulfilled: $identifier"
}

cmd_status() {
    local open=0 fulfilled=0 line slug file
    local -a arrived=()
    while IFS= read -r line; do
        split_row "$line"
        case "$R_STATUS" in
            open)
                open=$((open + 1))
                slug="$(slugify "$R_ID")"
                if [[ -n "$slug" ]] && file="$(dropped_file "$slug")"; then
                    arrived+=("$R_ID"$'\t'"$file")
                fi
                ;;
            fulfilled) fulfilled=$((fulfilled + 1)) ;;
        esac
    done < <(rows)

    echo "queue: $QUEUE"
    echo "open: $open"
    echo "fulfilled: $fulfilled"
    if [[ ${#arrived[@]} -gt 0 ]]; then
        echo "files present for open requests:"
        local entry
        for entry in "${arrived[@]}"; do
            printf '  %s  ->  %s\n' "${entry%%$'\t'*}" "${entry##*$'\t'}"
        done
        echo "run: paper-queue.sh done <identifier>"
    fi
}

case "${1:-}" in
    add)    shift; cmd_add "$@" ;;
    list)   cmd_list ;;
    done)   shift; cmd_done "$@" ;;
    status) cmd_status ;;
    *)      usage; exit 1 ;;
esac
