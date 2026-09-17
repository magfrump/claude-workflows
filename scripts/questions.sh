#!/bin/bash
# Maintain the running-questions documents: docs/working/questions.md (live,
# open questions only) and docs/working/questions-archive.md (answered).
#
# Why a script and not a convention: this repo's own evidence is that an
# unenforced instruction does not execute — docs/thoughts/failure-patterns.md
# holds 0 entries against 104 eligible fix commits, and the code-review override
# log went unwritten for nine runs, both because only prose asked for them.
# An index that must be hand-maintained would drift the same way. Here `index`
# regenerates it, `archive` keeps the live file compact, and `check` fails the
# health check when structure breaks, so the drift is caught rather than trusted.
#
# Entry grammar (enforced by `check`):
#
#     ### Q-NNN · <slug>
#     **Needs:** <route> · **Opened:** YYYY-MM-DD · **Status:** OPEN|ANSWERED
#
#     <question, then the decision card's bullets>
#
# Routes are the triage routes from docs/working/triage-2026-09-17-backlog.md:
#   you: judgment   needs taste, authority, or a preference only the user holds
#   you: terminal   needs the user's machine, not their mind — batched into a paste
#   agent           mechanical; no judgment needed
#   trigger         not a question yet; an unmet condition being watched
#   deferred        scheduled behind an event that has not happened
#
# Usage:
#   scripts/questions.sh check      validate both files (exit 1 on problems)
#   scripts/questions.sh index      regenerate the index tables in place
#   scripts/questions.sh archive    move ANSWERED entries to the archive, reindex
#   scripts/questions.sh next-id    print the next free Q-NNN
#   scripts/questions.sh open       list open questions, one per line (ID, route, slug)

set -euo pipefail

# Byte-oriented text handling throughout. The container has no usable UTF-8
# locale (`locale` errors on LC_CTYPE), and under a broken locale grep treats a
# file containing any invalid multi-byte sequence as binary and returns nothing
# at all — not a zero count, no output. Every grep-based assertion over such a
# file then passes vacuously. LC_ALL=C plus `grep -a` makes that impossible;
# `check` additionally verifies UTF-8 validity so a corrupt file is loud.
export LC_ALL=C

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIVE="${QUESTIONS_LIVE:-$REPO_ROOT/docs/working/questions.md}"
ARCHIVE="${QUESTIONS_ARCHIVE:-$REPO_ROOT/docs/working/questions-archive.md}"

INDEX_START='<!-- index:start -->'
INDEX_END='<!-- index:end -->'

VALID_ROUTES='you: judgment|you: terminal|agent|trigger|deferred'

# --- Emit "ID<TAB>route<TAB>date<TAB>status<TAB>slug<TAB>summary" per entry ---
# summary is the first non-empty prose line after the header pair, truncated.
# Parsing is line-oriented on purpose: the grammar is two fixed lines, so no
# markdown parser is needed and a malformed entry surfaces as a missing field
# rather than as silently skipped output.
parse_entries() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    awk '
        function flush() {
            if (id != "") {
                printf "%s\t%s\t%s\t%s\t%s\t%s\n", id, route, opened, status, slug, summary
            }
            id = ""; route = ""; opened = ""; status = ""; slug = ""; summary = ""
            want_summary = 0
        }
        /^### Q-[0-9]+ / {
            flush()
            line = $0
            sub(/^### /, "", line)
            split(line, parts, " · ")
            id = parts[1]
            slug = parts[2]
            want_summary = 1
            next
        }
        /^\*\*Needs:\*\*/ {
            if (id == "") next
            line = $0
            gsub(/\*\*/, "", line)
            n = split(line, f, " · ")
            for (i = 1; i <= n; i++) {
                if (f[i] ~ /^Needs:/)  { route  = substr(f[i], 8) }
                if (f[i] ~ /^Opened:/) { opened = substr(f[i], 9) }
                if (f[i] ~ /^Status:/) { status = substr(f[i], 9) }
            }
            next
        }
        # First prose line after the header pair becomes the index summary.
        want_summary && status != "" && /[^[:space:]]/ && !/^\*\*/ && !/^###/ && !/^</ {
            summary = $0
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", summary)
            if (length(summary) > 110) {
                summary = substr(summary, 1, 107)
                # substr is byte-oriented here (the container has no usable
                # UTF-8 locale), so a cut can land inside a multi-byte
                # character. Left in place that writes invalid UTF-8 to the
                # index, which makes grep treat the whole file as binary and
                # silently return nothing — i.e. it turns `check` into a
                # vacuous assertion. Drop any trailing sequence that could be
                # incomplete; the cost is at most one visible character before
                # the ellipsis.
                sub(/[\302-\364][\200-\277]*$/, "", summary)
                summary = summary "..."
            }
            want_summary = 0
            next
        }
        END { flush() }
    ' "$file"
}

# --- Prefix each parsed line with a sort rank for its route ---
# Rank ascending = costs the user most first. Keep in step with VALID_ROUTES.
route_rank() {
    awk -F'\t' '
        BEGIN {
            r["you: judgment"] = 1; r["you: terminal"] = 2; r["agent"] = 3
            r["deferred"] = 4; r["trigger"] = 5
        }
        { printf "%d\t%s\n", (($2 in r) ? r[$2] : 9), $0 }
    '
}

# --- Extract one entry's full text (header through the line before the next) ---
extract_entry() {
    local file="$1" want="$2"
    awk -v want="$want" '
        /^### Q-[0-9]+ / {
            line = $0; sub(/^### /, "", line)
            split(line, parts, " · ")
            inside = (parts[1] == want)
        }
        /^## / && !/^### / { inside = 0 }
        inside { print }
    ' "$file"
}

cmd_check() {
    local rc=0 file seen_ids="" id route opened status slug

    for file in "$LIVE" "$ARCHIVE"; do
        [[ -f "$file" ]] || { echo "  ✗ missing: $file" >&2; rc=1; continue; }

        # Precondition for every other assertion below. An invalid byte makes
        # grep report the file as binary and emit nothing, so without this the
        # rest of `check` would pass on a corrupt file rather than fail on it.
        if ! python3 -c 'import sys; open(sys.argv[1],"rb").read().decode("utf-8")' "$file" 2>/dev/null; then
            echo "  ✗ $(basename "$file"): not valid UTF-8 — later checks cannot be trusted" >&2
            rc=1
        fi

        # A heading that looks like an entry but does not match the grammar is
        # the failure this catches: it would vanish from the index silently.
        while IFS= read -r line; do
            if [[ ! "$line" =~ ^\#\#\#\ Q-[0-9]{3}\ ·\ [a-z0-9-]+$ ]]; then
                echo "  ✗ $(basename "$file"): malformed entry heading: $line" >&2
                rc=1
            fi
        done < <(grep -a '^### Q-' "$file" || true)

        while IFS=$'\t' read -r id route opened status slug _; do
            [[ -n "$id" ]] || continue
            if [[ " $seen_ids " == *" $id "* ]]; then
                echo "  ✗ duplicate id: $id" >&2; rc=1
            fi
            seen_ids="$seen_ids $id"

            if [[ ! "$route" =~ ^($VALID_ROUTES)$ ]]; then
                echo "  ✗ $id: invalid route '$route' (want one of: ${VALID_ROUTES//|/, })" >&2; rc=1
            fi
            if [[ ! "$opened" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                echo "  ✗ $id: invalid Opened date '$opened'" >&2; rc=1
            fi
            if [[ "$status" != "OPEN" && "$status" != "ANSWERED" ]]; then
                echo "  ✗ $id: invalid status '$status'" >&2; rc=1
            fi
            if [[ -z "$slug" ]]; then
                echo "  ✗ $id: missing slug" >&2; rc=1
            fi
            # The live file is for open questions; answered ones belong in the
            # archive. This is what keeps the live file compact by construction
            # rather than by anyone remembering to move things.
            if [[ "$file" == "$LIVE" && "$status" == "ANSWERED" ]]; then
                echo "  ⚠ $id is ANSWERED but still in questions.md — run: scripts/questions.sh archive" >&2
            fi
            if [[ "$file" == "$ARCHIVE" && "$status" == "OPEN" ]]; then
                echo "  ✗ $id is OPEN but lives in the archive" >&2; rc=1
            fi
        done < <(parse_entries "$file")
    done

    # An index that disagrees with the entries is worse than no index, because
    # it is read instead of the entries.
    for file in "$LIVE" "$ARCHIVE"; do
        [[ -f "$file" ]] || continue
        local want_ids have_ids
        want_ids="$(parse_entries "$file" | cut -f1 | sort)"
        have_ids="$(sed -n "/$INDEX_START/,/$INDEX_END/p" "$file" | grep -ao 'Q-[0-9]\{3\}' | sort -u || true)"
        if [[ "$want_ids" != "$have_ids" ]]; then
            echo "  ✗ $(basename "$file"): index is stale — run: scripts/questions.sh index" >&2
            rc=1
        fi
    done

    [[ $rc -eq 0 ]] && echo "  ✓ questions: structure valid, indexes current"
    return $rc
}

# --- Regenerate the index table between the markers, in place ---
render_index() {
    local file="$1" kind="$2" tmp
    [[ -f "$file" ]] || return 0
    grep -aqF "$INDEX_START" "$file" || { echo "  ✗ $(basename "$file"): no $INDEX_START marker" >&2; return 1; }

    tmp="$(mktemp)"
    {
        if [[ "$kind" == "live" ]]; then
            echo "| ID | Needs | Question | Opened |"
            echo "|---|---|---|---|"
            # Ordered by how much of the user this costs, most first, so the
            # index answers "what is mine?" in one glance. Alphabetical would
            # put `deferred` and `trigger` — the two that cost nothing — on top.
            parse_entries "$file" | route_rank | sort -t$'\t' -k1,1 -k2,2 | cut -f2- \
              | while IFS=$'\t' read -r id route opened _ slug summary; do
                printf '| [%s](#%s--%s) | %s | %s | %s |\n' \
                    "$id" "${id,,}" "$slug" "$route" "$summary" "$opened"
            done
        else
            echo "| ID | Question | Opened |"
            echo "|---|---|---|"
            parse_entries "$file" | sort -t$'\t' -k1,1 | while IFS=$'\t' read -r id _ opened _ slug summary; do
                printf '| [%s](#%s--%s) | %s | %s |\n' \
                    "$id" "${id,,}" "$slug" "$summary" "$opened"
            done
        fi
    } > "$tmp"

    awk -v start="$INDEX_START" -v end="$INDEX_END" -v tbl="$tmp" '
        index($0, start) { print; while ((getline l < tbl) > 0) print l; skip = 1; next }
        index($0, end)   { skip = 0 }
        !skip
    ' "$file" > "$tmp.out"
    mv "$tmp.out" "$file"
    rm -f "$tmp"
}

cmd_index() {
    render_index "$LIVE" live
    render_index "$ARCHIVE" archive
    echo "  ✓ indexes regenerated"
}

cmd_archive() {
    local moved=0 id status
    while IFS=$'\t' read -r id _ _ status _ _; do
        [[ "$status" == "ANSWERED" ]] || continue

        # Append to the archive before removing from the live file, so an
        # interrupted run duplicates an entry (which `check` reports) rather
        # than losing one.
        extract_entry "$LIVE" "$id" >> "$ARCHIVE"
        echo >> "$ARCHIVE"

        awk -v want="$id" '
            /^### Q-[0-9]+ / {
                line = $0; sub(/^### /, "", line)
                split(line, parts, " · ")
                dropping = (parts[1] == want)
            }
            /^## / && !/^### / { dropping = 0 }
            !dropping
        ' "$LIVE" > "$LIVE.tmp"
        mv "$LIVE.tmp" "$LIVE"

        moved=$((moved + 1))
        echo "  → archived $id"
    done < <(parse_entries "$LIVE")

    cmd_index
    echo "  ✓ archived $moved entr$([[ $moved -eq 1 ]] && echo y || echo ies)"
}

cmd_next_id() {
    local max
    max="$( { parse_entries "$LIVE"; parse_entries "$ARCHIVE"; } \
        | cut -f1 | sed 's/^Q-//' | sort -n | tail -1 )"
    # 10# forces base 10: IDs are zero-padded, and bash reads a leading zero as
    # octal, so a bare $((021 + 1)) yields 18 rather than 22 — and silently,
    # which would hand out an ID that is already in use.
    printf 'Q-%03d\n' $(( 10#${max:-0} + 1 ))
}

cmd_open() {
    parse_entries "$LIVE" | route_rank | sort -t$'\t' -k1,1 -k2,2 | cut -f2- \
        | while IFS=$'\t' read -r id route _ _ slug _; do
            printf '%s  %-14s  %s\n' "$id" "$route" "$slug"
        done
}

case "${1:-}" in
    check)   cmd_check ;;
    index)   cmd_index ;;
    archive) cmd_archive ;;
    next-id) cmd_next_id ;;
    open)    cmd_open ;;
    *)
        sed -n '/^# Usage:/,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
        exit 1
        ;;
esac
