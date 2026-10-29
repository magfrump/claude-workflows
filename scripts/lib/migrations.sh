#!/usr/bin/env bash
# Convention migrations: the one registry of changes to a convention other
# repos' files follow, read by the dev-cycle digest (section 7b) and held to
# the conventions' sources by test/scripts/convention-migrations.bats.
#
# Covered conventions (CONVENTIONS) and the source each is fingerprinted from
# (conv_source): questions, scripts/questions.sh's "Entry grammar" header
# block plus the files `questions.sh init` writes; roadmap, the template in
# skills/dev-cycle/SKILL.md step 6; brief, step 8's rules for a brief's lines;
# record, step 9's record template. A change to one of those sources changes
# its fingerprint, and the test fails until the change adds a registry line
# whose FP is the new one (guides/convention-changes.md).
#
# Registry grammar: one `mig` call per change, oldest first, added at the
# registry's end (below the "Registry" line, above the run-directly block):
#
#   mig ID CONVENTION FP PATH ERE REMEDY
#
#   ID       lowercase letters, digits and hyphens, unique.
#   FP       the convention's fingerprint after the change: 16 hex digits, as
#            `bash scripts/lib/migrations.sh fingerprint` prints it.
#   PATH     the repo file that can still hold the old shape, relative to the
#            repo root ("-" when no existing file needs changing).
#   ERE      a grep -E pattern (C locale) matching a line only the old shape
#            has ("-" with PATH "-").
#   REMEDY   the command the repo's owner runs from its root to migrate PATH,
#            then commits; with PATH "-", "none: WHY" (a baseline, or a change
#            every existing file already satisfies).
#
# The digest reports a migration as pending while PATH holds a line ERE
# matches; the dev cycle files the remedy for the owner (SKILL.md step 1b),
# because the files a migration rewrites are ones its chore commit may not.
#
# Run directly: `bash scripts/lib/migrations.sh check [ROOT]` (exit 1 naming
# each convention whose newest line's FP is not its source's, and each
# malformed line) or `fingerprint [ROOT]` (one "CONVENTION FP" line each).
# The bats merge check also holds the registry append-only against the
# default branch's copy (conv_append_only).
# ROOT defaults to the checkout holding this file.

CONVENTIONS=(questions roadmap brief record)
MIG_ID=(); MIG_CONV=(); MIG_FP=(); MIG_PATH=(); MIG_ERE=(); MIG_REMEDY=(); MIG_BAD=()
mig_reset() { MIG_ID=(); MIG_CONV=(); MIG_FP=(); MIG_PATH=(); MIG_ERE=(); MIG_REMEDY=(); MIG_BAD=(); }

# Record one registry line; a malformed one goes to MIG_BAD (the digest then
# checks nothing, and `check` fails), never into the list.
mig() {
  local id="${1:-}" c="${2:-}" fp="${3:-}" p="${4:-}" ere="${5:-}" rem="${6:-}" why="" x rc=0
  if [[ $# -ne 6 ]]; then why="takes 6 fields, not $#"
  elif [[ ! "$id" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then why="the ID is not lowercase letters, digits and hyphens"
  elif [[ " ${CONVENTIONS[*]} " != *" $c "* ]]; then why="no convention named '$c'"
  elif [[ ! "$fp" =~ ^[0-9a-f]{16}$ ]]; then why="the FP is not 16 hex digits"
  elif [[ "$rem" == *$'\n'* || -z "$rem" ]]; then why="the remedy is empty or spans lines"
  elif [[ "$p" == - ]]; then
    [[ "$ere" == - && "$rem" == "none: "?* ]] || why="with PATH '-', ERE is '-' and the remedy 'none: WHY'"
  elif [[ ! "$p" =~ ^[A-Za-z0-9._][A-Za-z0-9._/-]*$ || "/$p/" == */../* || "/$p/" == */./* || "$p" == */ || "/${p,,}/" == */.git/* ]]; then
    why="PATH is not a plain relative file path"
  elif [[ -z "$ere" || "$ere" == - || "$rem" == none:* ]]; then why="a migration needs an ERE and a command"
  else
    env LC_ALL=C grep -qE -- "$ere" </dev/null || rc=$?
    [[ $rc -le 1 ]] || why="the ERE does not compile"
  fi
  for x in "${MIG_ID[@]}"; do [[ -n "$why" || "$x" != "$id" ]] || why="the ID is used twice"; done
  if [[ -n "$why" ]]; then MIG_BAD+=("mig ${id:-?}: $why"); return 0; fi
  MIG_ID+=("$id"); MIG_CONV+=("$c"); MIG_FP+=("$fp"); MIG_PATH+=("$p"); MIG_ERE+=("$ere"); MIG_REMEDY+=("$rem")
}

# The text a convention is fingerprinted from, in checkout $2; fails, printing
# nothing it could not find, when an anchor is gone (so `check` names it).
conv_source() {
  local c="$1" r="$2" t f out
  case "$c" in
    questions)
      out="$(awk '/^# Entry grammar/ { on = 1 } on && /^# Usage:/ { e = 1; exit } on { print } END { exit !e }' "$r/scripts/questions.sh")" || return 1
      [[ -n "$out" ]] || return 1
      printf '%s\n' "$out"
      t="$(mktemp -d)" || return 1
      # init in an empty repo: the templates every project's files start from.
      if ! (cd "$t" && git init -q . && env -u QUESTIONS_LIVE -u QUESTIONS_ARCHIVE -u QUESTIONS_WATCHING \
            bash "$r/scripts/questions.sh" init >/dev/null 2>&1); then rm -rf -- "$t"; return 1; fi
      for f in "$t"/docs/working/*; do [[ -f "$f" ]] || continue; printf '== %s\n' "${f##*/}"; cat -- "$f"; done
      rm -rf -- "$t" ;;
    roadmap|record)
      [[ "$c" == roadmap ]] && f='### 6. Roadmap' || f='### 9. Record and land'
      out="$(awk -v h="$f" '$0 == h { s = 1; next } s == 1 && /^### / { exit } s == 1 && /^```markdown$/ { s = 2; next } s == 2 && /^```$/ { e = 1; exit } s == 2 { print } END { exit !e }' \
        "$r/skills/dev-cycle/SKILL.md")" || return 1
      [[ -n "$out" ]] || return 1; printf '%s\n' "$out" ;;
    brief)
      out="$(awk '/^### 8\. Build briefs$/ { s = 1; next } s && /^### / { exit } s == 1 && /^For each, write `docs\/working\/briefs\// { s = 2 } s == 2 { print } s == 2 && /line a loop.s merge changes\./ { e = 1; exit } END { exit !e }' \
        "$r/skills/dev-cycle/SKILL.md")" || return 1
      printf '%s\n' "$out" ;;
    *) return 1 ;;
  esac
}
conv_fingerprint() {  # $1 convention, $2 checkout
  local s
  s="$(conv_source "$1" "$2")" || return 1
  printf '%s\n' "$s" | sha256sum | cut -c1-16
}

# Append-only: every `mig` line of registry file $1 (the default branch's)
# is, in order, the start of $2's (this checkout's). Prints a refuse line and
# fails otherwise, so a convention change cannot pass by rewriting an old line.
conv_append_only() {
  local a b
  a="$(grep -a '^mig ' -- "$1")" || [[ $? -eq 1 ]] || { echo "refuse registry: $1 could not be read"; return 1; }
  b="$(grep -a '^mig ' -- "$2")" || [[ $? -eq 1 ]] || { echo "refuse registry: $2 could not be read"; return 1; }
  # The registry section (from its marker to the run-directly block) holds
  # mig lines and comments only, so nothing after the old lines can reset them.
  if awk '/^# Registry \(oldest first/ { on = 1; next } /^if \[\[ "\$\{BASH_SOURCE/ { on = 0 } on && NF && !/^mig / && !/^#/ { bad = 1 } END { exit bad }' "$2"; then :
  else echo "refuse registry: a line in the registry is neither a mig line nor a comment"; return 1; fi
  [[ -z "$a" || "$b" == "$a" || "$b" == "$a"$'\n'* ]] && return 0
  echo "refuse registry: a mig line the default branch has was edited, removed or moved; restore it and add a new line instead"
  return 1
}

conv_check() {  # $1 checkout; prints one "refuse" line per problem, exit 1 if any
  local r="$1" c fp last i bad=0 x
  for x in "${MIG_BAD[@]}"; do echo "refuse registry: $x"; bad=1; done
  for c in "${CONVENTIONS[@]}"; do
    if ! fp="$(conv_fingerprint "$c" "$r")"; then
      echo "refuse $c: its source was not found in $r (conv_source's anchors); fix conv_source with the move"; bad=1; continue
    fi
    last=""; for i in "${!MIG_ID[@]}"; do [[ "${MIG_CONV[$i]}" != "$c" ]] || last="${MIG_FP[$i]}"; done
    if [[ "$last" != "$fp" ]]; then
      echo "refuse $c: its source's fingerprint is $fp, its newest registry line's ${last:-none}: the convention changed, so add, in scripts/lib/migrations.sh, mig ID $c $fp PATH ERE 'COMMAND' (an existing file needs migrating) or mig ID $c $fp - - 'none: WHY' (guides/convention-changes.md)"
      bad=1
    fi
  done
  return "$bad"
}

# Registry (oldest first; never edit or remove a line, add one).
mig baseline-questions questions 0111dd8c057884c9 - - 'none: the baseline the registry starts from'
mig baseline-roadmap roadmap 09fe4c684d3695f6 - - 'none: the baseline the registry starts from'
mig baseline-brief brief 677fec67dd3bebda - - 'none: the baseline the registry starts from'
mig baseline-record record 7e93036efc09b7ba - - 'none: the baseline the registry starts from'

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -uo pipefail
  root="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
  case "${1:-}" in
    check) conv_check "$root"; exit $? ;;
    fingerprint)
      for c in "${CONVENTIONS[@]}"; do fp="$(conv_fingerprint "$c" "$root")" || fp="(source not found)"; echo "$c $fp"; done ;;
    *) echo "usage: bash scripts/lib/migrations.sh check|fingerprint [ROOT]" >&2; exit 1 ;;
  esac
fi
