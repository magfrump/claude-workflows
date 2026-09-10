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
# Behavior:
#   - not a `git commit`, no enforcement file staged, trailer present → exit 0
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
if printf '%s' "$cmd" | grep -Eq -- '(^|[[:space:]])(-a|--all|-[a-zA-Z]*a[a-zA-Z]*)([[:space:]]|$)'; then
  files="$files"$'\n'"$(git diff --name-only 2>/dev/null)"
fi

# The enforcement set: what cc-isolated.sh's enforcement_files() hashes, as repo
# paths. Keep in step with that function.
enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|egress/)'
touched="$(printf '%s\n' "$files" | grep -E "$enforcement" | sort -u)"
[ -n "$touched" ] || exit 0

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
