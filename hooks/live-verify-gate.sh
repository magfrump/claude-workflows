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
# file under devcontainer-config/ (the ones the trust manifest hashes), the commit
# message must carry a `Live-verified:` trailer. The value is free text on
# purpose — `Live-verified: 3f2a9c0e1b7d4a6f` (the blessed hash `cc-isolated --list`
# shows after a passing probe) or `Live-verified: no — <why, and what will run it>`.
# The gate does not judge the answer; it refuses a commit that leaves the question
# unasked, which is exactly how the debt accrued. `git log --grep 'Live-verified: no'`
# then lists the outstanding debt.
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
#   - not a `git commit`, no enforcement file staged, trailer present → exit 0
#   - enforcement file staged, its diff touches only comment/blank lines → exit 0
#   - enforcement file staged, no trailer                              → exit 2 (blocks;
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
files="$(git diff --cached --name-only 2>/dev/null)" || exit 0
commit_all=0
if printf '%s' "$cmd" | grep -Eq -- '(^|[[:space:]])(-a|--all|-[a-zA-Z]*a[a-zA-Z]*)([[:space:]]|$)'; then
  commit_all=1
  files="$files"$'\n'"$(git diff --name-only 2>/dev/null)"
fi

# The enforcement set: what cc-isolated.sh's enforcement_files() hashes, as repo
# paths. Keep in step with that function.
enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|egress/)'
touched="$(printf '%s\n' "$files" | grep -E "$enforcement" | sort -u)"
[ -n "$touched" ] || exit 0

# The comment-only escape (Q-009). Read the same diff the commit would carry —
# the index, plus the worktree when -a/--all widened `files` above — restricted
# to the enforcement files, and let it through only if every added and removed
# line is blank or a comment. `#` covers the Dockerfile, the shell scripts, the
# python and the egress/*.txt lists; `//` covers the jsonc devcontainer.json.
comment_only_diff() {
  local diff_text line body stripped content=0 touched_files=()
  mapfile -t touched_files <<< "$touched"
  [ "${#touched_files[@]}" -gt 0 ] || return 1

  diff_text="$(git diff --cached -U0 --no-color -- "${touched_files[@]}" 2>/dev/null)" || return 1
  if [ "$commit_all" = "1" ]; then
    diff_text="$diff_text"$'\n'"$(git diff -U0 --no-color -- "${touched_files[@]}" 2>/dev/null)"
  fi

  # A rename, a mode change, an added or deleted enforcement file, or a binary
  # blob is substantive whatever its text says — the file's presence, path or
  # permissions are themselves part of the boundary. Keep gating.
  grep -Eq '^(new file mode|deleted file mode|old mode|new mode|rename from|similarity index|Binary files)' <<< "$diff_text" && return 1

  while IFS= read -r line; do
    case "$line" in
      '+++'*|'---'*) continue ;;   # file headers, not content
      '+'*|'-'*) ;;
      *) continue ;;               # @@, `diff --git`, `index`, context
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

if comment_only_diff; then exit 0; fi

has_trailer() {
  grep -Eq "(^|[[:space:]\"'])Live-verified:" <<< "$1"
}

if has_trailer "$cmd"; then exit 0; fi

# -F <file> / --file <file> / --file=<file>: read the message file(s).
while read -r f; do
  [ -n "$f" ] || continue
  f="${f%\"}"; f="${f#\"}"; f="${f%\'}"; f="${f#\'}"
  if [ -r "$f" ] && has_trailer "$(cat "$f")"; then exit 0; fi
done < <(printf '%s' "$cmd" | grep -Eo -- '(-F|--file)(=|[[:space:]]+)[^[:space:]]+' | sed -E 's/^(-F|--file)(=|[[:space:]]+)//')

{
  echo "BLOCKED: this commit changes the cc-isolated boundary but says nothing about live verification."
  echo "Enforcement files in the commit:"
  printf '  %s\n' "$touched"
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
exit 2
