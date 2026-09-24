#!/bin/bash
# Run the suites hermetically. Output logs into $OUT.
W=/workspace/.claude/wt-copyinstall
SP=/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad
OUT=$SP/fc/logs
mkdir -p "$OUT"
export TMPDIR=$SP/fc/tmp; mkdir -p "$TMPDIR"
unset CLAUDECODE CLAUDE_CONFIG_DIR
cd "$W"
date -u +%FT%TZ > "$OUT/ts-start"
bats test/install-host.bats > "$OUT/install-host-head.log" 2>&1; echo "exit=$?" >> "$OUT/install-host-head.log"
bats test/cc-isolated-functions.bats > "$OUT/cc-isolated.log" 2>&1; echo "exit=$?" >> "$OUT/cc-isolated.log"
bats test/link-claude-home-wiring.bats > "$OUT/link-wiring.log" 2>&1; echo "exit=$?" >> "$OUT/link-wiring.log"
bats test/hooks/*.bats > "$OUT/hooks.log" 2>&1; echo "exit=$?" >> "$OUT/hooks.log"
# Old install.sh against the new suite
C=$TMPDIR/oldcopy; rm -rf "$C"; mkdir -p "$C"
git archive d0fdd04 | tar -x -C "$C"
git show 712c626:devcontainer-config/install.sh > "$C/devcontainer-config/install.sh"
chmod +x "$C/devcontainer-config/install.sh"
(cd "$C" && bats test/install-host.bats) > "$OUT/install-host-old.log" 2>&1; echo "exit=$?" >> "$OUT/install-host-old.log"
date -u +%FT%TZ > "$OUT/ts-end"
