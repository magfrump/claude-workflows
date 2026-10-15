#!/usr/bin/env bash
# Runs the gate suite at both archived commits; logs into $1.
P="$(cd "$(dirname "$0")" && pwd)"
L="$1"
[ -d "$P/src" ] && [ -d "$L" ] || { echo "missing dirs"; exit 1; }
export HOME="$P/home" LC_ALL=C
for c in src s12; do
  ( cd "$P/$c" || exit 1
    echo "cwd: $P/$c"; echo "start: $(date -u +%FT%TZ)"
    echo "cmd: timeout 300 bats test/hooks/live-verify-gate.bats"
    timeout 300 bats test/hooks/live-verify-gate.bats
    echo "exit=$?" ) > "$L/bats-gate-$c.log" 2>&1
  echo "== $c"; tail -2 "$L/bats-gate-$c.log"
  grep -c -E '^(ok|not ok)' "$L/bats-gate-$c.log"; grep '^not ok' "$L/bats-gate-$c.log"
done
( cd "$P/src" || exit 1
  echo "cwd: $P/src"; echo "start: $(date -u +%FT%TZ)"
  echo "cmd: timeout 600 bats -f 'host_tool|verify_host_tools|PAYLOAD|host-tools' test/cc-isolated-functions.bats; bats test/cc-push.bats"
  timeout 600 bats -f 'host_tool|verify_host_tools|PAYLOAD|host-tools|host tool' test/cc-isolated-functions.bats
  echo "exit=$?"
  timeout 600 bats -f 'refuse|host|tamper|help' test/cc-push.bats
  echo "exit=$?" ) > "$L/bats-hosttools-src.log" 2>&1
echo "== hosttools"; grep -E '^(not ok|exit=)|^1\.\.' "$L/bats-hosttools-src.log"
