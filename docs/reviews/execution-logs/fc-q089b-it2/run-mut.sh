#!/usr/bin/env bash
# Runs the gate suite clean and under single mutations of hooks/live-verify-gate.sh.
# $1 = probe root (holds src/, home/, logs/). Each mutation copies src to mut-<name>.
P="$1"
case "$P" in /home/node/.claude/jobs/00bcf178/tmp/fc-it2.*) ;; *) echo "bad P"; exit 1 ;; esac
[ -d "$P/src" ] || { echo "no src"; exit 1; }
mkdir -p "$P/logs" "$P/home" "$P/tmpd"
export HOME="$P/home" LC_ALL=C TMPDIR="$P/tmpd"
unset CLAUDE_DEVC_CONFIG_DIR CC_LIVE_VERIFY_GATE_DISABLE
H=hooks/live-verify-gate.sh
run_suite() { # $1 name, $2 dir
  local log="$P/logs/bats-$1.log"
  ( cd "$2" || exit 1
    echo "name: $1"; echo "cwd: $2"; echo "start: $(date -u +%FT%TZ)"
    echo "cmd: timeout 300 bats test/hooks/live-verify-gate.bats"
    grep -n -E '^(enforcement|host_tools)=|--name-only|BLOCKED: this commit changes a host|cannot exercise them' "$H"
    timeout 300 bats test/hooks/live-verify-gate.bats; echo "exit=$?" ) > "$log" 2>&1
  printf '%-18s total=%s notok=%s %s\n' "$1" "$(grep -c -E '^(ok|not ok)' "$log")" \
    "$(grep -c '^not ok' "$log")" "$(tail -1 "$log")"
  grep '^not ok' "$log" | sed 's/^/    /'
}
mut() { # $1 name, $2 python replacement: old, $3 new (literal), $4 optional count
  rm -rf "$P/mut-$1"; cp -a "$P/src" "$P/mut-$1"
  python3 -I - "$P/mut-$1/$H" "$2" "$3" <<'PY'
import sys
p, old, new = sys.argv[1:4]
s = open(p).read()
if old not in s:
    sys.exit("pattern not found")
open(p, "w").write(s.replace(old, new))
PY
  if cmp -s "$P/src/$H" "$P/mut-$1/$H"; then echo "$1: MUTATION DID NOT APPLY"; return; fi
  run_suite "$1" "$P/mut-$1"
}
run_suite clean "$P/src"
HT="host_tools='^devcontainer-config/("
mut M1-swap "init-firewall\\.sh|cc-sni" "cc-sni"
# M1 needs a second edit: put init-firewall into host_tools
python3 -I - "$P/mut-M1-swap/$H" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
s = s.replace("host_tools='^devcontainer-config/(", "host_tools='^devcontainer-config/(init-firewall\\.sh|")
open(p, "w").write(s)
PY
run_suite M1-swap-full "$P/mut-M1-swap"
mut M2-cached-renames "--cached --name-only --no-renames" "--cached --name-only"
mut M3-all-renames 'files="$files"$'"'"'\n'"'"'"$(git diff --name-only --no-renames' 'files="$files"$'"'"'\n'"'"'"$(git diff --name-only'
mut M4-endanchor "cc-push\\.sh)'" "cc-push\\.sh)\$'"
mut M5-extra-sh "$HT" "${HT}cc-extra\\.sh|"
mut M6-extra-py "$HT" "${HT}cc-extra\\.py|"
mut M7-joined-host 'comment_only_diff "$host_touched"' 'comment_only_diff "$touched"'
mut M7b-joined-boundary 'comment_only_diff "$boundary_touched"' 'comment_only_diff "$touched"'
mut M8-msg "changes a host tool but" "changes a host-only tool but"
mut M9-why 'git log --grep '"'"'Host-tool-tested: no'"'"' lists the outstanding host-tool debt."' 'nothing."'
