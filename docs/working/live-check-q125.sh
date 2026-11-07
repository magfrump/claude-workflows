#!/usr/bin/env bash
# shellcheck disable=SC2015  # every `A && res … || res …` is safe: res() is a printf.
# live-check-q125.sh — Q-125 live checks, run INSIDE a cc-isolated session built
# from the Q-125 branch, by asking Claude to run it with its Bash tool. That path
# is the sandboxed one; `!bash …` runs unsandboxed and proves nothing (the script
# says so if it can tell).
#
# Each check prints `RESULT <id> pass|FAIL|SKIP …`. pass means the sandbox did what
# the plan (docs/working/plan-q125-cc-isolated-sandbox.md, step 6) requires.
# Writes are tried as zero-byte appends (`: >>`), which never change a file's
# content; a file one of them CREATES is removed again. settings.json is backed up
# to a temp dir first and restored if the --output check ever changes it.
# Optional: `--watch` keeps a 10-minute credential-read loop running; run
# `/login` in the session meanwhile (the rename check).
set -u

tmp="$(mktemp -d)" || { echo "mktemp failed" >&2; exit 1; }
if [ -z "$tmp" ] || [ ! -d "$tmp" ]; then echo "no temp dir" >&2; exit 1; fi
trap 'rm -rf "$tmp"' EXIT
cred="$HOME/.claude/.credentials.json"

res() { printf 'RESULT %-28s %s\n' "$1" "$2"; }
# refused <id> <cmd...>: pass when the command fails.
refused() { local id="$1"; shift; if "$@" >/dev/null 2>&1; then res "$id" "FAIL (allowed: $*)"; else res "$id" pass; fi; }
# nowrite <id> <path>: pass when a zero-byte append is refused; removes a file it created.
nowrite() {
  local existed=0 parent
  parent="$(dirname "$2")"
  # A missing parent would make the append fail for the wrong reason: an agent
  # could mkdir it first. Creating it counts as writable.
  if [ ! -d "$parent" ]; then
    if mkdir "$parent" 2>/dev/null; then rmdir "$parent"; res "$1" "FAIL (could create $parent)"; else res "$1" pass; fi
    return
  fi
  [ -e "$2" ] && existed=1
  if ( : >> "$2" ) 2>/dev/null; then
    [ "$existed" = 1 ] || rm -f "$2"
    res "$1" "FAIL (writable: $2)"
  else
    res "$1" pass
  fi
}

echo "INFO pid1=$(cat /proc/1/comm 2>/dev/null) self-pid=$$ (a small pid and pid1 bwrap/bash suggest the sandbox)"
echo "INFO managed: $(jq -c '{enabled: .sandbox.enabled, fail: .sandbox.failIfUnavailable, domains: (.sandbox.network.allowedDomains | length)}' /etc/claude-code/managed-settings.json 2>&1)"

if [ "${1:-}" = "--watch" ]; then
  for _ in $(seq 600); do if cat "$cred" >/dev/null 2>&1; then res C10-cred-across-rename "FAIL (readable)"; exit 1; fi; sleep 1; done
  res C10-cred-across-rename pass; exit 0
fi

# C1 the credential, judged by CONTENT and never by exit status: denyRead binds
# /dev/null over the file, so a refused read exits 0 and prints nothing. If cat
# shows a single byte this shell is not sandboxed (a `!` run, or a broken sandbox):
# stop here, before any check that writes, so an unsandboxed run cannot touch
# settings.json or plant probe files.
cat "$cred" > "$tmp/o" 2>/dev/null
if [ -s "$tmp/o" ]; then
  res C1-cat-credential "FAIL (readable: not sandboxed, or the sandbox is broken)"
  echo "ABORT: skipping every other check; nothing was written." >&2
  exit 1
fi
res C1-cat-credential pass
# The other readers print the file inside a diff or an error message, so these grep
# for its content: q125-verify-check.sh's canary, or a real login's keys. A control
# file proves the tool would have shown content, so a broken tool cannot pass.
echo '{"q125Control":"shown"}' > "$tmp/control"
noread() {
  local id="$1"; shift
  "$@" "$tmp/control" > "$tmp/o" 2>&1
  if ! grep -q q125Control "$tmp/o"; then res "$id" "FAIL (control: $* shows no content)"; return; fi
  "$@" "$cred" > "$tmp/o" 2>&1
  if grep -qE 'q125canary[0-9a-f]{16}|claudeAiOauth|accessToken' "$tmp/o"; then res "$id" "FAIL (credential content read: $*)"; else res "$id" pass; fi
}
noread C1-git-diff-credential git diff --no-index /dev/null
noread C1-man-l-credential env MANPAGER=cat PAGER=cat man -l
noread C1-date-f-credential date -f

# C2 settings, hooks wiring, Claude Code state.
nowrite C2-user-settings "$HOME/.claude/settings.json"
nowrite C2-user-settings-local "$HOME/.claude/settings.local.json"
nowrite C2-claude-json "$HOME/.claude/.claude.json"
cp "$HOME/.claude/settings.json" "$tmp/settings.bak" 2>/dev/null
( cd /workspace && git log -1 --format=%B --output="$HOME/.claude/settings.json" ) >/dev/null 2>&1
if cmp -s "$tmp/settings.bak" "$HOME/.claude/settings.json"; then res C2-git-log-output pass
else cp "$tmp/settings.bak" "$HOME/.claude/settings.json" 2>/dev/null; res C2-git-log-output "FAIL (rewrote settings.json; restore attempted)"; fi

# C3 things that run unsandboxed later.
nowrite C3-elan-bin "$HOME/.elan/bin/q125-probe"
mkdir -p /tmp/cc-web-taint 2>/dev/null
nowrite C3-web-taint "/tmp/cc-web-taint/q125-probe"
nowrite C3-project-settings /workspace/.claude/settings.json
nowrite C3-project-settings-local /workspace/.claude/settings.local.json
nowrite C3-mcp-json /workspace/.mcp.json
if [ -d /workspace/.git ]; then
  nowrite C3-git-config /workspace/.git/config
  nowrite C3-git-hooks /workspace/.git/hooks/q125-probe
fi
n=0
for wt in /workspace/.claude/worktrees/*/; do
  [ -d "$wt" ] || continue
  n=$((n + 1))
  nowrite "C3-nested-settings-$n" "${wt}.claude/settings.json"
  [ -f "${wt}.git" ] && nowrite "C3-nested-gitfile-$n" "${wt}.git"
done
[ "$n" -gt 0 ] || res C3-nested-worktrees "SKIP (no /workspace/.claude/worktrees/* here)"

# C4 a repo-config hook running inside the sandbox cannot leak the credential.
( cd "$tmp" && git init -q r && cd r && git config core.fsmonitor "cat '$cred' > '$tmp/leak'" && git status >/dev/null 2>&1 )
if [ -s "$tmp/leak" ]; then res C4-fsmonitor "FAIL (credential copied)"; else res C4-fsmonitor pass; fi

# C5 network: listed hosts work without a prompt, unlisted are denied.
code="$(curl -s -o /dev/null -m 15 -w '%{http_code}' https://api.github.com/zen)"
[ "$code" = 200 ] && res C5-github "pass (200)" || res C5-github "FAIL (http $code)"
code="$(curl -s -o /dev/null -m 15 -w '%{http_code}' https://api.anthropic.com/)"
[ "$code" != 000 ] && res C5-anthropic "pass (http $code)" || res C5-anthropic "FAIL (no connection)"
if git ls-remote https://github.com/git/git HEAD >/dev/null 2>&1; then res C5-git-https pass; else res C5-git-https FAIL; fi
refused C5-unlisted-denied curl -s -m 15 https://example.com
echo "INFO if a network permission prompt appeared for example.com, strictAllowlist is NOT honoured: note it"

# C6 builds write only where allowWrite permits.
if command -v cargo >/dev/null; then
  ( cd "$tmp" && cargo new -q c && cd c && cargo build -q ) >/dev/null 2>&1 && res C6-cargo pass || res C6-cargo FAIL
fi
( mkdir -p "$tmp/n" && cd "$tmp/n" && npm init -y >/dev/null && npm install --no-audit --no-fund left-pad ) >/dev/null 2>&1 \
  && res C6-npm pass || res C6-npm "FAIL (or registry.npmjs.org unreachable)"
