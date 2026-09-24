#!/bin/bash
# Run install-host.bats at 66891a7 (pre-stderr-fix) and at 648124c in fresh clones.
D=/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/cfc-q058
for c in 66891a7 648124c; do
  rm -rf "$D/clone-$c"
  git clone -q /workspace/.claude/wt-copyinstall "$D/clone-$c"
  git -C "$D/clone-$c" checkout -q "$c"
  echo "== $c LC_ALL=${LC_ALL:-unset} =="
  (cd "$D/clone-$c" && bats test/install-host.bats > "$D/logs/ih-$c.log" 2>&1; echo "exit=$?")
  echo "not ok: $(grep -c '^not ok' "$D/logs/ih-$c.log")  ok: $(grep -c '^ok' "$D/logs/ih-$c.log")"
done
