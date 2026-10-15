#!/usr/bin/env bash
# PreToolUse hook (Bash): a commit that changes the cc-isolated boundary must say
# whether it was verified in a live container.
#
# WHY. Decision log #40 and #41 both shipped with "needs a live-container check
# before bless" in their commit messages, were blessed without one, and sessions
# ran with no DNS for six days while every root-run probe passed (#44). The bats
# suites stub iptables and cannot see a kernel, so four review passes re-read the
# command sequence and none could touch the assumption. Guidance alone did not
# hold; this is the mechanical part. The runtime half is the launcher's
# verified-live receipt (cc-isolated.sh, `--probe-only`).
#
# WHAT IT ENFORCES. If the files about to be committed include any enforcement
# file under devcontainer-config/ (the ones the trust manifest hashes, plus
# install.sh per decision 035), the commit
# message must carry a `Live-verified:` trailer. The value is free text on
# purpose — `Live-verified: 3f2a9c0e1b7d4a6f` (the blessed hash `cc-isolated --list`
# shows after a passing probe) or `Live-verified: no — <why, and what will run it>`.
# The gate does not judge the answer; it refuses a commit that leaves the question
# unasked, which is exactly how the debt accrued. `git log --grep 'Live-verified: no'`
# then lists the outstanding debt.
#
# HOST TOOLS (decision log row 71). cc-exit-scan.sh, cc-gitdir.sh and cc-push.sh
# run on the host and no live probe can exercise them, so they carry their own
# trailer, `Host-tool-tested:` (what ran on a host, or `no — <reason>`), and a
# `Live-verified:` trailer does not satisfy them. A commit touching both kinds
# needs both trailers. Each set gets the comment-only narrowing below on its own.
#
# NARROWING (Q-009). The gate fired on a diff that only rewrote comments: the
# admitted set was byte-identical, so no probe was possible and none would have
# said anything. So a change confined to comment and blank lines is let through.
# The rule is deliberately "no change to any NON-COMMENT line", never "no change
# to hostnames": commenting OUT a live allowlist entry deletes a non-comment
# line, changes what the container may reach, and must still be gated. Anything
# the shortcut cannot read as pure comment text — a rename, a mode change, a new
# or deleted enforcement file, a binary blob, or a diff that came back empty
# because the command failed — falls through to the gate, which is the safe
# direction.
#
# Behavior:
#   - not a `git commit`, or no enforcement file or host tool staged   → exit 0
#   - each staged set whose diff touches only comment/blank lines     → needs no trailer
#   - every remaining set carries its trailer (Live-verified: for
#     enforcement files, Host-tool-tested: for host tools)             → exit 0
#   - a remaining set lacks its trailer                                → exit 2 (blocks;
#     stderr is fed back to the model)
#   - jq/git missing, malformed input, `--amend --no-edit`             → exit 0
#
# Message sources checked: the command text itself (-m strings, heredocs) and any
# `-F <file>` / `--file=<file>` it names, read relative to the hook's cwd (the
# project directory). Disable with CC_LIVE_VERIFY_GATE_DISABLE=1.

# No `set -e`: every internal failure must fall through to exit 0.

[ "${CC_LIVE_VERIFY_GATE_DISABLE:-0}" = "1" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

input="$(cat 2>/dev/null)" || exit 0
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)" || exit 0
[ -n "$cmd" ] || exit 0

# Only `git commit` (possibly after other commands in a chain, possibly with -C/-c
# options between `git` and `commit`).
printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])git([[:space:]]+-[A-Za-z][^[:space:]]*|[[:space:]]+-C[[:space:]]+[^[:space:]]+)*[[:space:]]+commit([[:space:]]|$)' || exit 0

# An amend that keeps its message cannot be inspected here; leave it alone.
printf '%s' "$cmd" | grep -Eq -- '--amend' && printf '%s' "$cmd" | grep -Eq -- '--no-edit' && exit 0

# Files this commit would carry: the index, plus tracked modifications when -a/--all.
# --no-renames: a rename is listed as both paths, so moving a gated file to an
# ungated name is still gated (with rename detection only the destination shows).
files="$(git diff --cached --name-only --no-renames 2>/dev/null)" || exit 0
commit_all=0
if printf '%s' "$cmd" | grep -Eq -- '(^|[[:space:]])(-a|--all|-[a-zA-Z]*a[a-zA-Z]*)([[:space:]]|$)'; then
  commit_all=1
  files="$files"$'\n'"$(git diff --name-only --no-renames 2>/dev/null)"
fi

# The enforcement set: what cc-isolated.sh's enforcement_files() hashes, as repo
# paths. Keep in step with that function. Plus install.sh, which is not hashed but
# runs on the host and chooses the diff the human reviews (decision 035).
enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|install\.sh$|egress/)'
# Host-only tools: cc-isolated.sh's host_tool_files() (decision log row 71); keep in
# step with that function too (a bats test pins both lists in both directions). No
# live probe can exercise them, so they carry their own trailer, `Host-tool-tested:`
# (what was run on a host, or `no — <reason>`), and `Live-verified: no` stays a
# list of debt a probe can pay. A commit touching both kinds needs both trailers.
# Not end-anchored, like `enforcement`: a stray sibling such as cc-push.sh.orig is
# gated too (it was, while the tools sat in `enforcement`).
host_tools='^devcontainer-config/(cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh)'
boundary_touched="$(printf '%s\n' "$files" | grep -E "$enforcement" | sort -u)"
host_touched="$(printf '%s\n' "$files" | grep -E "$host_tools" | sort -u)"
touched="$(printf '%s\n%s\n' "$boundary_touched" "$host_touched" | grep -v '^$' | sort -u)"
[ -n "$touched" ] || exit 0

# The comment-only escape (Q-009). Read the same diff the commit would carry —
# the index, plus the worktree when -a/--all widened `files` above — restricted
# to one set's files (enforcement or host tools, whichever the caller passes), and
# let that set through only if every added and removed
# line is blank or a comment. `#` covers the Dockerfile, the shell scripts, the
# python and the egress/*.txt lists; `//` covers the jsonc devcontainer.json.
# $1: the newline-separated files to read (one trailer's set).
comment_only_diff() {
  local diff_text line body stripped content=0 in_header=0 touched_files=()
  mapfile -t touched_files <<< "$1"
  [ "${#touched_files[@]}" -gt 0 ] || return 1

  # --no-textconv --no-ext-diff: a repo-local diff driver (.gitattributes plus
  # diff.<x>.textconv) could otherwise render a real change as comment lines.
  diff_text="$(git diff --cached -U0 --no-color --no-textconv --no-ext-diff -- "${touched_files[@]}" 2>/dev/null)" || return 1
  if [ "$commit_all" = "1" ]; then
    diff_text="$diff_text"$'\n'"$(git diff -U0 --no-color --no-textconv --no-ext-diff -- "${touched_files[@]}" 2>/dev/null)"
  fi

  # A rename, a mode change, an added or deleted enforcement file, or a binary
  # blob is substantive whatever its text says — the file's presence, path or
  # permissions are themselves part of the boundary. Keep gating.
  grep -Eq '^(new file mode|deleted file mode|old mode|new mode|rename from|similarity index|Binary files)' <<< "$diff_text" && return 1

  while IFS= read -r line; do
    # `---`/`+++` are file headers only between `diff --git` and the first
    # `@@`; inside a hunk they are a removed `--…` or added `++…` line, and
    # skipping those let a real change (e.g. dropping a `--flag` line) pass as
    # comment-only whenever a comment was edited alongside it.
    case "$line" in
      'diff --git '*) in_header=1; continue ;;
      '@@'*) in_header=0; continue ;;
    esac
    if [ "$in_header" = 1 ]; then
      continue                     # `index`, `---`, `+++` file headers
    fi
    case "$line" in
      '+'*|'-'*) ;;
      *) continue ;;               # context
    esac
    content=1
    body="${line#?}"
    stripped="${body#"${body%%[![:space:]]*}"}"
    case "$stripped" in
      '') continue ;;              # blank or whitespace-only
      '#'*|'//'*) continue ;;      # comment
    esac
    return 1                       # a real line changed
  done <<< "$diff_text"

  # No +/- content at all means the diff was empty or the command failed. Never
  # let that read as "comment-only"; fall through to the gate.
  [ "$content" = 1 ]
}

# Each set is judged on its own diff: a comment-only edit to a host tool needs no
# trailer even when the same commit changes a boundary file, and vice versa.
need=()
if [ -n "$boundary_touched" ] && ! comment_only_diff "$boundary_touched"; then need+=("Live-verified"); fi
if [ -n "$host_touched" ] && ! comment_only_diff "$host_touched"; then need+=("Host-tool-tested"); fi
[ "${#need[@]}" -gt 0 ] || exit 0

# The message text: the command itself, plus any -F <file> / --file <file> /
# --file=<file> it names.
msg="$cmd"
while read -r f; do
  [ -n "$f" ] || continue
  f="${f%\"}"; f="${f#\"}"; f="${f%\'}"; f="${f#\'}"
  if [ -r "$f" ]; then msg="$msg"$'\n'"$(cat "$f")"; fi
done < <(printf '%s' "$cmd" | grep -Eo -- '(-F|--file)(=|[[:space:]]+)[^[:space:]]+' | sed -E 's/^(-F|--file)(=|[[:space:]]+)//')

has_trailer() {  # $1 = trailer name
  grep -Eq "(^|[[:space:]\"'])$1:" <<< "$msg"
}

missing=()
for t in "${need[@]}"; do has_trailer "$t" || missing+=("$t"); done
[ "${#missing[@]}" -gt 0 ] || exit 0

for t in "${missing[@]}"; do
  if [ "$t" = "Live-verified" ]; then
    {
      echo "BLOCKED: this commit changes the cc-isolated boundary but says nothing about live verification."
      echo "Enforcement files in the commit:"
      printf '  %s\n' "$boundary_touched"
      echo
      echo "Add a trailer to the commit message. Either the blessed hash a passing probe recorded"
      echo "(cc-isolated --list shows it after cc-isolated --probe-only <repo>):"
      echo "    Live-verified: <hash>"
      echo "or an explicit statement that it has not run, and what will run it:"
      echo "    Live-verified: no — <reason>; run cc-isolated --probe-only <repo> after install.sh"
      echo
      echo "bats and shellcheck cannot see a kernel; only a container built from this config can"
      echo "(guides/devcontainer-setup.md, 'Changing the boundary'). Two outages came from"
      echo "commits that carried 'needs a live check' and were blessed without one."
    } >&2
  else
    {
      echo "BLOCKED: this commit changes a host tool but says nothing about testing it on a host."
      echo "Host tools in the commit:"
      printf '  %s\n' "$host_touched"
      echo
      echo "Add a trailer naming what ran on a host (no live probe can exercise these):"
      echo "    Host-tool-tested: <what you ran, e.g. cc-push of a scratch repo after install.sh>"
      echo "or an explicit statement that nothing has, and what will:"
      echo "    Host-tool-tested: no — <reason>; <what will run it>"
      echo
      echo "These run on the host after or outside the container, so cc-isolated --probe-only"
      echo "cannot exercise them (guides/devcontainer-setup.md, host-tools note; decision log #71)."
      echo "git log --grep 'Host-tool-tested: no' lists the outstanding host-tool debt."
    } >&2
  fi
done
exit 2
