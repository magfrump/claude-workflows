#!/usr/bin/env bash
# code-fact-check it3 probes for 25d8f272 (Q-089 B). Creates its own probe root
# under the job tmp dir and aborts if it cannot; writes logs to $1 (the
# execution-logs dir). Every mutation runs on a copy of `git archive 25d8f272`.
set -u
OUT="$1"
[ -d "$OUT" ] || { echo "no out dir"; exit 1; }
P="$(mktemp -d /home/node/.claude/jobs/00bcf178/tmp/fc-it3.XXXXXX)" || exit 1
case "$P" in /home/node/.claude/jobs/00bcf178/tmp/fc-it3.*) ;; *) echo "bad P"; exit 1 ;; esac
[ -d "$P" ] || exit 1
cd "$P" || exit 1
mkdir -p src old home tmpd
git -C /workspace/.claude/wt-q089b archive 25d8f272 | tar -x -C src || exit 1
git -C /workspace/.claude/wt-q089b archive 79f22357 hooks/live-verify-gate.sh | tar -x -C old || exit 1
export HOME="$P/home" LC_ALL=C TMPDIR="$P/tmpd" GIT_CONFIG_NOSYSTEM=1
unset CLAUDE_DEVC_CONFIG_DIR CC_LIVE_VERIFY_GATE_DISABLE CLAUDE_CONFIG_DIR
H=hooks/live-verify-gate.sh
echo "probe root: $P"

run_suite() { # $1 name, $2 dir
  local log="$OUT/bats-$1.log"
  ( cd "$2" || exit 1
    echo "name: $1"; echo "cwd: $2"; echo "start: $(date -u +%FT%TZ)"
    echo "cmd: timeout 300 bats test/hooks/live-verify-gate.bats  (HOME=$HOME LC_ALL=C)"
    echo "hook sha256: $(sha256sum "$H" | cut -c1-16)"
    timeout 300 bats test/hooks/live-verify-gate.bats; echo "exit=$?" ) > "$log" 2>&1
  printf '%-22s total=%s notok=%s %s\n' "$1" "$(grep -c -E '^(ok|not ok)' "$log")" \
    "$(grep -c '^not ok' "$log")" "$(tail -1 "$log")"
  grep '^not ok' "$log" | sed 's/^/    /'
}
mut() { # $1 name, $2 old (literal), $3 new; optional $4 = "first" to replace once
  rm -rf "$P/mut-$1"; cp -a "$P/src" "$P/mut-$1"
  python3 -I - "$P/mut-$1/$H" "$2" "$3" "${4:-all}" <<'PY' || { echo "$1: pattern not found"; return; }
import sys
p, old, new, mode = sys.argv[1:5]
s = open(p).read()
if old not in s:
    sys.exit(1)
s = s.replace(old, new, 1) if mode == "first" else s.replace(old, new)
open(p, "w").write(s)
PY
  if cmp -s "$P/src/$H" "$P/mut-$1/$H"; then echo "$1: MUTATION DID NOT APPLY"; return; fi
  diff "$P/src/$H" "$P/mut-$1/$H" | sed "s/^/    [$1] /"
  run_suite "$1" "$P/mut-$1"
}

echo "== count: $(cd src && bats --count test/hooks/live-verify-gate.bats)"
run_suite clean "$P/src"

# Old hook (79f22357) under the new suite: which new tests the fixes alone turn green.
rm -rf "$P/oldhook"; cp -a "$P/src" "$P/oldhook"; cp "$P/old/$H" "$P/oldhook/$H"
run_suite old-hook-79f22357 "$P/oldhook"

# The regex swap the commit says still fails 2 tests (it2's M1-swap-full).
mut M1-swap "init-firewall\\.sh|cc-sni" "cc-sni"
python3 -I - "$P/mut-M1-swap/$H" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace("host_tools='^devcontainer-config/(", "host_tools='^devcontainer-config/(init-firewall\\.sh|")
open(p, "w").write(s)
PY
run_suite M1-swap-full "$P/mut-M1-swap"

# -a path without --no-renames (line 77).
mut Ma-all-renames 'files="$files"$'"'"'\n'"'"'"$(git diff --name-only --no-renames' 'files="$files"$'"'"'\n'"'"'"$(git diff --name-only'
# Both flags off the --cached diff (line 111).
mut Mb-cached-both "--cached -U0 --no-color --no-textconv --no-ext-diff" "--cached -U0 --no-color"
# Only --no-textconv off the --cached diff.
mut Mc-cached-textconv "--cached -U0 --no-color --no-textconv --no-ext-diff" "--cached -U0 --no-color --no-ext-diff"
# Only --no-ext-diff off the --cached diff.
mut Md-cached-extdiff "--cached -U0 --no-color --no-textconv --no-ext-diff" "--cached -U0 --no-color --no-textconv"
# Both flags off the -a worktree diff (line 113).
mut Me-all-both '$(git diff -U0 --no-color --no-textconv --no-ext-diff' '$(git diff -U0 --no-color'
# The `$` anchor back on host_tools.
mut Mf-endanchor "cc-push\\.sh)'" "cc-push\\.sh)\$'"
# install.sh moved from the enforcement regex to host_tools.
mut Mg-install-host "install\\.sh\$|" ""
python3 -I - "$P/mut-Mg-install-host/$H" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace("host_tools='^devcontainer-config/(", "host_tools='^devcontainer-config/(install\\.sh$|")
open(p, "w").write(s)
PY
run_suite Mg-install-host-full "$P/mut-Mg-install-host"

# Direct probes: external diff driver and -a textconv, real hook vs mutants.
pl() { jq -n -c --arg c "$1" '{"tool_name":"Bash","tool_input":{"command":$c}}'; }
fresh() {
  R="$P/repo-$1"; rm -rf "$R"; mkdir -p "$R/devcontainer-config/egress"; cd "$R" || exit 1
  git init -q; git config user.email t@e; git config user.name t; git config commit.gpgsign false
  echo base > devcontainer-config/egress/base.txt
  git add -A; git commit -qm init
}
{
  echo "start: $(date -u +%FT%TZ)"
  printf '#!/bin/sh\nprintf "@@ -1 +1 @@\\n+# looks like a comment\\n"\n' > "$P/extdiff.sh"; chmod +x "$P/extdiff.sh"
  fresh x1
  echo 'devcontainer-config/egress/*.txt diff=cm' > .gitattributes
  git config diff.cm.command "$P/extdiff.sh"
  echo widened >> devcontainer-config/egress/base.txt; git add devcontainer-config/egress/base.txt
  echo "-- X1 external diff driver (diff.cm.command), staged real change, cwd $PWD"
  echo "   git diff --cached -U0 (driver active):"; git diff --cached -U0 --no-color | sed 's/^/     | /'
  for h in src mut-Md-cached-extdiff mut-Mb-cached-both; do
    timeout 20 bash "$P/$h/$H" <<< "$(pl 'git commit -m "x"')" >/dev/null 2>&1; echo "   $h: exit $?"
  done
  fresh x2
  echo 'devcontainer-config/egress/*.txt diff=cm' > .gitattributes
  git config diff.cm.textconv "sed s/^/#/"
  echo widened >> devcontainer-config/egress/base.txt   # NOT staged; -a path
  echo "-- X2 textconv driver, unstaged real change, git commit -am, cwd $PWD"
  for h in src mut-Me-all-both; do
    timeout 20 bash "$P/$h/$H" <<< "$(pl 'git commit -am "x"')" >/dev/null 2>&1; echo "   $h: exit $?"
  done
  fresh x3
  echo "-- X3 -a rename probe: name lists with and without --no-renames, cwd $PWD"
  mv devcontainer-config/egress/base.txt devcontainer-config/base-moved.txt
  git add -N devcontainer-config/base-moved.txt
  echo "   git diff --name-only:"; git diff --name-only | sed 's/^/     | /'
  echo "   git diff --name-only --no-renames:"; git diff --name-only --no-renames | sed 's/^/     | /'
  echo "   git diff --cached --name-only --no-renames:"; git diff --cached --name-only --no-renames | sed 's/^/     | /'
  echo "end: $(date -u +%FT%TZ)"
} > "$OUT/direct-probes.log" 2>&1
cd "$P" || exit 1

# Gate 6's lint flags over every .sh in the scoped diff, and the one
# disable directive's effect.
{
  echo "start: $(date -u +%FT%TZ) cwd: $P/src $(shellcheck --version | grep ^version)"
  echo "cmd: timeout 60 shellcheck -x -e SC1091 -s bash -S warning <f>"
  cd "$P/src" || exit 1
  for f in $(git -C /workspace/.claude/wt-q089b diff --name-only 79f22357 25d8f272 | grep -E '\.(sh|bash|bats)$'); do
    timeout 60 shellcheck -x -e SC1091 -s bash -S warning "$f" > "$P/tmpd/sc.out" 2>&1; rc=$?
    echo "$f exit=$rc"; sed 's/^/    /' "$P/tmpd/sc.out"
  done
  f=docs/reviews/execution-logs/sec-q089b-it2/probe-it2.sh
  grep -v '^# shellcheck disable=' "$f" > "$P/tmpd/probe-it2-stripped.sh"
  timeout 60 shellcheck -x -e SC1091 -s bash -S warning "$P/tmpd/probe-it2-stripped.sh" > "$P/tmpd/sc.out" 2>&1; rc=$?
  echo "$f (directive line removed) exit=$rc"; sed 's/^/    /' "$P/tmpd/sc.out"
  echo "end: $(date -u +%FT%TZ)"
} > "$OUT/shellcheck-gate6.log" 2>&1
cd /
rm -rf "$P"
echo "removed $P"
