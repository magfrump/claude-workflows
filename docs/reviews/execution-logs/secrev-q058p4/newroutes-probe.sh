#!/usr/bin/env bash
# Security review pass 4 (2026-09-25; copied unchanged from pass 3 except the
# regex source and the log's first lines)
# Security review pass 3 (2026-09-25): does any command-running route into
# install.sh's git calls survive the P2-R1 fix (repo_git flags + git_state_gate)
# at 516124d? Every git call here uses install.sh's exact repo_git flags:
#   git --no-optional-locks -C <repo> -c core.hooksPath=/dev/null -c core.fsmonitor=false
# plus --ignore-submodules=all on the two status calls, as assemble() runs them.
# Hermetic: temp HOME, empty global git config, no system config; all state in a
# mktemp dir under $TMPDIR. Writes newroutes-probe.log next to this script.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P="$(mktemp -d "${TMPDIR:-/tmp}/newroutes.XXXXXX")"
export HOME="$P/home" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$P/empty"
mkdir -p "$HOME"; : > "$GIT_CONFIG_GLOBAL"
INSTALL_SH=/workspace/.claude/wt-q058p2/devcontainer-config/install.sh
# Pass 4: the regex is read from install.sh at f5e3029, not hard-coded.
GIT_EXEC_KEYS_RE="$(sed -n "s/^GIT_EXEC_KEYS_RE='\\(.*\\)'$/\\1/p" "$INSTALL_SH")"

G() { git -c user.email=t@t -c user.name=t "$@"; }
# repo_git as install.sh defines it (install.sh:169-171)
R() { local r="$1"; shift; git --no-optional-locks -C "$r" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"; }
plant() { printf '#!/bin/sh\necho %s >> "%s/marks"\ncat >/dev/null 2>&1\nexit 0\n' "$1" "$P" > "$P/$1.sh"; chmod +x "$P/$1.sh"; }
marks() { if [ -s "$P/marks" ]; then tr '\n' ' ' < "$P/marks"; else printf none; fi; echo; : > "$P/marks"; }

mkrepo() {   # a repo with skills/a.txt committed, at $1
  git init -q "$1"; mkdir -p "$1/skills"; echo committed-a > "$1/skills/a.txt"
  G -C "$1" add -A; G -C "$1" commit -qm i
}
# The two status calls assemble() makes (install.sh:333-334), stat-dirtying first.
status_calls() {
  local r="$1"; sleep 1; touch "$r/skills/a.txt"
  R "$r" -c core.quotePath=true status --porcelain --untracked-files=all --ignore-submodules=all -- skills >/dev/null
  R "$r" -c core.quotePath=true status --porcelain --untracked-files=all --ignore-submodules=all -- skills >/dev/null
}

{
  git --version; echo "GIT_EXEC_KEYS_RE=$GIT_EXEC_KEYS_RE"; echo

  echo "== 1. config-based hooks: hook.<event>.command (git >= 2.36) =="
  mkrepo "$P/r1"; : > "$P/marks"
  git -C "$P/r1" config hook.post-index-change.command "$P/h1.sh" 2>/dev/null || echo "(config set failed)"
  plant h1
  git -C "$P/r1" config hook.post-index-change.command "$P/h1.sh" >/dev/null 2>&1
  status_calls "$P/r1"
  echo "hook.*.command marks: $(marks)"
  echo "git_state_gate would see in .git/config: '$(git config --file "$P/r1/.git/config" --no-includes --get-regexp "$GIT_EXEC_KEYS_RE" || true)'"
  echo

  echo "== 2. .git is a gitfile pointing elsewhere (planted GIT dir with a hook) =="
  mkrepo "$P/r2real"
  # A writer replaces .git with a file pointing at an attacker-arranged git dir.
  cp -a "$P/r2real" "$P/r2"
  realgit="$P/r2/.git"
  plant gf
  printf '#!/bin/sh\necho gitfile-hook-ran >> "%s/marks"\n' "$P" > "$realgit/hooks/post-index-change"
  chmod +x "$realgit/hooks/post-index-change"
  # Point a sibling worktree checkout at it through a .git file.
  mkdir -p "$P/r2b/skills"; cp "$P/r2/skills/a.txt" "$P/r2b/skills/a.txt"
  printf 'gitdir: %s\n' "$realgit" > "$P/r2b/.git"
  echo "core.hooksPath=/dev/null defends .git/hooks; does the gitfile route change that?"
  status_calls "$P/r2b"
  echo "gitfile hook marks: $(marks)"
  echo

  echo "== 3. GIT_DIR / GIT_* environment variables in the user's shell =="
  # install.sh does not unset GIT_* ; a value inherited from the terminal could
  # redirect where -C looks. repo_git relies on -C, not on a clean environment.
  mkrepo "$P/r3"
  plant ge
  printf '#!/bin/sh\necho gitdir-env-hook >> "%s/marks"\n' "$P" > "$P/r3/.git/hooks/post-index-change"
  chmod +x "$P/r3/.git/hooks/post-index-change"
  echo "3a. GIT_DIR set, core.hooksPath flag present:"
  ( export GIT_DIR="$P/r3/.git" GIT_WORK_TREE="$P/r3"; status_calls "$P/r3" )
  echo "   marks: $(marks)"
  echo "3b. does -c core.hooksPath=/dev/null override an env GIT_CONFIG?"
  # GIT_CONFIG only affects `git config`, not the running repo; note only.
  echo

  echo "== 4. safe.directory (repo owned by another uid) =="
  # If the checkout trips safe.directory, git refuses; install.sh would error,
  # not exec. This is a DoS/usability note, not an exec route. Recorded for scope.
  mkrepo "$P/r4"
  R "$P/r4" rev-parse --verify -q 'HEAD^{commit}' >/dev/null && echo "rev-parse ok (same uid, no safe.directory trip)"
  echo

  echo "== 5. archive attributes: export-subst / export-ignore via committed .gitattributes =="
  # A committed .gitattributes needs no .git write. export-subst substitutes
  # \$Format:...\$ placeholders (data, not exec). Confirm no command runs.
  mkrepo "$P/r5"
  printf 'skills/a.txt export-subst\n' > "$P/r5/.gitattributes"
  # shellcheck disable=SC2016  # literal git export-subst placeholder
  printf 'id=$Format:%%H$\n' > "$P/r5/skills/a.txt"
  G -C "$P/r5" add -A; G -C "$P/r5" commit -qm attrs
  : > "$P/marks"
  R "$P/r5" -c tar.umask=022 archive --format=tar HEAD -- skills | tar -tf - >/dev/null
  echo "archive export-subst marks: $(marks)"
  echo "git_state_gate sees attributes? committed .gitattributes is NOT info/attributes:"
  echo "  info/attributes present: $([ -s "$P/r5/.git/info/attributes" ] && echo yes || echo 'no (empty/absent)')"
  echo

  echo "== 6. git_state_gate config read: does its own 'git config --file' honour anything? =="
  mkrepo "$P/r6"
  git -C "$P/r6" config include.path "$P/evil.inc"
  printf '[core]\n\tfsmonitor = %s/should-not-run.sh\n' "$P" > "$P/evil.inc"
  plant should-not-run
  out="$(git --no-pager -c core.hooksPath=/dev/null config --file "$P/r6/.git/config" --no-includes --get-regexp "$GIT_EXEC_KEYS_RE" || true)"
  echo "gate --no-includes output (should list include.path, NOT follow it): '$out'"
  status_calls "$P/r6" 2>/dev/null
  echo "should-not-run marks: $(marks)"
} > "$here/newroutes-probe.log" 2>&1
find "$P" -mindepth 0 -maxdepth 0 -type d >/dev/null
cat "$here/newroutes-probe.log"
