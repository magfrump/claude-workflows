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
# Routes: ROUTES below is the one list (check, the sort order, the route
# tables `init` writes and `migrate` all read it). Four are the owner's
# (decision 040): you: judgment, you: walkthrough, you: terminal, you: fyi
# (answered `seen`). The others live elsewhere (ROUTE_HOME): `agent` in
# docs/roadmap.md, watches (`deferred`, `trigger`) in docs/working/watching.md,
# same grammar, closed ones (ANSWERED) under its `## Closed`. `check` refuses
# them in questions.md; `migrate` moves them out losslessly.
#
# Usage:
#   ~/.claude/scripts/questions.sh check      validate both files (exit 1 on problems)
#   ~/.claude/scripts/questions.sh index      regenerate the index tables in place
#   ~/.claude/scripts/questions.sh archive    move ANSWERED entries to the archive, reindex
#   ~/.claude/scripts/questions.sh next-id    print the next free Q-NNN
#   ~/.claude/scripts/questions.sh open       list open questions, one per line (ID, route, slug)
#   ~/.claude/scripts/questions.sh migrate    move agent/deferred/trigger entries out of questions.md
#   ~/.claude/scripts/questions.sh init       create empty live/archive/watching files if absent
#   (In claude-workflows, scripts/questions.sh is the same file.)
#
# Which files: the docs/working/ of the git repo you run it FROM (the toplevel
# of $PWD; $PWD itself outside a git repo), not of the repo the script lives
# in. Installed as ~/.claude/scripts/questions.sh, it serves every project;
# run from this repo, it resolves to this repo's docs/working/ as before.
# QUESTIONS_LIVE / QUESTIONS_ARCHIVE override either path; the watching file
# is QUESTIONS_WATCHING, else watching.md beside the live file. A missing
# watching file reads as empty (it holds no entry to check); `init` creates it.
#
# Every command except `init` needs both files to exist and fails, pointing at
# `init`, when they don't: a project without a questions doc is the normal case
# now that the script runs in every repo, and reporting "Q-001" or "0 archived"
# there would be a success claim about files that were never read.
#
# Writes never go through a symlinked questions file or docs/working/ dir,
# and, for the default paths, never land outside the git toplevel (an
# ancestor symlink such as a symlinked docs/ is caught by that check, not by
# the per-file one). Explicit QUESTIONS_LIVE/ARCHIVE paths get only the
# symlink checks. Because the script runs inside arbitrary
# cloned repos, docs/working/ and its files are attacker-authored input: a
# planted symlink would otherwise turn `archive`, `index` or `init` into an
# append/overwrite/create of any file the user can write (security review
# 2026-09-21, finding 2). See assert_write_target.

set -euo pipefail

# Byte-oriented text handling throughout. The container has no usable UTF-8
# locale (`locale` errors on LC_CTYPE), and under a broken locale grep treats a
# file containing any invalid multi-byte sequence as binary and returns nothing
# at all — not a zero count, no output. Every grep-based assertion over such a
# file then passes vacuously. LC_ALL=C plus `grep -a` makes that impossible;
# `check` additionally verifies UTF-8 validity so a corrupt file is loud.
export LC_ALL=C

# Resolve from the caller's project, not from the script's own location: the
# script is installed once (~/.claude/scripts, via link-claude-home.sh or the
# README symlink) and used from every project, and resolving next to itself sent
# every project's questions into claude-workflows' own doc (Q-025).
# The command name every message tells the user to run. The canonical spelling
# is the installed path, the one the global instructions use.
# shellcheck disable=SC2088  # a display string, deliberately not expanded
QS_CMD='~/.claude/scripts/questions.sh'

die() { echo "  ✗ questions.sh: $*" >&2; exit 1; }

# Inside .git/ there is no toplevel, so the $PWD fallback below would create
# .git/docs/working/ — a questions doc nobody would ever find.
if [[ "$(git -C "$PWD" rev-parse --is-inside-git-dir 2>/dev/null || true)" == "true" ]]; then
    die "\$PWD ($PWD) is inside a .git directory; run from the working tree instead"
fi

PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd)"
LIVE="${QUESTIONS_LIVE:-$PROJECT_ROOT/docs/working/questions.md}"
ARCHIVE="${QUESTIONS_ARCHIVE:-$PROJECT_ROOT/docs/working/questions-archive.md}"
WATCHING="${QUESTIONS_WATCHING:-$(dirname "$LIVE")/watching.md}"
# Agent entries `migrate` leaves for the roadmap's owner (the dev cycle's layout).
LISTING="$(dirname "$LIVE")/roadmap-from-questions.md"
# Derived from an overridden live path, these are the operator's choice too.
WATCHING_OVERRIDE="${QUESTIONS_WATCHING:-${QUESTIONS_LIVE:-}}"

# --- Refuse a write destination that is, or resolves through, a symlink ---
# Checked for the file itself (-L is true for a dangling link too, which -e
# misses — that gap is how `init` used to create files at a link's target) and
# for its directory. A default path must also resolve inside $PROJECT_ROOT,
# which catches a symlinked ancestor such as docs/ -> /elsewhere. An explicit
# QUESTIONS_LIVE/QUESTIONS_ARCHIVE is the operator's choice, so it is exempt
# from the containment check but not from the symlink check.
assert_write_target() {
    local file="$1" overridden="$2" dir root resolved
    dir="$(dirname "$file")"
    [[ -L "$file" ]] && die "refusing to write: $file is a symlink"
    [[ -L "$dir" ]] && die "refusing to write: directory $dir is a symlink"
    if [[ -z "$overridden" ]]; then
        root="$(realpath -m -- "$PROJECT_ROOT")"
        resolved="$(realpath -m -- "$file")"
        [[ "$resolved" == "$root"/* ]] \
            || die "refusing to write: $file resolves to $resolved, outside $root"
    fi
    return 0
}

assert_write_targets() {
    assert_write_target "$LIVE" "${QUESTIONS_LIVE:-}"
    assert_write_target "$ARCHIVE" "${QUESTIONS_ARCHIVE:-}"
    assert_write_target "$WATCHING" "$WATCHING_OVERRIDE"
}

# --- Atomically replace $target with the output of "$@" ---
# The temp file comes from mktemp in the target's own directory (O_EXCL, so a
# pre-planted name cannot redirect it — unlike the fixed `questions.md.tmp`
# this replaced), takes the target's mode, and is renamed over the target only
# after the symlink checks pass again immediately before the rename.
replace_with() {
    local target="$1" tmp; shift
    tmp="$(mktemp "$(dirname "$target")/.questions.XXXXXX")"
    if ! "$@" > "$tmp"; then rm -f "$tmp"; return 1; fi
    chmod --reference="$target" "$tmp" 2>/dev/null || true
    if [[ -L "$target" || -L "$(dirname "$target")" ]]; then
        rm -f "$tmp"; die "refusing to write: $target became a symlink"
    fi
    mv -f -- "$tmp" "$target"
}

# Every command but `init` reads both files; missing ones mean the project has
# no questions doc, which is an error to report, not an empty result.
require_files() {
    local missing=0 file
    for file in "$LIVE" "$ARCHIVE"; do
        [[ -f "$file" ]] || { echo "  ✗ missing: $file" >&2; missing=1; }
    done
    [[ $missing -eq 0 ]] || die "no questions doc here — run \`$QS_CMD init\` first"
}

INDEX_START='<!-- index:start -->'
INDEX_END='<!-- index:end -->'

# --- The routes, in sort order: what an entry costs the owner, most first ---
# One list (repo S3): VALID_ROUTES, route_rank and init's route table are all
# derived from it, so a route added here is accepted, sorted and documented
# together. ROUTE_MEANING is the table's text, one line per route, same order.
# Alphabetical order would put `deferred` and `trigger`, which cost the owner
# nothing, above their asks; walkthrough ranks above terminal because it takes
# the owner's time and attention, where a terminal entry is one batched paste.
ROUTES=('you: judgment' 'you: walkthrough' 'you: terminal' 'you: fyi' 'agent' 'deferred' 'trigger')
# shellcheck disable=SC2016  # literal backticks: markdown code spans, not commands
ROUTE_MEANING=(
    'Needs your taste or authority: a decision only you can make.'
    'Needs your hands on the product: a walkthrough or playtest only you can do.'
    'Needs your machine, not your mind: a command to run, collected into one paste.'
    'A quick read to acknowledge, not decide. Answer `seen`; an agent records a batched answer one entry at a time.'
    'Agent work, not yours: an item for the project'"'"'s roadmap.'
    'Waiting on an event that has not happened.'
    'A condition being watched, not a question yet.'
)
# Each route's home outside questions.md, same order; empty for an owner route.
WATCH_HOME='docs/working/watching.md'
ROUTE_HOME=('' '' '' '' 'docs/roadmap.md' "$WATCH_HOME" "$WATCH_HOME")
VALID_ROUTES="$(IFS='|'; echo "${ROUTES[*]}")"
# A length mismatch would make `init` die mid-write and leave a partial file
# that a re-run then keeps ("= exists"), so it is refused before any command.
(( ${#ROUTES[@]} == ${#ROUTE_MEANING[@]} )) || die "ROUTES and ROUTE_MEANING differ in length"
(( ${#ROUTES[@]} == ${#ROUTE_HOME[@]} )) || die "ROUTES and ROUTE_HOME differ in length"

# A non-owner entry in questions.md opened before this date only warns; from
# it on, it is refused. Older entries exist that only the owner may move, and
# refusing them would turn the health check red at the merge. Backdating
# Opened: evades it, a deliberate act this does not defend against
# (docs/working/research-2026-10-29-questions-watching-file.md).
LEGACY_BEFORE='2026-10-30'

# route_home ROUTE: its ROUTE_HOME (empty for an owner or unknown route).
route_home() {
    local i
    for i in "${!ROUTES[@]}"; do
        [[ "${ROUTES[i]}" == "$1" ]] && { printf '%s' "${ROUTE_HOME[i]}"; return 0; }
    done
}

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
# Rank ascending = costs the user most first: the position in ROUTES. An
# unknown route sorts last (rank 99); `check` reports it.
route_rank() {
    awk -F'\t' -v routes="$VALID_ROUTES" '
        BEGIN { n = split(routes, x, "|"); for (i = 1; i <= n; i++) r[x[i]] = i }
        { printf "%02d\t%s\n", (($2 in r) ? r[$2] : 99), $0 }
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

# --- Emit "ID<TAB>1" for each entry under a `## Closed` heading, else "ID<TAB>0" ---
entry_sections() {
    awk '
        /^## / && !/^### / { closed = ($0 ~ /^## Closed[[:space:]]*$/) }
        /^### Q-[0-9]+ / {
            line = $0; sub(/^### /, "", line); split(line, parts, " · ")
            print parts[1] "\t" (closed ? 1 : 0)
        }
    ' "$1"
}

cmd_check() {
    local rc=0 file seen_ids="" id route opened status slug home
    local -a files=("$LIVE" "$ARCHIVE")
    local -A closed=()
    # The watching file is optional (no file, no entry to check); present but
    # not a plain file, it is reported like a missing questions file.
    if [[ -e "$WATCHING" || -L "$WATCHING" ]]; then
        files+=("$WATCHING")
        [[ -f "$WATCHING" ]] && while IFS=$'\t' read -r id home; do closed[$id]="$home"; done < <(entry_sections "$WATCHING")
    fi

    for file in "${files[@]}"; do
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
                echo "  ⚠ $id is ANSWERED but still in questions.md — run: $QS_CMD archive" >&2
            fi
            if [[ "$file" == "$ARCHIVE" && "$status" == "OPEN" ]]; then
                echo "  ✗ $id is OPEN but lives in the archive" >&2; rc=1
            fi
            home="$(route_home "$route")"
            if [[ "$file" == "$LIVE" && -n "$home" ]]; then
                if [[ "$opened" < "$LEGACY_BEFORE" ]]; then
                    echo "  ⚠ $id: route '$route' belongs in $home, not questions.md (opened before $LEGACY_BEFORE, so not refused) — run: $QS_CMD migrate" >&2
                else
                    echo "  ✗ $id: route '$route' is refused in questions.md; it belongs in $home — run: $QS_CMD migrate" >&2; rc=1
                fi
            fi
            if [[ "$file" == "$WATCHING" ]]; then
                if [[ "$home" != "$WATCH_HOME" ]]; then
                    echo "  ✗ $id: route '$route' does not belong in watching.md (only deferred and trigger watches do)" >&2; rc=1
                fi
                if [[ "${closed[$id]:-0}" == 1 && "$status" == "OPEN" ]]; then
                    echo "  ✗ $id is OPEN but sits under watching.md's ## Closed" >&2; rc=1
                elif [[ "${closed[$id]:-0}" == 0 && "$status" == "ANSWERED" ]]; then
                    echo "  ✗ $id is ANSWERED (closed) but sits above watching.md's ## Closed" >&2; rc=1
                fi
            fi
        done < <(parse_entries "$file")
    done

    # An index that disagrees with the entries is worse than no index, because
    # it is read instead of the entries.
    for file in "${files[@]}"; do
        [[ -f "$file" ]] || continue
        local want_ids have_ids
        want_ids="$(parse_entries "$file" | cut -f1 | sort)"
        # First column only: a summary may itself mention another entry's ID.
        have_ids="$(sed -n "/$INDEX_START/,/$INDEX_END/p" "$file" | grep -ao '^| \[Q-[0-9]\{3\}\]' | grep -ao 'Q-[0-9]\{3\}' | sort -u || true)"
        if [[ "$want_ids" != "$have_ids" ]]; then
            echo "  ✗ $(basename "$file"): index is stale — run: $QS_CMD index" >&2
            rc=1
        fi
    done

    if [[ ! -f "$LIVE" || ! -f "$ARCHIVE" ]]; then
        echo "  ✗ no questions doc here — run \`$QS_CMD init\` first" >&2
    fi
    [[ $rc -eq 0 ]] && echo "  ✓ questions: structure valid, indexes current"
    return $rc
}

# --- Regenerate the index table between the markers, in place ---
render_index() {
    local file="$1" kind="$2" tmp
    [[ -f "$file" ]] || return 0
    grep -aqF "$INDEX_START" "$file" || { echo "  ✗ $(basename "$file"): no $INDEX_START marker" >&2; return 1; }

    # The table is scratch data awk reads back, never renamed anywhere, so the
    # system temp dir is fine for it; the file rewrite goes via replace_with.
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

    replace_with "$file" awk -v start="$INDEX_START" -v end="$INDEX_END" -v tbl="$tmp" '
        index($0, start) { print; while ((getline l < tbl) > 0) print l; skip = 1; next }
        index($0, end)   { skip = 0 }
        !skip
    ' "$file" || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
}

cmd_index() {
    require_files
    assert_write_targets
    render_index "$LIVE" live
    render_index "$ARCHIVE" archive
    render_index "$WATCHING" live
    echo "  ✓ indexes regenerated"
}

# Archive plus one entry, blank-line terminated — the new archive content.
archive_with_entry() {
    cat -- "$ARCHIVE"
    extract_entry "$LIVE" "$1"
    echo
}

live_without_entry() {
    awk -v want="$1" '
        /^### Q-[0-9]+ / {
            line = $0; sub(/^### /, "", line)
            split(line, parts, " · ")
            dropping = (parts[1] == want)
        }
        /^## / && !/^### / { dropping = 0 }
        !dropping
    ' "$LIVE"
}

cmd_archive() {
    local moved=0 id status
    require_files
    assert_write_targets
    while IFS=$'\t' read -r id _ _ status _ _; do
        [[ "$status" == "ANSWERED" ]] || continue

        # Append to the archive before removing from the live file, so an
        # interrupted run duplicates an entry (which `check` reports) rather
        # than losing one.
        # Both writes rebuild the file and rename it into place rather than
        # appending with >>, which would follow a symlink.
        replace_with "$ARCHIVE" archive_with_entry "$id"
        replace_with "$LIVE" live_without_entry "$id"

        moved=$((moved + 1))
        echo "  → archived $id"
    done < <(parse_entries "$LIVE")

    cmd_index
    echo "  ✓ archived $moved entr$([[ $moved -eq 1 ]] && echo y || echo ies)"
}

cmd_next_id() {
    local max
    require_files
    max="$( { parse_entries "$LIVE"; parse_entries "$ARCHIVE"; parse_entries "$WATCHING"; } \
        | cut -f1 | sed 's/^Q-//' | sort -n | tail -1 )"
    # 10# forces base 10: IDs are zero-padded, and bash reads a leading zero as
    # octal, so a bare $((021 + 1)) yields 18 rather than 22 — and silently,
    # which would hand out an ID that is already in use.
    printf 'Q-%03d\n' $(( 10#${max:-0} + 1 ))
}

# --- migrate: move every non-owner entry out of questions.md, losing no text ---
# Destinations are written first, as in `archive`: an interrupted run
# duplicates an entry (`check` reports it) rather than losing one.

# entry_text ID: the entry from the live file, trailing blank lines dropped.
entry_text() {
    extract_entry "$LIVE" "$1" | awk 'NF { while (gap-- > 0) print ""; gap = 0; print; next } { gap++ }'
}

# watching_with_entry ENTRYFILE CLOSED: the watching file with the entry
# inserted at the end of its `## Open` section (CLOSED=0) or at the end of the
# file, under `## Closed` (CLOSED=1; the heading is added if absent).
watching_with_entry() {
    awk -v entry="$1" -v want_closed="$2" '
        function emit(   l) {
            if (prev != "") print ""
            while ((getline l < entry) > 0) print l
            print ""; done = 1; prev = ""
        }
        !want_closed && !done && /^## Closed[[:space:]]*$/ { emit() }
        /^## Closed[[:space:]]*$/ { have_closed = 1 }
        { print; prev = $0 }
        END {
            if (done) exit
            if (want_closed && !have_closed) { if (prev != "") print ""; print "## Closed"; prev = "" }
            emit()
        }
    ' "$WATCHING"
}

listing_with_entry() {
    cat -- "$LISTING"
    cat -- "$1"
    echo
}

cmd_migrate() {
    local moved=0 id route status home entry
    require_files
    assert_write_targets
    assert_write_target "$LISTING" "${QUESTIONS_LIVE:-}"
    entry="$(mktemp)"; MIGRATE_TMP="$entry"
    trap 'rm -f -- "$MIGRATE_TMP"' EXIT
    while IFS=$'\t' read -r id route _ status _ _; do
        home="$(route_home "$route")"
        [[ -n "$home" ]] || continue
        entry_text "$id" > "$entry"
        if [[ "$home" == "$WATCH_HOME" ]]; then
            [[ -e "$WATCHING" ]] || cmd_init > /dev/null
            replace_with "$WATCHING" watching_with_entry "$entry" "$([[ "$status" == ANSWERED ]] && echo 1 || echo 0)"
        else
            if [[ ! -e "$LISTING" ]]; then
                ( set -o noclobber
                  printf '# Agent work moved out of questions.md\n\n%s\n%s\n\n' \
                      "Written by \`$QS_CMD migrate\`. The roadmap's owner folds each entry into" \
                      'docs/roadmap.md (it keeps its Q-ID as a reference), then deletes this file.' > "$LISTING" ) \
                    || die "could not create $LISTING"
            fi
            replace_with "$LISTING" listing_with_entry "$entry"
        fi
        replace_with "$LIVE" live_without_entry "$id"
        moved=$((moved + 1))
        echo "  → moved $id ($route) to $([[ "$home" == "$WATCH_HOME" ]] && echo "$WATCHING" || echo "$LISTING")"
    done < <(parse_entries "$LIVE")

    cmd_index
    echo "  ✓ migrated $moved entr$([[ $moved -eq 1 ]] && echo y || echo ies)"
    if [[ -e "$LISTING" ]]; then
        echo "  ! agent work waits in $LISTING: fold it into docs/roadmap.md, then delete it"
    fi
}

cmd_open() {
    require_files
    parse_entries "$LIVE" | route_rank | sort -t$'\t' -k1,1 -k2,2 | cut -f2- \
        | while IFS=$'\t' read -r id route _ _ slug _; do
            # 16 fits the longest route, `you: walkthrough`; dev-cycle.sh
            # splits this output on runs of two or more spaces.
            printf '%s  %-16s  %s\n' "$id" "$route" "$slug"
        done
}

# The text above `## Index`: how to answer, and the route table, written from
# ROUTES/ROUTE_HOME so the table and `check` cannot disagree. The live file's
# table lists the owner routes and names where the others live; the watching
# file's lists the routes whose home it is.
# shellcheck disable=SC2016  # literal backticks: markdown code spans, not commands
live_preamble() {
    local i away=""
    printf '%s\n' \
        'Questions for you, raised during autonomous work.' '' \
        '**To answer:** write `Q-NNN: <your answer>` anywhere (a reply, a file, a commit).' \
        'The ID is the whole handle. Answered entries move to `questions-archive.md`.' '' \
        '**Needs** is the route: who or what discharges the entry.' '' \
        '| Route | Meaning |' '|---|---|'
    for i in "${!ROUTES[@]}"; do
        if [[ -z "${ROUTE_HOME[i]}" ]]; then
            printf '| `%s` | %s |\n' "${ROUTES[i]}" "${ROUTE_MEANING[i]}"
        else
            away="$away${away:+, }\`${ROUTES[i]}\` (${ROUTE_HOME[i]})"
        fi
    done
    printf '\nNot in this file: %s. `check` refuses them here; `migrate` moves them out.\n' "$away"
    printf '\n%s\n%s\n\n' "Maintained by \`$QS_CMD\` (\`check\` · \`index\` · \`archive\` · \`migrate\` · \`next-id\` · \`open\`)." \
        'The index below is generated: edit entries, not the table.'
}

# shellcheck disable=SC2016  # literal backticks: markdown code spans, not commands
watching_preamble() {
    local i
    printf '%s\n' \
        'Watches the agents own and close: conditions and events being waited on, moved' \
        'out of `questions.md` (decision 040). Same entry grammar; a closed watch gets' \
        'Status ANSWERED and moves under `## Closed`.' '' \
        '| Route | Meaning |' '|---|---|'
    for i in "${!ROUTES[@]}"; do
        [[ "${ROUTE_HOME[i]}" == "$WATCH_HOME" ]] && printf '| `%s` | %s |\n' "${ROUTES[i]}" "${ROUTE_MEANING[i]}"
    done
    printf '\n%s\n\n' "Maintained by \`$QS_CMD\` (\`check\` · \`index\` · \`migrate\`); the index below is generated."
}

# Create whichever of the three files is missing, with the index markers the
# other commands need, so a project that has never had a questions doc can
# start one without copying this repo's. Never touches a file that exists.
cmd_init() {
    local file title section override
    # Before mkdir -p too: a symlinked docs/ would otherwise make mkdir create
    # directories at the link's target.
    assert_write_targets
    for file in "$LIVE" "$ARCHIVE" "$WATCHING"; do
        [[ -e "$file" ]] && { echo "  = exists: $file"; continue; }
        case "$file" in
            "$LIVE")    title="Running questions"; section="Open"; override="${QUESTIONS_LIVE:-}" ;;
            "$ARCHIVE") title="Running questions — archive"; section="Answered"; override="${QUESTIONS_ARCHIVE:-}" ;;
            *)          title="Watching"; section=$'Open\n\n## Closed'; override="$WATCHING_OVERRIDE" ;;
        esac
        mkdir -p "$(dirname "$file")"
        # Re-check now the directory exists, then create with noclobber, whose
        # O_EXCL open fails rather than following anything that appeared at the
        # path in between.
        assert_write_target "$file" "$override"
        # shellcheck disable=SC2094  # the preambles read no file; only the arrays
        ( set -o noclobber
          { printf '# %s\n\n' "$title"
            [[ "$file" == "$LIVE" ]] && live_preamble
            [[ "$file" == "$WATCHING" ]] && watching_preamble
            printf '## Index\n\n%s\n%s\n\n## %s\n' "$INDEX_START" "$INDEX_END" "$section"
          } > "$file" ) \
            || die "could not create $file"
        echo "  + created: $file"
    done
}

case "${1:-}" in
    init)    cmd_init ;;
    check)   cmd_check ;;
    index)   cmd_index ;;
    archive) cmd_archive ;;
    migrate) cmd_migrate ;;
    next-id) cmd_next_id ;;
    open)    cmd_open ;;
    *)
        sed -n '/^# Usage:/,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
        exit 1
        ;;
esac
