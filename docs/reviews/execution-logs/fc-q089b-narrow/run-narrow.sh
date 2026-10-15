#!/usr/bin/env bash
# code-fact-check k=1 narrow probes for 70097ae0 (Q-089 B iteration 3, Q-148 [1]).
# Creates its own probe root under the job tmp dir and aborts if it cannot;
# writes logs to $1. Every mutation runs on a copy of `git archive 70097ae0`.
set -u
OUT="$1"
[ -d "$OUT" ] || { echo "no out dir"; exit 1; }
P="$(mktemp -d /home/node/.claude/jobs/00bcf178/tmp/fc-narrow.XXXXXX)" || exit 1
case "$P" in /home/node/.claude/jobs/00bcf178/tmp/fc-narrow.*) ;; *) echo "bad P"; exit 1 ;; esac
[ -d "$P" ] || exit 1
cd "$P" || exit 1
mkdir -p src home tmpd
git -C /workspace/.claude/wt-q089b archive 70097ae0 | tar -x -C src || exit 1
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
  printf '%-24s total=%s notok=%s %s\n' "$1" "$(grep -c -E '^(ok|not ok)' "$log")" \
    "$(grep -c '^not ok' "$log")" "$(tail -1 "$log")"
  grep '^not ok' "$log" | sed 's/^/    /'
}
mut() { # $1 name, $2 old (literal), $3 new
  rm -rf "$P/mut-$1"; cp -a "$P/src" "$P/mut-$1"
  python3 -I - "$P/mut-$1/$H" "$2" "$3" <<'PY' || { echo "$1: pattern not found"; return; }
import sys
p, old, new = sys.argv[1:4]
s = open(p).read()
if old not in s:
    sys.exit(1)
open(p, "w").write(s.replace(old, new))
PY
  if cmp -s "$P/src/$H" "$P/mut-$1/$H"; then echo "$1: MUTATION DID NOT APPLY"; return; fi
  diff "$P/src/$H" "$P/mut-$1/$H" | sed "s/^/    [$1] /"
  run_suite "$1" "$P/mut-$1"
}

echo "== count: $(cd src && bats --count test/hooks/live-verify-gate.bats)"
run_suite clean "$P/src"

# M1: `//` a comment in every file again (the pre-fix rule).
mut M1-slashes-everywhere "'//'*) [ \"\$slashes\" = 1 ] && continue ;;" "'//'*) continue ;;"
# M2: both flags off the -a worktree diff.
mut M2-all-both '$(git diff -U0 --no-color --no-textconv --no-ext-diff' '$(git diff -U0 --no-color'
# M3: only --no-ext-diff off the -a worktree diff (does the -a test's 2nd half bite alone?).
mut M3-all-extdiff '$(git diff -U0 --no-color --no-textconv --no-ext-diff' '$(git diff -U0 --no-color --no-textconv'
# M4: only --no-ext-diff off the --cached diff (the new diff.external test).
mut M4-cached-extdiff '--cached -U0 --no-color --no-textconv --no-ext-diff' '--cached -U0 --no-color --no-textconv'
# M5: slashes never reset per file (sticky after devcontainer.json).
mut M5-no-reset '        slashes=0
        case' '        case'
# M6: the regex swap the commit says still fails (init-firewall.sh into host_tools).
mut M6-swap "init-firewall\\.sh|cc-sni" "cc-sni"
python3 -I - "$P/mut-M6-swap/$H" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace("host_tools='^devcontainer-config/(", "host_tools='^devcontainer-config/(init-firewall\\.sh|")
open(p, "w").write(s)
PY
run_suite M6-swap-full "$P/mut-M6-swap"

pl() { jq -n -c --arg c "$1" '{"tool_name":"Bash","tool_input":{"command":$c}}'; }
fresh() {
  R="$P/repo-$1"; rm -rf "$R"; mkdir -p "$R/devcontainer-config/egress"; cd "$R" || exit 1
  git init -q; git config user.email t@e; git config user.name t; git config commit.gpgsign false
  echo base > devcontainer-config/egress/base.txt
  printf '{\n  "name": "x"\n}\n' > devcontainer-config/devcontainer.json
  printf '#!/bin/bash\necho hi\n' > devcontainer-config/init-firewall.sh
  git add -A; git commit -qm init
}
hk() { # $1 hook dir, $2 command
  timeout 20 bash "$P/$1/$H" <<< "$(pl "$2")" >/dev/null 2>&1; echo "exit $?"
}
{
  echo "start: $(date -u +%FT%TZ)"
  echo "-- D0 does bash run a //usr/bin/x line as a command?"
  printf '#!/bin/bash\n//usr/bin/echo RAN\n' > "$P/tmpd/s.sh"; timeout 5 bash "$P/tmpd/s.sh"; echo "   exit $?"

  fresh d1
  printf '{\n  // a note\n  "name": "x"\n}\n' > devcontainer-config/devcontainer.json
  git add -A
  echo "-- D1 jsonc // comment added to devcontainer.json, staged: src $(hk src 'git commit -m x')"
  printf '{\n  // a note, edited\n  "name": "x"\n}\n' > devcontainer-config/devcontainer.json
  echo "   + unstaged edit of that comment, -a: src $(hk src 'git commit -am x')"
  git commit -qm c1 >/dev/null 2>&1
  printf '{\n  // a note\n  "name": "x"\n}\n' > devcontainer-config/devcontainer.json; git add -A
  echo "   removing/rewording an existing // line (staged): src $(hk src 'git commit -m x')"

  fresh d2
  printf '{\n  // a note\n  "name": "x"\n}\n' > devcontainer-config/devcontainer.json
  echo '//usr/bin/curl x.invalid' >> devcontainer-config/init-firewall.sh
  git add -A
  echo "-- D2 one staged diff: // comment in devcontainer.json AND // line in init-firewall.sh"
  git diff --cached -U0 --no-color --no-textconv --no-ext-diff | sed 's/^/     | /'
  echo "   src: $(hk src 'git commit -m x')   M5-no-reset: $(hk mut-M5-no-reset 'git commit -m x')   M1: $(hk mut-M1-slashes-everywhere 'git commit -m x')"

  fresh d3
  echo '//usr/bin/curl x.invalid' >> devcontainer-config/init-firewall.sh; git add -A
  printf '{\n  // a note\n  "name": "x"\n}\n' > devcontainer-config/devcontainer.json  # unstaged
  echo "-- D3 script // staged, devcontainer.json // unstaged, -a: src $(hk src 'git commit -am x')  M5: $(hk mut-M5-no-reset 'git commit -am x')"

  fresh d4
  printf '{\n  // a note\n  "name": "x"\n}\n' > devcontainer-config/devcontainer.json; git add -A
  echo '//usr/bin/curl x.invalid' >> devcontainer-config/init-firewall.sh  # unstaged
  echo "-- D4 devcontainer.json // staged, script // unstaged, -a: src $(hk src 'git commit -am x')  M5: $(hk mut-M5-no-reset 'git commit -am x')"

  fresh d5
  printf '// x\n' > devcontainer-config/egress/devcontainer.json; git add -A; git commit -qm seed
  printf '// x\n//usr/bin/true\n' > devcontainer-config/egress/devcontainer.json; git add -A
  echo "-- D5 path ending /devcontainer.json elsewhere in the touched set (egress/devcontainer.json), // line added"
  echo "   name-only: $(git diff --cached --name-only --no-renames)"
  echo "   src: $(hk src 'git commit -m x')  (0 = // leniency applied)"
  mkdir -p devcontainer-config/cc-push.sh.d
  printf '// x\n' > devcontainer-config/cc-push.sh.d/devcontainer.json; git add -A; git commit -qm seed2
  printf '// x\n//usr/bin/true\n' > devcontainer-config/cc-push.sh.d/devcontainer.json; git add -A
  echo "   host-tool set, cc-push.sh.d/devcontainer.json: src $(hk src 'git commit -m x')"
  echo "   enforcement_files egress glob in cc-isolated.sh:"
  grep -n 'egress' "$P/src/devcontainer-config/cc-isolated.sh" | grep -n -i 'txt\|find\|glob\|for ' | head -5 | sed 's/^/     | /'

  fresh d6
  echo "-- D6 quoted path header: a gated file whose name forces quoting"
  printf '#\n' > 'devcontainer-config/egress/t"q.txt'; git add -A; git commit -qm seed
  printf '#\n// y\n' > 'devcontainer-config/egress/t"q.txt'; git add -A
  echo "   name-only: $(git diff --cached --name-only --no-renames)"
  git diff --cached -U0 --no-color | head -1 | sed 's/^/     | /'
  echo "   src (// in a quoted non-json path): $(hk src 'git commit -m x')"

  fresh d7
  echo "-- D7 roadmap F3: non-ASCII path under default core.quotePath"
  printf 'x\n' > "devcontainer-config/egress/caf$(printf '\303\251').txt"; git add -A
  echo "   name-only: $(git diff --cached --name-only --no-renames)"
  echo "   src: $(hk src 'git commit -m x')  (0 = missed by the anchors)"
  echo "   name-only -z: $(git diff --cached --name-only --no-renames -z | tr '\0' '\n')"

  fresh d8
  echo "-- D8 roadmap F4: diff.relative, hook cwd a subdirectory"
  mkdir -p src; echo a > src/a; git add -A; git commit -qm s
  echo widened >> devcontainer-config/egress/base.txt; git add -A
  git config diff.relative true
  cd src || exit 1
  echo "   name-only from src/: [$(git diff --cached --name-only --no-renames)]  with --no-relative: [$(git diff --cached --name-only --no-renames --no-relative)]"
  echo "   src hook from src/: $(hk src 'git commit -m x')  (0 = dropped)"
  cd "$P" || exit 1
  echo "end: $(date -u +%FT%TZ)"
} > "$OUT/direct-probes.log" 2>&1
cd /
rm -rf "$P"
echo "removed $P"
