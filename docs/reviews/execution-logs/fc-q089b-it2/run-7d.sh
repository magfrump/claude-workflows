#!/usr/bin/env bash
# The gate suite at 7d25ea12 and 88432f39 (clean), and the init-firewall swap
# mutation at 7d25ea12. $1 = probe root; $2 = repo to archive from.
D="$1"; REPO="$2"
case "$D" in /home/node/.claude/jobs/00bcf178/tmp/fc-it2.*) ;; *) echo "bad D"; exit 1 ;; esac
export HOME="$D/home" LC_ALL=C TMPDIR="$D/tmpd"
unset CLAUDE_DEVC_CONFIG_DIR CC_LIVE_VERIFY_GATE_DISABLE
for c in 7d25ea12 88432f39; do
  rm -rf "$D/at-$c"; mkdir -p "$D/at-$c"
  git -C "$REPO" archive "$c" | tar -x -C "$D/at-$c"
done
cp -a "$D/at-7d25ea12" "$D/at-7d25ea12-mut"
python3 -I - "$D/at-7d25ea12-mut/hooks/live-verify-gate.sh" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
a = s.replace("init-firewall\\.sh|cc-sni", "cc-sni", 1)
b = a.replace("host_tools='^devcontainer-config/(", "host_tools='^devcontainer-config/(init-firewall\\.sh|", 1)
assert s != a != b
open(p, "w").write(b)
PY
for t in at-7d25ea12 at-88432f39 at-7d25ea12-mut; do
  log="$D/logs/bats-$t.log"
  ( cd "$D/$t" || exit 1; echo "cwd: $PWD start: $(date -u +%FT%TZ)"
    echo "cmd: timeout 300 bats test/hooks/live-verify-gate.bats"
    grep -n -E '^(enforcement|host_tools)=' hooks/live-verify-gate.sh
    timeout 300 bats test/hooks/live-verify-gate.bats; echo "exit=$?" ) > "$log" 2>&1
  printf '%-18s total=%s notok=%s %s\n' "$t" "$(grep -c -E '^(ok|not ok)' "$log")" "$(grep -c '^not ok' "$log")" "$(tail -1 "$log")"
  grep '^not ok' "$log" | sed 's/^/    /'
done
